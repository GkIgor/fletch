import 'package:fletch/core/contracts/http_client.dart';
import 'package:fletch/backend/requests/pipelines/contracts/pipeline_context.dart';
import 'package:fletch/backend/requests/pipelines/contracts/request_step.dart';

class ExecuteHttpStep implements IRequestStep {
  final IHttpClient _httpClient;

  ExecuteHttpStep(this._httpClient);

  @override
  Future<void> execute(RequestPipelineContext context) async {
    final runRequest = context.request.copyWith(
      url: context.url,
      body: context.body,
      headers: context.headers,
      queryParams: context.queryParams,
    );

    final response = await _httpClient.send(
      runRequest,
      variables: context.variables,
      resolvedAuth: context.resolvedAuth,
    );

    context.response = response;
  }
}
