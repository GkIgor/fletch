import '../models/visual_script.dart';
import 'script_execution_context.dart';

/// Abstract base execution instruction.
abstract class CompiledStep {
  final String id;
  final String name;

  CompiledStep({required this.id, required this.name});

  Future<ExecutionResult> execute(
    ExecutionContext context,
    Map<String, CompiledStep> nodes,
  );
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

    context.log(
      'script',
      'System',
      'Iniciando execução do script...',
      level: LogLevel.info,
    );

    while (currentId != null && stepsCount < maxSteps) {
      final step = nodes[currentId];
      if (step == null) {
        context.log(
          'script',
          'System',
          'Erro de compilação: conexão morta que aponta para ID "$currentId".',
          level: LogLevel.error,
        );
        throw Exception(
          'Erro de compilação: conexão morta que aponta para ID "$currentId".',
        );
      }

      stepsCount++;
      final result = await step.execute(context, nodes);
      if (!result.success) {
        context.log(
          step.id,
          step.name,
          'Falha no nó: ${result.error}',
          level: LogLevel.error,
        );
        throw Exception(
          'Execution failed in node "${step.name}": ${result.error}',
        );
      }
      currentId = result.nextNodeId;
    }

    if (stepsCount >= maxSteps) {
      context.log(
        'script',
        'System',
        'Limite de execuções de nós ($maxSteps) excedido (possível loop infinito ou ciclo sem delay).',
        level: LogLevel.error,
      );
      throw Exception('Limite de execuções excedido (possível loop infinito).');
    }

    context.log(
      'script',
      'System',
      'Execução concluída com sucesso.',
      level: LogLevel.info,
    );
  }
}

/// A JIT-compiled source operand. Resolves its value dynamically using the scope model.
String cleanJsonPath(String path) {
  var clean = path.trim();
  if (clean.startsWith('\$.')) {
    clean = clean.substring(2);
  } else if (clean.startsWith('\$')) {
    clean = clean.substring(1);
  }
  if (clean.startsWith('.')) {
    clean = clean.substring(1);
  }
  return clean;
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
        final pattern =
            key.startsWith('globals.') ||
            key.startsWith('response.') ||
            key.startsWith('request.') ||
            key == 'item' ||
            key.startsWith('item.') ||
            key == 'index';

        final resolvedVal = pattern
            ? (resolveScopePath(key, context)?.toString() ?? '')
            : (context.variables[key] ?? '');

        if (jsonPath.isNotEmpty && resolvedVal.isNotEmpty) {
          try {
            final cleanPath = cleanJsonPath(jsonPath);
            final decoded = context.getDecodedJson(resolvedVal);
            if (decoded != null) {
              final extracted = cleanPath.isEmpty ? decoded : getValueByPath(decoded, cleanPath);
              return extracted?.toString() ?? '';
            }
          } catch (_) {}
        }
        return resolvedVal;
      case ValueSourceType.responseBody:
        if (context.responseBody == null || context.responseBody!.isEmpty) {
          return '';
        }
        if (jsonPath.isNotEmpty) {
          try {
            final cleanPath = cleanJsonPath(jsonPath);
            final decoded = context.getDecodedJson(context.responseBody!);
            final extracted = cleanPath.isEmpty ? decoded : getValueByPath(decoded, cleanPath);
            return extracted?.toString() ?? '';
          } catch (_) {
            return '';
          }
        }
        return context.responseBody!;
    }
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
      final decoded = context.getDecodedJson(itemStr);
      return getValueByPath(decoded, rest);
    } catch (_) {
      return null;
    }
  }
  if (path.startsWith('globals.')) {
    final key = path.substring(8);
    if (context.variables.containsKey(key)) {
      return context.variables[key];
    }
    if (key.contains('.')) {
      final dotIdx = key.indexOf('.');
      final varName = key.substring(0, dotIdx);
      final rest = key.substring(dotIdx + 1);
      if (context.variables.containsKey(varName)) {
        final valStr = context.variables[varName];
        if (valStr != null && valStr.isNotEmpty) {
          try {
            final decoded = context.getDecodedJson(valStr);
            if (decoded != null) {
              return getValueByPath(decoded, rest);
            }
          } catch (_) {}
        }
      }
    }
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
      if (context.responseBody == null || context.responseBody!.isEmpty) {
        return null;
      }
      try {
        final decoded = context.getDecodedJson(context.responseBody!);
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

  // Fallback for user-defined variables (including nested JSON path extraction)
  if (context.variables.containsKey(path)) {
    return context.variables[path];
  }
  if (path.contains('.')) {
    final dotIdx = path.indexOf('.');
    final varName = path.substring(0, dotIdx);
    final rest = path.substring(dotIdx + 1);
    if (context.variables.containsKey(varName)) {
      final valStr = context.variables[varName];
      if (valStr != null && valStr.isNotEmpty) {
        try {
          final decoded = context.getDecodedJson(valStr);
          if (decoded != null) {
            return getValueByPath(decoded, rest);
          }
        } catch (_) {}
      }
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
