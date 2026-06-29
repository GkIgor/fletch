import 'package:fletch/backend/requests/pipelines/contracts/pipeline_context.dart';
import 'package:fletch/backend/requests/pipelines/contracts/request_step.dart';

class ResolveEnvironmentStep implements IRequestStep {
  @override
  Future<void> execute(RequestPipelineContext context) async {
    final envId = context.workspace.selectedEnvironmentId;
    if (envId == null) return;

    try {
      final env = context.workspace.environments.firstWhere((e) => e.id == envId);
      env.variables.forEach((key, secretKey) {
        // Environment variables serve as base values, so we put them if they are not already set
        context.variables.putIfAbsent(key, () => secretKey.value);
      });
    } catch (_) {
      // Selected environment not found or list is empty
    }
  }
}
