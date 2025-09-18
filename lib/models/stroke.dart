import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';

enum BrushType {
  pencil,
  pen,
  marker,
  eraser,
  highlighter,
  charcoal,
  watercolor,
}

extension BrushTypeExtension on BrushType {
  String get name {
    switch (this) {
      case BrushType.pencil:
        return 'Pencil';
      case BrushType.pen:
        return 'Pen';
      case BrushType.marker:
        return 'Marker';
      case BrushType.eraser:
        return 'Eraser';
      case BrushType.highlighter:
        return 'Highlighter';
      case BrushType.charcoal:
        return 'Charcoal';
      case BrushType.watercolor:
        return 'Watercolor';
    }
  }

  IconData get icon {
    switch (this) {
      case BrushType.pencil:
        return Icons.edit;
      case BrushType.pen:
        return Icons.create;
      case BrushType.marker:
        return Icons.brush;
      case BrushType.eraser:
        return Icons.clear;
      case BrushType.highlighter:
        return Icons.highlight;
      case BrushType.charcoal:
        return Icons.texture;
      case BrushType.watercolor:
        return Icons.water_drop;
    }
  }
}

enum BlendMode {
  normal,
  multiply,
  screen,
  overlay,
  softLight,
  hardLight,
  colorDodge,
  colorBurn,
  darken,
  lighten,
  difference,
  exclusion,
}

class StrokePoint {
  final Offset position;
  final double pressure;
  final double tiltX;
  final double tiltY;
  final double timestamp;
  final double velocity;
  final double distance;

  const StrokePoint({
    required this.position,
    this.pressure = 1.0,
    this.tiltX = 0.0,
    this.tiltY = 0.0,
    required this.timestamp,
    this.velocity = 0.0,
    this.distance = 0.0,
  });

  StrokePoint copyWith({
    Offset? position,
    double? pressure,
    double? tiltX,
    double? tiltY,
    double? timestamp,
    double? velocity,
    double? distance,
  }) {
    return StrokePoint(
      position: position ?? this.position,
      pressure: pressure ?? this.pressure,
      tiltX: tiltX ?? this.tiltX,
      tiltY: tiltY ?? this.tiltY,
      timestamp: timestamp ?? this.timestamp,
      velocity: velocity ?? this.velocity,
      distance: distance ?? this.distance,
    );
  }
}

class BrushSettings {
  final BrushType type;
  final double size;
  final Color color;
  final double opacity;
  final double hardness;
  final double spacing;
  final double scattering;
  final double angleJitter;
  final double sizeJitter;
  final double opacityJitter;
  final bool pressureSensitive;
  final bool velocitySensitive;
  final bool tiltSensitive;
  final BlendMode blendMode;
  final double minSize;
  final double maxSize;
  final double textureIntensity;

  const BrushSettings({
    required this.type,
    required this.size,
    required this.color,
    this.opacity = 1.0,
    this.hardness = 1.0,
    this.spacing = 0.25,
    this.scattering = 0.0,
    this.angleJitter = 0.0,
    this.sizeJitter = 0.0,
    this.opacityJitter = 0.0,
    this.pressureSensitive = true,
    this.velocitySensitive = true,
    this.tiltSensitive = false,
    this.blendMode = BlendMode.normal,
    this.minSize = 1.0,
    this.maxSize = 100.0,
    this.textureIntensity = 0.0,
  });

  BrushSettings copyWith({
    BrushType? type,
    double? size,
    Color? color,
    double? opacity,
    double? hardness,
    double? spacing,
    double? scattering,
    double? angleJitter,
    double? sizeJitter,
    double? opacityJitter,
    bool? pressureSensitive,
    bool? velocitySensitive,
    bool? tiltSensitive,
    BlendMode? blendMode,
    double? minSize,
    double? maxSize,
    double? textureIntensity,
  }) {
    return BrushSettings(
      type: type ?? this.type,
      size: size ?? this.size,
      color: color ?? this.color,
      opacity: opacity ?? this.opacity,
      hardness: hardness ?? this.hardness,
      spacing: spacing ?? this.spacing,
      scattering: scattering ?? this.scattering,
      angleJitter: angleJitter ?? this.angleJitter,
      sizeJitter: sizeJitter ?? this.sizeJitter,
      opacityJitter: opacityJitter ?? this.opacityJitter,
      pressureSensitive: pressureSensitive ?? this.pressureSensitive,
      velocitySensitive: velocitySensitive ?? this.velocitySensitive,
      tiltSensitive: tiltSensitive ?? this.tiltSensitive,
      blendMode: blendMode ?? this.blendMode,
      minSize: minSize ?? this.minSize,
      maxSize: maxSize ?? this.maxSize,
      textureIntensity: textureIntensity ?? this.textureIntensity,
    );
  }

  // Preset brush configurations
  static BrushSettings pencil({
    double size = 2.0,
    Color color = const Color(0xFF2C2C2C),
    double opacity = 0.8,
  }) {
    return BrushSettings(
      type: BrushType.pencil,
      size: size,
      color: color,
      opacity: opacity,
      hardness: 0.3,
      spacing: 0.1,
      scattering: 0.1,
      pressureSensitive: true,
      velocitySensitive: true,
      textureIntensity: 0.3,
      minSize: 0.5,
      maxSize: 20.0,
    );
  }

  static BrushSettings pen({
    double size = 1.5,
    Color color = const Color(0xFF000000),
    double opacity = 1.0,
  }) {
    return BrushSettings(
      type: BrushType.pen,
      size: size,
      color: color,
      opacity: opacity,
      hardness: 1.0,
      spacing: 0.05,
      pressureSensitive: false,
      velocitySensitive: false,
      minSize: 1.0,
      maxSize: 10.0,
    );
  }

  static BrushSettings marker({
    double size = 8.0,
    Color color = const Color(0xFF3498DB),
    double opacity = 0.6,
  }) {
    return BrushSettings(
      type: BrushType.marker,
      size: size,
      color: color,
      opacity: opacity,
      hardness: 0.7,
      spacing: 0.2,
      pressureSensitive: true,
      velocitySensitive: false,
      blendMode: BlendMode.multiply,
      minSize: 2.0,
      maxSize: 50.0,
    );
  }

  static BrushSettings eraser({double size = 10.0}) {
    return BrushSettings(
      type: BrushType.eraser,
      size: size,
      color: Colors.transparent,
      opacity: 1.0,
      hardness: 0.8,
      spacing: 0.1,
      pressureSensitive: true,
      minSize: 5.0,
      maxSize: 100.0,
    );
  }
}

class Stroke {
  final List<StrokePoint> points;
  final BrushSettings brushSettings;
  final String id;
  final DateTime createdAt;
  final Rect bounds;

  Stroke({
    required this.points,
    required this.brushSettings,
    String? id,
    DateTime? createdAt,
    Rect? bounds,
  }) : id = id ?? _generateId(),
       createdAt = createdAt ?? DateTime.now(),
       bounds = bounds ?? _calculateBounds(points, brushSettings.size);

  static String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        math.Random().nextInt(1000).toString();
  }

  static Rect _calculateBounds(List<StrokePoint> points, double brushSize) {
    if (points.isEmpty) return Rect.zero;

    double minX = points.first.position.dx;
    double maxX = points.first.position.dx;
    double minY = points.first.position.dy;
    double maxY = points.first.position.dy;

    for (final point in points) {
      minX = math.min(minX, point.position.dx);
      maxX = math.max(maxX, point.position.dx);
      minY = math.min(minY, point.position.dy);
      maxY = math.max(maxY, point.position.dy);
    }

    final padding = brushSize / 2;
    return Rect.fromLTRB(
      minX - padding,
      minY - padding,
      maxX + padding,
      maxY + padding,
    );
  }

  Stroke copyWith({
    List<StrokePoint>? points,
    BrushSettings? brushSettings,
    String? id,
    DateTime? createdAt,
    Rect? bounds,
  }) {
    return Stroke(
      points: points ?? this.points,
      brushSettings: brushSettings ?? this.brushSettings,
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      bounds: bounds ?? this.bounds,
    );
  }

  // Stroke processing methods
  List<StrokePoint> getSmoothedPoints() {
    if (points.length < 3) return points;

    final smoothed = <StrokePoint>[points.first];

    for (int i = 1; i < points.length - 1; i++) {
      final prev = points[i - 1];
      final current = points[i];
      final next = points[i + 1];

      // Quadratic bezier smoothing
      final smoothedPosition = Offset(
        (prev.position.dx + 2 * current.position.dx + next.position.dx) / 4,
        (prev.position.dy + 2 * current.position.dy + next.position.dy) / 4,
      );

      smoothed.add(current.copyWith(position: smoothedPosition));
    }

    smoothed.add(points.last);
    return smoothed;
  }

  double getStrokeLength() {
    double length = 0.0;
    for (int i = 1; i < points.length; i++) {
      length += (points[i].position - points[i - 1].position).distance;
    }
    return length;
  }

  bool intersects(Rect rect) {
    return bounds.overlaps(rect);
  }
}
