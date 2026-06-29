import 'package:fletch/core/contracts/http_client.dart';
import 'package:fletch/core/contracts/repository.dart';
import 'package:fletch/backend/requests/use_cases/execute_request.dart';
import 'package:fletch/backend/collections/models/collection.dart';
import 'package:fletch/backend/workspace/models/workspace.dart';
import 'package:fletch/backend/runner/models/runner_session.dart';

class RunSession {
  final IHttpClient _httpClient;
  final IRepository<WorkspaceModel> _workspaceRepository;

  RunSession({
    required IHttpClient httpClient,
    required IRepository<WorkspaceModel> workspaceRepository,
  })  : _httpClient = httpClient,
        _workspaceRepository = workspaceRepository;

  Future<void> call({
    required RunnerSession session,
    required List<RequestCollection> collections,
    required WorkspaceModel workspace,
    required Function(int index) onItemStart,
    required Function(int index) onItemComplete,
    required Function() onSessionComplete,
  }) async {
    if (session.isCurrentlyRunning) return;
    session.isCurrentlyRunning = true;
    session.stopExecution = false;

    for (var item in session.items) {
      if (item.isSelected) {
        item.reset();
      }
    }

    final executeRequest = ExecuteRequest(
      httpClient: _httpClient,
      workspaceRepository: _workspaceRepository,
    );

    bool isFirst = true;
    for (int i = 0; i < session.items.length; i++) {
      if (session.stopExecution) break;
      final item = session.items[i];
      if (!item.isSelected) continue;

      if (!isFirst && session.delayMs > 0) {
        await Future.delayed(Duration(milliseconds: session.delayMs));
        if (session.stopExecution) break;
      }
      isFirst = false;

      session.currentIndex = i;
      item.status = 'running';
      onItemStart(i);

      try {
        final pipelineContext = await executeRequest(
          request: item.request,
          collections: collections,
          workspace: workspace,
          variables: session.variables,
        );

        item.response = pipelineContext.response;
        if (pipelineContext.response != null && pipelineContext.response!.isSuccess) {
          item.status = 'success';
        } else {
          item.status = 'failure';
          if (pipelineContext.response != null) {
            item.errorMessage = 'HTTP Status: ${pipelineContext.response!.statusCode}';
          }
        }

        // Keep local runner environment variables updated with dynamically set scripts outputs
        session.variables.addAll(pipelineContext.variables);
      } catch (e) {
        item.status = 'failure';
        item.errorMessage = e.toString();
      }

      onItemComplete(i);
    }

    session.isCurrentlyRunning = false;
    onSessionComplete();
  }
}
