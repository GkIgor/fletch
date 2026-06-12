import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:fletch/models/visual_script.dart';

void main() {
  group('VisualScript & Decoupled ValueSource Polymorphic Serialization Tests', () {
    test('Should serialize and deserialize ValueSource values correctly', () {
      final script = VisualScript(
        name: 'Decoupled Setup Script',
        isPreRequest: true,
        mode: ScriptMode.lowCode,
        startNodeId: 'set1',
        nodes: {
          'set1': SetVariableStep(
            id: 'set1',
            name: 'Atribuir Variáveis',
            assignments: [
              VariableAssignment(
                variableName: 'userId',
                valueSource: ValueSource(
                  type: ValueSourceType.responseBody,
                  jsonPath: 'data.id',
                ),
              ),
            ],
            nextStepId: 'assert1',
          ),
          'assert1': AssertValueStep(
            id: 'assert1',
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
      );

      final jsonMap = script.toJson();
      final jsonStr = jsonEncode(jsonMap);
      
      final decodedScript = VisualScript.fromJson(jsonDecode(jsonStr));

      expect(decodedScript.nodes.length, equals(2));
      expect(decodedScript.startNodeId, equals('set1'));

      // 1. SetVariableStep with ValueSource check
      expect(decodedScript.nodes['set1'], isA<SetVariableStep>());
      final step0 = decodedScript.nodes['set1'] as SetVariableStep;
      expect(step0.assignments[0].variableName, equals('userId'));
      expect(step0.assignments[0].valueSource.type, equals(ValueSourceType.responseBody));
      expect(step0.assignments[0].valueSource.jsonPath, equals('data.id'));

      // 2. AssertValueStep with ValueSource check
      expect(decodedScript.nodes['assert1'], isA<AssertValueStep>());
      final step1 = decodedScript.nodes['assert1'] as AssertValueStep;
      expect(step1.leftSource.type, equals(ValueSourceType.responseStatusCode));
      expect(step1.operator, equals('=='));
      expect(step1.rightSource.type, equals(ValueSourceType.constant));
      expect(step1.rightSource.key, equals('200'));
    });

    test('Should serialize and deserialize the 10 new steps correctly', () {
      final sortStep = SortStep(
        id: 'sort-1',
        name: 'My Sort',
        enabled: true,
        nextStepId: 'limit-1',
        arraySource: ValueSource(type: ValueSourceType.variable, key: 'myList'),
        sortByPath: 'age',
        ascending: false,
        saveToVariable: 'sortedList',
      );

      final limitStep = LimitStep(
        id: 'limit-1',
        name: 'My Limit',
        enabled: true,
        nextStepId: 'dup-1',
        arraySource: ValueSource(type: ValueSourceType.variable, key: 'sortedList'),
        limit: 5,
        offset: 2,
        saveToVariable: 'limitedList',
      );

      final removeDuplicatesStep = RemoveDuplicatesStep(
        id: 'dup-1',
        name: 'My Dup',
        enabled: true,
        nextStepId: 'crypto-1',
        arraySource: ValueSource(type: ValueSourceType.variable, key: 'limitedList'),
        comparePath: 'id',
        saveToVariable: 'uniqueList',
      );

      final cryptoStep = CryptoStep(
        id: 'crypto-1',
        name: 'My Crypto',
        enabled: true,
        nextStepId: 'json-1',
        operation: 'hashMD5',
        valueSource: ValueSource(type: ValueSourceType.constant, key: 'hello'),
        keySource: ValueSource(type: ValueSourceType.constant, key: 'secret'),
        saveToVariable: 'hashedVal',
      );

      final jsonConvertStep = JsonConvertStep(
        id: 'json-1',
        name: 'My Json',
        enabled: true,
        nextStepId: 'xml-1',
        operation: 'serialize',
        valueSource: ValueSource(type: ValueSourceType.variable, key: 'obj'),
        saveToVariable: 'jsonStr',
      );

      final xmlConvertStep = XmlConvertStep(
        id: 'xml-1',
        name: 'My Xml',
        enabled: true,
        nextStepId: 'html-1',
        operation: 'xmlToJson',
        valueSource: ValueSource(type: ValueSourceType.variable, key: 'xmlStr'),
        saveToVariable: 'parsedXml',
      );

      final htmlConvertStep = HtmlConvertStep(
        id: 'html-1',
        name: 'My Html',
        enabled: true,
        nextStepId: 'md-1',
        operation: 'extractSelector',
        valueSource: ValueSource(type: ValueSourceType.variable, key: 'htmlStr'),
        selector: 'div.content',
        attribute: 'text',
        saveToVariable: 'extractedHtml',
      );

      final markdownConvertStep = MarkdownConvertStep(
        id: 'md-1',
        name: 'My Md',
        enabled: true,
        nextStepId: 'jsonpath-1',
        operation: 'markdownToHtml',
        valueSource: ValueSource(type: ValueSourceType.variable, key: 'mdStr'),
        saveToVariable: 'htmlOutput',
      );

      final jsonPathStep = JsonPathStep(
        id: 'jsonpath-1',
        name: 'My JsonPath',
        enabled: true,
        nextStepId: 'header-1',
        valueSource: ValueSource(type: ValueSourceType.variable, key: 'jsonData'),
        jsonPathExpression: r'$.items[*].name',
        saveToVariable: 'names',
      );

      final headerBuilderStep = HeaderBuilderStep(
        id: 'header-1',
        name: 'My HeaderBuilder',
        enabled: true,
        nextStepId: null,
        authType: 'bearer',
        tokenSource: ValueSource(type: ValueSourceType.variable, key: 'jwt'),
        additionalHeaders: {'Content-Type': 'application/json'},
        saveToVariable: 'myHeaders',
      );

      final script = VisualScript(
        name: '10 Steps Test Script',
        isPreRequest: true,
        mode: ScriptMode.lowCode,
        startNodeId: 'sort-1',
        nodes: {
          'sort-1': sortStep,
          'limit-1': limitStep,
          'dup-1': removeDuplicatesStep,
          'crypto-1': cryptoStep,
          'json-1': jsonConvertStep,
          'xml-1': xmlConvertStep,
          'html-1': htmlConvertStep,
          'md-1': markdownConvertStep,
          'jsonpath-1': jsonPathStep,
          'header-1': headerBuilderStep,
        },
      );

      final jsonMap = script.toJson();
      final jsonStr = jsonEncode(jsonMap);
      final decodedScript = VisualScript.fromJson(jsonDecode(jsonStr));

      expect(decodedScript.nodes.length, equals(10));
      expect(decodedScript.startNodeId, equals('sort-1'));

      // Validate SortStep
      expect(decodedScript.nodes['sort-1'], isA<SortStep>());
      final decodedSort = decodedScript.nodes['sort-1'] as SortStep;
      expect(decodedSort.type, equals(VisualStepType.sort));
      expect(decodedSort.type.name, equals('sort'));
      expect(decodedSort.sortByPath, equals('age'));
      expect(decodedSort.ascending, isFalse);
      expect(decodedSort.saveToVariable, equals('sortedList'));

      // Validate LimitStep
      expect(decodedScript.nodes['limit-1'], isA<LimitStep>());
      final decodedLimit = decodedScript.nodes['limit-1'] as LimitStep;
      expect(decodedLimit.type, equals(VisualStepType.limit));
      expect(decodedLimit.type.name, equals('limit'));
      expect(decodedLimit.limit, equals(5));
      expect(decodedLimit.offset, equals(2));
      expect(decodedLimit.saveToVariable, equals('limitedList'));

      // Validate RemoveDuplicatesStep
      expect(decodedScript.nodes['dup-1'], isA<RemoveDuplicatesStep>());
      final decodedDup = decodedScript.nodes['dup-1'] as RemoveDuplicatesStep;
      expect(decodedDup.type, equals(VisualStepType.removeDuplicates));
      expect(decodedDup.type.name, equals('removeDuplicates'));
      expect(decodedDup.comparePath, equals('id'));
      expect(decodedDup.saveToVariable, equals('uniqueList'));

      // Validate CryptoStep
      expect(decodedScript.nodes['crypto-1'], isA<CryptoStep>());
      final decodedCrypto = decodedScript.nodes['crypto-1'] as CryptoStep;
      expect(decodedCrypto.type, equals(VisualStepType.crypto));
      expect(decodedCrypto.type.name, equals('crypto'));
      expect(decodedCrypto.operation, equals('hashMD5'));
      expect(decodedCrypto.valueSource.key, equals('hello'));
      expect(decodedCrypto.keySource?.key, equals('secret'));
      expect(decodedCrypto.saveToVariable, equals('hashedVal'));

      // Validate JsonConvertStep
      expect(decodedScript.nodes['json-1'], isA<JsonConvertStep>());
      final decodedJson = decodedScript.nodes['json-1'] as JsonConvertStep;
      expect(decodedJson.type, equals(VisualStepType.jsonConvert));
      expect(decodedJson.type.name, equals('jsonConvert'));
      expect(decodedJson.operation, equals('serialize'));
      expect(decodedJson.saveToVariable, equals('jsonStr'));

      // Validate XmlConvertStep
      expect(decodedScript.nodes['xml-1'], isA<XmlConvertStep>());
      final decodedXml = decodedScript.nodes['xml-1'] as XmlConvertStep;
      expect(decodedXml.type, equals(VisualStepType.xmlConvert));
      expect(decodedXml.type.name, equals('xmlConvert'));
      expect(decodedXml.operation, equals('xmlToJson'));
      expect(decodedXml.saveToVariable, equals('parsedXml'));

      // Validate HtmlConvertStep
      expect(decodedScript.nodes['html-1'], isA<HtmlConvertStep>());
      final decodedHtml = decodedScript.nodes['html-1'] as HtmlConvertStep;
      expect(decodedHtml.type, equals(VisualStepType.htmlConvert));
      expect(decodedHtml.type.name, equals('htmlConvert'));
      expect(decodedHtml.operation, equals('extractSelector'));
      expect(decodedHtml.selector, equals('div.content'));
      expect(decodedHtml.attribute, equals('text'));
      expect(decodedHtml.saveToVariable, equals('extractedHtml'));

      // Validate MarkdownConvertStep
      expect(decodedScript.nodes['md-1'], isA<MarkdownConvertStep>());
      final decodedMd = decodedScript.nodes['md-1'] as MarkdownConvertStep;
      expect(decodedMd.type, equals(VisualStepType.markdownConvert));
      expect(decodedMd.type.name, equals('markdownConvert'));
      expect(decodedMd.operation, equals('markdownToHtml'));
      expect(decodedMd.saveToVariable, equals('htmlOutput'));

      // Validate JsonPathStep
      expect(decodedScript.nodes['jsonpath-1'], isA<JsonPathStep>());
      final decodedJsonPath = decodedScript.nodes['jsonpath-1'] as JsonPathStep;
      expect(decodedJsonPath.type, equals(VisualStepType.jsonPathStep));
      expect(decodedJsonPath.type.name, equals('jsonPathStep'));
      expect(decodedJsonPath.jsonPathExpression, equals(r'$.items[*].name'));
      expect(decodedJsonPath.saveToVariable, equals('names'));

      // Validate HeaderBuilderStep
      expect(decodedScript.nodes['header-1'], isA<HeaderBuilderStep>());
      final decodedHeader = decodedScript.nodes['header-1'] as HeaderBuilderStep;
      expect(decodedHeader.type, equals(VisualStepType.headerBuilder));
      expect(decodedHeader.type.name, equals('headerBuilder'));
      expect(decodedHeader.authType, equals('bearer'));
      expect(decodedHeader.tokenSource.key, equals('jwt'));
      expect(decodedHeader.additionalHeaders['Content-Type'], equals('application/json'));
      expect(decodedHeader.saveToVariable, equals('myHeaders'));
    });

    test('Should serialize and deserialize StartStep correctly', () {
      final startStep = StartStep(
        id: 'start-1',
        name: 'My Start',
        enabled: true,
        nextStepId: 'next-1',
      );

      final script = VisualScript(
        name: 'Start Step Test Script',
        startNodeId: 'start-1',
        nodes: {
          'start-1': startStep,
        },
      );

      final jsonMap = script.toJson();
      final jsonStr = jsonEncode(jsonMap);
      final decodedScript = VisualScript.fromJson(jsonDecode(jsonStr));

      expect(decodedScript.nodes.length, equals(1));
      expect(decodedScript.startNodeId, equals('start-1'));
      expect(decodedScript.nodes['start-1'], isA<StartStep>());
      final decodedStart = decodedScript.nodes['start-1'] as StartStep;
      expect(decodedStart.type, equals(VisualStepType.start));
      expect(decodedStart.type.name, equals('start'));
      expect(decodedStart.name, equals('My Start'));
      expect(decodedStart.enabled, isTrue);
      expect(decodedStart.nextStepId, equals('next-1'));
    });

    test('Should serialize and deserialize FailStep and EndStep correctly', () {
      final failStep = FailStep(
        id: 'fail-1',
        name: 'My Fail',
        enabled: true,
      );
      final endStep = EndStep(
        id: 'end-1',
        name: 'My End',
        enabled: true,
      );

      final script = VisualScript(
        name: 'Fail and End Step Test Script',
        startNodeId: 'start-1',
        nodes: {
          'fail-1': failStep,
          'end-1': endStep,
        },
      );

      final jsonMap = script.toJson();
      final jsonStr = jsonEncode(jsonMap);
      final decodedScript = VisualScript.fromJson(jsonDecode(jsonStr));

      expect(decodedScript.nodes.length, equals(2));
      expect(decodedScript.nodes['fail-1'], isA<FailStep>());
      final decodedFail = decodedScript.nodes['fail-1'] as FailStep;
      expect(decodedFail.type, equals(VisualStepType.fail));
      expect(decodedFail.type.name, equals('fail'));
      expect(decodedFail.name, equals('My Fail'));

      expect(decodedScript.nodes['end-1'], isA<EndStep>());
      final decodedEnd = decodedScript.nodes['end-1'] as EndStep;
      expect(decodedEnd.type, equals(VisualStepType.end));
      expect(decodedEnd.type.name, equals('end'));
      expect(decodedEnd.name, equals('My End'));
    });
  });
}
