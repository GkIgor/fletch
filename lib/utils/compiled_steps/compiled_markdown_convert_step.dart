import 'package:fletch/utils/script_compiler.dart';

class CompiledMarkdownConvertStep extends CompiledStep {
  final String? nextStepId;
  final String operation;
  final CompiledValueSource valueSource;
  final String saveToVariable;

  CompiledMarkdownConvertStep({
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
      if (operation == 'markdownToHtml') {
        final html = _markdownToHtml(value);
        context.variables[saveToVariable] = html;
        context.log(id, name, 'Markdown convertido para HTML em "$saveToVariable".', level: LogLevel.info);
      } else {
        final md = _htmlToMarkdown(value);
        context.variables[saveToVariable] = md;
        context.log(id, name, 'HTML convertido para Markdown em "$saveToVariable".', level: LogLevel.info);
      }
    } catch (e) {
      context.log(id, name, 'Erro na conversão Markdown ($operation): $e', level: LogLevel.error);
      return ExecutionResult(success: false, error: e.toString());
    }

    return ExecutionResult(success: true, nextNodeId: nextStepId);
  }

  String _markdownToHtml(String markdown) {
    String html = markdown;
    html = html.replaceAllMapped(RegExp(r'\*\*(.*?)\*\*'), (m) => '<strong>${m[1]}</strong>');
    html = html.replaceAllMapped(RegExp(r'\*(.*?)\*'), (m) => '<em>${m[1]}</em>');
    html = html.replaceAllMapped(RegExp(r'^### (.*?)$', multiLine: true), (m) => '<h3>${m[1]}</h3>');
    html = html.replaceAllMapped(RegExp(r'^## (.*?)$', multiLine: true), (m) => '<h2>${m[1]}</h2>');
    html = html.replaceAllMapped(RegExp(r'^# (.*?)$', multiLine: true), (m) => '<h1>${m[1]}</h1>');
    html = html.replaceAllMapped(RegExp(r'^[*-] (.*?)$', multiLine: true), (m) => '<li>${m[1]}</li>');
    return html;
  }

  String _htmlToMarkdown(String html) {
    String md = html;
    md = md.replaceAllMapped(RegExp(r'<h1>(.*?)</h1>', caseSensitive: false), (m) => '# ${m[1]}\n');
    md = md.replaceAllMapped(RegExp(r'<h2>(.*?)</h2>', caseSensitive: false), (m) => '## ${m[1]}\n');
    md = md.replaceAllMapped(RegExp(r'<h3>(.*?)</h3>', caseSensitive: false), (m) => '### ${m[1]}\n');
    md = md.replaceAllMapped(RegExp(r'<strong>(.*?)</strong>', caseSensitive: false), (m) => '**${m[1]}**');
    md = md.replaceAllMapped(RegExp(r'<em>(.*?)</em>', caseSensitive: false), (m) => '*${m[1]}*');
    md = md.replaceAllMapped(RegExp(r'<li>(.*?)</li>', caseSensitive: false), (m) => '* ${m[1]}\n');
    md = md.replaceAll(RegExp(r'<br/?>', caseSensitive: false), '\n');
    md = md.replaceAll(RegExp(r'<[^>]*>'), '');
    return md;
  }
}
