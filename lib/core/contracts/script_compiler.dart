import 'package:fletch/models/visual_script.dart';
import 'package:fletch/utils/compiled_script.dart';
import 'package:fletch/utils/script_execution_context.dart';

abstract class IScriptCompiler {
  CompiledScript compile(
    VisualScript script, {
    List<WorkspaceRequestRef>? availableRequests,
  });
}
