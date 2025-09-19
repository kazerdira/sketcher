import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../controllers/sketch_controller.dart';
import '../painters/sketch_painter.dart';
import '../models/drawing_tool.dart';
import '../models/stroke.dart';

class DrawingCanvas extends StatefulWidget {
  const DrawingCanvas({Key? key}) : super(key: key);

  @override
  State<DrawingCanvas> createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends State<DrawingCanvas> {
  late final SketchController controller;
  // Removed InteractiveViewer, no need for TransformationController

  bool _isDrawing = false;
  ui.Image? _backgroundImageData;
  Offset? _cursorPos;
  final GlobalKey _repaintKey = GlobalKey();

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
                  print(
                      '🏗️ GETBUILDER: Rebuilding canvas with ${controller.strokes.length} strokes');
                  return SizedBox.expand(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      key: const Key('drawing-area'),
                      onPanStart: (details) {
                        _isDrawing = true;
                        HapticFeedback.lightImpact();
                        controller.startStroke(details.localPosition, 1.0);
                        setState(() => _cursorPos = details.localPosition);
                      },
                      onPanUpdate: (details) {
                        if (!_isDrawing) return;
                        controller.addPoint(details.localPosition, 1.0);
                        setState(() => _cursorPos = details.localPosition);
                      },
                      onPanEnd: (_) {
                        if (!_isDrawing) return;
                        _isDrawing = false;
                        controller.endStroke();
                        setState(() => _cursorPos = null);
                      },
                      onPanCancel: () {
                        if (!_isDrawing) return;
                        _isDrawing = false;
                        controller.endStroke();
                        setState(() => _cursorPos = null);
                      },
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          RepaintBoundary(
                            key: _repaintKey,
                            child: CustomPaint(
                              painter: SketchPainter(
                                strokes: List<Stroke>.from(controller.strokes),
                                currentStroke: controller.currentStroke,
                                backgroundImage:
                                    controller.backgroundImage.value,
                                imageOpacity: controller.imageOpacity.value,
                                isImageVisible: controller.isImageVisible.value,
                                backgroundImageData: _backgroundImageData,
                              ),
                              child: const SizedBox.expand(),
                            ),
                          ),
                          GetBuilder<SketchController>(builder: (_) {
                            if (_cursorPos == null ||
                                controller.currentTool.value !=
                                    DrawingTool.eraser) {
                              return const SizedBox.shrink();
                            }
                            final d = controller.brushSize.value;
                            return Positioned(
                              left: _cursorPos!.dx - d / 2,
                              top: _cursorPos!.dy - d / 2,
                              width: d,
                              height: d,
                              child: IgnorePointer(
                                child: Stack(children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.black.withOpacity(0.7),
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    margin: const EdgeInsets.all(1.5),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.9),
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                ]),
                              ),
                            );
                          }),
                        ],
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
    return Material(
      elevation: 2,
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 72,
          child: GetBuilder<SketchController>(
            builder: (controller) {
              return Row(
                children: [
                  const SizedBox(width: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children: [
                          _buildToolButton(
                            icon: Icons.edit,
                            isSelected: controller.currentTool.value ==
                                DrawingTool.pencil,
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
                            isSelected: controller.currentTool.value ==
                                DrawingTool.marker,
                            onTap: () => controller.setTool(DrawingTool.marker),
                            tooltip: 'Marker',
                          ),
                          _buildToolButton(
                            icon: Icons.cleaning_services,
                            isSelected: controller.currentTool.value ==
                                DrawingTool.eraser,
                            onTap: () => controller.setTool(DrawingTool.eraser),
                            tooltip: 'Eraser',
                          ),
                          _buildToolButton(
                            icon: Icons.brush_outlined,
                            isSelected: controller.currentTool.value ==
                                DrawingTool.brush,
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
                  const SizedBox(width: 8),
                ],
              );
            },
          ),
        ),
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
              color: isSelected ? const Color(0xFF007AFF) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF007AFF)
                    : Colors.grey.withOpacity(0.2),
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0xFF007AFF).withOpacity(0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      )
                    ],
            ),
            child: Icon(
              icon,
              color: isSelected ? Colors.white : Colors.black87,
              size: 22,
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
              key: const Key('undo-button'),
              onPressed: () {
                print('🔘 BUTTON: Undo button pressed');
                controller.undo();
                print('🔘 BUTTON: Undo call completed');
              },
              icon: const Icon(Icons.undo),
              tooltip: 'Undo',
            ),
            IconButton(
              key: const Key('clear-button'),
              onPressed: controller.clear,
              icon: const Icon(Icons.clear),
              tooltip: 'Clear All',
            ),
            IconButton(
              onPressed: () => _showImagePicker(),
              icon: const Icon(Icons.image),
              tooltip: 'Background Image',
            ),
            IconButton(
              onPressed: _saveSketch,
              icon: const Icon(Icons.save_alt),
              tooltip: 'Save Sketch',
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
            if (controller.backgroundImage.value != null)
              IconButton(
                key: const Key('remove-background-button'),
                onPressed: () {
                  setState(() {
                    _backgroundImageData = null;
                  });
                  controller.setBackgroundImage(null);
                  controller.isImageVisible.value = false;
                  controller.update();
                },
                icon: const Icon(Icons.close),
                tooltip: 'Remove Background',
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
                          key: const Key('brush-size-slider'),
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
                      const Text('Stroke Opacity:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Expanded(
                        child: Slider(
                          key: const Key('stroke-opacity-slider'),
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
                  if (controller.backgroundImage.value != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.image, size: 16),
                        const SizedBox(width: 8),
                        const Text('Image Opacity:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Expanded(
                          child: Slider(
                            key: const Key('image-opacity-slider'),
                            value: controller.imageOpacity.value,
                            min: 0.0,
                            max: 1.0,
                            divisions: 10,
                            label:
                                '${(controller.imageOpacity.value * 100).round()}%',
                            onChanged: controller.setImageOpacity,
                          ),
                        ),
                        SizedBox(
                          width: 40,
                          child: Text(
                            '${(controller.imageOpacity.value * 100).round()}%',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showImagePicker() {
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
                  _pickFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickFromCamera();
                },
              ),
              if (controller.backgroundImage.value != null)
                ListTile(
                  leading: const Icon(Icons.delete),
                  title: const Text('Remove Background'),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _backgroundImageData = null;
                    });
                    controller.setBackgroundImage(null);
                    controller.isImageVisible.value = false;
                    controller.update();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickFromGallery() async {
    try {
      final picker = ImagePicker();
      final XFile? picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      final img = await _decodeUiImage(bytes);

      setState(() {
        _backgroundImageData = img;
      });
      // Use MemoryImage to avoid platform-specific file issues
      controller.setBackgroundImage(MemoryImage(bytes));
      controller.isImageVisible.value = true;
      controller.update();
    } catch (e) {
      Get.snackbar(
        'Image Error',
        'Failed to load image: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _pickFromCamera() async {
    try {
      final picker = ImagePicker();
      final XFile? picked = await picker.pickImage(source: ImageSource.camera);
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      final img = await _decodeUiImage(bytes);

      setState(() {
        _backgroundImageData = img;
      });
      controller.setBackgroundImage(MemoryImage(bytes));
      controller.isImageVisible.value = true;
      controller.update();
    } catch (e) {
      Get.snackbar(
        'Camera Error',
        'Failed to capture image: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<ui.Image> _decodeUiImage(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  Future<void> _saveSketch() async {
    try {
      final boundary = _repaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final pngBytes = byteData.buffer.asUint8List();

      // TODO: Persist via path_provider and show a snackbar with the path
      Get.snackbar(
        'Saved',
        'Sketch captured to PNG (${(pngBytes.lengthInBytes / 1024).toStringAsFixed(1)} KB)',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Save Error',
        'Failed to save sketch: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
