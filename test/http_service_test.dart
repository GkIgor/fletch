import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gk_http_client/models/http_method.dart';
import 'package:gk_http_client/models/http_request.dart';
import 'package:gk_http_client/services/http_service.dart';
import 'package:gk_http_client/widgets/body_editor.dart';

void main() {
  group('HttpService Tests', () {
    late Dio dio;
    late HttpService httpService;

    setUp(() {
      dio = Dio();
      httpService = HttpService(dio: dio);
    });

    test('GET request is sent and parsed correctly', () async {
      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(Response(
            requestOptions: options,
            data: {'result': 'success'},
            statusCode: 200,
            statusMessage: 'OK',
            headers: Headers.fromMap({
              'content-type': ['application/json'],
              'custom-header': ['custom-value'],
            }),
          ));
        },
      ));

      final request = HttpRequest(
        name: 'Test GET',
        method: HttpMethod.get,
        url: 'https://example.com/get',
        headers: {'x-test-header': 'test-val'},
        queryParams: {'param1': 'val1'},
      );

      final response = await httpService.send(request);

      expect(response.statusCode, equals(200));
      expect(response.statusMessage, equals('OK'));
      expect(response.body, equals({'result': 'success'}));
      expect(response.headers['custom-header'], equals('custom-value'));
    });

    test('POST json body is sent correctly', () async {
      final requestData = {'message': 'hello'};
      
      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          expect(options.method, equals('POST'));
          expect(options.headers['Content-Type'], equals('application/json'));
          expect(options.data, equals(requestData));
          
          handler.resolve(Response(
            requestOptions: options,
            data: {'echo': options.data},
            statusCode: 201,
            statusMessage: 'Created',
          ));
        },
      ));

      final request = HttpRequest(
        name: 'Test POST',
        method: HttpMethod.post,
        url: 'https://example.com/post',
        bodyType: BodyType.json,
        body: jsonEncode(requestData),
      );

      final response = await httpService.send(request);

      expect(response.statusCode, equals(201));
      expect(response.statusMessage, equals('Created'));
      expect(response.body['echo'], equals(requestData));
    });

    test('Error responses are handled without crashing', () async {
      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.reject(DioException(
            requestOptions: options,
            response: Response(
              requestOptions: options,
              statusCode: 400,
              statusMessage: 'Bad Request',
              data: 'Invalid input data',
            ),
          ));
        },
      ));

      final request = HttpRequest(
        name: 'Test Error',
        method: HttpMethod.get,
        url: 'https://example.com/error',
      );

      final response = await httpService.send(request);

      expect(response.statusCode, equals(400));
      expect(response.statusMessage, equals('Bad Request'));
      expect(response.body, equals('Invalid input data'));
    });
  });
}
