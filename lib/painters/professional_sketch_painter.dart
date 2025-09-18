import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;
import '../models/drawing_tool.dart';
import '../models/enhanced_stroke.dart';

class ProfessionalSketchPainter extends CustomPainter {
  final List<EnhancedStroke> strokes;
  final EnhancedStroke? currentStroke;
  final ui.Image? backgroundImage;
  final double imageOpacity;
  final bool showImage;
  final Size canvasSize;

  ProfessionalSketchPainter({
    required this.strokes,
    this.currentStroke,
    this.backgroundImage,
    this.imageOpacity = 0.5,
    this.showImage = true,
    required this.canvasSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Setup canvas
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // Draw background image if available
    if (showImage && backgroundImage != null) {
      _drawBackgroundImage(canvas, size);
    }

    // Draw all completed strokes
    for (final stroke in strokes) {
      _drawStroke(canvas, stroke, size);
    }

    // Draw current stroke if available
    if (currentStroke != null && currentStroke!.points.isNotEmpty) {
      _drawStroke(canvas, currentStroke!, size);
    }
  }

  void _drawBackgroundImage(Canvas canvas, Size size) {
    if (backgroundImage == null) return;

    final paint = Paint()
      ..filterQuality = FilterQuality.high
      ..color = Colors.white.withOpacity(imageOpacity);

    final imageSize = Size(
      backgroundImage!.width.toDouble(),
      backgroundImage!.height.toDouble(),
    );
    final canvasRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final imageRect = _calculateImageRect(imageSize, canvasRect);

    canvas.drawImageRect(
      backgroundImage!,
      Rect.fromLTWH(0, 0, imageSize.width, imageSize.height),
      imageRect,
      paint,
    );
  }

  Rect _calculateImageRect(Size imageSize, Rect canvasRect) {
    final imageAspect = imageSize.width / imageSize.height;
    final canvasAspect = canvasRect.width / canvasRect.height;

    if (imageAspect > canvasAspect) {
      // Image is wider than canvas
      final height = canvasRect.width / imageAspect;
      final y = (canvasRect.height - height) / 2;
      return Rect.fromLTWH(0, y, canvasRect.width, height);
    } else {
      // Image is taller than canvas
      final width = canvasRect.height * imageAspect;
      final x = (canvasRect.width - width) / 2;
      return Rect.fromLTWH(x, 0, width, canvasRect.height);
    }
  }

  void _drawStroke(Canvas canvas, EnhancedStroke stroke, Size size) {
    if (stroke.points.isEmpty) return;

    switch (stroke.toolSettings.tool) {
      case DrawingTool.pencil:
        _drawPencilStroke(canvas, stroke);
        break;
      case DrawingTool.pen:
        _drawPenStroke(canvas, stroke);
        break;
      case DrawingTool.marker:
        _drawMarkerStroke(canvas, stroke);
        break;
      case DrawingTool.eraser:
        _drawEraserStroke(canvas, stroke);
        break;
      case DrawingTool.brush:
        _drawBrushStroke(canvas, stroke);
        break;
    }
  }

  void _drawPencilStroke(Canvas canvas, EnhancedStroke stroke) {
    if (stroke.points.length < 2) return;

    final paint = Paint()
      ..color = stroke.toolSettings.color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = stroke.toolSettings.antiAlias;

    // Create textured pencil effect
    for (int i = 0; i < stroke.points.length - 1; i++) {
      final point = stroke.points[i];
      final nextPoint = stroke.points[i + 1];

      // Calculate pressure-based size and opacity
      final pressureFactor =
          stroke.toolSettings.pressureSensitive ? point.pressure : 1.0;
      final velocityFactor = math.max(0.3, 1.0 - (point.velocity / 1000.0));

      final dynamicSize =
          stroke.toolSettings.size * pressureFactor * velocityFactor;
      final dynamicOpacity =
          (stroke.toolSettings.opacity * pressureFactor).clamp(0.1, 1.0);

      paint.strokeWidth = dynamicSize;
      paint.color = stroke.toolSettings.color.withOpacity(dynamicOpacity);

      // Add texture by drawing multiple thin lines with slight offsets
      final random = math.Random(i);
      final numTextureLayers = (dynamicSize / 2).ceil().clamp(1, 4);

      for (int layer = 0; layer < numTextureLayers; layer++) {
        final offset = (random.nextDouble() - 0.5) * dynamicSize * 0.1;
        final layerOpacity =
            (dynamicOpacity / numTextureLayers).clamp(0.05, 1.0);

        final layerPaint = Paint()
          ..color = stroke.toolSettings.color.withOpacity(layerOpacity)
          ..strokeWidth = dynamicSize / numTextureLayers
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;

        final startOffset = Offset(
          point.position.dx + offset,
          point.position.dy + offset,
        );
        final endOffset = Offset(
          nextPoint.position.dx + offset,
          nextPoint.position.dy + offset,
        );

        canvas.drawLine(startOffset, endOffset, layerPaint);
      }
    }
  }

  void _drawPenStroke(Canvas canvas, EnhancedStroke stroke) {
    if (stroke.points.length < 2) return;

    final path = Path();
    path.moveTo(stroke.points[0].position.dx, stroke.points[0].position.dy);

    // Create smooth path using quadratic bezier curves
    for (int i = 1; i < stroke.points.length - 1; i++) {
      final current = stroke.points[i].position;
      final next = stroke.points[i + 1].position;
      final controlPoint = Offset(
        (current.dx + next.dx) / 2,
        (current.dy + next.dy) / 2,
      );
      path.quadraticBezierTo(
        current.dx,
        current.dy,
        controlPoint.dx,
        controlPoint.dy,
      );
    }

    if (stroke.points.length > 1) {
      final lastPoint = stroke.points.last.position;
      path.lineTo(lastPoint.dx, lastPoint.dy);
    }

    final paint = Paint()
      ..color = stroke.toolSettings.color.withOpacity(
        stroke.toolSettings.opacity,
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke.toolSettings.size
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = stroke.toolSettings.antiAlias;

    canvas.drawPath(path, paint);
  }

  void _drawMarkerStroke(Canvas canvas, EnhancedStroke stroke) {
    if (stroke.points.isEmpty) return;

    // Create marker effect with multiple layers
    final baseOpacity = stroke.toolSettings.opacity * 0.6;

    // Draw base layer (wider, more transparent)
    _drawMarkerLayer(canvas, stroke, 1.5, baseOpacity * 0.4);

    // Draw main layer
    _drawMarkerLayer(canvas, stroke, 1.0, baseOpacity);

    // Draw highlight layer (narrower, less transparent)
    _drawMarkerLayer(canvas, stroke, 0.6, baseOpacity * 1.2);
  }

  void _drawMarkerLayer(
    Canvas canvas,
    EnhancedStroke stroke,
    double sizeFactor,
    double opacity,
  ) {
    for (int i = 0; i < stroke.points.length - 1; i++) {
      final point = stroke.points[i];
      final nextPoint = stroke.points[i + 1];

      final pressureFactor =
          stroke.toolSettings.pressureSensitive ? point.pressure : 1.0;
      final dynamicSize =
          stroke.toolSettings.size * sizeFactor * pressureFactor;

      final paint = Paint()
        ..color = stroke.toolSettings.color.withOpacity(opacity.clamp(0.0, 1.0))
        ..strokeWidth = dynamicSize
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke
        ..blendMode = ui.BlendMode.multiply;

      canvas.drawLine(point.position, nextPoint.position, paint);
    }
  }

  void _drawBrushStroke(Canvas canvas, EnhancedStroke stroke) {
    if (stroke.points.length < 2) return;

    // Create soft brush effect
    for (int i = 0; i < stroke.points.length - 1; i++) {
      final point = stroke.points[i];
      final nextPoint = stroke.points[i + 1];

      final pressureFactor =
          stroke.toolSettings.pressureSensitive ? point.pressure : 1.0;
      final dynamicSize = stroke.toolSettings.size * pressureFactor;
      final dynamicOpacity =
          stroke.toolSettings.opacity * stroke.toolSettings.flow;

      // Create gradient brush effect
      final center = Offset(
        (point.position.dx + nextPoint.position.dx) / 2,
        (point.position.dy + nextPoint.position.dy) / 2,
      );

      final gradient = RadialGradient(
        colors: [
          stroke.toolSettings.color.withOpacity(dynamicOpacity),
          stroke.toolSettings.color.withOpacity(0.0),
        ],
        stops: const [0.0, 1.0],
      );

      final paint = Paint()
        ..shader = gradient.createShader(
          Rect.fromCircle(center: center, radius: dynamicSize / 2),
        )
        ..blendMode = ui.BlendMode.srcOver;

      canvas.drawCircle(center, dynamicSize / 2, paint);
    }
  }

  void _drawEraserStroke(Canvas canvas, EnhancedStroke stroke) {
    if (stroke.points.length < 2) return;

    final paint = Paint()
      ..color = Colors.transparent
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..blendMode = ui.BlendMode.clear
      ..isAntiAlias = stroke.toolSettings.antiAlias;

    for (int i = 0; i < stroke.points.length - 1; i++) {
      final point = stroke.points[i];
      final nextPoint = stroke.points[i + 1];

      final pressureFactor =
          stroke.toolSettings.pressureSensitive ? point.pressure : 1.0;
      final dynamicSize = stroke.toolSettings.size * pressureFactor;

      paint.strokeWidth = dynamicSize;
      canvas.drawLine(point.position, nextPoint.position, paint);
    }
  }

  @override
  bool shouldRepaint(covariant ProfessionalSketchPainter oldDelegate) {
    return oldDelegate.strokes != strokes ||
        oldDelegate.currentStroke != currentStroke ||
        oldDelegate.backgroundImage != backgroundImage ||
        oldDelegate.imageOpacity != imageOpacity ||
        oldDelegate.showImage != showImage;
  }
}
