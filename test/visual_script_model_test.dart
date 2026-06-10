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
        steps: [
          SetVariableStep(
            enabled: true,
            variableName: 'userId',
            valueSource: ValueSource(
              type: ValueSourceType.responseBody,
              jsonPath: 'data.id',
            ),
          ),
          AssertValueStep(
            enabled: true,
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
      );

      final jsonMap = script.toJson();
      final jsonStr = jsonEncode(jsonMap);
      
      final decodedScript = VisualScript.fromJson(jsonDecode(jsonStr));

      expect(decodedScript.steps.length, equals(2));

      // 1. SetVariableStep with ValueSource check
      expect(decodedScript.steps[0], isA<SetVariableStep>());
      final step0 = decodedScript.steps[0] as SetVariableStep;
      expect(step0.variableName, equals('userId'));
      expect(step0.valueSource.type, equals(ValueSourceType.responseBody));
      expect(step0.valueSource.jsonPath, equals('data.id'));

      // 2. AssertValueStep with ValueSource check
      expect(decodedScript.steps[1], isA<AssertValueStep>());
      final step1 = decodedScript.steps[1] as AssertValueStep;
      expect(step1.leftSource.type, equals(ValueSourceType.responseStatusCode));
      expect(step1.operator, equals('=='));
      expect(step1.rightSource.type, equals(ValueSourceType.constant));
      expect(step1.rightSource.key, equals('200'));
    });
  });
}
