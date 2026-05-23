import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fletch/widgets/code_input_formatter.dart';

void main() {
  final formatter = CodeInputFormatter();

  test('Auto-closes opening brackets', () {
    const oldValue = TextEditingValue(
      text: 'const a = ',
      selection: TextSelection.collapsed(offset: 10),
    );
    const newValue = TextEditingValue(
      text: 'const a = {',
      selection: TextSelection.collapsed(offset: 11),
    );

    final result = formatter.formatEditUpdate(oldValue, newValue);
    expect(result.text, equals('const a = {}'));
    expect(result.selection.start, equals(11));
  });

  test('Skips closing bracket if already present', () {
    const oldValue = TextEditingValue(
      text: 'const a = {}',
      selection: TextSelection.collapsed(offset: 11), // between { and }
    );
    const newValue = TextEditingValue(
      text: 'const a = {}}',
      selection: TextSelection.collapsed(offset: 12),
    );

    final result = formatter.formatEditUpdate(oldValue, newValue);
    expect(result.text, equals('const a = {}'));
    expect(result.selection.start, equals(12));
  });

  test('Deletes matching closing bracket on backspace', () {
    const oldValue = TextEditingValue(
      text: 'const a = {}',
      selection: TextSelection.collapsed(offset: 11), // between { and }
    );
    const newValue = TextEditingValue(
      text: 'const a = }',
      selection: TextSelection.collapsed(offset: 10),
    );

    final result = formatter.formatEditUpdate(oldValue, newValue);
    expect(result.text, equals('const a = '));
    expect(result.selection.start, equals(10));
  });

  test('Auto-indents on newline with open bracket', () {
    const oldValue = TextEditingValue(
      text: '  {',
      selection: TextSelection.collapsed(offset: 3),
    );
    const newValue = TextEditingValue(
      text: '  {\n',
      selection: TextSelection.collapsed(offset: 4),
    );

    final result = formatter.formatEditUpdate(oldValue, newValue);
    expect(result.text, equals('  {\n    '));
    expect(result.selection.start, equals(8));
  });

  test('Auto-indents and separates brackets on newline when closed bracket is next', () {
    const oldValue = TextEditingValue(
      text: '  {}',
      selection: TextSelection.collapsed(offset: 3), // between { and }
    );
    const newValue = TextEditingValue(
      text: '  {\n}',
      selection: TextSelection.collapsed(offset: 4),
    );

    final result = formatter.formatEditUpdate(oldValue, newValue);
    expect(result.text, equals('  {\n    \n  }'));
    expect(result.selection.start, equals(8)); // end of middle line ('  {\n    ')
  });

  test('Wraps selected text in symbols', () {
    const oldValue = TextEditingValue(
      text: 'my value',
      selection: TextSelection(baseOffset: 3, extentOffset: 8), // 'value'
    );
    const newValue = TextEditingValue(
      text: 'my {value',
      selection: TextSelection.collapsed(offset: 4),
    );

    final result = formatter.formatEditUpdate(oldValue, newValue);
    expect(result.text, equals('my {value}'));
    expect(result.selection.start, equals(4));
    expect(result.selection.end, equals(9));
  });
}
