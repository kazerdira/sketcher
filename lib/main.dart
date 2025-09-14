// Enhanced Sketching App with Professional Architecture
// Features: GetX state management, modular widgets, zoom/pan, multi-level undo,
// stroke smoothing, pressure simulation, image import/export

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'controllers/sketch_controller.dart';
import 'widgets/sketch_app_bar.dart';
import 'widgets/drawing_canvas.dart';
import 'widgets/controls_panel.dart';
import 'utils/dialogs.dart';

void main() => runApp(const SketchingApp());

class SketchingApp extends StatelessWidget {
  const SketchingApp({super.key});

  @override
  Widget build(BuildContext context) => GetMaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Professional Sketching App',
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      useMaterial3: true,
    ),
    home: const SketchHomePage(),
  );
}

class SketchHomePage extends StatefulWidget {
  const SketchHomePage({super.key});

  @override
  State<SketchHomePage> createState() => _SketchHomePageState();
}

class _SketchHomePageState extends State<SketchHomePage> {
  final SketchController c = Get.put(SketchController());
  final GlobalKey _drawingKey = GlobalKey();
  late final DrawingCanvas _drawingCanvas;

  @override
  void initState() {
    super.initState();
    _drawingCanvas = DrawingCanvas(drawingKey: _drawingKey);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SketchAppBar(onExport: _exportDrawing),
      body: Stack(
        children: [
          // Main content
          Column(
            children: [
              // Main drawing area
              _drawingCanvas,

              // Controls panel (collapsible)
              const ControlsPanel(),
            ],
          ),

          // Loading overlay during export
          Obx(() {
            if (c.exporting.value) {
              return Container(
                color: Colors.black54,
                child: const Center(
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(width: 16),
                          Text('Exporting image...'),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
    );
  }

  /// Export the current drawing as an image
  Future<void> _exportDrawing() async {
    if (c.strokes.isEmpty) {
      DialogUtils.showSnack(context, 'Nothing to export');
      return;
    }

    try {
      // Capture the drawing canvas as an image
      final ui.Image? image = await _drawingCanvas.captureAsImage();

      if (image != null) {
        final bool success = await c.exportImage(image);

        if (mounted) {
          DialogUtils.showSnack(
            context,
            success ? 'Image exported successfully!' : 'Export failed',
          );
        }
      } else {
        if (mounted) {
          DialogUtils.showSnack(context, 'Failed to capture image');
        }
      }
    } catch (e) {
      if (mounted) {
        DialogUtils.showSnack(context, 'Export error: $e');
      }
    }
  }
}
