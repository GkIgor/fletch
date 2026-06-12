import 'package:fletch/utils/script_compiler.dart';

class CompiledFailStep extends CompiledStep {
  CompiledFailStep({
    required super.id,
    required super.name,
  });

  @override
  Future<ExecutionResult> execute(ExecutionContext context, Map<String, CompiledStep> nodes) async {
    context.log(id, name, 'Flow execution failed at Fail step.', level: LogLevel.error);
    return ExecutionResult(success: false, error: 'Fail step reached.');
  }
}
