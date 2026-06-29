import 'package:fletch/backend/scripting/models/visual_script.dart';
import 'package:fletch/backend/scripting/compiler/compiled_script.dart';
import 'package:fletch/backend/scripting/execution/script_execution_context.dart';

abstract class IStepCompiler<T extends VisualStep> {
  CompiledStep compile(
    T step,
    Map<String, WorkspaceRequestRef> requestsById,
    Map<String, CompiledStep> compiledNodes,
  );
}
