import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fletch/theme/app_colors.dart';

class CodeEditorPainter extends CustomPainter {
  final int totalLines;
  final int currentLine;
  final double scrollOffset;
  final double fontSize;
  final double lineHeightMultiplier;
  final bool isDark;
  final String text;

  CodeEditorPainter({
    required this.totalLines,
    required this.currentLine,
    required this.scrollOffset,
    required this.fontSize,
    required this.lineHeightMultiplier,
    required this.isDark,
    required this.text,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double lineHeight = fontSize * lineHeightMultiplier;

    // Draw gutter background (matching BodyEditor)
    final gutterPaint = Paint()
      ..color = AppColors.slate800.withValues(alpha: 0.5);
    canvas.drawRect(
      Rect.fromLTWH(0.0, 0.0, 40.0, size.height),
      gutterPaint,
    );

    // 1. Draw current line highlight background
    final activePaint = Paint()
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.05)
          : Colors.black.withValues(alpha: 0.03);

    final double activeTop = currentLine * lineHeight - scrollOffset + 17.5;
    if (activeTop + lineHeight >= 0 && activeTop <= size.height) {
      canvas.drawRect(
        Rect.fromLTWH(40.0, activeTop, size.width - 40.0, lineHeight),
        activePaint,
      );
    }

    // Calculate character width of JetBrains Mono at this fontSize
    final charPainter = TextPainter(
      text: TextSpan(text: ' ', style: GoogleFonts.jetBrainsMono(fontSize: fontSize)),
      textDirection: TextDirection.ltr,
    )..layout();
    final double charWidth = charPainter.width;

    // Draw vertical guide lines in the editor
    final textLines = text.split('\n');
    int lastCollectionLine = -1;
    int lastRequestLine = -1;
    double lastIndent = 0.0;

    for (int i = 0; i < textLines.length; i++) {
      final line = textLines[i];
      final trimmed = line.trimLeft();
      if (trimmed.startsWith('+')) {
        if (lastCollectionLine != -1 && lastRequestLine > lastCollectionLine) {
          _drawEditorGuideLine(canvas, lastCollectionLine, lastRequestLine, lastIndent, charWidth, lineHeight, size.height);
        }
        lastCollectionLine = i;
        lastRequestLine = -1;
        lastIndent = 0.0;
      } else if (trimmed.startsWith('-') && lastCollectionLine != -1) {
        lastRequestLine = i;
        // Count leading spaces to find the indentation column
        final leadingSpaces = line.length - trimmed.length;
        lastIndent = leadingSpaces.toDouble();
      }
    }
    if (lastCollectionLine != -1 && lastRequestLine > lastCollectionLine) {
      _drawEditorGuideLine(canvas, lastCollectionLine, lastRequestLine, lastIndent, charWidth, lineHeight, size.height);
    }

    // 3. Draw line numbers
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    for (int i = 0; i < totalLines; i++) {
      final double top = i * lineHeight - scrollOffset + 17.5;
      if (top + lineHeight < 0 || top > size.height) continue;

      final isActive = i == currentLine;
      textPainter.text = TextSpan(
        text: '${i + 1}',
        style: GoogleFonts.jetBrainsMono(
          fontSize: 13, // Match text font size
          height: lineHeightMultiplier,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          color: isActive
              ? AppColors.primary
              : (isDark ? AppColors.slate500 : AppColors.slate400),
        ),
      );
      textPainter.layout();

      final double x = (40.0 - textPainter.width) / 2; // Center horizontally in the gutter
      final double y = top; // Align vertically with code text

      textPainter.paint(canvas, Offset(x, y));
    }
  }

  void _drawEditorGuideLine(Canvas canvas, int startLine, int endLine, double indent, double charWidth, double lineHeight, double viewHeight) {
    final double col = indent > 0 ? (indent - 0.5) : 0.5;
    final double x = 40.0 + 12.0 + charWidth * col;
    final double startY = (startLine + 1) * lineHeight - scrollOffset + 21.0;
    final double endY = endLine * lineHeight - scrollOffset + 21.0 + (lineHeight / 2.0);

    if (endY < 0 || startY > viewHeight) return;

    final guidePaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.4) // Brighter and clearer primary color for guide line
      ..strokeWidth = 1.0;

    canvas.drawLine(
      Offset(x, startY),
      Offset(x, endY),
      guidePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CodeEditorPainter oldDelegate) {
    return oldDelegate.totalLines != totalLines ||
        oldDelegate.currentLine != currentLine ||
        oldDelegate.scrollOffset != scrollOffset ||
        oldDelegate.text != text ||
        oldDelegate.isDark != isDark;
  }
}
