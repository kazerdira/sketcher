import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import '../../lib/models/drawing_tool.dart';

void main() {
  group('DrawingTool Tests', () {
    test('should have correct number of tools', () {
      expect(DrawingTool.values.length, 5);
    });

    test('should have all expected tools', () {
      expect(
          DrawingTool.values,
          containsAll([
            DrawingTool.pencil,
            DrawingTool.pen,
            DrawingTool.marker,
            DrawingTool.eraser,
            DrawingTool.brush,
          ]));
    });

    test('pencil should have correct name', () {
      expect(DrawingTool.pencil.name, 'pencil');
    });

    test('pen should have correct name', () {
      expect(DrawingTool.pen.name, 'pen');
    });

    test('marker should have correct name', () {
      expect(DrawingTool.marker.name, 'marker');
    });

    test('eraser should have correct name', () {
      expect(DrawingTool.eraser.name, 'eraser');
    });

    test('brush should have correct name', () {
      expect(DrawingTool.brush.name, 'brush');
    });

    test('should be able to iterate through all tools', () {
      var toolNames = <String>[];
      for (var tool in DrawingTool.values) {
        toolNames.add(tool.name);
      }

      expect(toolNames, ['pencil', 'pen', 'marker', 'eraser', 'brush']);
    });

    test('should have unique values', () {
      var tools = DrawingTool.values.toSet();
      expect(tools.length, DrawingTool.values.length);
    });
  });
}
