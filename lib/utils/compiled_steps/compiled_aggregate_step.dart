import 'dart:convert';
import 'package:fletch/utils/script_compiler.dart';

class CompiledAggregateStep extends CompiledStep {
  final String? nextStepId;
  final CompiledValueSource itemSource;
  final String targetListVariable;

  CompiledAggregateStep({
    required super.id,
    required super.name,
    this.nextStepId,
    required this.itemSource,
    required this.targetListVariable,
  });

  @override
  Future<ExecutionResult> execute(ExecutionContext context, Map<String, CompiledStep> nodes) async {
    if (targetListVariable.isEmpty) {
      context.log(id, name, 'Agregação abortada: variável destino vazia.', level: LogLevel.warn);
      return ExecutionResult(success: true, nextNodeId: nextStepId);
    }

    final resolvedItem = itemSource.resolve(context);
    final existingVal = context.variables[targetListVariable] ?? '[]';
    
    List<dynamic> list = [];
    try {
      final decoded = jsonDecode(existingVal);
      if (decoded is List) {
        list = decoded;
      }
    } catch (_) {}

    try {
      final itemDecoded = jsonDecode(resolvedItem);
      list.add(itemDecoded);
    } catch (_) {
      list.add(resolvedItem);
    }

    context.variables[targetListVariable] = jsonEncode(list);
    context.log(id, name, 'Agregado item à lista "$targetListVariable" (Tamanho atual: ${list.length}).', level: LogLevel.info);
    return ExecutionResult(success: true, nextNodeId: nextStepId);
  }
}
