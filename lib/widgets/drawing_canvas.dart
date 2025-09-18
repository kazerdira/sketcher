import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/sketch_controller.dart';
import '../painters/sketch_painter.dart';
import '../models/drawing_tool.dart';

class DrawingCanvas extends StatefulWidget {
  const DrawingCanvas({Key? key}) : super(key: key);

  @override
  State<DrawingCanvas> createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends State<DrawingCanvas> {
  late final SketchController controller;
  // Removed InteractiveViewer, no need for TransformationController

  bool _isDrawing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildToolbar(),
          Expanded(
            child: Container(
              color: Colors.white,
              child: GetBuilder<SketchController>(
                builder: (controller) {
                  return SizedBox.expand(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      key: const Key('drawing-area'),
                      onPanStart: (details) {
                        _isDrawing = true;
                        HapticFeedback.lightImpact();
                        controller.startStroke(details.localPosition, 1.0);
                      },
                      onPanUpdate: (details) {
                        if (!_isDrawing) return;
                        controller.addPoint(details.localPosition, 1.0);
                      },
                      onPanEnd: (_) {
                        if (!_isDrawing) return;
                        _isDrawing = false;
                        controller.endStroke();
                      },
                      onPanCancel: () {
                        if (!_isDrawing) return;
                        _isDrawing = false;
                        controller.endStroke();
                      },
                      child: CustomPaint(
                        painter: SketchPainter(
                          strokes: controller.strokes,
                          currentStroke: controller.currentStroke,
                          backgroundImage: controller.backgroundImage.value,
                          imageOpacity: controller.imageOpacity.value,
                          isImageVisible: controller.isImageVisible.value,
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          _buildBottomControls(),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<SketchController>()) {
      controller = Get.find<SketchController>();
    } else {
      controller = Get.put(SketchController());
    }
  }

  // Interaction callbacks removed with InteractiveViewer

  // Pointer handlers migrated to GestureDetector callbacks

  Widget _buildToolbar() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: GetBuilder<SketchController>(
        builder: (controller) {
          return Row(
            children: [
              const SizedBox(width: 16),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildToolButton(
                        icon: Icons.edit,
                        isSelected:
                            controller.currentTool.value == DrawingTool.pencil,
                        onTap: () => controller.setTool(DrawingTool.pencil),
                        tooltip: 'Pencil',
                      ),
                      _buildToolButton(
                        icon: Icons.create,
                        isSelected:
                            controller.currentTool.value == DrawingTool.pen,
                        onTap: () => controller.setTool(DrawingTool.pen),
                        tooltip: 'Pen',
                      ),
                      _buildToolButton(
                        icon: Icons.brush,
                        isSelected:
                            controller.currentTool.value == DrawingTool.marker,
                        onTap: () => controller.setTool(DrawingTool.marker),
                        tooltip: 'Marker',
                      ),
                      _buildToolButton(
                        icon: Icons.cleaning_services,
                        isSelected:
                            controller.currentTool.value == DrawingTool.eraser,
                        onTap: () => controller.setTool(DrawingTool.eraser),
                        tooltip: 'Eraser',
                      ),
                      _buildToolButton(
                        icon: Icons.brush_outlined,
                        isSelected:
                            controller.currentTool.value == DrawingTool.brush,
                        onTap: () => controller.setTool(DrawingTool.brush),
                        tooltip: 'Brush',
                      ),
                      const SizedBox(width: 16),
                      _buildColorPalette(),
                      const SizedBox(width: 16),
                    ],
                  ),
                ),
              ),
              _buildActionButtons(),
              const SizedBox(width: 16),
            ],
          );
        },
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? Colors.blue : Colors.grey.withOpacity(0.3),
              ),
            ),
            child: Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[700],
              size: 24,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildColorPalette() {
    final colors = [
      Colors.black,
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.orange,
      Colors.purple,
      Colors.brown,
      Colors.pink,
      Colors.grey,
    ];

    return GetBuilder<SketchController>(
      builder: (controller) {
        return Row(
          children: colors.map((color) {
            final isSelected = controller.currentColor.value == color;
            return GestureDetector(
              onTap: () => controller.setColor(color),
              child: Container(
                margin: const EdgeInsets.only(right: 6),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.blue : Colors.grey,
                    width: isSelected ? 3 : 1,
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildActionButtons() {
    return GetBuilder<SketchController>(
      builder: (controller) {
        return Row(
          children: [
            IconButton(
              onPressed: controller.undo,
              icon: const Icon(Icons.undo),
              tooltip: 'Undo',
            ),
            IconButton(
              onPressed: controller.clear,
              icon: const Icon(Icons.clear),
              tooltip: 'Clear All',
            ),
            IconButton(
              onPressed: () => _showImagePicker(),
              icon: const Icon(Icons.image),
              tooltip: 'Background Image',
            ),
            if (controller.backgroundImage.value != null)
              IconButton(
                onPressed: controller.toggleImageVisibility,
                icon: Icon(
                  controller.isImageVisible.value
                      ? Icons.visibility
                      : Icons.visibility_off,
                ),
                tooltip: 'Toggle Image Visibility',
              ),
          ],
        );
      },
    );
  }

  Widget _buildBottomControls() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: GetBuilder<SketchController>(
          builder: (controller) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Brush Size Slider
                  Row(
                    children: [
                      const Icon(Icons.brush, size: 16),
                      const SizedBox(width: 8),
                      const Text('Size:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Expanded(
                        child: Slider(
                          value: controller.brushSize.value,
                          min: 1.0,
                          max: 50.0,
                          divisions: 49,
                          label: controller.brushSize.value.round().toString(),
                          onChanged: controller.setBrushSize,
                        ),
                      ),
                      SizedBox(
                        width: 30,
                        child: Text(
                          '${controller.brushSize.value.round()}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  // Opacity Slider
                  Row(
                    children: [
                      const Icon(Icons.opacity, size: 16),
                      const SizedBox(width: 8),
                      const Text('Opacity:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Expanded(
                        child: Slider(
                          value: controller.toolOpacity.value,
                          min: 0.0,
                          max: 1.0,
                          divisions: 10,
                          label:
                              '${(controller.toolOpacity.value * 100).round()}%',
                          onChanged: controller.setOpacity,
                        ),
                      ),
                      SizedBox(
                        width: 40,
                        child: Text(
                          '${(controller.toolOpacity.value * 100).round()}%',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showImagePicker() {
    // Implementation for image picker
    // This would typically use image_picker package
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  // Implement gallery picker
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  // Implement camera picker
                },
              ),
              if (controller.backgroundImage.value != null)
                ListTile(
                  leading: const Icon(Icons.delete),
                  title: const Text('Remove Background'),
                  onTap: () {
                    Navigator.pop(context);
                    // Note: This would need to be implemented in controller
                    // controller.removeBackgroundImage();
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}
