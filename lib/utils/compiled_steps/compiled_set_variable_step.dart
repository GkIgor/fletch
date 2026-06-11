import 'package:fletch/utils/script_compiler.dart';

class CompiledSetVariableStep extends CompiledStep {
  final String? nextStepId;
  final List<CompiledAssignment> assignments;

  CompiledSetVariableStep({
    required super.id,
    required super.name,
    this.nextStepId,
    required this.assignments,
  });

  @override
  Future<ExecutionResult> execute(ExecutionContext context, Map<String, CompiledStep> nodes) async {
    if (assignments.isEmpty) {
      context.log(id, name, 'Nenhuma atribuição configurada.', level: LogLevel.warn);
      return ExecutionResult(success: true, nextNodeId: nextStepId);
    }

    for (var assignment in assignments) {
      if (assignment.variableName.isEmpty) continue;
      final resolvedVal = assignment.source.resolve(context);
      context.variables[assignment.variableName] = resolvedVal;
      context.log(id, name, 'Definido "${assignment.variableName}" = "$resolvedVal"', level: LogLevel.info);
    }

    return ExecutionResult(success: true, nextNodeId: nextStepId);
  }
}
