import 'package:flutter/material.dart';
import 'drawing_tool.dart';

class DrawingPoint {
  final Offset offset;
  final double pressure;
  final double timestamp;

  DrawingPoint({
    required this.offset,
    this.pressure = 1.0,
    required this.timestamp,
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

  Stroke({
    required this.points,
    required this.color,
    required this.width,
    required this.tool,
    this.opacity = 1.0,
    this.blendMode = BlendMode.srcOver,
    this.isEraser = false,
  });

  Stroke copyWith({
    List<DrawingPoint>? points,
    Color? color,
    double? width,
    DrawingTool? tool,
    double? opacity,
    BlendMode? blendMode,
    bool? isEraser,
  }) {
    return Stroke(
      points: points ?? this.points,
      color: color ?? this.color,
      width: width ?? this.width,
      tool: tool ?? this.tool,
      opacity: opacity ?? this.opacity,
      blendMode: blendMode ?? this.blendMode,
      isEraser: isEraser ?? this.isEraser,
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
      defaultColor: Colors.blue,
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
      minWidth: 10.0,
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
