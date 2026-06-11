import 'dart:convert';
import 'package:fletch/utils/script_compiler.dart';

class CompiledSortStep extends CompiledStep {
  final String? nextStepId;
  final CompiledValueSource arraySource;
  final String sortByPath;
  final bool ascending;
  final String saveToVariable;

  CompiledSortStep({
    required super.id,
    required super.name,
    this.nextStepId,
    required this.arraySource,
    required this.sortByPath,
    required this.ascending,
    required this.saveToVariable,
  });

  @override
  Future<ExecutionResult> execute(ExecutionContext context, Map<String, CompiledStep> nodes) async {
    final rawVal = arraySource.resolve(context);
    if (rawVal.isEmpty) {
      context.log(id, name, 'Array para ordenação está vazio.', level: LogLevel.warn);
      return ExecutionResult(success: true, nextNodeId: nextStepId);
    }

    try {
      final decoded = jsonDecode(rawVal);
      if (decoded is List) {
        final List<dynamic> list = List.from(decoded);
        list.sort((a, b) {
          dynamic valA = a;
          dynamic valB = b;
          if (sortByPath.isNotEmpty) {
            valA = getValueByPath(a, sortByPath);
            valB = getValueByPath(b, sortByPath);
          }
          if (valA == null && valB == null) return 0;
          if (valA == null) return ascending ? -1 : 1;
          if (valB == null) return ascending ? 1 : -1;

          int comp;
          if (valA is Comparable && valB is Comparable) {
            comp = valA.compareTo(valB);
          } else {
            comp = valA.toString().compareTo(valB.toString());
          }
          return ascending ? comp : -comp;
        });

        context.variables[saveToVariable] = jsonEncode(list);
        context.log(id, name, 'Array ordenado com sucesso e salvo em "$saveToVariable".', level: LogLevel.info);
      } else {
        context.log(id, name, 'O valor de origem não é uma lista JSON válida para ordenação.', level: LogLevel.error);
        return ExecutionResult(success: false, error: 'Source value is not a JSON list.');
      }
    } catch (e) {
      context.log(id, name, 'Erro ao processar ordenação: $e', level: LogLevel.error);
      return ExecutionResult(success: false, error: e.toString());
    }

    return ExecutionResult(success: true, nextNodeId: nextStepId);
  }
}
