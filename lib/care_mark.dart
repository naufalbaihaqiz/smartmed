import 'package:flutter/material.dart';

import 'palette.dart';

/// Two figures lean toward one another to represent shared care.
class CareLogo extends StatelessWidget {
  const CareLogo({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: const CustomPaint(painter: _LogoPainter()),
  );
}

class _LogoPainter extends CustomPainter {
  const _LogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 64, size.height / 64);
    final paint = Paint()..color = ink;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, 0, 64, 64),
        const Radius.circular(13),
      ),
      paint,
    );

    final figure = Path()
      ..moveTo(11, 35)
      ..cubicTo(11, 28, 16, 24, 22, 24)
      ..cubicTo(28, 24, 32, 28, 36, 33)
      ..lineTo(31, 39)
      ..cubicTo(27, 34, 25, 32, 22, 32)
      ..cubicTo(19, 32, 18, 34, 18, 37)
      ..cubicTo(18, 42, 24, 46, 32, 50)
      ..cubicTo(20, 49, 11, 43, 11, 35)
      ..close();

    canvas.drawCircle(const Offset(22, 16), 4.5, paint..color = cream);
    canvas.drawCircle(const Offset(42, 16), 4.5, paint..color = signal);
    canvas.drawPath(figure, paint..color = cream);
    canvas.translate(64, 0);
    canvas.scale(-1, 1);
    canvas.drawPath(figure, paint..color = signal);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_LogoPainter oldDelegate) => false;
}

class CareArtwork extends StatelessWidget {
  const CareArtwork({super.key});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: MediaQuery.sizeOf(context).width < 400 ? 195 : 218,
    child: const Center(
      child: CustomPaint(size: Size(210, 175), painter: _FigmaCarePainter()),
    ),
  );
}

class _FigmaCarePainter extends CustomPainter {
  const _FigmaCarePainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 180, size.height / 150);
    final paint = Paint();
    final outerHeart = Path()
      ..moveTo(91, 119)
      ..relativeCubicTo(-5, -9, -13, -17, -23, -23)
      ..relativeCubicTo(-13, -8, -22, -18, -25, -31)
      ..relativeCubicTo(-2, -8, 1, -18, 8, -23)
      ..relativeCubicTo(8, -6, 19, -4, 25, 3)
      ..relativeLineTo(15, 17)
      ..relativeLineTo(15, -17)
      ..relativeCubicTo(6, -7, 17, -9, 25, -3)
      ..relativeCubicTo(7, 5, 10, 15, 8, 23)
      ..relativeCubicTo(-3, 13, -12, 23, -25, 31)
      ..relativeCubicTo(-10, 6, -18, 14, -23, 23)
      ..close();
    canvas.drawPath(outerHeart, paint..color = red);
    final leftHand = Path()
      ..moveTo(87, 122)
      ..relativeCubicTo(-12, 8, -29, 10, -43, 2)
      ..lineTo(15, 107)
      ..relativeCubicTo(-5, -3, -7, -9, -4, -14)
      ..relativeCubicTo(3, -5, 9, -6, 14, -3)
      ..relativeLineTo(21, 12)
      ..relativeLineTo(-25, -27)
      ..relativeCubicTo(-4, -4, -4, -11, 1, -15)
      ..relativeCubicTo(4, -3, 10, -3, 14, 1)
      ..relativeLineTo(24, 25)
      ..relativeLineTo(-16, -28)
      ..relativeCubicTo(-3, -5, -1, -11, 4, -14)
      ..relativeCubicTo(5, -2, 11, 0, 14, 5)
      ..relativeLineTo(24, 42)
      ..relativeCubicTo(6, 11, 6, 22, 1, 31)
      ..close();
    canvas.drawPath(leftHand, paint..color = teal);
    final rightHand = Path()
      ..moveTo(94, 122)
      ..relativeCubicTo(12, 8, 29, 10, 43, 2)
      ..relativeLineTo(29, -17)
      ..relativeCubicTo(5, -3, 7, -9, 4, -14)
      ..relativeCubicTo(-3, -5, -9, -6, -14, -3)
      ..relativeLineTo(-21, 12)
      ..relativeLineTo(25, -27)
      ..relativeCubicTo(4, -4, 4, -11, -1, -15)
      ..relativeCubicTo(-4, -3, -10, -3, -14, 1)
      ..relativeLineTo(-24, 25)
      ..relativeLineTo(16, -28)
      ..relativeCubicTo(3, -5, 1, -11, -4, -14)
      ..relativeCubicTo(-5, -2, -11, 0, -14, 5)
      ..lineTo(95, 91)
      ..relativeCubicTo(-6, 11, -6, 22, -1, 31)
      ..close();
    canvas.drawPath(rightHand, paint..color = red.withValues(alpha: .92));
    final innerHeart = Path()
      ..moveTo(90, 88)
      ..relativeCubicTo(-4, -8, -14, -17, -20, -23)
      ..relativeCubicTo(-5, -5, -5, -13, 0, -18)
      ..relativeCubicTo(5, -4, 12, -4, 17, 1)
      ..relativeLineTo(3, 4)
      ..relativeLineTo(4, -4)
      ..relativeCubicTo(5, -5, 12, -5, 17, -1)
      ..relativeCubicTo(5, 5, 5, 13, 0, 18)
      ..relativeCubicTo(-6, 6, -16, 15, -21, 23)
      ..close();
    canvas.drawPath(innerHeart, paint..color = cream);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_FigmaCarePainter oldDelegate) => false;
}
