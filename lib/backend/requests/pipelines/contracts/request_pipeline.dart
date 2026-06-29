import 'package:fletch/backend/requests/models/http_request.dart';
import 'package:fletch/backend/collections/models/collection.dart';
import 'package:fletch/backend/workspace/models/workspace.dart';
import 'package:fletch/backend/requests/pipelines/contracts/pipeline_context.dart';

abstract class IRequestPipeline {
  Future<RequestPipelineContext> run(
    HttpRequest request,
    List<RequestCollection> collections,
    WorkspaceModel workspace, {
    Map<String, String>? initialVariables,
  });
}
