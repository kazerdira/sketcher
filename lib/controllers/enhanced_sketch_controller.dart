import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/drawing_tool.dart';
import '../models/enhanced_stroke.dart';

class EnhancedSketchController extends ChangeNotifier {
  List<EnhancedStroke> _strokes = [];
  List<EnhancedStroke> _undoStack = [];
  EnhancedStroke? _currentStroke;
  ToolSettings _currentToolSettings = ToolPresets.pencil;

  // Performance optimization
  static const int _maxUndoSteps = 50;
  static const double _velocitySmoothing = 0.8;
  static const double _pressureSmoothing = 0.7;

  // Velocity tracking
  Offset? _lastPosition;
  DateTime? _lastTime;
  double _currentVelocity = 0.0;
  double _smoothedPressure = 1.0;

  // Getters
  List<EnhancedStroke> get strokes => List.unmodifiable(_strokes);
  EnhancedStroke? get currentStroke => _currentStroke;
  ToolSettings get currentToolSettings => _currentToolSettings;
  bool get canUndo => _strokes.isNotEmpty;
  bool get canRedo => _undoStack.isNotEmpty;
  bool get hasStrokes => _strokes.isNotEmpty;
  double get currentVelocity => _currentVelocity;

  // Tool management
  void setTool(DrawingTool tool) {
    switch (tool) {
      case DrawingTool.pencil:
        _currentToolSettings = ToolPresets.pencil;
        break;
      case DrawingTool.pen:
        _currentToolSettings = ToolPresets.pen;
        break;
      case DrawingTool.marker:
        _currentToolSettings = ToolPresets.marker;
        break;
      case DrawingTool.eraser:
        _currentToolSettings = ToolPresets.eraser;
        break;
      case DrawingTool.brush:
        _currentToolSettings = ToolPresets.brush;
        break;
    }
    notifyListeners();
  }

  void updateToolSettings(ToolSettings settings) {
    _currentToolSettings = settings;
    notifyListeners();
  }

  void updateToolProperty<T>(String property, T value) {
    switch (property) {
      case 'size':
        _currentToolSettings = _currentToolSettings.copyWith(
          size: value as double,
        );
        break;
      case 'opacity':
        _currentToolSettings = _currentToolSettings.copyWith(
          opacity: value as double,
        );
        break;
      case 'flow':
        _currentToolSettings = _currentToolSettings.copyWith(
          flow: value as double,
        );
        break;
      case 'hardness':
        _currentToolSettings = _currentToolSettings.copyWith(
          hardness: value as double,
        );
        break;
      case 'spacing':
        _currentToolSettings = _currentToolSettings.copyWith(
          spacing: value as double,
        );
        break;
      case 'color':
        _currentToolSettings = _currentToolSettings.copyWith(
          color: value as Color,
        );
        break;
      case 'pressureSensitive':
        _currentToolSettings = _currentToolSettings.copyWith(
          pressureSensitive: value as bool,
        );
        break;
      case 'antiAlias':
        _currentToolSettings = _currentToolSettings.copyWith(
          antiAlias: value as bool,
        );
        break;
    }
    notifyListeners();
  }

  // Stroke management
  void startStroke(
    Offset position, {
    double pressure = 1.0,
    double tilt = 0.0,
  }) {
    _clearRedoStack();
    _lastPosition = position;
    _lastTime = DateTime.now();
    _currentVelocity = 0.0;
    _smoothedPressure = pressure;

    final point = StrokePoint(
      position: position,
      pressure: pressure,
      timestamp: _lastTime!.millisecondsSinceEpoch.toDouble(),
      velocity: 0.0,
      tilt: tilt,
      size: _currentToolSettings.size,
      opacity: _currentToolSettings.opacity,
    );

    _currentStroke = EnhancedStroke(
      points: [point],
      toolSettings: _currentToolSettings,
      id: _generateStrokeId(),
      createdAt: _lastTime!,
    );

    notifyListeners();
  }

  void addPoint(Offset position, {double pressure = 1.0, double tilt = 0.0}) {
    if (_currentStroke == null || _lastPosition == null || _lastTime == null)
      return;

    final now = DateTime.now();
    final timeDelta = now.difference(_lastTime!).inMicroseconds / 1000000.0;

    if (timeDelta <= 0) return;

    // Calculate velocity
    final distance = (position - _lastPosition!).distance;
    final instantVelocity = distance / timeDelta;
    _currentVelocity = (_currentVelocity * _velocitySmoothing) +
        (instantVelocity * (1.0 - _velocitySmoothing));

    // Smooth pressure
    _smoothedPressure = (_smoothedPressure * _pressureSmoothing) +
        (pressure * (1.0 - _pressureSmoothing));

    // Check spacing
    if (_shouldAddPoint(position, distance)) {
      final point = StrokePoint(
        position: position,
        pressure: _smoothedPressure,
        timestamp: now.millisecondsSinceEpoch.toDouble(),
        velocity: _currentVelocity,
        tilt: tilt,
        size: _currentToolSettings.size * _smoothedPressure,
        opacity: _currentToolSettings.opacity,
      );

      _currentStroke = _currentStroke!.copyWith(
        points: [..._currentStroke!.points, point],
      );

      _lastPosition = position;
      _lastTime = now;
      notifyListeners();
    }
  }

  bool _shouldAddPoint(Offset position, double distance) {
    if (_currentStroke!.points.isEmpty) return true;

    // Ensure a minimal spacing threshold so tiny tools still add points
    final raw = _currentToolSettings.spacing * _currentToolSettings.size;
    final minDistance = raw.clamp(0.5, double.infinity);
    return distance >= minDistance;
  }

  void endStroke() {
    if (_currentStroke == null || _currentStroke!.points.isEmpty) {
      _currentStroke = null;
      return;
    }

    // Optimize stroke for performance
    final optimizedStroke = _optimizeStroke(_currentStroke!);
    _strokes.add(optimizedStroke);
    _currentStroke = null;

    _lastPosition = null;
    _lastTime = null;
    _currentVelocity = 0.0;

    notifyListeners();
  }

  EnhancedStroke _optimizeStroke(EnhancedStroke stroke) {
    // Remove redundant points for performance
    if (stroke.points.length <= 2) return stroke;

    final optimizedPoints = <StrokePoint>[stroke.points.first];

    for (int i = 1; i < stroke.points.length - 1; i++) {
      final prev = stroke.points[i - 1];
      final current = stroke.points[i];
      final next = stroke.points[i + 1];

      // Keep point if it significantly changes direction or pressure
      final angle1 = math.atan2(
        current.position.dy - prev.position.dy,
        current.position.dx - prev.position.dx,
      );
      final angle2 = math.atan2(
        next.position.dy - current.position.dy,
        next.position.dx - current.position.dx,
      );
      final angleDiff = (angle2 - angle1).abs();
      final pressureDiff = (current.pressure - prev.pressure).abs();

      if (angleDiff > 0.1 || pressureDiff > 0.05) {
        optimizedPoints.add(current);
      }
    }

    optimizedPoints.add(stroke.points.last);

    return stroke.copyWith(points: optimizedPoints);
  }

  // Undo/Redo functionality
  void undo() {
    if (!canUndo) return;

    final lastStroke = _strokes.removeLast();
    _undoStack.add(lastStroke);

    // Limit undo stack size
    if (_undoStack.length > _maxUndoSteps) {
      _undoStack.removeAt(0);
    }

    notifyListeners();
  }

  void redo() {
    if (!canRedo) return;

    final stroke = _undoStack.removeLast();
    _strokes.add(stroke);
    notifyListeners();
  }

  void _clearRedoStack() {
    if (_undoStack.isNotEmpty) {
      _undoStack.clear();
    }
  }

  // Canvas management
  void clear() {
    if (_strokes.isNotEmpty) {
      _undoStack.addAll(_strokes);
      _strokes.clear();
      _currentStroke = null;

      // Limit undo stack
      if (_undoStack.length > _maxUndoSteps) {
        _undoStack.removeRange(0, _undoStack.length - _maxUndoSteps);
      }

      notifyListeners();
    }
  }

  void clearAll() {
    _strokes.clear();
    _undoStack.clear();
    _currentStroke = null;
    notifyListeners();
  }

  // Import/Export functionality
  void setStrokes(List<EnhancedStroke> strokes) {
    _strokes = List.from(strokes);
    _undoStack.clear();
    _currentStroke = null;
    notifyListeners();
  }

  void addStroke(EnhancedStroke stroke) {
    _clearRedoStack();
    _strokes.add(stroke);
    notifyListeners();
  }

  void removeStroke(String strokeId) {
    _clearRedoStack();
    final index = _strokes.indexWhere((s) => s.id == strokeId);
    if (index != -1) {
      final removedStroke = _strokes.removeAt(index);
      _undoStack.add(removedStroke);
      notifyListeners();
    }
  }

  // Statistics and analytics
  Map<String, dynamic> getDrawingStatistics() {
    if (_strokes.isEmpty) {
      return {
        'totalStrokes': 0,
        'totalPoints': 0,
        'totalDrawingTime': 0.0,
        'averageStrokeLength': 0.0,
        'toolUsage': <String, int>{},
      };
    }

    final toolUsage = <String, int>{};
    int totalPoints = 0;
    double totalLength = 0.0;
    Duration totalTime = Duration.zero;

    for (final stroke in _strokes) {
      final toolName = stroke.toolSettings.tool.toString().split('.').last;
      toolUsage[toolName] = (toolUsage[toolName] ?? 0) + 1;

      totalPoints += stroke.points.length;
      totalLength += stroke.statistics['length'] ?? 0.0;

      if (stroke.points.length >= 2) {
        final startTime = stroke.points.first.timestamp;
        final endTime = stroke.points.last.timestamp;
        final strokeDurationMs = endTime - startTime;
        totalTime += Duration(milliseconds: strokeDurationMs.round());
      }
    }

    return {
      'totalStrokes': _strokes.length,
      'totalPoints': totalPoints,
      'totalDrawingTime': totalTime.inSeconds.toDouble(),
      'averageStrokeLength': totalLength / _strokes.length,
      'toolUsage': toolUsage,
      'averagePointsPerStroke': totalPoints / _strokes.length,
    };
  }

  // Memory management
  void optimizeMemory() {
    // Remove very short strokes that might be accidental
    _strokes.removeWhere(
      (stroke) =>
          stroke.points.length < 2 ||
          (stroke.statistics['length'] ?? 0.0) < 5.0,
    );

    // Limit total stroke count
    const maxStrokes = 1000;
    if (_strokes.length > maxStrokes) {
      _strokes.removeRange(0, _strokes.length - maxStrokes);
    }

    notifyListeners();
  }

  // Utility methods
  String _generateStrokeId() {
    return 'stroke_${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(10000)}';
  }

  Rect? getBounds() {
    if (_strokes.isEmpty) return null;

    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    for (final stroke in _strokes) {
      final bounds = stroke.bounds;
      if (bounds != null) {
        minX = math.min(minX, bounds.left);
        minY = math.min(minY, bounds.top);
        maxX = math.max(maxX, bounds.right);
        maxY = math.max(maxY, bounds.bottom);
      }
    }

    if (minX == double.infinity) return null;

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  @override
  void dispose() {
    _strokes.clear();
    _undoStack.clear();
    _currentStroke = null;
    super.dispose();
  }
}
