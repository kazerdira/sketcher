import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../models/stroke.dart';
import '../image_exporter.dart';

/// Controller handling sketch state using GetX reactive variables.
class SketchController extends GetxController {
  // Image layer
  final baseImageFile = Rxn<File>();
  final imageOpacity = 0.6.obs;
  final savedOpacityBeforeHide = 0.6.obs;
  final imageVisible = true.obs;

  // Drawing state
  final strokes = <Stroke>[].obs;
  final undoHistory = <List<Stroke>>[].obs;
  Stroke? currentStroke;

  // Brush settings
  final currentBrushSettings = BrushSettings.pencil().obs;
  final pressureSimEnabled = true.obs;

  // View transform
  final scale = 1.0.obs;
  final offset = Offset.zero.obs;

  // UI flags
  final controlsVisible = true.obs;
  final exporting = false.obs;

  final ImagePicker _picker = ImagePicker();

  // Current stroke tracking
  final List<StrokePoint> _currentStrokePoints = [];
  DateTime _lastInputTime = DateTime.now();

  // Computed properties for backward compatibility
  Color get selectedColor => currentBrushSettings.value.color;
  double get brushSize => currentBrushSettings.value.size;
  BrushType get selectedBrushType => currentBrushSettings.value.type;

  // Palette
  List<Color> get palette => _paletteColors;

  static final List<Color> _paletteColors = [
    const Color(0xFF000000),
    const Color(0xFF616161),
    const Color(0xFFFF1744),
    const Color(0xFFF50057),
    const Color(0xFFFF9100),
    const Color(0xFFFFC400),
    const Color(0xFFFFFF00),
    const Color(0xFF00C853),
    const Color(0xFF00897B),
    const Color(0xFF00BCD4),
    const Color(0xFF2962FF),
    const Color(0xFF3D5AFE),
    const Color(0xFF651FFF),
    const Color(0xFF795548),
    const Color(0xFFFFFFFF),
  ];

  Future<void> pickImage() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      baseImageFile.value = File(picked.path);
      scale.value = 1.0;
      offset.value = Offset.zero;
    }
  }

  void startStroke(Offset point) {
    _snapshotUndo();
    _currentStrokePoints.clear();

    final now = DateTime.now();
    final strokePoint = StrokePoint(
      position: point,
      pressure: 1.0,
      timestamp: now.millisecondsSinceEpoch.toDouble(),
    );

    _currentStrokePoints.add(strokePoint);
    _lastInputTime = now;

    currentStroke = Stroke(
      points: List.from(_currentStrokePoints),
      brushSettings: currentBrushSettings.value,
    );
    update();
  }

  void appendPoint(Offset point, {double velocity = 0}) {
    if (currentStroke == null) return;

    final now = DateTime.now();

    // Calculate pressure based on velocity if pressure simulation is enabled
    double pressure = 1.0;
    if (pressureSimEnabled.value &&
        currentBrushSettings.value.pressureSensitive) {
      final v = velocity.clamp(0, 5000);
      pressure = (1.0 - (v / 5000)).clamp(0.3, 1.0);
    }

    final strokePoint = StrokePoint(
      position: point,
      pressure: pressure,
      timestamp: now.millisecondsSinceEpoch.toDouble(),
      velocity: velocity,
    );

    _currentStrokePoints.add(strokePoint);
    _lastInputTime = now;

    currentStroke = Stroke(
      points: List.from(_currentStrokePoints),
      brushSettings: currentBrushSettings.value,
    );
    update();
  }

  void endStroke() {
    final stroke = currentStroke;
    if (stroke == null || stroke.points.isEmpty) return;

    strokes.add(stroke);
    currentStroke = null;
    _currentStrokePoints.clear();
    update();
  }

  // Method to change brush type (for backward compatibility)
  void selectBrushType(BrushType brushType) {
    BrushSettings newSettings;

    switch (brushType) {
      case BrushType.pencil:
        newSettings = BrushSettings.pencil(
          size: brushSize,
          color: selectedColor,
        );
        break;
      case BrushType.pen:
        newSettings = BrushSettings.pen(size: brushSize, color: selectedColor);
        break;
      case BrushType.marker:
        newSettings = BrushSettings.marker(
          size: brushSize,
          color: selectedColor,
        );
        break;
      case BrushType.eraser:
        newSettings = BrushSettings.eraser(size: brushSize);
        break;
      default:
        newSettings = BrushSettings.pencil(
          size: brushSize,
          color: selectedColor,
        );
    }

    currentBrushSettings.value = newSettings;
  }

  // Method to change brush size
  void setBrushSize(double size) {
    currentBrushSettings.value = currentBrushSettings.value.copyWith(
      size: size,
    );
  }

  // Method to change brush color
  void setBrushColor(Color color) {
    currentBrushSettings.value = currentBrushSettings.value.copyWith(
      color: color,
    );
  }

  void undo() {
    if (undoHistory.isNotEmpty) {
      strokes
        ..clear()
        ..addAll(undoHistory.removeLast());
      update();
    }
  }

  void clear() {
    if (strokes.isNotEmpty) {
      strokes.clear();
      update();
    }
  }

  void toggleImageVisibility() {
    if (imageVisible.value) {
      savedOpacityBeforeHide.value = imageOpacity.value;
      imageOpacity.value = 0.0;
      imageVisible.value = false;
    } else {
      imageOpacity.value = savedOpacityBeforeHide.value;
      imageVisible.value = true;
    }
  }

  void resetView() {
    scale.value = 1.0;
    offset.value = Offset.zero;
  }

  /// Get the current brush type's size constraints (for backward compatibility)
  double get minBrushSize => currentBrushSettings.value.minSize;
  double get maxBrushSize => currentBrushSettings.value.maxSize;

  /// Check if pressure simulation is supported by current brush
  bool get isPressureSupported => currentBrushSettings.value.pressureSensitive;

  Future<bool> exportImage(ui.Image image) async {
    exporting.value = true;
    try {
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return false;
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/sketch_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(byteData.buffer.asUint8List());
      return await ImageExporter.saveToGallery(file.path);
    } finally {
      exporting.value = false;
    }
  }

  void _snapshotUndo() {
    undoHistory.add(List<Stroke>.from(strokes));
    if (undoHistory.length > 50) undoHistory.removeAt(0);
  }
}
