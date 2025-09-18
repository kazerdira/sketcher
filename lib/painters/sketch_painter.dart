import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/stroke.dart';
import '../models/brush_type.dart';

/// Professional painter that renders strokes with realistic brush effects
/// Inspired by industry-standard digital painting applications
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
      _drawAdvancedStroke(canvas, stroke);
    }
  }

  void _drawAdvancedStroke(Canvas canvas, Stroke stroke) {
    if (stroke.points.isEmpty) return;

    // Handle single point strokes
    if (stroke.points.length == 1) {
      _drawSinglePoint(canvas, stroke);
      return;
    }

    // Choose rendering technique based on brush type
    switch (stroke.brushType) {
      case BrushType.pencil:
        _drawPencilStroke(canvas, stroke);
        break;
      case BrushType.pen:
        _drawPenStroke(canvas, stroke);
        break;
      case BrushType.marker:
        _drawMarkerStroke(canvas, stroke);
        break;
      case BrushType.brush:
        _drawArtistBrushStroke(canvas, stroke);
        break;
      case BrushType.highlighter:
        _drawHighlighterStroke(canvas, stroke);
        break;
      case BrushType.eraser:
        _drawEraserStroke(canvas, stroke);
        break;
      case BrushType.airbrush:
        _drawAirbrushStroke(canvas, stroke);
        break;
      case BrushType.charcoal:
        _drawCharcoalStroke(canvas, stroke);
        break;
      case BrushType.watercolor:
        _drawWatercolorStroke(canvas, stroke);
        break;
      case BrushType.oil:
        _drawOilPaintStroke(canvas, stroke);
        break;
    }
  }

  void _drawSinglePoint(Canvas canvas, Stroke stroke) {
    final paint = _createBasePaint(stroke);
    paint.style = PaintingStyle.fill;
    canvas.drawCircle(stroke.points.first, stroke.width / 2, paint);
  }

  Paint _createBasePaint(Stroke stroke) {
    final brushType = stroke.brushType;
    return Paint()
      ..color = brushType.isEraser
          ? Colors.white
          : stroke.color.withValues(alpha: brushType.baseOpacity)
      ..style = PaintingStyle.stroke
      ..strokeCap = brushType.strokeCap
      ..strokeJoin = brushType.strokeJoin
      ..blendMode = brushType.blendMode
      ..isAntiAlias = true;
  }

  // PENCIL: Graphite-like texture with pressure sensitivity
  void _drawPencilStroke(Canvas canvas, Stroke stroke) {
    final random = math.Random(stroke.points.length);

    for (int i = 0; i < stroke.points.length - 1; i++) {
      final start = stroke.points[i];
      final end = stroke.points[i + 1];

      // Simulate pencil grain texture
      final jitter = stroke.brushType.jitterAmount;
      final startJittered = Offset(
        start.dx + (random.nextDouble() - 0.5) * jitter,
        start.dy + (random.nextDouble() - 0.5) * jitter,
      );
      final endJittered = Offset(
        end.dx + (random.nextDouble() - 0.5) * jitter,
        end.dy + (random.nextDouble() - 0.5) * jitter,
      );

      // Variable opacity for graphite buildup
      final pressure = _getPressureAt(stroke, i);
      final opacity =
          stroke.brushType.baseOpacity *
          stroke.brushType.buildUpFactor *
          pressure;

      final paint = Paint()
        ..color = stroke.color.withValues(alpha: opacity)
        ..strokeWidth =
            stroke.width * pressure * (0.8 + random.nextDouble() * 0.4)
        ..strokeCap = StrokeCap.round
        ..blendMode = BlendMode.multiply
        ..isAntiAlias = true;

      canvas.drawLine(startJittered, endJittered, paint);

      // Add extra texture strokes for realism
      if (random.nextDouble() < 0.3) {
        final texturePaint = Paint()
          ..color = stroke.color.withValues(alpha: opacity * 0.3)
          ..strokeWidth = 0.5
          ..strokeCap = StrokeCap.round
          ..blendMode = BlendMode.multiply;

        canvas.drawLine(
          Offset(
            startJittered.dx + random.nextDouble() - 0.5,
            startJittered.dy + random.nextDouble() - 0.5,
          ),
          Offset(
            endJittered.dx + random.nextDouble() - 0.5,
            endJittered.dy + random.nextDouble() - 0.5,
          ),
          texturePaint,
        );
      }
    }
  }

  // PEN: Consistent ink flow, smooth lines
  void _drawPenStroke(Canvas canvas, Stroke stroke) {
    final paint = _createBasePaint(stroke)
      ..strokeWidth = stroke.width
      ..color = stroke.color.withValues(alpha: 1.0); // Opaque ink

    final path = _createSmoothPath(stroke.points);
    canvas.drawPath(path, paint);
  }

  // MARKER: Semi-transparent with saturated colors and edge blending
  void _drawMarkerStroke(Canvas canvas, Stroke stroke) {
    final paint = _createBasePaint(stroke)
      ..strokeWidth = stroke.width
      ..color = stroke.color.withValues(alpha: 0.7)
      ..blendMode = BlendMode.multiply;

    final path = _createDirectPath(stroke.points);
    canvas.drawPath(path, paint);

    // Add edge softening for felt tip effect
    final edgePaint = Paint()
      ..color = stroke.color.withValues(alpha: 0.15)
      ..strokeWidth = stroke.width + 3
      ..strokeCap = StrokeCap.square
      ..blendMode = BlendMode.multiply
      ..isAntiAlias = true;

    canvas.drawPath(path, edgePaint);
  }

  // ARTIST BRUSH: Natural bristle effects with pressure variation
  void _drawArtistBrushStroke(Canvas canvas, Stroke stroke) {
    final random = math.Random(stroke.points.length);

    for (int i = 0; i < stroke.points.length - 1; i++) {
      final start = stroke.points[i];
      final end = stroke.points[i + 1];
      final pressure = _getPressureAt(stroke, i);

      // Main brush stroke
      final mainPaint = Paint()
        ..color = stroke.color.withValues(
          alpha: stroke.brushType.baseOpacity * pressure,
        )
        ..strokeWidth = stroke.width * pressure
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true;

      canvas.drawLine(start, end, mainPaint);

      // Bristle separation effects
      final scatterAmount = stroke.brushType.scatterAmount;
      final bristleCount = math.max(1, (stroke.width / 8).round());

      for (int j = 0; j < bristleCount; j++) {
        if (random.nextDouble() < 0.7) {
          final bristleOffset = scatterAmount * (random.nextDouble() - 0.5);
          final bristleStart = Offset(
            start.dx + bristleOffset * math.cos(j * 2 * math.pi / bristleCount),
            start.dy + bristleOffset * math.sin(j * 2 * math.pi / bristleCount),
          );
          final bristleEnd = Offset(
            end.dx + bristleOffset * math.cos(j * 2 * math.pi / bristleCount),
            end.dy + bristleOffset * math.sin(j * 2 * math.pi / bristleCount),
          );

          final bristlePaint = Paint()
            ..color = stroke.color.withValues(
              alpha: stroke.brushType.baseOpacity * 0.3,
            )
            ..strokeWidth = 1.0
            ..strokeCap = StrokeCap.round
            ..isAntiAlias = true;

          canvas.drawLine(bristleStart, bristleEnd, bristlePaint);
        }
      }
    }
  }

  // HIGHLIGHTER: Wide, transparent, fluorescent effect
  void _drawHighlighterStroke(Canvas canvas, Stroke stroke) {
    final paint = _createBasePaint(stroke)
      ..strokeWidth = stroke.width
      ..color = stroke.color.withValues(alpha: 0.3)
      ..blendMode = BlendMode.screen;

    final path = _createDirectPath(stroke.points);
    canvas.drawPath(path, paint);

    // Add bright core for fluorescent effect
    final corePaint = Paint()
      ..color = stroke.color.withValues(alpha: 0.5)
      ..strokeWidth = stroke.width * 0.3
      ..strokeCap = StrokeCap.square
      ..blendMode = BlendMode.screen
      ..isAntiAlias = true;

    canvas.drawPath(path, corePaint);
  }

  // ERASER: Complete removal with clear blend mode
  void _drawEraserStroke(Canvas canvas, Stroke stroke) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = stroke.width
      ..strokeCap = StrokeCap.round
      ..blendMode = BlendMode.clear
      ..isAntiAlias = true;

    final path = _createSmoothPath(stroke.points);
    canvas.drawPath(path, paint);
  }

  // AIRBRUSH: Spray pattern with gradual buildup
  void _drawAirbrushStroke(Canvas canvas, Stroke stroke) {
    final random = math.Random(stroke.points.length);

    for (int i = 0; i < stroke.points.length; i++) {
      final point = stroke.points[i];
      final pressure = _getPressureAt(stroke, i);
      final sprayRadius = stroke.width * 0.5;
      final density = (pressure * 200).round();

      // Create spray pattern
      for (int j = 0; j < density; j++) {
        final angle = random.nextDouble() * 2 * math.pi;
        final distance = random.nextDouble() * sprayRadius;
        final sprayPoint = Offset(
          point.dx + distance * math.cos(angle),
          point.dy + distance * math.sin(angle),
        );

        final sprayPaint = Paint()
          ..color = stroke.color.withValues(alpha: 0.02 * pressure)
          ..style = PaintingStyle.fill
          ..isAntiAlias = true;

        canvas.drawCircle(sprayPoint, 0.5, sprayPaint);
      }
    }
  }

  // CHARCOAL: Dusty, organic texture with powder effects
  void _drawCharcoalStroke(Canvas canvas, Stroke stroke) {
    final random = math.Random(stroke.points.length);

    for (int i = 0; i < stroke.points.length - 1; i++) {
      final start = stroke.points[i];
      final end = stroke.points[i + 1];
      final pressure = _getPressureAt(stroke, i);

      // Main charcoal stroke
      final mainPaint = Paint()
        ..color = stroke.color.withValues(
          alpha: stroke.brushType.baseOpacity * pressure,
        )
        ..strokeWidth = stroke.width * pressure
        ..strokeCap = StrokeCap.square
        ..blendMode = BlendMode.multiply
        ..isAntiAlias = true;

      canvas.drawLine(start, end, mainPaint);

      // Charcoal dust effect
      final dustCount = (stroke.width * pressure * 0.5).round();
      for (int j = 0; j < dustCount; j++) {
        final dustPoint = Offset(
          start.dx +
              end.dx / 2 +
              (random.nextDouble() - 0.5) * stroke.width * 2,
          start.dy +
              end.dy / 2 +
              (random.nextDouble() - 0.5) * stroke.width * 2,
        );

        final dustPaint = Paint()
          ..color = stroke.color.withValues(alpha: 0.1 * pressure)
          ..style = PaintingStyle.fill
          ..isAntiAlias = true;

        canvas.drawCircle(dustPoint, random.nextDouble() * 2, dustPaint);
      }
    }
  }

  // WATERCOLOR: Flowing, transparent with wet-on-wet effects
  void _drawWatercolorStroke(Canvas canvas, Stroke stroke) {
    final random = math.Random(stroke.points.length);

    // Base watercolor wash
    final washPaint = Paint()
      ..color = stroke.color.withValues(alpha: 0.2)
      ..strokeWidth = stroke.width * 1.5
      ..strokeCap = StrokeCap.round
      ..blendMode = BlendMode.multiply
      ..isAntiAlias = true;

    final path = _createSmoothPath(stroke.points);
    canvas.drawPath(path, washPaint);

    // Pigment concentration areas
    for (int i = 0; i < stroke.points.length - 1; i++) {
      if (random.nextDouble() < 0.3) {
        final point = stroke.points[i];
        final pressure = _getPressureAt(stroke, i);

        final pigmentPaint = Paint()
          ..color = stroke.color.withValues(alpha: 0.4 * pressure)
          ..style = PaintingStyle.fill
          ..blendMode = BlendMode.multiply
          ..isAntiAlias = true;

        canvas.drawCircle(point, stroke.width * 0.3, pigmentPaint);
      }
    }

    // Water edge bleeding
    final edgePaint = Paint()
      ..color = stroke.color.withValues(alpha: 0.05)
      ..strokeWidth = stroke.width * 2.5
      ..strokeCap = StrokeCap.round
      ..blendMode = BlendMode.multiply
      ..isAntiAlias = true;

    canvas.drawPath(path, edgePaint);
  }

  // OIL PAINT: Thick, textured with impasto effects
  void _drawOilPaintStroke(Canvas canvas, Stroke stroke) {
    final random = math.Random(stroke.points.length);

    for (int i = 0; i < stroke.points.length - 1; i++) {
      final start = stroke.points[i];
      final end = stroke.points[i + 1];
      final pressure = _getPressureAt(stroke, i);

      // Main oil paint stroke
      final mainPaint = Paint()
        ..color = stroke.color.withValues(alpha: stroke.brushType.baseOpacity)
        ..strokeWidth = stroke.width * pressure
        ..strokeCap = StrokeCap.square
        ..isAntiAlias = true;

      canvas.drawLine(start, end, mainPaint);

      // Impasto texture effects
      if (pressure > 0.7) {
        final textureCount = (stroke.width * 0.2).round();
        for (int j = 0; j < textureCount; j++) {
          final texturePoint = Offset(
            start.dx +
                (end.dx - start.dx) * random.nextDouble() +
                (random.nextDouble() - 0.5) * stroke.width * 0.5,
            start.dy +
                (end.dy - start.dy) * random.nextDouble() +
                (random.nextDouble() - 0.5) * stroke.width * 0.5,
          );

          final texturePaint = Paint()
            ..color = stroke.color.withValues(alpha: 0.8)
            ..style = PaintingStyle.fill
            ..isAntiAlias = true;

          canvas.drawCircle(
            texturePoint,
            random.nextDouble() * 2 + 1,
            texturePaint,
          );
        }
      }
    }
  }

  // Helper methods
  Path _createSmoothPath(List<Offset> points) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);

    for (int i = 1; i < points.length; i++) {
      final pt = points[i];
      if (i < points.length - 1) {
        final next = points[i + 1];
        final control = Offset((pt.dx + next.dx) / 2, (pt.dy + next.dy) / 2);
        path.quadraticBezierTo(pt.dx, pt.dy, control.dx, control.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }

    return path;
  }

  Path _createDirectPath(List<Offset> points) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);

    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    return path;
  }

  double _getPressureAt(Stroke stroke, int index) {
    if (stroke.pressures.isEmpty || index >= stroke.pressures.length) {
      return 1.0;
    }
    return stroke.pressures[index].clamp(0.1, 1.0);
  }

  @override
  bool shouldRepaint(covariant SketchPainter oldDelegate) =>
      oldDelegate.strokes != strokes ||
      oldDelegate.currentStroke != currentStroke;
}
