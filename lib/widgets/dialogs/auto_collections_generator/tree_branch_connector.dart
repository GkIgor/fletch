import 'package:flutter/material.dart';

class TreeBranchConnector extends StatelessWidget {
  final bool isLast;
  final bool isDark;

  const TreeBranchConnector({
    super.key,
    required this.isLast,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(16, 20),
      painter: _BranchPainter(isLast: isLast, isDark: isDark),
    );
  }
}

class _BranchPainter extends CustomPainter {
  final bool isLast;
  final bool isDark;

  _BranchPainter({required this.isLast, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.15)
          : Colors.black.withValues(alpha: 0.1)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final double halfX = size.width / 2;
    final double halfY = size.height / 2;

    // Draw vertical line
    if (isLast) {
      canvas.drawLine(Offset(halfX, 0), Offset(halfX, halfY), paint);
    } else {
      canvas.drawLine(Offset(halfX, 0), Offset(halfX, size.height), paint);
    }

    // Draw horizontal line to the right
    canvas.drawLine(Offset(halfX, halfY), Offset(size.width, halfY), paint);
  }

  @override
  bool shouldRepaint(covariant _BranchPainter oldDelegate) {
    return oldDelegate.isLast != isLast || oldDelegate.isDark != isDark;
  }
}
