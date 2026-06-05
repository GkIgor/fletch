import 'dart:convert';
import 'dart:io';
import 'package:file_selector/file_selector.dart' as selector;
import 'package:flutter/material.dart';
import 'package:fletch/providers/workspace_provider.dart';
import 'package:fletch/widgets/dialogs/manage_collection.dart';
import 'package:provider/provider.dart';
import 'package:fletch/models/collection_model.dart';
import 'package:fletch/providers/request_provider.dart';
import 'package:fletch/theme/app_colors.dart';
import 'package:fletch/widgets/collection_folder.dart';
import 'package:fletch/widgets/custom_scrollbar.dart';
import 'package:fletch/widgets/request_list_item.dart';
import 'package:fletch/widgets/dialogs/export_format_dialog.dart';
import 'package:fletch/utils/converters/format_detector.dart';
import 'package:fletch/utils/converters/postman_converter.dart';
import 'package:fletch/utils/converters/insomnia_converter.dart';
import 'package:fletch/utils/converters/yaml_helper.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fletch/widgets/dialogs/auto_collections_generator_dialog.dart';
import 'package:fletch/widgets/dialogs/payload_bulk_importer_dialog.dart';

class RequestSidebar extends StatefulWidget {
  final double width;
  const RequestSidebar({super.key, this.width = 280.0});

  @override
  State<RequestSidebar> createState() => _RequestSidebarState();
}

class _RequestSidebarState extends State<RequestSidebar> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final wsProvider = Provider.of<WorkspaceProvider>(context, listen: false);
      final requestProvider = Provider.of<RequestProvider>(
        context,
        listen: false,
      );

      if (wsProvider.currentWorkspace != null) {
        requestProvider.loadCollections(wsProvider.currentWorkspace!.id);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final requestProvider = Provider.of<RequestProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: widget.width,
      color: isDark ? AppColors.sidebarDark : AppColors.slate50,
      child: Column(
        children: [
          _CollectionsHeader(
            isDark: isDark,
            provider: requestProvider,
          ),

          _SearchFilter(
            isDark: isDark,
            controller: _searchController,
            onChanged: (value) {
              requestProvider.setSearchFilter(value);
            },
          ),

          Divider(
            height: 1,
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),

          Expanded(
            child: CustomScrollbar(
              controller: _scrollController,
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.all(8),
                children: [
                  if (requestProvider.corruptedCollections.isNotEmpty)
                    _SecurityWarningBanner(provider: requestProvider),

                  ...(requestProvider.searchFilter.isEmpty
                      ? requestProvider.collections.where((c) => c.parentId == null).map((collection) {
                          return _Collection(
                            context: context,
                            provider: requestProvider,
                            collection: collection,
                          );
                        })
                      : requestProvider.filteredCollections.map((collection) {
                          return _Collection(
                            context: context,
                            provider: requestProvider,
                            collection: collection,
                          );
                        })),

                  if (requestProvider.filteredCollections.isEmpty &&
                      requestProvider.searchFilter.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(
                        child: Text(
                          'No matches found',
                          style: TextStyle(
                            color: AppColors.slate400,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          Divider(
            height: 1,
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),

          _SidebarFooterActions(isDark: isDark),
        ],
      ),
    );
  }
}

class _SecurityWarningBanner extends StatelessWidget {
  final RequestProvider provider;

  const _SecurityWarningBanner({required this.provider});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final count = provider.corruptedCollections.length;

    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$count Collection${count > 1 ? "s" : ""} Mismatch',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Signature mismatch detected. These files may have been imported or modified externally.',
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => _showCorruptedDetailsDialog(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Resolve', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCorruptedDetailsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return ListenableBuilder(
          listenable: provider,
          builder: (context, _) {
            final corrupted = provider.corruptedCollections;
            if (corrupted.isEmpty) {
              Navigator.of(context).pop();
            }

            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.security_rounded, color: Colors.amber),
                  SizedBox(width: 8),
                  Text('Security Mismatch Warning'),
                ],
              ),
              content: SizedBox(
                width: 500,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'The following collection files have security signatures that do not match this device. '
                      'This happens if they were copied directly from another machine or edited manually.\n\n'
                      'Choose whether to trust and re-sign them for this device, or discard them.',
                      style: TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: corrupted.length,
                        itemBuilder: (context, index) {
                          final coll = corrupted[index];
                          final name = coll['name'] ?? 'Unnamed Collection';
                          final id = coll['id'] ?? '';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            color: isDark ? AppColors.slate800 : AppColors.slate100,
                            child: ListTile(
                              title: Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                              subtitle: Text('ID: $id', style: TextStyle(fontSize: 11, color: AppColors.slate500)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 20),
                                    tooltip: 'Trust & Re-sign',
                                    onPressed: () => provider.reSignCollection(coll),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                    tooltip: 'Discard',
                                    onPressed: () => provider.discardCorruptedCollection(id),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => provider.reSignAllCorrupted(),
                  child: const Text('Trust & Re-sign All', style: TextStyle(color: Colors.green)),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _SidebarFooterActions extends StatelessWidget {
  const _SidebarFooterActions({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<RequestProvider>(context, listen: false);
    final wsProvider = Provider.of<WorkspaceProvider>(context, listen: false);

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Material(
                  color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(6),
                  child: InkWell(
                    onTap: () {
                      _openNewCollectionDialog(context, isDark);
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isDark ? AppColors.borderDark : AppColors.borderLight,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_rounded, size: 18, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text(
                            'New Collection',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.textDark : AppColors.textLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _ActionButton(
                icon: Icons.file_upload_rounded,
                tooltip: 'Import Collections',
                onTap: () => _importCollections(context, provider, wsProvider),
                isDark: isDark,
              ),
              _ActionButton(
                icon: Icons.file_download_rounded,
                tooltip: 'Export Collections',
                onTap: () => _exportCollections(context, provider, wsProvider),
                isDark: isDark,
              ),
              _ActionButton(
                icon: Icons.play_circle_outline_rounded,
                tooltip: 'Run Workspace',
                onTap: () => provider.startWorkspaceRun(),
                isDark: isDark,
              ),
              Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Tooltip(
                  message: 'Tools',
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      cardColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                    ),
                    child: PopupMenuButton<String>(
                      icon: const Icon(Icons.construction_rounded, size: 16, color: AppColors.slate500),
                      splashRadius: 20,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      onSelected: (value) {
                        if (value == 'generator') {
                          _openAutoGeneratorDialog(context, isDark);
                        } else if (value == 'importer') {
                          _pickAndOpenBulkImporter(context, provider, isDark);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'generator',
                          child: Row(
                            children: [
                              Icon(Icons.auto_awesome_rounded, size: 16, color: AppColors.primary),
                              const SizedBox(width: 8),
                              const Text('Auto Collections Generator', style: TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'importer',
                          child: Row(
                            children: [
                              Icon(Icons.system_update_alt_rounded, size: 16, color: AppColors.primary),
                              const SizedBox(width: 8),
                              const Text('Payload Bulk Importer', style: TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openNewCollectionDialog(BuildContext context, bool isDark) {
    final Map<String, IconData> icons = RequestProvider.icons;
    final Map<String, Color> colors = RequestProvider.colors;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: NewCollectionDialogBody(
            icons: icons,
            colors: colors,
            isDark: isDark,
          ),
        );
      },
    );
  }

  Future<void> _importCollections(
    BuildContext context,
    RequestProvider provider,
    WorkspaceProvider wsProvider,
  ) async {
    try {
      final currentWorkspace = wsProvider.currentWorkspace;
      if (currentWorkspace == null) return;

      final typeGroup = selector.XTypeGroup(
        label: 'HTTP Collections',
        extensions: ['json', 'yaml', 'yml'],
      );
      final pickedFile = await selector.openFile(
        acceptedTypeGroups: [typeGroup],
      );

      if (pickedFile != null) {
        final content = await pickedFile.readAsString();
        
        dynamic decoded;
        try {
          decoded = jsonDecode(content);
        } catch (_) {
          decoded = YamlHelper.parse(content);
        }

        final format = FormatDetector.detect(decoded);
        List<RequestCollection> collectionsToImport;
        String formatName = '';

        switch (format) {
          case CollectionFormat.native:
            final List<dynamic> jsonList = decoded as List;
            final List<Map<String, dynamic>> collectionsData = jsonList
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList();
            collectionsToImport = collectionsData.map((json) {
              json['workspaceId'] = currentWorkspace.id;
              json.remove('signature');
              return RequestCollection.fromJson(json);
            }).toList();
            formatName = 'Native';
            break;
          case CollectionFormat.postman:
            collectionsToImport = PostmanConverter.importCollection(
              Map<String, dynamic>.from(decoded as Map),
              currentWorkspace.id,
            );
            formatName = 'Postman';
            break;
          case CollectionFormat.insomnia:
            collectionsToImport = InsomniaConverter.importCollection(
              Map<String, dynamic>.from(decoded as Map),
              currentWorkspace.id,
            );
            formatName = 'Insomnia';
            break;
          case CollectionFormat.unknown:
            throw Exception('Unknown or unsupported collection format.');
        }

        await provider.importLoadedCollections(collectionsToImport, currentWorkspace.id);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$formatName collections imported successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _exportCollections(
    BuildContext context,
    RequestProvider provider,
    WorkspaceProvider wsProvider,
  ) async {
    try {
      final currentWorkspace = wsProvider.currentWorkspace;
      if (currentWorkspace == null) return;

      final format = await showDialog<ExportFormat>(
        context: context,
        builder: (context) => const ExportFormatDialog(),
      );

      if (format == null) return;

      dynamic exportData;
      String defaultFileName = 'collections_export.json';
      bool isYaml = false;

      switch (format) {
        case ExportFormat.native:
          exportData = provider.exportCollections();
          defaultFileName = 'collections_native_export.json';
          break;
        case ExportFormat.postman:
          exportData = provider.exportPostman(currentWorkspace.name);
          defaultFileName = '${currentWorkspace.name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}_postman_collection.json';
          break;
        case ExportFormat.insomniaJson:
          exportData = provider.exportInsomnia(currentWorkspace.id, currentWorkspace.name, exportFormat: 4);
          defaultFileName = '${currentWorkspace.name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}_insomnia_export.json';
          break;
        case ExportFormat.insomniaYaml:
          exportData = provider.exportInsomnia(currentWorkspace.id, currentWorkspace.name, exportFormat: 5);
          defaultFileName = '${currentWorkspace.name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}_insomnia_export.yaml';
          isYaml = true;
          break;
      }

      final String fileContent = isYaml
          ? YamlHelper.toYaml(exportData)
          : const JsonEncoder.withIndent('  ').convert(exportData);

      final typeGroup = selector.XTypeGroup(
        label: isYaml ? 'YAML Collection' : 'JSON Collection',
        extensions: isYaml ? ['yaml', 'yml'] : ['json'],
      );
      final selector.FileSaveLocation? result = await selector.getSaveLocation(
        suggestedName: defaultFileName,
        acceptedTypeGroups: [typeGroup],
      );

      if (result != null) {
        final file = File(result.path);
        await file.writeAsString(fileContent);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Collections exported successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _openAutoGeneratorDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: AutoCollectionsGeneratorDialog(isDark: isDark),
        );
      },
    );
  }

  Future<void> _pickAndOpenBulkImporter(BuildContext context, RequestProvider provider, bool isDark) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.isNotEmpty) {
        final List<MapEntry<String, String>> filesData = [];
        for (var file in result.files) {
          if (file.path != null) {
            final content = await File(file.path!).readAsString();
            filesData.add(MapEntry(file.name, content));
          }
        }

        if (context.mounted && filesData.isNotEmpty) {
          showDialog(
            context: context,
            builder: (context) {
              return Dialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: PayloadBulkImporterDialog(filesData: filesData, isDark: isDark),
              );
            },
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error selecting files: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    required this.isDark,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      width: 36,
      decoration: BoxDecoration(
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Tooltip(
        message: tooltip,
        child: IconButton(
          icon: Icon(icon, size: 16, color: AppColors.slate500),
          onPressed: onTap,
          splashRadius: 20,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
      ),
    );
  }
}

class _Collection extends StatelessWidget {
  final BuildContext context;
  final RequestProvider provider;
  final RequestCollection collection;

  const _Collection({
    required this.context,
    required this.provider,
    required this.collection,
  });

  @override
  Widget build(BuildContext context) {
    return CollectionFolder(
      collection: collection,
      isExpanded: collection.isExpanded,
      onToggle: () {
        provider.toggleCollectionExpansion(collection.id);
      },
      child: Column(
        children: [
          ...provider.collections
              .where((c) => c.parentId == collection.id)
              .map((subColl) => _Collection(
                    context: context,
                    provider: provider,
                    collection: subColl,
                  )),
          ...collection.requests.map((request) {
            final isSelected = provider.selectedRequest?.id == request.id;

            return RequestListItem(
              request: request,
              collectionId: collection.id,
              isSelected: isSelected,
              onTap: () {
                provider.selectRequest(request);
                final wsProvider = Provider.of<WorkspaceProvider>(context, listen: false);
                wsProvider.isManagingEnvironments = false;
                wsProvider.isManagingAuth = false;
              },
            );
          }),
        ],
      ),
    );
  }
}

class _CollectionsHeader extends StatelessWidget {
  const _CollectionsHeader({
    required this.isDark,
    required this.provider,
  });

  final bool isDark;
  final RequestProvider provider;

  @override
  Widget build(BuildContext context) {
    final bool anyExpanded = provider.collections.any((c) => c.isExpanded);
    final bool anyCollapsed = provider.collections.any((c) => !c.isExpanded);
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          Text(
            'Collections',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: textColor,
            ),
          ),
          if (provider.collections.isNotEmpty) ...[  
            const Spacer(),
            // Expand all
            Tooltip(
              message: 'Expand All',
              waitDuration: const Duration(milliseconds: 400),
              child: InkWell(
                onTap: anyCollapsed
                    ? () => provider.toggleAllCollections(expanded: true)
                    : null,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.unfold_more_rounded,
                    size: 16,
                    color: anyCollapsed
                        ? textColor
                        : textColor.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 2),
            // Collapse all
            Tooltip(
              message: 'Collapse All',
              waitDuration: const Duration(milliseconds: 400),
              child: InkWell(
                onTap: anyExpanded
                    ? () => provider.toggleAllCollections(expanded: false)
                    : null,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.unfold_less_rounded,
                    size: 16,
                    color: anyExpanded
                        ? textColor
                        : textColor.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SearchFilter extends StatelessWidget {
  const _SearchFilter({
    required this.isDark,
    required this.controller,
    required this.onChanged,
  });

  final bool isDark;
  final TextEditingController controller;
  final Function(String) onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: Row(
          children: [
            const SizedBox(width: 8),
            Icon(Icons.search_rounded, size: 16, color: AppColors.slate400),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: controller,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.textDark : AppColors.textLight,
                ),
                decoration: InputDecoration(
                  hintText: 'Filter requests...',
                  hintStyle: TextStyle(fontSize: 13, color: AppColors.slate400),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.only(bottom: 12),
                ),
                onChanged: onChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
