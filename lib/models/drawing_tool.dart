import 'package:flutter/material.dart';

enum DrawingTool { pencil, pen, marker, eraser, brush }

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

class ToolSettings {
  final DrawingTool tool;
  final double size;
  final double opacity;
  final double flow;
  final Color color;
  final BlendMode blendMode;
  final bool pressureSensitive;
  final double hardness;
  final double spacing;
  final bool antiAlias;
  final double velocitySmoothing;
  final double pressureSmoothing;

  const ToolSettings({
    required this.tool,
    this.size = 5.0,
    this.opacity = 1.0,
    this.flow = 1.0,
    this.color = Colors.black,
    this.blendMode = BlendMode.normal,
    this.pressureSensitive = true,
    this.hardness = 1.0,
    this.spacing = 0.1,
    this.antiAlias = true,
    this.velocitySmoothing = 0.5,
    this.pressureSmoothing = 0.3,
  });

  ToolSettings copyWith({
    DrawingTool? tool,
    double? size,
    double? opacity,
    double? flow,
    Color? color,
    BlendMode? blendMode,
    bool? pressureSensitive,
    double? hardness,
    double? spacing,
    bool? antiAlias,
    double? velocitySmoothing,
    double? pressureSmoothing,
  }) {
    return ToolSettings(
      tool: tool ?? this.tool,
      size: size ?? this.size,
      opacity: opacity ?? this.opacity,
      flow: flow ?? this.flow,
      color: color ?? this.color,
      blendMode: blendMode ?? this.blendMode,
      pressureSensitive: pressureSensitive ?? this.pressureSensitive,
      hardness: hardness ?? this.hardness,
      spacing: spacing ?? this.spacing,
      antiAlias: antiAlias ?? this.antiAlias,
      velocitySmoothing: velocitySmoothing ?? this.velocitySmoothing,
      pressureSmoothing: pressureSmoothing ?? this.pressureSmoothing,
    );
  }
}

// Professional tool presets
class ToolPresets {
  static const ToolSettings pencil = ToolSettings(
    tool: DrawingTool.pencil,
    size: 3.0,
    opacity: 0.8,
    flow: 0.9,
    hardness: 0.9,
    spacing: 0.05,
    pressureSensitive: true,
    velocitySmoothing: 0.7,
    pressureSmoothing: 0.5,
  );

  static const ToolSettings pen = ToolSettings(
    tool: DrawingTool.pen,
    size: 2.0,
    opacity: 1.0,
    flow: 1.0,
    hardness: 1.0,
    spacing: 0.02,
    pressureSensitive: true,
    velocitySmoothing: 0.3,
    pressureSmoothing: 0.2,
  );

  static const ToolSettings marker = ToolSettings(
    tool: DrawingTool.marker,
    size: 8.0,
    opacity: 0.6,
    flow: 0.7,
    hardness: 0.3,
    spacing: 0.1,
    blendMode: BlendMode.multiply,
    pressureSensitive: true,
    velocitySmoothing: 0.8,
    pressureSmoothing: 0.6,
  );

  static const ToolSettings eraser = ToolSettings(
    tool: DrawingTool.eraser,
    size: 10.0,
    opacity: 1.0,
    flow: 1.0,
    hardness: 0.8,
    spacing: 0.05,
    pressureSensitive: true,
    velocitySmoothing: 0.4,
    pressureSmoothing: 0.3,
  );

  static const ToolSettings brush = ToolSettings(
    tool: DrawingTool.brush,
    size: 12.0,
    opacity: 0.9,
    flow: 0.8,
    hardness: 0.5,
    spacing: 0.15,
    pressureSensitive: true,
    velocitySmoothing: 0.9,
    pressureSmoothing: 0.7,
  );
}

// Enhanced stroke point with more data
class StrokePoint {
  final Offset position;
  final double pressure;
  final double velocity;
  final double tilt;
  final double timestamp;
  final double size;
  final double opacity;

  const StrokePoint({
    required this.position,
    this.pressure = 1.0,
    this.velocity = 0.0,
    this.tilt = 0.0,
    required this.timestamp,
    required this.size,
    required this.opacity,
  });

  StrokePoint copyWith({
    Offset? position,
    double? pressure,
    double? velocity,
    double? tilt,
    double? timestamp,
    double? size,
    double? opacity,
  }) {
    return StrokePoint(
      position: position ?? this.position,
      pressure: pressure ?? this.pressure,
      velocity: velocity ?? this.velocity,
      tilt: tilt ?? this.tilt,
      timestamp: timestamp ?? this.timestamp,
      size: size ?? this.size,
      opacity: opacity ?? this.opacity,
    );
  }
}
