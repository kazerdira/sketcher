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
    print(
        '🎨 PAINT: Starting paint with ${strokes.length} strokes, currentStroke: ${currentStroke != null}');

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
    print('🎨 PAINT: Finished painting');
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
    paint
      ..style = PaintingStyle.stroke
      ..blendMode =
          BlendMode.srcOver; // avoid multiply artifacts over bright colors

    final baseColor = paint.color;

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

      // Add subtle texture lines using low alpha; avoid colored specks on bright colors
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

        final isBright = baseColor.computeLuminance() > 0.7;
        final textureAlpha = (baseColor.opacity * 0.18).clamp(0.05, 0.2);
        final texturePaint = Paint()
          ..color = isBright
              ? Colors.black.withOpacity(0.12)
              : baseColor.withOpacity(textureAlpha)
          ..strokeCap = paint.strokeCap
          ..strokeJoin = paint.strokeJoin
          ..blendMode = BlendMode.srcOver
          ..isAntiAlias = true
          ..filterQuality = FilterQuality.high
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(0.5, avgWidth * 0.25);

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
    final path =
        _createCatmullRomPath(stroke.points, closed: false, alpha: 0.5);
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

    // Draw main stroke with smooth path
    final path =
        _createCatmullRomPath(stroke.points, closed: false, alpha: 0.5);
    canvas.drawPath(path, paint);

    // Add soft glow effect
    paint
      ..strokeWidth = stroke.width * 1.5
      ..color = stroke.color.withOpacity(stroke.opacity * 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);

    canvas.drawPath(path, paint);
  }

  void _drawEraserStroke(Canvas canvas, Stroke stroke, Paint paint) {
    // Feathered dstOut eraser: removes stroke alpha softly without hard squares
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true
      ..strokeWidth = stroke.width
      ..blendMode = BlendMode.dstOut
      ..color = Colors.black.withOpacity(0.95);

    final feather = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true
      ..strokeWidth = stroke.width * 1.5
      ..blendMode = BlendMode.dstOut
      ..color = Colors.black.withOpacity(0.35);

    if (stroke.points.length == 1) {
      canvas.drawCircle(
        stroke.points.first.offset,
        (stroke.width * 1.5) / 2,
        feather..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        stroke.points.first.offset,
        stroke.width / 2,
        base..style = PaintingStyle.fill,
      );
      return;
    }

    final path =
        _createCatmullRomPath(stroke.points, closed: false, alpha: 0.5);
    canvas.drawPath(path, feather);
    canvas.drawPath(path, base);
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

    // Create varying width path with smooth interpolation
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

  // Catmull–Rom to Bezier conversion for smoother curves
  Path _createCatmullRomPath(List<DrawingPoint> points,
      {bool closed = false, double alpha = 0.5}) {
    final path = Path();
    if (points.length < 2) {
      if (points.isNotEmpty) {
        path.addOval(Rect.fromCircle(center: points.first.offset, radius: 0.5));
      }
      return path;
    }

    final pts = points.map((p) => p.offset).toList(growable: true);
    if (closed) {
      pts.insert(0, pts[pts.length - 2]);
      pts.addAll([pts[1], pts[2]]);
    } else {
      pts.insert(0, pts.first);
      pts.add(pts.last);
    }

    path.moveTo(pts[1].dx, pts[1].dy);

    double tj(Offset pi, Offset pj) {
      final dx = pj.dx - pi.dx;
      final dy = pj.dy - pi.dy;
      final dist = math.sqrt(dx * dx + dy * dy);
      return math.pow(dist, alpha).toDouble();
    }

    for (int i = 1; i < pts.length - 2; i++) {
      final p0 = pts[i - 1];
      final p1 = pts[i];
      final p2 = pts[i + 1];
      final p3 = pts[i + 2];

      final t01 = tj(p0, p1);
      final t12 = tj(p1, p2);
      final t23 = tj(p2, p3);

      double m1x = 0.0, m1y = 0.0, m2x = 0.0, m2y = 0.0;
      if (t12 > 0) {
        m1x = (p2.dx - p0.dx) / (t01 + t12);
        m1y = (p2.dy - p0.dy) / (t01 + t12);
        m2x = (p3.dx - p1.dx) / (t12 + t23);
        m2y = (p3.dy - p1.dy) / (t12 + t23);
      }

      final cp1 = Offset(
        p1.dx + m1x * t12 / 3.0,
        p1.dy + m1y * t12 / 3.0,
      );
      final cp2 = Offset(
        p2.dx - m2x * t12 / 3.0,
        p2.dy - m2y * t12 / 3.0,
      );

      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p2.dx, p2.dy);
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
    if (oldDelegate is! SketchPainter) {
      print('🎨 REPAINT: Different painter type - repaint TRUE');
      return true;
    }

    final old = oldDelegate;

    // Repaint when stroke count changes (especially for undo)
    if (old.strokes.length != strokes.length) {
      print(
          '🎨 REPAINT: Stroke count changed ${old.strokes.length} -> ${strokes.length} - repaint TRUE');
      return true;
    }

    // Check if strokes list reference changed (after refresh)
    if (!identical(old.strokes, strokes)) {
      print('🎨 REPAINT: Strokes list reference changed - repaint TRUE');
      return true;
    }

    // Repaint when stroke contents change (even if list identity is the same)
    for (int i = 0; i < strokes.length; i++) {
      if (!identical(old.strokes[i], strokes[i])) {
        print('🎨 REPAINT: Stroke $i changed - repaint TRUE');
        return true;
      }
    }

    // Repaint when current stroke changes (for live drawing)
    if (!identical(old.currentStroke, currentStroke)) {
      print('🎨 REPAINT: Current stroke changed - repaint TRUE');
      return true;
    }

    // Repaint when background properties change
    if (old.backgroundImage != backgroundImage) {
      print('🎨 REPAINT: Background image changed - repaint TRUE');
      return true;
    }
    if (old.imageOpacity != imageOpacity) {
      print('🎨 REPAINT: Image opacity changed - repaint TRUE');
      return true;
    }
    if (old.isImageVisible != isImageVisible) {
      print('🎨 REPAINT: Image visibility changed - repaint TRUE');
      return true;
    }

    print('🎨 REPAINT: No changes detected - repaint FALSE');
    return false;
  }
}
