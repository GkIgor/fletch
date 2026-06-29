import 'package:fletch/backend/requests/models/http_request.dart';
import 'package:fletch/backend/requests/models/http_response.dart';
import 'package:fletch/backend/requests/models/http_auth.dart';
import 'package:fletch/backend/collections/models/collection.dart';
import 'package:fletch/backend/workspace/models/workspace.dart';
import 'package:fletch/utils/script_execution_context.dart';

class RequestPipelineContext {
  final HttpRequest request;
  final List<RequestCollection> collections;
  final WorkspaceModel workspace;

  // Mutable state modified by steps
  String url;
  String? body;
  Map<String, String> headers;
  Map<String, String> queryParams;
  Map<String, String> variables;
  HttpAuth? resolvedAuth;
  HttpResponse? response;

  // Script Execution context
  ExecutionContext? scriptContext;

  RequestPipelineContext({
    required this.request,
    required this.collections,
    required this.workspace,
    Map<String, String>? initialVariables,
  }) : url = request.url,
       body = request.body,
       headers = Map<String, String>.from(request.headers),
       queryParams = Map<String, String>.from(request.queryParams),
       variables = Map<String, String>.from(initialVariables ?? {});
}
