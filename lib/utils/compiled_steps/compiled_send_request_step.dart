import 'package:fletch/utils/script_compiler.dart';

class CompiledSendRequestStep extends CompiledStep {
  final String? nextStepId;
  final String method;
  final String url;
  final Map<String, String> headers;
  final String? body;
  final String saveToVariable;

  CompiledSendRequestStep({
    required super.id,
    required super.name,
    this.nextStepId,
    required this.method,
    required this.url,
    required this.headers,
    this.body,
    required this.saveToVariable,
  });

  @override
  Future<ExecutionResult> execute(ExecutionContext context, Map<String, CompiledStep> nodes) async {
    final resolvedUrl = interpolate(url, context);
    context.log(id, name, 'Disparando requisição HTTP secundária: $method $resolvedUrl', level: LogLevel.info);
    
    if (context.httpExecutor == null) {
      return ExecutionResult(success: false, error: 'HTTP executor não injetado no contexto.');
    }

    try {
      final res = await context.httpExecutor!(method, resolvedUrl, headers, body);
      final bodyStr = res['body'] as String? ?? '';
      
      if (saveToVariable.isNotEmpty) {
        context.variables[saveToVariable] = bodyStr;
        context.log(id, name, 'Resposta salva na variável "$saveToVariable" (Status: ${res['statusCode']})', level: LogLevel.info);
      }
      
      context.statusCode = res['statusCode'] as int? ?? 200;
      context.responseBody = bodyStr;
      context.responseHeaders = Map<String, String>.from(res['headers'] as Map? ?? {});

      return ExecutionResult(success: true, nextNodeId: nextStepId);
    } catch (e) {
      context.log(id, name, 'Erro ao executar requisição HTTP secundária: $e', level: LogLevel.error);
      return ExecutionResult(success: false, error: e.toString());
    }
  }
}
