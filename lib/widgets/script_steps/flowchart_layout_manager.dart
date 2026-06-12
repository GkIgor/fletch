import 'dart:math';
import '../../models/visual_script.dart';

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
