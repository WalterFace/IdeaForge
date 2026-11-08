import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/menu_item.dart';
import '../theme/app_colors.dart';

/// Locally generated product visual. No external images required.
class ProductArtView extends StatelessWidget {
  const ProductArtView({
    super.key,
    required this.art,
    this.size = 96,
    this.radius = 20,
    this.showIcon = true,
  });

  final ProductArt art;
  final double size;
  final double radius;
  final bool showIcon;

  static ArtStyle styleFor(ProductArt art) => switch (art) {
        ProductArt.espresso => const ArtStyle(
            colors: [Color(0xFF4A3327), AppColors.espresso],
            accent: AppColors.caramel,
            icon: Icons.coffee_rounded,
          ),
        ProductArt.latte => const ArtStyle(
            colors: [Color(0xFFE6B77F), Color(0xFFC98A47)],
            accent: Color(0xFFFFF2DE),
            icon: Icons.coffee_rounded,
          ),
        ProductArt.iced => const ArtStyle(
            colors: [Color(0xFF9CC4DD), Color(0xFF5E8DAA)],
            accent: Colors.white,
            icon: Icons.local_cafe_rounded,
          ),
        ProductArt.matcha => const ArtStyle(
            colors: [Color(0xFF8FB08E), AppColors.softGreen],
            accent: Color(0xFFEAF3E6),
            icon: Icons.local_cafe_rounded,
          ),
        ProductArt.tea => const ArtStyle(
            colors: [Color(0xFFC9814F), Color(0xFF9B5A2F)],
            accent: Color(0xFFFFE6CC),
            icon: Icons.emoji_food_beverage_rounded,
          ),
        ProductArt.pastry => const ArtStyle(
            colors: [Color(0xFFF0C98A), Color(0xFFD69A4E)],
            accent: Color(0xFF7A4A22),
            icon: Icons.bakery_dining_rounded,
          ),
        ProductArt.cookie => const ArtStyle(
            colors: [Color(0xFFB9825A), Color(0xFF7A4A2E)],
            accent: Color(0xFFFFE9D1),
            icon: Icons.cookie_rounded,
          ),
        ProductArt.sandwich => const ArtStyle(
            colors: [Color(0xFF8FA98B), Color(0xFF4F6B57)],
            accent: Color(0xFFF4E6C8),
            icon: Icons.lunch_dining_rounded,
          ),
      };

  @override
  Widget build(BuildContext context) {
    final style = styleFor(art);
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _ArtPainter(style),
          child: showIcon
              ? Center(
                  child: Icon(
                    style.icon,
                    size: size * 0.42,
                    color: style.accent.withValues(alpha: 0.95),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

class ArtStyle {
  const ArtStyle({
    required this.colors,
    required this.accent,
    required this.icon,
  });

  final List<Color> colors;
  final Color accent;
  final IconData icon;
}

class _ArtPainter extends CustomPainter {
  _ArtPainter(this.style);

  final ArtStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: style.colors,
        ).createShader(rect),
    );

    final glow = Paint()..color = Colors.white.withValues(alpha: 0.14);
    canvas.drawCircle(
      Offset(size.width * 0.82, size.height * 0.18),
      size.width * 0.32,
      glow,
    );
    canvas.drawCircle(
      Offset(size.width * 0.15, size.height * 0.88),
      size.width * 0.24,
      Paint()..color = Colors.black.withValues(alpha: 0.08),
    );

    // Soft wave across the bottom for a "poured" feel.
    final path = Path()..moveTo(0, size.height * 0.78);
    for (var x = 0.0; x <= size.width; x += 4) {
      final y = size.height * 0.78 +
          math.sin((x / size.width) * math.pi * 2) * size.height * 0.03;
      path.lineTo(x, y);
    }
    path
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
        path, Paint()..color = Colors.white.withValues(alpha: 0.10));
  }

  @override
  bool shouldRepaint(covariant _ArtPainter oldDelegate) =>
      oldDelegate.style != style;
}

/// Decorative coffee-bean pattern painter for hero backgrounds.
class BeanPatternPainter extends CustomPainter {
  const BeanPatternPainter({this.color = Colors.white, this.opacity = 0.06});

  final Color color;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;
    final line = Paint()
      ..color = color.withValues(alpha: opacity * 1.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    const step = 56.0;
    var row = 0;
    for (var y = -20.0; y < size.height + 20; y += step) {
      final offsetX = row.isEven ? 0.0 : step / 2;
      for (var x = -20.0 + offsetX; x < size.width + 20; x += step) {
        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(-0.6);
        final bean = RRect.fromRectAndRadius(
          const Rect.fromLTWH(-9, -14, 18, 28),
          const Radius.circular(12),
        );
        canvas.drawRRect(bean, paint);
        canvas.drawLine(const Offset(0, -11), const Offset(0, 11), line);
        canvas.restore();
      }
      row++;
    }
  }

  @override
  bool shouldRepaint(covariant BeanPatternPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.opacity != opacity;
}
