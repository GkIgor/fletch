import 'package:flutter_test/flutter_test.dart';
import 'package:fletch/models/http_request.dart';
import 'package:fletch/models/http_method.dart';
import 'package:fletch/models/visual_script.dart';
import 'package:fletch/models/workspace_models.dart';
import 'package:fletch/utils/script_compiler.dart';
import 'package:fletch/utils/script_executor.dart';

void main() {
  setUp(() {
    JitCache.clear();
  });

  group('JIT Script Compiler & Cache Tests', () {
    test('Should compile VisualScript and pull from cache subsequently unless timestamp changes', () {
      final script = VisualScript(
        id: 'script-1',
        name: 'Cache Test Script',
        steps: [
          DelayStep(durationMs: 10),
        ],
      );

      final firstCompile = JitCache.getOrCreate(script);
      final secondCompile = JitCache.getOrCreate(script);

      expect(identical(firstCompile, secondCompile), isTrue);

      final updatedScript = script.copyWith(
        name: 'Updated Name',
        updatedAt: DateTime.now().add(const Duration(seconds: 1)),
      );

      final thirdCompile = JitCache.getOrCreate(updatedScript);
      expect(identical(firstCompile, thirdCompile), isFalse);
    });

    test('Should parse JSONPath expressions into search tokens correctly', () {
      final script = VisualScript(
        name: 'JSON Parser script',
        steps: [
          SetVariableStep(
            variableName: 'token',
            valueSource: ValueSource(
              type: ValueSourceType.responseBody,
              jsonPath: 'data.users[0].details.auth_token',
            ),
          ),
        ],
      );

      final compiled = ScriptCompiler.compile(script);
      expect(compiled.steps.first, isA<CompiledSetVariableStep>());
      final step = compiled.steps.first as CompiledSetVariableStep;

      expect(step.source.jsonPathTokens, isNotNull);
      expect(step.source.jsonPathTokens, equals(['data', 'users', 0, 'details', 'auth_token']));
    });
  });

  group('Script Executor and Variable Sandbox Tests', () {
    test('Pre-request scripts should dynamically modify query variables and headers', () async {
      final request = HttpRequest(
        name: 'Sample Req',
        method: HttpMethod.get,
        url: 'https://api.example.com/v1/resource',
        headers: {'Content-Type': 'application/json'},
        activeScriptIds: ['pre-1'],
        inheritScripts: false,
      );

      final workspace = WorkspaceModel(
        name: 'Sandbox WS',
        scripts: [
          VisualScript(
            id: 'pre-1',
            name: 'Inject API Headers',
            isPreRequest: true,
            steps: [
              SetVariableStep(
                variableName: 'apiKey',
                valueSource: ValueSource(
                  type: ValueSourceType.constant,
                  key: 'secret_key_123',
                ),
              ),
            ],
          ),
        ],
      );

      final context = await ScriptExecutor.executePreRequest(
        request: request,
        collections: [],
        workspace: workspace,
        initialVariables: {},
      );

      expect(context.variables['apiKey'], equals('secret_key_123'));
    });

    test('Post-response validation scripts should assert values and save response tokens', () async {
      final request = HttpRequest(
        name: 'Sample Req',
        method: HttpMethod.get,
        url: 'https://api.example.com',
        activeScriptIds: ['post-1', 'post-2'],
        inheritScripts: false,
      );

      final workspace = WorkspaceModel(
        name: 'Sandbox WS',
        scripts: [
          VisualScript(
            id: 'post-1',
            name: 'Assert Ok status',
            isPreRequest: false,
            steps: [
              AssertValueStep(
                leftSource: ValueSource(
                  type: ValueSourceType.responseStatusCode,
                ),
                operator: '==',
                rightSource: ValueSource(
                  type: ValueSourceType.constant,
                  key: '200',
                ),
              ),
            ],
          ),
          VisualScript(
            id: 'post-2',
            name: 'Extract JWT Token',
            isPreRequest: false,
            steps: [
              SetVariableStep(
                variableName: 'jwt_token',
                valueSource: ValueSource(
                  type: ValueSourceType.responseBody,
                  jsonPath: 'data.token',
                ),
              ),
            ],
          ),
        ],
      );

      final context = ExecutionContext(
        variables: {},
        statusCode: 200,
        responseBody: '{"data": {"token": "eyJhbGciOi"}}',
      );

      await ScriptExecutor.executePostResponse(
        request: request,
        collections: [],
        workspace: workspace,
        context: context,
        statusCode: 200,
        responseBody: '{"data": {"token": "eyJhbGciOi"}}',
        responseHeaders: {},
      );

      expect(context.variables['jwt_token'], equals('eyJhbGciOi'));
    });

    test('Assertion failure should raise exception halting execution', () async {
      final request = HttpRequest(
        name: 'Sample Req',
        method: HttpMethod.get,
        url: 'https://api.example.com',
        activeScriptIds: ['post-fail'],
        inheritScripts: false,
      );

      final workspace = WorkspaceModel(
        name: 'Sandbox WS',
        scripts: [
          VisualScript(
            id: 'post-fail',
            name: 'Fail Assert',
            isPreRequest: false,
            steps: [
              AssertValueStep(
                leftSource: ValueSource(
                  type: ValueSourceType.responseStatusCode,
                ),
                operator: '==',
                rightSource: ValueSource(
                  type: ValueSourceType.constant,
                  key: '201', // Fails since response has 200
                ),
              ),
            ],
          ),
        ],
      );

      final context = ExecutionContext(variables: {});

      expect(
        () => ScriptExecutor.executePostResponse(
          request: request,
          collections: [],
          workspace: workspace,
          context: context,
          statusCode: 200,
          responseBody: '{}',
          responseHeaders: {},
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
