import 'dart:convert';
import 'package:fletch/utils/script_compiler.dart';

class CompiledJsonConvertStep extends CompiledStep {
  final String? nextStepId;
  final String operation;
  final CompiledValueSource valueSource;
  final String saveToVariable;

  CompiledJsonConvertStep({
    required super.id,
    required super.name,
    this.nextStepId,
    required this.operation,
    required this.valueSource,
    required this.saveToVariable,
  });

  @override
  Future<ExecutionResult> execute(ExecutionContext context, Map<String, CompiledStep> nodes) async {
    final value = valueSource.resolve(context);

    try {
      if (operation == 'serialize') {
        dynamic decoded;
        try {
          decoded = jsonDecode(value);
        } catch (_) {
          decoded = value;
        }
        context.variables[saveToVariable] = jsonEncode(decoded);
        context.log(id, name, 'JSON serializado com sucesso em "$saveToVariable".', level: LogLevel.info);
      } else {
        final decoded = jsonDecode(value);
        context.variables[saveToVariable] = jsonEncode(decoded);
        context.log(id, name, 'JSON desserializado com sucesso em "$saveToVariable".', level: LogLevel.info);
      }
    } catch (e) {
      context.log(id, name, 'Erro na conversão JSON ($operation): $e', level: LogLevel.error);
      return ExecutionResult(success: false, error: e.toString());
    }

    return ExecutionResult(success: true, nextNodeId: nextStepId);
  }
}
