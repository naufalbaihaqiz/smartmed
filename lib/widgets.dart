import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'care_api.dart';
import 'care_mark.dart';
import 'palette.dart';

/// Pembungkus responsif agar tampilan selalu proporsional di ponsel maupun layar lebar.
class MobileFrame extends StatelessWidget {
  const MobileFrame({
    super.key,
    required this.child,
    this.backgroundColor = cream,
  });

  final Widget child;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isWide = screenWidth > 520;
    return ColoredBox(
      color: isWide ? shellBackground : backgroundColor,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: backgroundColor,
              boxShadow: isWide
                  ? const [
                      BoxShadow(
                        color: Color(0x14113826),
                        blurRadius: 32,
                        offset: Offset(0, 8),
                      ),
                    ]
                  : null,
            ),
            child: SizedBox.expand(child: child),
          ),
        ),
      ),
    );
  }
}

class Brand extends StatelessWidget {
  const Brand({super.key, this.compact = false, this.subtitle});
  final bool compact;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      CareLogo(size: compact ? 38 : 44),
      const SizedBox(width: 11),
      Flexible(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TemanRawat',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: compact ? 18.5 : 22,
                color: ink,
                fontWeight: FontWeight.w800,
                letterSpacing: -.6,
                height: 1.1,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: muted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    ],
  );
}

class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key, this.color = teal});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: TextStyle(
      color: color,
      fontSize: 10.5,
      letterSpacing: 1.3,
      fontWeight: FontWeight.w700,
    ),
  );
}

class Surface extends StatelessWidget {
  const Surface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.color = paper,
    this.borderColor = line,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final Color borderColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final box = Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A143526),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: onTap == null
            ? Padding(padding: padding, child: child)
            : InkWell(
                onTap: onTap,
                child: Padding(padding: padding, child: child),
              ),
      ),
    );
    return box;
  }
}

class BadgePill extends StatelessWidget {
  const BadgePill(
    this.text, {
    super.key,
    this.color = paleTeal,
    this.textColor = ink,
    this.icon,
  });

  final String text;
  final Color color;
  final Color textColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 13.5, color: textColor),
          const SizedBox(width: 5),
        ],
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: textColor,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

/// Lencana status jadwal pasien (Jadwal Selesai vs Belum Selesai).
class ScheduleStatusBadge extends StatelessWidget {
  const ScheduleStatusBadge({super.key, required this.completed});

  final bool completed;

  @override
  Widget build(BuildContext context) => BadgePill(
    completed ? 'Jadwal Selesai' : 'Belum Selesai',
    color: completed ? successSoft : warningSoft,
    textColor: completed ? successGreen : warningAmber,
    icon: completed ? Icons.check_circle_rounded : Icons.schedule_rounded,
  );
}

class Notice extends StatelessWidget {
  const Notice({
    super.key,
    required this.text,
    required this.icon,
    this.isError = false,
  });

  final String text;
  final IconData icon;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final bg = isError ? softRed : paleTeal;
    final fg = isError ? red : teal;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: fg.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: fg, size: 20),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: fg,
                fontSize: 13,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class IconTile extends StatelessWidget {
  const IconTile(
    this.icon, {
    super.key,
    this.accent = false,
    this.backgroundColor,
    this.iconColor,
    this.size = 44,
  });

  final IconData icon;
  final bool accent;
  final Color? backgroundColor;
  final Color? iconColor;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: backgroundColor ?? (accent ? ink : paleTeal),
      borderRadius: BorderRadius.circular(13),
    ),
    child: Icon(
      icon,
      size: size * 0.48,
      color: iconColor ?? (accent ? signal : teal),
    ),
  );
}

class EmptyPanel extends StatelessWidget {
  const EmptyPanel({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.action,
  });

  final IconData icon;
  final String title, description;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Surface(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
    child: Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: paleTeal,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(icon, size: 30, color: teal),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          description,
          textAlign: TextAlign.center,
          style: const TextStyle(color: muted, fontSize: 13.5, height: 1.55),
        ),
        if (action != null) ...[
          const SizedBox(height: 20),
          action!,
        ],
      ],
    ),
  );
}

/// Deretan ringkasan gizi (Kalori, Protein, Karbo, Lemak).
class NutritionBadges extends StatelessWidget {
  const NutritionBadges({super.key, required this.nutrition});

  final Json nutrition;

  String _fmt(Object? v) {
    if (v is num) {
      return v == v.roundToDouble()
          ? v.round().toString()
          : v.toStringAsFixed(1);
    }
    return '-';
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Kalori', '${_fmt(nutrition['calories'])} kkal', Icons.local_fire_department_rounded),
      ('Protein', '${_fmt(nutrition['protein'])} g', Icons.fitness_center_rounded),
      ('Karbo', '${_fmt(nutrition['carbohydrates'])} g', Icons.grain_rounded),
      ('Lemak', '${_fmt(nutrition['fat'])} g', Icons.water_drop_outlined),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final (label, val, icon) in items)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: slate,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: teal),
                const SizedBox(width: 5),
                Text(
                  '$label: ',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: muted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  val,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Kartu resep makanan modern dengan detail bahan & cara memasak.
class RecipeCard extends StatelessWidget {
  const RecipeCard({
    super.key,
    required this.meal,
    this.index = 0,
  });

  final Json meal;
  final int index;

  @override
  Widget build(BuildContext context) {
    final name = meal['recipe_name'] as String? ?? 'Menu Sehat';
    final description = meal['description'] as String?;
    final servings = meal['servings'] ?? 1;
    final cookingTime = meal['cooking_time'] ?? 20;
    final source = meal['source'] as String?;
    final nutrition = meal['nutrition'] is Map
        ? Map<String, dynamic>.from(meal['nutrition'] as Map)
        : null;
    final ingredients = (meal['ingredients'] as List? ?? const [])
        .whereType<Map>()
        .toList();

    return Surface(
      onTap: () => showRecipeDetailSheet(context, meal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconTile(
                index.isEven
                    ? Icons.soup_kitchen_rounded
                    : Icons.dinner_dining_rounded,
                backgroundColor: paleTeal,
                iconColor: teal,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 10,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.people_alt_outlined,
                              size: 14,
                              color: muted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$servings porsi',
                              style: const TextStyle(
                                color: muted,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.timer_outlined,
                              size: 14,
                              color: muted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$cookingTime menit',
                              style: const TextStyle(
                                color: muted,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                        if (ingredients.isNotEmpty)
                          Text(
                            '· ${ingredients.length} bahan',
                            style: const TextStyle(
                              color: muted,
                              fontSize: 12.5,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: muted),
            ],
          ),
          if (description != null && description.trim().isNotEmpty) ...[
            const SizedBox(height: 11),
            Text(
              description,
              style: const TextStyle(color: muted, fontSize: 13.5, height: 1.45),
            ),
          ],
          if (nutrition != null) ...[
            const SizedBox(height: 12),
            NutritionBadges(nutrition: nutrition),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: source != null && source.trim().isNotEmpty
                    ? Align(
                        alignment: Alignment.centerLeft,
                        child: BadgePill(
                          source,
                          icon: Icons.auto_awesome_rounded,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(width: 8),
              const Text(
                'Lihat detail',
                style: TextStyle(
                  color: teal,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_forward_rounded, size: 15, color: teal),
            ],
          ),
        ],
      ),
    );
  }
}

Future<void> showRecipeDetailSheet(BuildContext context, Json meal) {
  final name = meal['recipe_name'] as String? ?? 'Detail Resep';
  final description = meal['description'] as String?;
  final servings = meal['servings'] ?? 1;
  final cookingTime = meal['cooking_time'] ?? 20;
  final instructions = meal['instructions'] as String? ?? '';
  final source = meal['source'] as String?;
  final ingredients = (meal['ingredients'] as List? ?? const [])
      .whereType<Map>()
      .map(Map<String, dynamic>.from)
      .toList();
  final nutrition = meal['nutrition'] is Map
      ? Map<String, dynamic>.from(meal['nutrition'] as Map)
      : null;

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: paper,
    constraints: const BoxConstraints(maxWidth: 480),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.78,
      minChildSize: 0.5,
      maxChildSize: 0.94,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(22, 4, 22, 28),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (source != null && source.isNotEmpty) ...[
                      BadgePill(source, icon: Icons.auto_awesome_rounded),
                      const SizedBox(height: 8),
                    ],
                    Text(
                      name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
                tooltip: 'Tutup',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              BadgePill(
                '$servings porsi',
                color: slate,
                icon: Icons.people_alt_outlined,
              ),
              BadgePill(
                '$cookingTime menit memasak',
                color: slate,
                icon: Icons.timer_outlined,
              ),
            ],
          ),
          if (description != null && description.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              description,
              style: const TextStyle(color: muted, fontSize: 14, height: 1.55),
            ),
          ],
          if (nutrition != null) ...[
            const SizedBox(height: 18),
            const Eyebrow('INFORMASI GIZI PER PORSI'),
            const SizedBox(height: 8),
            NutritionBadges(nutrition: nutrition),
          ],
          if (ingredients.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Eyebrow('BAHAN-BAHAN'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cream,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: line),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < ingredients.length; i++) ...[
                    if (i > 0) const Divider(height: 14),
                    Row(
                      children: [
                        const Icon(
                          Icons.check_circle_outline_rounded,
                          size: 17,
                          color: teal,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            ingredients[i]['ingredient_name']?.toString() ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: ink,
                            ),
                          ),
                        ),
                        Text(
                          ingredients[i]['quantity']?.toString() ?? '',
                          style: const TextStyle(
                            color: muted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          const Eyebrow('CARA MEMASAK'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cream,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: line),
            ),
            child: Text(
              instructions,
              style: const TextStyle(
                color: ink,
                fontSize: 14,
                height: 1.65,
              ),
            ),
          ),
        ],
      ),
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
