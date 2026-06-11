import 'dart:convert';
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
        startNodeId: 'node-1',
        nodes: {
          'node-1': DelayStep(id: 'node-1', durationMs: 10),
        },
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
            startNodeId: 'node-1',
            nodes: {
              'node-1': SetVariableStep(
                id: 'node-1',
                assignments: [
                  VariableAssignment(
                    variableName: 'apiKey',
                    valueSource: ValueSource(
                      type: ValueSourceType.constant,
                      key: 'secret_key_123',
                    ),
                  ),
                ],
              ),
            },
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
            startNodeId: 'node-1',
            nodes: {
              'node-1': AssertValueStep(
                id: 'node-1',
                leftSource: ValueSource(
                  type: ValueSourceType.responseStatusCode,
                ),
                operator: '==',
                rightSource: ValueSource(
                  type: ValueSourceType.constant,
                  key: '200',
                ),
              ),
            },
          ),
          VisualScript(
            id: 'post-2',
            name: 'Extract JWT Token',
            isPreRequest: false,
            startNodeId: 'node-2',
            nodes: {
              'node-2': SetVariableStep(
                id: 'node-2',
                assignments: [
                  VariableAssignment(
                    variableName: 'jwt_token',
                    valueSource: ValueSource(
                      type: ValueSourceType.responseBody,
                      jsonPath: 'data.token',
                    ),
                  ),
                ],
              ),
            },
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
            startNodeId: 'node-1',
            nodes: {
              'node-1': AssertValueStep(
                id: 'node-1',
                leftSource: ValueSource(
                  type: ValueSourceType.responseStatusCode,
                ),
                operator: '==',
                rightSource: ValueSource(
                  type: ValueSourceType.constant,
                  key: '201', // Fails since response has 200
                ),
              ),
            },
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

  group('New Low-Code Nodes Execution Tests', () {
    test('SortStep sorts lists by paths ascending/descending', () async {
      final script = VisualScript(
        id: 'script-sort',
        name: 'Sort Test',
        startNodeId: 'sort-node',
        nodes: {
          'sort-node': SortStep(
            id: 'sort-node',
            arraySource: ValueSource(type: ValueSourceType.variable, key: 'inputList'),
            sortByPath: 'age',
            ascending: true,
            saveToVariable: 'outputList',
          ),
        },
      );

      final compiled = ScriptCompiler.compile(script);
      final context = ExecutionContext(
        variables: {
          'inputList': '[{"name": "Alice", "age": 30}, {"name": "Bob", "age": 25}, {"name": "Charlie", "age": 35}]'
        },
      );

      await compiled.execute(context);
      final result = jsonDecode(context.variables['outputList']!) as List;
      expect(result.length, 3);
      expect(result[0]['name'], 'Bob');
      expect(result[1]['name'], 'Alice');
      expect(result[2]['name'], 'Charlie');
    });

    test('LimitStep offsets and limits lists', () async {
      final script = VisualScript(
        id: 'script-limit',
        name: 'Limit Test',
        startNodeId: 'limit-node',
        nodes: {
          'limit-node': LimitStep(
            id: 'limit-node',
            arraySource: ValueSource(type: ValueSourceType.variable, key: 'inputList'),
            limit: 2,
            offset: 1,
            saveToVariable: 'outputList',
          ),
        },
      );

      final compiled = ScriptCompiler.compile(script);
      final context = ExecutionContext(
        variables: {
          'inputList': '["a", "b", "c", "d"]'
        },
      );

      await compiled.execute(context);
      final result = jsonDecode(context.variables['outputList']!) as List;
      expect(result, equals(['b', 'c']));
    });

    test('RemoveDuplicatesStep removes duplicate entries', () async {
      final script = VisualScript(
        id: 'script-dup',
        name: 'Remove Duplicates Test',
        startNodeId: 'dup-node',
        nodes: {
          'dup-node': RemoveDuplicatesStep(
            id: 'dup-node',
            arraySource: ValueSource(type: ValueSourceType.variable, key: 'inputList'),
            comparePath: 'id',
            saveToVariable: 'outputList',
          ),
        },
      );

      final compiled = ScriptCompiler.compile(script);
      final context = ExecutionContext(
        variables: {
          'inputList': '[{"id": 1, "name": "A"}, {"id": 2, "name": "B"}, {"id": 1, "name": "C"}]'
        },
      );

      await compiled.execute(context);
      final result = jsonDecode(context.variables['outputList']!) as List;
      expect(result.length, 2);
      expect(result[0]['name'], 'A');
      expect(result[1]['name'], 'B');
    });

    test('CryptoStepMD5 computes MD5 hash', () async {
      final script = VisualScript(
        id: 'script-crypto-md5',
        name: 'Crypto MD5 Test',
        startNodeId: 'crypto-node',
        nodes: {
          'crypto-node': CryptoStep(
            id: 'crypto-node',
            operation: 'hashMD5',
            valueSource: ValueSource(type: ValueSourceType.constant, key: 'hello'),
            saveToVariable: 'hashed',
          ),
        },
      );

      final compiled = ScriptCompiler.compile(script);
      final context = ExecutionContext(variables: {});
      await compiled.execute(context);
      expect(context.variables['hashed'], equals('5d41402abc4b2a76b9719d911017c592'));
    });

    test('CryptoStepSHA256 computes SHA256 hash', () async {
      final script = VisualScript(
        id: 'script-crypto-sha256',
        name: 'Crypto SHA256 Test',
        startNodeId: 'crypto-node',
        nodes: {
          'crypto-node': CryptoStep(
            id: 'crypto-node',
            operation: 'hashSHA256',
            valueSource: ValueSource(type: ValueSourceType.constant, key: 'hello'),
            saveToVariable: 'hashed',
          ),
        },
      );

      final compiled = ScriptCompiler.compile(script);
      final context = ExecutionContext(variables: {});
      await compiled.execute(context);
      expect(context.variables['hashed'], equals('2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824'));
    });

    test('CryptoStepHMAC computes HMAC-SHA256 hash', () async {
      final script = VisualScript(
        id: 'script-crypto-hmac',
        name: 'Crypto HMAC Test',
        startNodeId: 'crypto-node',
        nodes: {
          'crypto-node': CryptoStep(
            id: 'crypto-node',
            operation: 'hmacSHA256',
            valueSource: ValueSource(type: ValueSourceType.constant, key: 'hello'),
            keySource: ValueSource(type: ValueSourceType.constant, key: 'secret'),
            saveToVariable: 'hashed',
          ),
        },
      );

      final compiled = ScriptCompiler.compile(script);
      final context = ExecutionContext(variables: {});
      await compiled.execute(context);
      expect(context.variables['hashed'], equals('88aab3ede8d3adf94d26ab90d3bafd4a2083070c3bcce9c014ee04a443847c0b'));
    });

    test('JsonConvertStep serializes and deserializes correctly', () async {
      final scriptSer = VisualScript(
        id: 'script-json-ser',
        name: 'JSON Serialize Test',
        startNodeId: 'json-node',
        nodes: {
          'json-node': JsonConvertStep(
            id: 'json-node',
            operation: 'serialize',
            valueSource: ValueSource(type: ValueSourceType.variable, key: 'myVar'),
            saveToVariable: 'serialized',
          ),
        },
      );

      final compiledSer = ScriptCompiler.compile(scriptSer);
      final contextSer = ExecutionContext(variables: {'myVar': '{"a":1}'});
      await compiledSer.execute(contextSer);
      expect(jsonDecode(contextSer.variables['serialized']!), equals({'a': 1}));

      final scriptDes = VisualScript(
        id: 'script-json-des',
        name: 'JSON Deserialize Test',
        startNodeId: 'json-node',
        nodes: {
          'json-node': JsonConvertStep(
            id: 'json-node',
            operation: 'deserialize',
            valueSource: ValueSource(type: ValueSourceType.variable, key: 'myVar'),
            saveToVariable: 'deserialized',
          ),
        },
      );

      final compiledDes = ScriptCompiler.compile(scriptDes);
      final contextDes = ExecutionContext(variables: {'myVar': '{"b":2}'});
      await compiledDes.execute(contextDes);
      expect(jsonDecode(contextDes.variables['deserialized']!), equals({'b': 2}));
    });

    test('XmlConvertStep converts XML to JSON and vice-versa', () async {
      final scriptXmlToJson = VisualScript(
        id: 'script-xml-to-json',
        name: 'XML to JSON Test',
        startNodeId: 'xml-node',
        nodes: {
          'xml-node': XmlConvertStep(
            id: 'xml-node',
            operation: 'xmlToJson',
            valueSource: ValueSource(type: ValueSourceType.variable, key: 'xmlInput'),
            saveToVariable: 'jsonOutput',
          ),
        },
      );

      final compiledXmlToJson = ScriptCompiler.compile(scriptXmlToJson);
      final contextXmlToJson = ExecutionContext(variables: {
        'xmlInput': '<user><name>Igor</name><age>30</age></user>'
      });
      await compiledXmlToJson.execute(contextXmlToJson);
      final decodedJson = jsonDecode(contextXmlToJson.variables['jsonOutput']!);
      expect(decodedJson['name']['#text'], equals('Igor'));
      expect(decodedJson['age']['#text'], equals('30'));

      final scriptJsonToXml = VisualScript(
        id: 'script-json-to-xml',
        name: 'JSON to XML Test',
        startNodeId: 'xml-node',
        nodes: {
          'xml-node': XmlConvertStep(
            id: 'xml-node',
            operation: 'jsonToXml',
            valueSource: ValueSource(type: ValueSourceType.variable, key: 'jsonInput'),
            saveToVariable: 'xmlOutput',
          ),
        },
      );

      final compiledJsonToXml = ScriptCompiler.compile(scriptJsonToXml);
      final contextJsonToXml = ExecutionContext(variables: {
        'jsonInput': '{"name": "Igor", "age": 30}'
      });
      await compiledJsonToXml.execute(contextJsonToXml);
      final xmlResult = contextJsonToXml.variables['xmlOutput']!;
      expect(xmlResult.contains('<name>Igor</name>'), isTrue);
      expect(xmlResult.contains('<age>30</age>'), isTrue);
    });

    test('HtmlConvertStep cleans tags and extracts elements/attributes', () async {
      final scriptHtmlToText = VisualScript(
        id: 'script-html-to-text',
        name: 'HTML to Text Test',
        startNodeId: 'html-node',
        nodes: {
          'html-node': HtmlConvertStep(
            id: 'html-node',
            operation: 'htmlToText',
            valueSource: ValueSource(type: ValueSourceType.variable, key: 'htmlInput'),
            saveToVariable: 'textOutput',
          ),
        },
      );

      final compiledHtmlToText = ScriptCompiler.compile(scriptHtmlToText);
      final contextHtmlToText = ExecutionContext(variables: {
        'htmlInput': '<div><h1>Hello</h1><p>World</p></div>'
      });
      await compiledHtmlToText.execute(contextHtmlToText);
      expect(contextHtmlToText.variables['textOutput']!.trim(), equals('HelloWorld'));

      final scriptExtractSelector = VisualScript(
        id: 'script-extract-selector',
        name: 'Extract CSS Selector Test',
        startNodeId: 'html-node',
        nodes: {
          'html-node': HtmlConvertStep(
            id: 'html-node',
            operation: 'extractSelector',
            valueSource: ValueSource(type: ValueSourceType.variable, key: 'htmlInput'),
            selector: 'div.item',
            saveToVariable: 'elementsOutput',
          ),
        },
      );

      final compiledExtractSelector = ScriptCompiler.compile(scriptExtractSelector);
      final contextExtractSelector = ExecutionContext(variables: {
        'htmlInput': '<html><body><div class="item">A</div><div class="item">B</div></body></html>'
      });
      await compiledExtractSelector.execute(contextExtractSelector);
      final elements = jsonDecode(contextExtractSelector.variables['elementsOutput']!) as List;
      expect(elements.length, 2);
      expect(elements[0], contains('A'));
      expect(elements[1], contains('B'));
    });

    test('MarkdownConvertStep converts Markdown to HTML and vice-versa', () async {
      final scriptMdToHtml = VisualScript(
        id: 'script-md-to-html',
        name: 'Markdown to HTML Test',
        startNodeId: 'md-node',
        nodes: {
          'md-node': MarkdownConvertStep(
            id: 'md-node',
            operation: 'markdownToHtml',
            valueSource: ValueSource(type: ValueSourceType.variable, key: 'mdInput'),
            saveToVariable: 'htmlOutput',
          ),
        },
      );

      final compiledMdToHtml = ScriptCompiler.compile(scriptMdToHtml);
      final contextMdToHtml = ExecutionContext(variables: {
        'mdInput': '**bold** and *italic*'
      });
      await compiledMdToHtml.execute(contextMdToHtml);
      expect(contextMdToHtml.variables['htmlOutput'], equals('<strong>bold</strong> and <em>italic</em>'));

      final scriptHtmlToMd = VisualScript(
        id: 'script-html-to-md',
        name: 'HTML to Markdown Test',
        startNodeId: 'md-node',
        nodes: {
          'md-node': MarkdownConvertStep(
            id: 'md-node',
            operation: 'htmlToMarkdown',
            valueSource: ValueSource(type: ValueSourceType.variable, key: 'htmlInput'),
            saveToVariable: 'mdOutput',
          ),
        },
      );

      final compiledHtmlToMd = ScriptCompiler.compile(scriptHtmlToMd);
      final contextHtmlToMd = ExecutionContext(variables: {
        'htmlInput': '<strong>bold</strong> and <em>italic</em>'
      });
      await compiledHtmlToMd.execute(contextHtmlToMd);
      expect(contextHtmlToMd.variables['mdOutput'], equals('**bold** and *italic*'));
    });

    test('JsonPathStep extracts values using dot notation path', () async {
      final scriptJsonPath = VisualScript(
        id: 'script-json-path',
        name: 'JSON Path Test',
        startNodeId: 'path-node',
        nodes: {
          'path-node': JsonPathStep(
            id: 'path-node',
            valueSource: ValueSource(type: ValueSourceType.variable, key: 'jsonInput'),
            jsonPathExpression: r'$.user.profile.name',
            saveToVariable: 'extractedName',
          ),
        },
      );

      final compiledJsonPath = ScriptCompiler.compile(scriptJsonPath);
      final contextJsonPath = ExecutionContext(variables: {
        'jsonInput': '{"user": {"profile": {"name": "Igor"}}}'
      });
      await compiledJsonPath.execute(contextJsonPath);
      expect(contextJsonPath.variables['extractedName'], equals('Igor'));
    });

    test('HeaderBuilderStep creates header structures', () async {
      final scriptHeader = VisualScript(
        id: 'script-header',
        name: 'Header Builder Test',
        startNodeId: 'header-node',
        nodes: {
          'header-node': HeaderBuilderStep(
            id: 'header-node',
            authType: 'bearer',
            tokenSource: ValueSource(type: ValueSourceType.constant, key: 'my-secret-token'),
            additionalHeaders: {'Content-Type': 'application/json'},
            saveToVariable: 'headersOutput',
          ),
        },
      );

      final compiledHeader = ScriptCompiler.compile(scriptHeader);
      final contextHeader = ExecutionContext(variables: {});
      await compiledHeader.execute(contextHeader);
      final headersMap = jsonDecode(contextHeader.variables['headersOutput']!);
      expect(headersMap['Authorization'], equals('Bearer my-secret-token'));
      expect(headersMap['Content-Type'], equals('application/json'));
    });
  });
}
