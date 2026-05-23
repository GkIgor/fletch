import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fletch/widgets/code_highlight_controller.dart';

void main() {
  testWidgets('Test CodeHighlightController builds correct spans', (WidgetTester tester) async {
    final controller = CodeHighlightController(
      text: '{"key": "value", "num": 123}',
      language: 'json',
      isDark: true,
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
              expect(span.children!.length, greaterThan(0));
              
              final firstChild = span.children!.first as TextSpan;
              expect(firstChild.text, equals('{'));

              // Verify the attr span (key) propagates color Color(0xFF38BDF8) to its child textspan
              final keyParentSpan = span.children![1] as TextSpan;
              expect(keyParentSpan.style?.color, equals(const Color(0xFF38BDF8)));
              final keyLeafSpan = keyParentSpan.children!.first as TextSpan;
              expect(keyLeafSpan.style?.color, equals(const Color(0xFF38BDF8)));
              expect(keyLeafSpan.text, equals('"key"'));

              return Container();
            },
          ),
        ),
      ),
    );
  });
}
