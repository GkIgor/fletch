import 'dart:convert';
import 'package:html/parser.dart' as html_parser;
import 'package:fletch/utils/script_compiler.dart';

class CompiledHtmlConvertStep extends CompiledStep {
  final String? nextStepId;
  final String operation;
  final CompiledValueSource valueSource;
  final String selector;
  final String attribute;
  final String saveToVariable;

  CompiledHtmlConvertStep({
    required super.id,
    required super.name,
    this.nextStepId,
    required this.operation,
    required this.valueSource,
    required this.selector,
    required this.attribute,
    required this.saveToVariable,
  });

  @override
  Future<ExecutionResult> execute(ExecutionContext context, Map<String, CompiledStep> nodes) async {
    final value = valueSource.resolve(context);

    try {
      final document = html_parser.parse(value);
      if (operation == 'htmlToText') {
        final text = document.body?.text ?? '';
        context.variables[saveToVariable] = text;
        context.log(id, name, 'HTML limpo de tags e salvo em "$saveToVariable".', level: LogLevel.info);
      } else if (operation == 'extractSelector') {
        if (selector.isEmpty) {
          return ExecutionResult(success: false, error: 'CSS Selector is empty.');
        }
        final elements = document.querySelectorAll(selector);
        final List<String> results = elements.map((e) => e.outerHtml).toList();
        context.variables[saveToVariable] = jsonEncode(results);
        context.log(id, name, 'Elementos extraídos via seletor "$selector" salvos em "$saveToVariable".', level: LogLevel.info);
      } else if (operation == 'extractAttributes') {
        if (selector.isEmpty || attribute.isEmpty) {
          return ExecutionResult(success: false, error: 'CSS Selector or Attribute name is empty.');
        }
        final elements = document.querySelectorAll(selector);
        final List<String> results = elements
            .map((e) => e.attributes[attribute])
            .whereType<String>()
            .toList();
        context.variables[saveToVariable] = jsonEncode(results);
        context.log(id, name, 'Atributos "$attribute" extraídos via seletor "$selector" salvos em "$saveToVariable".', level: LogLevel.info);
      }
    } catch (e) {
      context.log(id, name, 'Erro na extração HTML: $e', level: LogLevel.error);
      return ExecutionResult(success: false, error: e.toString());
    }

    return ExecutionResult(success: true, nextNodeId: nextStepId);
  }
}
