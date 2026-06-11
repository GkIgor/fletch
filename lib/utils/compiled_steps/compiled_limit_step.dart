import 'dart:convert';
import 'package:fletch/utils/script_compiler.dart';

class CompiledLimitStep extends CompiledStep {
  final String? nextStepId;
  final CompiledValueSource arraySource;
  final int limit;
  final int offset;
  final String saveToVariable;

  CompiledLimitStep({
    required super.id,
    required super.name,
    this.nextStepId,
    required this.arraySource,
    required this.limit,
    required this.offset,
    required this.saveToVariable,
  });

  @override
  Future<ExecutionResult> execute(ExecutionContext context, Map<String, CompiledStep> nodes) async {
    final rawVal = arraySource.resolve(context);
    if (rawVal.isEmpty) {
      context.log(id, name, 'Array para fatiamento está vazio.', level: LogLevel.warn);
      return ExecutionResult(success: true, nextNodeId: nextStepId);
    }

    try {
      final decoded = jsonDecode(rawVal);
      if (decoded is List) {
        final List<dynamic> list = List.from(decoded);
        if (offset >= list.length) {
          context.variables[saveToVariable] = '[]';
          context.log(id, name, 'Offset maior que tamanho da lista. Lista vazia salva em "$saveToVariable".', level: LogLevel.info);
        } else {
          final end = (offset + limit) > list.length ? list.length : (offset + limit);
          final sliced = list.sublist(offset, end);
          context.variables[saveToVariable] = jsonEncode(sliced);
          context.log(id, name, 'Lista limitada/fatiada com sucesso. Salvo em "$saveToVariable".', level: LogLevel.info);
        }
      } else {
        context.log(id, name, 'O valor de origem não é uma lista JSON válida para fatiamento.', level: LogLevel.error);
        return ExecutionResult(success: false, error: 'Source value is not a JSON list.');
      }
    } catch (e) {
      context.log(id, name, 'Erro ao limitar lista: $e', level: LogLevel.error);
      return ExecutionResult(success: false, error: e.toString());
    }

    return ExecutionResult(success: true, nextNodeId: nextStepId);
  }
}
