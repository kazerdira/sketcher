import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:professional_sketcher/painters/sketch_painter.dart';
import 'package:professional_sketcher/models/stroke.dart';
import 'package:professional_sketcher/models/drawing_tool.dart';

void main() {
  group('SketchPainter Tests', () {
    late List<Stroke> testStrokes;
    late Stroke testCurrentStroke;

    setUp(() {
      // Create test strokes
      testStrokes = [
        Stroke(
          points: [
            DrawingPoint(offset: const Offset(10, 10), timestamp: 1),
            DrawingPoint(offset: const Offset(20, 20), timestamp: 2),
            DrawingPoint(offset: const Offset(30, 30), timestamp: 3),
          ],
          color: Colors.red,
          width: 5.0,
          tool: DrawingTool.pencil,
        ),
        Stroke(
          points: [
            DrawingPoint(offset: const Offset(40, 40), timestamp: 4),
            DrawingPoint(offset: const Offset(50, 50), timestamp: 5),
          ],
          color: Colors.blue,
          width: 3.0,
          tool: DrawingTool.pen,
        ),
      ];

      testCurrentStroke = Stroke(
        points: [
          DrawingPoint(offset: const Offset(60, 60), timestamp: 6),
          DrawingPoint(offset: const Offset(70, 70), timestamp: 7),
        ],
        color: Colors.green,
        width: 4.0,
        tool: DrawingTool.marker,
      );
    });

    group('Painter Initialization Tests', () {
      test('should create SketchPainter with required parameters', () {
        final painter = SketchPainter(
          strokes: testStrokes,
          currentStroke: testCurrentStroke,
          backgroundImage: null,
          imageOpacity: 0.5,
          isImageVisible: true,
        );

        expect(painter, isA<SketchPainter>());
        expect(painter, isA<CustomPainter>());
      });

      test('should create SketchPainter with empty strokes', () {
        final painter = SketchPainter(
          strokes: [],
          currentStroke: null,
          backgroundImage: null,
          imageOpacity: 0.5,
          isImageVisible: true,
        );

        expect(painter, isA<SketchPainter>());
      });

      test('should create SketchPainter with background image', () {
        const testImage = AssetImage('test.png');
        final painter = SketchPainter(
          strokes: testStrokes,
          currentStroke: null,
          backgroundImage: testImage,
          imageOpacity: 0.8,
          isImageVisible: true,
        );

        expect(painter, isA<SketchPainter>());
      });
    });

    group('shouldRepaint Tests', () {
      test('should repaint when strokes change', () {
        final painter1 = SketchPainter(
          strokes: testStrokes,
          currentStroke: null,
          backgroundImage: null,
          imageOpacity: 0.5,
          isImageVisible: true,
        );

        final newStrokes = List<Stroke>.from(testStrokes)
          ..add(Stroke(
            points: [
              DrawingPoint(offset: const Offset(100, 100), timestamp: 10)
            ],
            color: Colors.black,
            width: 2.0,
            tool: DrawingTool.brush,
          ));

        final painter2 = SketchPainter(
          strokes: newStrokes,
          currentStroke: null,
          backgroundImage: null,
          imageOpacity: 0.5,
          isImageVisible: true,
        );

        expect(painter1.shouldRepaint(painter2), isTrue);
      });

      test('should repaint when current stroke changes', () {
        final painter1 = SketchPainter(
          strokes: testStrokes,
          currentStroke: null,
          backgroundImage: null,
          imageOpacity: 0.5,
          isImageVisible: true,
        );

        final painter2 = SketchPainter(
          strokes: testStrokes,
          currentStroke: testCurrentStroke,
          backgroundImage: null,
          imageOpacity: 0.5,
          isImageVisible: true,
        );

        expect(painter1.shouldRepaint(painter2), isTrue);
      });

      test('should repaint when background image changes', () {
        final painter1 = SketchPainter(
          strokes: testStrokes,
          currentStroke: null,
          backgroundImage: null,
          imageOpacity: 0.5,
          isImageVisible: true,
        );

        const testImage = AssetImage('test.png');
        final painter2 = SketchPainter(
          strokes: testStrokes,
          currentStroke: null,
          backgroundImage: testImage,
          imageOpacity: 0.5,
          isImageVisible: true,
        );

        expect(painter1.shouldRepaint(painter2), isTrue);
      });

      test('should repaint when image opacity changes', () {
        final painter1 = SketchPainter(
          strokes: testStrokes,
          currentStroke: null,
          backgroundImage: null,
          imageOpacity: 0.5,
          isImageVisible: true,
        );

        final painter2 = SketchPainter(
          strokes: testStrokes,
          currentStroke: null,
          backgroundImage: null,
          imageOpacity: 0.8,
          isImageVisible: true,
        );

        expect(painter1.shouldRepaint(painter2), isTrue);
      });

      test('should repaint when image visibility changes', () {
        final painter1 = SketchPainter(
          strokes: testStrokes,
          currentStroke: null,
          backgroundImage: null,
          imageOpacity: 0.5,
          isImageVisible: true,
        );

        final painter2 = SketchPainter(
          strokes: testStrokes,
          currentStroke: null,
          backgroundImage: null,
          imageOpacity: 0.5,
          isImageVisible: false,
        );

        expect(painter1.shouldRepaint(painter2), isTrue);
      });

      test('should not repaint when nothing changes', () {
        final painter1 = SketchPainter(
          strokes: testStrokes,
          currentStroke: testCurrentStroke,
          backgroundImage: null,
          imageOpacity: 0.5,
          isImageVisible: true,
        );

        final painter2 = SketchPainter(
          strokes: testStrokes,
          currentStroke: testCurrentStroke,
          backgroundImage: null,
          imageOpacity: 0.5,
          isImageVisible: true,
        );

        expect(painter1.shouldRepaint(painter2), isFalse);
      });
    });

    group('Paint Method Tests', () {
      testWidgets('should paint without errors', (WidgetTester tester) async {
        final painter = SketchPainter(
          strokes: testStrokes,
          currentStroke: testCurrentStroke,
          backgroundImage: null,
          imageOpacity: 0.5,
          isImageVisible: true,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomPaint(
                painter: painter,
                size: const Size(400, 400),
              ),
            ),
          ),
        );

        expect(find.byType(CustomPaint), findsAtLeastNWidgets(1));
      });

      testWidgets('should paint empty canvas without errors',
          (WidgetTester tester) async {
        final painter = SketchPainter(
          strokes: [],
          currentStroke: null,
          backgroundImage: null,
          imageOpacity: 0.5,
          isImageVisible: true,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomPaint(
                painter: painter,
                size: const Size(400, 400),
              ),
            ),
          ),
        );

        expect(find.byType(CustomPaint), findsAtLeastNWidgets(1));
      });

      testWidgets('should paint all drawing tools correctly',
          (WidgetTester tester) async {
        final strokesWithAllTools = DrawingTool.values
            .map((tool) => Stroke(
                  points: [
                    DrawingPoint(
                        offset: Offset(tool.index * 10.0, tool.index * 10.0),
                        timestamp: 1),
                    DrawingPoint(
                        offset: Offset(
                            tool.index * 10.0 + 10, tool.index * 10.0 + 10),
                        timestamp: 2),
                  ],
                  color: Colors.red,
                  width: 5.0,
                  tool: tool,
                ))
            .toList();

        final painter = SketchPainter(
          strokes: strokesWithAllTools,
          currentStroke: null,
          backgroundImage: null,
          imageOpacity: 0.5,
          isImageVisible: true,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomPaint(
                painter: painter,
                size: const Size(400, 400),
              ),
            ),
          ),
        );

        expect(find.byType(CustomPaint), findsAtLeastNWidgets(1));
      });

      testWidgets('should paint eraser strokes correctly',
          (WidgetTester tester) async {
        final eraserStrokes = [
          Stroke(
            points: [
              DrawingPoint(offset: const Offset(10, 10), timestamp: 1),
              DrawingPoint(offset: const Offset(20, 20), timestamp: 2),
            ],
            color: Colors.transparent,
            width: 20.0,
            tool: DrawingTool.eraser,
            isEraser: true,
            blendMode: BlendMode.clear,
          ),
        ];

        final painter = SketchPainter(
          strokes: eraserStrokes,
          currentStroke: null,
          backgroundImage: null,
          imageOpacity: 0.5,
          isImageVisible: true,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomPaint(
                painter: painter,
                size: const Size(400, 400),
              ),
            ),
          ),
        );

        expect(find.byType(CustomPaint), findsAtLeastNWidgets(1));
      });

      testWidgets('should paint strokes with different opacities',
          (WidgetTester tester) async {
        final strokesWithOpacity = [
          Stroke(
            points: [
              DrawingPoint(offset: const Offset(10, 10), timestamp: 1),
              DrawingPoint(offset: const Offset(20, 20), timestamp: 2),
            ],
            color: Colors.red,
            width: 5.0,
            tool: DrawingTool.pencil,
            opacity: 0.3,
          ),
          Stroke(
            points: [
              DrawingPoint(offset: const Offset(30, 30), timestamp: 3),
              DrawingPoint(offset: const Offset(40, 40), timestamp: 4),
            ],
            color: Colors.blue,
            width: 5.0,
            tool: DrawingTool.pen,
            opacity: 0.8,
          ),
        ];

        final painter = SketchPainter(
          strokes: strokesWithOpacity,
          currentStroke: null,
          backgroundImage: null,
          imageOpacity: 0.5,
          isImageVisible: true,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomPaint(
                painter: painter,
                size: const Size(400, 400),
              ),
            ),
          ),
        );

        expect(find.byType(CustomPaint), findsAtLeastNWidgets(1));
      });

      testWidgets('should paint strokes with different blend modes',
          (WidgetTester tester) async {
        final strokesWithBlendModes = [
          Stroke(
            points: [
              DrawingPoint(offset: const Offset(10, 10), timestamp: 1),
              DrawingPoint(offset: const Offset(20, 20), timestamp: 2),
            ],
            color: Colors.red,
            width: 5.0,
            tool: DrawingTool.pencil,
            blendMode: BlendMode.multiply,
          ),
          Stroke(
            points: [
              DrawingPoint(offset: const Offset(15, 15), timestamp: 3),
              DrawingPoint(offset: const Offset(25, 25), timestamp: 4),
            ],
            color: Colors.blue,
            width: 5.0,
            tool: DrawingTool.marker,
            blendMode: BlendMode.overlay,
          ),
        ];

        final painter = SketchPainter(
          strokes: strokesWithBlendModes,
          currentStroke: null,
          backgroundImage: null,
          imageOpacity: 0.5,
          isImageVisible: true,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomPaint(
                painter: painter,
                size: const Size(400, 400),
              ),
            ),
          ),
        );

        expect(find.byType(CustomPaint), findsAtLeastNWidgets(1));
      });
    });

    group('Edge Cases Tests', () {
      testWidgets('should handle single point strokes',
          (WidgetTester tester) async {
        final singlePointStrokes = [
          Stroke(
            points: [
              DrawingPoint(offset: const Offset(10, 10), timestamp: 1),
            ],
            color: Colors.red,
            width: 5.0,
            tool: DrawingTool.pencil,
          ),
        ];

        final painter = SketchPainter(
          strokes: singlePointStrokes,
          currentStroke: null,
          backgroundImage: null,
          imageOpacity: 0.5,
          isImageVisible: true,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomPaint(
                painter: painter,
                size: const Size(400, 400),
              ),
            ),
          ),
        );

        expect(find.byType(CustomPaint), findsAtLeastNWidgets(1));
      });

      testWidgets('should handle strokes with zero width',
          (WidgetTester tester) async {
        final zeroWidthStrokes = [
          Stroke(
            points: [
              DrawingPoint(offset: const Offset(10, 10), timestamp: 1),
              DrawingPoint(offset: const Offset(20, 20), timestamp: 2),
            ],
            color: Colors.red,
            width: 0.0,
            tool: DrawingTool.pencil,
          ),
        ];

        final painter = SketchPainter(
          strokes: zeroWidthStrokes,
          currentStroke: null,
          backgroundImage: null,
          imageOpacity: 0.5,
          isImageVisible: true,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomPaint(
                painter: painter,
                size: const Size(400, 400),
              ),
            ),
          ),
        );

        expect(find.byType(CustomPaint), findsAtLeastNWidgets(1));
      });

      testWidgets('should handle transparent colors',
          (WidgetTester tester) async {
        final transparentStrokes = [
          Stroke(
            points: [
              DrawingPoint(offset: const Offset(10, 10), timestamp: 1),
              DrawingPoint(offset: const Offset(20, 20), timestamp: 2),
            ],
            color: Colors.transparent,
            width: 5.0,
            tool: DrawingTool.pencil,
          ),
        ];

        final painter = SketchPainter(
          strokes: transparentStrokes,
          currentStroke: null,
          backgroundImage: null,
          imageOpacity: 0.5,
          isImageVisible: true,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomPaint(
                painter: painter,
                size: const Size(400, 400),
              ),
            ),
          ),
        );

        expect(find.byType(CustomPaint), findsAtLeastNWidgets(1));
      });

      testWidgets('should handle very large stroke widths',
          (WidgetTester tester) async {
        final largeWidthStrokes = [
          Stroke(
            points: [
              DrawingPoint(offset: const Offset(100, 100), timestamp: 1),
              DrawingPoint(offset: const Offset(200, 200), timestamp: 2),
            ],
            color: Colors.red,
            width: 1000.0,
            tool: DrawingTool.brush,
          ),
        ];

        final painter = SketchPainter(
          strokes: largeWidthStrokes,
          currentStroke: null,
          backgroundImage: null,
          imageOpacity: 0.5,
          isImageVisible: true,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomPaint(
                painter: painter,
                size: const Size(400, 400),
              ),
            ),
          ),
        );

        expect(find.byType(CustomPaint), findsAtLeastNWidgets(1));
      });

      testWidgets('should handle many overlapping strokes',
          (WidgetTester tester) async {
        final overlappingStrokes = List.generate(
            100,
            (index) => Stroke(
                  points: [
                    DrawingPoint(
                        offset: Offset(50 + index * 0.1, 50 + index * 0.1),
                        timestamp: index.toDouble()),
                    DrawingPoint(
                        offset: Offset(60 + index * 0.1, 60 + index * 0.1),
                        timestamp: (index + 1).toDouble()),
                  ],
                  color: Color.fromRGBO((index * 3) % 256, (index * 5) % 256,
                      (index * 7) % 256, 1.0),
                  width: (index % 10) + 1.0,
                  tool: DrawingTool.values[index % DrawingTool.values.length],
                ));

        final painter = SketchPainter(
          strokes: overlappingStrokes,
          currentStroke: null,
          backgroundImage: null,
          imageOpacity: 0.5,
          isImageVisible: true,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomPaint(
                painter: painter,
                size: const Size(400, 400),
              ),
            ),
          ),
        );

        expect(find.byType(CustomPaint), findsAtLeastNWidgets(1));
      });
    });
  });
}
