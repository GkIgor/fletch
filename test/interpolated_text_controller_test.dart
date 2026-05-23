import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fletch/widgets/interpolated_text_controller.dart';

void main() {
  testWidgets('InterpolatedTextController highlights variables correctly', (WidgetTester tester) async {
    final controller = InterpolatedTextController(
      text: 'http://{{host}}/api/{{nonexistent_var}}',
      availableVariables: {'host'},
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

              // Structure of children should be:
              // 1. TextSpan: 'http://'
              // 2. TextSpan: '{{host}}' (existing, color = 0xFFF59E0B)
              // 3. TextSpan: '/api/'
              // 4. TextSpan: '{{nonexistent_var}}' (non-existing, color = 0xFFEF4444)
              expect(span.children, isNotNull);
              expect(span.children!.length, equals(4));

              final firstChild = span.children![0] as TextSpan;
              expect(firstChild.text, equals('http://'));
              expect(firstChild.style?.color, isNull);

              final secondChild = span.children![1] as TextSpan;
              expect(secondChild.text, equals('{{host}}'));
              expect(secondChild.style?.color, equals(const Color(0xFFF59E0B)));
              expect(secondChild.style?.fontWeight, equals(FontWeight.bold));

              final thirdChild = span.children![2] as TextSpan;
              expect(thirdChild.text, equals('/api/'));
              expect(thirdChild.style?.color, isNull);

              final fourthChild = span.children![3] as TextSpan;
              expect(fourthChild.text, equals('{{nonexistent_var}}'));
              expect(fourthChild.style?.color, equals(const Color(0xFFEF4444)));
              expect(fourthChild.style?.fontWeight, equals(FontWeight.bold));

              return Container();
            },
          ),
        ),
      ),
    );
  });
}
