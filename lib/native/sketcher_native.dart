import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/stroke.dart';

/// Point data structure for FFI communication
final class PointData extends Struct {
  @Double()
  external double x;

  @Double()
  external double y;

  @Double()
  external double pressure;

  @Double()
  external double timestamp;

  @Double()
  external double tiltX;

  @Double()
  external double tiltY;
}

/// Calligraphy segment data for rendering
final class CalligraphySegment extends Struct {
  @Double()
  external double x1;

  @Double()
  external double y1;

  @Double()
  external double x2;

  @Double()
  external double y2;

  @Double()
  external double thickness;

  @Double()
  external double alpha;
}

// Mesh vertex struct matching native Vertex2D
final class Vertex2D extends Struct {
  @Double()
  external double x;

  @Double()
  external double y;

  @Double()
  external double alpha;
}

/// Native function type definitions
typedef CalculateCalligraphySegmentsNative = Int32 Function(
  Pointer<PointData> points,
  Int32 pointCount,
  Double strokeWidth,
  Double opacity,
  Double nibAngleDeg,
  Double nibWidthFactor,
  Pointer<CalligraphySegment> outputSegments,
  Int32 maxSegments,
);

typedef CalculateCalligraphySegmentsDart = int Function(
  Pointer<PointData> points,
  int pointCount,
  double strokeWidth,
  double opacity,
  double nibAngleDeg,
  double nibWidthFactor,
  Pointer<CalligraphySegment> outputSegments,
  int maxSegments,
);

typedef SmoothStrokePointsNative = Int32 Function(
  Pointer<PointData> inputPoints,
  Int32 inputCount,
  Double smoothingFactor,
  Pointer<PointData> outputPoints,
  Int32 maxOutput,
);

typedef SmoothStrokePointsDart = int Function(
  Pointer<PointData> inputPoints,
  int inputCount,
  double smoothingFactor,
  Pointer<PointData> outputPoints,
  int maxOutput,
);

// Resample points
typedef ResampleStrokePointsNative = Int32 Function(
  Pointer<PointData> inputPoints,
  Int32 inputCount,
  Double spacing,
  Pointer<PointData> outputPoints,
  Int32 maxOutput,
);

typedef ResampleStrokePointsDart = int Function(
  Pointer<PointData> inputPoints,
  int inputCount,
  double spacing,
  Pointer<PointData> outputPoints,
  int maxOutput,
);

// One Euro filter
typedef OneEuroFilterPointsNative = Int32 Function(
  Pointer<PointData> inputPoints,
  Int32 inputCount,
  Double minCutoff,
  Double beta,
  Double dCutoff,
  Pointer<PointData> outputPoints,
  Int32 maxOutput,
);

typedef OneEuroFilterPointsDart = int Function(
  Pointer<PointData> inputPoints,
  int inputCount,
  double minCutoff,
  double beta,
  double dCutoff,
  Pointer<PointData> outputPoints,
  int maxOutput,
);

// Compute velocities between successive points
typedef ComputeStrokeVelocityNative = Int32 Function(
  Pointer<PointData> points,
  Int32 pointCount,
  Pointer<Double> outVelocities,
  Int32 maxOutput,
);
typedef ComputeStrokeVelocityDart = int Function(
  Pointer<PointData> points,
  int pointCount,
  Pointer<Double> outVelocities,
  int maxOutput,
);

// Simplify using RDP
typedef SimplifyStrokeRdpNative = Int32 Function(
  Pointer<PointData> inputPoints,
  Int32 inputCount,
  Double epsilon,
  Pointer<PointData> outputPoints,
  Int32 maxOutput,
);
typedef SimplifyStrokeRdpDart = int Function(
  Pointer<PointData> inputPoints,
  int inputCount,
  double epsilon,
  Pointer<PointData> outputPoints,
  int maxOutput,
);

// Mesh builder FFI typedefs
typedef BuildCalligraphyMeshNative = Int32 Function(
  Pointer<PointData> points,
  Int32 pointCount,
  Double strokeWidth,
  Double opacity,
  Double nibAngleDeg,
  Double nibWidthFactor,
  Pointer<Vertex2D> outVertices,
  Int32 maxVertices,
  Pointer<Uint32> outIndices,
  Int32 maxIndices,
  Pointer<Int32> outIndexCount,
);

typedef BuildCalligraphyMeshDart = int Function(
  Pointer<PointData> points,
  int pointCount,
  double strokeWidth,
  double opacity,
  double nibAngleDeg,
  double nibWidthFactor,
  Pointer<Vertex2D> outVertices,
  int maxVertices,
  Pointer<Uint32> outIndices,
  int maxIndices,
  Pointer<Int32> outIndexCount,
);

/// High-performance calligraphy rendering using native C++
class SketcherNative {
  static DynamicLibrary? _dylib;
  static late CalculateCalligraphySegmentsDart _calculateCalligraphySegments;
  static late SmoothStrokePointsDart _smoothStrokePoints;
  static BuildCalligraphyMeshDart? _buildCalligraphyMesh;
  static ResampleStrokePointsDart? _resampleStrokePoints;
  static OneEuroFilterPointsDart? _oneEuroFilterPoints;
  static ResampleStrokePointsDart? _resamplePoints;
  static ComputeStrokeVelocityDart? _computeVelocity;
  static SimplifyStrokeRdpDart? _simplifyRdp;

  static bool _initialized = false;
  static bool get isAvailable => _initialized;

  /// Initialize the native library
  static bool initialize() {
    if (_initialized) return true;

    try {
      // Load the native library
      if (Platform.isWindows) {
        _dylib = DynamicLibrary.open('sketcher_native.dll');
      } else if (Platform.isAndroid) {
        _dylib = DynamicLibrary.open('libsketcher_native.so');
      } else if (Platform.isIOS) {
        _dylib = DynamicLibrary.process();
      } else if (Platform.isMacOS) {
        _dylib = DynamicLibrary.open('libsketcher_native.dylib');
      } else if (Platform.isLinux) {
        _dylib = DynamicLibrary.open('libsketcher_native.so');
      } else {
        debugPrint('❌ Unsupported platform for native library');
        return false;
      }

      // Load function symbols
      _calculateCalligraphySegments = _dylib!
          .lookup<NativeFunction<CalculateCalligraphySegmentsNative>>(
              'calculate_calligraphy_segments')
          .asFunction<CalculateCalligraphySegmentsDart>();

      _smoothStrokePoints = _dylib!
          .lookup<NativeFunction<SmoothStrokePointsNative>>(
              'smooth_stroke_points')
          .asFunction<SmoothStrokePointsDart>();

      // Optional mesh builder (if present)
      try {
        _buildCalligraphyMesh = _dylib!
            .lookup<NativeFunction<BuildCalligraphyMeshNative>>(
                'build_calligraphy_mesh')
            .asFunction<BuildCalligraphyMeshDart>();
      } catch (_) {
        _buildCalligraphyMesh = null;
      }

      // Optional preprocessing APIs
      try {
        _resampleStrokePoints = _dylib!
            .lookup<NativeFunction<ResampleStrokePointsNative>>(
                'resample_stroke_points')
            .asFunction<ResampleStrokePointsDart>();
      } catch (_) {
        _resampleStrokePoints = null;
      }

      try {
        _oneEuroFilterPoints = _dylib!
            .lookup<NativeFunction<OneEuroFilterPointsNative>>(
                'one_euro_filter_points')
            .asFunction<OneEuroFilterPointsDart>();
      } catch (_) {
        _oneEuroFilterPoints = null;
      }

      // Optional utilities
      try {
        _resamplePoints = _dylib!
            .lookup<NativeFunction<ResampleStrokePointsNative>>(
                'resample_stroke_points')
            .asFunction<ResampleStrokePointsDart>();
      } catch (_) {
        _resamplePoints = null;
      }
      try {
        _computeVelocity = _dylib!
            .lookup<NativeFunction<ComputeStrokeVelocityNative>>(
                'compute_stroke_velocity')
            .asFunction<ComputeStrokeVelocityDart>();
      } catch (_) {
        _computeVelocity = null;
      }
      try {
        _simplifyRdp = _dylib!
            .lookup<NativeFunction<SimplifyStrokeRdpNative>>(
                'simplify_stroke_rdp')
            .asFunction<SimplifyStrokeRdpDart>();
      } catch (_) {
        _simplifyRdp = null;
      }

      _initialized = true;
      debugPrint('✅ Native calligraphy library initialized successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Failed to initialize native library: $e');
      return false;
    }
  }

  /// One Euro filter on stroke points (if available)
  static List<DrawingPoint> oneEuroFilterPoints({
    required List<DrawingPoint> points,
    double minCutoff = 1.0,
    double beta = 0.0,
    double dCutoff = 1.0,
  }) {
    if (!_initialized || _oneEuroFilterPoints == null || points.length < 2) {
      return points;
    }
    final input = calloc<PointData>(points.length);
    final output = calloc<PointData>(points.length);
    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      input[i]
        ..x = p.offset.dx
        ..y = p.offset.dy
        ..pressure = p.pressure
        ..timestamp = p.timestamp
        ..tiltX = p.tiltX
        ..tiltY = p.tiltY;
    }
    final count = _oneEuroFilterPoints!(
      input,
      points.length,
      minCutoff,
      beta,
      dCutoff,
      output,
      points.length,
    );

    final result = List<DrawingPoint>.generate(count, (i) {
      final p = output[i];
      return DrawingPoint(
        offset: Offset(p.x, p.y),
        pressure: p.pressure,
        timestamp: p.timestamp,
        tiltX: p.tiltX,
        tiltY: p.tiltY,
      );
    });
    calloc.free(input);
    calloc.free(output);
    return result;
  }

  /// Resample points at uniform spacing (if available)
  static List<DrawingPoint> resamplePoints({
    required List<DrawingPoint> points,
    required double spacing,
    int maxOutputMultiplier = 2,
  }) {
    if (!_initialized || _resampleStrokePoints == null || points.length < 2) {
      return points;
    }
    final maxOut = (points.length * maxOutputMultiplier).clamp(2, 8192);
    final input = calloc<PointData>(points.length);
    final output = calloc<PointData>(maxOut);
    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      input[i]
        ..x = p.offset.dx
        ..y = p.offset.dy
        ..pressure = p.pressure
        ..timestamp = p.timestamp
        ..tiltX = p.tiltX
        ..tiltY = p.tiltY;
    }
    final count = _resampleStrokePoints!(
      input,
      points.length,
      spacing,
      output,
      maxOut,
    );
    final result = List<DrawingPoint>.generate(count, (i) {
      final p = output[i];
      return DrawingPoint(
        offset: Offset(p.x, p.y),
        pressure: p.pressure,
        timestamp: p.timestamp,
        tiltX: p.tiltX,
        tiltY: p.tiltY,
      );
    });
    calloc.free(input);
    calloc.free(output);
    return result;
  }

  /// Build a mesh for calligraphy stroke (single drawVertices)
  static ({List<Offset> positions, List<int> indices, List<double> alphas})?
      buildCalligraphyMesh({
    required List<DrawingPoint> points,
    required double strokeWidth,
    required double opacity,
    required double nibAngleDeg,
    required double nibWidthFactor,
    int maxSegments = 1024,
  }) {
    if (!_initialized || _buildCalligraphyMesh == null || points.length < 2) {
      return null;
    }

    // Each segment -> 4 vertices, 6 indices
    final maxVertices = maxSegments * 4;
    final maxIndices = maxSegments * 6;

    final nativePoints = calloc<PointData>(points.length);
    final nativeVerts = calloc<Vertex2D>(maxVertices);
    final nativeIndices = calloc<Uint32>(maxIndices);
    final outIndexCount = calloc<Int32>(1);

    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      nativePoints[i]
        ..x = p.offset.dx
        ..y = p.offset.dy
        ..pressure = p.pressure
        ..timestamp = p.timestamp
        ..tiltX = p.tiltX
        ..tiltY = p.tiltY;
    }

    final vcount = _buildCalligraphyMesh!(
      nativePoints,
      points.length,
      strokeWidth,
      opacity,
      nibAngleDeg,
      nibWidthFactor,
      nativeVerts,
      maxVertices,
      nativeIndices,
      maxIndices,
      outIndexCount,
    );

    final icount = outIndexCount.value;

    final positions = List<Offset>.generate(vcount, (i) {
      final v = nativeVerts[i];
      return Offset(v.x, v.y);
    }, growable: false);

    final alphas = List<double>.generate(vcount, (i) => nativeVerts[i].alpha,
        growable: false);

    final indices =
        List<int>.generate(icount, (i) => nativeIndices[i], growable: false);

    calloc.free(nativePoints);
    calloc.free(nativeVerts);
    calloc.free(nativeIndices);
    calloc.free(outIndexCount);

    return (positions: positions, indices: indices, alphas: alphas);
  }

  // Resample helper
  static List<DrawingPoint> resample({
    required List<DrawingPoint> points,
    double spacing = 1.5,
  }) {
    if (!_initialized || _resamplePoints == null || points.length < 2) {
      return points;
    }
    final inPtr = calloc<PointData>(points.length);
    final outPtr = calloc<PointData>(points.length);
    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      inPtr[i]
        ..x = p.offset.dx
        ..y = p.offset.dy
        ..pressure = p.pressure
        ..timestamp = p.timestamp
        ..tiltX = p.tiltX
        ..tiltY = p.tiltY;
    }
    final outCount =
        _resamplePoints!(inPtr, points.length, spacing, outPtr, points.length);
    final result = <DrawingPoint>[];
    for (int i = 0; i < outCount; i++) {
      final p = outPtr[i];
      result.add(DrawingPoint(
        offset: Offset(p.x, p.y),
        pressure: p.pressure,
        timestamp: p.timestamp,
        tiltX: p.tiltX,
        tiltY: p.tiltY,
      ));
    }
    calloc.free(inPtr);
    calloc.free(outPtr);
    return result;
  }

  // Velocity helper
  static List<double> velocities({required List<DrawingPoint> points}) {
    if (!_initialized || _computeVelocity == null || points.length < 2) {
      return const [];
    }
    final inPtr = calloc<PointData>(points.length);
    final outPtr = calloc<Double>(points.length);
    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      inPtr[i]
        ..x = p.offset.dx
        ..y = p.offset.dy
        ..pressure = p.pressure
        ..timestamp = p.timestamp
        ..tiltX = p.tiltX
        ..tiltY = p.tiltY;
    }
    final count =
        _computeVelocity!(inPtr, points.length, outPtr, points.length);
    final v = List<double>.generate(count, (i) => outPtr[i], growable: false);
    calloc.free(inPtr);
    calloc.free(outPtr);
    return v;
  }

  // Simplify helper
  static List<DrawingPoint> simplifyRdp({
    required List<DrawingPoint> points,
    double epsilon = 1.0,
  }) {
    if (!_initialized || _simplifyRdp == null || points.length < 3) {
      return points;
    }
    final inPtr = calloc<PointData>(points.length);
    final outPtr = calloc<PointData>(points.length);
    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      inPtr[i]
        ..x = p.offset.dx
        ..y = p.offset.dy
        ..pressure = p.pressure
        ..timestamp = p.timestamp
        ..tiltX = p.tiltX
        ..tiltY = p.tiltY;
    }
    final outCount =
        _simplifyRdp!(inPtr, points.length, epsilon, outPtr, points.length);
    final result = <DrawingPoint>[];
    for (int i = 0; i < outCount; i++) {
      final p = outPtr[i];
      result.add(DrawingPoint(
        offset: Offset(p.x, p.y),
        pressure: p.pressure,
        timestamp: p.timestamp,
        tiltX: p.tiltX,
        tiltY: p.tiltY,
      ));
    }
    calloc.free(inPtr);
    calloc.free(outPtr);
    return result;
  }

  /// Calculate calligraphy segments with high performance
  static List<CalligraphySegmentData> calculateCalligraphySegments({
    required List<DrawingPoint> points,
    required double strokeWidth,
    required double opacity,
    required double nibAngleDeg,
    required double nibWidthFactor,
  }) {
    if (!_initialized || points.length < 2) return [];

    const maxSegments = 1000; // Reasonable limit for performance

    try {
      // Allocate native memory
      final nativeInput = calloc<PointData>(points.length);
      final nativeOutput = calloc<CalligraphySegment>(maxSegments);

      // Copy points to native memory
      for (int i = 0; i < points.length; i++) {
        final point = points[i];
        nativeInput[i]
          ..x = point.offset.dx
          ..y = point.offset.dy
          ..pressure = point.pressure
          ..timestamp = point.timestamp
          ..tiltX = point.tiltX
          ..tiltY = point.tiltY;
      }

      // Call native function
      final segmentCount = _calculateCalligraphySegments(
        nativeInput,
        points.length,
        strokeWidth,
        opacity,
        nibAngleDeg,
        nibWidthFactor,
        nativeOutput,
        maxSegments,
      );

      // Convert results back to Dart
      final result = <CalligraphySegmentData>[];
      for (int i = 0; i < segmentCount; i++) {
        final segment = nativeOutput[i];
        result.add(CalligraphySegmentData(
          x1: segment.x1,
          y1: segment.y1,
          x2: segment.x2,
          y2: segment.y2,
          thickness: segment.thickness,
          alpha: segment.alpha,
        ));
      }

      // Clean up memory
      calloc.free(nativeInput);
      calloc.free(nativeOutput);

      return result;
    } catch (e) {
      debugPrint('❌ Native calligraphy calculation failed: $e');
      return [];
    }
  }

  /// Smooth stroke points for professional quality
  static List<DrawingPoint> smoothStrokePoints({
    required List<DrawingPoint> points,
    double smoothingFactor = 0.3,
  }) {
    if (!_initialized || points.length < 3) return points;

    try {
      // Allocate native memory
      final nativeInput = calloc<PointData>(points.length);
      final nativeOutput = calloc<PointData>(points.length);

      // Copy points to native memory
      for (int i = 0; i < points.length; i++) {
        final point = points[i];
        nativeInput[i]
          ..x = point.offset.dx
          ..y = point.offset.dy
          ..pressure = point.pressure
          ..timestamp = point.timestamp
          ..tiltX = point.tiltX
          ..tiltY = point.tiltY;
      }

      // Call native function
      final outputCount = _smoothStrokePoints(
        nativeInput,
        points.length,
        smoothingFactor,
        nativeOutput,
        points.length,
      );

      // Convert results back to Dart
      final result = <DrawingPoint>[];
      for (int i = 0; i < outputCount; i++) {
        final point = nativeOutput[i];
        result.add(DrawingPoint(
          offset: Offset(point.x, point.y),
          pressure: point.pressure,
          timestamp: point.timestamp,
          tiltX: point.tiltX,
          tiltY: point.tiltY,
        ));
      }

      // Clean up memory
      calloc.free(nativeInput);
      calloc.free(nativeOutput);

      return result;
    } catch (e) {
      debugPrint('❌ Native stroke smoothing failed: $e');
      return points;
    }
  }
}

/// Dart representation of calligraphy segment data
class CalligraphySegmentData {
  final double x1, y1, x2, y2;
  final double thickness;
  final double alpha;

  const CalligraphySegmentData({
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
    required this.thickness,
    required this.alpha,
  });

  @override
  String toString() =>
      'CalligraphySegment(($x1,$y1)->($x2,$y2), thickness: $thickness, alpha: $alpha)';
}
