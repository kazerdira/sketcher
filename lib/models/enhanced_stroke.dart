import 'package:flutter/material.dart';
import 'drawing_tool.dart';

class EnhancedStroke {
  final List<StrokePoint> points;
  final ToolSettings toolSettings;
  final String id;
  final DateTime createdAt;
  final Rect? bounds;
  final List<Offset>? smoothedPoints;

  const EnhancedStroke({
    required this.points,
    required this.toolSettings,
    required this.id,
    required this.createdAt,
    this.bounds,
    this.smoothedPoints,
  });

  EnhancedStroke copyWith({
    List<StrokePoint>? points,
    ToolSettings? toolSettings,
    String? id,
    DateTime? createdAt,
    Rect? bounds,
    List<Offset>? smoothedPoints,
  }) {
    return EnhancedStroke(
      points: points ?? this.points,
      toolSettings: toolSettings ?? this.toolSettings,
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      bounds: bounds ?? this.bounds,
      smoothedPoints: smoothedPoints ?? this.smoothedPoints,
    );
  }

  // Calculate stroke bounds
  Rect calculateBounds() {
    if (points.isEmpty) return Rect.zero;

    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    final maxSize = points.map((p) => p.size).reduce((a, b) => a > b ? a : b);
    final padding = maxSize / 2;

    for (final point in points) {
      minX = minX < point.position.dx ? minX : point.position.dx;
      minY = minY < point.position.dy ? minY : point.position.dy;
      maxX = maxX > point.position.dx ? maxX : point.position.dx;
      maxY = maxY > point.position.dy ? maxY : point.position.dy;
    }

    return Rect.fromLTRB(
      minX - padding,
      minY - padding,
      maxX + padding,
      maxY + padding,
    );
  }

  // Calculate smoothed points using Catmull-Rom splines
  List<Offset> calculateSmoothedPoints({
    double tension = 0.5,
    int segments = 10,
  }) {
    if (points.length < 2) return points.map((p) => p.position).toList();
    if (points.length == 2) return [points[0].position, points[1].position];

    final smoothed = <Offset>[];
    final positions = points.map((p) => p.position).toList();

    // Add first point
    smoothed.add(positions[0]);

    for (int i = 1; i < positions.length - 1; i++) {
      final p0 = i > 0 ? positions[i - 1] : positions[i];
      final p1 = positions[i];
      final p2 = positions[i + 1];
      final p3 = i < positions.length - 2 ? positions[i + 2] : positions[i + 1];

      for (int j = 1; j <= segments; j++) {
        final t = j / segments;
        final point = _catmullRomSpline(p0, p1, p2, p3, t, tension);
        smoothed.add(point);
      }
    }

    // Add last point
    smoothed.add(positions.last);

    return smoothed;
  }

  Offset _catmullRomSpline(
    Offset p0,
    Offset p1,
    Offset p2,
    Offset p3,
    double t,
    double tension,
  ) {
    final t2 = t * t;
    final t3 = t2 * t;

    final v0 = (p2 - p0) * tension;
    final v1 = (p3 - p1) * tension;

    final x =
        (2 * p1.dx - 2 * p2.dx + v0.dx + v1.dx) * t3 +
        (-3 * p1.dx + 3 * p2.dx - 2 * v0.dx - v1.dx) * t2 +
        v0.dx * t +
        p1.dx;

    final y =
        (2 * p1.dy - 2 * p2.dy + v0.dy + v1.dy) * t3 +
        (-3 * p1.dy + 3 * p2.dy - 2 * v0.dy - v1.dy) * t2 +
        v0.dy * t +
        p1.dy;

    return Offset(x, y);
  }

  // Calculate stroke length
  double get length {
    if (points.length < 2) return 0.0;

    double totalLength = 0.0;
    for (int i = 1; i < points.length; i++) {
      totalLength += (points[i].position - points[i - 1].position).distance;
    }
    return totalLength;
  }

  // Get stroke statistics
  Map<String, dynamic> get statistics {
    if (points.isEmpty) return {};

    final pressures = points.map((p) => p.pressure).toList();
    final velocities = points.map((p) => p.velocity).toList();
    final sizes = points.map((p) => p.size).toList();

    return {
      'pointCount': points.length,
      'length': length,
      'duration': points.last.timestamp - points.first.timestamp,
      'avgPressure': pressures.reduce((a, b) => a + b) / pressures.length,
      'maxPressure': pressures.reduce((a, b) => a > b ? a : b),
      'minPressure': pressures.reduce((a, b) => a < b ? a : b),
      'avgVelocity': velocities.reduce((a, b) => a + b) / velocities.length,
      'maxVelocity': velocities.reduce((a, b) => a > b ? a : b),
      'avgSize': sizes.reduce((a, b) => a + b) / sizes.length,
      'bounds': calculateBounds(),
    };
  }
}
