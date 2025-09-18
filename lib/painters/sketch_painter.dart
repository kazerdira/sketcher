import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;
import '../models/stroke.dart';
import '../models/drawing_tool.dart';

class SketchPainter extends CustomPainter {
  final List<Stroke> strokes;
  final Stroke? currentStroke;
  final ImageProvider? backgroundImage;
  final double imageOpacity;
  final bool isImageVisible;
  final ui.Image? backgroundImageData;

  SketchPainter({
    required this.strokes,
    this.currentStroke,
    this.backgroundImage,
    this.imageOpacity = 0.5,
    this.isImageVisible = true,
    this.backgroundImageData,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw background image if available
    if (isImageVisible && backgroundImageData != null) {
      _drawBackgroundImage(canvas, size);
    }

    // Set up canvas for drawing strokes
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());

    // Draw all completed strokes
    for (final stroke in strokes) {
      _drawStroke(canvas, stroke);
    }

    // Draw current stroke being drawn
    if (currentStroke != null) {
      _drawStroke(canvas, currentStroke!);
    }

    canvas.restore();
  }

  void _drawBackgroundImage(Canvas canvas, Size size) {
    if (backgroundImageData == null) return;

    final paint = Paint()
      ..color = Colors.white.withOpacity(imageOpacity)
      ..filterQuality = FilterQuality.high;

    final imageSize = Size(
      backgroundImageData!.width.toDouble(),
      backgroundImageData!.height.toDouble(),
    );

    // Calculate scaling to fit the canvas
    final scale = math.min(
      size.width / imageSize.width,
      size.height / imageSize.height,
    );

    final scaledSize = Size(
      imageSize.width * scale,
      imageSize.height * scale,
    );

    final offset = Offset(
      (size.width - scaledSize.width) / 2,
      (size.height - scaledSize.height) / 2,
    );

    final srcRect = Rect.fromLTWH(0, 0, imageSize.width, imageSize.height);
    final dstRect = Rect.fromLTWH(
      offset.dx,
      offset.dy,
      scaledSize.width,
      scaledSize.height,
    );

    canvas.drawImageRect(backgroundImageData!, srcRect, dstRect, paint);
  }

  void _drawStroke(Canvas canvas, Stroke stroke) {
    if (stroke.points.isEmpty) return;

    final paint = Paint()
      ..color = stroke.color.withOpacity(stroke.opacity)
      ..strokeCap = _getStrokeCap(stroke.tool)
      ..strokeJoin = StrokeJoin.round
      ..blendMode = stroke.blendMode
      ..isAntiAlias = true
      ..filterQuality = FilterQuality.high;

    switch (stroke.tool) {
      case DrawingTool.pencil:
        _drawPencilStroke(canvas, stroke, paint);
        break;
      case DrawingTool.pen:
        _drawPenStroke(canvas, stroke, paint);
        break;
      case DrawingTool.marker:
        _drawMarkerStroke(canvas, stroke, paint);
        break;
      case DrawingTool.eraser:
        _drawEraserStroke(canvas, stroke, paint);
        break;
      case DrawingTool.brush:
        _drawBrushStroke(canvas, stroke, paint);
        break;
    }
  }

  void _drawPencilStroke(Canvas canvas, Stroke stroke, Paint paint) {
    // Pencil: textured, pressure-sensitive, slightly transparent
    paint.style = PaintingStyle.stroke;

    final baseColor = paint.color; // preserve original color

    if (stroke.points.length == 1) {
      // Single point - draw a small circle
      canvas.drawCircle(
        stroke.points.first.offset,
        stroke.width / 2,
        paint..style = PaintingStyle.fill,
      );
      return;
    }

    // Create path with varying width based on pressure
    for (int i = 0; i < stroke.points.length - 1; i++) {
      final point1 = stroke.points[i];
      final point2 = stroke.points[i + 1];

      final width1 = stroke.width * point1.pressure;
      final width2 = stroke.width * point2.pressure;
      final avgWidth = (width1 + width2) / 2;

      // Draw main stroke segment with base color
      paint
        ..color = baseColor
        ..strokeWidth = avgWidth;
      canvas.drawLine(point1.offset, point2.offset, paint);

      // Add texture by drawing multiple thin lines with slight offset
      final random = math.Random(i);
      for (int j = 0; j < 2; j++) {
        final offset1 = Offset(
          point1.offset.dx + random.nextDouble() * 0.5 - 0.25,
          point1.offset.dy + random.nextDouble() * 0.5 - 0.25,
        );
        final offset2 = Offset(
          point2.offset.dx + random.nextDouble() * 0.5 - 0.25,
          point2.offset.dy + random.nextDouble() * 0.5 - 0.25,
        );

        final texturePaint = Paint()
          ..color = baseColor.withOpacity(baseColor.opacity * 0.3)
          ..strokeCap = paint.strokeCap
          ..strokeJoin = paint.strokeJoin
          ..blendMode = paint.blendMode
          ..isAntiAlias = true
          ..filterQuality = FilterQuality.high
          ..style = PaintingStyle.stroke
          ..strokeWidth = avgWidth * 0.3;

        canvas.drawLine(offset1, offset2, texturePaint);
      }
    }
  }

  void _drawPenStroke(Canvas canvas, Stroke stroke, Paint paint) {
    // Pen: clean, consistent width, sharp edges
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = stroke.width;

    if (stroke.points.length == 1) {
      canvas.drawCircle(
        stroke.points.first.offset,
        stroke.width / 2,
        paint..style = PaintingStyle.fill,
      );
      return;
    }

    final path = Path();
    path.moveTo(stroke.points.first.offset.dx, stroke.points.first.offset.dy);

    for (int i = 1; i < stroke.points.length; i++) {
      path.lineTo(stroke.points[i].offset.dx, stroke.points[i].offset.dy);
    }

    canvas.drawPath(path, paint);
  }

  void _drawMarkerStroke(Canvas canvas, Stroke stroke, Paint paint) {
    // Marker: wide, semi-transparent, soft edges
    if (stroke.points.isEmpty) return;

    // Create gradient effect for marker
    final rect = _getBoundingRect(stroke.points);
    final gradient = RadialGradient(
      colors: [
        stroke.color.withOpacity(stroke.opacity * 0.8),
        stroke.color.withOpacity(stroke.opacity * 0.4),
      ],
      stops: const [0.0, 1.0],
    );

    paint.shader = gradient.createShader(rect);
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = stroke.width;

    if (stroke.points.length == 1) {
      canvas.drawCircle(
        stroke.points.first.offset,
        stroke.width / 2,
        paint..style = PaintingStyle.fill,
      );
      return;
    }

    // Draw main stroke
    final path = _createSmoothPath(stroke.points);
    canvas.drawPath(path, paint);

    // Add soft glow effect
    paint
      ..strokeWidth = stroke.width * 1.5
      ..color = stroke.color.withOpacity(stroke.opacity * 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);

    canvas.drawPath(path, paint);
  }

  void _drawEraserStroke(Canvas canvas, Stroke stroke, Paint paint) {
    // Eraser: removes content, soft edges
    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke.width
      ..blendMode = BlendMode.clear;

    if (stroke.points.length == 1) {
      canvas.drawCircle(
        stroke.points.first.offset,
        stroke.width / 2,
        paint..style = PaintingStyle.fill,
      );
      return;
    }

    final path = _createSmoothPath(stroke.points);
    canvas.drawPath(path, paint);

    // Add soft edge effect
    paint
      ..strokeWidth = stroke.width * 0.8
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.0);

    canvas.drawPath(path, paint);
  }

  void _drawBrushStroke(Canvas canvas, Stroke stroke, Paint paint) {
    // Brush: artistic, pressure-sensitive, textured
    paint.style = PaintingStyle.stroke;

    if (stroke.points.length == 1) {
      final width = stroke.width * stroke.points.first.pressure;
      canvas.drawCircle(
        stroke.points.first.offset,
        width / 2,
        paint
          ..style = PaintingStyle.fill
          ..strokeWidth = 0,
      );
      return;
    }

    // Create varying width path
    for (int i = 0; i < stroke.points.length - 1; i++) {
      final point1 = stroke.points[i];
      final point2 = stroke.points[i + 1];

      final width1 = stroke.width * point1.pressure;
      final width2 = stroke.width * point2.pressure;

      // Create brush bristle effect
      final bristleCount = (stroke.width / 3).round().clamp(3, 10);
      for (int bristle = 0; bristle < bristleCount; bristle++) {
        final offset = (bristle - bristleCount / 2) * 0.5;

        final perpendicular = _getPerpendicular(point1.offset, point2.offset);
        final bristleOffset = perpendicular * offset;

        final bristleStart = point1.offset + bristleOffset;
        final bristleEnd = point2.offset + bristleOffset;

        final bristleWidth =
            ((width1 + width2) / 2) * (0.7 + 0.3 * (bristle % 2));

        canvas.drawLine(
          bristleStart,
          bristleEnd,
          paint
            ..strokeWidth = bristleWidth / bristleCount
            ..color = paint.color.withOpacity(
              paint.color.opacity * (0.8 + 0.2 * math.sin(bristle.toDouble())),
            ),
        );
      }
    }
  }

  Offset _getPerpendicular(Offset start, Offset end) {
    final direction = end - start;
    final perpendicular = Offset(-direction.dy, direction.dx);
    final length = perpendicular.distance;
    if (length == 0) return Offset.zero;
    return perpendicular / length;
  }

  StrokeCap _getStrokeCap(DrawingTool tool) {
    switch (tool) {
      case DrawingTool.pencil:
      case DrawingTool.pen:
        return StrokeCap.round;
      case DrawingTool.marker:
      case DrawingTool.brush:
        return StrokeCap.round;
      case DrawingTool.eraser:
        return StrokeCap.round;
    }
  }

  Path _createSmoothPath(List<DrawingPoint> points) {
    final path = Path();
    if (points.isEmpty) return path;

    path.moveTo(points.first.offset.dx, points.first.offset.dy);

    for (int i = 1; i < points.length; i++) {
      final point1 = points[i - 1];
      final point2 = points[i];

      // Use quadratic bezier for smooth curves
      final controlPoint = Offset(
        (point1.offset.dx + point2.offset.dx) / 2,
        (point1.offset.dy + point2.offset.dy) / 2,
      );

      path.quadraticBezierTo(
        point1.offset.dx,
        point1.offset.dy,
        controlPoint.dx,
        controlPoint.dy,
      );
    }

    return path;
  }

  Rect _getBoundingRect(List<DrawingPoint> points) {
    if (points.isEmpty) return Rect.zero;

    double minX = points.first.offset.dx;
    double maxX = points.first.offset.dx;
    double minY = points.first.offset.dy;
    double maxY = points.first.offset.dy;

    for (final point in points) {
      minX = math.min(minX, point.offset.dx);
      maxX = math.max(maxX, point.offset.dx);
      minY = math.min(minY, point.offset.dy);
      maxY = math.max(maxY, point.offset.dy);
    }

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is! SketchPainter) return true;

    final old = oldDelegate;

    if (identical(old.strokes, strokes) &&
        identical(old.currentStroke, currentStroke) &&
        old.backgroundImage == backgroundImage &&
        old.imageOpacity == imageOpacity &&
        old.isImageVisible == isImageVisible) {
      return false;
    }

    if (old.strokes.length != strokes.length) return true;
    for (int i = 0; i < strokes.length; i++) {
      if (!identical(old.strokes[i], strokes[i])) return true;
    }

    if (!identical(old.currentStroke, currentStroke)) return true;
    if (old.backgroundImage != backgroundImage) return true;
    if (old.imageOpacity != imageOpacity) return true;
    if (old.isImageVisible != isImageVisible) return true;

    return false;
  }
}
