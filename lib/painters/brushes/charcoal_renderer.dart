import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../../models/stroke.dart';

class CharcoalRenderer {
  static void draw(
    Canvas canvas,
    List<DrawingPoint> points,
    Stroke stroke,
    Color baseColor,
  ) {
    final dabPaint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    for (final p in points) {
      final w = (stroke.width * p.pressure).clamp(0.5, 200.0);
      dabPaint.color = baseColor.withValues(alpha: stroke.opacity * 0.7);
      canvas.drawCircle(p.offset, w * 0.5, dabPaint);

      // Optimized grain: reduced particle count
      final rnd = math.Random(
        p.offset.dx.toInt() * 73856093 ^ p.offset.dy.toInt() * 19349663,
      );
      final grains = (w / 4).round().clamp(3, 8);
      for (int i = 0; i < grains; i++) {
        final ang = rnd.nextDouble() * 2 * math.pi;
        final dist = rnd.nextDouble() * w * 0.5;
        final gSize = rnd.nextDouble() * 1.3 + 0.4;
        final gOff = Offset(math.cos(ang) * dist, math.sin(ang) * dist);
        final gColor = baseColor.withValues(
          alpha: stroke.opacity * (0.12 + rnd.nextDouble() * 0.25),
        );
        canvas.drawCircle(p.offset + gOff, gSize, dabPaint..color = gColor);
      }
    }
  }
}
