import 'package:flutter/material.dart';
import '../models/stroke.dart';

/// Painter that renders existing strokes and the in-progress stroke.
class SketchPainter extends CustomPainter {
  SketchPainter({required this.strokes, required this.currentStroke});
  final List<Stroke> strokes;
  final Stroke? currentStroke;

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in [
      ...strokes,
      if (currentStroke != null) currentStroke!,
    ]) {
      _drawStroke(canvas, stroke);
    }
  }

  void _drawStroke(Canvas canvas, Stroke stroke) {
    if (stroke.points.isEmpty) return;
    if (stroke.points.length == 1) {
      canvas.drawCircle(
        stroke.points.first,
        stroke.width / 2,
        Paint()
          ..color = stroke.color
          ..style = PaintingStyle.fill
          ..isAntiAlias = true,
      );
      return;
    }
    final path = Path()..moveTo(stroke.points.first.dx, stroke.points.first.dy);
    for (int i = 1; i < stroke.points.length; i++) {
      final pt = stroke.points[i];
      if (i < stroke.points.length - 1) {
        final next = stroke.points[i + 1];
        final control = Offset((pt.dx + next.dx) / 2, (pt.dy + next.dy) / 2);
        path.quadraticBezierTo(pt.dx, pt.dy, control.dx, control.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
    final paint = Paint()
      ..color = stroke.color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = stroke.width
      ..isAntiAlias = true;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant SketchPainter oldDelegate) =>
      oldDelegate.strokes != strokes ||
      oldDelegate.currentStroke != currentStroke;
}
