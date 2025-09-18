import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;
import '../controllers/enhanced_sketch_controller.dart';
import '../painters/professional_sketch_painter.dart';

class EnhancedCanvasWidget extends StatefulWidget {
  final EnhancedSketchController controller;
  final ui.Image? backgroundImage;
  final bool showImage;
  final double imageOpacity;
  final bool enableZoom;
  final bool enablePan;
  final double minScale;
  final double maxScale;
  final VoidCallback? onCanvasTap;
  final Function(Offset)? onCanvasLongPress;
  final EnhancedCanvasController? externalController;

  const EnhancedCanvasWidget({
    super.key,
    required this.controller,
    this.backgroundImage,
    this.showImage = true,
    this.imageOpacity = 0.5,
    this.enableZoom = true,
    this.enablePan = true,
    this.minScale = 0.5,
    this.maxScale = 5.0,
    this.onCanvasTap,
    this.onCanvasLongPress,
    this.externalController,
  });

  @override
  State<EnhancedCanvasWidget> createState() => _EnhancedCanvasWidgetState();
}

/// Public controller to access canvas utilities from outside the widget
class EnhancedCanvasController {
  _EnhancedCanvasWidgetState? _state;

  bool get isAttached => _state != null;

  Future<ui.Image?> captureImage({double pixelRatio = 3.0}) async {
    return _state?._captureCanvas(pixelRatio: pixelRatio);
  }

  void resetZoom() => _state?.resetZoom();
  void zoomToFit() => _state?.zoomToFit();
  void centerCanvas() => _state?.centerCanvas();
  void zoomIn() => _state?.zoomIn();
  void zoomOut() => _state?.zoomOut();

  double get currentScale => _state?.currentScale ?? 1.0;
}

class _EnhancedCanvasWidgetState extends State<EnhancedCanvasWidget>
    with TickerProviderStateMixin {
  final TransformationController _transformationController =
      TransformationController();

  // Canvas state
  Size _canvasSize = Size.zero;
  bool _isDrawing = false;

  // Performance optimization
  bool _shouldOptimizePerformance = false;

  // Gesture tracking
  final Map<int, Offset> _activePointers = {};

  @override
  void initState() {
    super.initState();
    _transformationController.addListener(_onTransformationChanged);
    // Attach external controller if provided
    widget.externalController?._state = this;
    // Rebuild canvas when controller updates (points added, tool changes, etc.)
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    _transformationController.removeListener(_onTransformationChanged);
    _transformationController.dispose();
    // Detach controller on dispose
    if (widget.externalController?._state == this) {
      widget.externalController?._state = null;
    }
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant EnhancedCanvasWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
    }
    if (oldWidget.externalController != widget.externalController) {
      oldWidget.externalController?._state = null;
      widget.externalController?._state = this;
    }
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  void _onTransformationChanged() {
    // Handle transformation changes if needed
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _canvasSize = constraints.biggest;

        return ClipRect(
          child: Stack(
            children: [
              // Main drawing canvas
              _buildDrawingCanvas(),

              // Performance indicator
              if (_shouldOptimizePerformance) _buildPerformanceIndicator(),

              // Debug info (only in debug mode)
              if (kDebugMode) _buildDebugInfo(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDrawingCanvas() {
    return InteractiveViewer(
      transformationController: _transformationController,
      minScale: widget.minScale,
      maxScale: widget.maxScale,
      panEnabled: widget.enablePan && !_isDrawing,
      scaleEnabled: widget.enableZoom && !_isDrawing,
      onInteractionStart: _onInteractionStart,
      onInteractionUpdate: _onInteractionUpdate,
      onInteractionEnd: _onInteractionEnd,
      child: GestureDetector(
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        child: Container(
          width: _canvasSize.width,
          height: _canvasSize.height,
          child: CustomPaint(
            painter: ProfessionalSketchPainter(
              strokes: widget.controller.strokes,
              currentStroke: widget.controller.currentStroke,
              backgroundImage: widget.backgroundImage,
              imageOpacity: widget.imageOpacity,
              showImage: widget.showImage,
              canvasSize: _canvasSize,
            ),
            size: _canvasSize,
          ),
        ),
      ),
    );
  }

  Widget _buildPerformanceIndicator() {
    return Positioned(
      top: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.8),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text(
          'Optimizing...',
          style: TextStyle(color: Colors.white, fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildDebugInfo() {
    return Positioned(
      bottom: 16,
      left: 16,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Strokes: ${widget.controller.strokes.length}',
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
            Text(
              'Tool: ${widget.controller.currentToolSettings.tool.toString().split('.').last}',
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
            Text(
              'Velocity: ${widget.controller.currentVelocity.toStringAsFixed(1)}',
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
            Text(
              'Scale: ${_transformationController.value.getMaxScaleOnAxis().toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  void _onInteractionStart(ScaleStartDetails details) {
    // Handle zoom/pan start
    if (_activePointers.length <= 1) {
      _isDrawing = false;
    }
  }

  void _onInteractionUpdate(ScaleUpdateDetails details) {
    // Handle zoom/pan update - InteractiveViewer handles this automatically
  }

  void _onInteractionEnd(ScaleEndDetails details) {
    // Handle zoom/pan end
    _isDrawing = false;
  }

  void _onPanStart(DragStartDetails details) {
    if (_activePointers.isEmpty) {
      _isDrawing = true;

      final localPosition = details.localPosition;
      final pressure = 1.0; // Default pressure for touch/mouse
      final tilt = 0.0; // Default tilt

      widget.controller.startStroke(
        localPosition,
        pressure: pressure,
        tilt: tilt,
      );

      // Provide haptic feedback for drawing start
      HapticFeedback.lightImpact();
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_isDrawing) {
      final localPosition = details.localPosition;
      final pressure = 1.0; // Default pressure for touch/mouse
      final tilt = 0.0; // Default tilt

      widget.controller.addPoint(localPosition, pressure: pressure, tilt: tilt);

      _checkPerformanceOptimization();
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (_isDrawing) {
      widget.controller.endStroke();
      _isDrawing = false;

      // Provide haptic feedback for drawing end
      HapticFeedback.selectionClick();
    }
  }

  void _checkPerformanceOptimization() {
    // Monitor performance and enable optimization if needed
    final strokeCount = widget.controller.strokes.length;
    final currentStrokePoints =
        widget.controller.currentStroke?.points.length ?? 0;

    final shouldOptimize = strokeCount > 100 || currentStrokePoints > 1000;

    if (shouldOptimize != _shouldOptimizePerformance) {
      setState(() {
        _shouldOptimizePerformance = shouldOptimize;
      });

      if (shouldOptimize) {
        // Trigger memory optimization
        widget.controller.optimizeMemory();
      }
    }
  }

  // Public methods for canvas control
  void resetZoom() {
    _transformationController.value = Matrix4.identity();
  }

  void zoomToFit() {
    final bounds = widget.controller.getBounds();
    if (bounds != null) {
      final canvasRect = Rect.fromLTWH(
        0,
        0,
        _canvasSize.width,
        _canvasSize.height,
      );
      final scaleX = canvasRect.width / bounds.width;
      final scaleY = canvasRect.height / bounds.height;
      final scale =
          (scaleX < scaleY ? scaleX : scaleY) * 0.9; // 90% to add padding

      final centerX = (canvasRect.width - bounds.width * scale) / 2;
      final centerY = (canvasRect.height - bounds.height * scale) / 2;

      _transformationController.value = Matrix4.identity()
        ..translate(centerX - bounds.left * scale, centerY - bounds.top * scale)
        ..scale(scale);
    }
  }

  void centerCanvas() {
    final bounds = widget.controller.getBounds();
    if (bounds != null) {
      final currentScale = _transformationController.value.getMaxScaleOnAxis();
      final centerX = (_canvasSize.width - bounds.width * currentScale) / 2;
      final centerY = (_canvasSize.height - bounds.height * currentScale) / 2;

      _transformationController.value = Matrix4.identity()
        ..translate(
          centerX - bounds.left * currentScale,
          centerY - bounds.top * currentScale,
        )
        ..scale(currentScale);
    }
  }

  void zoomIn() {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    final newScale = (currentScale * 1.5).clamp(
      widget.minScale,
      widget.maxScale,
    );

    if (newScale != currentScale) {
      final center = Offset(_canvasSize.width / 2, _canvasSize.height / 2);
      _transformationController.value = Matrix4.identity()
        ..translate(center.dx, center.dy)
        ..scale(newScale)
        ..translate(-center.dx, -center.dy);
    }
  }

  void zoomOut() {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    final newScale = (currentScale / 1.5).clamp(
      widget.minScale,
      widget.maxScale,
    );

    if (newScale != currentScale) {
      final center = Offset(_canvasSize.width / 2, _canvasSize.height / 2);
      _transformationController.value = Matrix4.identity()
        ..translate(center.dx, center.dy)
        ..scale(newScale)
        ..translate(-center.dx, -center.dy);
    }
  }

  // Getters for current state
  double get currentScale =>
      _transformationController.value.getMaxScaleOnAxis();
  Offset get currentTranslation {
    final transform = _transformationController.value;
    return Offset(transform.getTranslation().x, transform.getTranslation().y);
  }

  bool get isDrawing => _isDrawing;
  Size get canvasSize => _canvasSize;

  // Render to image for export
  Future<ui.Image?> _captureCanvas({double pixelRatio = 3.0}) async {
    if (_canvasSize.isEmpty) return null;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Paint using the same painter used by CustomPaint
    final painter = ProfessionalSketchPainter(
      strokes: widget.controller.currentStroke != null
          ? [
              ...widget.controller.strokes,
              widget.controller.currentStroke!,
            ]
          : widget.controller.strokes,
      backgroundImage: widget.backgroundImage,
      imageOpacity: widget.imageOpacity,
      showImage: widget.showImage,
      canvasSize: _canvasSize,
    );
    painter.paint(canvas, _canvasSize);
    final picture = recorder.endRecording();
    final image = await picture.toImage(
      (_canvasSize.width * pixelRatio).toInt(),
      (_canvasSize.height * pixelRatio).toInt(),
    );
    return image;
  }
}

// Extension to add utility methods to Matrix4
extension Matrix4Utils on Matrix4 {
  Offset getTranslation() {
    return Offset(entry(0, 3), entry(1, 3));
  }

  double getMaxScaleOnAxis() {
    final scaleX = math.sqrt(
      entry(0, 0) * entry(0, 0) + entry(1, 0) * entry(1, 0),
    );
    final scaleY = math.sqrt(
      entry(0, 1) * entry(0, 1) + entry(1, 1) * entry(1, 1),
    );
    return scaleX > scaleY ? scaleX : scaleY;
  }
}
