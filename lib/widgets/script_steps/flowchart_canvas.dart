import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/visual_script.dart';
import '../../theme/app_colors.dart';
import '../../utils/script_compiler.dart';
import 'node_selector_dialog.dart';

double getNodeHeight(VisualStep node) {
  if (node is SwitchStep) {
    return 36.0 + (node.cases.length + 1) * 28.0 + 8.0;
  }
  return 70.0;
}

double getOutputYOffset(VisualStep node, String connectionType, {String? switchCaseVal}) {
  if (node is SwitchStep) {
    if (connectionType == 'switch_default') {
      return 36.0 + node.cases.length * 28.0 + 14.0;
    } else if (connectionType == 'switch_case' && switchCaseVal != null) {
      final idx = node.cases.indexWhere((c) => c.value == switchCaseVal);
      if (idx != -1) {
        return 36.0 + idx * 28.0 + 14.0;
      }
    }
    return 36.0 + 14.0;
  }
  const double nodeH = 70.0;
  if (node is IfStep) {
    if (connectionType == 'true') return nodeH / 4;
    if (connectionType == 'false') return (nodeH * 3) / 4;
  }
  if (node is SplitOutStep) {
    if (connectionType == 'loop') return nodeH / 4;
    if (connectionType == 'next') return (nodeH * 3) / 4;
  }
  return nodeH / 2;
}

int getNodeRowSpan(VisualStep node) {
  final height = getNodeHeight(node);
  return (height / 110.0).ceil();
}

class FlowchartLayoutManager {
  final Map<String, Point<int>> gridPositions = {};
  final Set<String> visited = {};
  final Map<int, Set<int>> occupiedCells = {}; // col -> set of rows

  void calculate(VisualScript script) {
    gridPositions.clear();
    visited.clear();
    occupiedCells.clear();
    if (script.startNodeId == null || script.nodes[script.startNodeId] == null) return;
    _layoutNode(script, script.startNodeId!, 0, 0);

    // Layout orphaned nodes below the main flow
    script.nodes.forEach((id, node) {
      if (!visited.contains(id)) {
        int maxOccupiedRow = -1;
        occupiedCells.forEach((col, rows) {
          for (var r in rows) {
            if (r > maxOccupiedRow) maxOccupiedRow = r;
          }
        });
        int startRow = maxOccupiedRow + 2;
        _layoutNode(script, id, 0, startRow);
      }
    });
  }

  void _layoutNode(VisualScript script, String nodeId, int col, int row) {
    if (visited.contains(nodeId)) return;
    visited.add(nodeId);

    final node = script.nodes[nodeId];
    if (node == null) return;

    // Resolve collision taking row span into account
    int targetRow = row;
    int span = getNodeRowSpan(node);
    bool hasCollision = true;

    while (hasCollision) {
      hasCollision = false;
      for (int r = 0; r < span; r++) {
        if (isCellOccupied(col, targetRow + r)) {
          hasCollision = true;
          break;
        }
      }
      if (hasCollision) {
        targetRow++;
      }
    }

    for (int r = 0; r < span; r++) {
      occupyCell(col, targetRow + r);
    }
    gridPositions[nodeId] = Point(col, targetRow);

    if (node is IfStep) {
      if (node.trueStepId != null && node.trueStepId!.isNotEmpty) {
        _layoutNode(script, node.trueStepId!, col + 1, targetRow);
      }
      if (node.falseStepId != null && node.falseStepId!.isNotEmpty) {
        _layoutNode(script, node.falseStepId!, col + 1, targetRow + 1);
      }
    } else if (node is SwitchStep) {
      int offset = 0;
      for (var caseItem in node.cases) {
        if (caseItem.nextStepId != null && caseItem.nextStepId!.isNotEmpty) {
          _layoutNode(script, caseItem.nextStepId!, col + 1, targetRow + offset);
          offset++;
        }
      }
      if (node.defaultStepId != null && node.defaultStepId!.isNotEmpty) {
        _layoutNode(script, node.defaultStepId!, col + 1, targetRow + offset);
      }
    } else if (node is SplitOutStep) {
      if (node.loopStepId != null && node.loopStepId!.isNotEmpty) {
        _layoutNode(script, node.loopStepId!, col + 1, targetRow + 1);
      }
      if (node.nextStepId != null && node.nextStepId!.isNotEmpty) {
        _layoutNode(script, node.nextStepId!, col + 1, targetRow);
      }
    } else {
      if (node.nextStepId != null && node.nextStepId!.isNotEmpty) {
        _layoutNode(script, node.nextStepId!, col + 1, targetRow);
      }
    }
  }

  bool isCellOccupied(int col, int row) {
    return occupiedCells[col]?.contains(row) ?? false;
  }

  void occupyCell(int col, int row) {
    occupiedCells.putIfAbsent(col, () => {}).add(row);
  }
}

class FlowchartCanvas extends StatefulWidget {
  final VisualScript script;
  final ExecutionContext? lastExecutionContext;
  final String? selectedNodeId;
  final ValueChanged<String?> onSelectNode;
  final ValueChanged<String?> onDoubleSelectNode;
  final ValueChanged<VisualScript> onChanged;

  const FlowchartCanvas({
    super.key,
    required this.script,
    this.lastExecutionContext,
    this.selectedNodeId,
    required this.onSelectNode,
    required this.onDoubleSelectNode,
    required this.onChanged,
  });

  @override
  State<FlowchartCanvas> createState() => _FlowchartCanvasState();
}

class _FlowchartCanvasState extends State<FlowchartCanvas> {
  final FlowchartLayoutManager _layoutManager = FlowchartLayoutManager();
  bool _topologyChanged = true;
  String? _hoveredNodeId;
  TapDownDetails? _tapDownDetails;

  @override
  void didUpdateWidget(covariant FlowchartCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.script.nodes.length != widget.script.nodes.length ||
        oldWidget.script.startNodeId != widget.script.startNodeId ||
        oldWidget.script.updatedAt != widget.script.updatedAt) {
      _topologyChanged = true;
    }
  }

  void _calculateLayoutIfNeeded() {
    if (_topologyChanged) {
      _layoutManager.calculate(widget.script);
      _topologyChanged = false;
    }
  }

  void _addNode(String parentId, String connectionType, VisualStepType type, {String? switchCaseVal}) {
    final newStepId = UniqueKey().toString();
    VisualStep newStep;

    switch (type) {
      case VisualStepType.setVariable:
        newStep = SetVariableStep(
          id: newStepId,
          name: 'Assign Variables',
          assignments: [VariableAssignment(variableName: 'var_name', valueSource: ValueSource(type: ValueSourceType.constant, key: 'value'))],
        );
        break;
      case VisualStepType.assertValue:
        newStep = AssertValueStep(
          id: newStepId,
          name: 'Assert Value',
          leftSource: ValueSource(type: ValueSourceType.responseStatusCode),
          operator: '==',
          rightSource: ValueSource(type: ValueSourceType.constant, key: '200'),
        );
        break;
      case VisualStepType.sendRequest:
        newStep = SendRequestStep(
          id: newStepId,
          name: 'HTTP Request',
          method: 'GET',
          url: 'https://api.example.com',
        );
        break;
      case VisualStepType.delay:
        newStep = DelayStep(
          id: newStepId,
          name: 'Delay',
          durationMs: 1000,
        );
        break;
      case VisualStepType.switchStep:
        newStep = SwitchStep(
          id: newStepId,
          name: 'Switch',
          cases: [SwitchCase(value: '200'), SwitchCase(value: '404')],
        );
        break;
      case VisualStepType.merge:
        newStep = MergeStep(
          id: newStepId,
          name: 'Merge',
          strategy: 'deepMerge',
          sources: [],
          saveTo: 'merged_result',
        );
        break;
      case VisualStepType.splitOut:
        newStep = SplitOutStep(
          id: newStepId,
          name: 'Split Out',
          arraySource: ValueSource(type: ValueSourceType.responseBody, jsonPath: 'items'),
          runInParallel: false,
          maxConcurrency: 5,
        );
        break;
      case VisualStepType.aggregate:
        newStep = AggregateStep(
          id: newStepId,
          name: 'Aggregate',
          itemSource: ValueSource(type: ValueSourceType.responseBody),
          targetListVariable: 'list_result',
        );
        break;
      case VisualStepType.dateTime:
        newStep = DateTimeStep(
          id: newStepId,
          name: 'Date & Time',
          operation: 'current',
          formatPattern: 'yyyy-MM-dd HH:mm:ss',
          saveToVariable: 'now',
        );
        break;
      case VisualStepType.ifStep:
        newStep = IfStep(
          id: newStepId,
          name: 'IF Condition',
          leftSource: ValueSource(type: ValueSourceType.responseStatusCode),
          operator: '==',
          rightSource: ValueSource(type: ValueSourceType.constant, key: '200'),
        );
        break;
      case VisualStepType.sort:
        newStep = SortStep(
          id: newStepId,
          name: 'Sort List',
          arraySource: ValueSource(type: ValueSourceType.variable, key: 'list_result'),
          sortByPath: 'id',
          ascending: true,
          saveToVariable: 'sorted_list',
        );
        break;
      case VisualStepType.limit:
        newStep = LimitStep(
          id: newStepId,
          name: 'Limit List',
          arraySource: ValueSource(type: ValueSourceType.variable, key: 'list_result'),
          limit: 10,
          offset: 0,
          saveToVariable: 'limited_list',
        );
        break;
      case VisualStepType.removeDuplicates:
        newStep = RemoveDuplicatesStep(
          id: newStepId,
          name: 'Remove Duplicates',
          arraySource: ValueSource(type: ValueSourceType.variable, key: 'list_result'),
          comparePath: 'id',
          saveToVariable: 'unique_list',
        );
        break;
      case VisualStepType.crypto:
        newStep = CryptoStep(
          id: newStepId,
          name: 'Crypto Hash',
          operation: 'hashSHA256',
          valueSource: ValueSource(type: ValueSourceType.constant, key: 'payload'),
          saveToVariable: 'hashed_val',
        );
        break;
      case VisualStepType.jsonConvert:
        newStep = JsonConvertStep(
          id: newStepId,
          name: 'JSON Convert',
          operation: 'deserialize',
          valueSource: ValueSource(type: ValueSourceType.responseBody),
          saveToVariable: 'json_obj',
        );
        break;
      case VisualStepType.xmlConvert:
        newStep = XmlConvertStep(
          id: newStepId,
          name: 'XML Convert',
          operation: 'xmlToJson',
          valueSource: ValueSource(type: ValueSourceType.responseBody),
          saveToVariable: 'json_from_xml',
        );
        break;
      case VisualStepType.htmlConvert:
        newStep = HtmlConvertStep(
          id: newStepId,
          name: 'HTML Extract',
          operation: 'htmlToText',
          valueSource: ValueSource(type: ValueSourceType.responseBody),
          selector: 'div.content',
          attribute: 'href',
          saveToVariable: 'extracted_html',
        );
        break;
      case VisualStepType.markdownConvert:
        newStep = MarkdownConvertStep(
          id: newStepId,
          name: 'Markdown Convert',
          operation: 'markdownToHtml',
          valueSource: ValueSource(type: ValueSourceType.constant, key: '# Hello'),
          saveToVariable: 'html_output',
        );
        break;
      case VisualStepType.jsonPathStep:
        newStep = JsonPathStep(
          id: newStepId,
          name: 'JSON Path',
          valueSource: ValueSource(type: ValueSourceType.responseBody),
          jsonPathExpression: 'users[0].name',
          saveToVariable: 'extracted_field',
        );
        break;
      case VisualStepType.headerBuilder:
        newStep = HeaderBuilderStep(
          id: newStepId,
          name: 'Header Builder',
          authType: 'none',
          tokenSource: ValueSource(type: ValueSourceType.constant, key: ''),
          additionalHeaders: {'Content-Type': 'application/json'},
          saveToVariable: 'custom_headers',
        );
        break;
      case VisualStepType.start:
        newStep = StartStep(
          id: newStepId,
          name: 'Start',
        );
        break;
    }

    final Map<String, VisualStep> updatedNodes = Map.from(widget.script.nodes);
    final parent = updatedNodes[parentId];
    String? oldChildId;

    if (parent != null) {
      if (connectionType == 'next') {
        oldChildId = parent.nextStepId;
        parent.nextStepId = newStepId;
      } else if (connectionType == 'true' && parent is IfStep) {
        oldChildId = parent.trueStepId;
        parent.trueStepId = newStepId;
      } else if (connectionType == 'false' && parent is IfStep) {
        oldChildId = parent.falseStepId;
        parent.falseStepId = newStepId;
      } else if (connectionType == 'loop' && parent is SplitOutStep) {
        oldChildId = parent.loopStepId;
        parent.loopStepId = newStepId;
      } else if (connectionType == 'switch_case' && parent is SwitchStep && switchCaseVal != null) {
        final idx = parent.cases.indexWhere((c) => c.value == switchCaseVal);
        if (idx != -1) {
          oldChildId = parent.cases[idx].nextStepId;
          parent.cases[idx].nextStepId = newStepId;
        }
      } else if (connectionType == 'switch_default' && parent is SwitchStep) {
        oldChildId = parent.defaultStepId;
        parent.defaultStepId = newStepId;
      }
    }

    // Connect downstream nodes to heal chain (splicing)
    if (oldChildId != null && oldChildId.isNotEmpty) {
      newStep.nextStepId = oldChildId;
    }

    updatedNodes[newStepId] = newStep;

    widget.onChanged(widget.script.copyWith(
      nodes: updatedNodes,
      updatedAt: DateTime.now(),
    ));
    widget.onSelectNode(newStepId);
  }

  void _deleteNode(String id) {
    final nodeToDelete = widget.script.nodes[id];
    if (nodeToDelete?.type == VisualStepType.start) return;
    final Map<String, VisualStep> updatedNodes = Map.from(widget.script.nodes);
    updatedNodes.remove(id);

    // Heals connections pointing to deleted node
    updatedNodes.forEach((k, node) {
      if (node.nextStepId == id) {
        node.nextStepId = null;
      }
      if (node is IfStep) {
        if (node.trueStepId == id) node.trueStepId = null;
        if (node.falseStepId == id) node.falseStepId = null;
      }
      if (node is SwitchStep) {
        for (var c in node.cases) {
          if (c.nextStepId == id) c.nextStepId = null;
        }
        if (node.defaultStepId == id) node.defaultStepId = null;
      }
      if (node is SplitOutStep) {
        if (node.loopStepId == id) node.loopStepId = null;
      }
    });

    String? startNodeId = widget.script.startNodeId;
    if (startNodeId == id) {
      startNodeId = updatedNodes.keys.isNotEmpty ? updatedNodes.keys.first : null;
    }

    widget.onChanged(widget.script.copyWith(
      nodes: updatedNodes,
      startNodeId: startNodeId,
      updatedAt: DateTime.now(),
    ));
    if (widget.selectedNodeId == id) {
      widget.onSelectNode(null);
    }
  }

  void _renameNode(String id, String newName) {
    if (newName.trim().isEmpty) return;
    final Map<String, VisualStep> updatedNodes = Map.from(widget.script.nodes);
    final node = updatedNodes[id];
    if (node != null) {
      node.name = newName;
      widget.onChanged(widget.script.copyWith(
        nodes: updatedNodes,
        updatedAt: DateTime.now(),
      ));
    }
  }

  void _disconnectNode(String id) {
    final Map<String, VisualStep> updatedNodes = Map.from(widget.script.nodes);
    updatedNodes.forEach((k, node) {
      if (node.nextStepId == id) {
        node.nextStepId = null;
      }
      if (node is IfStep) {
        if (node.trueStepId == id) node.trueStepId = null;
        if (node.falseStepId == id) node.falseStepId = null;
      }
      if (node is SwitchStep) {
        for (var c in node.cases) {
          if (c.nextStepId == id) c.nextStepId = null;
        }
        if (node.defaultStepId == id) node.defaultStepId = null;
      }
      if (node is SplitOutStep) {
        if (node.loopStepId == id) node.loopStepId = null;
      }
    });

    widget.onChanged(widget.script.copyWith(
      nodes: updatedNodes,
      updatedAt: DateTime.now(),
    ));
  }

  bool _isPortConnected(VisualStep node, String connectionType, {String? switchCaseVal}) {
    if (connectionType == 'next') {
      return node.nextStepId != null && node.nextStepId!.isNotEmpty;
    } else if (connectionType == 'true' && node is IfStep) {
      return node.trueStepId != null && node.trueStepId!.isNotEmpty;
    } else if (connectionType == 'false' && node is IfStep) {
      return node.falseStepId != null && node.falseStepId!.isNotEmpty;
    } else if (connectionType == 'loop' && node is SplitOutStep) {
      return node.loopStepId != null && node.loopStepId!.isNotEmpty;
    } else if (connectionType == 'switch_case' && node is SwitchStep && switchCaseVal != null) {
      final idx = node.cases.indexWhere((c) => c.value == switchCaseVal);
      if (idx != -1) {
        return node.cases[idx].nextStepId != null && node.cases[idx].nextStepId!.isNotEmpty;
      }
    } else if (connectionType == 'switch_default' && node is SwitchStep) {
      return node.defaultStepId != null && node.defaultStepId!.isNotEmpty;
    }
    return false;
  }

  Widget _buildInsertionButton(String parentId, String connectionType, {String? switchCaseVal}) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () async {
          final selectedType = await showDialog<VisualStepType>(
            context: context,
            builder: (context) => const NodeSelectorDialog(),
          );
          if (!mounted) return;
          if (selectedType != null) {
            _addNode(parentId, connectionType, selectedType, switchCaseVal: switchCaseVal);
          }
        },
        child: Container(
          width: 18,
          height: 18,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF4B2BEE),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 3,
                offset: Offset(0, 1),
              )
            ],
          ),
          child: const Icon(Icons.add_rounded, size: 12, color: Colors.white),
        ),
      ),
    );
  }

  void _showNodeMenu(BuildContext context, String id, VisualStep node, Offset tapPos) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final RenderBox overlay = Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromLTWH(tapPos.dx, tapPos.dy, 0, 0),
      Offset.zero & overlay.size,
    );
    showMenu<String>(
      context: context,
      position: position,
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      items: [
        PopupMenuItem(
          value: 'rename',
          child: Text(
            'Rename Node',
            style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 13),
          ),
        ),
        PopupMenuItem(
          value: 'disconnect',
          child: Text(
            'Disconnect Node',
            style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 13),
          ),
        ),
        if (node.type != VisualStepType.start)
          const PopupMenuItem(
            value: 'delete',
            child: Text(
              'Delete Node',
              style: TextStyle(color: Colors.red, fontSize: 13),
            ),
          ),
      ],
    ).then((val) {
      if (!context.mounted) return;
      if (val == 'rename') {
        _showRenameDialog(context, id, node.name);
      } else if (val == 'disconnect') {
        _disconnectNode(id);
      } else if (val == 'delete') {
        _deleteNode(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    _calculateLayoutIfNeeded();

    if (widget.script.nodes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.schema_outlined, size: 48, color: isDark ? AppColors.slate500 : AppColors.slate400),
            const SizedBox(height: 16),
            const Text(
              'Empty Canvas. Add the first node to start.',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                final startId = UniqueKey().toString();
                final startNode = StartStep(id: startId, name: 'Start');
                widget.onChanged(widget.script.copyWith(
                  nodes: {startId: startNode},
                  startNodeId: startId,
                  updatedAt: DateTime.now(),
                ));
                widget.onSelectNode(startId);
              },
              icon: const Icon(Icons.add, size: 14),
              label: const Text('Add Start'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            )
          ],
        ),
      );
    }

    const double colWidth = 180.0;
    const double rowHeight = 110.0;
    const double nodeW = 140.0;
    const double startX = 30.0;
    const double startY = 30.0;

    int maxCol = 0;
    int maxRow = 0;

    final Map<String, Offset> pixelPositions = {};
    _layoutManager.gridPositions.forEach((id, p) {
      if (p.x > maxCol) maxCol = p.x;
      if (p.y > maxRow) maxRow = p.y;
      pixelPositions[id] = Offset(startX + p.x * colWidth, startY + p.y * rowHeight);
    });

    final canvasW = max(1000.0, (maxCol + 1) * colWidth + 100.0);
    double computedCanvasH = 0.0;
    pixelPositions.forEach((id, offset) {
      final node = widget.script.nodes[id];
      if (node != null) {
        final nodeH = getNodeHeight(node);
        if (offset.dy + nodeH > computedCanvasH) {
          computedCanvasH = offset.dy + nodeH;
        }
      }
    });
    final canvasH = max(600.0, computedCanvasH + 100.0);
    final canvasColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);

    return Container(
      color: canvasColor,
      child: InteractiveViewer(
        constrained: false,
        boundaryMargin: const EdgeInsets.all(100.0),
        minScale: 0.5,
        maxScale: 1.5,
        child: Container(
          width: canvasW,
          height: canvasH,
          color: canvasColor,
          child: Stack(
            children: [
              // Background connections layer
              Positioned.fill(
                child: CustomPaint(
                  painter: FlowchartPainter(
                    script: widget.script,
                    positions: pixelPositions,
                    nodeWidth: nodeW,
                    isDark: isDark,
                  ),
                ),
              ),
              // Nodes rendering
              ...widget.script.nodes.entries.map((entry) {
                final id = entry.key;
                final node = entry.value;
                final offset = pixelPositions[id] ?? Offset.zero;
                final isSelected = widget.selectedNodeId == id;
                final isHovered = _hoveredNodeId == id;
                final showInsertionButtons = isSelected || isHovered;
                final nodeH = getNodeHeight(node);

                IconData? statusIcon;
                Color? statusColor;
                if (widget.lastExecutionContext != null) {
                  final logs = widget.lastExecutionContext!.logs.where((l) => l.nodeId == id).toList();
                  if (logs.isNotEmpty) {
                    final hasError = logs.any((l) => l.level == LogLevel.error);
                    if (hasError) {
                      statusIcon = Icons.cancel_rounded;
                      statusColor = Colors.red;
                    } else {
                      statusIcon = Icons.check_circle_rounded;
                      statusColor = Colors.green;
                    }
                  }
                }

                return Positioned(
                  left: offset.dx,
                  top: offset.dy,
                  child: MouseRegion(
                    onEnter: (_) => setState(() => _hoveredNodeId = id),
                    onExit: (_) => setState(() {
                      if (_hoveredNodeId == id) _hoveredNodeId = null;
                    }),
                    child: GestureDetector(
                      onTapDown: (details) {
                        _tapDownDetails = details;
                      },
                      onTap: () {
                        widget.onSelectNode(id);
                        if (_tapDownDetails != null) {
                          _showNodeMenu(context, id, node, _tapDownDetails!.globalPosition);
                        }
                      },
                      onDoubleTap: () => widget.onDoubleSelectNode(id),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: nodeW,
                            height: nodeH,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF4B2BEE)
                                    : isDark
                                        ? const Color(0xFF334155)
                                        : const Color(0xFFE2E8F0),
                                width: isSelected ? 2.0 : 1.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                )
                              ],
                            ),
                            child: node is SwitchStep
                                ? Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      // Header
                                      Padding(
                                        padding: const EdgeInsets.only(left: 10, right: 10, top: 8, bottom: 4),
                                        child: Row(
                                          children: [
                                            Icon(_getStepIcon(node.type), size: 16, color: _getStepColor(node.type)),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                node.name,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: isDark ? Colors.white : Colors.black87,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Divider(height: 1, thickness: 0.5),
                                      // Cases list
                                      ...node.cases.map((c) => Container(
                                            height: 28,
                                            padding: const EdgeInsets.symmetric(horizontal: 10),
                                            alignment: Alignment.centerRight,
                                            child: Text(
                                              c.value,
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: isDark ? AppColors.slate300 : AppColors.slate700,
                                              ),
                                            ),
                                          )),
                                      // Default case
                                      Container(
                                        height: 28,
                                        padding: const EdgeInsets.symmetric(horizontal: 10),
                                        alignment: Alignment.centerRight,
                                        child: Text(
                                          'Default',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontStyle: FontStyle.italic,
                                            color: isDark ? AppColors.slate400 : AppColors.slate600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : Row(
                                    children: [
                                      const SizedBox(width: 10),
                                      Icon(_getStepIcon(node.type), size: 18, color: _getStepColor(node.type)),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              node.name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: isDark ? Colors.white : Colors.black87,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              _getStepTypeName(node.type),
                                              style: TextStyle(
                                                fontSize: 9,
                                                color: isDark ? AppColors.slate400 : AppColors.slate500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                    ],
                                  ),
                          ),
                          // Execution status indicator
                          if (statusIcon != null)
                            Positioned(
                              top: -6,
                              left: -6,
                              child: Icon(statusIcon, size: 14, color: statusColor),
                            ),
                          // Output Connection Ports
                          if (showInsertionButtons) ...[
                            if (node is IfStep) ...[
                              if (!_isPortConnected(node, 'true'))
                                Positioned(
                                  right: -9,
                                  top: getOutputYOffset(node, 'true') - 9,
                                  child: _buildInsertionButton(id, 'true'),
                                ),
                              if (!_isPortConnected(node, 'false'))
                                Positioned(
                                  right: -9,
                                  top: getOutputYOffset(node, 'false') - 9,
                                  child: _buildInsertionButton(id, 'false'),
                                ),
                            ] else if (node is SwitchStep) ...[
                              ...node.cases.asMap().entries.map((e) {
                                final c = e.value;
                                if (_isPortConnected(node, 'switch_case', switchCaseVal: c.value)) {
                                  return const SizedBox.shrink();
                                }
                                return Positioned(
                                  right: -9,
                                  top: getOutputYOffset(node, 'switch_case', switchCaseVal: c.value) - 9,
                                  child: Tooltip(
                                    message: 'Case: ${c.value}',
                                    child: _buildInsertionButton(id, 'switch_case', switchCaseVal: c.value),
                                  ),
                                );
                              }),
                              if (!_isPortConnected(node, 'switch_default'))
                                Positioned(
                                  right: -9,
                                  top: getOutputYOffset(node, 'switch_default') - 9,
                                  child: Tooltip(
                                    message: 'Default',
                                    child: _buildInsertionButton(id, 'switch_default'),
                                  ),
                                ),
                            ] else if (node is SplitOutStep) ...[
                              if (!_isPortConnected(node, 'loop'))
                                Positioned(
                                  right: -9,
                                  top: getOutputYOffset(node, 'loop') - 9,
                                  child: Tooltip(
                                    message: 'Loop Body',
                                    child: _buildInsertionButton(id, 'loop'),
                                  ),
                                ),
                              if (!_isPortConnected(node, 'next'))
                                Positioned(
                                  right: -9,
                                  top: getOutputYOffset(node, 'next') - 9,
                                  child: Tooltip(
                                    message: 'Next',
                                    child: _buildInsertionButton(id, 'next'),
                                  ),
                                ),
                            ] else ...[
                              if (!_isPortConnected(node, 'next'))
                                Positioned(
                                  right: -9,
                                  top: getOutputYOffset(node, 'next') - 9,
                                  child: _buildInsertionButton(id, 'next'),
                                ),
                            ]
                          ]
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _showRenameDialog(BuildContext context, String id, String currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Node', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'New node name'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              _renameNode(id, controller.text);
              Navigator.pop(context);
            },
            child: const Text('Rename'),
          )
        ],
      ),
    );
  }

  IconData _getStepIcon(VisualStepType type) {
    switch (type) {
      case VisualStepType.setVariable:
        return Icons.account_tree_outlined;
      case VisualStepType.assertValue:
        return Icons.fact_check_outlined;
      case VisualStepType.sendRequest:
        return Icons.http_outlined;
      case VisualStepType.start:
        return Icons.play_arrow_rounded;
      case VisualStepType.delay:
        return Icons.hourglass_top_outlined;
      case VisualStepType.switchStep:
        return Icons.call_split_rounded;
      case VisualStepType.merge:
        return Icons.merge_type_rounded;
      case VisualStepType.splitOut:
        return Icons.repeat_rounded;
      case VisualStepType.aggregate:
        return Icons.widgets_outlined;
      case VisualStepType.dateTime:
        return Icons.date_range_outlined;
      case VisualStepType.ifStep:
        return Icons.help_outline_rounded;
      case VisualStepType.sort:
        return Icons.sort_rounded;
      case VisualStepType.limit:
        return Icons.filter_list_rounded;
      case VisualStepType.removeDuplicates:
        return Icons.copy_all_outlined;
      case VisualStepType.crypto:
        return Icons.lock_outline_rounded;
      case VisualStepType.jsonConvert:
        return Icons.settings_ethernet_rounded;
      case VisualStepType.xmlConvert:
        return Icons.code_rounded;
      case VisualStepType.htmlConvert:
        return Icons.html_rounded;
      case VisualStepType.markdownConvert:
        return Icons.text_snippet_outlined;
      case VisualStepType.jsonPathStep:
        return Icons.troubleshoot_rounded;
      case VisualStepType.headerBuilder:
        return Icons.badge_outlined;
    }
  }

  Color _getStepColor(VisualStepType type) {
    switch (type) {
      case VisualStepType.setVariable:
        return AppColors.primary;
      case VisualStepType.assertValue:
        return Colors.orange;
      case VisualStepType.sendRequest:
        return Colors.blue;
      case VisualStepType.start:
        return Colors.green;
      case VisualStepType.delay:
        return Colors.teal;
      case VisualStepType.switchStep:
        return Colors.indigo;
      case VisualStepType.merge:
        return Colors.amber.shade700;
      case VisualStepType.splitOut:
        return Colors.purple;
      case VisualStepType.aggregate:
        return Colors.cyan;
      case VisualStepType.dateTime:
        return Colors.pink;
      case VisualStepType.ifStep:
        return Colors.red.shade400;
      case VisualStepType.sort:
        return Colors.blueGrey;
      case VisualStepType.limit:
        return Colors.brown;
      case VisualStepType.removeDuplicates:
        return Colors.deepOrange;
      case VisualStepType.crypto:
        return Colors.lime.shade800;
      case VisualStepType.jsonConvert:
        return Colors.green.shade700;
      case VisualStepType.xmlConvert:
        return Colors.orange.shade800;
      case VisualStepType.htmlConvert:
        return Colors.teal.shade800;
      case VisualStepType.markdownConvert:
        return Colors.indigo.shade800;
      case VisualStepType.jsonPathStep:
        return Colors.purple.shade700;
      case VisualStepType.headerBuilder:
        return Colors.pink.shade700;
    }
  }

  String _getStepTypeName(VisualStepType type) {
    switch (type) {
      case VisualStepType.setVariable:
        return 'Set Fields';
      case VisualStepType.assertValue:
        return 'Assert Value';
      case VisualStepType.sendRequest:
        return 'HTTP Request';
      case VisualStepType.start:
        return 'Start';
      case VisualStepType.delay:
        return 'Delay';
      case VisualStepType.switchStep:
        return 'Switch';
      case VisualStepType.merge:
        return 'Merge';
      case VisualStepType.splitOut:
        return 'Split Out';
      case VisualStepType.aggregate:
        return 'Aggregate';
      case VisualStepType.dateTime:
        return 'Date & Time';
      case VisualStepType.ifStep:
        return 'If';
      case VisualStepType.sort:
        return 'Sort';
      case VisualStepType.limit:
        return 'Limit';
      case VisualStepType.removeDuplicates:
        return 'Remove Duplicates';
      case VisualStepType.crypto:
        return 'Crypto';
      case VisualStepType.jsonConvert:
        return 'JSON Convert';
      case VisualStepType.xmlConvert:
        return 'XML Convert';
      case VisualStepType.htmlConvert:
        return 'HTML Convert';
      case VisualStepType.markdownConvert:
        return 'Markdown Convert';
      case VisualStepType.jsonPathStep:
        return 'JSON Path';
      case VisualStepType.headerBuilder:
        return 'Header Builder';
    }
  }
}

class FlowchartPainter extends CustomPainter {
  final VisualScript script;
  final Map<String, Offset> positions;
  final double nodeWidth;
  final bool isDark;

  FlowchartPainter({
    required this.script,
    required this.positions,
    required this.nodeWidth,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paintNormal = Paint()
      ..color = isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final paintBackEdge = Paint()
      ..color = Colors.orange.shade700
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    script.nodes.forEach((id, node) {
      final src = positions[id];
      if (src == null) return;

      if (node is IfStep) {
        _drawConnection(canvas, id, node.trueStepId, src, getOutputYOffset(node, 'true'), paintNormal, paintBackEdge, label: 'T');
        _drawConnection(canvas, id, node.falseStepId, src, getOutputYOffset(node, 'false'), paintNormal, paintBackEdge, label: 'F');
      } else if (node is SwitchStep) {
        for (int i = 0; i < node.cases.length; i++) {
          final c = node.cases[i];
          _drawConnection(canvas, id, c.nextStepId, src, getOutputYOffset(node, 'switch_case', switchCaseVal: c.value), paintNormal, paintBackEdge, label: c.value);
        }
        _drawConnection(canvas, id, node.defaultStepId, src, getOutputYOffset(node, 'switch_default'), paintNormal, paintBackEdge, label: 'Default');
      } else if (node is SplitOutStep) {
        _drawConnection(canvas, id, node.loopStepId, src, getOutputYOffset(node, 'loop'), paintNormal, paintBackEdge, label: 'Loop');
        _drawConnection(canvas, id, node.nextStepId, src, getOutputYOffset(node, 'next'), paintNormal, paintBackEdge, label: 'Next');
      } else {
        _drawConnection(canvas, id, node.nextStepId, src, getOutputYOffset(node, 'next'), paintNormal, paintBackEdge);
      }
    });
  }

  void _drawConnection(
    Canvas canvas,
    String srcId,
    String? destId,
    Offset src,
    double outputYOffset,
    Paint paintNormal,
    Paint paintBackEdge, {
    String? label,
  }) {
    if (destId == null || destId.isEmpty) return;
    final dest = positions[destId];
    if (dest == null) return;

    final destNode = script.nodes[destId];
    final destHeight = destNode != null ? getNodeHeight(destNode) : 70.0;

    final startPoint = Offset(src.dx + nodeWidth, src.dy + outputYOffset);
    final endPoint = Offset(dest.dx, dest.dy + destHeight / 2);

    final isBackEdge = dest.dx <= src.dx;

    if (isBackEdge) {
      final path = Path()..moveTo(startPoint.dx, startPoint.dy);
      final controlPoint1 = Offset(startPoint.dx + 40, startPoint.dy + (dest.dy > src.dy ? 40 : -40));
      final controlPoint2 = Offset(endPoint.dx - 40, endPoint.dy + (dest.dy > src.dy ? 40 : -40));
      
      path.cubicTo(controlPoint1.dx, controlPoint1.dy, controlPoint2.dx, controlPoint2.dy, endPoint.dx, endPoint.dy);
      
      _drawDottedPath(canvas, path, paintBackEdge);
      _drawArrowHead(canvas, controlPoint2, endPoint, paintBackEdge.color);
    } else {
      final path = Path()..moveTo(startPoint.dx, startPoint.dy);
      final controlX = startPoint.dx + (endPoint.dx - startPoint.dx) * 0.5;
      path.cubicTo(controlX, startPoint.dy, controlX, endPoint.dy, endPoint.dx, endPoint.dy);
      canvas.drawPath(path, paintNormal);
      _drawArrowHead(canvas, Offset(controlX, endPoint.dy), endPoint, paintNormal.color);
    }

    if (label != null && label.isNotEmpty) {
      final labelOffset = Offset(startPoint.dx + 12, startPoint.dy - 10);
      final textPainter = TextPainter(
        text: TextSpan(
          text: label.length > 8 ? '${label.substring(0, 6)}..' : label,
          style: TextStyle(fontSize: 8, color: isBackEdge ? Colors.orange.shade700 : (isDark ? AppColors.slate400 : AppColors.slate600)),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, labelOffset);
    }
  }

  void _drawDottedPath(Canvas canvas, Path path, Paint paint) {
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double distance = 0.0;
      const double dashLength = 4.0;
      const double spaceLength = 4.0;
      while (distance < metric.length) {
        final segment = metric.extractPath(distance, distance + dashLength);
        canvas.drawPath(segment, paint);
        distance += dashLength + spaceLength;
      }
    }
  }

  void _drawArrowHead(Canvas canvas, Offset from, Offset to, Color color) {
    final double angle = atan2(to.dy - from.dy, to.dx - from.dx);
    const double arrowSize = 6.0;

    final path = Path()
      ..moveTo(to.dx, to.dy)
      ..lineTo(to.dx - arrowSize * cos(angle - pi / 6), to.dy - arrowSize * sin(angle - pi / 6))
      ..lineTo(to.dx - arrowSize * cos(angle + pi / 6), to.dy - arrowSize * sin(angle + pi / 6))
      ..close();

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant FlowchartPainter oldDelegate) {
    return oldDelegate.script != script || oldDelegate.positions != positions || oldDelegate.isDark != isDark;
  }
}
