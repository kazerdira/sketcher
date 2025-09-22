import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../../models/stroke.dart';

class CalligraphyRenderer {
  static void draw(
    Canvas canvas,
    List<DrawingPoint> points,
    Stroke stroke,
    Color baseColor,
  ) {
    final nibAngleDeg = stroke.calligraphyNibAngleDeg ?? 40.0;
    final nibAngle = nibAngleDeg * math.pi / 180.0;
    final nibDir = Offset(math.cos(nibAngle), math.sin(nibAngle));

    for (int i = 0; i < points.length - 1; i++) {
      final a = points[i];
      final b = points[i + 1];
      final seg = b.offset - a.offset;
      final len = seg.distance;
      if (len <= 0.0001) continue;
      final t = seg / len; // unit tangent
      // Thickness follows |sin(theta)| between stroke and nib direction
      final cross = (t.dx * nibDir.dy - t.dy * nibDir.dx).abs();
      final pressure = (a.pressure + b.pressure) * 0.5;
      final widthFactor =
          (stroke.calligraphyNibWidthFactor ?? 1.0).clamp(0.3, 2.5);
      final thickness = math.max(
        0.6,
        stroke.width * widthFactor * (0.35 + 0.9 * cross) * pressure,
      );
      final core = Paint()
        ..color = baseColor.withValues(alpha: stroke.opacity)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.butt
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true
        ..strokeWidth = thickness;
      canvas.drawLine(a.offset, b.offset, core);
      // Soft edge pass to slightly feather the ribbon
      final edge = Paint()
        ..color = baseColor.withValues(alpha: stroke.opacity * 0.25)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.butt
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.6)
        ..strokeWidth = thickness * 1.1;
      canvas.drawLine(a.offset, b.offset, edge);
    }
  }
}
