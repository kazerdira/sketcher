import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/stroke.dart';

class ProfessionalSketchPainter extends CustomPainter {
  final List<Stroke> strokes;
  final ui.Image? backgroundImage;
  final double imageOpacity;
  final bool showImage;
  final Offset panOffset;
  final double scale;
  final ui.Image? paperTexture;
  final ui.Image? brushTextures;

  ProfessionalSketchPainter({
    required this.strokes,
    this.backgroundImage,
    this.imageOpacity = 0.5,
    this.showImage = true,
    this.panOffset = Offset.zero,
    this.scale = 1.0,
    this.paperTexture,
    this.brushTextures,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();

    // Apply transformations
    canvas.translate(panOffset.dx, panOffset.dy);
    canvas.scale(scale);

    // Draw paper texture background
    _drawPaperTexture(canvas, size);

    // Draw background image if present
    if (showImage && backgroundImage != null) {
      _drawBackgroundImage(canvas, size);
    }

    // Draw all strokes with proper blending
    _drawStrokes(canvas, size);

    canvas.restore();
  }

  void _drawPaperTexture(Canvas canvas, Size size) {
    if (paperTexture == null) {
      // Create a subtle paper texture effect
      final paint = Paint()
        ..color = const Color(0xFFFFFEF8)
        ..style = PaintingStyle.fill;
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

      // Add subtle noise pattern
      final noisePaint = Paint()
        ..color = const Color(0xFFF8F8F8)
        ..style = PaintingStyle.fill;

      final random = math.Random(42); // Fixed seed for consistent texture
      for (int i = 0; i < 1000; i++) {
        final x = random.nextDouble() * size.width;
        final y = random.nextDouble() * size.height;
        final opacity = random.nextDouble() * 0.1;
        noisePaint.color = Color.fromRGBO(240, 240, 240, opacity);
        canvas.drawCircle(Offset(x, y), 0.5, noisePaint);
      }
    } else {
      // Use actual paper texture
      canvas.drawImageRect(
        paperTexture!,
        Rect.fromLTWH(
          0,
          0,
          paperTexture!.width.toDouble(),
          paperTexture!.height.toDouble(),
        ),
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint(),
      );
    }
  }

  void _drawBackgroundImage(Canvas canvas, Size size) {
    if (backgroundImage == null) return;

    final paint = Paint()..color = Color.fromRGBO(255, 255, 255, imageOpacity);

    // Calculate aspect ratio and positioning
    final imageAspect = backgroundImage!.width / backgroundImage!.height;
    final canvasAspect = size.width / size.height;

    Rect destRect;
    if (imageAspect > canvasAspect) {
      // Image is wider - fit to height
      final scaledWidth = size.height * imageAspect;
      final offsetX = (size.width - scaledWidth) / 2;
      destRect = Rect.fromLTWH(offsetX, 0, scaledWidth, size.height);
    } else {
      // Image is taller - fit to width
      final scaledHeight = size.width / imageAspect;
      final offsetY = (size.height - scaledHeight) / 2;
      destRect = Rect.fromLTWH(0, offsetY, size.width, scaledHeight);
    }

    canvas.drawImageRect(
      backgroundImage!,
      Rect.fromLTWH(
        0,
        0,
        backgroundImage!.width.toDouble(),
        backgroundImage!.height.toDouble(),
      ),
      destRect,
      paint,
    );
  }

  void _drawStrokes(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      _drawStroke(canvas, stroke);
    }
  }

  void _drawStroke(Canvas canvas, Stroke stroke) {
    if (stroke.points.length < 2) return;

    switch (stroke.brushSettings.type) {
      case BrushType.pencil:
        _drawPencilStroke(canvas, stroke);
        break;
      case BrushType.pen:
        _drawPenStroke(canvas, stroke);
        break;
      case BrushType.marker:
        _drawMarkerStroke(canvas, stroke);
        break;
      case BrushType.eraser:
        _drawEraserStroke(canvas, stroke);
        break;
      case BrushType.highlighter:
        _drawHighlighterStroke(canvas, stroke);
        break;
      case BrushType.charcoal:
        _drawCharcoalStroke(canvas, stroke);
        break;
      case BrushType.watercolor:
        _drawWatercolorStroke(canvas, stroke);
        break;
    }
  }

  void _drawPencilStroke(Canvas canvas, Stroke stroke) {
    final path = Path();
    final points = stroke.getSmoothedPoints();

    if (points.isEmpty) return;

    path.moveTo(points.first.position.dx, points.first.position.dy);

    // Create multiple layers for realistic pencil effect
    final layers = 3;
    final baseOpacity = stroke.brushSettings.opacity;

    for (int layer = 0; layer < layers; layer++) {
      final layerPath = Path();
      layerPath.moveTo(points.first.position.dx, points.first.position.dy);

      for (int i = 1; i < points.length; i++) {
        final point = points[i];
        final prevPoint = points[i - 1];

        // Add slight randomness for texture
        final random = math.Random(i + layer * 1000);
        final offsetX = (random.nextDouble() - 0.5) * 0.5 * (layer + 1);
        final offsetY = (random.nextDouble() - 0.5) * 0.5 * (layer + 1);

        final adjustedPoint = Offset(
          point.position.dx + offsetX,
          point.position.dy + offsetY,
        );

        // Quadratic bezier curve for smoothness
        final controlPoint = Offset(
          (prevPoint.position.dx + adjustedPoint.dx) / 2,
          (prevPoint.position.dy + adjustedPoint.dy) / 2,
        );

        layerPath.quadraticBezierTo(
          prevPoint.position.dx,
          prevPoint.position.dy,
          controlPoint.dx,
          controlPoint.dy,
        );
      }

      // Calculate dynamic stroke width based on pressure and velocity
      final paint = Paint()
        ..color = stroke.brushSettings.color.withOpacity(
          baseOpacity * (1.0 - layer * 0.2) * 0.6,
        )
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = stroke.brushSettings.size * (1.0 - layer * 0.15);

      // Add texture effect
      if (stroke.brushSettings.textureIntensity > 0) {
        paint.maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          stroke.brushSettings.textureIntensity * 0.5,
        );
      }

      canvas.drawPath(layerPath, paint);
    }
  }

  void _drawPenStroke(Canvas canvas, Stroke stroke) {
    final path = Path();
    final points = stroke.points; // No smoothing for pen - keep it precise

    if (points.isEmpty) return;

    path.moveTo(points.first.position.dx, points.first.position.dy);

    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].position.dx, points[i].position.dy);
    }

    final paint = Paint()
      ..color = stroke.brushSettings.color.withOpacity(
        stroke.brushSettings.opacity,
      )
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = stroke.brushSettings.size;

    canvas.drawPath(path, paint);
  }

  void _drawMarkerStroke(Canvas canvas, Stroke stroke) {
    final points = stroke.getSmoothedPoints();
    if (points.isEmpty) return;

    // Markers have a distinctive flat, wide appearance
    for (int i = 1; i < points.length; i++) {
      final point = points[i];
      final prevPoint = points[i - 1];

      // Calculate pressure-sensitive width
      final pressure = stroke.brushSettings.pressureSensitive
          ? point.pressure
          : 1.0;
      final width = stroke.brushSettings.size * pressure;

      // Create marker shape (flattened circle)
      final paint = Paint()
        ..color = stroke.brushSettings.color.withOpacity(
          stroke.brushSettings.opacity * 0.7,
        )
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.square
        ..strokeWidth = width;

      // Add streaky effect typical of markers
      canvas.drawLine(prevPoint.position, point.position, paint);

      // Add translucent overlay for blending effect
      final overlayPaint = Paint()
        ..color = stroke.brushSettings.color.withOpacity(
          stroke.brushSettings.opacity * 0.3,
        )
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = width * 1.2;

      canvas.drawLine(prevPoint.position, point.position, overlayPaint);
    }
  }

  void _drawEraserStroke(Canvas canvas, Stroke stroke) {
    final points = stroke.getSmoothedPoints();
    if (points.isEmpty) return;

    // Eraser effect - we'll use blend mode to "subtract" from existing content
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = stroke.brushSettings.size
      ..blendMode = ui.BlendMode.clear;

    final path = Path();
    path.moveTo(points.first.position.dx, points.first.position.dy);

    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].position.dx, points[i].position.dy);
    }

    canvas.drawPath(path, paint);
  }

  void _drawHighlighterStroke(Canvas canvas, Stroke stroke) {
    final points = stroke.getSmoothedPoints();
    if (points.isEmpty) return;

    final path = Path();
    path.moveTo(points.first.position.dx, points.first.position.dy);

    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].position.dx, points[i].position.dy);
    }

    // Highlighter has a distinctive flat, transparent appearance
    final paint = Paint()
      ..color = stroke.brushSettings.color.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square
      ..strokeWidth = stroke.brushSettings.size * 2
      ..blendMode = ui.BlendMode.multiply;

    canvas.drawPath(path, paint);
  }

  void _drawCharcoalStroke(Canvas canvas, Stroke stroke) {
    final points = stroke.getSmoothedPoints();
    if (points.isEmpty) return;

    // Charcoal has a very organic, textured appearance
    final random = math.Random(42);

    for (int i = 1; i < points.length; i++) {
      final point = points[i];
      final prevPoint = points[i - 1];

      // Create multiple scattered strokes for texture
      for (int j = 0; j < 5; j++) {
        final offsetX =
            (random.nextDouble() - 0.5) * stroke.brushSettings.size * 0.3;
        final offsetY =
            (random.nextDouble() - 0.5) * stroke.brushSettings.size * 0.3;

        final startOffset = Offset(
          prevPoint.position.dx + offsetX,
          prevPoint.position.dy + offsetY,
        );
        final endOffset = Offset(
          point.position.dx + offsetX,
          point.position.dy + offsetY,
        );

        final paint = Paint()
          ..color = stroke.brushSettings.color.withOpacity(
            stroke.brushSettings.opacity * (0.3 + random.nextDouble() * 0.4),
          )
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth =
              stroke.brushSettings.size * (0.1 + random.nextDouble() * 0.3);

        canvas.drawLine(startOffset, endOffset, paint);
      }
    }
  }

  void _drawWatercolorStroke(Canvas canvas, Stroke stroke) {
    final points = stroke.getSmoothedPoints();
    if (points.isEmpty) return;

    // Watercolor effect with bleeding and transparency
    final path = Path();
    path.moveTo(points.first.position.dx, points.first.position.dy);

    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].position.dx, points[i].position.dy);
    }

    // Main stroke
    final mainPaint = Paint()
      ..color = stroke.brushSettings.color.withOpacity(
        stroke.brushSettings.opacity * 0.6,
      )
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke.brushSettings.size;

    canvas.drawPath(path, mainPaint);

    // Add bleeding effect
    final bleedPaint = Paint()
      ..color = stroke.brushSettings.color.withOpacity(
        stroke.brushSettings.opacity * 0.2,
      )
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke.brushSettings.size * 2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);

    canvas.drawPath(path, bleedPaint);
  }

  @override
  bool shouldRepaint(ProfessionalSketchPainter oldDelegate) {
    return oldDelegate.strokes != strokes ||
        oldDelegate.backgroundImage != backgroundImage ||
        oldDelegate.imageOpacity != imageOpacity ||
        oldDelegate.showImage != showImage ||
        oldDelegate.panOffset != panOffset ||
        oldDelegate.scale != scale;
  }
}
