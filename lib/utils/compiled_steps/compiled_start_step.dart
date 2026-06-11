import 'package:fletch/utils/script_compiler.dart';

class CompiledStartStep extends CompiledStep {
  final String? nextStepId;

  CompiledStartStep({
    required super.id,
    required super.name,
    this.nextStepId,
  });

  @override
  Future<ExecutionResult> execute(ExecutionContext context, Map<String, CompiledStep> nodes) async {
    context.log(id, name, 'Fluxo iniciado.', level: LogLevel.info);
    return ExecutionResult(success: true, nextNodeId: nextStepId);
  }
}
