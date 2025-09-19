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
      elevation: 8,
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: GetBuilder<SketchController>(
            builder: (controller) {
              return Row(
                children: [
                  // Tool Selector (iPhone-style segmented control)
                  Expanded(
                    flex: 3,
                    child: _buildToolSelector(controller),
                  ),
                  const SizedBox(width: 16),
                  // Color Palette (Adobe-style)
                  _buildModernColorPalette(controller),
                  const SizedBox(width: 16),
                  // Action Buttons
                  _buildCompactActionButtons(controller),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // Modern iPhone-style segmented tool selector
  Widget _buildToolSelector(SketchController controller) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          _buildSegmentedButton(
            Icons.edit,
            'Pencil',
            controller.currentTool.value == DrawingTool.pencil,
            () => controller.setTool(DrawingTool.pencil),
          ),
          _buildSegmentedButton(
            Icons.create,
            'Pen',
            controller.currentTool.value == DrawingTool.pen,
            () => controller.setTool(DrawingTool.pen),
          ),
          _buildSegmentedButton(
            Icons.brush,
            'Marker',
            controller.currentTool.value == DrawingTool.marker,
            () => controller.setTool(DrawingTool.marker),
          ),
          _buildSegmentedButton(
            Icons.cleaning_services,
            'Eraser',
            controller.currentTool.value == DrawingTool.eraser,
            () => controller.setTool(DrawingTool.eraser),
          ),
          _buildSegmentedButton(
            Icons.brush_outlined,
            'Brush',
            controller.currentTool.value == DrawingTool.brush,
            () => controller.setTool(DrawingTool.brush),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedButton(
    IconData icon,
    String tooltip,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[600] : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Icon(
              icon,
              size: 20,
              color: isSelected ? Colors.white : Colors.grey[700],
            ),
          ),
        ),
      ),
    );
  }

  // Adobe-style color palette with quick access
  Widget _buildModernColorPalette(SketchController controller) {
    final colors = [
      Colors.black,
      Colors.red[600]!,
      Colors.blue[600]!,
      Colors.green[600]!,
      Colors.orange[600]!,
      Colors.purple[600]!,
    ];

    return Container(
      height: 40,
      child: Row(
        children: [
          // Current color indicator
          GestureDetector(
            onTap: () => _showColorPicker(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: controller.currentColor.value,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey[300]!, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: controller.currentColor.value == Colors.white
                  ? Icon(Icons.add, color: Colors.grey[600], size: 20)
                  : null,
            ),
          ),
          const SizedBox(width: 8),
          // Quick color swatches
          ...colors.map((color) => Padding(
                padding: const EdgeInsets.only(right: 4),
                child: GestureDetector(
                  onTap: () => controller.setColor(color),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: controller.currentColor.value == color
                            ? Colors.blue[600]!
                            : Colors.grey[300]!,
                        width: controller.currentColor.value == color ? 3 : 1,
                      ),
                    ),
                  ),
                ),
              )),
        ],
      ),
    );
  }

  // Compact action buttons
  Widget _buildCompactActionButtons(SketchController controller) {
    return Row(
      children: [
        _buildModernActionButton(
          Icons.undo,
          'Undo',
          controller.strokes.isNotEmpty,
          controller.undo,
        ),
        const SizedBox(width: 8),
        _buildModernActionButton(
          Icons.clear_all,
          'Clear',
          controller.strokes.isNotEmpty,
          controller.clear,
        ),
        const SizedBox(width: 8),
        _buildModernActionButton(
          Icons.settings,
          'Settings',
          true,
          () => _showAdvancedSettings(),
        ),
      ],
    );
  }

  Widget _buildModernActionButton(
    IconData icon,
    String tooltip,
    bool enabled,
    VoidCallback? onTap,
  ) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: enabled ? Colors.grey[100] : Colors.grey[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(20),
        child: Icon(
          icon,
          size: 20,
          color: enabled ? Colors.grey[700] : Colors.grey[400],
        ),
      ),
    );
  }

  void _showColorPicker() {
    // TODO: Implement advanced color picker
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Advanced color picker coming soon!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showAdvancedSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildAdvancedSettingsPanel(),
    );
  }

  // Adobe-style advanced settings panel
  Widget _buildAdvancedSettingsPanel() {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: GetBuilder<SketchController>(
            builder: (controller) {
              return Column(
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Text(
                          'Brush Settings',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  // Settings content
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildModernSlider(
                            'Brush Size',
                            controller.brushSize.value,
                            1.0,
                            50.0,
                            (value) => controller.setBrushSize(value),
                            Icons.brush,
                          ),
                          const SizedBox(height: 24),
                          _buildModernSlider(
                            'Stroke Opacity',
                            controller.toolOpacity.value,
                            0.1,
                            1.0,
                            (value) => controller.setOpacity(value),
                            Icons.opacity,
                          ),
                          if (controller.backgroundImage.value != null) ...[
                            const SizedBox(height: 24),
                            _buildModernSlider(
                              'Image Opacity',
                              controller.imageOpacity.value,
                              0.1,
                              1.0,
                              (value) => controller.setImageOpacity(value),
                              Icons.image,
                            ),
                          ],
                          const SizedBox(height: 32),
                          _buildActionSection(controller),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildModernSlider(
    String label,
    double value,
    double min,
    double max,
    Function(double) onChanged,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                value.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Colors.blue[600],
            inactiveTrackColor: Colors.grey[300],
            thumbColor: Colors.blue[600],
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
            trackHeight: 4,
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildActionSection(SketchController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Save Sketch',
                Icons.save_alt,
                Colors.green,
                _saveSketch,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'Background',
                Icons.image,
                Colors.blue,
                _showImagePicker,
              ),
            ),
          ],
        ),
        if (controller.backgroundImage.value != null) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  controller.isImageVisible.value ? 'Hide Image' : 'Show Image',
                  controller.isImageVisible.value
                      ? Icons.visibility_off
                      : Icons.visibility,
                  Colors.orange,
                  controller.toggleImageVisibility,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  'Remove Image',
                  Icons.close,
                  Colors.red,
                  () {
                    setState(() {
                      _backgroundImageData = null;
                    });
                    controller.setBackgroundImage(null);
                    controller.isImageVisible.value = false;
                    controller.update();
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
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
