import 'dart:convert';
import 'package:fletch/backend/requests/pipelines/contracts/pipeline_context.dart';
import 'package:fletch/backend/requests/pipelines/contracts/request_step.dart';
import 'package:fletch/utils/script_executor.dart';
import 'package:fletch/utils/script_execution_context.dart';

class ExecutePostScriptsStep implements IRequestStep {
  @override
  Future<void> execute(RequestPipelineContext context) async {
    final response = context.response;
    if (response == null) return;

    final execContext = context.scriptContext ?? ExecutionContext(
      variables: context.variables,
      headers: context.headers,
      queryParams: context.queryParams,
      url: context.url,
      body: context.body,
    );

    final Map<String, String> responseHeaders = response.headers.map((k, v) {
      if (v is List) {
        return MapEntry(k, v.join(', '));
      }
      return MapEntry(k, v.toString());
    });

    await ScriptExecutor.executePostResponse(
      request: context.request,
      collections: context.collections,
      workspace: context.workspace,
      context: execContext,
      statusCode: response.statusCode,
      responseBody: response.body is String
          ? response.body
          : jsonEncode(response.body),
      responseHeaders: responseHeaders,
    );

    context.variables = execContext.variables;
    context.scriptContext = execContext;
  }
}
