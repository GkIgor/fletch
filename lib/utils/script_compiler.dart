// JIT Engine, ExecutionLog, and compiled instruction steps for Fletch visual automation scripts.
import '../models/visual_script.dart';
import 'compiled_steps/compiled_set_variable_step.dart';
import 'compiled_steps/compiled_assert_value_step.dart';
import 'compiled_steps/compiled_if_step.dart';
import 'compiled_steps/compiled_send_request_step.dart';
import 'compiled_steps/compiled_delay_step.dart';
import 'compiled_steps/compiled_switch_step.dart';
import 'compiled_steps/compiled_merge_step.dart';
import 'compiled_steps/compiled_split_out_step.dart';
import 'compiled_steps/compiled_aggregate_step.dart';
import 'compiled_steps/compiled_date_time_step.dart';
import 'compiled_steps/compiled_sort_step.dart';
import 'compiled_steps/compiled_limit_step.dart';
import 'compiled_steps/compiled_remove_duplicates_step.dart';
import 'compiled_steps/compiled_crypto_step.dart';
import 'compiled_steps/compiled_json_convert_step.dart';
import 'compiled_steps/compiled_xml_convert_step.dart';
import 'compiled_steps/compiled_html_convert_step.dart';
import 'compiled_steps/compiled_markdown_convert_step.dart';
import 'compiled_steps/compiled_json_path_step.dart';
import 'compiled_steps/compiled_header_builder_step.dart';
import 'compiled_steps/compiled_start_step.dart';
import 'compiled_steps/compiled_fail_step.dart';
import 'compiled_steps/compiled_end_step.dart';

import 'script_execution_context.dart';
import 'compiled_script.dart';

export 'script_execution_context.dart';
export 'compiled_script.dart';
export 'jit_cache.dart';

export 'compiled_steps/compiled_set_variable_step.dart';
export 'compiled_steps/compiled_assert_value_step.dart';
export 'compiled_steps/compiled_if_step.dart';
export 'compiled_steps/compiled_send_request_step.dart';
export 'compiled_steps/compiled_delay_step.dart';
export 'compiled_steps/compiled_switch_step.dart';
export 'compiled_steps/compiled_merge_step.dart';
export 'compiled_steps/compiled_split_out_step.dart';
export 'compiled_steps/compiled_aggregate_step.dart';
export 'compiled_steps/compiled_date_time_step.dart';
export 'compiled_steps/compiled_sort_step.dart';
export 'compiled_steps/compiled_limit_step.dart';
export 'compiled_steps/compiled_remove_duplicates_step.dart';
export 'compiled_steps/compiled_crypto_step.dart';
export 'compiled_steps/compiled_json_convert_step.dart';
export 'compiled_steps/compiled_xml_convert_step.dart';
export 'compiled_steps/compiled_html_convert_step.dart';
export 'compiled_steps/compiled_markdown_convert_step.dart';
export 'compiled_steps/compiled_json_path_step.dart';
export 'compiled_steps/compiled_header_builder_step.dart';
export 'compiled_steps/compiled_start_step.dart';
export 'compiled_steps/compiled_fail_step.dart';
export 'compiled_steps/compiled_end_step.dart';

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
    switch (step.type) {
      case VisualStepType.setVariable:
        return _compileSetVariable(step as SetVariableStep);
      case VisualStepType.assertValue:
        return _compileAssertValue(step as AssertValueStep);
      case VisualStepType.sendRequest:
        return _compileSendRequest(step as SendRequestStep, requestsById);
      case VisualStepType.delay:
        return _compileDelay(step as DelayStep);
      case VisualStepType.switchStep:
        return _compileSwitch(step as SwitchStep, compiledNodes);
      case VisualStepType.merge:
        return _compileMerge(step as MergeStep);
      case VisualStepType.splitOut:
        return _compileSplitOut(step as SplitOutStep);
      case VisualStepType.aggregate:
        return _compileAggregate(step as AggregateStep);
      case VisualStepType.dateTime:
        return _compileDateTime(step as DateTimeStep);
      case VisualStepType.ifStep:
        return _compileIf(step as IfStep, compiledNodes);
      case VisualStepType.sort:
        return _compileSort(step as SortStep);
      case VisualStepType.limit:
        return _compileLimit(step as LimitStep);
      case VisualStepType.removeDuplicates:
        return _compileRemoveDuplicates(step as RemoveDuplicatesStep);
      case VisualStepType.crypto:
        return _compileCrypto(step as CryptoStep);
      case VisualStepType.jsonConvert:
        return _compileJsonConvert(step as JsonConvertStep);
      case VisualStepType.xmlConvert:
        return _compileXmlConvert(step as XmlConvertStep);
      case VisualStepType.htmlConvert:
        return _compileHtmlConvert(step as HtmlConvertStep);
      case VisualStepType.markdownConvert:
        return _compileMarkdownConvert(step as MarkdownConvertStep);
      case VisualStepType.jsonPathStep:
        return _compileJsonPath(step as JsonPathStep);
      case VisualStepType.headerBuilder:
        return _compileHeaderBuilder(step as HeaderBuilderStep);
      case VisualStepType.start:
        return _compileStart(step as StartStep);
      case VisualStepType.fail:
        return _compileFail(step as FailStep);
      case VisualStepType.end:
        return _compileEnd(step as EndStep);
    }
  }

  static CompiledStep _compileSetVariable(SetVariableStep s) {
    return CompiledSetVariableStep(
      id: s.id,
      name: s.name,
      nextStepId: s.nextStepId,
      assignments: s.assignments
          .map((a) => CompiledAssignment(
                variableName: a.variableName,
                source: compileValueSource(a.valueSource),
              ))
          .toList(),
    );
  }

  static CompiledStep _compileAssertValue(AssertValueStep s) {
    return CompiledAssertValueStep(
      id: s.id,
      name: s.name,
      nextStepId: s.nextStepId,
      left: compileValueSource(s.leftSource),
      operator: s.operator,
      right: compileValueSource(s.rightSource),
    );
  }

  static CompiledStep _compileSendRequest(
    SendRequestStep s,
    Map<String, WorkspaceRequestRef> requestsById,
  ) {
    final ref = s.requestId != null ? requestsById[s.requestId] : null;
    return CompiledSendRequestStep(
      id: s.id,
      name: s.name,
      nextStepId: s.nextStepId,
      method: ref?.method ?? s.method,
      url: ref?.url ?? s.url,
      headers: ref?.headers ?? s.headers,
      body: ref?.body ?? s.body,
      saveToVariable: s.saveToVariable,
    );
  }

  static CompiledStep _compileDelay(DelayStep s) {
    return CompiledDelayStep(
      id: s.id,
      name: s.name,
      nextStepId: s.nextStepId,
      durationMs: s.durationMs,
    );
  }

  static CompiledStep _compileSwitch(
    SwitchStep s,
    Map<String, CompiledStep> compiledNodes,
  ) {
    final List<SwitchCase> compiledCases = [];
    for (int i = 0; i < s.cases.length; i++) {
      final c = s.cases[i];
      String? caseNextId = c.nextStepId;
      if (caseNextId == null || caseNextId.isEmpty) {
        caseNextId = 'virtual_fail_${s.id}_case_$i';
        compiledNodes[caseNextId] = CompiledFailStep(
          id: caseNextId,
          name: 'Virtual Fail (Case: ${c.value})',
        );
      }
      compiledCases.add(SwitchCase(value: c.value, nextStepId: caseNextId));
    }
    String? defaultId = s.defaultStepId;
    if (defaultId == null || defaultId.isEmpty) {
      defaultId = 'virtual_fail_${s.id}_default';
      compiledNodes[defaultId] = CompiledFailStep(
        id: defaultId,
        name: 'Virtual Fail (Default Branch)',
      );
    }
    return CompiledSwitchStep(
      id: s.id,
      name: s.name,
      valueSource: compileValueSource(s.valueSource),
      cases: compiledCases,
      defaultStepId: defaultId,
    );
  }

  static CompiledStep _compileMerge(MergeStep s) {
    return CompiledMergeStep(
      id: s.id,
      name: s.name,
      nextStepId: s.nextStepId,
      strategy: s.strategy,
      sources: s.sources,
      saveTo: s.saveTo,
    );
  }

  static CompiledStep _compileSplitOut(SplitOutStep s) {
    return CompiledSplitOutStep(
      id: s.id,
      name: s.name,
      nextStepId: s.nextStepId,
      arraySource: compileValueSource(s.arraySource),
      loopStepId: s.loopStepId,
      runInParallel: s.runInParallel,
      maxConcurrency: s.maxConcurrency,
    );
  }

  static CompiledStep _compileAggregate(AggregateStep s) {
    return CompiledAggregateStep(
      id: s.id,
      name: s.name,
      nextStepId: s.nextStepId,
      itemSource: compileValueSource(s.itemSource),
      targetListVariable: s.targetListVariable,
    );
  }

  static CompiledStep _compileDateTime(DateTimeStep s) {
    return CompiledDateTimeStep(
      id: s.id,
      name: s.name,
      nextStepId: s.nextStepId,
      operation: s.operation,
      value: s.value,
      formatPattern: s.formatPattern,
      saveToVariable: s.saveToVariable,
    );
  }

  static CompiledStep _compileIf(
    IfStep s,
    Map<String, CompiledStep> compiledNodes,
  ) {
    String? trueId = s.trueStepId;
    if (trueId == null || trueId.isEmpty) {
      trueId = 'virtual_fail_${s.id}_true';
      compiledNodes[trueId] = CompiledFailStep(
        id: trueId,
        name: 'Virtual Fail (True Branch)',
      );
    }
    String? falseId = s.falseStepId;
    if (falseId == null || falseId.isEmpty) {
      falseId = 'virtual_fail_${s.id}_false';
      compiledNodes[falseId] = CompiledFailStep(
        id: falseId,
        name: 'Virtual Fail (False Branch)',
      );
    }
    return CompiledIfStep(
      id: s.id,
      name: s.name,
      left: compileValueSource(s.leftSource),
      operator: s.operator,
      right: compileValueSource(s.rightSource),
      trueStepId: trueId,
      falseStepId: falseId,
    );
  }

  static CompiledStep _compileSort(SortStep s) {
    return CompiledSortStep(
      id: s.id,
      name: s.name,
      nextStepId: s.nextStepId,
      arraySource: compileValueSource(s.arraySource),
      sortByPath: s.sortByPath,
      ascending: s.ascending,
      saveToVariable: s.saveToVariable,
    );
  }

  static CompiledStep _compileLimit(LimitStep s) {
    return CompiledLimitStep(
      id: s.id,
      name: s.name,
      nextStepId: s.nextStepId,
      arraySource: compileValueSource(s.arraySource),
      limit: s.limit,
      offset: s.offset,
      saveToVariable: s.saveToVariable,
    );
  }

  static CompiledStep _compileRemoveDuplicates(RemoveDuplicatesStep s) {
    return CompiledRemoveDuplicatesStep(
      id: s.id,
      name: s.name,
      nextStepId: s.nextStepId,
      arraySource: compileValueSource(s.arraySource),
      comparePath: s.comparePath,
      saveToVariable: s.saveToVariable,
    );
  }

  static CompiledStep _compileCrypto(CryptoStep s) {
    return CompiledCryptoStep(
      id: s.id,
      name: s.name,
      nextStepId: s.nextStepId,
      operation: s.operation,
      valueSource: compileValueSource(s.valueSource),
      keySource: s.keySource != null ? compileValueSource(s.keySource!) : null,
      saveToVariable: s.saveToVariable,
    );
  }

  static CompiledStep _compileJsonConvert(JsonConvertStep s) {
    return CompiledJsonConvertStep(
      id: s.id,
      name: s.name,
      nextStepId: s.nextStepId,
      operation: s.operation,
      valueSource: compileValueSource(s.valueSource),
      saveToVariable: s.saveToVariable,
    );
  }

  static CompiledStep _compileXmlConvert(XmlConvertStep s) {
    return CompiledXmlConvertStep(
      id: s.id,
      name: s.name,
      nextStepId: s.nextStepId,
      operation: s.operation,
      valueSource: compileValueSource(s.valueSource),
      saveToVariable: s.saveToVariable,
    );
  }

  static CompiledStep _compileHtmlConvert(HtmlConvertStep s) {
    return CompiledHtmlConvertStep(
      id: s.id,
      name: s.name,
      nextStepId: s.nextStepId,
      operation: s.operation,
      valueSource: compileValueSource(s.valueSource),
      selector: s.selector,
      attribute: s.attribute,
      saveToVariable: s.saveToVariable,
    );
  }

  static CompiledStep _compileMarkdownConvert(MarkdownConvertStep s) {
    return CompiledMarkdownConvertStep(
      id: s.id,
      name: s.name,
      nextStepId: s.nextStepId,
      operation: s.operation,
      valueSource: compileValueSource(s.valueSource),
      saveToVariable: s.saveToVariable,
    );
  }

  static CompiledStep _compileJsonPath(JsonPathStep s) {
    return CompiledJsonPathStep(
      id: s.id,
      name: s.name,
      nextStepId: s.nextStepId,
      valueSource: compileValueSource(s.valueSource),
      jsonPathExpression: s.jsonPathExpression,
      saveToVariable: s.saveToVariable,
    );
  }

  static CompiledStep _compileHeaderBuilder(HeaderBuilderStep s) {
    return CompiledHeaderBuilderStep(
      id: s.id,
      name: s.name,
      nextStepId: s.nextStepId,
      authType: s.authType,
      tokenSource: compileValueSource(s.tokenSource),
      additionalHeaders: s.additionalHeaders,
      saveToVariable: s.saveToVariable,
    );
  }

  static CompiledStep _compileStart(StartStep s) {
    return CompiledStartStep(
      id: s.id,
      name: s.name,
      nextStepId: s.nextStepId,
    );
  }

  static CompiledStep _compileFail(FailStep s) {
    return CompiledFailStep(
      id: s.id,
      name: s.name,
    );
  }

  static CompiledStep _compileEnd(EndStep s) {
    return CompiledEndStep(
      id: s.id,
      name: s.name,
    );
  }

  static CompiledValueSource compileValueSource(ValueSource source) {
    return CompiledValueSource(
      type: source.type,
      key: source.key,
      jsonPath: source.jsonPath,
    );
  }
}
