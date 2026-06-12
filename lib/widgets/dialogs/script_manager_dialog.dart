// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import '../../models/visual_script.dart';
import '../../models/workspace_models.dart';
import '../../theme/app_colors.dart';
import '../../utils/script_compiler.dart';
import '../script_steps/flowchart_canvas.dart';

import '../script_steps/forms/set_variable_step_form.dart';
import '../script_steps/forms/assert_value_step_form.dart';
import '../script_steps/forms/if_step_form.dart';
import '../script_steps/forms/send_request_step_form.dart';
import '../script_steps/forms/delay_step_form.dart';
import '../script_steps/forms/switch_step_form.dart';
import '../script_steps/forms/merge_step_form.dart';
import '../script_steps/forms/split_out_step_form.dart';
import '../script_steps/forms/aggregate_step_form.dart';
import '../script_steps/forms/date_time_step_form.dart';
import '../script_steps/forms/sort_step_form.dart';
import '../script_steps/forms/limit_step_form.dart';
import '../script_steps/forms/remove_duplicates_step_form.dart';
import '../script_steps/forms/crypto_step_form.dart';
import '../script_steps/forms/json_convert_step_form.dart';
import '../script_steps/forms/xml_convert_step_form.dart';
import '../script_steps/forms/html_convert_step_form.dart';
import '../script_steps/forms/markdown_convert_step_form.dart';
import '../script_steps/forms/json_path_step_form.dart';
import '../script_steps/forms/header_builder_step_form.dart';
import '../script_steps/forms/start_step_form.dart';
import '../script_steps/forms/fail_step_form.dart';
import '../script_steps/forms/end_step_form.dart';

class ScriptManagerDialog extends StatefulWidget {
  final WorkspaceModel workspace;
  final ValueChanged<WorkspaceModel> onWorkspaceUpdated;
  /// Slim request refs built by the call site from RequestProvider.collections.
  /// Passed here to avoid loading full HttpRequest bodies in widget memory.
  final List<WorkspaceRequestRef> availableRequests;

  // Global visual persistence variables for sidebar visibilities
  static bool showLeftSidebar = true;
  static bool showRightSidebar = true;

  const ScriptManagerDialog({
    super.key,
    required this.workspace,
    required this.onWorkspaceUpdated,
    this.availableRequests = const [],
  });

  @override
  State<ScriptManagerDialog> createState() => _ScriptManagerDialogState();
}

class _ScriptManagerDialogState extends State<ScriptManagerDialog> {
  VisualScript? _selectedScript;
  String? _selectedNodeId;

  void _createNewScript() {
    final startNode = StartStep(name: 'Start');
    final newScript = VisualScript(
      name: 'New Script ${_getUniqueIndex()}',
      isPreRequest: true,
      mode: ScriptMode.lowCode,
      nodes: {startNode.id: startNode},
      startNodeId: startNode.id,
    );

    final updatedScripts = List<VisualScript>.from(widget.workspace.scripts)
      ..add(newScript);
    final updatedWorkspace = widget.workspace..scripts = updatedScripts;

    widget.onWorkspaceUpdated(updatedWorkspace);
    setState(() {
      _selectedScript = newScript;
      _selectedNodeId = null;
    });
  }

  int _getUniqueIndex() {
    return widget.workspace.scripts.length + 1;
  }

  void _deleteScript(VisualScript script) {
    final updatedScripts = List<VisualScript>.from(widget.workspace.scripts)
      ..removeWhere((s) => s.id == script.id);

    final updatedActiveIds = List<String>.from(widget.workspace.activeScriptIds)
      ..remove(script.id);

    final updatedWorkspace = widget.workspace
      ..scripts = updatedScripts
      ..activeScriptIds = updatedActiveIds;

    widget.onWorkspaceUpdated(updatedWorkspace);
    setState(() {
      if (_selectedScript?.id == script.id) {
        _selectedScript = null;
        _selectedNodeId = null;
      }
    });
  }

  void _duplicateScript(VisualScript script) {
    final duplicated = VisualScript(
      name: '${script.name} Copy',
      isPreRequest: script.isPreRequest,
      mode: script.mode,
      nodes: Map.from(script.nodes),
      startNodeId: script.startNodeId,
      advancedCode: script.advancedCode,
    );

    final updatedScripts = List<VisualScript>.from(widget.workspace.scripts)
      ..add(duplicated);
    final updatedWorkspace = widget.workspace..scripts = updatedScripts;

    widget.onWorkspaceUpdated(updatedWorkspace);
    setState(() {
      _selectedScript = duplicated;
      _selectedNodeId = null;
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

  void _updateNode(String nodeId, VisualStep updatedStep) {
    if (_selectedScript == null) return;
    final Map<String, VisualStep> updatedNodes = Map.from(_selectedScript!.nodes);
    updatedNodes[nodeId] = updatedStep;
    _updateSelectedScript(_selectedScript!.copyWith(
      nodes: updatedNodes,
      updatedAt: DateTime.now(),
    ));
  }

  void _autoFillFailSteps() {
    final List<VisualScript> updatedScripts = [];
    bool anyChanged = false;

    for (var script in widget.workspace.scripts) {
      final Map<String, VisualStep> updatedNodes = Map.from(script.nodes);
      bool scriptChanged = false;

      for (var entry in script.nodes.entries) {
        final nodeId = entry.key;
        final node = entry.value;

        if (node is IfStep) {
          String? trueId = node.trueStepId;
          if (trueId == null || trueId.isEmpty) {
            final failNodeId = UniqueKey().toString();
            final failStep = FailStep(
              id: failNodeId,
              name: 'Fail',
            );
            updatedNodes[failNodeId] = failStep;
            final updatedNode = IfStep.fromJson(node.toJson())..trueStepId = failNodeId;
            updatedNodes[nodeId] = updatedNode;
            scriptChanged = true;
          }
          final currentNode = updatedNodes[nodeId] as IfStep;
          String? falseId = currentNode.falseStepId;
          if (falseId == null || falseId.isEmpty) {
            final failNodeId = UniqueKey().toString();
            final failStep = FailStep(
              id: failNodeId,
              name: 'Fail',
            );
            updatedNodes[failNodeId] = failStep;
            final updatedNode = IfStep.fromJson(currentNode.toJson())..falseStepId = failNodeId;
            updatedNodes[nodeId] = updatedNode;
            scriptChanged = true;
          }
        } else if (node is SwitchStep) {
          final List<SwitchCase> updatedCases = [];
          bool switchChanged = false;

          for (var c in node.cases) {
            String? caseNextId = c.nextStepId;
            if (caseNextId == null || caseNextId.isEmpty) {
              final failNodeId = UniqueKey().toString();
              final failStep = FailStep(
                id: failNodeId,
                name: 'Fail',
              );
              updatedNodes[failNodeId] = failStep;
              updatedCases.add(SwitchCase(value: c.value, nextStepId: failNodeId));
              switchChanged = true;
            } else {
              updatedCases.add(c);
            }
          }

          String? newDefaultStepId = node.defaultStepId;
          if (newDefaultStepId == null || newDefaultStepId.isEmpty) {
            final failNodeId = UniqueKey().toString();
            final failStep = FailStep(
              id: failNodeId,
              name: 'Fail',
            );
            updatedNodes[failNodeId] = failStep;
            newDefaultStepId = failNodeId;
            switchChanged = true;
          }

          if (switchChanged) {
            final updatedNode = SwitchStep.fromJson(node.toJson())
              ..cases = updatedCases
              ..defaultStepId = newDefaultStepId;
            updatedNodes[nodeId] = updatedNode;
            scriptChanged = true;
          }
        }
      }

      if (scriptChanged) {
        updatedScripts.add(script.copyWith(
          nodes: updatedNodes,
          updatedAt: DateTime.now(),
        ));
        anyChanged = true;
      } else {
        updatedScripts.add(script);
      }
    }

    if (anyChanged) {
      widget.workspace.scripts = updatedScripts;
      widget.onWorkspaceUpdated(widget.workspace);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    final screenSize = MediaQuery.of(context).size;
    final dialogWidth = screenSize.width * 0.95;
    final dialogHeight = screenSize.height * 0.90;

    return WillPopScope(
      onWillPop: () async {
        _autoFillFailSteps();
        return true;
      },
      child: Dialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: dialogWidth,
        height: dialogHeight,
        child: Column(
          children: [
            // Title Header Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  Icon(Icons.settings_suggest_rounded, color: isDark ? Colors.white70 : Colors.black87),
                  const SizedBox(width: 8),
                  Text(
                    'E2E Script Automation',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  // Toggle Left Sidebar Button
                  IconButton(
                    icon: Icon(
                      ScriptManagerDialog.showLeftSidebar ? Icons.keyboard_tab_rounded : Icons.menu_open_rounded,
                      size: 20,
                    ),
                    tooltip: ScriptManagerDialog.showLeftSidebar ? 'Hide Library' : 'Show Library',
                    onPressed: () {
                      setState(() {
                        ScriptManagerDialog.showLeftSidebar = !ScriptManagerDialog.showLeftSidebar;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  // Toggle Right Sidebar Button
                  IconButton(
                    icon: Icon(
                      ScriptManagerDialog.showRightSidebar ? Icons.chrome_reader_mode_outlined : Icons.chrome_reader_mode_rounded,
                      size: 20,
                    ),
                    tooltip: ScriptManagerDialog.showRightSidebar ? 'Hide Properties' : 'Show Properties',
                    onPressed: () {
                      setState(() {
                        ScriptManagerDialog.showRightSidebar = !ScriptManagerDialog.showRightSidebar;
                      });
                    },
                  ),
                  const SizedBox(width: 12),
                  // Divider
                  Container(width: 1, height: 24, color: borderColor),
                  const SizedBox(width: 12),
                  // Close Dialog Button
                  IconButton(
                    onPressed: () {
                      _autoFillFailSteps();
                      Navigator.pop(context);
                    },
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
                  // Left Sidebar: Library list of scripts
                  if (ScriptManagerDialog.showLeftSidebar)
                    Material(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
                      child: Container(
                        width: 220,
                        decoration: BoxDecoration(border: Border(right: BorderSide(color: borderColor))),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: ElevatedButton.icon(
                                onPressed: _createNewScript,
                                icon: const Icon(Icons.add_rounded, size: 14),
                                label: const Text('New Script', style: TextStyle(fontSize: 12)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                            const Divider(height: 1),
                            Expanded(
                              child: widget.workspace.scripts.isEmpty
                                  ? const Center(
                                      child: Text(
                                        'No scripts registered.',
                                        style: TextStyle(fontSize: 11, color: Colors.grey),
                                      ),
                                    )
                                  : ListView.builder(
                                      itemCount: widget.workspace.scripts.length,
                                      itemBuilder: (context, index) {
                                        final script = widget.workspace.scripts[index];
                                        final isSelected = _selectedScript?.id == script.id;

                                        return ListTile(
                                          selected: isSelected,
                                          selectedTileColor: isDark ? AppColors.surfaceDark : AppColors.slate100,
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 2.0),
                                          horizontalTitleGap: 8.0,
                                          dense: true,
                                          leading: Icon(
                                            script.isPreRequest
                                                ? Icons.arrow_circle_up_rounded
                                                : Icons.arrow_circle_down_rounded,
                                            color: script.isPreRequest ? Colors.blue : Colors.orange,
                                            size: 18,
                                          ),
                                          title: Text(
                                            script.name,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                              color: isSelected
                                                  ? AppColors.primary
                                                  : (isDark ? AppColors.textDark : AppColors.textLight),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          subtitle: Text(
                                            '${script.isPreRequest ? "Pre" : "Post"} • ${script.nodes.length} nodes',
                                            style: const TextStyle(fontSize: 10),
                                          ),
                                          trailing: isSelected
                                              ? PopupMenuButton<String>(
                                                  icon: const Icon(Icons.more_vert_rounded, size: 16),
                                                  onSelected: (action) {
                                                    if (action == 'duplicate') {
                                                      _duplicateScript(script);
                                                    } else if (action == 'delete') {
                                                      _deleteScript(script);
                                                    }
                                                  },
                                                  itemBuilder: (context) => [
                                                    const PopupMenuItem(value: 'duplicate', child: Text('Duplicate', style: TextStyle(fontSize: 12))),
                                                    const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(fontSize: 12, color: Colors.red))),
                                                  ],
                                                )
                                              : null,
                                          onTap: () {
                                            setState(() {
                                              _selectedScript = script;
                                              _selectedNodeId = null;
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

                  // Center: 2D Canvas + Right properties sidebar
                  Expanded(
                    child: _selectedScript == null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.dashboard_customize_outlined, size: 64, color: isDark ? AppColors.borderDark : AppColors.slate300),
                                const SizedBox(height: 16),
                                const Text(
                                  'Select or create a script to edit its flowchart.',
                                  style: TextStyle(fontSize: 13, color: Colors.grey),
                                ),
                              ],
                            ),
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // 2D Flowchart Canvas
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    // Sub-header controls (Name and settings)
                                    Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: TextField(
                                              controller: TextEditingController(text: _selectedScript!.name)
                                                ..selection = TextSelection.collapsed(offset: _selectedScript!.name.length),
                                              decoration: InputDecoration(
                                                hintText: 'Script Name',
                                                isDense: true,
                                                contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                                                enabledBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(6),
                                                  borderSide: BorderSide(color: borderColor),
                                                ),
                                                focusedBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(6),
                                                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                                                ),
                                              ),
                                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                              onChanged: (val) {
                                                _updateSelectedScript(_selectedScript!.copyWith(name: val));
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          DropdownButton<bool>(
                                            value: _selectedScript!.isPreRequest,
                                            dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
                                            items: const [
                                              DropdownMenuItem(value: true, child: Text('Pre-Request', style: TextStyle(fontSize: 12))),
                                              DropdownMenuItem(value: false, child: Text('Post-Response', style: TextStyle(fontSize: 12))),
                                            ],
                                            onChanged: (val) {
                                              if (val != null) {
                                                _updateSelectedScript(_selectedScript!.copyWith(isPreRequest: val));
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Divider(height: 1),
                                    Expanded(
                                      child: FlowchartCanvas(
                                        script: _selectedScript!,
                                        selectedNodeId: _selectedNodeId,
                                        onSelectNode: (id) {
                                          setState(() {
                                            _selectedNodeId = id;
                                          });
                                        },
                                        onDoubleSelectNode: (id) {
                                          setState(() {
                                            _selectedNodeId = id;
                                            ScriptManagerDialog.showRightSidebar = true;
                                          });
                                        },
                                        onChanged: _updateSelectedScript,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Right Sidebar: Node properties form
                              if (ScriptManagerDialog.showRightSidebar) ...[
                                VerticalDivider(width: 1, color: borderColor),
                                Container(
                                  width: 300,
                                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
                                  child: _selectedNodeId == null || !_selectedScript!.nodes.containsKey(_selectedNodeId)
                                      ? const Center(
                                          child: Text(
                                            'Select a node in the canvas\nto edit properties.',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(fontSize: 11, color: Colors.grey),
                                          ),
                                        )
                                      : _buildPropertiesPanel(isDark, borderColor),
                                ),
                              ],
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildPropertiesPanel(bool isDark, Color borderColor) {
    final nodeId = _selectedNodeId!;
    final node = _selectedScript!.nodes[nodeId]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Panel Header
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Icon(Icons.tune_rounded, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text(
                'Node Properties',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(12.0),
            children: [
              // Customizable Node Name
              TextField(
                controller: TextEditingController(text: node.name)
                  ..selection = TextSelection.collapsed(offset: node.name.length),
                decoration: const InputDecoration(
                  labelText: 'Node Name',
                  labelStyle: TextStyle(fontSize: 11),
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                onChanged: (val) {
                  node.name = val;
                  _updateNode(nodeId, node);
                },
              ),
              const SizedBox(height: 16),
              // Type-specific configs
              _buildNodeSpecificFields(nodeId, node, isDark, borderColor),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNodeSpecificFields(String nodeId, VisualStep node, bool isDark, Color borderColor) {
    if (node is SetVariableStep) {
      return SetVariableStepForm(nodeId: nodeId, node: node, borderColor: borderColor, onUpdated: _updateNode);
    } else if (node is AssertValueStep) {
      return AssertValueStepForm(nodeId: nodeId, node: node, onUpdated: _updateNode);
    } else if (node is IfStep) {
      return IfStepForm(nodeId: nodeId, node: node, onUpdated: _updateNode);
    } else if (node is SendRequestStep) {
      return SendRequestStepForm(
        nodeId: nodeId,
        node: node,
        onUpdated: _updateNode,
        availableRequests: widget.availableRequests,
      );
    } else if (node is DelayStep) {
      return DelayStepForm(nodeId: nodeId, node: node, onUpdated: _updateNode);
    } else if (node is SwitchStep) {
      return SwitchStepForm(nodeId: nodeId, node: node, onUpdated: _updateNode);
    } else if (node is MergeStep) {
      return MergeStepForm(nodeId: nodeId, node: node, borderColor: borderColor, onUpdated: _updateNode);
    } else if (node is SplitOutStep) {
      return SplitOutStepForm(nodeId: nodeId, node: node, onUpdated: _updateNode);
    } else if (node is AggregateStep) {
      return AggregateStepForm(nodeId: nodeId, node: node, onUpdated: _updateNode);
    } else if (node is DateTimeStep) {
      return DateTimeStepForm(nodeId: nodeId, node: node, onUpdated: _updateNode);
    } else if (node is SortStep) {
      return SortStepForm(nodeId: nodeId, node: node, onUpdated: _updateNode);
    } else if (node is LimitStep) {
      return LimitStepForm(nodeId: nodeId, node: node, onUpdated: _updateNode);
    } else if (node is RemoveDuplicatesStep) {
      return RemoveDuplicatesStepForm(nodeId: nodeId, node: node, onUpdated: _updateNode);
    } else if (node is CryptoStep) {
      return CryptoStepForm(nodeId: nodeId, node: node, onUpdated: _updateNode);
    } else if (node is JsonConvertStep) {
      return JsonConvertStepForm(nodeId: nodeId, node: node, onUpdated: _updateNode);
    } else if (node is XmlConvertStep) {
      return XmlConvertStepForm(nodeId: nodeId, node: node, onUpdated: _updateNode);
    } else if (node is HtmlConvertStep) {
      return HtmlConvertStepForm(nodeId: nodeId, node: node, onUpdated: _updateNode);
    } else if (node is MarkdownConvertStep) {
      return MarkdownConvertStepForm(nodeId: nodeId, node: node, onUpdated: _updateNode);
    } else if (node is JsonPathStep) {
      return JsonPathStepForm(nodeId: nodeId, node: node, onUpdated: _updateNode);
    } else if (node is HeaderBuilderStep) {
      return HeaderBuilderStepForm(nodeId: nodeId, node: node, borderColor: borderColor, onUpdated: _updateNode);
    } else if (node is StartStep) {
      return StartStepForm(nodeId: nodeId, node: node, onUpdated: _updateNode);
    } else if (node is FailStep) {
      return FailStepForm(nodeId: nodeId, node: node, onUpdated: _updateNode);
    } else if (node is EndStep) {
      return EndStepForm(nodeId: nodeId, node: node, onUpdated: _updateNode);
    }
    return const SizedBox.shrink();
  }
}
