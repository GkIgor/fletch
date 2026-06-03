import 'package:flutter/services.dart';

class OutlineInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final oldText = oldValue.text;
    final newText = newValue.text;

    // Detect if a single newline character '\n' was added
    if (newText.length > oldText.length) {
      final oldStart = oldValue.selection.start;
      final addedText = newText.substring(oldStart, newValue.selection.end);

      if (addedText == '\n') {
        // Find the beginning of the line where Enter was pressed
        final lastNewline = oldText.lastIndexOf('\n', oldStart - 1);
        final lineStart = lastNewline == -1 ? 0 : lastNewline + 1;
        final lineContent = oldText.substring(lineStart, oldStart);

        // Extract the leading indentation spaces/tabs from the current line
        String indent = '';
        for (int i = 0; i < lineContent.length; i++) {
          if (lineContent[i] == ' ' || lineContent[i] == '\t') {
            indent += lineContent[i];
          } else {
            break;
          }
        }

        final prefix = oldText.substring(0, oldStart);
        final suffix = oldText.substring(oldStart);
        final updatedText = '$prefix\n$indent$suffix';
        return TextEditingValue(
          text: updatedText,
          selection: TextSelection.collapsed(offset: oldStart + 1 + indent.length),
        );
      }
    }
    return newValue;
  }
}
