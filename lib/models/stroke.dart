import 'dart:ui';

/// Basic stroke model used by the sketching app.
class Stroke {
  Stroke({
    required this.color,
    required this.width,
    required this.points,
    this.pressures = const [],
  });

  final Color color;
  final double width;
  final List<Offset> points;
  final List<double> pressures; // Optional per-point pressure

  bool get isEmpty => points.isEmpty;
  bool get isSinglePoint => points.length == 1;
}
