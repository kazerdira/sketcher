import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../../models/stroke.dart';

class OilPaintRenderer {
  static void draw(
    Canvas canvas,
    List<DrawingPoint> points,
    Stroke stroke,
    Color baseColor,
    Path Function(List<DrawingPoint> points, {bool closed, double alpha})
        createCatmullRomPath,
    Offset Function(Offset start, Offset end) getPerpendicular,
  ) {
    final path = createCatmullRomPath(stroke.points, closed: false, alpha: 0.5);

    // Underpaint: slightly darker, wider, soft
    final under = Paint()
      ..color =
          baseColor.withValues(alpha: (stroke.opacity * 0.22).clamp(0.0, 1.0))
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5)
      ..strokeWidth = stroke.width * 1.35;
    canvas.drawPath(path, under);

    // Body paint: main opaque body with slight texture variation
    final body = Paint()
      ..color = baseColor.withValues(alpha: stroke.opacity.clamp(0.0, 1.0))
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = stroke.width;
    canvas.drawPath(path, body);

    // Ridge highlight
    final highlight = Paint()
      ..color = Colors.white.withValues(alpha: (stroke.opacity * 0.18))
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = math.max(1.0, stroke.width * 0.35)
      ..blendMode = BlendMode.screen;

    final hlPath = Path();
    if (points.isNotEmpty) {
      hlPath.moveTo(points.first.offset.dx, points.first.offset.dy);
      for (int i = 0; i < points.length - 1; i++) {
        final a = points[i].offset;
        final b = points[i + 1].offset;
        final perp = getPerpendicular(a, b);
        final offsetAmt = math.max(0.6, stroke.width * 0.15);
        final a2 = a + perp * offsetAmt;
        final b2 = b + perp * offsetAmt;
        hlPath.lineTo(b2.dx, b2.dy);
        if (i == 0) {
          hlPath.moveTo(a2.dx, a2.dy);
        }
      }
    }
    canvas.drawPath(hlPath, highlight);

    // Occasional thick daubs
    final rnd = math.Random(1337);
    for (int i = 0; i < points.length; i += 6) {
      final p = points[i];
      final w = (stroke.width * p.pressure).clamp(0.8, 200.0);
      final daub = Paint()
        ..color = baseColor.withValues(alpha: (stroke.opacity * 0.35))
        ..style = PaintingStyle.fill;
      final rx = w * (0.45 + rnd.nextDouble() * 0.25);
      final ry = w * (0.25 + rnd.nextDouble() * 0.2);
      final ang = rnd.nextDouble() * math.pi;
      canvas.save();
      canvas.translate(p.offset.dx, p.offset.dy);
      canvas.rotate(ang);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: rx, height: ry),
        daub,
      );
      canvas.restore();
    }
  }
}
