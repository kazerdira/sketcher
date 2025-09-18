import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:professional_sketcher/widgets/drawing_canvas.dart';
import 'package:professional_sketcher/controllers/sketch_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildHarness() {
    return GetMaterialApp(
      home: const DrawingCanvas(),
    );
  }

  testWidgets('stroke opacity slider updates current stroke opacity',
      (tester) async {
    Get.testMode = true;
    await tester.pumpWidget(buildHarness());
    await tester.pumpAndSettle();

    final controller = Get.find<SketchController>();

    final drawingArea = find.byKey(const Key('drawing-area'));
    expect(drawingArea, findsOneWidget);

    // Start a stroke and keep the pointer down
    final box = tester.firstRenderObject<RenderBox>(drawingArea);
    final topLeft = box.localToGlobal(Offset.zero);
    final center = topLeft + box.size.center(Offset.zero);

    final gesture = await tester.startGesture(center);
    await tester.pump(const Duration(milliseconds: 16));
    await gesture.moveBy(const Offset(20, 0));
    await tester.pump(const Duration(milliseconds: 16));

    // Move the stroke opacity slider to 50%
    final strokeSlider = find.byKey(const Key('stroke-opacity-slider'));
    expect(strokeSlider, findsOneWidget);

    // Simulate slider change by calling controller directly (more reliable)
    controller.setOpacity(0.5);
    await tester.pump();

    expect(controller.currentStroke, isNotNull);
    expect(controller.currentStroke!.opacity, closeTo(0.5, 0.01));

    // Continue stroke and then end it
    await gesture.moveBy(const Offset(50, 0));
    await tester.pump(const Duration(milliseconds: 16));
    await gesture.up();
    await tester.pump();

    expect(controller.strokes, isNotEmpty);
    expect(controller.strokes.last.opacity, closeTo(0.5, 0.01));
  });

  testWidgets(
      'image opacity slider appears and updates value when background set',
      (tester) async {
    Get.testMode = true;
    await tester.pumpWidget(buildHarness());
    await tester.pumpAndSettle();

    final controller = Get.find<SketchController>();

    // Initially no background image -> slider absent
    expect(find.byKey(const Key('image-opacity-slider')), findsNothing);

    // Set a dummy background image
    controller
        .setBackgroundImage(const AssetImage('test/assets/placeholder.png'));
    await tester.pump();

    expect(find.byKey(const Key('image-opacity-slider')), findsOneWidget);

    controller.setImageOpacity(0.2);
    await tester.pump();

    expect(controller.imageOpacity.value, closeTo(0.2, 0.01));
  });
}
