import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:fletch/models/http_request.dart';
import 'package:fletch/models/http_response.dart';
import 'package:path/path.dart' as p;
import 'package:fletch/widgets/body_editor.dart';

class HttpService {
  final Dio _dio;

  HttpService({Dio? dio}) : _dio = dio ?? Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      validateStatus: (status) => true, // Permitir qualquer código de status para que possamos mostrá-lo na UI
    ),
  );

  String _interpolate(String value, Map<String, String>? variables) {
    if (variables == null || variables.isEmpty) return value;
    final regex = RegExp(r'\{\{([^}]+)\}\}');
    return value.replaceAllMapped(regex, (match) {
      final varName = match.group(1)?.trim() ?? '';
      return variables[varName] ?? '';
    });
  }

  Future<HttpResponse> send(HttpRequest request, {Map<String, String>? variables}) async {
    final stopwatch = Stopwatch()..start();

    // 1. Validar e preparar URL
    String url = _interpolate(request.url, variables).trim();
    if (url.isNotEmpty && !url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'http://$url';
    }

    // 2. Mapear Query Parameters e Headers com Interpolação
    final Map<String, dynamic> headers = {};
    request.headers.forEach((key, val) {
      final interpolatedKey = _interpolate(key, variables).trim();
      final interpolatedVal = _interpolate(val, variables);
      if (interpolatedKey.isNotEmpty) {
        headers[interpolatedKey] = interpolatedVal;
      }
    });

    final Map<String, dynamic> queryParams = {};
    request.queryParams.forEach((key, val) {
      final interpolatedKey = _interpolate(key, variables).trim();
      final interpolatedVal = _interpolate(val, variables);
      if (interpolatedKey.isNotEmpty) {
        queryParams[interpolatedKey] = interpolatedVal;
      }
    });

    // 3. Configurar Body baseado no BodyType com Interpolação
    dynamic data;
    try {
      if (request.bodyType == BodyType.json) {
        if (request.body != null && request.body!.isNotEmpty) {
          if (!headers.containsKey('content-type') && !headers.containsKey('Content-Type')) {
            headers['Content-Type'] = 'application/json';
          }
          final interpolatedBody = _interpolate(request.body!, variables);
          try {
            data = jsonDecode(interpolatedBody);
          } catch (_) {
            data = interpolatedBody; // Caso o JSON seja inválido, envia a String bruta
          }
        }
      } else if (request.bodyType == BodyType.xml) {
        if (request.body != null && request.body!.isNotEmpty) {
          if (!headers.containsKey('content-type') && !headers.containsKey('Content-Type')) {
            headers['Content-Type'] = 'application/xml';
          }
          data = _interpolate(request.body!, variables);
        }
      } else if (request.bodyType == BodyType.formData) {
        final map = <String, dynamic>{};
        for (final entry in request.formData) {
          if (!entry.enabled) continue;
          final interpolatedKey = _interpolate(entry.key, variables).trim();
          final interpolatedValue = _interpolate(entry.value, variables);
          if (interpolatedKey.isEmpty) continue;

          if (entry.isFile && interpolatedValue.isNotEmpty) {
            final file = File(interpolatedValue);
            if (await file.exists()) {
              map[interpolatedKey] = await MultipartFile.fromFile(
                interpolatedValue,
                filename: p.basename(interpolatedValue),
              );
            } else {
              throw Exception('Arquivo não encontrado: $interpolatedValue');
            }
          } else {
            map[interpolatedKey] = interpolatedValue;
          }
        }
        data = FormData.fromMap(map);
      } else if (request.bodyType == BodyType.binary) {
        if (request.binaryPath != null && request.binaryPath!.isNotEmpty) {
          final interpolatedPath = _interpolate(request.binaryPath!, variables);
          final file = File(interpolatedPath);
          if (await file.exists()) {
            data = file.openRead();
            final length = await file.length();
            headers['Content-Length'] = length.toString();
          } else {
            throw Exception('Arquivo binário não encontrado: $interpolatedPath');
          }
        }
      }
    } catch (e) {
      stopwatch.stop();
      final errorMsg = e.toString();
      return HttpResponse(
        statusCode: 400,
        statusMessage: 'Bad Request',
        headers: {},
        body: 'Erro ao processar corpo da requisição:\n$errorMsg',
        responseTime: stopwatch.elapsedMilliseconds,
        contentLength: utf8.encode(errorMsg).length,
      );
    }

    try {
      final response = await _dio.request(
        url,
        data: data,
        queryParameters: queryParams,
        options: Options(
          method: request.method.value.toUpperCase(),
          headers: headers,
          responseType: ResponseType.json, // Tentará decodificar JSON automaticamente
        ),
      );

      stopwatch.stop();
      final duration = stopwatch.elapsedMilliseconds;

      // Calcular tamanho do conteúdo
      int contentLength = 0;
      final contentLengthStr = response.headers.value('content-length');
      if (contentLengthStr != null) {
        contentLength = int.tryParse(contentLengthStr) ?? 0;
      }
      if (contentLength == 0 && response.data != null) {
        if (response.data is String) {
          contentLength = utf8.encode(response.data as String).length;
        } else if (response.data is List<int>) {
          contentLength = (response.data as List<int>).length;
        } else {
          try {
            contentLength = utf8.encode(jsonEncode(response.data)).length;
          } catch (_) {}
        }
      }

      // Mapear headers multivariados do Dio para Map simples
      final responseHeaders = <String, dynamic>{};
      response.headers.forEach((name, values) {
        if (values.length == 1) {
          responseHeaders[name] = values.first;
        } else {
          responseHeaders[name] = values;
        }
      });

      return HttpResponse(
        statusCode: response.statusCode ?? 200,
        statusMessage: response.statusMessage ?? 'OK',
        headers: responseHeaders,
        body: response.data,
        responseTime: duration,
        contentLength: contentLength,
      );
    } on DioException catch (e) {
      stopwatch.stop();
      final duration = stopwatch.elapsedMilliseconds;

      if (e.response != null) {
        final response = e.response!;
        int contentLength = 0;
        final contentLengthStr = response.headers.value('content-length');
        if (contentLengthStr != null) {
          contentLength = int.tryParse(contentLengthStr) ?? 0;
        }
        if (contentLength == 0 && response.data != null) {
          if (response.data is String) {
            contentLength = utf8.encode(response.data as String).length;
          } else {
            try {
              contentLength = utf8.encode(jsonEncode(response.data)).length;
            } catch (_) {}
          }
        }

        final responseHeaders = <String, dynamic>{};
        response.headers.forEach((name, values) {
          if (values.length == 1) {
            responseHeaders[name] = values.first;
          } else {
            responseHeaders[name] = values;
          }
        });

        return HttpResponse(
          statusCode: response.statusCode ?? 500,
          statusMessage: response.statusMessage ?? 'Error',
          headers: responseHeaders,
          body: response.data,
          responseTime: duration,
          contentLength: contentLength,
        );
      } else {
        final errorMsg = e.message ?? e.toString();
        return HttpResponse(
          statusCode: 0,
          statusMessage: 'Connection Error',
          headers: {},
          body: errorMsg,
          responseTime: duration,
          contentLength: utf8.encode(errorMsg).length,
        );
      }
    } catch (e) {
      stopwatch.stop();
      final errorMsg = e.toString();
      return HttpResponse(
        statusCode: 0,
        statusMessage: 'Error',
        headers: {},
        body: errorMsg,
        responseTime: stopwatch.elapsedMilliseconds,
        contentLength: utf8.encode(errorMsg).length,
      );
    }
  }
}
