import 'package:fletch/core/contracts/http_client.dart';
import 'package:fletch/core/contracts/repository.dart';
import 'package:fletch/backend/requests/models/http_request.dart';
import 'package:fletch/backend/collections/models/collection.dart';
import 'package:fletch/backend/workspace/models/workspace.dart';
import 'package:fletch/backend/requests/pipelines/contracts/pipeline_context.dart';
import 'package:fletch/backend/requests/pipelines/standard_request_pipeline.dart';

class ExecuteRequest {
  final IHttpClient _httpClient;
  final IRepository<WorkspaceModel> _workspaceRepository;

  ExecuteRequest({
    required IHttpClient httpClient,
    required IRepository<WorkspaceModel> workspaceRepository,
  })  : _httpClient = httpClient,
        _workspaceRepository = workspaceRepository;

  Future<RequestPipelineContext> call({
    required HttpRequest request,
    required List<RequestCollection> collections,
    required WorkspaceModel workspace,
    Map<String, String>? variables,
  }) async {
    final pipeline = StandardRequestPipeline(_httpClient);
    final context = await pipeline.run(
      request,
      collections,
      workspace,
      initialVariables: variables,
    );

    // Propagate variables updated during script execution back to the active environment
    if (workspace.environments.isNotEmpty) {
      final activeEnvId = workspace.selectedEnvironmentId;
      if (activeEnvId != null) {
        final envIdx = workspace.environments.indexWhere(
          (e) => e.id == activeEnvId,
        );
        if (envIdx != -1) {
          context.variables.forEach((key, val) {
            workspace.environments[envIdx].variables[key] =
                WorkspaceSecretKey(value: val);
          });

          try {
            await _workspaceRepository.save(workspace);
          } catch (_) {
            // Failed to save updated environment variables back to storage
          }
        }
      }
    }

    return context;
  }
}
