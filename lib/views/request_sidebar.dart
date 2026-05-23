import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart' as picker;
import 'package:flutter/material.dart';
import 'package:gk_http_client/providers/workspace_provider.dart';
import 'package:gk_http_client/widgets/dialogs/manage_collection.dart';
import 'package:provider/provider.dart';
import 'package:gk_http_client/models/collection_model.dart';
import 'package:gk_http_client/providers/request_provider.dart';
import 'package:gk_http_client/theme/app_colors.dart';
import 'package:gk_http_client/widgets/collection_folder.dart';
import 'package:gk_http_client/widgets/custom_scrollbar.dart';
import 'package:gk_http_client/widgets/request_list_item.dart';

class RequestSidebar extends StatefulWidget {
  const RequestSidebar({super.key});

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
      width: 280,
      color: isDark ? AppColors.sidebarDark : AppColors.slate50,
      child: Column(
        children: [
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
                            depth: 0,
                          );
                        })
                      : requestProvider.filteredCollections.map((collection) {
                          return _Collection(
                            context: context,
                            provider: requestProvider,
                            collection: collection,
                            depth: 0,
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
      child: Row(
        children: [
          Expanded(
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              child: InkWell(
                onTap: () {
                  _openNewCollectionDialog(context, isDark);
                },
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_rounded, size: 16, color: AppColors.slate500),
                      const SizedBox(width: 4),
                      Text(
                        'New Collection',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.slate500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _ActionButton(
            icon: Icons.file_upload_rounded,
            tooltip: 'Import Collections',
            onTap: () => _importCollections(context, provider, wsProvider),
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          _ActionButton(
            icon: Icons.file_download_rounded,
            tooltip: 'Export Collections',
            onTap: () => _exportCollections(context, provider),
            isDark: isDark,
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

      final result = await picker.FilePicker.platform.pickFiles(
        type: picker.FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final content = await file.readAsString();
        final List<dynamic> jsonList = jsonDecode(content);
        final List<Map<String, dynamic>> collectionsData = jsonList
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();

        await provider.importCollections(collectionsData, currentWorkspace.id);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Collections imported successfully!'),
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
  ) async {
    try {
      final collectionsJson = provider.exportCollections();
      final jsonString = const JsonEncoder.withIndent('  ').convert(collectionsJson);

      final String? outputPath = await picker.FilePicker.platform.saveFile(
        dialogTitle: 'Export Collections',
        fileName: 'collections_export.json',
        type: picker.FileType.custom,
        allowedExtensions: ['json'],
      );

      if (outputPath != null) {
        final file = File(outputPath);
        await file.writeAsString(jsonString);

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
  final double depth;

  const _Collection({
    required this.context,
    required this.provider,
    required this.collection,
    required this.depth,
  });

  @override
  Widget build(BuildContext context) {
    return CollectionFolder(
      collection: collection,
      isExpanded: collection.isExpanded,
      depth: depth,
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
                    depth: depth + 1,
                  )),
          ...collection.requests.map((request) {
            final isSelected = provider.selectedRequest?.id == request.id;

            return RequestListItem(
              request: request,
              collectionId: collection.id,
              isSelected: isSelected,
              depth: depth + 1,
              onTap: () {
                provider.selectRequest(request);
                Provider.of<WorkspaceProvider>(context, listen: false)
                    .isManagingEnvironments = false;
              },
            );
          }),
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
