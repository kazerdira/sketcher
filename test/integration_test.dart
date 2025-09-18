import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import '../lib/main.dart' as app;
import '../lib/controllers/sketch_controller.dart';
import '../lib/models/drawing_tool.dart';

void main() {
  group('Professional Sketching App Integration Tests', () {
    testWidgets('complete drawing workflow test', (WidgetTester tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();

      // Verify app launched successfully
      expect(find.byType(MaterialApp), findsOneWidget);

      // Get the controller
      final controller = Get.find<SketchController>();

      // Test 1: Initial state verification
      expect(controller.currentTool.value, DrawingTool.pencil);
      expect(controller.currentColor.value, Colors.black);
      expect(controller.strokes, isEmpty);

      // Test 2: Tool switching workflow
      await _testToolSwitching(tester, controller);

      // Test 3: Drawing workflow
      await _testDrawingWorkflow(tester, controller);

      // Test 4: Color and brush size adjustment
      await _testStyleAdjustments(tester, controller);

      // Test 5: Undo/clear functionality
      await _testUndoAndClear(tester, controller);

      // Test 6: Professional tool behaviors
      await _testProfessionalToolBehaviors(tester, controller);
    });

    testWidgets('realistic drawing experience test',
        (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      final controller = Get.find<SketchController>();

      // Test realistic drawing scenarios
      await _testRealisticDrawingScenarios(tester, controller);
    });

    testWidgets('performance under load test', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      final controller = Get.find<SketchController>();

      // Test performance with many strokes
      await _testPerformanceUnderLoad(tester, controller);
    });

    testWidgets('tool-specific feature test', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      final controller = Get.find<SketchController>();

      // Test each tool's specific features
      await _testToolSpecificFeatures(tester, controller);
    });

    testWidgets('UI responsiveness test', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Test UI responsiveness and state management
      await _testUIResponsiveness(tester);
    });
  });
}

Future<void> _testToolSwitching(
    WidgetTester tester, SketchController controller) async {
  // Find tool buttons and test switching
  final toolButtons = find.byType(InkWell);

  if (toolButtons.evaluate().length >= DrawingTool.values.length) {
    for (int i = 0; i < DrawingTool.values.length; i++) {
      await tester.tap(toolButtons.at(i));
      await tester.pumpAndSettle();

      // Verify tool changed
      expect(controller.currentTool.value, DrawingTool.values[i]);

      // Verify UI updated
      await tester.pump();
    }
  }
}

Future<void> _testDrawingWorkflow(
    WidgetTester tester, SketchController controller) async {
  // Find the drawing canvas
  final drawingArea = find.byKey(const Key('drawing-area'));

  // Simulate drawing a stroke
  final center = tester.getCenter(drawingArea);

  // Draw a line
  await tester.dragFrom(center, const Offset(50, 50));
  await tester.pumpAndSettle();

  // Verify stroke was created
  expect(controller.strokes, hasLength(1));
  expect(controller.strokes.first.points, isNotEmpty);

  // Draw another stroke
  await tester.dragFrom(
    center + const Offset(10, 10),
    const Offset(30, 30),
  );
  await tester.pumpAndSettle();

  // Verify second stroke
  expect(controller.strokes, hasLength(2));
}

Future<void> _testStyleAdjustments(
    WidgetTester tester, SketchController controller) async {
  final originalSize = controller.brushSize.value;

  // Find and adjust brush size slider
  final sliders = find.byType(Slider);
  if (sliders.evaluate().isNotEmpty) {
    await tester.drag(sliders.first, const Offset(20, 0));
    await tester.pumpAndSettle();

    expect(controller.brushSize.value, isNot(equals(originalSize)));
  }

  // Test color selection
  final colorButtons = find.byType(GestureDetector);
  if (colorButtons.evaluate().length > 5) {
    await tester.tap(colorButtons.at(2)); // Tap a color
    await tester.pumpAndSettle();
  }
}

Future<void> _testUndoAndClear(
    WidgetTester tester, SketchController controller) async {
  // Ensure we have strokes to undo
  if (controller.strokes.isEmpty) {
    final drawingArea = find.byType(GestureDetector).last;
    await tester.dragFrom(
      tester.getCenter(drawingArea),
      const Offset(20, 20),
    );
    await tester.pumpAndSettle();
  }

  final strokeCountBeforeUndo = controller.strokes.length;

  // Test undo
  final undoButton = find.byIcon(Icons.undo);
  await tester.tap(undoButton);
  await tester.pumpAndSettle();

  expect(controller.strokes.length, lessThan(strokeCountBeforeUndo));

  // Add more strokes for clear test
  final drawingArea = find.byKey(const Key('drawing-area'));
  for (int i = 0; i < 3; i++) {
    await tester.dragFrom(
      tester.getCenter(drawingArea) + Offset(i * 10.0, i * 10.0),
      const Offset(15, 15),
    );
    await tester.pumpAndSettle();
  }

  // Test clear
  final clearButton = find.byIcon(Icons.clear);
  await tester.tap(clearButton);
  await tester.pumpAndSettle();

  expect(controller.strokes, isEmpty);
}

Future<void> _testProfessionalToolBehaviors(
    WidgetTester tester, SketchController controller) async {
  final drawingArea = find.byKey(const Key('drawing-area'));

  // Test pencil (pressure sensitive)
  controller.setTool(DrawingTool.pencil);
  await tester.pumpAndSettle();

  await tester.dragFrom(
    tester.getCenter(drawingArea),
    const Offset(30, 30),
  );
  await tester.pumpAndSettle();

  final pencilStroke = controller.strokes.last;
  expect(pencilStroke.tool, DrawingTool.pencil);
  expect(pencilStroke.opacity, 0.8); // Pencil default opacity

  // Test pen (consistent, no pressure)
  controller.setTool(DrawingTool.pen);
  await tester.pumpAndSettle();

  await tester.dragFrom(
    tester.getCenter(drawingArea) + const Offset(50, 0),
    const Offset(30, 30),
  );
  await tester.pumpAndSettle();

  final penStroke = controller.strokes.last;
  expect(penStroke.tool, DrawingTool.pen);
  expect(penStroke.opacity, 1.0); // Pen default opacity

  // Test marker (transparent, wide)
  controller.setTool(DrawingTool.marker);
  await tester.pumpAndSettle();

  await tester.dragFrom(
    tester.getCenter(drawingArea) + const Offset(100, 0),
    const Offset(30, 30),
  );
  await tester.pumpAndSettle();

  final markerStroke = controller.strokes.last;
  expect(markerStroke.tool, DrawingTool.marker);
  expect(markerStroke.opacity, 0.6); // Marker default opacity

  // Test eraser
  controller.setTool(DrawingTool.eraser);
  await tester.pumpAndSettle();

  await tester.dragFrom(
    tester.getCenter(drawingArea) + const Offset(0, 50),
    const Offset(30, 30),
  );
  await tester.pumpAndSettle();

  final eraserStroke = controller.strokes.last;
  expect(eraserStroke.tool, DrawingTool.eraser);
  expect(eraserStroke.isEraser, isTrue);

  // Test brush (variable, artistic)
  controller.setTool(DrawingTool.brush);
  await tester.pumpAndSettle();

  await tester.dragFrom(
    tester.getCenter(drawingArea) + const Offset(150, 0),
    const Offset(30, 30),
  );
  await tester.pumpAndSettle();

  final brushStroke = controller.strokes.last;
  expect(brushStroke.tool, DrawingTool.brush);
  expect(brushStroke.opacity, 0.9); // Brush default opacity
}

Future<void> _testRealisticDrawingScenarios(
    WidgetTester tester, SketchController controller) async {
  final drawingArea = find.byKey(const Key('drawing-area'));
  final center = tester.getCenter(drawingArea);

  // Scenario 1: Sketch outline with pencil
  controller.setTool(DrawingTool.pencil);
  controller.setBrushSize(2.0);
  await tester.pumpAndSettle();

  // Draw a simple outline
  await tester.dragFrom(center, const Offset(50, 0));
  await tester.dragFrom(center + const Offset(50, 0), const Offset(0, 50));
  await tester.dragFrom(center + const Offset(50, 50), const Offset(-50, 0));
  await tester.dragFrom(center + const Offset(0, 50), const Offset(0, -50));
  await tester.pumpAndSettle();

  expect(controller.strokes.length, 4);

  // Scenario 2: Fill with marker
  controller.setTool(DrawingTool.marker);
  controller.setBrushSize(15.0);
  await tester.pumpAndSettle();

  await tester.dragFrom(center + const Offset(10, 10), const Offset(30, 30));
  await tester.pumpAndSettle();

  // Scenario 3: Add details with pen
  controller.setTool(DrawingTool.pen);
  controller.setBrushSize(1.0);
  await tester.pumpAndSettle();

  await tester.dragFrom(center + const Offset(15, 15), const Offset(10, 10));
  await tester.pumpAndSettle();

  // Scenario 4: Artistic touches with brush
  controller.setTool(DrawingTool.brush);
  controller.setBrushSize(8.0);
  await tester.pumpAndSettle();

  await tester.dragFrom(center + const Offset(60, 10), const Offset(20, 40));
  await tester.pumpAndSettle();

  // Verify we have a complex drawing
  expect(controller.strokes.length, greaterThan(5));

  // Verify different tools were used
  final toolsUsed = controller.strokes.map((s) => s.tool).toSet();
  expect(toolsUsed, contains(DrawingTool.pencil));
  expect(toolsUsed, contains(DrawingTool.marker));
  expect(toolsUsed, contains(DrawingTool.pen));
  expect(toolsUsed, contains(DrawingTool.brush));
}

Future<void> _testPerformanceUnderLoad(
    WidgetTester tester, SketchController controller) async {
  final drawingArea = find.byKey(const Key('drawing-area'));
  final center = tester.getCenter(drawingArea);

  // Clear canvas first
  controller.clear();
  await tester.pumpAndSettle();

  // Draw many strokes rapidly
  final stopwatch = Stopwatch()..start();

  for (int i = 0; i < 50; i++) {
    await tester.dragFrom(
      center + Offset(i * 2.0, i * 2.0),
      const Offset(10, 10),
    );

    // Don't wait for settle on every stroke to test performance
    if (i % 10 == 0) {
      await tester.pump();
    }
  }

  await tester.pumpAndSettle();
  stopwatch.stop();

  // Verify performance (should complete in reasonable time)
  expect(stopwatch.elapsedMilliseconds, lessThan(10000)); // 10 seconds max
  expect(controller.strokes.length, 50);

  // Test UI responsiveness after many strokes
  controller.setTool(DrawingTool.pen);
  await tester.pumpAndSettle();
  expect(controller.currentTool.value, DrawingTool.pen);

  // Test undo performance
  final undoStopwatch = Stopwatch()..start();
  controller.undo();
  await tester.pumpAndSettle();
  undoStopwatch.stop();

  expect(
      undoStopwatch.elapsedMilliseconds, lessThan(100)); // Should be very fast
  expect(controller.strokes.length, 49);
}

Future<void> _testToolSpecificFeatures(
    WidgetTester tester, SketchController controller) async {
  // Test pressure sensitivity detection
  expect(controller.isCurrentToolPressureSensitive, isTrue); // Default pencil

  controller.setTool(DrawingTool.pen);
  expect(controller.isCurrentToolPressureSensitive, isFalse);

  controller.setTool(DrawingTool.marker);
  expect(controller.isCurrentToolPressureSensitive, isTrue);

  controller.setTool(DrawingTool.eraser);
  expect(controller.isCurrentToolPressureSensitive, isTrue);

  controller.setTool(DrawingTool.brush);
  expect(controller.isCurrentToolPressureSensitive, isTrue);

  // Test velocity sensitivity detection
  controller.setTool(DrawingTool.pencil);
  expect(controller.isCurrentToolVelocitySensitive, isTrue);

  controller.setTool(DrawingTool.pen);
  expect(controller.isCurrentToolVelocitySensitive, isFalse);

  controller.setTool(DrawingTool.brush);
  expect(controller.isCurrentToolVelocitySensitive, isTrue);

  // Test tool-specific width constraints
  controller.setTool(DrawingTool.pencil);
  controller.setBrushSize(100.0); // Try to set beyond pencil max
  expect(controller.brushSize.value, lessThanOrEqualTo(8.0)); // Pencil max

  controller.setTool(DrawingTool.marker);
  controller.setBrushSize(1.0); // Try to set below marker min
  expect(controller.brushSize.value, greaterThanOrEqualTo(8.0)); // Marker min

  // Test effective color for eraser
  controller.setTool(DrawingTool.eraser);
  expect(controller.effectiveColor, Colors.transparent);

  controller.setTool(DrawingTool.pencil);
  controller.setColor(Colors.red);
  controller.setOpacity(0.5);
  final effectiveColor = controller.effectiveColor;
  expect(effectiveColor.opacity, closeTo(0.5, 0.01));
}

Future<void> _testUIResponsiveness(WidgetTester tester) async {
  // Test rapid UI interactions
  final toolButtons = find.byType(InkWell);

  if (toolButtons.evaluate().length >= 3) {
    // Rapidly switch between tools
    for (int i = 0; i < 10; i++) {
      await tester.tap(toolButtons.at(i % 3));
      await tester.pump(); // Don't settle to test responsiveness
    }

    await tester.pumpAndSettle();
  }

  // Test slider responsiveness
  final sliders = find.byType(Slider);
  if (sliders.evaluate().isNotEmpty) {
    for (int i = 0; i < 5; i++) {
      await tester.drag(sliders.first, Offset(i * 10.0, 0));
      await tester.pump();
    }

    await tester.pumpAndSettle();
  }

  // Test color selection responsiveness
  final colorButtons = find.byType(GestureDetector);
  if (colorButtons.evaluate().length > 10) {
    for (int i = 0; i < 5; i++) {
      await tester.tap(colorButtons.at(i + 5));
      await tester.pump();
    }

    await tester.pumpAndSettle();
  }
}
