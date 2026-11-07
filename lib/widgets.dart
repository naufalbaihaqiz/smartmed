import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'demo_data.dart';

class Brand extends StatelessWidget {
  const Brand({super.key, this.compact = false});
  final bool compact;
  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.scaleDown,
    alignment: Alignment.centerLeft,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: compact ? 28 : 34,
          height: compact ? 28 : 34,
          decoration: BoxDecoration(
            color: teal,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(Icons.spa_rounded, color: paper, size: compact ? 17 : 21),
        ),
        const SizedBox(width: 9),
        Text(
          'temanrawat',
          style: TextStyle(
            fontSize: compact ? 18 : 21,
            color: ink,
            fontWeight: FontWeight.w700,
            letterSpacing: -.8,
          ),
        ),
      ],
    ),
  );
}

class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: muted,
      fontSize: 10,
      letterSpacing: 1.5,
      fontWeight: FontWeight.w600,
    ),
  );
}

class Surface extends StatelessWidget {
  const Surface({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(23),
    decoration: BoxDecoration(
      color: paper,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: line),
    ),
    child: child,
  );
}

class BadgePill extends StatelessWidget {
  const BadgePill(this.text, {super.key, this.color = paleTeal});
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      text,
      style: const TextStyle(
        color: ink,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class Notice extends StatelessWidget {
  const Notice({super.key, required this.text, required this.icon});
  final String text;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(
      color: paleTeal,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: teal, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: teal, fontSize: 12, height: 1.7),
          ),
        ),
      ],
    ),
  );
}

/// Vector artwork keeps the prototype available without external image services.
class CareIllustration extends StatelessWidget {
  const CareIllustration({super.key});
  @override
  Widget build(BuildContext context) => CustomPaint(painter: _CarePainter());
}

class _CarePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 360, size.height / 290);
    final p = Paint();
    void oval(Rect r, Color c) => canvas.drawOval(r, p..color = c);
    void box(Rect r, double radius, Color c) => canvas.drawRRect(
      RRect.fromRectAndRadius(r, Radius.circular(radius)),
      p..color = c,
    );
    oval(const Rect.fromLTWH(24, 12, 300, 300), const Color(0xFF247B71));
    oval(const Rect.fromLTWH(55, 228, 260, 30), const Color(0xFF075B54));
    box(const Rect.fromLTWH(205, 36, 85, 105), 40, const Color(0xFF4D9282));
    oval(const Rect.fromLTWH(225, 51, 37, 37), const Color(0xFFEEC8A2));
    canvas.drawLine(
      const Offset(247, 38),
      const Offset(247, 140),
      p
        ..color = teal
        ..strokeWidth = 5,
    );
    box(const Rect.fromLTWH(74, 139, 125, 102), 22, const Color(0xFFE5AC89));
    box(const Rect.fromLTWH(67, 184, 27, 62), 12, const Color(0xFFD79471));
    box(const Rect.fromLTWH(181, 184, 27, 62), 12, const Color(0xFFD79471));
    box(const Rect.fromLTWH(104, 209, 70, 47), 10, const Color(0xFFF1E7D4));
    oval(const Rect.fromLTWH(108, 115, 60, 67), const Color(0xFFEEE5D3));
    oval(const Rect.fromLTWH(118, 95, 40, 47), const Color(0xFFE6B38F));
    oval(const Rect.fromLTWH(113, 88, 48, 29), const Color(0xFFC8D0C1));
    box(const Rect.fromLTWH(111, 153, 62, 35), 10, const Color(0xFFFCF4E5));
    box(const Rect.fromLTWH(212, 115, 62, 105), 25, const Color(0xFFA9CBB4));
    box(const Rect.fromLTWH(218, 208, 20, 47), 8, const Color(0xFFF0E8D7));
    box(const Rect.fromLTWH(247, 208, 20, 47), 8, const Color(0xFFF0E8D7));
    oval(const Rect.fromLTWH(222, 62, 45, 56), const Color(0xFF173B3A));
    oval(const Rect.fromLTWH(226, 75, 35, 39), const Color(0xFFECC2A2));
    oval(const Rect.fromLTWH(221, 62, 43, 24), const Color(0xFF173B3A));
    final arm = Path()
      ..moveTo(219, 132)
      ..quadraticBezierTo(201, 160, 169, 157);
    canvas.drawPath(
      arm,
      p
        ..color = const Color(0xFFECC2A2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 15
        ..strokeCap = StrokeCap.round,
    );
    p.style = PaintingStyle.fill;
    box(const Rect.fromLTWH(160, 151, 35, 26), 4, const Color(0xFFFFF9EA));
    box(const Rect.fromLTWH(301, 219, 27, 34), 5, const Color(0xFFEBC19C));
    canvas.drawLine(
      const Offset(314, 221),
      const Offset(314, 158),
      p
        ..color = const Color(0xFFA9CBB4)
        ..strokeWidth = 3,
    );
    oval(const Rect.fromLTWH(291, 167, 25, 12), const Color(0xFFA9CBB4));
    oval(const Rect.fromLTWH(313, 184, 25, 12), const Color(0xFF88B69D));
    oval(const Rect.fromLTWH(300, 146, 15, 24), const Color(0xFF88B69D));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CarePainter oldDelegate) => false;
}

class FoodIllustration extends StatelessWidget {
  const FoodIllustration({super.key, this.kind = 0});
  final int kind;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 180,
    height: 140,
    child: CustomPaint(painter: _FoodPainter(kind)),
  );
}

class _FoodPainter extends CustomPainter {
  const _FoodPainter(this.kind);
  final int kind;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 180, size.height / 140);
    final p = Paint();
    canvas.drawOval(
      const Rect.fromLTWH(25, 107, 135, 19),
      p..color = const Color(0x1A173B3A),
    );
    canvas.drawOval(const Rect.fromLTWH(22, 22, 136, 99), p..color = paper);
    canvas.drawOval(
      const Rect.fromLTWH(31, 29, 118, 81),
      p..color = const Color(0xFFD6DED2),
    );
    canvas.drawOval(
      const Rect.fromLTWH(35, 31, 110, 74),
      p..color = kind == 1 ? const Color(0xFFDCC99F) : const Color(0xFFE8BF70),
    );
    for (int i = 0; i < 9; i++) {
      final x = 61 + math.cos(i * 2.4) * 29 + (i.isEven ? 20 : 0);
      final y = 62 + math.sin(i * 2.4) * 22;
      if (kind == 1) {
        canvas.drawCircle(Offset(x, y), 9, p..color = const Color(0xFFF8E5AF));
        canvas.drawCircle(Offset(x, y), 3, p..color = const Color(0xFFC5A46B));
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, y, 15, 11),
            const Radius.circular(4),
          ),
          p
            ..color = i % 3 == 0
                ? const Color(0xFFEA9759)
                : i % 3 == 1
                ? const Color(0xFF719C65)
                : const Color(0xFFFFE5AF),
        );
      }
    }
    canvas.drawLine(
      const Offset(154, 42),
      const Offset(143, 109),
      p
        ..color = const Color(0xFF9BA79B)
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawOval(
      const Rect.fromLTWH(145, 27, 17, 26),
      p..color = const Color(0xFF9BA79B),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _FoodPainter oldDelegate) =>
      kind != oldDelegate.kind;
}
