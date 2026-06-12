import 'package:fletch/utils/script_compiler.dart';

class CompiledEndStep extends CompiledStep {
  CompiledEndStep({
    required super.id,
    required super.name,
  });

  @override
  Future<ExecutionResult> execute(ExecutionContext context, Map<String, CompiledStep> nodes) async {
    context.log(id, name, 'Flow completed at End step.', level: LogLevel.info);
    return ExecutionResult(success: true, nextNodeId: null);
  }
}
