import 'package:flutter/material.dart';
import 'package:fletch/models/collection_model.dart';
import 'package:fletch/providers/request_provider.dart';
import 'package:fletch/providers/workspace_provider.dart';
import 'package:fletch/theme/app_colors.dart';
import 'package:fletch/models/http_auth.dart';
import 'package:fletch/widgets/http_auth_editor.dart';
import 'package:fletch/utils/auth_resolver.dart';
import 'package:provider/provider.dart';
import 'package:fletch/widgets/script_selector_widget.dart';
import 'package:fletch/widgets/dialogs/script_manager_dialog.dart';
import 'package:fletch/models/visual_script.dart';
import 'package:fletch/models/workspace_models.dart';

class NewCollectionDialogBody extends StatefulWidget {
  const NewCollectionDialogBody({
    super.key,
    required this.icons,
    required this.colors,
    required this.isDark,
    this.collection,
    this.initialTab = 0,
  });

  final Map<String, IconData> icons;
  final Map<String, Color> colors;
  final bool isDark;
  final RequestCollection? collection;
  final int initialTab;

  @override
  State<NewCollectionDialogBody> createState() =>
      _NewCollectionDialogBodyState();
}

class _NewCollectionDialogBodyState extends State<NewCollectionDialogBody> {
  String currentColor = '#8b5cf6';
  String currentIcon = 'folder';
  late TextEditingController _collectionDescriptionController;
  late TextEditingController _collectionNameController;
  late HttpAuth _collectionAuth;
  late List<String> _collectionActiveScriptIds;
  late bool _collectionInheritScripts;
  bool _editing = false;
  late int _activeTab;

  @override
  void initState() {
    super.initState();
    _collectionDescriptionController = TextEditingController();
    _collectionNameController = TextEditingController();
    _collectionAuth = HttpAuth(type: AuthType.inherit);
    _collectionActiveScriptIds = widget.collection?.activeScriptIds ?? [];
    _collectionInheritScripts = widget.collection?.inheritScripts ?? true;
    _activeTab = widget.initialTab;

    if (widget.collection != null) {
      _editing = true;
      currentColor = widget.collection!.color;
      currentIcon = widget.collection!.icon;
      _collectionNameController.text = widget.collection?.name ?? '';
      _collectionDescriptionController.text =
          widget.collection?.description ?? '';
      _collectionAuth = widget.collection!.auth;
    }
  }

  @override
  void dispose() {
    _collectionDescriptionController.dispose();
    _collectionNameController.dispose();
    super.dispose();
  }

  List<VisualScript> _resolveCollectionInheritedScripts(
    String? parentId,
    List<RequestCollection> collections,
    WorkspaceModel workspace,
    bool inheritScripts,
  ) {
    if (!inheritScripts) {
      return [];
    }
    final List<String> inheritedIds = [];

    if (parentId != null) {
      RequestCollection? parent;
      try {
        parent = collections.firstWhere((c) => c.id == parentId);
      } catch (_) {}

      if (parent != null) {
        inheritedIds.addAll(parent.activeScriptIds);
        // Recursively add parent's inherited scripts
        inheritedIds.addAll(
          _resolveCollectionInheritedScripts(
            parent.parentId,
            collections,
            workspace,
            parent.inheritScripts,
          ).map((s) => s.id),
        );
      }
    } else {
      // Directly under workspace, inherits workspace level active scripts
      inheritedIds.addAll(workspace.activeScriptIds);
    }

    final allScriptModels = {for (var s in workspace.scripts) s.id: s};
    final Set<String> uniqueIds = inheritedIds.toSet();
    return uniqueIds.map((id) => allScriptModels[id]).whereType<VisualScript>().toList();
  }

  Widget _buildTabButton(int index, String label, Color activeColor, Color inactiveColor) {
    final isSelected = _activeTab == index;
    return InkWell(
      onTap: () => setState(() => _activeTab = index),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6366F1).withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF6366F1) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isSelected ? const Color(0xFF6366F1) : inactiveColor,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isDark ? Colors.white : const Color(0xFF0F172A);
    final labelColor = widget.isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);

    final requestProvider = Provider.of<RequestProvider>(context);
    final wsProvider = Provider.of<WorkspaceProvider>(context);
    final workspaceAuth = wsProvider.currentWorkspace?.auth ?? HttpAuth(type: AuthType.none);

    RequestCollection? parentCol;
    if (widget.collection?.parentId != null) {
      try {
        parentCol = requestProvider.collections.firstWhere((c) => c.id == widget.collection!.parentId);
      } catch (_) {}
    }

    final inheritedFromName = parentCol != null
        ? 'Collection "${parentCol.name}"'
        : 'Workspace';

    final resolvedInheritedAuth = parentCol != null
        ? AuthResolver.resolveCollectionAuth(
            collection: parentCol,
            collections: requestProvider.collections,
            workspaceAuth: workspaceAuth,
          )
        : workspaceAuth;

    return Container(
      padding: const EdgeInsets.all(24),
      width: 520,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_editing ? Icons.edit_note_rounded : Icons.create_new_folder),
              const SizedBox(width: 8),
              Text(
                _editing ? 'Edit Collection' : 'Create New Collection',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(
            height: 1,
            color: widget.isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
          const SizedBox(height: 16),

          // Tabs
          Row(
            children: [
              _buildTabButton(0, 'General', textColor, labelColor),
              const SizedBox(width: 12),
              _buildTabButton(1, 'Authentication', textColor, labelColor),
              const SizedBox(width: 12),
              _buildTabButton(2, 'Scripts', textColor, labelColor),
            ],
          ),
          const SizedBox(height: 20),

          // Tab Body
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_activeTab == 0) ...[
                    const Text('COLLECTION NAME'),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _collectionNameController,
                      style: TextStyle(fontSize: 14, color: textColor),
                      decoration: InputDecoration(
                        hintText: 'e.g. Payments API',
                        hintStyle: TextStyle(
                          fontSize: 14,
                          color: labelColor.withValues(alpha: 0.2),
                        ),
                      ),
                      autofocus: true,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('SELECT ICON'),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                for (final entry in widget.icons.entries) ...[
                                  _buildIconSelector(entry, entry.key == currentIcon),
                                  const SizedBox(width: 6),
                                ],
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('FOLDER COLOR'),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                for (final color in widget.colors.entries) ...[
                                  _buildColorSelector(color, color.key == currentColor),
                                  const SizedBox(width: 6),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('DESCRIPTION (OPTIONAL)'),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _collectionDescriptionController,
                          maxLines: 8,
                          minLines: 4,
                          keyboardType: TextInputType.multiline,
                          style: TextStyle(fontSize: 13, color: textColor),
                          decoration: InputDecoration(
                            hintText: 'Briefly describe the purpose of this collection...',
                            hintStyle: TextStyle(
                              color: labelColor.withValues(alpha: 0.2),
                              fontSize: 13,
                            ),
                            alignLabelWithHint: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else if (_activeTab == 1) ...[
                    HttpAuthEditor(
                      initialAuth: _collectionAuth,
                      showInheritOption: true,
                      inheritedFromName: inheritedFromName,
                      resolvedInheritedAuth: resolvedInheritedAuth,
                      onChanged: (updatedAuth) {
                        setState(() {
                          _collectionAuth = updatedAuth;
                        });
                      },
                    ),
                  ] else ...[
                    SizedBox(
                      height: 350,
                      child: ScriptSelectorWidget(
                        allScripts: wsProvider.currentWorkspace?.scripts ?? [],
                        activeScriptIds: _collectionActiveScriptIds,
                        inheritScripts: _collectionInheritScripts,
                        inheritedFromName: inheritedFromName,
                        inheritedScripts: _resolveCollectionInheritedScripts(
                          widget.collection?.parentId,
                          requestProvider.collections,
                          wsProvider.currentWorkspace!,
                          _collectionInheritScripts,
                        ),
                        onActiveScriptsChanged: (activeIds) {
                          setState(() {
                            _collectionActiveScriptIds = activeIds;
                          });
                        },
                        onInheritChanged: (inherit) {
                          setState(() {
                            _collectionInheritScripts = inherit;
                          });
                        },
                        onOpenManager: () {
                          final workspace = wsProvider.currentWorkspace;
                          if (workspace != null) {
                            showDialog(
                              context: context,
                              builder: (context) => ScriptManagerDialog(
                                workspace: workspace,
                                onWorkspaceUpdated: (updatedWorkspace) {
                                  wsProvider.addWorkspace(updatedWorkspace);
                                },
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
          Divider(height: 1, color: widget.isDark ? AppColors.borderDark : AppColors.borderLight),
          const SizedBox(height: 16),

          // Footer
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: widget.isDark
                        ? AppColors.textDark
                        : AppColors.textLight,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: widget.isDark
                            ? AppColors.borderDark
                            : AppColors.borderLight,
                      ),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _handleSubmit(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    _editing ? 'Update Collection' : 'Create Collection',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconSelector(MapEntry<String, IconData> entry, bool isSelected) {
    return InkWell(
      onTap: () {
        setState(() {
          currentIcon = entry.key;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            width: 1.5,
            color: isSelected
                ? AppColors.primary.withValues(alpha: .9)
                : (widget.isDark
                    ? AppColors.borderDark
                    : AppColors.borderLight),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(8),
        child: Icon(
          entry.value,
          size: 16,
          color: isSelected
              ? AppColors.primary.withValues(alpha: .9)
              : AppColors.slate500,
        ),
      ),
    );
  }

  Widget _buildColorSelector(MapEntry<String, Color> entry, bool isSelected) {
    return InkWell(
      onTap: () {
        setState(() {
          currentColor = entry.key;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? entry.value : Colors.transparent,
            width: 2,
          ),
        ),
        padding: const EdgeInsets.all(3),
        child: Container(
          decoration: BoxDecoration(color: entry.value, shape: BoxShape.circle),
        ),
      ),
    );
  }

  Future<void> _handleSubmit(BuildContext context) async {
    if (_collectionNameController.text.isEmpty) {
      return;
    }

    final collection = RequestCollection(
      name: _collectionNameController.text,
      description: _collectionDescriptionController.text,
      workspaceId: _editing
          ? widget.collection!.workspaceId
          : Provider.of<WorkspaceProvider>(
              context,
              listen: false,
            ).currentWorkspace!.id,
      requests: _editing ? widget.collection!.requests : [],
      isExpanded: _editing ? widget.collection!.isExpanded : true,
      icon: currentIcon,
      color: currentColor,
      id: _editing ? widget.collection!.id : null,
      parentId: _editing ? widget.collection!.parentId : null,
      sortOrder: _editing ? widget.collection!.sortOrder : 0,
      auth: _collectionAuth,
      activeScriptIds: _collectionActiveScriptIds,
      inheritScripts: _collectionInheritScripts,
    );

    if (!_editing) {
      await Provider.of<RequestProvider>(
        context,
        listen: false,
      ).addCollection(collection);
    } else {
      await Provider.of<RequestProvider>(
        context,
        listen: false,
      ).updateCollection(collection);
    }

    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }
}
