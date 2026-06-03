import 'package:flutter/material.dart';
import 'package:fletch/theme/app_colors.dart';
import 'generator_utils.dart';

class OutlineTextEditingController extends TextEditingController {
  final bool isDark;

  OutlineTextEditingController({required this.isDark});

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final baseStyle = style ?? const TextStyle();
    final lines = text.split('\n');
    final children = <TextSpan>[];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lineChildren = <TextSpan>[];

      final trimmed = line.trimLeft();
      final leadingWhitespace = line.substring(0, line.length - trimmed.length);

      if (leadingWhitespace.isNotEmpty) {
        lineChildren.add(TextSpan(text: leadingWhitespace));
      }

      if (trimmed.startsWith('+')) {
        lineChildren.add(TextSpan(
          text: '+',
          style: TextStyle(
            color: isDark ? const Color(0xFFC084FC) : const Color(0xFF7C3AED),
            fontWeight: FontWeight.bold,
          ),
        ));
        lineChildren.add(TextSpan(text: trimmed.substring(1)));
      } else if (trimmed.startsWith('-')) {
        lineChildren.add(const TextSpan(
          text: '-',
          style: TextStyle(
            color: AppColors.slate500,
            fontWeight: FontWeight.bold,
          ),
        ));

        final restOfLine = trimmed.substring(1);
        final RegExp verbRegExp = RegExp(r'\b(GET|POST|PUT|DELETE|PATCH)\b', caseSensitive: false);
        final matches = verbRegExp.allMatches(restOfLine);

        if (matches.isEmpty) {
          lineChildren.add(TextSpan(text: restOfLine));
        } else {
          int lastIndex = 0;
          for (final match in matches) {
            if (match.start > lastIndex) {
              lineChildren.add(TextSpan(text: restOfLine.substring(lastIndex, match.start)));
            }
            final verb = match.group(0)!;
            lineChildren.add(TextSpan(
              text: verb,
              style: TextStyle(
                color: getMethodColor(verb.toUpperCase()),
                fontWeight: FontWeight.bold,
              ),
            ));
            lastIndex = match.end;
          }
          if (lastIndex < restOfLine.length) {
            lineChildren.add(TextSpan(text: restOfLine.substring(lastIndex)));
          }
        }
      } else {
        final RegExp verbRegExp = RegExp(r'\b(GET|POST|PUT|DELETE|PATCH)\b', caseSensitive: false);
        final matches = verbRegExp.allMatches(trimmed);

        if (matches.isEmpty) {
          lineChildren.add(TextSpan(text: trimmed));
        } else {
          int lastIndex = 0;
          for (final match in matches) {
            if (match.start > lastIndex) {
              lineChildren.add(TextSpan(text: trimmed.substring(lastIndex, match.start)));
            }
            final verb = match.group(0)!;
            lineChildren.add(TextSpan(
              text: verb,
              style: TextStyle(
                color: getMethodColor(verb.toUpperCase()),
                fontWeight: FontWeight.bold,
              ),
            ));
            lastIndex = match.end;
          }
          if (lastIndex < trimmed.length) {
            lineChildren.add(TextSpan(text: trimmed.substring(lastIndex)));
          }
        }
      }

      if (i < lines.length - 1) {
        lineChildren.add(const TextSpan(text: '\n'));
      }

      children.addAll(lineChildren);
    }

    return TextSpan(children: children, style: baseStyle);
  }
}
