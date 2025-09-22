import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../../models/stroke.dart';

class AirbrushRenderer {
  static void draw(
    Canvas canvas,
    List<DrawingPoint> points,
    Stroke stroke,
    Color baseColor,
  ) {
    // Airbrush: soft spray particles with a faint core
    final rnd = math.Random(9029);

    // Draw a faint core to guide stroke shape
    for (int i = 0; i < points.length - 1; i++) {
      final a = points[i];
      final b = points[i + 1];
      final corePaint = Paint()
        ..color = baseColor.withValues(alpha: stroke.opacity * 0.15)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.5)
        ..strokeWidth =
            math.max(0.5, (a.pressure + b.pressure) * 0.5 * stroke.width * 0.4);
      canvas.drawLine(a.offset, b.offset, corePaint);
    }

    // Spray particles around each segment
    for (int i = 0; i < points.length - 1; i++) {
      final a = points[i];
      final b = points[i + 1];
      final seg = b.offset - a.offset;
      final len = seg.distance;
      if (len <= 0) continue;
      // Particle budget scales with stroke length and size
      final baseCount = (len * 0.6 + stroke.width * 1.5).clamp(6, 80).toInt();
      for (int k = 0; k < baseCount; k++) {
        final t = rnd.nextDouble();
        final p = Offset.lerp(a.offset, b.offset, t)!;
        // Radius depends on stroke width and pressure
        final pr = a.pressure * (1 - t) + b.pressure * t;
        final radius = (stroke.width * (0.15 + rnd.nextDouble() * 0.35) * pr)
            .clamp(0.4, 6.0);
        // Scatter perpendicular with Gaussian-ish distribution
        final perp = _getPerpendicular(a.offset, b.offset);
        final spread = stroke.width * (0.6 + rnd.nextDouble() * 0.8);
        final jitter = (rnd.nextDouble() - 0.5) + (rnd.nextDouble() - 0.5);
        final offset = perp * (jitter * spread);
        final drop = Paint()
          ..color = baseColor.withValues(
              alpha: stroke.opacity * (0.05 + rnd.nextDouble() * 0.22))
          ..style = PaintingStyle.fill
          ..isAntiAlias = true
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.8);
        canvas.drawCircle(p + offset, radius, drop);
      }
    }
  }

  static Offset _getPerpendicular(Offset start, Offset end) {
    final direction = end - start;
    final perpendicular = Offset(-direction.dy, direction.dx);
    final length = perpendicular.distance;
    if (length == 0) return Offset.zero;
    return perpendicular / length;
  }
}
