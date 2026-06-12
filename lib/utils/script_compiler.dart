// JIT Engine, ExecutionLog, and compiled instruction steps for Fletch visual automation scripts.
import 'dart:convert';
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

enum LogLevel { info, warn, error, debug }

class ExecutionLog {
  final DateTime timestamp;
  final LogLevel level;
  final String nodeId;
  final String nodeName;
  final String message;

  ExecutionLog({
    required this.timestamp,
    required this.level,
    required this.nodeId,
    required this.nodeName,
    required this.message,
  });

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'level': level.name,
        'nodeId': nodeId,
        'nodeName': nodeName,
        'message': message,
      };
}

class ExecutionResult {
  final bool success;
  final String? nextNodeId;
  final String? error;

  ExecutionResult({
    required this.success,
    this.nextNodeId,
    this.error,
  });
}

/// Isolation context for visual script executions.
class ExecutionContext {
  final Map<String, String> variables;
  final Map<String, String> headers;
  final Map<String, String> queryParams;
  String url;
  String? body;
  
  // Response metadata (available in post-response scripts)
  int statusCode;
  String? responseBody;
  Map<String, String> responseHeaders;

  // HTTP execution callback
  Future<Map<String, dynamic>> Function(String method, String url, Map<String, String> headers, String? body)? httpExecutor;

  // Execution logs
  final List<ExecutionLog> logs = [];

  ExecutionContext({
    Map<String, String>? variables,
    Map<String, String>? headers,
    Map<String, String>? queryParams,
    this.url = '',
    this.body,
    this.statusCode = 0,
    this.responseBody,
    Map<String, String>? responseHeaders,
  })  : variables = variables ?? {},
        headers = headers ?? {},
        queryParams = queryParams ?? {},
        responseHeaders = responseHeaders ?? {};

  void log(String nodeId, String nodeName, String message, {LogLevel level = LogLevel.info}) {
    logs.add(ExecutionLog(
      timestamp: DateTime.now(),
      level: level,
      nodeId: nodeId,
      nodeName: nodeName,
      message: message,
    ));
  }
}

/// Abstract base execution instruction.
abstract class CompiledStep {
  final String id;
  final String name;

  CompiledStep({required this.id, required this.name});

  Future<ExecutionResult> execute(ExecutionContext context, Map<String, CompiledStep> nodes);
}

/// A sequential/connected runner of compiled steps.
class CompiledScript {
  final Map<String, CompiledStep> nodes;
  final String? startNodeId;

  CompiledScript({required this.nodes, this.startNodeId});

  Future<void> execute(ExecutionContext context) async {
    String? currentId = startNodeId;
    int stepsCount = 0;
    const maxSteps = 10000;

    context.log('script', 'System', 'Iniciando execução do script...', level: LogLevel.info);

    while (currentId != null && stepsCount < maxSteps) {
      final step = nodes[currentId];
      if (step == null) {
        context.log('script', 'System', 'Erro de compilação: conexão morta que aponta para ID "$currentId".', level: LogLevel.error);
        throw Exception('Erro de compilação: conexão morta que aponta para ID "$currentId".');
      }

      stepsCount++;
      final result = await step.execute(context, nodes);
      if (!result.success) {
        context.log(step.id, step.name, 'Falha no nó: ${result.error}', level: LogLevel.error);
        throw Exception('Execution failed in node "${step.name}": ${result.error}');
      }
      currentId = result.nextNodeId;
    }

    if (stepsCount >= maxSteps) {
      context.log('script', 'System', 'Limite de execuções de nós ($maxSteps) excedido (possível loop infinito ou ciclo sem delay).', level: LogLevel.error);
      throw Exception('Limite de execuções excedido (possível loop infinito).');
    }

    context.log('script', 'System', 'Execução concluída com sucesso.', level: LogLevel.info);
  }
}

/// A JIT-compiled source operand. Resolves its value dynamically using the scope model.
class CompiledValueSource {
  final ValueSourceType type;
  final String key;
  final String jsonPath;

  CompiledValueSource({
    required this.type,
    required this.key,
    required this.jsonPath,
  });

  String resolve(ExecutionContext context) {
    switch (type) {
      case ValueSourceType.constant:
        return interpolate(key, context);
      case ValueSourceType.responseStatusCode:
        return context.statusCode.toString();
      case ValueSourceType.responseHeader:
        return context.responseHeaders[key] ?? '';
      case ValueSourceType.variable:
        if (key.startsWith('globals.') ||
            key.startsWith('response.') ||
            key.startsWith('request.') ||
            key == 'item' ||
            key.startsWith('item.') ||
            key == 'index') {
          return resolveScopePath(key, context)?.toString() ?? '';
        }
        return context.variables[key] ?? '';
      case ValueSourceType.responseBody:
        if (context.responseBody == null || context.responseBody!.isEmpty) return '';
        if (jsonPath.isNotEmpty) {
          try {
            final decoded = jsonDecode(context.responseBody!);
            final extracted = getValueByPath(decoded, jsonPath);
            return extracted?.toString() ?? '';
          } catch (_) {
            return '';
          }
        }
        return context.responseBody!;
    }
  }
}

/// JIT Compilation Cache containing compiled scripts.
class JitCache {
  static final Map<String, CompiledScript> _cache = {};
  static final Map<String, DateTime> _timestamps = {};

  static CompiledScript getOrCreate(VisualScript script) {
    final cached = _cache[script.id];
    final lastModified = _timestamps[script.id];

    if (cached != null && lastModified != null && !lastModified.isBefore(script.updatedAt)) {
      return cached;
    }

    // Compile and cache
    final compiled = ScriptCompiler.compile(script);
    _cache[script.id] = compiled;
    _timestamps[script.id] = script.updatedAt;
    return compiled;
  }

  static void invalidate(String scriptId) {
    _cache.remove(scriptId);
    _timestamps.remove(scriptId);
  }

  static void clear() {
    _cache.clear();
    _timestamps.clear();
  }
}

/// JIT Compiler that translates VisualScript structures to optimized runtime representations.
class ScriptCompiler {
  static CompiledScript compile(VisualScript script) {
    final Map<String, CompiledStep> compiledNodes = {};

    script.nodes.forEach((id, step) {
      if (!step.enabled) return;

      switch (step.type) {
        case VisualStepType.setVariable:
          final s = step as SetVariableStep;
          compiledNodes[id] = CompiledSetVariableStep(
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
          break;
        case VisualStepType.assertValue:
          final s = step as AssertValueStep;
          compiledNodes[id] = CompiledAssertValueStep(
            id: s.id,
            name: s.name,
            nextStepId: s.nextStepId,
            left: compileValueSource(s.leftSource),
            operator: s.operator,
            right: compileValueSource(s.rightSource),
          );
          break;
        case VisualStepType.sendRequest:
          final s = step as SendRequestStep;
          compiledNodes[id] = CompiledSendRequestStep(
            id: s.id,
            name: s.name,
            nextStepId: s.nextStepId,
            method: s.method,
            url: s.url,
            headers: s.headers,
            body: s.body,
            saveToVariable: s.saveToVariable,
          );
          break;
        case VisualStepType.delay:
          final s = step as DelayStep;
          compiledNodes[id] = CompiledDelayStep(
            id: s.id,
            name: s.name,
            nextStepId: s.nextStepId,
            durationMs: s.durationMs,
          );
          break;
        case VisualStepType.switchStep:
          final s = step as SwitchStep;
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
          compiledNodes[id] = CompiledSwitchStep(
            id: s.id,
            name: s.name,
            valueSource: compileValueSource(s.valueSource),
            cases: compiledCases,
            defaultStepId: defaultId,
          );
          break;
        case VisualStepType.merge:
          final s = step as MergeStep;
          compiledNodes[id] = CompiledMergeStep(
            id: s.id,
            name: s.name,
            nextStepId: s.nextStepId,
            strategy: s.strategy,
            sources: s.sources,
            saveTo: s.saveTo,
          );
          break;
        case VisualStepType.splitOut:
          final s = step as SplitOutStep;
          compiledNodes[id] = CompiledSplitOutStep(
            id: s.id,
            name: s.name,
            nextStepId: s.nextStepId,
            arraySource: compileValueSource(s.arraySource),
            loopStepId: s.loopStepId,
            runInParallel: s.runInParallel,
            maxConcurrency: s.maxConcurrency,
          );
          break;
        case VisualStepType.aggregate:
          final s = step as AggregateStep;
          compiledNodes[id] = CompiledAggregateStep(
            id: s.id,
            name: s.name,
            nextStepId: s.nextStepId,
            itemSource: compileValueSource(s.itemSource),
            targetListVariable: s.targetListVariable,
          );
          break;
        case VisualStepType.dateTime:
          final s = step as DateTimeStep;
          compiledNodes[id] = CompiledDateTimeStep(
            id: s.id,
            name: s.name,
            nextStepId: s.nextStepId,
            operation: s.operation,
            value: s.value,
            formatPattern: s.formatPattern,
            saveToVariable: s.saveToVariable,
          );
          break;
        case VisualStepType.ifStep:
          final s = step as IfStep;
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
          compiledNodes[id] = CompiledIfStep(
            id: s.id,
            name: s.name,
            left: compileValueSource(s.leftSource),
            operator: s.operator,
            right: compileValueSource(s.rightSource),
            trueStepId: trueId,
            falseStepId: falseId,
          );
          break;
        case VisualStepType.sort:
          final s = step as SortStep;
          compiledNodes[id] = CompiledSortStep(
            id: s.id,
            name: s.name,
            nextStepId: s.nextStepId,
            arraySource: compileValueSource(s.arraySource),
            sortByPath: s.sortByPath,
            ascending: s.ascending,
            saveToVariable: s.saveToVariable,
          );
          break;
        case VisualStepType.limit:
          final s = step as LimitStep;
          compiledNodes[id] = CompiledLimitStep(
            id: s.id,
            name: s.name,
            nextStepId: s.nextStepId,
            arraySource: compileValueSource(s.arraySource),
            limit: s.limit,
            offset: s.offset,
            saveToVariable: s.saveToVariable,
          );
          break;
        case VisualStepType.removeDuplicates:
          final s = step as RemoveDuplicatesStep;
          compiledNodes[id] = CompiledRemoveDuplicatesStep(
            id: s.id,
            name: s.name,
            nextStepId: s.nextStepId,
            arraySource: compileValueSource(s.arraySource),
            comparePath: s.comparePath,
            saveToVariable: s.saveToVariable,
          );
          break;
        case VisualStepType.crypto:
          final s = step as CryptoStep;
          compiledNodes[id] = CompiledCryptoStep(
            id: s.id,
            name: s.name,
            nextStepId: s.nextStepId,
            operation: s.operation,
            valueSource: compileValueSource(s.valueSource),
            keySource: s.keySource != null ? compileValueSource(s.keySource!) : null,
            saveToVariable: s.saveToVariable,
          );
          break;
        case VisualStepType.jsonConvert:
          final s = step as JsonConvertStep;
          compiledNodes[id] = CompiledJsonConvertStep(
            id: s.id,
            name: s.name,
            nextStepId: s.nextStepId,
            operation: s.operation,
            valueSource: compileValueSource(s.valueSource),
            saveToVariable: s.saveToVariable,
          );
          break;
        case VisualStepType.xmlConvert:
          final s = step as XmlConvertStep;
          compiledNodes[id] = CompiledXmlConvertStep(
            id: s.id,
            name: s.name,
            nextStepId: s.nextStepId,
            operation: s.operation,
            valueSource: compileValueSource(s.valueSource),
            saveToVariable: s.saveToVariable,
          );
          break;
        case VisualStepType.htmlConvert:
          final s = step as HtmlConvertStep;
          compiledNodes[id] = CompiledHtmlConvertStep(
            id: s.id,
            name: s.name,
            nextStepId: s.nextStepId,
            operation: s.operation,
            valueSource: compileValueSource(s.valueSource),
            selector: s.selector,
            attribute: s.attribute,
            saveToVariable: s.saveToVariable,
          );
          break;
        case VisualStepType.markdownConvert:
          final s = step as MarkdownConvertStep;
          compiledNodes[id] = CompiledMarkdownConvertStep(
            id: s.id,
            name: s.name,
            nextStepId: s.nextStepId,
            operation: s.operation,
            valueSource: compileValueSource(s.valueSource),
            saveToVariable: s.saveToVariable,
          );
          break;
        case VisualStepType.jsonPathStep:
          final s = step as JsonPathStep;
          compiledNodes[id] = CompiledJsonPathStep(
            id: s.id,
            name: s.name,
            nextStepId: s.nextStepId,
            valueSource: compileValueSource(s.valueSource),
            jsonPathExpression: s.jsonPathExpression,
            saveToVariable: s.saveToVariable,
          );
          break;
        case VisualStepType.headerBuilder:
          final s = step as HeaderBuilderStep;
          compiledNodes[id] = CompiledHeaderBuilderStep(
            id: s.id,
            name: s.name,
            nextStepId: s.nextStepId,
            authType: s.authType,
            tokenSource: compileValueSource(s.tokenSource),
            additionalHeaders: s.additionalHeaders,
            saveToVariable: s.saveToVariable,
          );
          break;
        case VisualStepType.start:
          final s = step as StartStep;
          compiledNodes[id] = CompiledStartStep(
            id: s.id,
            name: s.name,
            nextStepId: s.nextStepId,
          );
          break;
        case VisualStepType.fail:
          final s = step as FailStep;
          compiledNodes[id] = CompiledFailStep(
            id: s.id,
            name: s.name,
          );
          break;
        case VisualStepType.end:
          final s = step as EndStep;
          compiledNodes[id] = CompiledEndStep(
            id: s.id,
            name: s.name,
          );
          break;
      }
    });

    return CompiledScript(
      nodes: compiledNodes,
      startNodeId: script.startNodeId,
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

class CompiledAssignment {
  final String variableName;
  final CompiledValueSource source;

  CompiledAssignment({required this.variableName, required this.source});
}

// -------------------------------------------------------------
// Shared JIT compilation utility methods
// -------------------------------------------------------------

dynamic getValueByPath(dynamic obj, String path) {
  if (obj == null) return null;
  final parts = path.split('.');
  dynamic current = obj;
  for (var part in parts) {
    if (current == null) return null;
    if (part.contains('[') && part.endsWith(']')) {
      final openIdx = part.indexOf('[');
      final arrayName = part.substring(0, openIdx);
      final indexStr = part.substring(openIdx + 1, part.length - 1);
      final index = int.tryParse(indexStr);

      if (arrayName.isNotEmpty) {
        if (current is Map) {
          current = current[arrayName];
        } else {
          return null;
        }
      }
      if (index != null && current is List) {
        if (index >= 0 && index < current.length) {
          current = current[index];
        } else {
          return null;
        }
      } else if (index != null) {
        return null;
      }
    } else {
      if (current is Map) {
        current = current[part];
      } else {
        return null;
      }
    }
  }
  return current;
}

dynamic resolveScopePath(String path, ExecutionContext context) {
  if (path == 'index') {
    return context.variables['index'];
  }
  if (path == 'item') {
    return context.variables['item'];
  }
  if (path.startsWith('item.')) {
    final rest = path.substring(5);
    final itemStr = context.variables['item'];
    if (itemStr == null || itemStr.isEmpty) return null;
    try {
      final decoded = jsonDecode(itemStr);
      return getValueByPath(decoded, rest);
    } catch (_) {
      return null;
    }
  }
  if (path.startsWith('globals.')) {
    final key = path.substring(8);
    return context.variables[key];
  }
  if (path.startsWith('response.')) {
    if (path == 'response.body') {
      return context.responseBody;
    }
    if (path == 'response.status') {
      return context.statusCode;
    }
    if (path.startsWith('response.headers.')) {
      final key = path.substring(17);
      return context.responseHeaders[key];
    }
    if (path.startsWith('response.body.')) {
      final rest = path.substring(14);
      if (context.responseBody == null || context.responseBody!.isEmpty) return null;
      try {
        final decoded = jsonDecode(context.responseBody!);
        return getValueByPath(decoded, rest);
      } catch (_) {
        return null;
      }
    }
  }
  if (path.startsWith('request.')) {
    if (path == 'request.url') {
      return context.url;
    }
    if (path == 'request.body') {
      return context.body;
    }
    if (path.startsWith('request.headers.')) {
      final key = path.substring(16);
      return context.headers[key];
    }
    if (path.startsWith('request.queryParams.')) {
      final key = path.substring(20);
      return context.queryParams[key];
    }
  }
  return null;
}

String interpolate(String value, ExecutionContext context) {
  String result = value;
  final regex = RegExp(r'\{\{(.+?)\}\}');
  final matches = regex.allMatches(value).toList();

  for (var match in matches.reversed) {
    final key = match.group(1)!.trim();
    final resolved = resolveScopePath(key, context) ?? context.variables[key];
    if (resolved != null) {
      result = result.replaceRange(match.start, match.end, resolved.toString());
    }
  }
  return result;
}
