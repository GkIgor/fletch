import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:fletch/models/collection_model.dart';
import 'package:fletch/models/http_auth.dart';
import 'package:fletch/models/http_method.dart';
import 'package:fletch/models/http_request.dart';
import 'package:fletch/providers/request_provider.dart';
import 'package:fletch/services/http_service.dart';
import 'package:fletch/utils/auth_resolver.dart';
import 'package:fletch/widgets/interpolated_text_controller.dart';

void main() {
  group('Interpolation Highlighting Tests', () {
    testWidgets('InterpolatedTextController highlights variables correctly', (WidgetTester tester) async {
      final controller = InterpolatedTextController(
        text: 'Bearer {{token}} and {{missing}}',
        availableVariables: {'token'},
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final span = controller.buildTextSpan(
                  context: context,
                  style: const TextStyle(fontSize: 14),
                  withComposing: false,
                );

                expect(span.children, isNotNull);
                expect(span.children!.length, equals(4));

                final child0 = span.children![0] as TextSpan;
                expect(child0.text, equals('Bearer '));
                expect(child0.style?.color, isNull);

                final child1 = span.children![1] as TextSpan;
                expect(child1.text, equals('{{token}}'));
                expect(child1.style?.color, equals(const Color(0xFFF59E0B)));

                final child2 = span.children![2] as TextSpan;
                expect(child2.text, equals(' and '));
                expect(child2.style?.color, isNull);

                final child3 = span.children![3] as TextSpan;
                expect(child3.text, equals('{{missing}}'));
                expect(child3.style?.color, equals(const Color(0xFFEF4444)));

                return Container();
              },
            ),
          ),
        ),
      );
    });
  });

  group('Auth Resolution & Variable Substitution Integration', () {
    late Dio dio;
    late HttpService httpService;
    final variables = {
      'ws_key': 'X-Workspace-Auth',
      'ws_val': 'ws-secret-value',
      'col_token': 'collection-token-value',
      'req_user': 'request-user',
      'req_pass': 'request-pass',
    };

    setUp(() {
      dio = Dio();
      httpService = HttpService(dio: dio);
    });

    test('Scenario: Auth only on request', () async {
      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          expect(options.headers['Authorization'], equals('Basic ${base64Encode(utf8.encode('request-user:request-pass'))}'));
          handler.resolve(Response(requestOptions: options, statusCode: 200));
        },
      ));

      final req = HttpRequest(
        name: 'Req 1',
        method: HttpMethod.get,
        url: 'example.com',
        auth: HttpAuth(
          type: AuthType.basic,
          basicUsername: '{{req_user}}',
          basicPassword: '{{req_pass}}',
        ),
      );

      final col = RequestCollection(
        name: 'Col 1',
        workspaceId: 'ws1',
        auth: HttpAuth(type: AuthType.inherit),
      );

      final resolved = AuthResolver.resolveAuth(
        request: req,
        collections: [col],
        workspaceAuth: HttpAuth(type: AuthType.none),
      );

      expect(resolved.type, equals(AuthType.basic));

      final response = await httpService.send(req, variables: variables, resolvedAuth: resolved);
      expect(response.statusCode, equals(200));
    });

    test('Scenario: Auth on request and collection (request overrides collection)', () async {
      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          expect(options.headers['Authorization'], equals('Basic ${base64Encode(utf8.encode('request-user:request-pass'))}'));
          expect(options.headers.containsValue('Bearer collection-token-value'), isFalse);
          handler.resolve(Response(requestOptions: options, statusCode: 200));
        },
      ));

      final req = HttpRequest(
        name: 'Req',
        method: HttpMethod.get,
        url: 'example.com',
        auth: HttpAuth(
          type: AuthType.basic,
          basicUsername: '{{req_user}}',
          basicPassword: '{{req_pass}}',
        ),
      );

      final col = RequestCollection(
        name: 'Col',
        workspaceId: 'ws1',
        auth: HttpAuth(
          type: AuthType.bearer,
          bearerToken: '{{col_token}}',
        ),
      );

      final resolved = AuthResolver.resolveAuth(
        request: req,
        collections: [col],
        workspaceAuth: HttpAuth(
          type: AuthType.apiKey,
          apiKeyKey: 'X-WS',
          apiKeyValue: 'ws',
        ),
      );

      expect(resolved.type, equals(AuthType.basic));

      final response = await httpService.send(req, variables: variables, resolvedAuth: resolved);
      expect(response.statusCode, equals(200));
    });

    test('Scenario: Auth on collection and inherited on request', () async {
      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          expect(options.headers['Authorization'], equals('Bearer collection-token-value'));
          handler.resolve(Response(requestOptions: options, statusCode: 200));
        },
      ));

      final req = HttpRequest(
        name: 'Req',
        method: HttpMethod.get,
        url: 'example.com',
        auth: HttpAuth(type: AuthType.inherit),
      );

      final col = RequestCollection(
        id: 'col1',
        name: 'Col',
        workspaceId: 'ws1',
        requests: [req],
        auth: HttpAuth(
          type: AuthType.bearer,
          bearerToken: '{{col_token}}',
        ),
      );

      final resolved = AuthResolver.resolveAuth(
        request: req,
        collections: [col],
        workspaceAuth: HttpAuth(type: AuthType.none),
      );

      expect(resolved.type, equals(AuthType.bearer));

      final response = await httpService.send(req, variables: variables, resolvedAuth: resolved);
      expect(response.statusCode, equals(200));
    });

    test('Scenario: Auth inherited from workspace through collection to request', () async {
      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          expect(options.headers['X-Workspace-Auth'], equals('ws-secret-value'));
          handler.resolve(Response(requestOptions: options, statusCode: 200));
        },
      ));

      final req = HttpRequest(
        name: 'Req',
        method: HttpMethod.get,
        url: 'example.com',
        auth: HttpAuth(type: AuthType.inherit),
      );

      final col = RequestCollection(
        id: 'col1',
        name: 'Col',
        workspaceId: 'ws1',
        requests: [req],
        auth: HttpAuth(type: AuthType.inherit),
      );

      final resolved = AuthResolver.resolveAuth(
        request: req,
        collections: [col],
        workspaceAuth: HttpAuth(
          type: AuthType.apiKey,
          apiKeyKey: '{{ws_key}}',
          apiKeyValue: '{{ws_val}}',
          apiKeyAddTo: 'header',
        ),
      );

      expect(resolved.type, equals(AuthType.apiKey));

      final response = await httpService.send(req, variables: variables, resolvedAuth: resolved);
      expect(response.statusCode, equals(200));
    });

    test('Scenario: Auth inherited from workspace, collection inherits, but request overrides', () async {
      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          expect(options.headers['Authorization'], equals('Basic ${base64Encode(utf8.encode('request-user:request-pass'))}'));
          expect(options.headers.containsKey('X-Workspace-Auth'), isFalse);
          handler.resolve(Response(requestOptions: options, statusCode: 200));
        },
      ));

      final req = HttpRequest(
        name: 'Req',
        method: HttpMethod.get,
        url: 'example.com',
        auth: HttpAuth(
          type: AuthType.basic,
          basicUsername: '{{req_user}}',
          basicPassword: '{{req_pass}}',
        ),
      );

      final col = RequestCollection(
        id: 'col1',
        name: 'Col',
        workspaceId: 'ws1',
        requests: [req],
        auth: HttpAuth(type: AuthType.inherit),
      );

      final resolved = AuthResolver.resolveAuth(
        request: req,
        collections: [col],
        workspaceAuth: HttpAuth(
          type: AuthType.apiKey,
          apiKeyKey: '{{ws_key}}',
          apiKeyValue: '{{ws_val}}',
        ),
      );

      expect(resolved.type, equals(AuthType.basic));

      final response = await httpService.send(req, variables: variables, resolvedAuth: resolved);
      expect(response.statusCode, equals(200));
    });

    test('Scenario: Nested collections (Workspace -> Parent Col [Inherit] -> Child Col [Bearer] -> Request [Inherit])', () async {
      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          expect(options.headers['Authorization'], equals('Bearer collection-token-value'));
          handler.resolve(Response(requestOptions: options, statusCode: 200));
        },
      ));

      final req = HttpRequest(
        name: 'Req',
        method: HttpMethod.get,
        url: 'example.com',
        auth: HttpAuth(type: AuthType.inherit),
      );

      final childCol = RequestCollection(
        id: 'child_col',
        parentId: 'parent_col',
        name: 'Child Col',
        workspaceId: 'ws1',
        requests: [req],
        auth: HttpAuth(
          type: AuthType.bearer,
          bearerToken: '{{col_token}}',
        ),
      );

      final parentCol = RequestCollection(
        id: 'parent_col',
        name: 'Parent Col',
        workspaceId: 'ws1',
        requests: [],
        auth: HttpAuth(type: AuthType.inherit),
      );

      final resolved = AuthResolver.resolveAuth(
        request: req,
        collections: [childCol, parentCol],
        workspaceAuth: HttpAuth(
          type: AuthType.apiKey,
          apiKeyKey: '{{ws_key}}',
          apiKeyValue: '{{ws_val}}',
        ),
      );

      expect(resolved.type, equals(AuthType.bearer));

      final response = await httpService.send(req, variables: variables, resolvedAuth: resolved);
      expect(response.statusCode, equals(200));
    });
  });

  group('Batch Runner End-to-End Execution with Mixed Auth Configurations', () {
    late Dio dio;
    late HttpService httpService;
    late RequestProvider provider;
    late RecordingInterceptor recorder;
    final workspaceId = 'test-ws-runner';

    final variables = {
      'ws_val': 'ws-token-123',
      'col_token': 'col-token-456',
      'req_user': 'runner-user',
      'req_pass': 'runner-pass',
    };

    final wsAuth = HttpAuth(
      type: AuthType.apiKey,
      apiKeyKey: 'X-WS-Auth',
      apiKeyValue: '{{ws_val}}',
      apiKeyAddTo: 'header',
    );

    setUp(() {
      dio = Dio();
      recorder = RecordingInterceptor();
      dio.interceptors.add(recorder);
      httpService = HttpService(dio: dio);
      provider = RequestProvider(httpService: httpService);
    });

    test('Executing batch runner resolves correct auth configurations and substitutes variables', () async {
      final reqA = HttpRequest(
        id: 'req-a',
        name: 'Req A',
        method: HttpMethod.get,
        url: 'https://example.com/a',
        auth: HttpAuth(type: AuthType.inherit),
      );
      final colA = RequestCollection(
        id: 'col-a',
        name: 'Collection A',
        workspaceId: workspaceId,
        requests: [reqA],
        auth: HttpAuth(type: AuthType.inherit),
      );

      final reqB1 = HttpRequest(
        id: 'req-b1',
        name: 'Req B1',
        method: HttpMethod.get,
        url: 'https://example.com/b1',
        auth: HttpAuth(type: AuthType.inherit),
      );
      final reqB2 = HttpRequest(
        id: 'req-b2',
        name: 'Req B2',
        method: HttpMethod.get,
        url: 'https://example.com/b2',
        auth: HttpAuth(
          type: AuthType.basic,
          basicUsername: '{{req_user}}',
          basicPassword: '{{req_pass}}',
        ),
      );
      final colB = RequestCollection(
        id: 'col-b',
        name: 'Collection B',
        workspaceId: workspaceId,
        requests: [reqB1, reqB2],
        auth: HttpAuth(
          type: AuthType.bearer,
          bearerToken: '{{col_token}}',
        ),
      );

      final reqC = HttpRequest(
        id: 'req-c',
        name: 'Req C',
        method: HttpMethod.get,
        url: 'https://example.com/c',
        auth: HttpAuth(type: AuthType.inherit),
      );
      final colC = RequestCollection(
        id: 'col-c',
        name: 'Collection C',
        workspaceId: workspaceId,
        requests: [reqC],
        auth: HttpAuth(type: AuthType.none),
      );

      await provider.addCollection(colA);
      await provider.addCollection(colB);
      await provider.addCollection(colC);

      provider.startWorkspaceRun();
      expect(provider.runnerItems.length, equals(4));

      await provider.executeRunnerSession(
        variables: variables,
        workspaceAuth: wsAuth,
      );

      expect(provider.runnerItems[0].status, equals('success')); // Req A
      expect(provider.runnerItems[1].status, equals('success')); // Req B1
      expect(provider.runnerItems[2].status, equals('success')); // Req B2
      expect(provider.runnerItems[3].status, equals('success')); // Req C

      expect(recorder.requests.length, equals(4));

      final reqAOptions = recorder.requests.firstWhere((r) => r.path == 'https://example.com/a');
      expect(reqAOptions.headers['X-WS-Auth'], equals('ws-token-123'));

      final reqB1Options = recorder.requests.firstWhere((r) => r.path == 'https://example.com/b1');
      expect(reqB1Options.headers['Authorization'], equals('Bearer col-token-456'));

      final reqB2Options = recorder.requests.firstWhere((r) => r.path == 'https://example.com/b2');
      final expectedBase64 = base64Encode(utf8.encode('runner-user:runner-pass'));
      expect(reqB2Options.headers['Authorization'], equals('Basic $expectedBase64'));

      final reqCOptions = recorder.requests.firstWhere((r) => r.path == 'https://example.com/c');
      expect(reqCOptions.headers.containsKey('Authorization'), isFalse);
      expect(reqCOptions.headers.containsKey('X-WS-Auth'), isFalse);
    });
  });
}

class RecordingInterceptor extends Interceptor {
  final List<RequestOptions> requests = [];

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    requests.add(options);
    handler.resolve(Response(
      requestOptions: options,
      statusCode: 200,
      data: '{"status":"ok"}',
    ));
  }
}
