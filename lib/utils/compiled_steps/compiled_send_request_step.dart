import 'dart:convert';
import 'package:fletch/utils/script_compiler.dart';
import 'package:fletch/models/http_auth.dart';
import 'package:fletch/utils/oauth1_helper.dart';

class CompiledSendRequestStep extends CompiledStep {
  final String? nextStepId;
  final String method;
  final String url;
  final Map<String, String> headers;
  final String? body;
  final String saveToVariable;
  final HttpAuth? auth;

  CompiledSendRequestStep({
    required super.id,
    required super.name,
    this.nextStepId,
    required this.method,
    required this.url,
    required this.headers,
    this.body,
    required this.saveToVariable,
    this.auth,
  });

  @override
  Future<ExecutionResult> execute(ExecutionContext context, Map<String, CompiledStep> nodes) async {
    final resolvedUrl = interpolate(url, context);
    final resolvedBody = body != null ? interpolate(body!, context) : null;
    
    final Map<String, String> resolvedHeaders = {};
    headers.forEach((k, v) {
      resolvedHeaders[k] = interpolate(v, context);
    });

    String finalUrl = resolvedUrl;

    if (auth != null) {
      switch (auth!.type) {
        case AuthType.apiKey:
          final key = interpolate(auth!.apiKeyKey, context).trim();
          final value = interpolate(auth!.apiKeyValue, context);
          if (key.isNotEmpty) {
            if (auth!.apiKeyAddTo == 'query') {
              final uri = Uri.parse(finalUrl);
              final queryMap = Map<String, String>.from(uri.queryParameters);
              queryMap[key] = value;
              finalUrl = uri.replace(queryParameters: queryMap).toString();
            } else {
              resolvedHeaders[key] = value;
            }
          }
          break;
        case AuthType.bearer:
          final token = interpolate(auth!.bearerToken, context);
          resolvedHeaders['Authorization'] = 'Bearer $token';
          break;
        case AuthType.basic:
          final username = interpolate(auth!.basicUsername, context);
          final password = interpolate(auth!.basicPassword, context);
          final credentials = base64Encode(utf8.encode('$username:$password'));
          resolvedHeaders['Authorization'] = 'Basic $credentials';
          break;
        case AuthType.oauth1:
          final consumerKey = interpolate(auth!.oauth1ConsumerKey, context);
          final consumerSecret = interpolate(auth!.oauth1ConsumerSecret, context);
          final token = interpolate(auth!.oauth1Token, context);
          final tokenSecret = interpolate(auth!.oauth1TokenSecret, context);
          
          final uri = Uri.parse(finalUrl);
          final oauthHeader = OAuth1Helper.generateHeader(
            method: method,
            url: finalUrl,
            queryParams: uri.queryParameters,
            consumerKey: consumerKey,
            consumerSecret: consumerSecret,
            token: token,
            tokenSecret: tokenSecret,
            signatureMethod: auth!.oauth1SignatureMethod,
          );
          resolvedHeaders['Authorization'] = oauthHeader;
          break;
        case AuthType.oauth2:
          final token = interpolate(auth!.oauth2AccessToken, context);
          resolvedHeaders['Authorization'] = 'Bearer $token';
          break;
        case AuthType.inherit:
        case AuthType.none:
          break;
      }
    }

    context.log(id, name, 'Disparando requisição HTTP secundária: $method $finalUrl', level: LogLevel.info);
    
    if (context.httpExecutor == null) {
      return ExecutionResult(success: false, error: 'HTTP executor não injetado no contexto.');
    }

    try {
      final res = await context.httpExecutor!(method, finalUrl, resolvedHeaders, resolvedBody);
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
