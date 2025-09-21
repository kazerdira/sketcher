import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;
import '../models/stroke.dart';
import '../models/drawing_tool.dart';
import '../models/brush_mode.dart';

class SketchPainter extends CustomPainter {
  final List<Stroke> strokes;
  final Stroke? currentStroke;
  final ImageProvider? backgroundImage;
  final double imageOpacity;
  final bool isImageVisible;
  final ui.Image? backgroundImageData;
  final Rect? viewport;
  final Rect? anchoredImageRect;

  // Performance optimization: cache for stroke bounds
  static final Map<Stroke, Rect> _boundsCache = <Stroke, Rect>{};
  static const int _maxCacheSize = 500;

  // Phase 2: Stroke-level caching for rendered strokes
  static final Map<Stroke, ui.Image?> _strokeCache = <Stroke, ui.Image?>{};
  static final Map<Stroke, bool> _strokeDirty = <Stroke, bool>{};
  static const int _maxStrokeCacheSize = 100;

  // Phase 1: Airbrush Performance Optimization
  /// Calculate dynamic performance budget based on stroke complexity
  static int _calculateParticleBudget(int pointCount, double strokeWidth) {
    // Dynamic performance budgeting based on stroke complexity
    final complexity = pointCount + (strokeWidth / 10).round();

    if (complexity > 150) return 6; // Heavy stroke - minimum particles
    if (complexity > 80) return 10; // Medium stroke - reduced particles
    if (complexity > 40) return 15; // Light stroke - moderate particles
    return 20; // Very light stroke - full quality
  }

  /// Viewport culling to skip invisible particles
  static bool _shouldCullParticle(
      Offset position, Rect? viewport, double strokeWidth) {
    if (viewport == null) return false;

    // Expand viewport by stroke width to account for blur effects
    final margin = strokeWidth * 2;
    final expandedViewport = viewport.inflate(margin);

    return !expandedViewport.contains(position);
  }

  /// Draw core stroke foundation to prevent gaps at high drawing speeds
  void _drawAirbrushCore(Canvas canvas, List<DrawingPoint> points,
      Color baseColor, double opacity, double strokeWidth) {
    if (points.length < 2) return;

    for (int i = 0; i < points.length - 1; i++) {
      final a = points[i];
      final b = points[i + 1];
      final corePaint = Paint()
        ..color = baseColor.withValues(alpha: opacity * 0.15)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.5)
        ..strokeWidth =
            math.max(0.5, (a.pressure + b.pressure) * 0.5 * strokeWidth * 0.4);
      canvas.drawLine(a.offset, b.offset, corePaint);
    }
  }

  SketchPainter({
    required this.strokes,
    this.currentStroke,
    this.backgroundImage,
    this.imageOpacity = 0.5,
    this.isImageVisible = true,
    this.backgroundImageData,
    this.viewport,
    this.anchoredImageRect,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw background image if available
    if (isImageVisible && backgroundImageData != null) {
      _drawBackgroundImage(canvas, size);
    }

    // Set up canvas for drawing strokes
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());

    // Draw all completed strokes (with optimized caching)
    for (final stroke in strokes) {
      if (viewport != null && stroke.points.isNotEmpty) {
        if (!_isStrokeVisible(stroke)) continue;
      }
      _drawStrokeOptimized(canvas, stroke);
    }

    // Draw current stroke being drawn (always fresh, no caching)
    if (currentStroke != null) {
      if (viewport != null && currentStroke!.points.isNotEmpty) {
        // For current stroke, be more generous with culling at high zoom levels
        final strokeBounds = _getBoundingRect(currentStroke!.points);
        final generousInflation = math.max(currentStroke!.width * 2, 50.0);
        final inflatedBounds = strokeBounds.inflate(generousInflation);
        if (inflatedBounds.overlaps(viewport!)) {
          _drawStroke(canvas, currentStroke!);
        }
      } else {
        _drawStroke(canvas, currentStroke!);
      }
    }

    canvas.restore();
  }

  void _drawBackgroundImage(Canvas canvas, Size size) {
    if (backgroundImageData == null) return;

    final paint = Paint()
      ..color = Colors.white.withValues(alpha: imageOpacity)
      ..filterQuality = FilterQuality.high;

    final imageSize = Size(
      backgroundImageData!.width.toDouble(),
      backgroundImageData!.height.toDouble(),
    );

    final srcRect = Rect.fromLTWH(0, 0, imageSize.width, imageSize.height);

    if (anchoredImageRect != null) {
      canvas.drawImageRect(
          backgroundImageData!, srcRect, anchoredImageRect!, paint);
      return;
    }

    // Fallback: fit to current canvas size
    final scale = math.min(
      size.width / imageSize.width,
      size.height / imageSize.height,
    );

    final scaledSize = Size(
      imageSize.width * scale,
      imageSize.height * scale,
    );

    final offset = Offset(
      (size.width - scaledSize.width) / 2,
      (size.height - scaledSize.height) / 2,
    );

    final dstRect = Rect.fromLTWH(
      offset.dx,
      offset.dy,
      scaledSize.width,
      scaledSize.height,
    );

    canvas.drawImageRect(backgroundImageData!, srcRect, dstRect, paint);
  }

  void _drawStroke(Canvas canvas, Stroke stroke) {
    if (stroke.points.isEmpty) return;

    final paint = Paint()
      ..color = stroke.color.withValues(alpha: stroke.opacity)
      ..strokeCap = _getStrokeCap(stroke.tool)
      ..strokeJoin = StrokeJoin.round
      ..blendMode = stroke.blendMode
      ..isAntiAlias = true
      ..filterQuality = FilterQuality.high;

    switch (stroke.tool) {
      case DrawingTool.pencil:
        _drawPencilStroke(canvas, stroke, paint);
        break;
      case DrawingTool.pen:
        _drawPenStroke(canvas, stroke, paint);
        break;
      case DrawingTool.marker:
        _drawMarkerStroke(canvas, stroke, paint);
        break;
      case DrawingTool.eraser:
        _drawEraserStroke(canvas, stroke, paint);
        break;
      case DrawingTool.brush:
        _drawBrushStroke(canvas, stroke, paint);
        break;
    }
  }

  // Phase 2: Optimized stroke drawing with caching
  void _drawStrokeOptimized(Canvas canvas, Stroke stroke) {
    if (stroke.points.isEmpty) return;

    // Check if stroke is cached and clean
    if (_strokeCache.containsKey(stroke) && _strokeDirty[stroke] != true) {
      final cachedImage = _strokeCache[stroke];
      if (cachedImage != null) {
        // Draw cached image
        canvas.drawImage(cachedImage, Offset.zero, Paint());
        return;
      }
    }

    // Render stroke normally if not cached
    _drawStroke(canvas, stroke);

    // Mark for caching if cache has space (simplified for now)
    if (_strokeCache.length < _maxStrokeCacheSize) {
      _markStrokeForCaching(stroke);
    }
  }

  // Mark stroke as clean for caching
  void _markStrokeForCaching(Stroke stroke) {
    _strokeDirty[stroke] = false;
    // Note: Actual image caching would require more complex implementation
    // For now, we're just tracking dirty state to avoid expensive recomputation
  }

  // Static methods for cache management
  static void clearStrokeCache() {
    // CRITICAL: Dispose all cached images before clearing to prevent memory leaks
    for (final image in _strokeCache.values) {
      image?.dispose();
    }
    _strokeCache.clear();
    _strokeDirty.clear();
  }

  static void invalidateStroke(Stroke stroke) {
    _strokeDirty[stroke] = true;
    // CRITICAL: Dispose cached image before removing to prevent memory leak
    final cachedImage = _strokeCache.remove(stroke);
    cachedImage?.dispose();
  }

  // Phase 4: Enhanced memory management for bounds cache
  static void clearBoundsCache() {
    _boundsCache.clear();
  }

  static void removeBoundsCache(Stroke stroke) {
    _boundsCache.remove(stroke);
  }

  static void cleanupStrokeCaches(Stroke stroke) {
    // Remove from all caches when a stroke is deleted
    invalidateStroke(stroke);
    removeBoundsCache(stroke);
  }

  static void optimizeCaches() {
    // Phase 4: Implement LRU-style cache optimization
    if (_strokeCache.length > _maxStrokeCacheSize) {
      final excess = _strokeCache.length - (_maxStrokeCacheSize * 3 ~/ 4);
      final oldestKeys = _strokeCache.keys.take(excess).toList();
      for (final key in oldestKeys) {
        // CRITICAL: Dispose cached image before removing to prevent memory leak
        final cachedImage = _strokeCache.remove(key);
        cachedImage?.dispose();
        _strokeDirty.remove(key);
      }
    }

    if (_boundsCache.length > _maxCacheSize) {
      final excess = _boundsCache.length - (_maxCacheSize * 3 ~/ 4);
      final oldestKeys = _boundsCache.keys.take(excess).toList();
      for (final key in oldestKeys) {
        _boundsCache.remove(key);
      }
    }
  }

  void _drawPencilStroke(Canvas canvas, Stroke stroke, Paint paint) {
    // Pencil: textured, pressure-sensitive, slightly transparent
    paint
      ..style = PaintingStyle.stroke
      ..blendMode =
          BlendMode.srcOver; // avoid multiply artifacts over bright colors

    final baseColor = paint.color;

    // Work on an interpolated set of points to reduce gaps/dots
    final points = _interpolatePoints(stroke.points, maxSegmentLen: 3.0);

    if (points.length == 1) {
      // Single point - draw a small circle
      canvas.drawCircle(
        points.first.offset,
        (stroke.width * points.first.pressure) / 2,
        paint..style = PaintingStyle.fill,
      );
      return;
    }

    // Create path with varying width based on pressure
    for (int i = 0; i < points.length - 1; i++) {
      final point1 = points[i];
      final point2 = points[i + 1];

      final width1 = stroke.width * point1.pressure;
      final width2 = stroke.width * point2.pressure;
      final avgWidth = (width1 + width2) / 2;

      // Draw main stroke segment with base color
      paint
        ..color = baseColor
        ..strokeWidth = avgWidth;
      canvas.drawLine(point1.offset, point2.offset, paint);

      // Add subtle texture lines using low alpha; avoid colored specks on bright colors
      final random = math.Random(i * 31);
      for (int j = 0; j < 2; j++) {
        final offset1 = Offset(
          point1.offset.dx + random.nextDouble() * 0.5 - 0.25,
          point1.offset.dy + random.nextDouble() * 0.5 - 0.25,
        );
        final offset2 = Offset(
          point2.offset.dx + random.nextDouble() * 0.5 - 0.25,
          point2.offset.dy + random.nextDouble() * 0.5 - 0.25,
        );

        final isBright = baseColor.computeLuminance() > 0.7;
        final textureAlpha = (baseColor.a * 0.18).clamp(0.05, 0.2);
        final texturePaint = Paint()
          ..color = isBright
              ? Colors.black.withValues(alpha: 0.12)
              : baseColor.withValues(alpha: textureAlpha)
          ..strokeCap = paint.strokeCap
          ..strokeJoin = paint.strokeJoin
          ..blendMode = BlendMode.srcOver
          ..isAntiAlias = true
          ..filterQuality = FilterQuality.high
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(0.5, avgWidth * 0.25);

        canvas.drawLine(offset1, offset2, texturePaint);
      }
    }
  }

  void _drawPenStroke(Canvas canvas, Stroke stroke, Paint paint) {
    // Pen: clean, consistent width, sharp edges
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = stroke.width;

    if (stroke.points.length == 1) {
      canvas.drawCircle(
        stroke.points.first.offset,
        stroke.width / 2,
        paint..style = PaintingStyle.fill,
      );
      return;
    }
    final path =
        _createCatmullRomPath(stroke.points, closed: false, alpha: 0.5);
    canvas.drawPath(path, paint);
  }

  void _drawMarkerStroke(Canvas canvas, Stroke stroke, Paint paint) {
    // Marker: wide, semi-transparent, soft edges
    if (stroke.points.isEmpty) return;

    // Create gradient effect for marker
    final rect = _getBoundingRect(stroke.points);
    final gradient = RadialGradient(
      colors: [
        stroke.color.withValues(alpha: stroke.opacity * 0.8),
        stroke.color.withValues(alpha: stroke.opacity * 0.4),
      ],
      stops: const [0.0, 1.0],
    );

    paint.shader = gradient.createShader(rect);
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = stroke.width;

    if (stroke.points.length == 1) {
      canvas.drawCircle(
        stroke.points.first.offset,
        stroke.width / 2,
        paint..style = PaintingStyle.fill,
      );
      return;
    }

    // Draw main stroke with smooth path
    final path =
        _createCatmullRomPath(stroke.points, closed: false, alpha: 0.5);
    canvas.drawPath(path, paint);

    // Add soft glow effect
    paint
      ..strokeWidth = stroke.width * 1.5
      ..color = stroke.color.withValues(alpha: stroke.opacity * 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);

    canvas.drawPath(path, paint);
  }

  void _drawEraserStroke(Canvas canvas, Stroke stroke, Paint paint) {
    // Feathered dstOut eraser: removes stroke alpha softly without hard squares
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true
      ..strokeWidth = stroke.width
      ..blendMode = BlendMode.dstOut
      ..color = Colors.black.withValues(alpha: 0.95);

    final feather = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true
      ..strokeWidth = stroke.width * 1.5
      ..blendMode = BlendMode.dstOut
      ..color = Colors.black.withValues(alpha: 0.35);

    if (stroke.points.length == 1) {
      canvas.drawCircle(
        stroke.points.first.offset,
        (stroke.width * 1.5) / 2,
        feather..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        stroke.points.first.offset,
        stroke.width / 2,
        base..style = PaintingStyle.fill,
      );
      return;
    }

    final path =
        _createCatmullRomPath(stroke.points, closed: false, alpha: 0.5);
    canvas.drawPath(path, feather);
    canvas.drawPath(path, base);
  }

  void _drawBrushStroke(Canvas canvas, Stroke stroke, Paint paint) {
    // Brush: artistic, pressure-sensitive, textured
    paint.style = PaintingStyle.stroke;

    // Interpolate to keep strokes continuous
    final adaptiveSegLen = math.max(1.5, math.min(3.0, stroke.width * 0.5));
    final points =
        _interpolatePoints(stroke.points, maxSegmentLen: adaptiveSegLen);

    if (points.length == 1) {
      final width = stroke.width * points.first.pressure;
      canvas.drawCircle(
        points.first.offset,
        width / 2,
        paint
          ..style = PaintingStyle.fill
          ..strokeWidth = 0,
      );
      return;
    }

    // If an advanced brush mode is selected, render accordingly
    switch (stroke.brushMode) {
      case null:
        // Phase 3: Optimized default brush with reduced bristle count
        for (int i = 0; i < points.length - 1; i++) {
          final point1 = points[i];
          final point2 = points[i + 1];
          final width1 = stroke.width * point1.pressure;
          final width2 = stroke.width * point2.pressure;
          final bristleCount = (stroke.width / 4)
              .round()
              .clamp(2, 6); // Reduced from 3-10 to 2-6
          for (int bristle = 0; bristle < bristleCount; bristle++) {
            final offset = (bristle - bristleCount / 2) * 0.5;
            final perpendicular =
                _getPerpendicular(point1.offset, point2.offset);
            final bristleOffset = perpendicular * offset;
            final bristleStart = point1.offset + bristleOffset;
            final bristleEnd = point2.offset + bristleOffset;
            final bristleWidth =
                ((width1 + width2) / 2) * (0.7 + 0.3 * (bristle % 2));
            canvas.drawLine(
              bristleStart,
              bristleEnd,
              paint
                ..strokeWidth = bristleWidth / bristleCount
                ..color = paint.color.withValues(
                  alpha: paint.color.a *
                      (0.8 + 0.2 * math.sin(bristle.toDouble())),
                ),
            );
          }
        }
        break;
      case BrushMode.charcoal:
        // Phase 3: Optimized charcoal with reduced particle count
        final baseColor = paint.color;
        final dabPaint = Paint()
          ..style = PaintingStyle.fill
          ..isAntiAlias = true;
        for (final p in points) {
          final w = (stroke.width * p.pressure).clamp(0.5, 200.0);
          dabPaint.color = baseColor.withValues(alpha: stroke.opacity * 0.7);
          canvas.drawCircle(p.offset, w * 0.5, dabPaint);
          // Optimized grain: reduced from 6-18 to 3-8 particles
          final rnd = math.Random(
              p.offset.dx.toInt() * 73856093 ^ p.offset.dy.toInt() * 19349663);
          final grains = (w / 4).round().clamp(3, 8); // Reduced particle count
          for (int i = 0; i < grains; i++) {
            final ang = rnd.nextDouble() * 2 * math.pi;
            final dist = rnd.nextDouble() * w * 0.5;
            final gSize = rnd.nextDouble() * 1.3 + 0.4;
            final gOff = Offset(math.cos(ang) * dist, math.sin(ang) * dist);
            final gColor = baseColor.withValues(
                alpha: stroke.opacity * (0.12 + rnd.nextDouble() * 0.25));
            canvas.drawCircle(p.offset + gOff, gSize, dabPaint..color = gColor);
          }
        }
        break;
      case BrushMode.watercolor:
        // Watercolor: multiple soft, translucent layers with blur
        if (stroke.points.length == 1) {
          final p = points.first;
          final w = (stroke.width * p.pressure).clamp(0.5, 200.0);
          final spotPaint = Paint()
            ..color = paint.color.withValues(alpha: stroke.opacity * 0.25)
            ..style = PaintingStyle.fill
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
          canvas.drawCircle(p.offset, w * 0.6, spotPaint);
          break;
        }
        final path =
            _createCatmullRomPath(stroke.points, closed: false, alpha: 0.5);
        // Phase 3: Simplified watercolor with reduced layers (3 -> 2)
        final layers = [
          {"widthFactor": 1.2, "alpha": 0.22, "blur": 2.5},
          {"widthFactor": 0.9, "alpha": 0.35, "blur": 1.0},
        ];
        for (final layer in layers) {
          final layerPaint = Paint()
            ..color = paint.color
                .withValues(alpha: stroke.opacity * (layer["alpha"] as double))
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..isAntiAlias = true
            ..maskFilter =
                MaskFilter.blur(BlurStyle.normal, layer["blur"] as double)
            ..strokeWidth = stroke.width * (layer["widthFactor"] as double);
          canvas.drawPath(path, layerPaint);
        }
        // Optional: subtle bleed at the end point
        final end = stroke.points.last.offset;
        final bleedPaint = Paint()
          ..color = paint.color.withValues(alpha: stroke.opacity * 0.12)
          ..style = PaintingStyle.fill
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
        canvas.drawCircle(end, stroke.width * 0.6, bleedPaint);
        break;
      case BrushMode.oilPaint:
        // Oil paint: impasto-like layered stroke with subtle highlight
        {
          final path =
              _createCatmullRomPath(stroke.points, closed: false, alpha: 0.5);
          final baseColor = paint.color;

          // Underpaint: slightly darker, wider, soft
          final under = Paint()
            ..color = baseColor.withValues(
                alpha: (stroke.opacity * 0.22).clamp(0.0, 1.0))
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5)
            ..strokeWidth = stroke.width * 1.35;
          canvas.drawPath(path, under);

          // Body paint: main opaque body with slight texture variation
          final body = Paint()
            ..color =
                baseColor.withValues(alpha: stroke.opacity.clamp(0.0, 1.0))
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..strokeWidth = stroke.width;
          canvas.drawPath(path, body);

          // Ridge highlight: lighter sheen along one side based on tangent
          final highlight = Paint()
            ..color = Colors.white.withValues(alpha: (stroke.opacity * 0.18))
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..strokeWidth = math.max(1.0, stroke.width * 0.35)
            ..blendMode = BlendMode.screen;

          // Approximate highlight by stroking a slightly offset path
          final hlPath = Path();
          if (points.isNotEmpty) {
            hlPath.moveTo(points.first.offset.dx, points.first.offset.dy);
            for (int i = 0; i < points.length - 1; i++) {
              final a = points[i].offset;
              final b = points[i + 1].offset;
              final perp = _getPerpendicular(a, b);
              final offsetAmt = math.max(0.6, stroke.width * 0.15);
              final a2 = a + perp * offsetAmt;
              final b2 = b + perp * offsetAmt;
              hlPath.lineTo(b2.dx, b2.dy);
              if (i == 0) {
                hlPath.moveTo(a2.dx, a2.dy);
              }
            }
          }
          canvas.drawPath(hlPath, highlight);

          // Occasional thick daubs along the path to simulate impasto
          final rnd = math.Random(1337);
          for (int i = 0; i < points.length; i += 6) {
            final p = points[i];
            final w = (stroke.width * p.pressure).clamp(0.8, 200.0);
            final daub = Paint()
              ..color = baseColor.withValues(alpha: (stroke.opacity * 0.35))
              ..style = PaintingStyle.fill;
            final rx = w * (0.45 + rnd.nextDouble() * 0.25);
            final ry = w * (0.25 + rnd.nextDouble() * 0.2);
            final ang = rnd.nextDouble() * math.pi;
            canvas.save();
            canvas.translate(p.offset.dx, p.offset.dy);
            canvas.rotate(ang);
            canvas.drawOval(
                Rect.fromCenter(center: Offset.zero, width: rx, height: ry),
                daub);
            canvas.restore();
          }
        }
        break;
      case BrushMode.airbrush:
        // PHASE 1: Industrial-grade airbrush with performance budgeting
        {
          final baseColor = paint.color;

          // Use stroke-consistent seeding to prevent frame-rate variations
          final strokeHash = stroke.points.fold<int>(
              0,
              (hash, p) =>
                  hash ^
                  (p.offset.dx.toInt() * 73856093) ^
                  (p.offset.dy.toInt() * 19349663));
          final rnd = math.Random(strokeHash);

          // Calculate performance budget
          final maxParticlesPerSegment =
              _calculateParticleBudget(points.length, stroke.width);

          // Draw core stroke foundation (prevents gaps at high drawing speeds)
          _drawAirbrushCore(
              canvas, points, baseColor, stroke.opacity, stroke.width);

          // Optimized particle generation
          for (int i = 0; i < points.length - 1; i++) {
            final a = points[i];
            final b = points[i + 1];
            final seg = b.offset - a.offset;
            final len = seg.distance;
            if (len <= 0) continue;

            // CRITICAL OPTIMIZATION: Adaptive particle count
            final speedFactor =
                math.min(len / 10.0, 2.0); // Reduce particles for fast strokes
            final baseCount = (stroke.width * 0.15 * speedFactor)
                .clamp(2, maxParticlesPerSegment) // Use performance budget
                .toInt();

            for (int k = 0; k < baseCount; k++) {
              final t = rnd.nextDouble();
              final p = Offset.lerp(a.offset, b.offset, t)!;

              // Viewport culling: skip invisible particles
              if (_shouldCullParticle(p, viewport, stroke.width)) continue;

              // Rest of particle generation...
              final pr = a.pressure * (1 - t) + b.pressure * t;
              final radius =
                  (stroke.width * (0.15 + rnd.nextDouble() * 0.35) * pr)
                      .clamp(0.4, 6.0);
              final perp = _getPerpendicular(a.offset, b.offset);
              final spread = stroke.width * (0.6 + rnd.nextDouble() * 0.8);
              final jitter =
                  (rnd.nextDouble() - 0.5) + (rnd.nextDouble() - 0.5);
              final offset = perp * (jitter * spread);

              final drop = Paint()
                ..color = baseColor.withValues(
                    alpha: stroke.opacity * (0.05 + rnd.nextDouble() * 0.22))
                ..style = PaintingStyle.fill
                ..isAntiAlias = true
                ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.8);
              canvas.drawCircle(p + offset, radius, drop);
            }
          }
        }
        break;
      case BrushMode.calligraphy:
        // Calligraphy: flat nib with fixed angle causing thick/thin variation
        {
          final baseColor = paint.color;
          final nibAngleDeg =
              stroke.calligraphyNibAngleDeg ?? 40.0; // default if unset
          final nibAngle = nibAngleDeg * math.pi / 180.0;
          final nibDir = Offset(math.cos(nibAngle), math.sin(nibAngle));
          for (int i = 0; i < points.length - 1; i++) {
            final a = points[i];
            final b = points[i + 1];
            final seg = b.offset - a.offset;
            final len = seg.distance;
            if (len <= 0.0001) continue;
            final t = seg / len; // unit tangent
            // Thickness follows |sin(theta)| between stroke and nib direction
            final cross = (t.dx * nibDir.dy - t.dy * nibDir.dx).abs();
            final pressure = (a.pressure + b.pressure) * 0.5;
            final widthFactor =
                (stroke.calligraphyNibWidthFactor ?? 1.0).clamp(0.3, 2.5);
            final thickness = math.max(
              0.6,
              stroke.width * widthFactor * (0.35 + 0.9 * cross) * pressure,
            );
            final core = Paint()
              ..color = baseColor.withValues(alpha: stroke.opacity)
              ..style = PaintingStyle.stroke
              ..strokeCap = StrokeCap.butt
              ..strokeJoin = StrokeJoin.round
              ..isAntiAlias = true
              ..strokeWidth = thickness;
            canvas.drawLine(a.offset, b.offset, core);
            // Soft edge pass to slightly feather the ribbon
            final edge = Paint()
              ..color = baseColor.withValues(alpha: stroke.opacity * 0.25)
              ..style = PaintingStyle.stroke
              ..strokeCap = StrokeCap.butt
              ..strokeJoin = StrokeJoin.round
              ..isAntiAlias = true
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.6)
              ..strokeWidth = thickness * 1.1;
            canvas.drawLine(a.offset, b.offset, edge);
          }
        }
        break;
      case BrushMode.pastel:
        // Pastel: chalky, layered dabs with grain
        {
          final baseColor = paint.color;
          final rnd = math.Random(2718);
          for (final p in points) {
            final w = (stroke.width * p.pressure).clamp(0.5, 220.0);
            // Base smudge
            final base = Paint()
              ..color = baseColor.withValues(alpha: stroke.opacity * 0.35)
              ..style = PaintingStyle.fill
              ..isAntiAlias = true
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.8);
            canvas.drawCircle(p.offset, w * 0.55, base);

            // Chalk body
            final body = Paint()
              ..color = baseColor.withValues(alpha: stroke.opacity * 0.55)
              ..style = PaintingStyle.fill
              ..isAntiAlias = true;
            canvas.drawCircle(p.offset, w * 0.42, body);

            // Grain speckles around
            final grainDensity =
                (stroke.pastelGrainDensity ?? 1.0).clamp(0.3, 3.0);
            final grains = (w * 0.8 * grainDensity).round().clamp(4, 50);
            for (int i = 0; i < grains; i++) {
              final ang = rnd.nextDouble() * 2 * math.pi;
              final dist = rnd.nextDouble() * w * 0.6;
              final gSize = 0.6 + rnd.nextDouble() * 1.4;
              final gOff = Offset(math.cos(ang) * dist, math.sin(ang) * dist);
              final alpha = stroke.opacity * (0.06 + rnd.nextDouble() * 0.24);
              final speck = Paint()
                ..color = baseColor.withValues(alpha: alpha)
                ..style = PaintingStyle.fill
                ..isAntiAlias = true;
              canvas.drawCircle(p.offset + gOff, gSize, speck);
            }
          }
        }
        break;
    }
  }

  // Insert intermediate points along segments longer than maxSegmentLen (pixels)
  List<DrawingPoint> _interpolatePoints(List<DrawingPoint> pts,
      {double maxSegmentLen = 4.0}) {
    if (pts.length < 2) return pts;
    final out = <DrawingPoint>[];
    out.add(pts.first);
    for (int i = 0; i < pts.length - 1; i++) {
      final a = pts[i];
      final b = pts[i + 1];
      final distance = (b.offset - a.offset).distance;
      if (distance <= maxSegmentLen) {
        out.add(b);
        continue;
      }
      final steps = (distance / maxSegmentLen).ceil();
      for (int s = 1; s <= steps; s++) {
        final t = s / steps;
        final o = Offset.lerp(a.offset, b.offset, t)!;
        final p = _lerpDouble(a.pressure, b.pressure, t);
        final ts = _lerpDouble(a.timestamp, b.timestamp, t);
        out.add(DrawingPoint(offset: o, pressure: p, timestamp: ts));
      }
    }
    return out;
  }

  double _lerpDouble(double a, double b, double t) => a + (b - a) * t;

  Offset _getPerpendicular(Offset start, Offset end) {
    final direction = end - start;
    final perpendicular = Offset(-direction.dy, direction.dx);
    final length = perpendicular.distance;
    if (length == 0) return Offset.zero;
    return perpendicular / length;
  }

  StrokeCap _getStrokeCap(DrawingTool tool) {
    switch (tool) {
      case DrawingTool.pencil:
      case DrawingTool.pen:
        return StrokeCap.round;
      case DrawingTool.marker:
      case DrawingTool.brush:
        return StrokeCap.round;
      case DrawingTool.eraser:
        return StrokeCap.round;
    }
  }

  // Catmull–Rom to Bezier conversion for smoother curves
  Path _createCatmullRomPath(List<DrawingPoint> points,
      {bool closed = false, double alpha = 0.5}) {
    final path = Path();
    if (points.length < 2) {
      if (points.isNotEmpty) {
        path.addOval(Rect.fromCircle(center: points.first.offset, radius: 0.5));
      }
      return path;
    }

    final pts = points.map((p) => p.offset).toList(growable: true);
    if (closed) {
      pts.insert(0, pts[pts.length - 2]);
      pts.addAll([pts[1], pts[2]]);
    } else {
      pts.insert(0, pts.first);
      pts.add(pts.last);
    }

    path.moveTo(pts[1].dx, pts[1].dy);

    double tj(Offset pi, Offset pj) {
      final dx = pj.dx - pi.dx;
      final dy = pj.dy - pi.dy;
      final dist = math.sqrt(dx * dx + dy * dy);
      return math.pow(dist, alpha).toDouble();
    }

    for (int i = 1; i < pts.length - 2; i++) {
      final p0 = pts[i - 1];
      final p1 = pts[i];
      final p2 = pts[i + 1];
      final p3 = pts[i + 2];

      final t01 = tj(p0, p1);
      final t12 = tj(p1, p2);
      final t23 = tj(p2, p3);

      double m1x = 0.0, m1y = 0.0, m2x = 0.0, m2y = 0.0;
      if (t12 > 0) {
        m1x = (p2.dx - p0.dx) / (t01 + t12);
        m1y = (p2.dy - p0.dy) / (t01 + t12);
        m2x = (p3.dx - p1.dx) / (t12 + t23);
        m2y = (p3.dy - p1.dy) / (t12 + t23);
      }

      final cp1 = Offset(
        p1.dx + m1x * t12 / 3.0,
        p1.dy + m1y * t12 / 3.0,
      );
      final cp2 = Offset(
        p2.dx - m2x * t12 / 3.0,
        p2.dy - m2y * t12 / 3.0,
      );

      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p2.dx, p2.dy);
    }

    return path;
  }

  Rect _getBoundingRect(List<DrawingPoint> points) {
    if (points.isEmpty) return Rect.zero;

    double minX = points.first.offset.dx;
    double maxX = points.first.offset.dx;
    double minY = points.first.offset.dy;
    double maxY = points.first.offset.dy;

    for (final point in points) {
      minX = math.min(minX, point.offset.dx);
      maxX = math.max(maxX, point.offset.dx);
      minY = math.min(minY, point.offset.dy);
      maxY = math.max(maxY, point.offset.dy);
    }

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  // Enhanced viewport culling with bounds caching
  bool _isStrokeVisible(Stroke stroke) {
    if (viewport == null || stroke.points.isEmpty) return true;

    // Use cached bounds or compute new ones
    Rect bounds;
    if (_boundsCache.containsKey(stroke)) {
      bounds = _boundsCache[stroke]!;
    } else {
      bounds = _getBoundingRect(stroke.points);
      _cacheStrokeBounds(stroke, bounds);
    }

    // Be more generous with inflation at high zoom levels
    // At high zoom, even small strokes should be visible if they're near the viewport
    final baseInflation = stroke.width;
    final generousInflation = math.max(baseInflation, 20.0);
    final inflatedBounds = bounds.inflate(generousInflation);
    return viewport!.overlaps(inflatedBounds);
  }

  void _cacheStrokeBounds(Stroke stroke, Rect bounds) {
    // Phase 4: Improved bounds cache management
    if (_boundsCache.length >= _maxCacheSize) {
      optimizeCaches(); // Use centralized cache optimization
    }
    _boundsCache[stroke] = bounds;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is! SketchPainter) {
      print('🎨 REPAINT: Different painter type - repaint TRUE');
      return true;
    }

    final old = oldDelegate;

    // Fast checks first - most common cases
    // Repaint when current stroke changes (for live drawing)
    if (!identical(old.currentStroke, currentStroke)) {
      print('🎨 REPAINT: Current stroke changed - repaint TRUE');
      return true;
    }

    // Repaint when stroke count changes (especially for undo)
    if (old.strokes.length != strokes.length) {
      print(
          '🎨 REPAINT: Stroke count changed ${old.strokes.length} -> ${strokes.length} - repaint TRUE');
      return true;
    }

    // Efficient reference check - if list reference changed, we need to repaint
    // This avoids expensive per-stroke comparisons
    if (!identical(old.strokes, strokes)) {
      print('🎨 REPAINT: Strokes list reference changed - repaint TRUE');
      return true;
    }

    // Background property checks
    if (old.backgroundImage != backgroundImage) {
      print('🎨 REPAINT: Background image changed - repaint TRUE');
      return true;
    }
    if (old.imageOpacity != imageOpacity) {
      print('🎨 REPAINT: Image opacity changed - repaint TRUE');
      return true;
    }
    if (old.isImageVisible != isImageVisible) {
      print('🎨 REPAINT: Image visibility changed - repaint TRUE');
      return true;
    }

    // Repaint when anchored image rect changes
    if (old.anchoredImageRect != anchoredImageRect) {
      print('🎨 REPAINT: Anchored image rect changed - repaint TRUE');
      return true;
    }

    // If we reach here, no changes detected
    print('🎨 REPAINT: No changes detected - repaint FALSE');
    return false;
  }
}
