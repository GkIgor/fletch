import 'package:fletch/utils/script_compiler.dart';

class CompiledDelayStep extends CompiledStep {
  final String? nextStepId;
  final int durationMs;

  CompiledDelayStep({
    required super.id,
    required super.name,
    this.nextStepId,
    required this.durationMs,
  });

  @override
  Future<ExecutionResult> execute(ExecutionContext context, Map<String, CompiledStep> nodes) async {
    if (durationMs <= 0) {
      return ExecutionResult(success: true, nextNodeId: nextStepId);
    }
    context.log(id, name, 'Aguardando ${durationMs}ms...', level: LogLevel.info);
    await Future.delayed(Duration(milliseconds: durationMs));
    return ExecutionResult(success: true, nextNodeId: nextStepId);
  }
}
