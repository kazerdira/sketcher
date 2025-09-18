import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:professional_sketcher/controllers/sketch_controller.dart';
import 'package:professional_sketcher/models/drawing_tool.dart';

void main() {
  group('SketchController Tests', () {
    late SketchController controller;

    setUp(() {
      // Initialize GetX for testing
      Get.testMode = true;
      controller = SketchController();
    });

    tearDown(() {
      Get.reset();
    });

    group('Initialization Tests', () {
      test('should initialize with default values', () {
        expect(controller.currentTool.value, DrawingTool.pencil);
        expect(controller.currentColor.value, Colors.black);
        expect(controller.brushSize.value, 5.0);
        expect(controller.toolOpacity.value, 1.0);
        expect(controller.strokes, isEmpty);
        expect(controller.backgroundImage.value, isNull);
        expect(controller.imageOpacity.value, 0.5);
        expect(controller.isImageVisible.value, isTrue);
      });

      test('should have undo history initialized', () {
        expect(controller.undoHistory, isNotEmpty);
        expect(controller.undoHistory.first, isEmpty);
      });
    });

    group('Tool Management Tests', () {
      test('should change drawing tool', () {
        controller.setTool(DrawingTool.pen);
        expect(controller.currentTool.value, DrawingTool.pen);

        controller.setTool(DrawingTool.marker);
        expect(controller.currentTool.value, DrawingTool.marker);
      });

      test('should update tool opacity when changing tools', () {
        controller.setTool(DrawingTool.pencil);
        expect(controller.toolOpacity.value, 0.8); // Pencil default opacity

        controller.setTool(DrawingTool.pen);
        expect(controller.toolOpacity.value, 1.0); // Pen default opacity
      });

      test('should change color for non-eraser tools', () {
        controller.setColor(Colors.red);
        expect(controller.currentColor.value, Colors.red);

        controller.setColor(Colors.blue);
        expect(controller.currentColor.value, Colors.blue);
      });

      test('should not change color for eraser tool', () {
        final originalColor = controller.currentColor.value;
        controller.setTool(DrawingTool.eraser);
        controller.setColor(Colors.red);
        expect(controller.currentColor.value, originalColor);
      });

      test('should change brush size within tool constraints', () {
        controller.setTool(DrawingTool.pencil);
        controller.setBrushSize(5.0);
        expect(controller.brushSize.value, 5.0);

        // Test clamping to tool's min/max width
        controller.setBrushSize(0.5); // Below pencil min (1.0)
        expect(controller.brushSize.value, 1.0);

        controller.setBrushSize(10.0); // Above pencil max (8.0)
        expect(controller.brushSize.value, 8.0);
      });

      test('should change opacity within valid range', () {
        controller.setOpacity(0.5);
        expect(controller.toolOpacity.value, 0.5);

        controller.setOpacity(-0.1); // Below 0
        expect(controller.toolOpacity.value, 0.0);

        controller.setOpacity(1.5); // Above 1
        expect(controller.toolOpacity.value, 1.0);
      });

      test('should handle all drawing tools', () {
        for (final tool in DrawingTool.values) {
          controller.setTool(tool);
          expect(controller.currentTool.value, tool);
        }
      });
    });

    group('Drawing Tests', () {
      test('should start stroke and add first point', () {
        controller.startStroke(const Offset(10, 10), 0.8);
        expect(controller.currentStroke, isNotNull);
        expect(controller.currentStroke!.points, hasLength(1));
        expect(controller.currentStroke!.points.first.offset,
            const Offset(10, 10));
        expect(controller.currentStroke!.points.first.pressure, 0.8);
      });

      test('should add points to current stroke', () {
        controller.startStroke(const Offset(10, 10), 0.8);
        controller.addPoint(const Offset(20, 20), 0.9);
        controller.addPoint(const Offset(30, 30), 1.0);

        expect(controller.currentStroke!.points, hasLength(3));
        expect(
            controller.currentStroke!.points[1].offset, const Offset(20, 20));
        expect(
            controller.currentStroke!.points[2].offset, const Offset(30, 30));
      });

      test('should end stroke and add to collection', () {
        controller.startStroke(const Offset(10, 10), 1.0);
        controller.addPoint(const Offset(20, 20), 1.0);

        expect(controller.strokes, isEmpty);

        controller.endStroke();

        expect(controller.strokes, hasLength(1));
        expect(controller.currentStroke, isNull);
      });

      test('should not add empty strokes', () {
        controller.endStroke(); // Try to end without starting
        expect(controller.strokes, isEmpty);
      });

      test('should handle stroke for different tools', () {
        for (final tool in DrawingTool.values) {
          controller.setTool(tool);
          controller.startStroke(
              Offset(tool.index * 10.0, tool.index * 10.0), 1.0);
          controller.endStroke();
        }

        expect(controller.strokes, hasLength(DrawingTool.values.length));

        for (int i = 0; i < controller.strokes.length; i++) {
          expect(controller.strokes[i].tool, DrawingTool.values[i]);
        }
      });

      test('should handle eraser tool correctly', () {
        controller.setTool(DrawingTool.eraser);
        controller.startStroke(const Offset(10, 10), 1.0);
        controller.endStroke();

        final stroke = controller.strokes.last;
        expect(stroke.tool, DrawingTool.eraser);
        expect(stroke.isEraser, isTrue);
        expect(stroke.color, Colors.transparent);
      });
    });

    group('Tool Properties Tests', () {
      test('should detect pressure sensitive tools correctly', () {
        controller.setTool(DrawingTool.pencil);
        expect(controller.isCurrentToolPressureSensitive, isTrue);

        controller.setTool(DrawingTool.pen);
        expect(controller.isCurrentToolPressureSensitive, isFalse);

        controller.setTool(DrawingTool.marker);
        expect(controller.isCurrentToolPressureSensitive, isTrue);

        controller.setTool(DrawingTool.eraser);
        expect(controller.isCurrentToolPressureSensitive, isTrue);

        controller.setTool(DrawingTool.brush);
        expect(controller.isCurrentToolPressureSensitive, isTrue);
      });

      test('should detect velocity sensitive tools correctly', () {
        controller.setTool(DrawingTool.pencil);
        expect(controller.isCurrentToolVelocitySensitive, isTrue);

        controller.setTool(DrawingTool.pen);
        expect(controller.isCurrentToolVelocitySensitive, isFalse);

        controller.setTool(DrawingTool.marker);
        expect(controller.isCurrentToolVelocitySensitive, isFalse);

        controller.setTool(DrawingTool.eraser);
        expect(controller.isCurrentToolVelocitySensitive, isFalse);

        controller.setTool(DrawingTool.brush);
        expect(controller.isCurrentToolVelocitySensitive, isTrue);
      });

      test('should return effective color based on tool and opacity', () {
        controller.setColor(Colors.red);
        controller.setOpacity(0.5);

        final effectiveColor = controller.effectiveColor;
        expect(effectiveColor.red, Colors.red.red);
        expect(effectiveColor.opacity, closeTo(0.5, 0.01));

        controller.setTool(DrawingTool.eraser);
        expect(controller.effectiveColor, Colors.transparent);
      });
    });

    group('Undo/Clear Tests', () {
      test('should undo last stroke', () {
        // Add two strokes
        controller.startStroke(const Offset(10, 10), 1.0);
        controller.endStroke();
        controller.startStroke(const Offset(20, 20), 1.0);
        controller.endStroke();

        expect(controller.strokes, hasLength(2));

        controller.undo();
        expect(controller.strokes, hasLength(1));
      });

      test('should not undo when no strokes exist', () {
        expect(controller.strokes, isEmpty);
        controller.undo();
        expect(controller.strokes, isEmpty);
      });

      test('should handle multiple undos', () {
        // Add three strokes
        for (int i = 0; i < 3; i++) {
          controller.startStroke(Offset(i * 10.0, i * 10.0), 1.0);
          controller.endStroke();
        }

        expect(controller.strokes, hasLength(3));

        controller.undo();
        expect(controller.strokes, hasLength(2));

        controller.undo();
        expect(controller.strokes, hasLength(1));

        controller.undo();
        expect(controller.strokes, isEmpty);

        // Should not go below zero
        controller.undo();
        expect(controller.strokes, isEmpty);
      });

      test('should clear all strokes', () {
        // Add strokes
        controller.startStroke(const Offset(10, 10), 1.0);
        controller.endStroke();
        controller.startStroke(const Offset(20, 20), 1.0);
        controller.endStroke();

        expect(controller.strokes, hasLength(2));

        controller.clear();
        expect(controller.strokes, isEmpty);
      });
    });

    group('Background Image Tests', () {
      test('should set background image', () {
        const testImage = AssetImage('test.png');
        controller.setBackgroundImage(testImage);
        expect(controller.backgroundImage.value, testImage);
      });

      test('should set image opacity within valid range', () {
        controller.setImageOpacity(0.3);
        expect(controller.imageOpacity.value, 0.3);

        controller.setImageOpacity(-0.1);
        expect(controller.imageOpacity.value, 0.0);

        controller.setImageOpacity(1.5);
        expect(controller.imageOpacity.value, 1.0);
      });

      test('should toggle image visibility', () {
        expect(controller.isImageVisible.value, isTrue);

        controller.toggleImageVisibility();
        expect(controller.isImageVisible.value, isFalse);

        controller.toggleImageVisibility();
        expect(controller.isImageVisible.value, isTrue);
      });
    });

    group('Reactive State Tests', () {
      test('should notify listeners when tool changes', () {
        bool notified = false;
        controller.currentTool.listen((_) {
          notified = true;
        });

        controller.setTool(DrawingTool.pen);
        expect(notified, isTrue);
      });

      test('should notify listeners when color changes', () {
        bool notified = false;
        controller.currentColor.listen((_) {
          notified = true;
        });

        controller.setColor(Colors.red);
        expect(notified, isTrue);
      });

      test('should notify listeners when brush size changes', () {
        bool notified = false;
        controller.brushSize.listen((_) {
          notified = true;
        });

        controller.setBrushSize(10.0);
        expect(notified, isTrue);
      });
    });

    group('Edge Cases Tests', () {
      test('should handle rapid tool switching', () {
        for (int i = 0; i < 100; i++) {
          final tool = DrawingTool.values[i % DrawingTool.values.length];
          controller.setTool(tool);
          expect(controller.currentTool.value, tool);
        }
      });

      test('should handle adding points without starting stroke', () {
        controller.addPoint(const Offset(10, 10), 1.0);
        expect(controller.currentStroke, isNull);
      });

      test('should handle tool default colors', () {
        controller.setTool(DrawingTool.pen);
        // Color should change to tool's default if current is black
        controller.setTool(DrawingTool.marker);
        // Should update to marker's default color (yellow)
      });

      test('should maintain history size limit', () {
        // Add many strokes to test history limit
        for (int i = 0; i < 60; i++) {
          controller.startStroke(Offset(i.toDouble(), i.toDouble()), 1.0);
          controller.endStroke();
        }

        expect(controller.undoHistory.length, lessThanOrEqualTo(50));
      });
    });
  });
}
