import 'package:fletch/backend/requests/pipelines/contracts/pipeline_context.dart';
import 'package:fletch/backend/requests/pipelines/contracts/request_step.dart';
import 'package:fletch/utils/auth_resolver.dart';

class ResolveAuthStep implements IRequestStep {
  @override
  Future<void> execute(RequestPipelineContext context) async {
    // We construct a run request representing the request details at this point in the pipeline
    final currentRequest = context.request.copyWith(
      url: context.url,
      body: context.body,
      headers: context.headers,
      queryParams: context.queryParams,
    );

    context.resolvedAuth = AuthResolver.resolveAuth(
      request: currentRequest,
      collections: context.collections,
      workspaceAuth: context.workspace.auth,
    );
  }
}
