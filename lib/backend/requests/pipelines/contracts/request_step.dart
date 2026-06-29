import 'package:fletch/backend/requests/pipelines/contracts/pipeline_context.dart';

abstract class IRequestStep {
  Future<void> execute(RequestPipelineContext context);
}
