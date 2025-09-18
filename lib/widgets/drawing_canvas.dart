import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import '../controllers/sketch_controller.dart';
import '../painters/professional_sketch_painter.dart';

/// The main drawing canvas with zoom, pan, and drawing capabilities
class DrawingCanvas extends StatelessWidget {
  const DrawingCanvas({super.key, required this.drawingKey});

  final GlobalKey drawingKey;

  @override
  Widget build(BuildContext context) {
    final SketchController c = Get.find();

    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              // Background image layer
              Obx(() {
                if (c.baseImageFile.value != null && c.imageVisible.value) {
                  return Positioned.fill(
                    child: Opacity(
                      opacity: c.imageOpacity.value,
                      child: Image.file(
                        c.baseImageFile.value!,
                        fit: BoxFit.contain,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                  );
                } else if (c.baseImageFile.value == null) {
                  return Center(
                    child: Text(
                      'Import an image to start',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),

              // Drawing layer
              RepaintBoundary(
                key: drawingKey,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onScaleStart: (details) {
                    if (details.pointerCount == 1) {
                      final pt = _toCanvasPoint(details.focalPoint);
                      if (pt != null) c.startStroke(pt);
                    }
                  },
                  onScaleUpdate: (details) {
                    if (details.pointerCount == 1 && c.currentStroke != null) {
                      final pt = _toCanvasPoint(details.focalPoint);
                      if (pt != null) {
                        c.appendPoint(
                          pt,
                          velocity:
                              details.horizontalScale + details.verticalScale,
                        );
                      }
                    } else if (details.pointerCount == 2) {
                      // Zoom and pan
                      c.scale.value = (c.scale.value * details.scale).clamp(
                        0.5,
                        3.0,
                      );
                      c.offset.value += details.focalPointDelta;
                    }
                  },
                  onScaleEnd: (details) => c.endStroke(),
                  child: Obx(
                    () => Transform(
                      alignment: Alignment.topLeft,
                      transform: Matrix4.identity()
                        ..translate(c.offset.value.dx, c.offset.value.dy)
                        ..scale(c.scale.value),
                      child: GetBuilder<SketchController>(
                        builder: (_) => CustomPaint(
                          painter: ProfessionalSketchPainter(
                            strokes: c.strokes,
                          ),
                          size: Size.infinite,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Zoom indicator
              Obx(() {
                if (c.scale.value != 1.0) {
                  return Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${(c.scale.value * 100).round()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),
            ],
          ),
        ),
      ),
    );
  }

  /// Convert global coordinates to canvas coordinates
  Offset? _toCanvasPoint(Offset global) {
    final SketchController c = Get.find();
    final renderObject = drawingKey.currentContext?.findRenderObject();

    if (renderObject is RenderBox) {
      final local = renderObject.globalToLocal(global);
      return (local - c.offset.value) / c.scale.value;
    }
    return null;
  }

  /// Capture the drawing area as an image for export
  Future<ui.Image?> captureAsImage() async {
    final RenderRepaintBoundary? boundary =
        drawingKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;

    if (boundary != null) {
      return await boundary.toImage(pixelRatio: 3.0);
    }
    return null;
  }
}
