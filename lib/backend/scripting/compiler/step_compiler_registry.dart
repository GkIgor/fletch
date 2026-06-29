import 'package:fletch/backend/scripting/compiler/step_compiler.dart';
import 'package:fletch/backend/scripting/models/visual_script.dart';
import 'package:fletch/utils/compiled_script.dart';
import 'package:fletch/utils/script_execution_context.dart';
import 'package:fletch/utils/compiled_steps/compiled_set_variable_step.dart';
import 'package:fletch/utils/compiled_steps/compiled_assert_value_step.dart';
import 'package:fletch/utils/compiled_steps/compiled_if_step.dart';
import 'package:fletch/utils/compiled_steps/compiled_send_request_step.dart';
import 'package:fletch/utils/compiled_steps/compiled_delay_step.dart';
import 'package:fletch/utils/compiled_steps/compiled_switch_step.dart';
import 'package:fletch/utils/compiled_steps/compiled_merge_step.dart';
import 'package:fletch/utils/compiled_steps/compiled_split_out_step.dart';
import 'package:fletch/utils/compiled_steps/compiled_aggregate_step.dart';
import 'package:fletch/utils/compiled_steps/compiled_date_time_step.dart';
import 'package:fletch/utils/compiled_steps/compiled_sort_step.dart';
import 'package:fletch/utils/compiled_steps/compiled_limit_step.dart';
import 'package:fletch/utils/compiled_steps/compiled_remove_duplicates_step.dart';
import 'package:fletch/utils/compiled_steps/compiled_crypto_step.dart';
import 'package:fletch/utils/compiled_steps/compiled_json_convert_step.dart';
import 'package:fletch/utils/compiled_steps/compiled_xml_convert_step.dart';
import 'package:fletch/utils/compiled_steps/compiled_html_convert_step.dart';
import 'package:fletch/utils/compiled_steps/compiled_markdown_convert_step.dart';
import 'package:fletch/utils/compiled_steps/compiled_json_path_step.dart';
import 'package:fletch/utils/compiled_steps/compiled_header_builder_step.dart';
import 'package:fletch/utils/compiled_steps/compiled_start_step.dart';
import 'package:fletch/utils/compiled_steps/compiled_fail_step.dart';
import 'package:fletch/utils/compiled_steps/compiled_end_step.dart';

class StepCompilerRegistry {
  static final Map<VisualStepType, IStepCompiler> _compilers = {
    VisualStepType.setVariable: _SetVariableStepCompiler(),
    VisualStepType.assertValue: _AssertValueStepCompiler(),
    VisualStepType.sendRequest: _SendRequestStepCompiler(),
    VisualStepType.delay: _DelayStepCompiler(),
    VisualStepType.switchStep: _SwitchStepCompiler(),
    VisualStepType.merge: _MergeStepCompiler(),
    VisualStepType.splitOut: _SplitOutStepCompiler(),
    VisualStepType.aggregate: _AggregateStepCompiler(),
    VisualStepType.dateTime: _DateTimeStepCompiler(),
    VisualStepType.ifStep: _IfStepCompiler(),
    VisualStepType.sort: _SortStepCompiler(),
    VisualStepType.limit: _LimitStepCompiler(),
    VisualStepType.removeDuplicates: _RemoveDuplicatesStepCompiler(),
    VisualStepType.crypto: _CryptoStepCompiler(),
    VisualStepType.jsonConvert: _JsonConvertStepCompiler(),
    VisualStepType.xmlConvert: _XmlConvertStepCompiler(),
    VisualStepType.htmlConvert: _HtmlConvertStepCompiler(),
    VisualStepType.markdownConvert: _MarkdownConvertStepCompiler(),
    VisualStepType.jsonPathStep: _JsonPathStepCompiler(),
    VisualStepType.headerBuilder: _HeaderBuilderStepCompiler(),
    VisualStepType.start: _StartStepCompiler(),
    VisualStepType.fail: _FailStepCompiler(),
    VisualStepType.end: _EndStepCompiler(),
  };

  static IStepCompiler? getCompiler(VisualStepType type) => _compilers[type];

  static CompiledValueSource compileValueSource(ValueSource source) {
    return CompiledValueSource(
      type: source.type,
      key: source.key,
      jsonPath: source.jsonPath,
    );
  }
}

class _SetVariableStepCompiler implements IStepCompiler<SetVariableStep> {
  @override
  CompiledStep compile(
    SetVariableStep step,
    Map<String, WorkspaceRequestRef> requestsById,
    Map<String, CompiledStep> compiledNodes,
  ) {
    return CompiledSetVariableStep(
      id: step.id,
      name: step.name,
      nextStepId: step.nextStepId,
      assignments: step.assignments
          .map((a) => CompiledAssignment(
                variableName: a.variableName,
                source: StepCompilerRegistry.compileValueSource(a.valueSource),
              ))
          .toList(),
    );
  }
}

class _AssertValueStepCompiler implements IStepCompiler<AssertValueStep> {
  @override
  CompiledStep compile(
    AssertValueStep step,
    Map<String, WorkspaceRequestRef> requestsById,
    Map<String, CompiledStep> compiledNodes,
  ) {
    return CompiledAssertValueStep(
      id: step.id,
      name: step.name,
      nextStepId: step.nextStepId,
      left: StepCompilerRegistry.compileValueSource(step.leftSource),
      operator: step.operator,
      right: StepCompilerRegistry.compileValueSource(step.rightSource),
    );
  }
}

class _SendRequestStepCompiler implements IStepCompiler<SendRequestStep> {
  @override
  CompiledStep compile(
    SendRequestStep step,
    Map<String, WorkspaceRequestRef> requestsById,
    Map<String, CompiledStep> compiledNodes,
  ) {
    final ref = step.requestId != null ? requestsById[step.requestId] : null;
    return CompiledSendRequestStep(
      id: step.id,
      name: step.name,
      nextStepId: step.nextStepId,
      method: ref?.method ?? step.method,
      url: ref?.url ?? step.url,
      headers: ref?.headers ?? step.headers,
      body: ref?.body ?? step.body,
      saveToVariable: step.saveToVariable,
      auth: ref?.resolvedAuth,
    );
  }
}

class _DelayStepCompiler implements IStepCompiler<DelayStep> {
  @override
  CompiledStep compile(
    DelayStep step,
    Map<String, WorkspaceRequestRef> requestsById,
    Map<String, CompiledStep> compiledNodes,
  ) {
    return CompiledDelayStep(
      id: step.id,
      name: step.name,
      nextStepId: step.nextStepId,
      durationMs: step.durationMs,
    );
  }
}

class _SwitchStepCompiler implements IStepCompiler<SwitchStep> {
  @override
  CompiledStep compile(
    SwitchStep step,
    Map<String, WorkspaceRequestRef> requestsById,
    Map<String, CompiledStep> compiledNodes,
  ) {
    final List<SwitchCase> compiledCases = [];
    for (int i = 0; i < step.cases.length; i++) {
      final c = step.cases[i];
      String? caseNextId = c.nextStepId;
      if (caseNextId == null || caseNextId.isEmpty) {
        caseNextId = 'virtual_fail_${step.id}_case_$i';
        compiledNodes[caseNextId] = CompiledFailStep(
          id: caseNextId,
          name: 'Virtual Fail (Case: ${c.value})',
        );
      }
      compiledCases.add(SwitchCase(value: c.value, nextStepId: caseNextId));
    }
    String? defaultId = step.defaultStepId;
    if (defaultId == null || defaultId.isEmpty) {
      defaultId = 'virtual_fail_${step.id}_default';
      compiledNodes[defaultId] = CompiledFailStep(
        id: defaultId,
        name: 'Virtual Fail (Default Branch)',
      );
    }
    return CompiledSwitchStep(
      id: step.id,
      name: step.name,
      valueSource: StepCompilerRegistry.compileValueSource(step.valueSource),
      cases: compiledCases,
      defaultStepId: defaultId,
    );
  }
}

class _MergeStepCompiler implements IStepCompiler<MergeStep> {
  @override
  CompiledStep compile(
    MergeStep step,
    Map<String, WorkspaceRequestRef> requestsById,
    Map<String, CompiledStep> compiledNodes,
  ) {
    return CompiledMergeStep(
      id: step.id,
      name: step.name,
      nextStepId: step.nextStepId,
      strategy: step.strategy,
      sources: step.sources,
      saveTo: step.saveTo,
    );
  }
}

class _SplitOutStepCompiler implements IStepCompiler<SplitOutStep> {
  @override
  CompiledStep compile(
    SplitOutStep step,
    Map<String, WorkspaceRequestRef> requestsById,
    Map<String, CompiledStep> compiledNodes,
  ) {
    return CompiledSplitOutStep(
      id: step.id,
      name: step.name,
      nextStepId: step.nextStepId,
      arraySource: StepCompilerRegistry.compileValueSource(step.arraySource),
      loopStepId: step.loopStepId,
      runInParallel: step.runInParallel,
      maxConcurrency: step.maxConcurrency,
    );
  }
}

class _AggregateStepCompiler implements IStepCompiler<AggregateStep> {
  @override
  CompiledStep compile(
    AggregateStep step,
    Map<String, WorkspaceRequestRef> requestsById,
    Map<String, CompiledStep> compiledNodes,
  ) {
    return CompiledAggregateStep(
      id: step.id,
      name: step.name,
      nextStepId: step.nextStepId,
      itemSource: StepCompilerRegistry.compileValueSource(step.itemSource),
      targetListVariable: step.targetListVariable,
    );
  }
}

class _DateTimeStepCompiler implements IStepCompiler<DateTimeStep> {
  @override
  CompiledStep compile(
    DateTimeStep step,
    Map<String, WorkspaceRequestRef> requestsById,
    Map<String, CompiledStep> compiledNodes,
  ) {
    return CompiledDateTimeStep(
      id: step.id,
      name: step.name,
      nextStepId: step.nextStepId,
      operation: step.operation,
      value: step.value,
      formatPattern: step.formatPattern,
      saveToVariable: step.saveToVariable,
    );
  }
}

class _IfStepCompiler implements IStepCompiler<IfStep> {
  @override
  CompiledStep compile(
    IfStep step,
    Map<String, WorkspaceRequestRef> requestsById,
    Map<String, CompiledStep> compiledNodes,
  ) {
    String? trueId = step.trueStepId;
    if (trueId == null || trueId.isEmpty) {
      trueId = 'virtual_fail_${step.id}_true';
      compiledNodes[trueId] = CompiledFailStep(
        id: trueId,
        name: 'Virtual Fail (True Branch)',
      );
    }
    String? falseId = step.falseStepId;
    if (falseId == null || falseId.isEmpty) {
      falseId = 'virtual_fail_${step.id}_false';
      compiledNodes[falseId] = CompiledFailStep(
        id: falseId,
        name: 'Virtual Fail (False Branch)',
      );
    }
    return CompiledIfStep(
      id: step.id,
      name: step.name,
      left: StepCompilerRegistry.compileValueSource(step.leftSource),
      operator: step.operator,
      right: StepCompilerRegistry.compileValueSource(step.rightSource),
      trueStepId: trueId,
      falseStepId: falseId,
    );
  }
}

class _SortStepCompiler implements IStepCompiler<SortStep> {
  @override
  CompiledStep compile(
    SortStep step,
    Map<String, WorkspaceRequestRef> requestsById,
    Map<String, CompiledStep> compiledNodes,
  ) {
    return CompiledSortStep(
      id: step.id,
      name: step.name,
      nextStepId: step.nextStepId,
      arraySource: StepCompilerRegistry.compileValueSource(step.arraySource),
      sortByPath: step.sortByPath,
      ascending: step.ascending,
      saveToVariable: step.saveToVariable,
    );
  }
}

class _LimitStepCompiler implements IStepCompiler<LimitStep> {
  @override
  CompiledStep compile(
    LimitStep step,
    Map<String, WorkspaceRequestRef> requestsById,
    Map<String, CompiledStep> compiledNodes,
  ) {
    return CompiledLimitStep(
      id: step.id,
      name: step.name,
      nextStepId: step.nextStepId,
      arraySource: StepCompilerRegistry.compileValueSource(step.arraySource),
      limit: step.limit,
      offset: step.offset,
      saveToVariable: step.saveToVariable,
    );
  }
}

class _RemoveDuplicatesStepCompiler implements IStepCompiler<RemoveDuplicatesStep> {
  @override
  CompiledStep compile(
    RemoveDuplicatesStep step,
    Map<String, WorkspaceRequestRef> requestsById,
    Map<String, CompiledStep> compiledNodes,
  ) {
    return CompiledRemoveDuplicatesStep(
      id: step.id,
      name: step.name,
      nextStepId: step.nextStepId,
      arraySource: StepCompilerRegistry.compileValueSource(step.arraySource),
      comparePath: step.comparePath,
      saveToVariable: step.saveToVariable,
    );
  }
}

class _CryptoStepCompiler implements IStepCompiler<CryptoStep> {
  @override
  CompiledStep compile(
    CryptoStep step,
    Map<String, WorkspaceRequestRef> requestsById,
    Map<String, CompiledStep> compiledNodes,
  ) {
    return CompiledCryptoStep(
      id: step.id,
      name: step.name,
      nextStepId: step.nextStepId,
      operation: step.operation,
      valueSource: StepCompilerRegistry.compileValueSource(step.valueSource),
      keySource: step.keySource != null ? StepCompilerRegistry.compileValueSource(step.keySource!) : null,
      saveToVariable: step.saveToVariable,
    );
  }
}

class _JsonConvertStepCompiler implements IStepCompiler<JsonConvertStep> {
  @override
  CompiledStep compile(
    JsonConvertStep step,
    Map<String, WorkspaceRequestRef> requestsById,
    Map<String, CompiledStep> compiledNodes,
  ) {
    return CompiledJsonConvertStep(
      id: step.id,
      name: step.name,
      nextStepId: step.nextStepId,
      operation: step.operation,
      valueSource: StepCompilerRegistry.compileValueSource(step.valueSource),
      saveToVariable: step.saveToVariable,
    );
  }
}

class _XmlConvertStepCompiler implements IStepCompiler<XmlConvertStep> {
  @override
  CompiledStep compile(
    XmlConvertStep step,
    Map<String, WorkspaceRequestRef> requestsById,
    Map<String, CompiledStep> compiledNodes,
  ) {
    return CompiledXmlConvertStep(
      id: step.id,
      name: step.name,
      nextStepId: step.nextStepId,
      operation: step.operation,
      valueSource: StepCompilerRegistry.compileValueSource(step.valueSource),
      saveToVariable: step.saveToVariable,
    );
  }
}

class _HtmlConvertStepCompiler implements IStepCompiler<HtmlConvertStep> {
  @override
  CompiledStep compile(
    HtmlConvertStep step,
    Map<String, WorkspaceRequestRef> requestsById,
    Map<String, CompiledStep> compiledNodes,
  ) {
    return CompiledHtmlConvertStep(
      id: step.id,
      name: step.name,
      nextStepId: step.nextStepId,
      operation: step.operation,
      valueSource: StepCompilerRegistry.compileValueSource(step.valueSource),
      selector: step.selector,
      attribute: step.attribute,
      saveToVariable: step.saveToVariable,
    );
  }
}

class _MarkdownConvertStepCompiler implements IStepCompiler<MarkdownConvertStep> {
  @override
  CompiledStep compile(
    MarkdownConvertStep step,
    Map<String, WorkspaceRequestRef> requestsById,
    Map<String, CompiledStep> compiledNodes,
  ) {
    return CompiledMarkdownConvertStep(
      id: step.id,
      name: step.name,
      nextStepId: step.nextStepId,
      operation: step.operation,
      valueSource: StepCompilerRegistry.compileValueSource(step.valueSource),
      saveToVariable: step.saveToVariable,
    );
  }
}

class _JsonPathStepCompiler implements IStepCompiler<JsonPathStep> {
  @override
  CompiledStep compile(
    JsonPathStep step,
    Map<String, WorkspaceRequestRef> requestsById,
    Map<String, CompiledStep> compiledNodes,
  ) {
    return CompiledJsonPathStep(
      id: step.id,
      name: step.name,
      nextStepId: step.nextStepId,
      valueSource: StepCompilerRegistry.compileValueSource(step.valueSource),
      jsonPathExpression: step.jsonPathExpression,
      saveToVariable: step.saveToVariable,
    );
  }
}

class _HeaderBuilderStepCompiler implements IStepCompiler<HeaderBuilderStep> {
  @override
  CompiledStep compile(
    HeaderBuilderStep step,
    Map<String, WorkspaceRequestRef> requestsById,
    Map<String, CompiledStep> compiledNodes,
  ) {
    return CompiledHeaderBuilderStep(
      id: step.id,
      name: step.name,
      nextStepId: step.nextStepId,
      authType: step.authType,
      tokenSource: StepCompilerRegistry.compileValueSource(step.tokenSource),
      additionalHeaders: step.additionalHeaders,
      saveToVariable: step.saveToVariable,
    );
  }
}

class _StartStepCompiler implements IStepCompiler<StartStep> {
  @override
  CompiledStep compile(
    StartStep step,
    Map<String, WorkspaceRequestRef> requestsById,
    Map<String, CompiledStep> compiledNodes,
  ) {
    return CompiledStartStep(
      id: step.id,
      name: step.name,
      nextStepId: step.nextStepId,
    );
  }
}

class _FailStepCompiler implements IStepCompiler<FailStep> {
  @override
  CompiledStep compile(
    FailStep step,
    Map<String, WorkspaceRequestRef> requestsById,
    Map<String, CompiledStep> compiledNodes,
  ) {
    return CompiledFailStep(
      id: step.id,
      name: step.name,
    );
  }
}

class _EndStepCompiler implements IStepCompiler<EndStep> {
  @override
  CompiledStep compile(
    EndStep step,
    Map<String, WorkspaceRequestRef> requestsById,
    Map<String, CompiledStep> compiledNodes,
  ) {
    return CompiledEndStep(
      id: step.id,
      name: step.name,
    );
  }
}
