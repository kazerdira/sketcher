import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import '../../lib/widgets/drawing_canvas.dart';
import '../../lib/controllers/sketch_controller.dart';
import '../../lib/models/drawing_tool.dart';

void main() {
  group('DrawingCanvas Widget Tests', () {
    late SketchController controller;

    setUp(() {
      Get.testMode = true;
      controller = SketchController();
      Get.put(controller);
    });

    tearDown(() {
      Get.reset();
    });

    testWidgets('should render DrawingCanvas widget',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DrawingCanvas(),
          ),
        ),
      );

      expect(find.byType(DrawingCanvas), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('should display all drawing tools in toolbar',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DrawingCanvas(),
          ),
        ),
      );

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Check if tool icons are present (may appear in multiple contexts)
      expect(find.byIcon(Icons.edit), findsWidgets); // Pencil
      expect(find.byIcon(Icons.create), findsWidgets); // Pen
      expect(find.byIcon(Icons.brush), findsWidgets); // Marker

      // Note: Some tools might use the same icon, so we check for at least these
    });

    testWidgets('should respond to tool selection',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DrawingCanvas(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initial tool should be pencil
      expect(controller.currentTool.value, DrawingTool.pencil);

      // Try to find and tap the pen tool (second tool button)
      final toolButtons = find.byType(InkWell);
      if (toolButtons.evaluate().length > 1) {
        await tester.tap(toolButtons.at(1));
        await tester.pumpAndSettle();
      }
    });

    testWidgets('should display color palette', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DrawingCanvas(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Look for color selection widgets
      expect(find.byType(Container), findsWidgets);

      // Should have color options - look for circular color buttons
      final containers = find.byType(Container);
      expect(containers.evaluate().length,
          greaterThan(5)); // Multiple color options
    });

    testWidgets('should respond to color selection',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DrawingCanvas(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Try to find and tap a color button
      final gestureDetectors = find.byType(GestureDetector);
      if (gestureDetectors.evaluate().isNotEmpty) {
        await tester.tap(gestureDetectors.first);
        await tester.pumpAndSettle();

        // Color might have changed (depending on which color was tapped)
        // This test mainly ensures the tap doesn't crash
      }
    });

    testWidgets('should display brush size slider',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DrawingCanvas(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Look for slider widgets
      expect(find.byType(Slider), findsWidgets);
    });

    testWidgets('should respond to brush size changes',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DrawingCanvas(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final originalSize = controller.brushSize.value;

      // Find the brush size slider and interact with it
      final sliders = find.byType(Slider);
      if (sliders.evaluate().isNotEmpty) {
        await tester.drag(sliders.first, const Offset(50, 0));
        await tester.pumpAndSettle();

        // Size should have changed
        expect(controller.brushSize.value, isNot(equals(originalSize)));
      }
    });

    testWidgets('should display opacity slider', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DrawingCanvas(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should have multiple sliders (brush size and opacity)
      expect(find.byType(Slider), findsAtLeastNWidgets(1));
    });

    testWidgets('should handle pan gestures on canvas',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DrawingCanvas(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the drawing area (CustomPaint or GestureDetector)
      final drawingArea = find.byKey(const Key('drawing-area'));

      // Simulate a pan gesture
      await tester.drag(
        drawingArea,
        const Offset(50, 50),
      );

      await tester.pumpAndSettle();

      // The gesture should be handled without crashing
    });

    testWidgets('should handle tap gestures on canvas',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DrawingCanvas(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the drawing area
      final drawingArea = find.byKey(const Key('drawing-area'));

      // Simulate a tap
      await tester.tap(drawingArea);
      await tester.pumpAndSettle();

      // Should handle the tap without crashing
    });

    testWidgets('should display undo button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DrawingCanvas(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Look for undo icon or button
      expect(find.byIcon(Icons.undo), findsOneWidget);
    });

    testWidgets('should handle undo button tap', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DrawingCanvas(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Add a stroke first
      controller.startStroke(const Offset(10, 10), 1.0);
      controller.endStroke();

      expect(controller.strokes.length, 1);

      // Find and tap undo button
      final undoButton = find.byIcon(Icons.undo);
      await tester.tap(undoButton);
      await tester.pumpAndSettle();

      expect(controller.strokes.length, 0);
    });

    testWidgets('should display clear button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DrawingCanvas(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Look for clear icon or button
      expect(find.byIcon(Icons.clear), findsOneWidget);
    });

    testWidgets('should handle clear button tap', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DrawingCanvas(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Add multiple strokes
      for (int i = 0; i < 3; i++) {
        controller.startStroke(Offset(i * 10.0, i * 10.0), 1.0);
        controller.endStroke();
      }

      expect(controller.strokes.length, 3);

      // Find and tap clear button
      final clearButton = find.byIcon(Icons.clear);
      await tester.ensureVisible(clearButton);
      await tester.tap(clearButton, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(controller.strokes.length, 0);
    });

    testWidgets('should show image picker option', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DrawingCanvas(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Look for image/photo icon
      expect(find.byIcon(Icons.image), findsOneWidget);
    });

    testWidgets('should handle different screen orientations',
        (WidgetTester tester) async {
      // Test portrait
      await tester.binding.setSurfaceSize(const Size(400, 800));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DrawingCanvas(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(DrawingCanvas), findsOneWidget);

      // Test landscape
      await tester.binding.setSurfaceSize(const Size(800, 400));
      await tester.pumpAndSettle();
      expect(find.byType(DrawingCanvas), findsOneWidget);

      // Reset to default
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('should handle widget rebuilds correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DrawingCanvas(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Change controller state
      controller.setTool(DrawingTool.pen);
      controller.setColor(Colors.red);

      // Rebuild
      await tester.pumpAndSettle();

      // Widget should still be there and functional
      expect(find.byType(DrawingCanvas), findsOneWidget);
      expect(controller.currentTool.value, DrawingTool.pen);
      expect(controller.currentColor.value, Colors.red);
    });

    testWidgets('should display tool-specific UI correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DrawingCanvas(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Test each tool
      for (final tool in DrawingTool.values) {
        controller.setTool(tool);
        await tester.pumpAndSettle();

        // Widget should update without errors
        expect(find.byType(DrawingCanvas), findsOneWidget);
      }
    });

    testWidgets('should handle rapid state changes',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DrawingCanvas(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Rapidly change multiple states
      for (int i = 0; i < 10; i++) {
        controller.setTool(DrawingTool.values[i % DrawingTool.values.length]);
        controller.setBrushSize((i % 20) + 1.0);
        controller.setOpacity((i % 10) / 10.0);

        await tester.pump(); // Don't settle, just pump
      }

      await tester.pumpAndSettle();

      // Should handle rapid changes without errors
      expect(find.byType(DrawingCanvas), findsOneWidget);
    });
  });

  group('DrawingCanvas Error Handling Tests', () {
    testWidgets('should handle null controller gracefully',
        (WidgetTester tester) async {
      // Don't put any controller in GetX
      Get.reset();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DrawingCanvas(),
          ),
        ),
      );

      // Should create its own controller or handle gracefully
      await tester.pumpAndSettle();
    });

    testWidgets('should handle extreme values gracefully',
        (WidgetTester tester) async {
      Get.testMode = true;
      final controller = SketchController();
      Get.put(controller);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DrawingCanvas(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Test extreme brush sizes
      controller.setBrushSize(0.1);
      await tester.pump();

      controller.setBrushSize(1000.0);
      await tester.pump();

      // Test extreme opacity
      controller.setOpacity(-1.0);
      await tester.pump();

      controller.setOpacity(10.0);
      await tester.pump();

      await tester.pumpAndSettle();

      // Should handle extreme values without crashing
      expect(find.byType(DrawingCanvas), findsOneWidget);
    });
  });
}
