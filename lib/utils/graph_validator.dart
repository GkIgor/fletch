import '../models/visual_script.dart';

enum ValidationErrorSeverity { error, warning }

class GraphValidationError {
  final ValidationErrorSeverity severity;
  final String nodeId;
  final String nodeName;
  final String message;

  GraphValidationError({
    required this.severity,
    required this.nodeId,
    required this.nodeName,
    required this.message,
  });

  Map<String, dynamic> toJson() => {
        'severity': severity.name,
        'nodeId': nodeId,
        'nodeName': nodeName,
        'message': message,
      };
}

class GraphValidator {
  static List<GraphValidationError> validate(VisualScript script) {
    final List<GraphValidationError> errors = [];

    // 1. Validate script start node
    if (script.startNodeId == null || script.startNodeId!.isEmpty) {
      errors.add(GraphValidationError(
        severity: ValidationErrorSeverity.error,
        nodeId: 'start',
        nodeName: 'Script',
        message: 'No initial node configured in the flowchart.',
      ));
      return errors;
    }

    if (!script.nodes.containsKey(script.startNodeId)) {
      errors.add(GraphValidationError(
        severity: ValidationErrorSeverity.error,
        nodeId: 'start',
        nodeName: 'Script',
        message: 'Script start node "${script.startNodeId}" does not exist in the graph.',
      ));
    }

    final Set<String> referencedIds = {script.startNodeId!};
    bool hasSplitOut = false;
    bool hasAggregate = false;

    // 2. Validate connections
    script.nodes.forEach((id, node) {
      if (node.type == VisualStepType.splitOut) {
        hasSplitOut = true;
      }
      if (node.type == VisualStepType.aggregate) {
        hasAggregate = true;
      }

      // Validate default connection nextStepId
      if (node.nextStepId != null && node.nextStepId!.isNotEmpty) {
        if (!script.nodes.containsKey(node.nextStepId)) {
          errors.add(GraphValidationError(
            severity: ValidationErrorSeverity.error,
            nodeId: id,
            nodeName: node.name,
            message: 'Default output connection points to non-existent node "${node.nextStepId}".',
          ));
        } else {
          referencedIds.add(node.nextStepId!);
        }
      }

      // Validate conditional / branching nodes using switch/case
      switch (node.type) {
        case VisualStepType.ifStep:
          if (node is IfStep) {
            _validateIfNode(script, id, node, errors, referencedIds);
          }
          break;
        case VisualStepType.switchStep:
          if (node is SwitchStep) {
            _validateSwitchNode(script, id, node, errors, referencedIds);
          }
          break;
        case VisualStepType.splitOut:
          if (node is SplitOutStep) {
            _validateSplitOutNode(script, id, node, errors, referencedIds);
          }
          break;
        default:
          break;
      }
    });

    // 3. Validate orphan nodes
    script.nodes.forEach((id, node) {
      if (!referencedIds.contains(id)) {
        errors.add(GraphValidationError(
          severity: ValidationErrorSeverity.warning,
          nodeId: id,
          nodeName: node.name,
          message: 'The node is disconnected from the main flow (orphan).',
        ));
      }
    });

    // 4. Split Out without Aggregate warning
    if (hasSplitOut && !hasAggregate) {
      errors.add(GraphValidationError(
        severity: ValidationErrorSeverity.warning,
        nodeId: 'split_aggregate',
        nodeName: 'Script',
        message: 'Loop "Split Out" configured without a corresponding "Aggregate" node.',
      ));
    }

    return errors;
  }

  static void _validateIfNode(
    VisualScript script,
    String id,
    IfStep node,
    List<GraphValidationError> errors,
    Set<String> referencedIds,
  ) {
    if (node.trueStepId == null || node.trueStepId!.isEmpty) {
      errors.add(GraphValidationError(
        severity: ValidationErrorSeverity.warning,
        nodeId: id,
        nodeName: node.name,
        message: 'True branch is empty and will fallback to Fail step.',
      ));
    } else if (!script.nodes.containsKey(node.trueStepId)) {
      errors.add(GraphValidationError(
        severity: ValidationErrorSeverity.error,
        nodeId: id,
        nodeName: node.name,
        message: 'Connection "True" points to non-existent node "${node.trueStepId}".',
      ));
    } else {
      referencedIds.add(node.trueStepId!);
    }

    if (node.falseStepId == null || node.falseStepId!.isEmpty) {
      errors.add(GraphValidationError(
        severity: ValidationErrorSeverity.warning,
        nodeId: id,
        nodeName: node.name,
        message: 'False branch is empty and will fallback to Fail step.',
      ));
    } else if (!script.nodes.containsKey(node.falseStepId)) {
      errors.add(GraphValidationError(
        severity: ValidationErrorSeverity.error,
        nodeId: id,
        nodeName: node.name,
        message: 'Connection "False" points to non-existent node "${node.falseStepId}".',
      ));
    } else {
      referencedIds.add(node.falseStepId!);
    }
  }

  static void _validateSwitchNode(
    VisualScript script,
    String id,
    SwitchStep node,
    List<GraphValidationError> errors,
    Set<String> referencedIds,
  ) {
    for (var c in node.cases) {
      if (c.nextStepId == null || c.nextStepId!.isEmpty) {
        errors.add(GraphValidationError(
          severity: ValidationErrorSeverity.warning,
          nodeId: id,
          nodeName: node.name,
          message: 'Case "${c.value}" branch is empty and will fallback to Fail step.',
        ));
      } else if (!script.nodes.containsKey(c.nextStepId)) {
        errors.add(GraphValidationError(
          severity: ValidationErrorSeverity.error,
          nodeId: id,
          nodeName: node.name,
          message: 'Case "${c.value}" points to non-existent node "${c.nextStepId}".',
        ));
      } else {
        referencedIds.add(c.nextStepId!);
      }
    }

    if (node.defaultStepId == null || node.defaultStepId!.isEmpty) {
      errors.add(GraphValidationError(
        severity: ValidationErrorSeverity.warning,
        nodeId: id,
        nodeName: node.name,
        message: 'Default branch is empty and will fallback to Fail step.',
      ));
    } else if (!script.nodes.containsKey(node.defaultStepId)) {
      errors.add(GraphValidationError(
        severity: ValidationErrorSeverity.error,
        nodeId: id,
        nodeName: node.name,
        message: 'Default branch points to non-existent node "${node.defaultStepId}".',
      ));
    } else {
      referencedIds.add(node.defaultStepId!);
    }
  }

  static void _validateSplitOutNode(
    VisualScript script,
    String id,
    SplitOutStep node,
    List<GraphValidationError> errors,
    Set<String> referencedIds,
  ) {
    if (node.loopStepId != null && node.loopStepId!.isNotEmpty) {
      if (!script.nodes.containsKey(node.loopStepId)) {
        errors.add(GraphValidationError(
          severity: ValidationErrorSeverity.error,
          nodeId: id,
          nodeName: node.name,
          message: 'Loop sequence points to non-existent node "${node.loopStepId}".',
        ));
      } else {
        referencedIds.add(node.loopStepId!);
      }
    }
  }
}
