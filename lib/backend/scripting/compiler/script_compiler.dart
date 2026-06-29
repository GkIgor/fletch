// JIT Engine, ExecutionLog, and compiled instruction steps for Fletch visual automation scripts.
import 'package:fletch/backend/scripting/models/visual_script.dart';
import 'package:fletch/backend/scripting/compiler/step_compiler_registry.dart';
import 'package:fletch/backend/scripting/execution/script_execution_context.dart';
import 'package:fletch/backend/scripting/compiler/compiled_script.dart';

export 'package:fletch/backend/scripting/execution/script_execution_context.dart';
export 'package:fletch/backend/scripting/compiler/compiled_script.dart';
export 'package:fletch/backend/scripting/compiler/jit_cache.dart';

export 'package:fletch/backend/scripting/compiler/compiled_steps/compiled_set_variable_step.dart';
export 'package:fletch/backend/scripting/compiler/compiled_steps/compiled_assert_value_step.dart';
export 'package:fletch/backend/scripting/compiler/compiled_steps/compiled_if_step.dart';
export 'package:fletch/backend/scripting/compiler/compiled_steps/compiled_send_request_step.dart';
export 'package:fletch/backend/scripting/compiler/compiled_steps/compiled_delay_step.dart';
export 'package:fletch/backend/scripting/compiler/compiled_steps/compiled_switch_step.dart';
export 'package:fletch/backend/scripting/compiler/compiled_steps/compiled_merge_step.dart';
export 'package:fletch/backend/scripting/compiler/compiled_steps/compiled_split_out_step.dart';
export 'package:fletch/backend/scripting/compiler/compiled_steps/compiled_aggregate_step.dart';
export 'package:fletch/backend/scripting/compiler/compiled_steps/compiled_date_time_step.dart';
export 'package:fletch/backend/scripting/compiler/compiled_steps/compiled_sort_step.dart';
export 'package:fletch/backend/scripting/compiler/compiled_steps/compiled_limit_step.dart';
export 'package:fletch/backend/scripting/compiler/compiled_steps/compiled_remove_duplicates_step.dart';
export 'package:fletch/backend/scripting/compiler/compiled_steps/compiled_crypto_step.dart';
export 'package:fletch/backend/scripting/compiler/compiled_steps/compiled_json_convert_step.dart';
export 'package:fletch/backend/scripting/compiler/compiled_steps/compiled_xml_convert_step.dart';
export 'package:fletch/backend/scripting/compiler/compiled_steps/compiled_html_convert_step.dart';
export 'package:fletch/backend/scripting/compiler/compiled_steps/compiled_markdown_convert_step.dart';
export 'package:fletch/backend/scripting/compiler/compiled_steps/compiled_json_path_step.dart';
export 'package:fletch/backend/scripting/compiler/compiled_steps/compiled_header_builder_step.dart';
export 'package:fletch/backend/scripting/compiler/compiled_steps/compiled_start_step.dart';
export 'package:fletch/backend/scripting/compiler/compiled_steps/compiled_fail_step.dart';
export 'package:fletch/backend/scripting/compiler/compiled_steps/compiled_end_step.dart';

/// JIT Compiler that translates VisualScript structures to optimized runtime representations.
class ScriptCompiler {
  static CompiledScript compile(
    VisualScript script, {
    List<WorkspaceRequestRef>? availableRequests,
  }) {
    final Map<String, CompiledStep> compiledNodes = {};
    final Map<String, WorkspaceRequestRef> requestsById = {
      if (availableRequests != null)
        for (final r in availableRequests) r.id: r,
    };

    script.nodes.forEach((id, step) {
      if (!step.enabled) return;

      final compiledStep = _compileStep(step, compiledNodes, requestsById);
      if (compiledStep != null) {
        compiledNodes[id] = compiledStep;
      }
    });

    return CompiledScript(
      nodes: compiledNodes,
      startNodeId: script.startNodeId,
    );
  }

  static CompiledStep? _compileStep(
    VisualStep step,
    Map<String, CompiledStep> compiledNodes,
    Map<String, WorkspaceRequestRef> requestsById,
  ) {
    final compiler = StepCompilerRegistry.getCompiler(step.type);
    if (compiler != null) {
      return compiler.compile(step, requestsById, compiledNodes);
    }
    return null;
  }

  static CompiledValueSource compileValueSource(ValueSource source) {
    return StepCompilerRegistry.compileValueSource(source);
  }
}
