import 'package:flutter/material.dart';
import 'package:highlight/highlight.dart' show highlight, Node;

class CodeHighlightController extends TextEditingController {
  String language;
  bool isDark;

  CodeHighlightController({
    super.text,
    required this.language,
    required this.isDark,
  });

  // Estilos de destaque para o modo escuro (Slate 900 background)
  static final Map<String, TextStyle> _darkTheme = {
    'attr': const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.w600), // Light blue for JSON keys / attributes
    'string': const TextStyle(color: Color(0xFF34D399)), // Green for strings
    'number': const TextStyle(color: Color(0xFFFB923C)), // Orange for numbers
    'keyword': const TextStyle(color: Color(0xFFC084FC), fontWeight: FontWeight.bold), // Violet for true/false/null
    'literal': const TextStyle(color: Color(0xFFC084FC), fontWeight: FontWeight.bold),
    'tag': const TextStyle(color: Color(0xFFF472B6)), // Pink for XML tags e.g. <tag>
    'name': const TextStyle(color: Color(0xFFF472B6), fontWeight: FontWeight.w600), // Pink for XML tag names
    'comment': const TextStyle(color: Color(0xFF64748B), fontStyle: FontStyle.italic), // Gray for comments
    'meta': const TextStyle(color: Color(0xFF94A3B8)), // Gray for metadata headers
  };

  // Estilos de destaque para o modo claro (Light background)
  static final Map<String, TextStyle> _lightTheme = {
    'attr': const TextStyle(color: Color(0xFF0284C7), fontWeight: FontWeight.w600), // Darker blue
    'string': const TextStyle(color: Color(0xFF16A34A)), // Darker green
    'number': const TextStyle(color: Color(0xFFD97706)), // Darker amber
    'keyword': const TextStyle(color: Color(0xFF7C3AED), fontWeight: FontWeight.bold), // Purple
    'literal': const TextStyle(color: Color(0xFF7C3AED), fontWeight: FontWeight.bold),
    'tag': const TextStyle(color: Color(0xFFDB2777)), // Darker pink
    'name': const TextStyle(color: Color(0xFFDB2777), fontWeight: FontWeight.w600),
    'comment': const TextStyle(color: Color(0xFF94A3B8), fontStyle: FontStyle.italic),
    'meta': const TextStyle(color: Color(0xFF64748B)),
  };

  Map<String, TextStyle> get _theme => isDark ? _darkTheme : _lightTheme;

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final baseStyle = style ?? const TextStyle();

    // Se o idioma não for suportado ou for 'none', retorna o estilo padrão
    if (language.toLowerCase() == 'none' || language.isEmpty) {
      return TextSpan(text: text, style: baseStyle);
    }

    try {
      final parsed = highlight.parse(text, language: language.toLowerCase());
      final nodes = parsed.nodes;

      if (nodes == null || nodes.isEmpty) {
        return TextSpan(text: text, style: baseStyle);
      }

      final children = <TextSpan>[];
      for (final node in nodes) {
        children.add(_buildSpan(node, baseStyle));
      }

      return TextSpan(children: children, style: baseStyle);
    } catch (e) {
      // Fallback em caso de erro de parsing
      return TextSpan(text: text, style: baseStyle);
    }
  }

  TextSpan _buildSpan(Node node, TextStyle baseStyle) {
    TextStyle nodeStyle = baseStyle;

    if (node.className != null) {
      final styleFromTheme = _theme[node.className];
      if (styleFromTheme != null) {
        nodeStyle = baseStyle.merge(styleFromTheme);
      }
    }

    if (node.value != null) {
      return TextSpan(text: node.value, style: nodeStyle);
    }

    if (node.children != null && node.children!.isNotEmpty) {
      final childrenSpans = <TextSpan>[];
      for (final child in node.children!) {
        childrenSpans.add(_buildSpan(child, nodeStyle));
      }
      return TextSpan(children: childrenSpans, style: nodeStyle);
    }

    return const TextSpan();
  }
}
