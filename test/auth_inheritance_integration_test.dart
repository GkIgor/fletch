import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fletch/core/app_config.dart';
import 'package:fletch/models/collection_model.dart';
import 'package:fletch/models/http_auth.dart';
import 'package:fletch/models/http_method.dart';
import 'package:fletch/models/http_request.dart';
import 'package:fletch/models/workspace_models.dart';
import 'package:fletch/providers/request_provider.dart';
import 'package:fletch/providers/workspace_provider.dart';
import 'package:fletch/services/http_service.dart';
import 'package:fletch/utils/auth_resolver.dart';
import 'package:fletch/widgets/interpolated_text_controller.dart';
import 'package:fletch/widgets/runner_view.dart';

void main() {
  late Directory tempDir;
  late String originalWorkspaceDir;
  late String originalCollectionsDir;

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    originalWorkspaceDir = AppConfig.workspaceDir;
    originalCollectionsDir = AppConfig.collectionsDir;
    tempDir = await Directory.systemTemp.createTemp('auth_integration_test_');
    AppConfig.workspaceDir = '${tempDir.path}/workspaces';
    AppConfig.collectionsDir = '${tempDir.path}/collections';
    await Directory(AppConfig.workspaceDir).create(recursive: true);
    await Directory(AppConfig.collectionsDir).create(recursive: true);
  });

  tearDownAll(() async {
    AppConfig.workspaceDir = originalWorkspaceDir;
    AppConfig.collectionsDir = originalCollectionsDir;
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

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

  group('RunnerView URL Display Interpolation Tests', () {
    testWidgets('RunnerView displays interpolated URL in request list and detail pane', (WidgetTester tester) async {
      final workspaceProvider = WorkspaceProvider();
      final requestProvider = RequestProvider();

      // 1. Create a workspace with an active environment containing a variable
      final ws = WorkspaceModel(
        id: 'ws-test-runner-ui',
        name: 'Test WS',
      );
      final env = EnvironmentModel(
        id: 'env-test-runner-ui',
        name: 'Test Env',
        variables: {
          'baseUrl': WorkspaceSecretKey(value: 'api.example.com'),
        },
      );
      ws.environments.add(env);
      ws.selectedEnvironmentId = env.id;

      // 2. Set up request list in RequestProvider
      final req = HttpRequest(
        id: 'req-runner-ui-test',
        name: 'Test Request URL',
        method: HttpMethod.get,
        url: 'http://{{baseUrl}}/api/users',
      );
      final col = RequestCollection(
        id: 'col-runner-ui-test',
        name: 'Test Col',
        workspaceId: ws.id,
        requests: [req],
      );

      // Set viewport size to avoid layout overflows
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.runAsync(() async {
        await workspaceProvider.addWorkspace(ws);
        await requestProvider.addCollection(col);
        await workspaceProvider.loadWorkspaces();
        workspaceProvider.openWorkspace(ws.id);
        await workspaceProvider.selectEnvironment(env.id);
        await requestProvider.loadCollections(ws.id);
      });

      requestProvider.startCollectionRun(col);

      // 3. Pump the RunnerView inside the provider scope
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<WorkspaceProvider>.value(value: workspaceProvider),
            ChangeNotifierProvider<RequestProvider>.value(value: requestProvider),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: RunnerView(),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 4. Verify that the list view shows the interpolated URL: "http://api.example.com/api/users"
      // And NOT the raw URL "http://{{baseUrl}}/api/users"
      expect(find.text('http://api.example.com/api/users'), findsOneWidget);
      expect(find.text('http://{{baseUrl}}/api/users'), findsNothing);

      // 5. Select the item to show it in the detail pane
      await tester.tap(find.text('Test Request URL'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 6. Verify that the detail pane shows the interpolated URL: "http://api.example.com/api/users"
      expect(find.text('http://api.example.com/api/users'), findsAtLeastNWidgets(1));
      expect(find.text('http://{{baseUrl}}/api/users'), findsNothing);
    }, timeout: const Timeout(Duration(seconds: 5)));
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
