import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/visual_script.dart';
import '../../theme/app_colors.dart';
import 'flowchart_layout_manager.dart';

class FlowchartPainter extends CustomPainter {
  final VisualScript script;
  final Map<String, Offset> positions;
  final double nodeWidth;
  final bool isDark;

  FlowchartPainter({
    required this.script,
    required this.positions,
    required this.nodeWidth,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paintNormal = Paint()
      ..color = isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final paintBackEdge = Paint()
      ..color = Colors.orange.shade700
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    script.nodes.forEach((id, node) {
      final src = positions[id];
      if (src == null) return;

      if (node is IfStep) {
        _drawConnection(canvas, id, node.trueStepId, src, getOutputYOffset(node, 'true'), paintNormal, paintBackEdge, label: 'true');
        _drawConnection(canvas, id, node.falseStepId, src, getOutputYOffset(node, 'false'), paintNormal, paintBackEdge, label: 'false');
      } else if (node is SwitchStep) {
        for (int i = 0; i < node.cases.length; i++) {
          final c = node.cases[i];
          _drawConnection(canvas, id, c.nextStepId, src, getOutputYOffset(node, 'switch_case', switchCaseVal: c.value), paintNormal, paintBackEdge, label: c.value);
        }
        _drawConnection(canvas, id, node.defaultStepId, src, getOutputYOffset(node, 'switch_default'), paintNormal, paintBackEdge, label: 'Default');
      } else if (node is SplitOutStep) {
        _drawConnection(canvas, id, node.loopStepId, src, getOutputYOffset(node, 'loop'), paintNormal, paintBackEdge, label: 'Loop');
        _drawConnection(canvas, id, node.nextStepId, src, getOutputYOffset(node, 'next'), paintNormal, paintBackEdge, label: 'Next');
      } else {
        _drawConnection(canvas, id, node.nextStepId, src, getOutputYOffset(node, 'next'), paintNormal, paintBackEdge);
      }
    });
  }

  void _drawConnection(
    Canvas canvas,
    String srcId,
    String? destId,
    Offset src,
    double outputYOffset,
    Paint paintNormal,
    Paint paintBackEdge, {
    String? label,
  }) {
    if (destId == null || destId.isEmpty) return;
    final dest = positions[destId];
    if (dest == null) return;

    final destNode = script.nodes[destId];
    final destHeight = destNode != null ? getNodeHeight(destNode) : 70.0;

    final startPoint = Offset(src.dx + nodeWidth, src.dy + outputYOffset);
    final endPoint = Offset(dest.dx, dest.dy + destHeight / 2);

    final isBackEdge = dest.dx <= src.dx;

    if (isBackEdge) {
      final path = Path()..moveTo(startPoint.dx, startPoint.dy);
      final controlPoint1 = Offset(startPoint.dx + 40, startPoint.dy + (dest.dy > src.dy ? 40 : -40));
      final controlPoint2 = Offset(endPoint.dx - 40, endPoint.dy + (dest.dy > src.dy ? 40 : -40));
      
      path.cubicTo(controlPoint1.dx, controlPoint1.dy, controlPoint2.dx, controlPoint2.dy, endPoint.dx, endPoint.dy);
      
      _drawDottedPath(canvas, path, paintBackEdge);
      _drawArrowHead(canvas, controlPoint2, endPoint, paintBackEdge.color);
    } else {
      final path = Path()..moveTo(startPoint.dx, startPoint.dy);
      final controlX = startPoint.dx + (endPoint.dx - startPoint.dx) * 0.5;
      path.cubicTo(controlX, startPoint.dy, controlX, endPoint.dy, endPoint.dx, endPoint.dy);
      canvas.drawPath(path, paintNormal);
      _drawArrowHead(canvas, Offset(controlX, endPoint.dy), endPoint, paintNormal.color);
    }

    if (label != null && label.isNotEmpty) {
      final labelOffset = Offset(startPoint.dx + 12, startPoint.dy - 10);
      final textPainter = TextPainter(
        text: TextSpan(
          text: label.length > 8 ? '${label.substring(0, 6)}..' : label,
          style: TextStyle(fontSize: 8, color: isBackEdge ? Colors.orange.shade700 : (isDark ? AppColors.slate400 : AppColors.slate600)),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, labelOffset);
    }
  }

  void _drawDottedPath(Canvas canvas, Path path, Paint paint) {
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double distance = 0.0;
      const double dashLength = 4.0;
      const double spaceLength = 4.0;
      while (distance < metric.length) {
        final segment = metric.extractPath(distance, distance + dashLength);
        canvas.drawPath(segment, paint);
        distance += dashLength + spaceLength;
      }
    }
  }

  void _drawArrowHead(Canvas canvas, Offset from, Offset to, Color color) {
    final double angle = atan2(to.dy - from.dy, to.dx - from.dx);
    const double arrowSize = 6.0;

    final path = Path()
      ..moveTo(to.dx, to.dy)
      ..lineTo(to.dx - arrowSize * cos(angle - pi / 6), to.dy - arrowSize * sin(angle - pi / 6))
      ..lineTo(to.dx - arrowSize * cos(angle + pi / 6), to.dy - arrowSize * sin(angle + pi / 6))
      ..close();

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant FlowchartPainter oldDelegate) {
    return oldDelegate.script != script || oldDelegate.positions != positions || oldDelegate.isDark != isDark;
  }
}
