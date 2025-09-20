import 'package:flutter/material.dart';
import 'drawing_tool.dart';
import 'brush_mode.dart';

class DrawingPoint {
  final Offset offset;
  final double pressure;
  final double timestamp;
  final double tiltX; // Stylus tilt in X direction (-π/2 to π/2)
  final double tiltY; // Stylus tilt in Y direction (-π/2 to π/2)

  DrawingPoint({
    required this.offset,
    this.pressure = 1.0,
    required this.timestamp,
    this.tiltX = 0.0,
    this.tiltY = 0.0,
  });
}

class Stroke {
  final List<DrawingPoint> points;
  final Color color;
  final double width;
  final DrawingTool tool;
  final double opacity;
  final BlendMode blendMode;
  final bool isEraser;
  final BrushMode? brushMode;
  // Brush tuning params (optional, used by specific brush modes)
  final double? calligraphyNibAngleDeg; // 0–90 degrees
  final double? calligraphyNibWidthFactor; // ~0.4–1.8
  final double? pastelGrainDensity; // ~0.5–2.0

  Stroke({
    required this.points,
    required this.color,
    required this.width,
    required this.tool,
    this.opacity = 1.0,
    this.blendMode = BlendMode.srcOver,
    this.isEraser = false,
    this.brushMode,
    this.calligraphyNibAngleDeg,
    this.calligraphyNibWidthFactor,
    this.pastelGrainDensity,
  });

  Stroke copyWith({
    List<DrawingPoint>? points,
    Color? color,
    double? width,
    DrawingTool? tool,
    double? opacity,
    BlendMode? blendMode,
    bool? isEraser,
    BrushMode? brushMode,
    double? calligraphyNibAngleDeg,
    double? calligraphyNibWidthFactor,
    double? pastelGrainDensity,
  }) {
    return Stroke(
      points: points ?? this.points,
      color: color ?? this.color,
      width: width ?? this.width,
      tool: tool ?? this.tool,
      opacity: opacity ?? this.opacity,
      blendMode: blendMode ?? this.blendMode,
      isEraser: isEraser ?? this.isEraser,
      brushMode: brushMode ?? this.brushMode,
      calligraphyNibAngleDeg:
          calligraphyNibAngleDeg ?? this.calligraphyNibAngleDeg,
      calligraphyNibWidthFactor:
          calligraphyNibWidthFactor ?? this.calligraphyNibWidthFactor,
      pastelGrainDensity: pastelGrainDensity ?? this.pastelGrainDensity,
    );
  }
}

// Tool configurations for realistic drawing behavior
class ToolConfig {
  final double minWidth;
  final double maxWidth;
  final double opacity;
  final BlendMode blendMode;
  final bool supportsPressure;
  final bool supportsVelocity;
  final Color defaultColor;

  const ToolConfig({
    required this.minWidth,
    required this.maxWidth,
    required this.opacity,
    required this.blendMode,
    required this.supportsPressure,
    required this.supportsVelocity,
    required this.defaultColor,
  });

  static const Map<DrawingTool, ToolConfig> configs = {
    DrawingTool.pencil: ToolConfig(
      minWidth: 1.0,
      maxWidth: 8.0,
      opacity: 0.8,
      blendMode: BlendMode.multiply,
      supportsPressure: true,
      supportsVelocity: true,
      defaultColor: Colors.grey,
    ),
    DrawingTool.pen: ToolConfig(
      minWidth: 1.0,
      maxWidth: 6.0,
      opacity: 1.0,
      blendMode: BlendMode.srcOver,
      supportsPressure: false,
      supportsVelocity: false,
      defaultColor: Colors.black,
    ),
    DrawingTool.marker: ToolConfig(
      minWidth: 8.0,
      maxWidth: 24.0,
      opacity: 0.6,
      blendMode: BlendMode.multiply,
      supportsPressure: true,
      supportsVelocity: false,
      defaultColor: Colors.yellow,
    ),
    DrawingTool.eraser: ToolConfig(
      minWidth: 4.0,
      maxWidth: 50.0,
      opacity: 1.0,
      blendMode: BlendMode.clear,
      supportsPressure: true,
      supportsVelocity: false,
      defaultColor: Colors.transparent,
    ),
    DrawingTool.brush: ToolConfig(
      minWidth: 4.0,
      maxWidth: 40.0,
      opacity: 0.9,
      blendMode: BlendMode.srcOver,
      supportsPressure: true,
      supportsVelocity: true,
      defaultColor: Colors.black,
    ),
  };
}
