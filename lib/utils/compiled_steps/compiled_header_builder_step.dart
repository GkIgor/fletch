import 'dart:convert';
import 'package:fletch/utils/script_compiler.dart';

class CompiledHeaderBuilderStep extends CompiledStep {
  final String? nextStepId;
  final String authType;
  final CompiledValueSource tokenSource;
  final Map<String, String> additionalHeaders;
  final String saveToVariable;

  CompiledHeaderBuilderStep({
    required super.id,
    required super.name,
    this.nextStepId,
    required this.authType,
    required this.tokenSource,
    required this.additionalHeaders,
    required this.saveToVariable,
  });

  @override
  Future<ExecutionResult> execute(ExecutionContext context, Map<String, CompiledStep> nodes) async {
    final Map<String, String> headers = {};
    
    if (authType != 'none') {
      final credentials = tokenSource.resolve(context);
      if (authType == 'bearer') {
        headers['Authorization'] = 'Bearer $credentials';
      } else if (authType == 'basic') {
        final encoded = base64.encode(utf8.encode(credentials));
        headers['Authorization'] = 'Basic $encoded';
      } else if (authType == 'apiKey') {
        headers['X-API-Key'] = credentials;
      }
    }

    additionalHeaders.forEach((k, v) {
      headers[k] = interpolate(v, context);
    });

    context.variables[saveToVariable] = jsonEncode(headers);
    context.log(id, name, 'Header Builder gerou ${headers.length} cabeçalhos em "$saveToVariable".', level: LogLevel.info);
    return ExecutionResult(success: true, nextNodeId: nextStepId);
  }
}
