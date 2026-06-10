// Optimized compiled scripts and execution-ready instruction steps (JIT Engine) for Fletch.
import 'dart:convert';
import '../models/visual_script.dart';

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
}

/// Abstract base execution instruction.
abstract class CompiledStep {
  Future<void> execute(ExecutionContext context);
}

/// A sequential list of executable compiled steps.
class CompiledScript {
  final List<CompiledStep> steps;

  CompiledScript({required this.steps});

  Future<void> execute(ExecutionContext context) async {
    for (var step in steps) {
      await step.execute(context);
    }
  }
}

/// A JIT-compiled source operand. Resolves its value dynamically.
class CompiledValueSource {
  final ValueSourceType type;
  final String key;
  final List<dynamic>? jsonPathTokens;

  CompiledValueSource({
    required this.type,
    required this.key,
    this.jsonPathTokens,
  });

  String resolve(ExecutionContext context) {
    switch (type) {
      case ValueSourceType.constant:
        return _interpolate(key, context);
      case ValueSourceType.responseStatusCode:
        return context.statusCode.toString();
      case ValueSourceType.responseHeader:
        return context.responseHeaders[key] ?? '';
      case ValueSourceType.variable:
        return context.variables[key] ?? '';
      case ValueSourceType.responseBody:
        if (context.responseBody == null) return '';
        if (jsonPathTokens != null && jsonPathTokens!.isNotEmpty) {
          final extracted = _extractFromJson(context.responseBody!, jsonPathTokens!);
          return extracted?.toString() ?? '';
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
    final compiledSteps = <CompiledStep>[];

    for (var step in script.steps) {
      if (!step.enabled) continue;

      switch (step.type) {
        case VisualStepType.setVariable:
          final s = step as SetVariableStep;
          compiledSteps.add(CompiledSetVariableStep(
            variableName: s.variableName,
            source: compileValueSource(s.valueSource),
          ));
          break;
        case VisualStepType.assertValue:
          final s = step as AssertValueStep;
          compiledSteps.add(CompiledAssertValueStep(
            left: compileValueSource(s.leftSource),
            operator: s.operator,
            right: compileValueSource(s.rightSource),
          ));
          break;
        case VisualStepType.sendRequest:
          final s = step as SendRequestStep;
          compiledSteps.add(CompiledSendRequestStep(
            method: s.method,
            url: s.url,
            headers: s.headers,
            body: s.body,
            saveToVariable: s.saveToVariable,
          ));
          break;
        case VisualStepType.delay:
          final s = step as DelayStep;
          compiledSteps.add(CompiledDelayStep(durationMs: s.durationMs));
          break;
      }
    }

    return CompiledScript(steps: compiledSteps);
  }

  static CompiledValueSource compileValueSource(ValueSource source) {
    return CompiledValueSource(
      type: source.type,
      key: source.key,
      jsonPathTokens: _parseJsonPathTokens(source.jsonPath),
    );
  }

  /// Parses JSONPath e.g. "data.users[0].name" into ['data', 'users', 0, 'name']
  static List<dynamic>? _parseJsonPathTokens(String path) {
    if (path.isEmpty) return null;
    
    final segments = path.split('.');
    final List<dynamic> tokens = [];

    for (var segment in segments) {
      if (segment.contains('[') && segment.endsWith(']')) {
        final openIdx = segment.indexOf('[');
        final arrayName = segment.substring(0, openIdx);
        final indexStr = segment.substring(openIdx + 1, segment.length - 1);
        final index = int.tryParse(indexStr);

        if (arrayName.isNotEmpty) {
          tokens.add(arrayName);
        }
        if (index != null) {
          tokens.add(index);
        }
      } else {
        tokens.add(segment);
      }
    }
    return tokens;
  }
}

// -------------------------------------------------------------
// Concrete runtime instruction implementations (Low-Code Engine)
// -------------------------------------------------------------

class CompiledSetVariableStep extends CompiledStep {
  final String variableName;
  final CompiledValueSource source;

  CompiledSetVariableStep({
    required this.variableName,
    required this.source,
  });

  @override
  Future<void> execute(ExecutionContext context) async {
    if (variableName.isEmpty) return;
    context.variables[variableName] = source.resolve(context);
  }
}

class CompiledAssertValueStep extends CompiledStep {
  final CompiledValueSource left;
  final String operator;
  final CompiledValueSource right;

  CompiledAssertValueStep({
    required this.left,
    required this.operator,
    required this.right,
  });

  @override
  Future<void> execute(ExecutionContext context) async {
    final leftVal = left.resolve(context);
    final rightVal = right.resolve(context);

    bool isPassed = false;
    switch (operator) {
      case '==':
        isPassed = leftVal == rightVal;
        break;
      case '!=':
        isPassed = leftVal != rightVal;
        break;
      case 'contains':
        isPassed = leftVal.contains(rightVal);
        break;
      case '>':
        final lNum = double.tryParse(leftVal);
        final rNum = double.tryParse(rightVal);
        isPassed = (lNum != null && rNum != null) ? lNum > rNum : false;
        break;
      case '<':
        final lNum = double.tryParse(leftVal);
        final rNum = double.tryParse(rightVal);
        isPassed = (lNum != null && rNum != null) ? lNum < rNum : false;
        break;
    }

    if (!isPassed) {
      throw Exception('Assertion Failed: "$leftVal" $operator "$rightVal"');
    }
  }
}

class CompiledSendRequestStep extends CompiledStep {
  final String method;
  final String url;
  final Map<String, String> headers;
  final String? body;
  final String saveToVariable;

  CompiledSendRequestStep({
    required this.method,
    required this.url,
    required this.headers,
    this.body,
    required this.saveToVariable,
  });

  @override
  Future<void> execute(ExecutionContext context) async {
    // Core sandboxed execution helper - will hook into HttpService in executor
  }
}

class CompiledDelayStep extends CompiledStep {
  final int durationMs;

  CompiledDelayStep({required this.durationMs});

  @override
  Future<void> execute(ExecutionContext context) async {
    if (durationMs <= 0) return;
    await Future.delayed(Duration(milliseconds: durationMs));
  }
}

// -------------------------------------------------------------
// Shared JIT compilation utility methods
// -------------------------------------------------------------

dynamic _extractFromJson(String body, List<dynamic> tokens) {
  try {
    dynamic current = jsonDecode(body);
    for (var token in tokens) {
      if (current == null) return null;
      if (token is String && current is Map) {
        current = current[token];
      } else if (token is int && current is List) {
        if (token >= 0 && token < current.length) {
          current = current[token];
        } else {
          return null;
        }
      } else {
        return null;
      }
    }
    return current;
  } catch (_) {
    return null;
  }
}

String _interpolate(String value, ExecutionContext context) {
  String result = value;
  final regex = RegExp(r'\{\{(.+?)\}\}');
  final matches = regex.allMatches(value).toList();

  for (var match in matches.reversed) {
    final key = match.group(1)!.trim();
    if (context.variables.containsKey(key)) {
      result = result.replaceRange(match.start, match.end, context.variables[key]!);
    }
  }
  return result;
}
