import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../../models/stroke.dart';

class PastelRenderer {
  static void draw(
    Canvas canvas,
    List<DrawingPoint> points,
    Stroke stroke,
    Color baseColor,
  ) {
    final rnd = math.Random(2718);
    for (final p in points) {
      final w = (stroke.width * p.pressure).clamp(0.5, 220.0);
      // Base smudge
      final base = Paint()
        ..color = baseColor.withValues(alpha: stroke.opacity * 0.35)
        ..style = PaintingStyle.fill
        ..isAntiAlias = true
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.8);
      canvas.drawCircle(p.offset, w * 0.55, base);

      // Chalk body
      final body = Paint()
        ..color = baseColor.withValues(alpha: stroke.opacity * 0.55)
        ..style = PaintingStyle.fill
        ..isAntiAlias = true;
      canvas.drawCircle(p.offset, w * 0.42, body);

      // Grain speckles around
      final grainDensity = (stroke.pastelGrainDensity ?? 1.0).clamp(0.3, 3.0);
      final grains = (w * 0.8 * grainDensity).round().clamp(4, 50);
      for (int i = 0; i < grains; i++) {
        final ang = rnd.nextDouble() * 2 * math.pi;
        final dist = rnd.nextDouble() * w * 0.6;
        final gSize = 0.6 + rnd.nextDouble() * 1.4;
        final gOff = Offset(math.cos(ang) * dist, math.sin(ang) * dist);
        final alpha = stroke.opacity * (0.06 + rnd.nextDouble() * 0.24);
        final speck = Paint()
          ..color = baseColor.withValues(alpha: alpha)
          ..style = PaintingStyle.fill
          ..isAntiAlias = true;
        canvas.drawCircle(p.offset + gOff, gSize, speck);
      }
    }
  }
}
