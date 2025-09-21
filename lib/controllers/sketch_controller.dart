import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/stroke.dart';
import '../models/drawing_tool.dart';
import '../models/brush_mode.dart';
import '../painters/sketch_painter.dart';

class SketchController extends GetxController {
  SketchController() {
    _saveToHistory();
  }
  // Observable state
  final strokes = <Stroke>[].obs;
  final undoHistory = <List<Stroke>>[].obs;
  final currentTool = DrawingTool.pencil.obs;
  final currentColor = Colors.black.obs;
  final brushSize = 5.0.obs;
  final toolOpacity = 1.0.obs;
  final currentBrushMode = Rx<BrushMode?>(null);
  // Input settings
  final stylusOnlyMode = false.obs; // Palm rejection: ignore touch for drawing
  // Brush tuning state
  final calligraphyNibAngleDeg = 40.0.obs; // 0–90
  final calligraphyNibWidthFactor = 1.0.obs; // ~0.4–1.8
  final pastelGrainDensity = 1.0.obs; // ~0.5–2.0
  final backgroundImage = Rx<ImageProvider?>(null);
  final imageOpacity = 0.5.obs;
  final isImageVisible = true.obs;
  // Anchored background image destination rect in scene coordinates
  final Rx<Rect?> imageRect = Rx<Rect?>(null);

  // Current stroke being drawn
  Stroke? _currentStroke;
  List<DrawingPoint> _currentPoints = [];

  // Velocity and pressure tracking
  double _lastVelocity = 0.0;
  // Per-tool settings
  final Map<DrawingTool, double> _toolSizes = {
    DrawingTool.pencil: 3.0,
    DrawingTool.pen: 2.0,
    DrawingTool.marker: 12.0,
    DrawingTool.eraser: 6.0,
    DrawingTool.brush: 6.0,
  };
  final Map<DrawingTool, double> _toolOpacities = {
    DrawingTool.pencil: ToolConfig.configs[DrawingTool.pencil]!.opacity,
    DrawingTool.pen: ToolConfig.configs[DrawingTool.pen]!.opacity,
    DrawingTool.marker: ToolConfig.configs[DrawingTool.marker]!.opacity,
    DrawingTool.eraser: ToolConfig.configs[DrawingTool.eraser]!.opacity,
    DrawingTool.brush: ToolConfig.configs[DrawingTool.brush]!.opacity,
  };
  final Map<DrawingTool, Color> _toolColors = {
    DrawingTool.pencil: Colors.black,
    DrawingTool.pen: Colors.black,
    DrawingTool.marker: Colors.black,
    DrawingTool.eraser: Colors.transparent,
    DrawingTool.brush: Colors.black,
  };
  DateTime _lastPointTime = DateTime.now();
  Offset _lastOffset = Offset.zero;

  // Zoom & pan state (applies to entire scene via InteractiveViewer)
  final TransformationController transformationController =
      TransformationController();

  double get zoomScale => transformationController.value.getMaxScaleOnAxis();

  void resetZoom() {
    transformationController.value = Matrix4.identity();
    update();
  }

  @override
  void onInit() {
    super.onInit();
    // History is initialized in constructor as well for cases
    // where onInit is not triggered (e.g., direct instantiation in tests).
  }

  @override
  void onClose() {
    transformationController.dispose();
    super.onClose();
  }

  // Tool management
  void setTool(DrawingTool tool) {
    currentTool.value = tool;
    final config = ToolConfig.configs[tool]!;

    // Update tool-specific settings
    // Apply stored per-tool opacity/size
    toolOpacity.value = _toolOpacities[tool] ?? config.opacity;
    brushSize.value = (_toolSizes[tool] ?? brushSize.value)
        .clamp(config.minWidth, config.maxWidth);

    // Apply per-tool color memory (default black). Do not change for eraser.
    if (tool != DrawingTool.eraser) {
      currentColor.value = _toolColors[tool] ?? currentColor.value;
    }

    update();
  }

  void setBrushMode(BrushMode? mode) {
    currentBrushMode.value = mode;
    if (_currentPoints.isNotEmpty) {
      _updateCurrentStroke();
    }
    update();
  }

  void setStylusOnlyMode(bool enabled) {
    stylusOnlyMode.value = enabled;
    update();
  }

  void setCalligraphyNibAngle(double degrees) {
    calligraphyNibAngleDeg.value = degrees.clamp(0.0, 90.0);
    if (_currentPoints.isNotEmpty) _updateCurrentStroke();
    update();
  }

  void setCalligraphyNibWidthFactor(double factor) {
    calligraphyNibWidthFactor.value = factor.clamp(0.3, 2.5);
    if (_currentPoints.isNotEmpty) _updateCurrentStroke();
    update();
  }

  void setPastelGrainDensity(double density) {
    pastelGrainDensity.value = density.clamp(0.3, 3.0);
    if (_currentPoints.isNotEmpty) _updateCurrentStroke();
    update();
  }

  void setBrushSize(double size) {
    final config = ToolConfig.configs[currentTool.value]!;
    brushSize.value = size.clamp(config.minWidth, config.maxWidth);
    _toolSizes[currentTool.value] = brushSize.value;
    update();
  }

  void setColor(Color color) {
    if (currentTool.value != DrawingTool.eraser) {
      currentColor.value = color;
      _toolColors[currentTool.value] = color;
      update();
    }
  }

  void setOpacity(double opacity) {
    toolOpacity.value = opacity.clamp(0.0, 1.0);
    _toolOpacities[currentTool.value] = toolOpacity.value;
    if (_currentPoints.isNotEmpty) {
      _updateCurrentStroke();
    }
    update();
  }

  // Drawing methods
  void startStroke(Offset point, double pressure,
      {double tiltX = 0.0, double tiltY = 0.0}) {
    // Phase 3: Error boundary for stroke creation
    try {
      _currentPoints = [];
      final drawingPoint = DrawingPoint(
        offset: point,
        pressure: pressure,
        timestamp: DateTime.now().millisecondsSinceEpoch.toDouble(),
        tiltX: tiltX,
        tiltY: tiltY,
      );

      _currentPoints.add(drawingPoint);
      _lastOffset = point;
      _lastPointTime = DateTime.now();
      _lastVelocity = 0.0;

      // Initialize current stroke immediately for real-time preview
      _updateCurrentStroke();

      update();
    } catch (e) {
      debugPrint('Stroke creation failed: $e');
      // Graceful recovery: reset drawing state
      _currentStroke = null;
      _currentPoints = [];

      Get.snackbar(
        'Drawing Error',
        'Failed to start stroke. Please try again.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    }
  }

  void addPoint(Offset point, double pressure,
      {double tiltX = 0.0, double tiltY = 0.0}) {
    // Phase 3: Error boundary for point addition
    try {
      if (_currentPoints.isEmpty) return;

      final now = DateTime.now();
      final timeDelta = now.difference(_lastPointTime).inMilliseconds;
      final distance = (point - _lastOffset).distance;

      // Calculate velocity for dynamic sizing
      double velocity = 0.0;
      if (timeDelta > 0) {
        velocity = distance / timeDelta;
        _lastVelocity = velocity;
      }

      final drawingPoint = DrawingPoint(
        offset: point,
        pressure: pressure,
        timestamp: now.millisecondsSinceEpoch.toDouble(),
        tiltX: tiltX,
        tiltY: tiltY,
      );

      _currentPoints.add(drawingPoint);
      _lastOffset = point;
      _lastPointTime = now;

      // Create temporary stroke for real-time preview
      _updateCurrentStroke();
      update();
    } catch (e) {
      debugPrint('Point addition failed: $e');
      // Continue drawing if possible, don't crash the entire stroke
      // Just skip this point and continue
    }
  }

  void endStroke() {
    // Phase 3: Error boundary for stroke completion
    try {
      if (_currentPoints.isEmpty) return;

      // Smooth the final stroke
      final smoothedPoints = _smoothPoints(_currentPoints);

      final config = ToolConfig.configs[currentTool.value]!;
      final finalStroke = Stroke(
        points: smoothedPoints,
        color: currentTool.value == DrawingTool.eraser
            ? Colors.transparent
            : currentColor.value,
        width: _calculateDynamicWidth(),
        tool: currentTool.value,
        opacity: toolOpacity.value,
        blendMode: config.blendMode,
        isEraser: currentTool.value == DrawingTool.eraser,
        brushMode: currentTool.value == DrawingTool.brush
            ? currentBrushMode.value
            : null,
        calligraphyNibAngleDeg: calligraphyNibAngleDeg.value,
        calligraphyNibWidthFactor: calligraphyNibWidthFactor.value,
        pastelGrainDensity: pastelGrainDensity.value,
      );

      strokes.add(finalStroke);
      _currentStroke = null;
      _currentPoints = [];

      // Phase 4: Periodic cache optimization every 20 strokes
      if (strokes.length % 20 == 0) {
        SketchPainter.optimizeCaches();
      }

      _saveToHistory();
      update();
    } catch (e) {
      debugPrint('Stroke completion failed: $e');
      // Graceful recovery: clean up current stroke state
      _currentStroke = null;
      _currentPoints = [];

      Get.snackbar(
        'Drawing Error',
        'Failed to complete stroke. Please try again.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );

      update(); // Ensure UI updates even on error
    }
  }

  void _updateCurrentStroke() {
    final config = ToolConfig.configs[currentTool.value]!;
    _currentStroke = Stroke(
      points: _currentPoints,
      color: currentTool.value == DrawingTool.eraser
          ? Colors.transparent
          : currentColor.value,
      width: _calculateDynamicWidth(),
      tool: currentTool.value,
      opacity: toolOpacity.value,
      blendMode: config.blendMode,
      isEraser: currentTool.value == DrawingTool.eraser,
      brushMode: currentTool.value == DrawingTool.brush
          ? currentBrushMode.value
          : null,
      calligraphyNibAngleDeg: calligraphyNibAngleDeg.value,
      calligraphyNibWidthFactor: calligraphyNibWidthFactor.value,
      pastelGrainDensity: pastelGrainDensity.value,
    );
  }

  double _calculateDynamicWidth() {
    final config = ToolConfig.configs[currentTool.value]!;
    double width = brushSize.value;

    if (_currentPoints.isNotEmpty) {
      final lastPoint = _currentPoints.last;

      // Apply pressure if supported
      if (config.supportsPressure) {
        width *= lastPoint.pressure;
      }

      // Apply velocity if supported
      if (config.supportsVelocity) {
        final velocityFactor = (1.0 - (_lastVelocity * 0.1).clamp(0.0, 0.5));
        width *= velocityFactor;
      }
    }

    return width.clamp(config.minWidth, config.maxWidth);
  }

  List<DrawingPoint> _smoothPoints(List<DrawingPoint> points) {
    if (points.length < 3) return points;

    final smoothed = <DrawingPoint>[];
    smoothed.add(points.first);

    for (int i = 1; i < points.length - 1; i++) {
      final prev = points[i - 1];
      final curr = points[i];
      final next = points[i + 1];

      // Simple averaging for smoothing
      final smoothedOffset = Offset(
        (prev.offset.dx + curr.offset.dx + next.offset.dx) / 3,
        (prev.offset.dy + curr.offset.dy + next.offset.dy) / 3,
      );

      smoothed.add(DrawingPoint(
        offset: smoothedOffset,
        pressure: curr.pressure,
        timestamp: curr.timestamp,
      ));
    }

    smoothed.add(points.last);
    return smoothed;
  }

  // Get current stroke for real-time preview
  Stroke? get currentStroke => _currentStroke;

  // Undo/Redo functionality
  void undo() {
    print('🔄 UNDO: Called - strokes.length = ${strokes.length}');
    if (strokes.isNotEmpty) {
      final removedStroke = strokes.last;
      strokes.removeLast();
      _currentStroke = null;
      _currentPoints = [];
      _lastVelocity = 0.0;

      // Phase 4: Enhanced cache cleanup for removed stroke
      SketchPainter.cleanupStrokeCaches(removedStroke);

      strokes.refresh(); // Force GetX observable update
      update();
    } else {}
  }

  void clear() {
    strokes.clear();
    _currentStroke = null;
    _currentPoints = [];
    _lastVelocity = 0.0;

    // Phase 4: Clear all caches completely
    SketchPainter.clearStrokeCache();
    SketchPainter.clearBoundsCache();

    _saveToHistory();
    update();
  }

  void _saveToHistory() {
    undoHistory.add(List<Stroke>.from(strokes));
    if (undoHistory.length > 50) {
      undoHistory.removeAt(0);
    }
  }

  // Background image management
  void setBackgroundImage(ImageProvider? image) {
    backgroundImage.value = image;
    // Reset anchored rect when image changes/removed
    imageRect.value = null;
    update();
  }

  void setImageOpacity(double opacity) {
    imageOpacity.value = opacity.clamp(0.0, 1.0);
    update();
  }

  void toggleImageVisibility() {
    isImageVisible.value = !isImageVisible.value;
    update();
  }

  // Tool-specific helper methods
  bool get isCurrentToolPressureSensitive =>
      ToolConfig.configs[currentTool.value]!.supportsPressure;

  bool get isCurrentToolVelocitySensitive =>
      ToolConfig.configs[currentTool.value]!.supportsVelocity;

  Color get effectiveColor {
    if (currentTool.value == DrawingTool.eraser) {
      return Colors.transparent;
    }
    return currentColor.value.withOpacity(toolOpacity.value);
  }
}
