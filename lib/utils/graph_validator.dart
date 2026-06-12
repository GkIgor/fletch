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

      // Validate conditional / branching nodes
      if (node is IfStep) {
        if (node.trueStepId != null && node.trueStepId!.isNotEmpty) {
          if (!script.nodes.containsKey(node.trueStepId)) {
            errors.add(GraphValidationError(
              severity: ValidationErrorSeverity.error,
              nodeId: id,
              nodeName: node.name,
              message: 'Connection "True" points to non-existent node "${node.trueStepId}".',
            ));
          } else {
            referencedIds.add(node.trueStepId!);
          }
        }
        if (node.falseStepId != null && node.falseStepId!.isNotEmpty) {
          if (!script.nodes.containsKey(node.falseStepId)) {
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
      } else if (node is SwitchStep) {
        for (var c in node.cases) {
          if (c.nextStepId != null && c.nextStepId!.isNotEmpty) {
            if (!script.nodes.containsKey(c.nextStepId)) {
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
        }
        if (node.defaultStepId != null && node.defaultStepId!.isNotEmpty) {
          if (!script.nodes.containsKey(node.defaultStepId)) {
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
      } else if (node is SplitOutStep) {
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
}
