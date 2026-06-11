import 'dart:convert';
import 'package:fletch/utils/script_compiler.dart';

class CompiledMergeStep extends CompiledStep {
  final String? nextStepId;
  final String strategy;
  final List<String> sources;
  final String saveTo;

  CompiledMergeStep({
    required super.id,
    required super.name,
    this.nextStepId,
    required this.strategy,
    required this.sources,
    required this.saveTo,
  });

  @override
  Future<ExecutionResult> execute(ExecutionContext context, Map<String, CompiledStep> nodes) async {
    if (saveTo.isEmpty) {
      context.log(id, name, 'Fusão abortada: variável de destino vazia.', level: LogLevel.warn);
      return ExecutionResult(success: true, nextNodeId: nextStepId);
    }

    if (sources.isEmpty) {
      context.log(id, name, 'Nenhuma fonte de dados configurada para fusão.', level: LogLevel.warn);
      return ExecutionResult(success: true, nextNodeId: nextStepId);
    }

    dynamic merged;

    if (strategy == 'deepMerge') {
      final Map<String, dynamic> result = {};
      for (var src in sources) {
        final val = resolveScopePath(src, context) ?? context.variables[src];
        if (val == null) continue;
        try {
          final decoded = val is Map ? val : jsonDecode(val.toString());
          if (decoded is Map) {
            result.addAll(Map<String, dynamic>.from(decoded));
          }
        } catch (_) {
          // If not mergeable, override
          result[src] = val;
        }
      }
      merged = jsonEncode(result);
    } else if (strategy == 'concatLists') {
      final List<dynamic> result = [];
      for (var src in sources) {
        final val = resolveScopePath(src, context) ?? context.variables[src];
        if (val == null) continue;
        try {
          final decoded = val is List ? val : jsonDecode(val.toString());
          if (decoded is List) {
            result.addAll(decoded);
          } else {
            result.add(decoded);
          }
        } catch (_) {
          result.add(val);
        }
      }
      merged = jsonEncode(result);
    } else if (strategy == 'zip') {
      final List<dynamic> listA = [];
      final List<dynamic> listB = [];
      
      if (sources.isNotEmpty) {
        final valA = resolveScopePath(sources[0], context) ?? context.variables[sources[0]];
        if (valA != null) {
          try {
            listA.addAll(valA is List ? valA : jsonDecode(valA.toString()) as List);
          } catch (_) {}
        }
      }
      if (sources.length >= 2) {
        final valB = resolveScopePath(sources[1], context) ?? context.variables[sources[1]];
        if (valB != null) {
          try {
            listB.addAll(valB is List ? valB : jsonDecode(valB.toString()) as List);
          } catch (_) {}
        }
      }

      final int minLen = listA.length < listB.length ? listA.length : listB.length;
      final List<List<dynamic>> zipped = [];
      for (int i = 0; i < minLen; i++) {
        zipped.add([listA[i], listB[i]]);
      }
      merged = jsonEncode(zipped);
    }

    context.variables[saveTo] = merged?.toString() ?? '';
    context.log(id, name, 'Mesclagem realizada usando a estratégia "$strategy" salva em "$saveTo".', level: LogLevel.info);
    return ExecutionResult(success: true, nextNodeId: nextStepId);
  }
}
