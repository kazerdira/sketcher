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

  // Brush
  final selectedColor = const Color(0xFFFF0000).obs; // red default
  final brushSize = 4.0.obs;
  final pressureSimEnabled = true.obs;

  // View transform
  final scale = 1.0.obs;
  final offset = Offset.zero.obs;

  // UI flags
  final controlsVisible = true.obs;
  final exporting = false.obs;

  final ImagePicker _picker = ImagePicker();

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
    currentStroke = Stroke(
      color: selectedColor.value,
      width: brushSize.value,
      points: [point],
      pressures: pressureSimEnabled.value ? [1.0] : const [],
    );
    update();
  }

  void appendPoint(Offset point, {double velocity = 0}) {
    if (currentStroke == null) return;
    currentStroke!.points.add(point);
    if (pressureSimEnabled.value && currentStroke!.pressures.isNotEmpty) {
      final v = velocity.clamp(0, 5000);
      final pressure = (1.0 - (v / 5000)).clamp(0.3, 1.0);
      currentStroke!.pressures.add(pressure);
    }
    update();
  }

  void endStroke() {
    final s = currentStroke;
    if (s == null) return;
    strokes.add(_maybeSmooth(s));
    currentStroke = null;
    update();
  }

  Stroke _maybeSmooth(Stroke stroke) {
    if (stroke.points.length < 3) return stroke;
    final pts = stroke.points;
    final prs = stroke.pressures;
    final outPts = <Offset>[pts.first];
    final outPrs = <double>[];
    if (prs.isNotEmpty) outPrs.add(prs.first);
    for (var i = 1; i < pts.length - 1; i++) {
      final p = Offset(
        (pts[i - 1].dx + pts[i].dx + pts[i + 1].dx) / 3,
        (pts[i - 1].dy + pts[i].dy + pts[i + 1].dy) / 3,
      );
      outPts.add(p);
      if (prs.isNotEmpty && i < prs.length - 1) {
        outPrs.add((prs[i - 1] + prs[i] + prs[i + 1]) / 3);
      }
    }
    outPts.add(pts.last);
    if (prs.isNotEmpty) outPrs.add(prs.last);
    return Stroke(
      color: stroke.color,
      width: stroke.width,
      points: outPts,
      pressures: prs.isEmpty ? const [] : outPrs,
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
