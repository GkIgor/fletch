import 'package:fletch/core/contracts/http_client.dart';
import 'package:fletch/backend/requests/models/http_request.dart';
import 'package:fletch/backend/collections/models/collection.dart';
import 'package:fletch/backend/workspace/models/workspace.dart';
import 'contracts/request_pipeline.dart';
import 'contracts/pipeline_context.dart';
import 'contracts/request_step.dart';
import 'steps/resolve_environment_step.dart';
import 'steps/resolve_auth_step.dart';
import 'steps/execute_http_step.dart';

class ScriptRequestPipeline implements IRequestPipeline {
  final List<IRequestStep> _steps;

  ScriptRequestPipeline(IHttpClient httpClient)
      : _steps = [
          ResolveEnvironmentStep(),
          ResolveAuthStep(),
          ExecuteHttpStep(httpClient),
        ];

  @override
  Future<RequestPipelineContext> run(
    HttpRequest request,
    List<RequestCollection> collections,
    WorkspaceModel workspace, {
    Map<String, String>? initialVariables,
  }) async {
    final context = RequestPipelineContext(
      request: request,
      collections: collections,
      workspace: workspace,
      initialVariables: initialVariables,
    );

    for (final step in _steps) {
      await step.execute(context);
    }

    return context;
  }
}
