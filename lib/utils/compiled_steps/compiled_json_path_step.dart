import 'dart:convert';
import 'package:fletch/utils/script_compiler.dart';

class CompiledJsonPathStep extends CompiledStep {
  final String? nextStepId;
  final CompiledValueSource valueSource;
  final String jsonPathExpression;
  final String saveToVariable;

  CompiledJsonPathStep({
    required super.id,
    required super.name,
    this.nextStepId,
    required this.valueSource,
    required this.jsonPathExpression,
    required this.saveToVariable,
  });

  @override
  Future<ExecutionResult> execute(ExecutionContext context, Map<String, CompiledStep> nodes) async {
    final value = valueSource.resolve(context);
    if (value.isEmpty) {
      context.log(id, name, 'Valor de origem do JSON Path está vazio.', level: LogLevel.warn);
      return ExecutionResult(success: true, nextNodeId: nextStepId);
    }

    try {
      final decoded = jsonDecode(value);
      var cleanPath = jsonPathExpression.trim();
      if (cleanPath.startsWith('\$.')) {
        cleanPath = cleanPath.substring(2);
      } else if (cleanPath.startsWith('\$')) {
        cleanPath = cleanPath.substring(1);
      }
      if (cleanPath.startsWith('.')) {
        cleanPath = cleanPath.substring(1);
      }

      final extracted = cleanPath.isEmpty ? decoded : getValueByPath(decoded, cleanPath);
      final resultStr = (extracted is Map || extracted is List) ? jsonEncode(extracted) : extracted?.toString() ?? '';

      context.variables[saveToVariable] = resultStr;
      context.log(id, name, 'JSON Path extraído: "$cleanPath" -> "$resultStr" salvo em "$saveToVariable".', level: LogLevel.info);
    } catch (e) {
      context.log(id, name, 'Erro ao extrair JSON Path: $e', level: LogLevel.error);
      return ExecutionResult(success: false, error: e.toString());
    }

    return ExecutionResult(success: true, nextNodeId: nextStepId);
  }
}
