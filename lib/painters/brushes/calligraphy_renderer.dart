import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;

import '../../models/stroke.dart';
import '../../native/sketcher_native.dart';

/// High-performance calligraphy brush renderer using native C++ calculations
class CalligraphyRenderer {
  // Render cache for performance
  static final Map<String, List<CalligraphySegmentData>> _segmentCache = {};

  // Performance metrics
  static int _cacheHits = 0;
  static int _cacheMisses = 0;
  static int _nativeCalculations = 0;

  /// Legacy draw method for backward compatibility
  static void draw(
    Canvas canvas,
    List<DrawingPoint> points,
    Stroke stroke,
    Color baseColor,
  ) {
    renderStroke(
      canvas: canvas,
      stroke: stroke,
      strokeWidth: stroke.width,
      color: baseColor,
      opacity: stroke.opacity,
      nibAngleDeg: stroke.calligraphyNibAngleDeg ?? 45.0,
      nibWidthFactor: stroke.calligraphyNibWidthFactor ?? 2.0,
      useNative: true,
      enableCache: true,
    );
  }

  /// Render a calligraphy stroke with professional quality
  static void renderStroke({
    required Canvas canvas,
    required Stroke stroke,
    required double strokeWidth,
    required Color color,
    required double opacity,
    double nibAngleDeg = 45.0,
    double nibWidthFactor = 2.0,
    bool enableCache = true,
    bool useNative = true,
  }) {
    if (stroke.points.isEmpty) return;

    final stopwatch = Stopwatch()..start();
    final cacheKey = enableCache
        ? _generateCacheKey(stroke, strokeWidth, nibAngleDeg, nibWidthFactor)
        : null;

    // Check cache first
    if (enableCache &&
        cacheKey != null &&
        _segmentCache.containsKey(cacheKey)) {
      _renderCachedSegments(canvas, _segmentCache[cacheKey]!, color, opacity);
      _cacheHits++;
      print('✒️ CALLIGRAPHY: Cache hit in ${stopwatch.elapsedMicroseconds}μs');
      return;
    }

    _cacheMisses++;

    // If mesh builder exists, prefer single drawVertices path
    if (useNative && SketcherNative.isAvailable) {
      // Optional preprocessing: One Euro + resample for stability and fewer vertices
      var prePoints = stroke.points;
      prePoints = SketcherNative.oneEuroFilterPoints(
        points: prePoints,
        minCutoff: 1.0,
        beta: 0.005,
        dCutoff: 1.0,
      );
      prePoints = SketcherNative.resamplePoints(
        points: prePoints,
        spacing: math.max(0.8, strokeWidth * 0.35),
      );

      final mesh = SketcherNative.buildCalligraphyMesh(
        points: prePoints,
        strokeWidth: strokeWidth,
        opacity: opacity,
        nibAngleDeg: nibAngleDeg,
        nibWidthFactor: nibWidthFactor,
      );
      if (mesh != null &&
          mesh.positions.isNotEmpty &&
          mesh.indices.isNotEmpty) {
        final colors = List<Color>.generate(mesh.positions.length,
            (i) => color.withValues(alpha: (mesh.alphas[i] * opacity)),
            growable: false);
        final vertices = ui.Vertices(
          VertexMode.triangles,
          mesh.positions,
          colors: colors,
          indices: mesh.indices,
        );

        final paint = Paint()
          ..style = PaintingStyle.fill
          ..isAntiAlias = true;
        canvas.drawVertices(vertices, BlendMode.srcOver, paint);

        stopwatch.stop();
        print(
            '✒️ CALLIGRAPHY: Mesh path in ${stopwatch.elapsedMicroseconds}μs | '
            'V:${mesh.positions.length} I:${mesh.indices.length}');
        return;
      }
    }

    // Use segment calculations if mesh not available
    List<CalligraphySegmentData> segments;
    if (useNative && SketcherNative.isAvailable) {
      segments = _calculateNativeSegments(
          stroke, strokeWidth, opacity, nibAngleDeg, nibWidthFactor);
      _nativeCalculations++;
      print(
          '✒️ CALLIGRAPHY: Native calculation with ${stroke.points.length} points');
    } else {
      segments = _calculateDartSegments(
          stroke, strokeWidth, opacity, nibAngleDeg, nibWidthFactor);
      print(
          '✒️ CALLIGRAPHY: Dart fallback with ${stroke.points.length} points');
    }

    // Cache results
    if (enableCache && cacheKey != null) {
      _segmentCache[cacheKey] = segments;

      // Limit cache size
      if (_segmentCache.length > 100) {
        final oldestKey = _segmentCache.keys.first;
        _segmentCache.remove(oldestKey);
      }
    }

    // Render segments
    _renderSegments(canvas, segments, color, opacity);

    stopwatch.stop();
    print('✒️ CALLIGRAPHY: Completed in ${stopwatch.elapsedMicroseconds}μs | '
        'Segments: ${segments.length} | '
        'Cache: ${_cacheHits}/${_cacheHits + _cacheMisses} hits');
  }

  /// Calculate calligraphy segments using native C++ library
  static List<CalligraphySegmentData> _calculateNativeSegments(
    Stroke stroke,
    double strokeWidth,
    double opacity,
    double nibAngleDeg,
    double nibWidthFactor,
  ) {
    try {
      // Pre-smooth points for better quality
      final smoothedPoints = SketcherNative.smoothStrokePoints(
        points: stroke.points,
        smoothingFactor: 0.3,
      );

      // Calculate segments with native performance
      return SketcherNative.calculateCalligraphySegments(
        points: smoothedPoints,
        strokeWidth: strokeWidth,
        opacity: opacity,
        nibAngleDeg: nibAngleDeg,
        nibWidthFactor: nibWidthFactor,
      );
    } catch (e) {
      print('⚠️  Native calculation failed, falling back to Dart: $e');
      return _calculateDartSegments(
          stroke, strokeWidth, opacity, nibAngleDeg, nibWidthFactor);
    }
  }

  /// Fallback Dart implementation for calligraphy calculations
  static List<CalligraphySegmentData> _calculateDartSegments(
    Stroke stroke,
    double strokeWidth,
    double opacity,
    double nibAngleDeg,
    double nibWidthFactor,
  ) {
    final segments = <CalligraphySegmentData>[];
    final points = stroke.points;

    if (points.length < 2) return segments;

    // SAFETY: Limit processing for extremely long strokes
    final processPoints =
        points.length > 300 ? points.take(300).toList() : points;

    final nibAngleRad = nibAngleDeg * math.pi / 180.0;
    final nibDir = Offset(math.cos(nibAngleRad), math.sin(nibAngleRad));

    for (int i = 0; i < processPoints.length - 1; i++) {
      final a = processPoints[i];
      final b = processPoints[i + 1];
      final seg = b.offset - a.offset;
      final len = seg.distance;

      if (len <= 0.0001) continue;

      final t = seg / len; // unit tangent
      // Thickness follows |sin(theta)| between stroke and nib direction
      final cross = (t.dx * nibDir.dy - t.dy * nibDir.dx).abs();
      final pressure = (a.pressure + b.pressure) * 0.5;
      final widthFactor = nibWidthFactor.clamp(0.3, 2.5);
      final thickness = math.max(
        0.6,
        strokeWidth * widthFactor * (0.35 + 0.9 * cross) * pressure,
      );
      final alpha = opacity * pressure;

      // Create segment
      segments.add(CalligraphySegmentData(
        x1: a.offset.dx,
        y1: a.offset.dy,
        x2: b.offset.dx,
        y2: b.offset.dy,
        thickness: thickness,
        alpha: alpha,
      ));
    }

    return segments;
  }

  /// Render segments with optimized drawing
  static void _renderSegments(
    Canvas canvas,
    List<CalligraphySegmentData> segments,
    Color color,
    double opacity,
  ) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    for (final segment in segments) {
      paint
        ..strokeWidth = segment.thickness
        ..color = color.withValues(alpha: segment.alpha * opacity);

      canvas.drawLine(
        Offset(segment.x1, segment.y1),
        Offset(segment.x2, segment.y2),
        paint,
      );
    }
  }

  /// Render cached segments for maximum performance
  static void _renderCachedSegments(
    Canvas canvas,
    List<CalligraphySegmentData> segments,
    Color color,
    double opacity,
  ) {
    _renderSegments(canvas, segments, color, opacity);
  }

  /// Generate cache key for stroke
  static String _generateCacheKey(
    Stroke stroke,
    double strokeWidth,
    double nibAngleDeg,
    double nibWidthFactor,
  ) {
    final pointsHash = stroke.points.fold<int>(0, (hash, point) {
      return hash ^
          point.offset.dx.hashCode ^
          point.offset.dy.hashCode ^
          point.pressure.hashCode;
    });

    return '${pointsHash}_${strokeWidth.toStringAsFixed(1)}_${nibAngleDeg.toStringAsFixed(1)}_${nibWidthFactor.toStringAsFixed(1)}';
  }

  /// Clear performance caches
  static void clearCache() {
    _segmentCache.clear();
    _cacheHits = 0;
    _cacheMisses = 0;
    _nativeCalculations = 0;
  }

  /// Get performance statistics
  static Map<String, dynamic> getPerformanceStats() {
    final total = _cacheHits + _cacheMisses;
    return {
      'cacheHits': _cacheHits,
      'cacheMisses': _cacheMisses,
      'cacheHitRate': total > 0
          ? (_cacheHits / total * 100).toStringAsFixed(1) + '%'
          : '0%',
      'nativeCalculations': _nativeCalculations,
      'segmentsCached': _segmentCache.length,
    };
  }

  /// Render stroke with adaptive quality based on performance
  static void renderAdaptiveStroke({
    required Canvas canvas,
    required Stroke stroke,
    required double strokeWidth,
    required Color color,
    required double opacity,
    double nibAngleDeg = 45.0,
    double nibWidthFactor = 2.0,
    bool forceHighQuality = false,
  }) {
    // Adaptive quality based on stroke complexity
    final pointCount = stroke.points.length;
    final useNative =
        forceHighQuality || pointCount > 20 || SketcherNative.isAvailable;
    final enableCache = pointCount < 500; // Don't cache very complex strokes

    renderStroke(
      canvas: canvas,
      stroke: stroke,
      strokeWidth: strokeWidth,
      color: color,
      opacity: opacity,
      nibAngleDeg: nibAngleDeg,
      nibWidthFactor: nibWidthFactor,
      enableCache: enableCache,
      useNative: useNative,
    );
  }
}
