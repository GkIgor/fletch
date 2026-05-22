import 'package:flutter/material.dart';
import 'package:gk_http_client/providers/workspace_provider.dart';
import 'package:provider/provider.dart';

class InterpolatedTextController extends TextEditingController {
  final Set<String>? availableVariables;
  final Set<String> Function()? getAvailableVariables;

  InterpolatedTextController({
    super.text,
    this.availableVariables,
    this.getAvailableVariables,
  });

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final baseStyle = style ?? const TextStyle();
    final children = <InlineSpan>[];

    // Regular expression to find all occurrences of {{var}}
    final regex = RegExp(r'\{\{([^}]+)\}\}');

    int start = 0;
    final matches = regex.allMatches(text);

    // Retrieve active environment variables
    Set<String> activeVars = {};
    if (availableVariables != null) {
      activeVars = availableVariables!;
    } else if (getAvailableVariables != null) {
      activeVars = getAvailableVariables!();
    } else {
      try {
        final wsProvider = Provider.of<WorkspaceProvider>(context, listen: false);
        final activeEnv = wsProvider.activeEnvironment;
        if (activeEnv != null) {
          activeVars = activeEnv.variables.keys.toSet();
        }
      } catch (_) {
        // Fallback for tests or contexts without WorkspaceProvider
      }
    }

    final yellowColor = const Color(0xFFF59E0B); // Amber / Yellow for valid variables
    final redColor = const Color(0xFFEF4444);    // Red for invalid / non-existent variables

    for (final match in matches) {
      // Text before the match
      if (match.start > start) {
        children.add(TextSpan(
          text: text.substring(start, match.start),
          style: baseStyle,
        ));
      }

      final fullMatchText = match.group(0)!;
      final varName = match.group(1)?.trim() ?? '';

      final exists = activeVars.contains(varName);

      // Render as plain text with syntax highlight color
      children.add(TextSpan(
        text: fullMatchText,
        style: baseStyle.copyWith(
          color: exists ? yellowColor : redColor,
          fontWeight: FontWeight.bold,
        ),
      ));

      start = match.end;
    }

    // Text after the last match
    if (start < text.length) {
      children.add(TextSpan(
        text: text.substring(start),
        style: baseStyle,
      ));
    }

    return TextSpan(children: children, style: baseStyle);
  }
}
