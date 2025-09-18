import 'package:flutter/material.dart';
import 'dart:ui' as ui;
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
        // Simple brush with soft edges
        for (int i = 0; i < stroke.points.length - 1; i++) {
          final point = stroke.points[i];
          final nextPoint = stroke.points[i + 1];

          final pressureFactor =
              stroke.toolSettings.pressureSensitive ? point.pressure : 1.0;
          final dynamicSize = stroke.toolSettings.size * pressureFactor;
          final dynamicOpacity =
              stroke.toolSettings.opacity * stroke.toolSettings.flow;

          final paint = Paint()
            ..color = stroke.toolSettings.color
                .withOpacity(dynamicOpacity.clamp(0.0, 1.0))
            ..strokeWidth = dynamicSize.clamp(1.0, 50.0)
            ..strokeCap = StrokeCap.round
            ..style = PaintingStyle.stroke
            ..isAntiAlias = stroke.toolSettings.antiAlias;

          canvas.drawLine(point.position, nextPoint.position, paint);
        }
        break;
    }
  }

  void _drawPencilStroke(Canvas canvas, EnhancedStroke stroke) {
    if (stroke.points.length < 2) return;

    // Simple, visible pencil stroke first
    for (int i = 0; i < stroke.points.length - 1; i++) {
      final point = stroke.points[i];
      final nextPoint = stroke.points[i + 1];

      // Calculate pressure-based size and opacity
      final pressureFactor =
          stroke.toolSettings.pressureSensitive ? point.pressure : 1.0;

      final dynamicSize = stroke.toolSettings.size * pressureFactor;
      final dynamicOpacity = stroke.toolSettings.opacity * pressureFactor;

      // Draw main stroke line
      final paint = Paint()
        ..color = stroke.toolSettings.color
            .withOpacity(dynamicOpacity.clamp(0.3, 1.0))
        ..strokeWidth = dynamicSize.clamp(1.0, 50.0)
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke
        ..isAntiAlias = stroke.toolSettings.antiAlias;

      canvas.drawLine(point.position, nextPoint.position, paint);

      // Add texture with additional thinner lines for pencil effect
      if (dynamicSize > 2.0) {
        final texturePaint = Paint()
          ..color = stroke.toolSettings.color.withOpacity(dynamicOpacity * 0.3)
          ..strokeWidth = (dynamicSize * 0.5).clamp(0.5, 10.0)
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;

        // Offset lines for texture
        canvas.drawLine(
          point.position + const Offset(0.5, 0),
          nextPoint.position + const Offset(0.5, 0),
          texturePaint,
        );
        canvas.drawLine(
          point.position + const Offset(-0.5, 0),
          nextPoint.position + const Offset(-0.5, 0),
          texturePaint,
        );
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

    // Simple, visible marker with transparency
    for (int i = 0; i < stroke.points.length - 1; i++) {
      final point = stroke.points[i];
      final nextPoint = stroke.points[i + 1];

      final pressureFactor =
          stroke.toolSettings.pressureSensitive ? point.pressure : 1.0;
      final dynamicSize = stroke.toolSettings.size * pressureFactor;

      // Main marker stroke with transparency
      final paint = Paint()
        ..color = stroke.toolSettings.color
            .withOpacity(0.6 * stroke.toolSettings.opacity)
        ..strokeWidth = dynamicSize.clamp(2.0, 50.0)
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke
        ..blendMode = ui.BlendMode.srcOver;

      canvas.drawLine(point.position, nextPoint.position, paint);

      // Add a second layer for marker effect
      final overlayPaint = Paint()
        ..color = stroke.toolSettings.color
            .withOpacity(0.3 * stroke.toolSettings.opacity)
        ..strokeWidth = (dynamicSize * 1.2).clamp(3.0, 60.0)
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke
        ..blendMode = ui.BlendMode.multiply;

      canvas.drawLine(point.position, nextPoint.position, overlayPaint);
    }
  }

  void _drawEraserStroke(Canvas canvas, EnhancedStroke stroke) {
    if (stroke.points.length < 2) return;

    // Use saveLayer for proper erasing
    canvas.saveLayer(null, Paint());

    for (int i = 0; i < stroke.points.length - 1; i++) {
      final point = stroke.points[i];
      final nextPoint = stroke.points[i + 1];

      final pressureFactor =
          stroke.toolSettings.pressureSensitive ? point.pressure : 1.0;
      final dynamicSize = stroke.toolSettings.size * pressureFactor;

      final paint = Paint()
        ..color = Colors.transparent
        ..strokeWidth = dynamicSize.clamp(5.0, 100.0)
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke
        ..blendMode = ui.BlendMode.clear
        ..isAntiAlias = stroke.toolSettings.antiAlias;

      canvas.drawLine(point.position, nextPoint.position, paint);
    }

    canvas.restore();
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
