import 'package:flutter/material.dart';

class ProGradientTrackShape extends RoundedRectSliderTrackShape {
  final LinearGradient gradient;
  final Color inactiveColor;

  const ProGradientTrackShape({
    required this.gradient,
    required this.inactiveColor,
  });

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    Offset? secondaryOffset,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    bool isDiscrete = false,
    bool isEnabled = false,
    double additionalActiveTrackHeight = 2,
  }) {
    final Canvas canvas = context.canvas;
    final double trackHeight = sliderTheme.trackHeight ?? 4;
    final Rect trackRect = Rect.fromLTWH(
      offset.dx,
      offset.dy + (parentBox.size.height - trackHeight) / 2,
      parentBox.size.width,
      trackHeight,
    );
    final RRect rRect = RRect.fromRectAndRadius(
      trackRect,
      Radius.circular(trackHeight / 2),
    );

    final Paint inactivePaint = Paint()..color = inactiveColor;
    canvas.drawRRect(rRect, inactivePaint);

    final bool ltr = textDirection == TextDirection.ltr;
    Rect activeRect = ltr
        ? Rect.fromLTRB(
            trackRect.left, trackRect.top, thumbCenter.dx, trackRect.bottom)
        : Rect.fromLTRB(
            thumbCenter.dx, trackRect.top, trackRect.right, trackRect.bottom);

    final Paint activePaint = Paint()
      ..shader = gradient.createShader(trackRect);
    canvas.save();
    canvas.clipRRect(rRect);
    canvas.drawRect(activeRect, activePaint);
    canvas.restore();
  }
}
