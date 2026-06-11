import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/visual_script.dart';
import '../../theme/app_colors.dart';
import '../../utils/script_compiler.dart';

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
  }

  void _layoutNode(VisualScript script, String nodeId, int col, int row) {
    if (visited.contains(nodeId)) return;
    visited.add(nodeId);

    final node = script.nodes[nodeId];
    if (node == null) return;

    // Resolve collision
    int targetRow = row;
    while (isCellOccupied(col, targetRow)) {
      targetRow++;
    }
    occupyCell(col, targetRow);
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

  @override
  void didUpdateWidget(covariant FlowchartCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If nodes count or connections change, mark topology changed
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
          name: 'Atribuir Variáveis',
          assignments: [VariableAssignment(variableName: 'var_name', valueSource: ValueSource(type: ValueSourceType.constant, key: 'value'))],
        );
        break;
      case VisualStepType.assertValue:
        newStep = AssertValueStep(
          id: newStepId,
          name: 'Validar Asserção',
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
          name: 'Condição IF',
          leftSource: ValueSource(type: ValueSourceType.responseStatusCode),
          operator: '==',
          rightSource: ValueSource(type: ValueSourceType.constant, key: '200'),
        );
        break;
      case VisualStepType.sort:
        newStep = SortStep(
          id: newStepId,
          name: 'Ordenar Lista',
          arraySource: ValueSource(type: ValueSourceType.variable, key: 'list_result'),
          sortByPath: 'id',
          ascending: true,
          saveToVariable: 'sorted_list',
        );
        break;
      case VisualStepType.limit:
        newStep = LimitStep(
          id: newStepId,
          name: 'Limitar Lista',
          arraySource: ValueSource(type: ValueSourceType.variable, key: 'list_result'),
          limit: 10,
          offset: 0,
          saveToVariable: 'limited_list',
        );
        break;
      case VisualStepType.removeDuplicates:
        newStep = RemoveDuplicatesStep(
          id: newStepId,
          name: 'Remover Duplicatas',
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
          name: 'Início',
        );
        break;
    }

    final Map<String, VisualStep> updatedNodes = Map.from(widget.script.nodes);
    updatedNodes[newStepId] = newStep;

    final parent = updatedNodes[parentId];
    if (parent != null) {
      if (connectionType == 'next') {
        parent.nextStepId = newStepId;
      } else if (connectionType == 'true' && parent is IfStep) {
        parent.trueStepId = newStepId;
      } else if (connectionType == 'false' && parent is IfStep) {
        parent.falseStepId = newStepId;
      } else if (connectionType == 'loop' && parent is SplitOutStep) {
        parent.loopStepId = newStepId;
      } else if (connectionType == 'switch_case' && parent is SwitchStep && switchCaseVal != null) {
        final idx = parent.cases.indexWhere((c) => c.value == switchCaseVal);
        if (idx != -1) {
          parent.cases[idx].nextStepId = newStepId;
        }
      } else if (connectionType == 'switch_default' && parent is SwitchStep) {
        parent.defaultStepId = newStepId;
      }
    }

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

  Widget _buildInsertionButton(String parentId, String connectionType, {String? switchCaseVal}) {
    return PopupMenuButton<VisualStepType>(
      icon: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.green.shade600,
        ),
        child: const Icon(Icons.add, size: 12, color: Colors.white),
      ),
      tooltip: 'Inserir Nó',
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      onSelected: (type) => _addNode(parentId, connectionType, type, switchCaseVal: switchCaseVal),
      itemBuilder: (context) => [
        const PopupMenuItem(value: VisualStepType.sendRequest, child: Text('HTTP Request')),
        const PopupMenuItem(value: VisualStepType.setVariable, child: Text('Set/Edit Fields')),
        const PopupMenuItem(value: VisualStepType.assertValue, child: Text('Assert Value')),
        const PopupMenuItem(value: VisualStepType.delay, child: Text('Delay Timer')),
        const PopupMenuItem(value: VisualStepType.switchStep, child: Text('Switch')),
        const PopupMenuItem(value: VisualStepType.merge, child: Text('Merge')),
        const PopupMenuItem(value: VisualStepType.splitOut, child: Text('Split Out')),
        const PopupMenuItem(value: VisualStepType.aggregate, child: Text('Aggregate')),
        const PopupMenuItem(value: VisualStepType.dateTime, child: Text('Date & Time')),
        const PopupMenuItem(value: VisualStepType.ifStep, child: Text('If')),
        const PopupMenuItem(value: VisualStepType.sort, child: Text('Sort')),
        const PopupMenuItem(value: VisualStepType.limit, child: Text('Limit')),
        const PopupMenuItem(value: VisualStepType.removeDuplicates, child: Text('Remove Duplicates')),
        const PopupMenuItem(value: VisualStepType.crypto, child: Text('Crypto')),
        const PopupMenuItem(value: VisualStepType.jsonConvert, child: Text('JSON Convert')),
        const PopupMenuItem(value: VisualStepType.xmlConvert, child: Text('XML Convert')),
        const PopupMenuItem(value: VisualStepType.htmlConvert, child: Text('HTML Convert')),
        const PopupMenuItem(value: VisualStepType.markdownConvert, child: Text('Markdown Convert')),
        const PopupMenuItem(value: VisualStepType.jsonPathStep, child: Text('JSON Path')),
        const PopupMenuItem(value: VisualStepType.headerBuilder, child: Text('Header Builder')),
      ],
    );
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
              'Canvas Vazio. Adicione o primeiro nó para começar.',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                final startId = UniqueKey().toString();
                final startNode = StartStep(id: startId, name: 'Início');
                widget.onChanged(widget.script.copyWith(
                  nodes: {startId: startNode},
                  startNodeId: startId,
                  updatedAt: DateTime.now(),
                ));
                widget.onSelectNode(startId);
              },
              icon: const Icon(Icons.add, size: 14),
              label: const Text('Adicionar Início'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            )
          ],
        ),
      );
    }

    const double colWidth = 180.0;
    const double rowHeight = 110.0;
    const double nodeW = 140.0;
    const double nodeH = 70.0;
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
    final canvasH = max(600.0, (maxRow + 1) * rowHeight + 100.0);

    return InteractiveViewer(
      constrained: false,
      boundaryMargin: const EdgeInsets.all(100.0),
      minScale: 0.5,
      maxScale: 1.5,
      child: Container(
        width: canvasW,
        height: canvasH,
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        child: Stack(
          children: [
            // Background connections layer
            Positioned.fill(
              child: CustomPaint(
                painter: FlowchartPainter(
                  script: widget.script,
                  positions: pixelPositions,
                  nodeWidth: nodeW,
                  nodeHeight: nodeH,
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

              // Check execution log state
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
                child: GestureDetector(
                  onTap: () => widget.onSelectNode(id),
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
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        child: Row(
                          children: [
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
                            // Node context options button
                            PopupMenuButton<String>(
                              icon: Icon(Icons.more_vert, size: 14, color: isDark ? AppColors.slate400 : AppColors.slate500),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onSelected: (val) {
                                if (val == 'delete') {
                                  _deleteNode(id);
                                } else if (val == 'disconnect') {
                                  _disconnectNode(id);
                                } else if (val == 'rename') {
                                  _showRenameDialog(context, id, node.name);
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(value: 'rename', child: Text('Renomear')),
                                const PopupMenuItem(value: 'disconnect', child: Text('Desconectar')),
                                if (node.type != VisualStepType.start)
                                  const PopupMenuItem(value: 'delete', child: Text('Excluir', style: TextStyle(color: Colors.red))),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Execution status dot
                      if (statusIcon != null)
                        Positioned(
                          top: -6,
                          left: -6,
                          child: Icon(statusIcon, size: 14, color: statusColor),
                        ),
                      // Loop/Next insertion output ports
                      if (node is IfStep) ...[
                        Positioned(
                          right: -10,
                          top: nodeH / 4 - 10,
                          child: _buildInsertionButton(id, 'true'),
                        ),
                        Positioned(
                          right: -10,
                          top: (nodeH * 3) / 4 - 10,
                          child: _buildInsertionButton(id, 'false'),
                        ),
                      ] else if (node is SwitchStep) ...[
                        ...node.cases.asMap().entries.map((e) {
                          final idx = e.key;
                          final c = e.value;
                          final offsetPercent = (idx + 1) / (node.cases.length + 2);
                          return Positioned(
                            right: -10,
                            top: nodeH * offsetPercent - 10,
                            child: Tooltip(
                              message: 'Caso: ${c.value}',
                              child: _buildInsertionButton(id, 'switch_case', switchCaseVal: c.value),
                            ),
                          );
                        }),
                        Positioned(
                          right: -10,
                          top: nodeH * ((node.cases.length + 1) / (node.cases.length + 2)) - 10,
                          child: Tooltip(
                            message: 'Padrão (Default)',
                            child: _buildInsertionButton(id, 'switch_default'),
                          ),
                        ),
                      ] else if (node is SplitOutStep) ...[
                        Positioned(
                          right: -10,
                          top: nodeH / 4 - 10,
                          child: Tooltip(
                            message: 'Loop Body',
                            child: _buildInsertionButton(id, 'loop'),
                          ),
                        ),
                        Positioned(
                          right: -10,
                          top: (nodeH * 3) / 4 - 10,
                          child: Tooltip(
                            message: 'Continuação',
                            child: _buildInsertionButton(id, 'next'),
                          ),
                        ),
                      ] else ...[
                        Positioned(
                          right: -10,
                          top: nodeH / 2 - 10,
                          child: _buildInsertionButton(id, 'next'),
                        ),
                      ]
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showRenameDialog(BuildContext context, String id, String currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Renomear Nó', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Novo nome para o nó'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              _renameNode(id, controller.text);
              Navigator.pop(context);
            },
            child: const Text('Renomear'),
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
        return 'Início';
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
  final double nodeHeight;
  final bool isDark;

  FlowchartPainter({
    required this.script,
    required this.positions,
    required this.nodeWidth,
    required this.nodeHeight,
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
        _drawConnection(canvas, id, node.trueStepId, src, nodeHeight / 4, paintNormal, paintBackEdge, label: 'T');
        _drawConnection(canvas, id, node.falseStepId, src, (nodeHeight * 3) / 4, paintNormal, paintBackEdge, label: 'F');
      } else if (node is SwitchStep) {
        for (int i = 0; i < node.cases.length; i++) {
          final c = node.cases[i];
          final offsetPercent = (i + 1) / (node.cases.length + 2);
          _drawConnection(canvas, id, c.nextStepId, src, nodeHeight * offsetPercent, paintNormal, paintBackEdge, label: c.value);
        }
        final defaultOffset = (node.cases.length + 1) / (node.cases.length + 2);
        _drawConnection(canvas, id, node.defaultStepId, src, nodeHeight * defaultOffset, paintNormal, paintBackEdge, label: 'Default');
      } else if (node is SplitOutStep) {
        _drawConnection(canvas, id, node.loopStepId, src, nodeHeight / 4, paintNormal, paintBackEdge, label: 'Loop');
        _drawConnection(canvas, id, node.nextStepId, src, (nodeHeight * 3) / 4, paintNormal, paintBackEdge, label: 'Next');
      } else {
        _drawConnection(canvas, id, node.nextStepId, src, nodeHeight / 2, paintNormal, paintBackEdge);
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

    final startPoint = Offset(src.dx + nodeWidth, src.dy + outputYOffset);
    final endPoint = Offset(dest.dx, dest.dy + nodeHeight / 2);

    final isBackEdge = dest.dx <= src.dx;

    if (isBackEdge) {
      // Draw curved dotted loopback back-edge
      final path = Path()..moveTo(startPoint.dx, startPoint.dy);
      // Curve going upwards/downwards out and around
      final controlPoint1 = Offset(startPoint.dx + 40, startPoint.dy + (dest.dy > src.dy ? 40 : -40));
      final controlPoint2 = Offset(endPoint.dx - 40, endPoint.dy + (dest.dy > src.dy ? 40 : -40));
      
      path.cubicTo(controlPoint1.dx, controlPoint1.dy, controlPoint2.dx, controlPoint2.dy, endPoint.dx, endPoint.dy);
      
      // Draw dotted path by sampling points along the bezier curve
      _drawDottedPath(canvas, path, paintBackEdge);
      _drawArrowHead(canvas, controlPoint2, endPoint, paintBackEdge.color);
    } else {
      // Draw normal S-curve connect line
      final path = Path()..moveTo(startPoint.dx, startPoint.dy);
      final controlX = startPoint.dx + (endPoint.dx - startPoint.dx) * 0.5;
      path.cubicTo(controlX, startPoint.dy, controlX, endPoint.dy, endPoint.dx, endPoint.dy);
      canvas.drawPath(path, paintNormal);
      _drawArrowHead(canvas, Offset(controlX, endPoint.dy), endPoint, paintNormal.color);
    }

    // Draw connecting labels if present
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
    // Basic path sampling for dotted line effect
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
