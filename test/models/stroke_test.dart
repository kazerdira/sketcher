import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import '../../lib/models/stroke.dart';
import '../../lib/models/drawing_tool.dart';

void main() {
  group('DrawingPoint Tests', () {
    test('should create DrawingPoint with all properties', () {
      final point = DrawingPoint(
        offset: const Offset(10.0, 20.0),
        pressure: 0.8,
        timestamp: 12345,
      );

      expect(point.offset, const Offset(10.0, 20.0));
      expect(point.pressure, 0.8);
      expect(point.timestamp, 12345);
    });

    test('should create DrawingPoint with default pressure', () {
      final point = DrawingPoint(
        offset: const Offset(5.0, 15.0),
        timestamp: 54321,
      );

      expect(point.offset, const Offset(5.0, 15.0));
      expect(point.pressure, 1.0); // default pressure
      expect(point.timestamp, 54321);
    });

    test('should handle edge cases for pressure', () {
      final point1 = DrawingPoint(
        offset: Offset.zero,
        pressure: 0.0,
        timestamp: 0,
      );
      expect(point1.pressure, 0.0);

      final point2 = DrawingPoint(
        offset: Offset.zero,
        pressure: 1.0,
        timestamp: 0,
      );
      expect(point2.pressure, 1.0);
    });
  });

  group('ToolConfig Tests', () {
    test('should have configurations for all drawing tools', () {
      for (final tool in DrawingTool.values) {
        expect(ToolConfig.configs.containsKey(tool), isTrue,
            reason: 'Missing config for $tool');
      }
    });

    test('pencil config should have correct properties', () {
      final config = ToolConfig.configs[DrawingTool.pencil]!;

      expect(config.minWidth, 1.0);
      expect(config.maxWidth, 8.0);
      expect(config.opacity, 0.8);
      expect(config.blendMode, BlendMode.multiply);
      expect(config.supportsPressure, isTrue);
      expect(config.supportsVelocity, isTrue);
      expect(config.defaultColor, Colors.grey);
    });

    test('pen config should have correct properties', () {
      final config = ToolConfig.configs[DrawingTool.pen]!;

      expect(config.minWidth, 1.0);
      expect(config.maxWidth, 6.0);
      expect(config.opacity, 1.0);
      expect(config.blendMode, BlendMode.srcOver);
      expect(config.supportsPressure, isFalse);
      expect(config.supportsVelocity, isFalse);
      expect(config.defaultColor, Colors.blue);
    });

    test('marker config should have correct properties', () {
      final config = ToolConfig.configs[DrawingTool.marker]!;

      expect(config.minWidth, 8.0);
      expect(config.maxWidth, 24.0);
      expect(config.opacity, 0.6);
      expect(config.blendMode, BlendMode.multiply);
      expect(config.supportsPressure, isTrue);
      expect(config.supportsVelocity, isFalse);
      expect(config.defaultColor, Colors.yellow);
    });

    test('eraser config should have correct properties', () {
      final config = ToolConfig.configs[DrawingTool.eraser]!;

      expect(config.minWidth, 10.0);
      expect(config.maxWidth, 50.0);
      expect(config.opacity, 1.0);
      expect(config.blendMode, BlendMode.clear);
      expect(config.supportsPressure, isTrue);
      expect(config.supportsVelocity, isFalse);
      expect(config.defaultColor, Colors.transparent);
    });

    test('brush config should have correct properties', () {
      final config = ToolConfig.configs[DrawingTool.brush]!;

      expect(config.minWidth, 4.0);
      expect(config.maxWidth, 40.0);
      expect(config.opacity, 0.9);
      expect(config.blendMode, BlendMode.srcOver);
      expect(config.supportsPressure, isTrue);
      expect(config.supportsVelocity, isTrue);
      expect(config.defaultColor, Colors.black);
    });

    test('should create custom ToolConfig', () {
      final config = ToolConfig(
        minWidth: 2.0,
        maxWidth: 10.0,
        opacity: 0.5,
        blendMode: BlendMode.overlay,
        supportsPressure: true,
        supportsVelocity: false,
        defaultColor: Colors.red,
      );

      expect(config.minWidth, 2.0);
      expect(config.maxWidth, 10.0);
      expect(config.opacity, 0.5);
      expect(config.blendMode, BlendMode.overlay);
      expect(config.supportsPressure, isTrue);
      expect(config.supportsVelocity, isFalse);
      expect(config.defaultColor, Colors.red);
    });
  });

  group('Stroke Tests', () {
    test('should create Stroke with all properties', () {
      final points = [
        DrawingPoint(offset: const Offset(0, 0), timestamp: 1),
        DrawingPoint(offset: const Offset(10, 10), timestamp: 2),
      ];

      final stroke = Stroke(
        points: points,
        color: Colors.red,
        width: 5.0,
        tool: DrawingTool.pencil,
        opacity: 0.8,
        blendMode: BlendMode.multiply,
        isEraser: false,
      );

      expect(stroke.points, points);
      expect(stroke.color, Colors.red);
      expect(stroke.width, 5.0);
      expect(stroke.tool, DrawingTool.pencil);
      expect(stroke.opacity, 0.8);
      expect(stroke.blendMode, BlendMode.multiply);
      expect(stroke.isEraser, isFalse);
    });

    test('should create Stroke with default values', () {
      final points = [
        DrawingPoint(offset: const Offset(0, 0), timestamp: 1),
      ];

      final stroke = Stroke(
        points: points,
        color: Colors.blue,
        width: 3.0,
        tool: DrawingTool.pen,
      );

      expect(stroke.points, points);
      expect(stroke.color, Colors.blue);
      expect(stroke.width, 3.0);
      expect(stroke.tool, DrawingTool.pen);
      expect(stroke.opacity, 1.0);
      expect(stroke.blendMode, BlendMode.srcOver);
      expect(stroke.isEraser, isFalse);
    });

    test('should handle copyWith method', () {
      final originalPoints = [
        DrawingPoint(offset: const Offset(0, 0), timestamp: 1),
      ];

      final originalStroke = Stroke(
        points: originalPoints,
        color: Colors.green,
        width: 2.0,
        tool: DrawingTool.marker,
      );

      final newPoints = [
        DrawingPoint(offset: const Offset(5, 5), timestamp: 2),
      ];

      final copiedStroke = originalStroke.copyWith(
        points: newPoints,
        color: Colors.purple,
        width: 4.0,
      );

      expect(copiedStroke.points, newPoints);
      expect(copiedStroke.color, Colors.purple);
      expect(copiedStroke.width, 4.0);
      expect(copiedStroke.tool, DrawingTool.marker); // unchanged
      expect(copiedStroke.opacity, 1.0); // unchanged
    });

    test('should handle empty points list', () {
      final stroke = Stroke(
        points: [],
        color: Colors.green,
        width: 2.0,
        tool: DrawingTool.marker,
      );

      expect(stroke.points, isEmpty);
      expect(stroke.color, Colors.green);
      expect(stroke.width, 2.0);
      expect(stroke.tool, DrawingTool.marker);
    });

    test('should handle different drawing tools', () {
      final points = [DrawingPoint(offset: const Offset(0, 0), timestamp: 1)];

      for (final tool in DrawingTool.values) {
        final stroke = Stroke(
          points: points,
          color: Colors.black,
          width: 1.0,
          tool: tool,
        );
        expect(stroke.tool, tool);
      }
    });

    test('should handle eraser strokes', () {
      final points = [DrawingPoint(offset: const Offset(0, 0), timestamp: 1)];

      final stroke = Stroke(
        points: points,
        color: Colors.transparent,
        width: 20.0,
        tool: DrawingTool.eraser,
        isEraser: true,
        blendMode: BlendMode.clear,
      );

      expect(stroke.tool, DrawingTool.eraser);
      expect(stroke.isEraser, isTrue);
      expect(stroke.blendMode, BlendMode.clear);
    });

    test('should handle various stroke widths', () {
      final points = [DrawingPoint(offset: const Offset(0, 0), timestamp: 1)];

      final stroke1 = Stroke(
        points: points,
        color: Colors.black,
        width: 0.5,
        tool: DrawingTool.pencil,
      );
      expect(stroke1.width, 0.5);

      final stroke2 = Stroke(
        points: points,
        color: Colors.black,
        width: 100.0,
        tool: DrawingTool.brush,
      );
      expect(stroke2.width, 100.0);
    });

    test('should handle various colors', () {
      final points = [DrawingPoint(offset: const Offset(0, 0), timestamp: 1)];

      final testColors = [
        Colors.red,
        Colors.green,
        Colors.blue,
        Colors.transparent,
        const Color(0xFF123456),
      ];

      for (final color in testColors) {
        final stroke = Stroke(
          points: points,
          color: color,
          width: 1.0,
          tool: DrawingTool.pencil,
        );
        expect(stroke.color, color);
      }
    });
  });
}
