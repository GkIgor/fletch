import 'package:flutter/services.dart';

class CodeInputFormatter extends TextInputFormatter {
  static const Map<String, String> _pairMap = {
    '{': '}',
    '[': ']',
    '(': ')',
    '"': '"',
    "'": "'",
  };

  static const Map<String, String> _reversePairMap = {
    '}': '{',
    ']': '[',
    ')': '(',
    '"': '"',
    "'": "'",
  };

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // 1. Se a alteração não for adição nem remoção de 1 caractere, ou for seleção complexa, passa direto
    final oldText = oldValue.text;
    final newText = newValue.text;
    
    // Detectar deleção de um único caractere com backspace
    if (newText.length < oldText.length && oldValue.selection.isCollapsed) {
      final oldStart = oldValue.selection.start;
      // Usuário apagou o caractere na posição oldStart - 1
      if (oldStart > 0 && oldStart <= oldText.length) {
        final deletedChar = oldText[oldStart - 1];
        if (_pairMap.containsKey(deletedChar)) {
          // Se o próximo caractere for o fechamento correspondente, apagamos ambos
          if (oldStart < oldText.length && oldText[oldStart] == _pairMap[deletedChar]) {
            final updatedText = oldText.substring(0, oldStart - 1) + oldText.substring(oldStart + 1);
            return TextEditingValue(
              text: updatedText,
              selection: TextSelection.collapsed(offset: oldStart - 1),
            );
          }
        }
      }
      return newValue;
    }

    // Detectar adição de texto
    if (newText.length > oldText.length) {
      final oldStart = oldValue.selection.start;
      final oldEnd = oldValue.selection.end;

      // Se a seleção não estava vazia (havia texto selecionado) e foi digitado um caractere de abre-símbolo
      if (!oldValue.selection.isCollapsed) {
        final addedText = newText.substring(oldStart, newValue.selection.end);
        if (addedText.length == 1 && _pairMap.containsKey(addedText)) {
          final closing = _pairMap[addedText]!;
          final selectedText = oldText.substring(oldStart, oldEnd);
          final wrapped = '$addedText$selectedText$closing';
          final prefix = oldText.substring(0, oldStart);
          final suffix = oldText.substring(oldEnd);
          final updatedText = '$prefix$wrapped$suffix';
          return TextEditingValue(
            text: updatedText,
            selection: TextSelection(
              baseOffset: oldStart + 1,
              extentOffset: oldEnd + 1,
            ),
          );
        }
        return newValue;
      }

      // Seleção vazia, digitação simples
      final addedText = newText.substring(oldStart, newValue.selection.end);
      if (addedText.length == 1) {
        final char = addedText;

        // Auto-pular caractere de fechamento se ele já estiver na frente do cursor
        if (_reversePairMap.containsKey(char)) {
          if (oldStart < oldText.length && oldText[oldStart] == char) {
            // Se digitou uma aspa e as aspas antes e depois batem, ou é apenas um pulo
            return TextEditingValue(
              text: oldText,
              selection: TextSelection.collapsed(offset: oldStart + 1),
            );
          }
        }

        // Auto-fechar abertura de símbolo
        if (_pairMap.containsKey(char)) {
          final closing = _pairMap[char]!;
          final prefix = oldText.substring(0, oldStart);
          final suffix = oldText.substring(oldStart);
          final updatedText = '$prefix$char$closing$suffix';
          return TextEditingValue(
            text: updatedText,
            selection: TextSelection.collapsed(offset: oldStart + 1),
          );
        }

        // Auto-identação no Enter
        if (char == '\n') {
          // Achar o início da linha atual
          final lastNewline = oldText.lastIndexOf('\n', oldStart - 1);
          final lineStart = lastNewline == -1 ? 0 : lastNewline + 1;
          final lineContent = oldText.substring(lineStart, oldStart);

          // Capturar recuo da linha atual
          String indent = '';
          for (int i = 0; i < lineContent.length; i++) {
            if (lineContent[i] == ' ' || lineContent[i] == '\t') {
              indent += lineContent[i];
            } else {
              break;
            }
          }

          final trimmedLine = lineContent.trimRight();
          final isOpenBracket = trimmedLine.endsWith('{') || trimmedLine.endsWith('[') || trimmedLine.endsWith('(');

          if (isOpenBracket) {
            // Verificar se o próximo caractere é o fechamento correspondente
            bool nextIsCloseBracket = false;
            if (oldStart < oldText.length) {
              final nextChar = oldText[oldStart];
              nextIsCloseBracket = (trimmedLine.endsWith('{') && nextChar == '}') ||
                                   (trimmedLine.endsWith('[') && nextChar == ']') ||
                                   (trimmedLine.endsWith('(') && nextChar == ')');
            }

            if (nextIsCloseBracket) {
              // Comportamento IDE: quebra linha, identa linha do meio (+2 espaços) e coloca o fechamento na linha seguinte com indent original
              final middleIndent = '$indent  ';
              final prefix = oldText.substring(0, oldStart);
              final suffix = oldText.substring(oldStart);
              final updatedText = '$prefix\n$middleIndent\n$indent$suffix';
              return TextEditingValue(
                text: updatedText,
                selection: TextSelection.collapsed(offset: oldStart + 1 + middleIndent.length),
              );
            } else {
              // Apenas quebra linha e identa com +2 espaços
              final middleIndent = '$indent  ';
              final prefix = oldText.substring(0, oldStart);
              final suffix = oldText.substring(oldStart);
              final updatedText = '$prefix\n$middleIndent$suffix';
              return TextEditingValue(
                text: updatedText,
                selection: TextSelection.collapsed(offset: oldStart + 1 + middleIndent.length),
              );
            }
          } else {
            // Apenas preserva o recuo original
            final prefix = oldText.substring(0, oldStart);
            final suffix = oldText.substring(oldStart);
            final updatedText = '$prefix\n$indent$suffix';
            return TextEditingValue(
              text: updatedText,
              selection: TextSelection.collapsed(offset: oldStart + 1 + indent.length),
            );
          }
        }
      }
    }

    return newValue;
  }
}
