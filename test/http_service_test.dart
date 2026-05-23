import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fletch/models/http_method.dart';
import 'package:fletch/models/http_request.dart';
import 'package:fletch/services/http_service.dart';
import 'package:fletch/widgets/body_editor.dart';

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

    group('Variable Interpolation Tests', () {
      final variables = {
        'baseUrl': 'https://api.example.com',
        'userId': '123',
        'apiKey': 'secret-key-xyz',
        'extraSpace': ' value_with_space ',
        'contentType': 'application/json',
      };

      test('Interpolates URL, Query parameters, and Headers', () async {
        dio.interceptors.add(InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.path, equals('https://api.example.com/users/123'));
            expect(options.queryParameters['query_id'], equals('123'));
            expect(options.headers['Authorization'], equals('Bearer secret-key-xyz'));
            expect(options.headers['Content-Type'], equals('application/json'));
            // Check that empty key headers were removed
            expect(options.headers.containsKey(''), isFalse);

            handler.resolve(Response(
              requestOptions: options,
              data: 'success',
              statusCode: 200,
            ));
          },
        ));

        final request = HttpRequest(
          name: 'Test Interpolation',
          method: HttpMethod.get,
          url: '{{baseUrl}}/users/{{userId}}',
          headers: {
            'Authorization': 'Bearer {{apiKey}}',
            'Content-Type': '{{contentType}}',
            '{{undefinedHeader}}': 'some-value',
          },
          queryParams: {
            'query_id': '{{userId}}',
          },
        );

        final response = await httpService.send(request, variables: variables);
        expect(response.statusCode, equals(200));
        expect(response.body, equals('success'));
      });

      test('Interpolates JSON body', () async {
        dio.interceptors.add(InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.data, equals({
              'id': '123',
              'details': ' value_with_space ',
              'missing': '',
            }));

            handler.resolve(Response(
              requestOptions: options,
              data: 'ok',
              statusCode: 200,
            ));
          },
        ));

        final request = HttpRequest(
          name: 'Test JSON body interpolation',
          method: HttpMethod.post,
          url: 'https://example.com/post',
          bodyType: BodyType.json,
          body: jsonEncode({
            'id': '{{userId}}',
            'details': '{{extraSpace}}',
            'missing': '{{nonexistent}}',
          }),
        );

        final response = await httpService.send(request, variables: variables);
        expect(response.statusCode, equals(200));
      });

      test('Interpolates Form Data', () async {
        dio.interceptors.add(InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.data, isA<FormData>());
            final formData = options.data as FormData;
            final fields = formData.fields.map((f) => MapEntry(f.key, f.value)).toList();
            
            expect(fields.any((f) => f.key == 'user' && f.value == '123'), isTrue);
            expect(fields.any((f) => f.key == 'key' && f.value == 'secret-key-xyz'), isTrue);
            // Non-existent variable field name should be ignored
            expect(fields.any((f) => f.key == ''), isFalse);

            handler.resolve(Response(
              requestOptions: options,
              data: 'ok',
              statusCode: 200,
            ));
          },
        ));

        final request = HttpRequest(
          name: 'Test Form Data Interpolation',
          method: HttpMethod.post,
          url: 'https://example.com/post',
          bodyType: BodyType.formData,
          formData: [
            FormDataEntry(key: 'user', value: '{{userId}}', enabled: true),
            FormDataEntry(key: 'key', value: '{{apiKey}}', enabled: true),
            FormDataEntry(key: '{{nonexistent}}', value: 'value', enabled: true),
          ],
        );

        final response = await httpService.send(request, variables: variables);
        expect(response.statusCode, equals(200));
      });
    });
  });
}
