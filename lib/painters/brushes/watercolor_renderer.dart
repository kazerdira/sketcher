import 'package:flutter/material.dart';

import '../../models/stroke.dart';

class WatercolorRenderer {
  static void draw(
    Canvas canvas,
    List<DrawingPoint> points,
    Stroke stroke,
    Color baseColor,
    Path Function(List<DrawingPoint> points, {bool closed, double alpha})
        createCatmullRomPath,
  ) {
    if (stroke.points.length == 1) {
      final p = points.first;
      final w = (stroke.width * p.pressure).clamp(0.5, 200.0);
      final spotPaint = Paint()
        ..color = baseColor.withValues(alpha: stroke.opacity * 0.25)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
      canvas.drawCircle(p.offset, w * 0.6, spotPaint);
      return;
    }

    final path = createCatmullRomPath(stroke.points, closed: false, alpha: 0.5);

    // Simplified watercolor with reduced layers (3 -> 2)
    final layers = [
      {"widthFactor": 1.2, "alpha": 0.22, "blur": 2.5},
      {"widthFactor": 0.9, "alpha": 0.35, "blur": 1.0},
    ];
    for (final layer in layers) {
      final layerPaint = Paint()
        ..color = baseColor.withValues(
            alpha: stroke.opacity * (layer["alpha"] as double))
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true
        ..maskFilter =
            MaskFilter.blur(BlurStyle.normal, layer["blur"] as double)
        ..strokeWidth = stroke.width * (layer["widthFactor"] as double);
      canvas.drawPath(path, layerPaint);
    }

    // subtle bleed at the end point
    final end = stroke.points.last.offset;
    final bleedPaint = Paint()
      ..color = baseColor.withValues(alpha: stroke.opacity * 0.12)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
    canvas.drawCircle(end, stroke.width * 0.6, bleedPaint);
  }
}
