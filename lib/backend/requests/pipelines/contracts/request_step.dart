import 'pipeline_context.dart';

abstract class IRequestStep {
  Future<void> execute(RequestPipelineContext context);
}
