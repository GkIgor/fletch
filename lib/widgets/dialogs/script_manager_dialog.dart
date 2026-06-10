import 'package:flutter/material.dart';
import 'package:fletch/models/visual_script.dart';
import 'package:fletch/models/workspace_models.dart';
import 'package:fletch/theme/app_colors.dart';
import 'package:fletch/widgets/low_code_step_editor.dart';

class ScriptManagerDialog extends StatefulWidget {
  final WorkspaceModel workspace;
  final ValueChanged<WorkspaceModel> onWorkspaceUpdated;

  const ScriptManagerDialog({
    super.key,
    required this.workspace,
    required this.onWorkspaceUpdated,
  });

  @override
  State<ScriptManagerDialog> createState() => _ScriptManagerDialogState();
}

class _ScriptManagerDialogState extends State<ScriptManagerDialog> {
  VisualScript? _selectedScript;

  void _createNewScript() {
    final newScript = VisualScript(
      name: 'New Script ${_getUniqueIndex()}',
      isPreRequest: true,
      mode: ScriptMode.lowCode,
    );

    final updatedScripts = List<VisualScript>.from(widget.workspace.scripts)
      ..add(newScript);
    final updatedWorkspace = widget.workspace..scripts = updatedScripts;

    widget.onWorkspaceUpdated(updatedWorkspace);
    setState(() {
      _selectedScript = newScript;
    });
  }

  int _getUniqueIndex() {
    return widget.workspace.scripts.length + 1;
  }

  void _deleteScript(VisualScript script) {
    final updatedScripts = List<VisualScript>.from(widget.workspace.scripts)
      ..removeWhere((s) => s.id == script.id);

    // Invalidate active script lists from workspace settings
    final updatedActiveIds = List<String>.from(widget.workspace.activeScriptIds)
      ..remove(script.id);

    final updatedWorkspace = widget.workspace
      ..scripts = updatedScripts
      ..activeScriptIds = updatedActiveIds;

    widget.onWorkspaceUpdated(updatedWorkspace);
    setState(() {
      if (_selectedScript?.id == script.id) {
        _selectedScript = null;
      }
    });
  }

  void _duplicateScript(VisualScript script) {
    final duplicated = VisualScript(
      name: '${script.name} Copy',
      isPreRequest: script.isPreRequest,
      mode: script.mode,
      steps: List.from(script.steps),
      advancedCode: script.advancedCode,
    );

    final updatedScripts = List<VisualScript>.from(widget.workspace.scripts)
      ..add(duplicated);
    final updatedWorkspace = widget.workspace..scripts = updatedScripts;

    widget.onWorkspaceUpdated(updatedWorkspace);
    setState(() {
      _selectedScript = duplicated;
    });
  }

  void _updateSelectedScript(VisualScript updated) {
    final updatedScripts = List<VisualScript>.from(widget.workspace.scripts);
    final idx = updatedScripts.indexWhere((s) => s.id == updated.id);
    if (idx != -1) {
      updatedScripts[idx] = updated;
      final updatedWorkspace = widget.workspace..scripts = updatedScripts;
      widget.onWorkspaceUpdated(updatedWorkspace);
      setState(() {
        _selectedScript = updated;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: 1000,
        height: 700,
        child: Column(
          children: [
            // Title Header with close button
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.settings_suggest_rounded,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Scripts Manager Library',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Close',
                    splashRadius: 20,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left sidebar: list of scripts
                  Material(
                    color: isDark
                        ? const Color(0xFF0F172A)
                        : const Color(0xFFF9FAFB),
                    child: Container(
                      width: 225,
                      decoration: BoxDecoration(
                        border: Border(right: BorderSide(color: borderColor)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // New Script Action Button
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: ElevatedButton.icon(
                              onPressed: _createNewScript,
                              icon: const Icon(Icons.add_rounded, size: 14),
                              label: const Text(
                                'New Script',
                                style: TextStyle(fontSize: 12),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                          const Divider(height: 1),
                          Expanded(
                            child: widget.workspace.scripts.isEmpty
                                ? Center(
                                    child: Text(
                                      'No scripts yet.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark
                                            ? AppColors.textSecondaryDark
                                            : AppColors.textSecondaryLight,
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: widget.workspace.scripts.length,
                                    itemBuilder: (context, index) {
                                      final script =
                                          widget.workspace.scripts[index];
                                      final isSelected =
                                          _selectedScript?.id == script.id;

                                      return ListTile(
                                        selected: isSelected,
                                        selectedTileColor: isDark
                                            ? AppColors.surfaceDark
                                            : AppColors.slate100,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 10.0,
                                              vertical: 2.0,
                                            ),
                                        horizontalTitleGap: 8.0,
                                        dense: true,
                                        leading: Icon(
                                          script.isPreRequest
                                              ? Icons.arrow_circle_up_rounded
                                              : Icons.arrow_circle_down_rounded,
                                          color: script.isPreRequest
                                              ? Colors.blue
                                              : Colors.orange,
                                          size: 18,
                                        ),
                                        title: Text(
                                          script.name,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            color: isSelected
                                                ? AppColors.primary
                                                : (isDark
                                                      ? AppColors.textDark
                                                      : AppColors.textLight),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        subtitle: Text(
                                          '${script.isPreRequest ? "Pre" : "Post"} • ${script.steps.length} steps',
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                        trailing: isSelected
                                            ? PopupMenuButton<String>(
                                                icon: const Icon(
                                                  Icons.more_vert_rounded,
                                                  size: 16,
                                                ),
                                                onSelected: (action) {
                                                  if (action == 'duplicate') {
                                                    _duplicateScript(script);
                                                  } else if (action ==
                                                      'delete') {
                                                    _deleteScript(script);
                                                  }
                                                },
                                                itemBuilder: (context) => [
                                                  const PopupMenuItem(
                                                    value: 'duplicate',
                                                    child: Text(
                                                      'Duplicate',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ),
                                                  const PopupMenuItem(
                                                    value: 'delete',
                                                    child: Text(
                                                      'Delete',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.red,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              )
                                            : null,
                                        onTap: () {
                                          setState(() {
                                            _selectedScript = script;
                                          });
                                        },
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Right side: Active Script builder/timeline
                  Expanded(
                    child: Container(
                      color: isDark
                          ? const Color(0xFF111827)
                          : const Color(0xFFF3F4F6),
                      child: _selectedScript == null
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.dashboard_customize_outlined,
                                    size: 64,
                                    color: isDark
                                        ? AppColors.borderDark
                                        : AppColors.slate300,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Select or create a script to edit settings.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark
                                          ? AppColors.textSecondaryDark
                                          : AppColors.textSecondaryLight,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Script Header Options
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller:
                                              TextEditingController(
                                                  text: _selectedScript!.name,
                                                )
                                                ..selection =
                                                    TextSelection.collapsed(
                                                      offset: _selectedScript!
                                                          .name
                                                          .length,
                                                    ),
                                          decoration: const InputDecoration(
                                            labelText: 'Script Name',
                                            border: InputBorder.none,
                                            focusedBorder: InputBorder.none,
                                          ),
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          onChanged: (val) {
                                            _updateSelectedScript(
                                              _selectedScript!.copyWith(
                                                name: val,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 24),
                                      DropdownButton<bool>(
                                        value: _selectedScript!.isPreRequest,
                                        dropdownColor: isDark
                                            ? AppColors.surfaceDark
                                            : Colors.white,
                                        items: const [
                                          DropdownMenuItem(
                                            value: true,
                                            child: Text(
                                              'Pre-Request',
                                              style: TextStyle(fontSize: 12),
                                            ),
                                          ),
                                          DropdownMenuItem(
                                            value: false,
                                            child: Text(
                                              'Post-Response',
                                              style: TextStyle(fontSize: 12),
                                            ),
                                          ),
                                        ],
                                        onChanged: (val) {
                                          if (val != null) {
                                            _updateSelectedScript(
                                              _selectedScript!.copyWith(
                                                isPreRequest: val,
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                      const SizedBox(width: 16),
                                      DropdownButton<ScriptMode>(
                                        value: _selectedScript!.mode,
                                        dropdownColor: isDark
                                            ? AppColors.surfaceDark
                                            : Colors.white,
                                        items: const [
                                          DropdownMenuItem(
                                            value: ScriptMode.lowCode,
                                            child: Text(
                                              'Basic (Low-Code)',
                                              style: TextStyle(fontSize: 12),
                                            ),
                                          ),
                                          DropdownMenuItem(
                                            value: ScriptMode.advanced,
                                            child: Text(
                                              'Advanced (Code)',
                                              style: TextStyle(fontSize: 12),
                                            ),
                                          ),
                                        ],
                                        onChanged: (val) {
                                          if (val != null) {
                                            _updateSelectedScript(
                                              _selectedScript!.copyWith(
                                                mode: val,
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                const Divider(height: 1),

                                // Form body based on Basic/Advanced select
                                Expanded(
                                  child:
                                      _selectedScript!.mode ==
                                          ScriptMode.advanced
                                      ? _buildAdvancedModePlaceholder(isDark)
                                      : LowCodeStepEditor(
                                          script: _selectedScript!,
                                          onChanged: _updateSelectedScript,
                                        ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedModePlaceholder(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.code_off_rounded,
            size: 64,
            color: isDark ? AppColors.borderDark : AppColors.slate300,
          ),
          const SizedBox(height: 16),
          const Text(
            'Advanced Script Code Editor (Dart Sandbox DSL)',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Coming soon in beta. Use Basic (Low-Code) mode to configure steps visual workflows.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}
