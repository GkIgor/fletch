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

    // 1. Validar início do script
    if (script.startNodeId == null || script.startNodeId!.isEmpty) {
      errors.add(GraphValidationError(
        severity: ValidationErrorSeverity.error,
        nodeId: 'start',
        nodeName: 'Script',
        message: 'Nenhum nó inicial configurado no fluxograma.',
      ));
      return errors;
    }

    if (!script.nodes.containsKey(script.startNodeId)) {
      errors.add(GraphValidationError(
        severity: ValidationErrorSeverity.error,
        nodeId: 'start',
        nodeName: 'Script',
        message: 'Nó de início do script "${script.startNodeId}" não existe no grafo.',
      ));
    }

    final Set<String> referencedIds = {script.startNodeId!};
    bool hasSplitOut = false;
    bool hasAggregate = false;

    // 2. Validar conexões
    script.nodes.forEach((id, node) {
      if (node.type == VisualStepType.splitOut) {
        hasSplitOut = true;
      }
      if (node.type == VisualStepType.aggregate) {
        hasAggregate = true;
      }

      // Validar conexão padrão nextStepId
      if (node.nextStepId != null && node.nextStepId!.isNotEmpty) {
        if (!script.nodes.containsKey(node.nextStepId)) {
          errors.add(GraphValidationError(
            severity: ValidationErrorSeverity.error,
            nodeId: id,
            nodeName: node.name,
            message: 'A conexão de saída padrão aponta para o nó inexistente "${node.nextStepId}".',
          ));
        } else {
          referencedIds.add(node.nextStepId!);
        }
      }

      // Validar nós condicionais / bifurcações
      if (node is IfStep) {
        if (node.trueStepId != null && node.trueStepId!.isNotEmpty) {
          if (!script.nodes.containsKey(node.trueStepId)) {
            errors.add(GraphValidationError(
              severity: ValidationErrorSeverity.error,
              nodeId: id,
              nodeName: node.name,
              message: 'Conexão "True" aponta para o nó inexistente "${node.trueStepId}".',
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
              message: 'Conexão "False" aponta para o nó inexistente "${node.falseStepId}".',
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
                message: 'Caso "${c.value}" aponta para o nó inexistente "${c.nextStepId}".',
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
              message: 'Ramificação padrão (Default) aponta para o nó inexistente "${node.defaultStepId}".',
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
              message: 'Cadeia de repetição (Loop) aponta para o nó inexistente "${node.loopStepId}".',
            ));
          } else {
            referencedIds.add(node.loopStepId!);
          }
        }
      }
    });

    // 3. Validar nós órfãos
    script.nodes.forEach((id, node) {
      if (!referencedIds.contains(id)) {
        errors.add(GraphValidationError(
          severity: ValidationErrorSeverity.warning,
          nodeId: id,
          nodeName: node.name,
          message: 'O nó está desconectado do fluxo principal (órfão).',
        ));
      }
    });

    // 4. Split Out sem Aggregate Warning
    if (hasSplitOut && !hasAggregate) {
      errors.add(GraphValidationError(
        severity: ValidationErrorSeverity.warning,
        nodeId: 'split_aggregate',
        nodeName: 'Script',
        message: 'Loop "Split Out" configurado sem um correspondente nó "Aggregate".',
      ));
    }

    return errors;
  }
}
