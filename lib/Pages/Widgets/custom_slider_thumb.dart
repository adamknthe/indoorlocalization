import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class CustomSliderThumbRect extends SliderComponentShape {
  final double thumbRadius;
  final thumbHeight;
  final int min;
  final int max;
  final Color textColor;
  final Color thumbColor;

  const CustomSliderThumbRect( {
    required this.thumbRadius,
    this.thumbHeight,
     required this.min,
    required this.max,
    required this.textColor,
    required this.thumbColor
  });

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(thumbRadius);
  }

  @override
  void paint(
      PaintingContext context,
      Offset center, {
        required Animation<double> activationAnimation,
        required Animation<double> enableAnimation,
        required bool isDiscrete,
        required TextPainter labelPainter,
        required RenderBox parentBox,
        required SliderThemeData sliderTheme,
        required TextDirection textDirection,
        required double value,
        required double textScaleFactor,
        required Size sizeWithOverflow,
      }) {
    final Canvas canvas = context.canvas;

    final rRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
          center: center, width: thumbHeight , height: thumbHeight ),
      Radius.circular(thumbRadius * .4),
    );

    final paint = Paint()
      ..color = thumbColor //Thumb Background Color
      ..style = PaintingStyle.fill;

    TextSpan span = new TextSpan(
        style: new TextStyle(
            fontSize: thumbHeight * .7,
            fontWeight: FontWeight.w700,
            color: textColor,
            height: 1),
        text: '${getValue(value)}');
    TextPainter tp = new TextPainter(
        text: span,
        textAlign: TextAlign.left,
        textDirection: TextDirection.ltr);
    tp.layout();
    Offset textCenter =
    Offset(center.dx - (tp.width / 2), center.dy - (tp.height / 2));

    canvas.drawRRect(rRect, paint);
    canvas.save();
    final pivot = tp.size.center(textCenter);
    canvas.translate(pivot.dx, pivot.dy);
    canvas.rotate(degToRadian(90));
    canvas.translate(-pivot.dx, -pivot.dy);
    tp.paint(canvas, textCenter);
    canvas.restore();
    //tp.paint(canvas, textCenter);
  }

  String getValue(double value) {
    return (min+(max-min)*value).round().toString();
  }
}

