import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
// Syncfusion imports removed after reverting to Material Slider for tests
import '../controllers/sketch_controller.dart';
import '../painters/sketch_painter.dart';
import '../models/drawing_tool.dart';
import '../models/stroke.dart';
import '../models/brush_mode.dart';

class DrawingCanvas extends StatefulWidget {
  const DrawingCanvas({Key? key}) : super(key: key);

  @override
  State<DrawingCanvas> createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends State<DrawingCanvas> {
  late final SketchController controller;
  final GlobalKey _repaintKey = GlobalKey();
  int _pointerCount = 0;

  bool _isDrawing = false;
  ui.Image? _backgroundImageData;
  Offset? _cursorPos;
  Offset? _downPos;
  bool _pendingTap = false;
  static const double _touchSlop = 8.0;
  bool _controlsExpanded = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildToolbar(),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Listener(
                onPointerDown: (event) {
                  // ignore: avoid_print
                  print('👆 pointer down');
                  final newCount = (_pointerCount + 1).clamp(0, 10);
                  final scenePos = controller.transformationController
                      .toScene(event.localPosition);
                  if (newCount == 1) {
                    // Defer starting stroke until we see movement or a tap completes.
                    _downPos = scenePos;
                    _pendingTap = true;
                    _cursorPos = scenePos;
                  } else {
                    // Multi-touch: cancel any pending tap or drawing.
                    _pendingTap = false;
                    if (_isDrawing) {
                      _isDrawing = false;
                      controller.endStroke();
                      _cursorPos = null;
                    }
                  }
                  _pointerCount = newCount;
                  setState(() {});
                },
                onPointerMove: (event) {
                  if (_pointerCount == 1) {
                    final scenePos = controller.transformationController
                        .toScene(event.localPosition);
                    if (!_isDrawing && _pendingTap && _downPos != null) {
                      final moved = (scenePos - _downPos!).distance;
                      if (moved >= _touchSlop) {
                        // Start drawing after surpassing touch slop.
                        _isDrawing = true;
                        _pendingTap = false;
                        HapticFeedback.lightImpact();
                        controller.startStroke(_downPos!, 1.0);
                        controller.addPoint(scenePos, 1.0);
                      }
                    } else if (_isDrawing) {
                      controller.addPoint(scenePos, 1.0);
                    }
                    _cursorPos = scenePos;
                    setState(() {});
                  }
                },
                onPointerUp: (event) {
                  // ignore: avoid_print
                  print('👇 pointer up');
                  if (_pointerCount == 1) {
                    if (_isDrawing) {
                      _isDrawing = false;
                      controller.endStroke();
                      _cursorPos = null;
                    } else if (_pendingTap && _downPos != null) {
                      // Treat as a dot tap if no multitouch occurred and no move beyond slop.
                      controller.startStroke(_downPos!, 1.0);
                      controller.endStroke();
                      _cursorPos = null;
                    }
                    _pendingTap = false;
                    _downPos = null;
                  }
                  _pointerCount = (_pointerCount - 1).clamp(0, 10);
                  setState(() {});
                },
                onPointerCancel: (event) {
                  // ignore: avoid_print
                  print('❌ pointer cancel');
                  if (_isDrawing) {
                    _isDrawing = false;
                    controller.endStroke();
                    _cursorPos = null;
                  }
                  _pendingTap = false;
                  _downPos = null;

                  _pointerCount = (_pointerCount - 1).clamp(0, 10);
                  setState(() {});
                },
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  key: const Key('drawing-area'),
                  child: InteractiveViewer(
                    transformationController:
                        controller.transformationController,
                    panEnabled: _pointerCount >= 2,
                    scaleEnabled: _pointerCount >= 2,
                    boundaryMargin: const EdgeInsets.all(1000),
                    minScale: 0.5,
                    maxScale: 8.0,
                    clipBehavior: Clip.none,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        GetBuilder<SketchController>(builder: (_) {
                          return RepaintBoundary(
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
                                viewport: _computeSceneViewport(constraints),
                              ),
                              child: const SizedBox.expand(),
                            ),
                          );
                        }),
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
                ),
              );
            },
          ),
        ),
        _buildInlineControls(),
      ],
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

  Rect _computeSceneViewport(BoxConstraints constraints) {
    final size = Size(constraints.maxWidth, constraints.maxHeight);
    final inverse = controller.transformationController.value.clone()..invert();
    final corners = <Offset>[
      Offset.zero,
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height),
    ].map((o) => MatrixUtils.transformPoint(inverse, o)).toList();
    double minX = corners.first.dx;
    double maxX = corners.first.dx;
    double minY = corners.first.dy;
    double maxY = corners.first.dy;
    for (final c in corners) {
      if (c.dx < minX) minX = c.dx;
      if (c.dx > maxX) maxX = c.dx;
      if (c.dy < minY) minY = c.dy;
      if (c.dy > maxY) maxY = c.dy;
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY).inflate(32); // padding
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
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      // Tool Selector (iPhone-style segmented control)
                      SizedBox(
                        width: 280, // Fixed width for tool selector
                        child: _buildToolSelector(controller),
                      ),
                      const SizedBox(width: 16),
                      // Color Picker Icon (Professional color palette access)
                      _buildColorPickerButton(controller),
                      const SizedBox(width: 16),
                      // Brush mode selector (shown only for Brush tool)
                      if (controller.currentTool.value == DrawingTool.brush)
                        _buildBrushModeSelector(controller),
                      const SizedBox(width: 16), // Extra space at the end
                    ],
                  ),
                ),
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

  Widget _buildBrushModeSelector(SketchController controller) {
    final current = controller.currentBrushMode.value;
    return Semantics(
      label: 'Brush mode selector',
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(children: [
          Tooltip(
            message: 'Basic Brush',
            child: ChoiceChip(
              key: const Key('brush-mode-basic'),
              label: const Text('Basic'),
              selected: current == null,
              onSelected: (_) => controller.setBrushMode(null),
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: 'Charcoal Brush',
            child: ChoiceChip(
              key: const Key('brush-mode-charcoal'),
              label: const Text('Charcoal'),
              selected: current == BrushMode.charcoal,
              onSelected: (_) => controller.setBrushMode(BrushMode.charcoal),
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: 'Watercolor Brush',
            child: ChoiceChip(
              key: const Key('brush-mode-watercolor'),
              label: const Text('Watercolor'),
              selected: current == BrushMode.watercolor,
              onSelected: (_) => controller.setBrushMode(BrushMode.watercolor),
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: 'Airbrush',
            child: ChoiceChip(
              key: const Key('brush-mode-airbrush'),
              label: const Text('Airbrush'),
              selected: current == BrushMode.airbrush,
              onSelected: (_) => controller.setBrushMode(BrushMode.airbrush),
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: 'Calligraphy Brush',
            child: ChoiceChip(
              key: const Key('brush-mode-calligraphy'),
              label: const Text('Calligraphy'),
              selected: current == BrushMode.calligraphy,
              onSelected: (_) => controller.setBrushMode(BrushMode.calligraphy),
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: 'Pastel Brush',
            child: ChoiceChip(
              key: const Key('brush-mode-pastel'),
              label: const Text('Pastel'),
              selected: current == BrushMode.pastel,
              onSelected: (_) => controller.setBrushMode(BrushMode.pastel),
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: 'Oil Paint Brush',
            child: ChoiceChip(
              key: const Key('brush-mode-oil'),
              label: const Text('Oil'),
              selected: current == BrushMode.oilPaint,
              onSelected: (_) => controller.setBrushMode(BrushMode.oilPaint),
            ),
          ),
        ]),
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

  // Professional color picker button
  Widget _buildColorPickerButton(SketchController controller) {
    return GestureDetector(
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
        child: Icon(
          Icons.palette,
          color: controller.currentColor.value.computeLuminance() > 0.5
              ? Colors.grey[700]
              : Colors.white,
          size: 20,
        ),
      ),
    );
  }

  // Compact action buttons removed; actions moved to bottom inline controls.

  Widget _buildInlineControls() {
    return GetBuilder<SketchController>(builder: (controller) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: SafeArea(
          top: false,
          child: Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withOpacity(0.6)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Material(
                    type: MaterialType.transparency,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Top row: arrow toggle + quick actions
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            _glassIconButton(
                              icon: _controlsExpanded
                                  ? Icons.keyboard_arrow_down
                                  : Icons.keyboard_arrow_up,
                              tooltip: _controlsExpanded
                                  ? 'Hide Sliders'
                                  : 'Show Sliders',
                              onTap: () => setState(
                                  () => _controlsExpanded = !_controlsExpanded),
                              key: const Key('toggle-sliders-button'),
                            ),
                            const SizedBox(width: 12),
                            // Image and editing action buttons grouped together
                            if (controller.backgroundImage.value != null) ...[
                              _glassIconButton(
                                icon: Icons.close,
                                tooltip: 'Remove Image',
                                key: const Key('remove-background-button'),
                                color: Colors.red,
                                onTap: () {
                                  setState(() {
                                    _backgroundImageData = null;
                                  });
                                  controller.setBackgroundImage(null);
                                  controller.isImageVisible.value = false;
                                  controller.update();
                                },
                              ),
                              _divider(),
                            ],
                            _glassIconButton(
                              icon: Icons.image,
                              tooltip: 'Background',
                              onTap: _showImagePicker,
                            ),
                            const SizedBox(width: 12),
                            _glassIconButton(
                              icon: Icons.undo,
                              tooltip: 'Undo',
                              onTap: controller.undo,
                              key: const Key('undo-button'),
                            ),
                            const SizedBox(width: 8),
                            _glassIconButton(
                              icon: Icons.clear,
                              tooltip: 'Clear',
                              onTap: controller.clear,
                              key: const Key('clear-button'),
                            ),
                            const SizedBox(width: 8),
                            _glassIconButton(
                              icon: Icons.settings,
                              tooltip: 'Settings',
                              onTap: _showAdvancedSettings,
                              key: const Key('settings-button'),
                            ),
                            const Spacer(),
                          ],
                        ),
                        // Collapsible sliders area (vertical with Syncfusion)
                        AnimatedSize(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeInOut,
                          child: ClipRect(
                            child: Align(
                              alignment: Alignment.topCenter,
                              heightFactor: _controlsExpanded ? 1.0 : 0.0,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 280),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      ProSlider(
                                        label: 'Brush Size',
                                        value: controller.brushSize.value,
                                        min: 1.0,
                                        max: 50.0,
                                        onChanged: (v) =>
                                            controller.setBrushSize(v),
                                        icon: Icons.brush,
                                        sliderKey:
                                            const Key('brush-size-slider'),
                                      ),
                                      const SizedBox(height: 12),
                                      ProSlider(
                                        label: 'Stroke Opacity',
                                        value: controller.toolOpacity.value,
                                        min: 0.0,
                                        max: 1.0,
                                        onChanged: (v) =>
                                            controller.setOpacity(v),
                                        icon: Icons.opacity,
                                        sliderKey:
                                            const Key('stroke-opacity-slider'),
                                      ),
                                      // Brush-specific tuning
                                      if (controller.currentTool.value ==
                                              DrawingTool.brush &&
                                          controller.currentBrushMode.value ==
                                              BrushMode.calligraphy) ...[
                                        const SizedBox(height: 12),
                                        ProSlider(
                                          label: 'Nib Angle (°)',
                                          value: controller
                                              .calligraphyNibAngleDeg.value,
                                          min: 0.0,
                                          max: 90.0,
                                          onChanged: (v) => controller
                                              .setCalligraphyNibAngle(v),
                                          icon: Icons.rotate_right,
                                          sliderKey: const Key(
                                              'calligraphy-nib-angle-slider'),
                                        ),
                                        const SizedBox(height: 12),
                                        ProSlider(
                                          label: 'Nib Width Factor',
                                          value: controller
                                              .calligraphyNibWidthFactor.value,
                                          min: 0.3,
                                          max: 2.5,
                                          onChanged: (v) => controller
                                              .setCalligraphyNibWidthFactor(v),
                                          icon: Icons.format_size,
                                          sliderKey: const Key(
                                              'calligraphy-nib-width-slider'),
                                        ),
                                      ],
                                      if (controller.currentTool.value ==
                                              DrawingTool.brush &&
                                          controller.currentBrushMode.value ==
                                              BrushMode.pastel) ...[
                                        const SizedBox(height: 12),
                                        ProSlider(
                                          label: 'Grain Density',
                                          value: controller
                                              .pastelGrainDensity.value,
                                          min: 0.3,
                                          max: 3.0,
                                          onChanged: (v) => controller
                                              .setPastelGrainDensity(v),
                                          icon: Icons.grain,
                                          sliderKey: const Key(
                                              'pastel-grain-density-slider'),
                                        ),
                                      ],
                                      if (controller.backgroundImage.value !=
                                          null) ...[
                                        const SizedBox(height: 12),
                                        ProSlider(
                                          label: 'Image Opacity',
                                          value: controller.imageOpacity.value,
                                          min: 0.0,
                                          max: 1.0,
                                          onChanged: (v) =>
                                              controller.setImageOpacity(v),
                                          icon: Icons.image,
                                          sliderKey:
                                              const Key('image-opacity-slider'),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _divider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      width: 1,
      height: 28,
      color: Colors.black.withOpacity(0.06),
    );
  }

  Widget _glassIconButton({
    required IconData icon,
    required String tooltip,
    VoidCallback? onTap,
    Color? color,
    Key? key,
  }) {
    final iconColor = color ?? Colors.grey[700]!;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          key: key,
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.55),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.7)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 3),
              )
            ],
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
      ),
    );
  }

  // _buildModernActionButton removed; using _glassIconButton in bottom bar.

  void _showColorPicker() {
    final controller = Get.find<SketchController>();
    Color selectedColor = controller.currentColor.value;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 420,
                  maxHeight: 600,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header with current color preview
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: selectedColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Color Picker',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  _getColorHex(selectedColor),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close),
                            iconSize: 20,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      Flexible(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              // Professional Color Palette with Full Shades
                              _buildProfessionalColorPalette(selectedColor,
                                  (color) {
                                setState(() {
                                  selectedColor = color;
                                });
                              }),

                              const SizedBox(height: 16),

                              // Additional Custom Colors Section
                              const Text(
                                'Custom Colors',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildCustomColorsGrid(selectedColor, (color) {
                                setState(() {
                                  selectedColor = color;
                                });
                              }),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.grey[600],
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                controller.setColor(selectedColor);
                                Navigator.of(context).pop();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: selectedColor,
                                foregroundColor:
                                    selectedColor.computeLuminance() > 0.5
                                        ? Colors.black
                                        : Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text('Select Color'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProfessionalColorPalette(
      Color selectedColor, Function(Color) onColorSelected) {
    // Base colors for generating complete shade ranges
    final baseColors = [
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.lightBlue,
      Colors.cyan,
      Colors.teal,
      Colors.green,
      Colors.lightGreen,
      Colors.lime,
      Colors.yellow,
      Colors.amber,
      Colors.orange,
      Colors.deepOrange,
      Colors.brown,
      Colors.grey,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Professional Color Palette',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),

        // Grayscale spectrum
        _buildColorRow(
            'Grayscale',
            [
              Colors.black,
              const Color(0xFF1C1C1C),
              const Color(0xFF2E2E2E),
              const Color(0xFF404040),
              const Color(0xFF525252),
              const Color(0xFF737373),
              const Color(0xFF949494),
              const Color(0xFFB6B6B6),
              const Color(0xFFD1D1D1),
              const Color(0xFFE8E8E8),
              const Color(0xFFF5F5F5),
              Colors.white,
            ],
            selectedColor,
            onColorSelected),

        const SizedBox(height: 8),

        // Color palette with complete shades (first 14 colors for better fit)
        ...baseColors.take(14).map((baseColor) {
          final colorName = _getColorName(baseColor);
          return _buildColorRow(
              colorName,
              [
                baseColor[900] ?? _adjustBrightness(baseColor, -0.4),
                baseColor[800] ?? _adjustBrightness(baseColor, -0.3),
                baseColor[700] ?? _adjustBrightness(baseColor, -0.2),
                baseColor[600] ?? _adjustBrightness(baseColor, -0.1),
                baseColor[500] ?? baseColor,
                baseColor[400] ?? _adjustBrightness(baseColor, 0.1),
                baseColor[300] ?? _adjustBrightness(baseColor, 0.2),
                baseColor[200] ?? _adjustBrightness(baseColor, 0.3),
                baseColor[100] ?? _adjustBrightness(baseColor, 0.4),
                baseColor[50] ?? _adjustBrightness(baseColor, 0.5),
              ],
              selectedColor,
              onColorSelected);
        }).toList(),
      ],
    );
  }

  Widget _buildColorRow(String name, List<Color> colors, Color selectedColor,
      Function(Color) onColorSelected) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: colors
            .map((color) =>
                _buildColorSwatch(color, selectedColor, onColorSelected))
            .toList(),
      ),
    );
  }

  Widget _buildColorSwatch(
      Color color, Color selectedColor, Function(Color) onColorSelected) {
    final isSelected = _colorsEqual(selectedColor, color);
    return Expanded(
      child: GestureDetector(
        onTap: () => onColorSelected(color),
        child: Container(
          height: 22,
          margin: const EdgeInsets.only(right: 1),
          decoration: BoxDecoration(
            color: color,
            border: Border.all(
              color: isSelected
                  ? Colors.blue[600]!
                  : color == Colors.white
                      ? Colors.grey[300]!
                      : Colors.transparent,
              width: isSelected ? 2 : 0.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: isSelected
              ? Icon(
                  Icons.check,
                  color: color.computeLuminance() > 0.5
                      ? Colors.black87
                      : Colors.white,
                  size: 10,
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildCustomColorsGrid(
      Color selectedColor, Function(Color) onColorSelected) {
    // Additional vibrant and unique colors not in the main palette
    final customColors = [
      // Vibrant colors
      const Color(0xFF6A1B9A), // Deep Purple
      const Color(0xFF00695C), // Dark Cyan
      const Color(0xFFBF360C), // Deep Orange Red
      const Color(0xFF263238), // Blue Grey Dark
      const Color(0xFF827717), // Lime Dark
      const Color(0xFFE65100), // Orange Dark
      const Color(0xFF1A237E), // Indigo Dark
      const Color(0xFF880E4F), // Pink Dark
      const Color(0xFF006064), // Cyan Dark
      const Color(0xFF33691E), // Light Green Dark
      const Color(0xFFFF6F00), // Amber Dark
      const Color(0xFF4A148C), // Purple Dark

      // Soft pastels
      const Color(0xFFF8BBD9), // Light Pink
      const Color(0xFFE1BEE7), // Light Purple
      const Color(0xFFB39DDB), // Light Deep Purple
      const Color(0xFF9FA8DA), // Light Indigo
      const Color(0xFF90CAF9), // Light Blue
      const Color(0xFF81D4FA), // Light Light Blue
      const Color(0xFF80CBC4), // Light Cyan
      const Color(0xFFA5D6A7), // Light Green
      const Color(0xFFC5E1A5), // Light Light Green
      const Color(0xFFDCE775), // Light Lime
      const Color(0xFFFFF176), // Light Yellow
      const Color(0xFFFFCC02), // Light Amber

      // Rich earth tones
      const Color(0xFF8D6E63), // Brown
      const Color(0xFF795548), // Brown Dark
      const Color(0xFF6D4C41), // Brown Darker
      const Color(0xFF5D4037), // Brown Darkest
      const Color(0xFF8BC34A), // Light Green
      const Color(0xFF689F38), // Light Green Dark
    ];

    return GridView.count(
      crossAxisCount: 6,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      childAspectRatio: 1.0,
      children: customColors.map((color) {
        final isSelected = _colorsEqual(selectedColor, color);
        return GestureDetector(
          onTap: () => onColorSelected(color),
          child: Container(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isSelected ? Colors.blue[600]! : Colors.grey[300]!,
                width: isSelected ? 2 : 0.5,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 1,
                        offset: const Offset(0, 0.5),
                      ),
                    ],
            ),
            child: isSelected
                ? Icon(
                    Icons.check,
                    color: color.computeLuminance() > 0.5
                        ? Colors.black87
                        : Colors.white,
                    size: 12,
                  )
                : null,
          ),
        );
      }).toList(),
    );
  }

  // Helper method to compare colors with tolerance for similar shades
  bool _colorsEqual(Color color1, Color color2) {
    return (color1.red - color2.red).abs() < 5 &&
        (color1.green - color2.green).abs() < 5 &&
        (color1.blue - color2.blue).abs() < 5;
  }

  // Helper method to adjust color brightness
  Color _adjustBrightness(Color color, double factor) {
    if (factor > 0) {
      // Lighten
      return Color.fromARGB(
        color.alpha,
        (color.red + (255 - color.red) * factor).round().clamp(0, 255),
        (color.green + (255 - color.green) * factor).round().clamp(0, 255),
        (color.blue + (255 - color.blue) * factor).round().clamp(0, 255),
      );
    } else {
      // Darken
      final positive = -factor;
      return Color.fromARGB(
        color.alpha,
        (color.red * (1 - positive)).round().clamp(0, 255),
        (color.green * (1 - positive)).round().clamp(0, 255),
        (color.blue * (1 - positive)).round().clamp(0, 255),
      );
    }
  }

  // Helper method to get color name
  String _getColorName(MaterialColor color) {
    if (color == Colors.red) return 'Red';
    if (color == Colors.pink) return 'Pink';
    if (color == Colors.purple) return 'Purple';
    if (color == Colors.deepPurple) return 'Deep Purple';
    if (color == Colors.indigo) return 'Indigo';
    if (color == Colors.blue) return 'Blue';
    if (color == Colors.lightBlue) return 'Light Blue';
    if (color == Colors.cyan) return 'Cyan';
    if (color == Colors.teal) return 'Teal';
    if (color == Colors.green) return 'Green';
    if (color == Colors.lightGreen) return 'Light Green';
    if (color == Colors.lime) return 'Lime';
    if (color == Colors.yellow) return 'Yellow';
    if (color == Colors.amber) return 'Amber';
    if (color == Colors.orange) return 'Orange';
    if (color == Colors.deepOrange) return 'Deep Orange';
    if (color == Colors.brown) return 'Brown';
    if (color == Colors.grey) return 'Grey';
    return 'Color';
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
                            sliderKey: const Key('brush-size-slider-modal'),
                          ),
                          const SizedBox(height: 24),
                          _buildModernSlider(
                            'Stroke Opacity',
                            controller.toolOpacity.value,
                            0.0,
                            1.0,
                            (value) => controller.setOpacity(value),
                            Icons.opacity,
                            sliderKey: const Key('stroke-opacity-slider-modal'),
                          ),
                          if (controller.backgroundImage.value != null) ...[
                            const SizedBox(height: 24),
                            _buildModernSlider(
                              'Image Opacity',
                              controller.imageOpacity.value,
                              0.0,
                              1.0,
                              (value) => controller.setImageOpacity(value),
                              Icons.image,
                              sliderKey:
                                  const Key('image-opacity-slider-modal'),
                            ),
                          ],
                          const SizedBox(height: 32),
                          _buildColorSection(controller),
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

  Widget _buildModernSlider(String label, double value, double min, double max,
      Function(double) onChanged, IconData icon,
      {Key? sliderKey, bool compact = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!compact) ...[
          Row(
            children: [
              Icon(icon, size: 20, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  value.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
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
            key: sliderKey,
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildColorSection(SketchController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.palette, size: 20, color: Colors.grey[600]),
            const SizedBox(width: 8),
            const Text(
              'Color',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Current color display with professional picker
        GestureDetector(
          onTap: _showColorPicker,
          child: Container(
            width: double.infinity,
            height: 60,
            decoration: BoxDecoration(
              color: controller.currentColor.value,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.colorize,
                            color: Colors.white, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Tap to Pick Color',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getColorHex(controller.currentColor.value),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Quick action buttons for color
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Color Picker',
                Icons.colorize,
                Colors.purple,
                _showColorPicker,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'HSV Picker',
                Icons.tune,
                Colors.indigo,
                () => _showHSVColorPicker(controller),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showHSVColorPicker(SketchController controller) {
    Color selectedColor = controller.currentColor.value;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'HSV Color Picker',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 300,
              height: 400,
              child: ColorPicker(
                pickerColor: selectedColor,
                onColorChanged: (Color color) {
                  selectedColor = color;
                },
                colorPickerWidth: 300.0,
                pickerAreaHeightPercent: 0.7,
                enableAlpha: false,
                displayThumbColor: true,
                showLabel: false,
                paletteType: PaletteType.hsvWithHue,
                pickerAreaBorderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                controller.setColor(selectedColor);
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Select'),
            ),
          ],
        );
      },
    );
  }

  String _getColorHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
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
                  key: const Key('remove-background-button'),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildActionCard(
      String title, IconData icon, Color color, VoidCallback onTap,
      {Key? key}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        key: key,
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

// Professional, compact slider used in the bottom inline controls
class ProSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final IconData icon;
  final bool compact;
  final Key? sliderKey;

  const ProSlider({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.icon,
    this.compact = false,
    this.sliderKey,
  });

  @override
  Widget build(BuildContext context) {
    final gradient = const LinearGradient(
      colors: [Color(0xFF4F8BFF), Color(0xFF8A63FF)],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!compact) ...[
          Row(
            children: [
              Icon(icon, size: 18, color: Colors.grey[700]),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Text(
                  value.toStringAsFixed(1),
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
        ],
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 8,
            activeTrackColor: Colors.transparent,
            inactiveTrackColor: Colors.transparent,
            thumbColor: Colors.white,
            overlayColor: const Color(0xFF4F8BFF).withOpacity(0.15),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
            trackShape: ProGradientTrackShape(
              gradient: gradient,
              inactiveColor: Colors.grey[200]!,
            ),
          ),
          child: Slider(
            key: sliderKey,
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class ProGradientTrackShape extends RoundedRectSliderTrackShape {
  final LinearGradient gradient;
  final Color inactiveColor;

  const ProGradientTrackShape({
    required this.gradient,
    required this.inactiveColor,
  });

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    Offset? secondaryOffset,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    bool isDiscrete = false,
    bool isEnabled = false,
    double additionalActiveTrackHeight = 2,
  }) {
    final Canvas canvas = context.canvas;
    final double trackHeight = sliderTheme.trackHeight ?? 4;
    final Rect trackRect = Rect.fromLTWH(
      offset.dx,
      offset.dy + (parentBox.size.height - trackHeight) / 2,
      parentBox.size.width,
      trackHeight,
    );
    final RRect rRect = RRect.fromRectAndRadius(
      trackRect,
      Radius.circular(trackHeight / 2),
    );

    final Paint inactivePaint = Paint()..color = inactiveColor;
    canvas.drawRRect(rRect, inactivePaint);

    final bool ltr = textDirection == TextDirection.ltr;
    Rect activeRect = ltr
        ? Rect.fromLTRB(
            trackRect.left, trackRect.top, thumbCenter.dx, trackRect.bottom)
        : Rect.fromLTRB(
            thumbCenter.dx, trackRect.top, trackRect.right, trackRect.bottom);

    final Paint activePaint = Paint()
      ..shader = gradient.createShader(trackRect);
    canvas.save();
    canvas.clipRRect(rRect);
    canvas.drawRect(activeRect, activePaint);
    canvas.restore();
  }
}

// Labeled wrapper for Syncfusion slider with icon, title, and value chip
// _SfLabeledSlider removed; using ProSlider-based labeled sliders.
