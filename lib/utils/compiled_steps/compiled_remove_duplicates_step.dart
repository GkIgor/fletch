import 'dart:convert';
import 'package:fletch/utils/script_compiler.dart';

class CompiledRemoveDuplicatesStep extends CompiledStep {
  final String? nextStepId;
  final CompiledValueSource arraySource;
  final String comparePath;
  final String saveToVariable;

  CompiledRemoveDuplicatesStep({
    required super.id,
    required super.name,
    this.nextStepId,
    required this.arraySource,
    required this.comparePath,
    required this.saveToVariable,
  });

  @override
  Future<ExecutionResult> execute(ExecutionContext context, Map<String, CompiledStep> nodes) async {
    final rawVal = arraySource.resolve(context);
    if (rawVal.isEmpty) {
      context.log(id, name, 'Array para remoção de duplicatas está vazio.', level: LogLevel.warn);
      return ExecutionResult(success: true, nextNodeId: nextStepId);
    }

    try {
      final decoded = jsonDecode(rawVal);
      if (decoded is List) {
        final List<dynamic> list = List.from(decoded);
        final Set<dynamic> seen = {};
        final List<dynamic> unique = [];

        for (var item in list) {
          dynamic key = item;
          if (comparePath.isNotEmpty) {
            key = getValueByPath(item, comparePath);
          }
          final checkVal = (key is Map || key is List) ? jsonEncode(key) : key;
          if (!seen.contains(checkVal)) {
            seen.add(checkVal);
            unique.add(item);
          }
        }

        context.variables[saveToVariable] = jsonEncode(unique);
        context.log(id, name, 'Duplicatas removidas. Elementos únicos: ${unique.length}. Salvo em "$saveToVariable".', level: LogLevel.info);
      } else {
        context.log(id, name, 'O valor de origem não é uma lista JSON válida para remoção de duplicatas.', level: LogLevel.error);
        return ExecutionResult(success: false, error: 'Source value is not a JSON list.');
      }
    } catch (e) {
      context.log(id, name, 'Erro ao remover duplicatas: $e', level: LogLevel.error);
      return ExecutionResult(success: false, error: e.toString());
    }

    return ExecutionResult(success: true, nextNodeId: nextStepId);
  }
}
