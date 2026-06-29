import 'package:fletch/backend/requests/pipelines/contracts/pipeline_context.dart';
import 'package:fletch/backend/requests/pipelines/contracts/request_step.dart';
import 'package:fletch/backend/scripting/execution/script_executor.dart';

class ExecutePreScriptsStep implements IRequestStep {
  @override
  Future<void> execute(RequestPipelineContext context) async {
    final execContext = await ScriptExecutor.executePreRequest(
      request: context.request,
      collections: context.collections,
      workspace: context.workspace,
      initialVariables: context.variables,
    );

    context.url = execContext.url;
    context.body = execContext.body;
    context.headers = execContext.headers;
    context.queryParams = execContext.queryParams;
    context.variables = execContext.variables;
    context.scriptContext = execContext;
  }
}
