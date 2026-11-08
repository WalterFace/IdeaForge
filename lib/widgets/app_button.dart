import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum AppButtonStyle { primary, secondary, caramel, green, ghost }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.style = AppButtonStyle.primary,
    this.loading = false,
    this.expanded = true,
    this.dense = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonStyle style;
  final bool loading;
  final bool expanded;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg, BorderSide? side) = switch (style) {
      AppButtonStyle.primary => (AppColors.espresso, AppColors.oatCream, null),
      AppButtonStyle.secondary => (
          Colors.white,
          AppColors.espresso,
          const BorderSide(color: AppColors.espresso, width: 1.4),
        ),
      AppButtonStyle.caramel => (AppColors.caramel, AppColors.espresso, null),
      AppButtonStyle.green => (AppColors.softGreen, Colors.white, null),
      AppButtonStyle.ghost => (
          AppColors.warmGray,
          AppColors.espresso,
          null,
        ),
    };

    final child = loading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2.4, color: fg),
          )
        : FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20),
                  const SizedBox(width: 8),
                ],
                Text(label, maxLines: 1, textAlign: TextAlign.center),
              ],
            ),
          );

    final button = FilledButton(
      onPressed: loading ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        disabledBackgroundColor: bg.withValues(alpha: 0.5),
        disabledForegroundColor: fg.withValues(alpha: 0.7),
        side: side,
        minimumSize: Size(48, dense ? 44 : 52),
        padding: EdgeInsets.symmetric(horizontal: dense ? 16 : 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: child,
    );

    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Small rounded pill used for tags, statuses and labels.
class Pill extends StatelessWidget {
  const Pill({
    super.key,
    required this.label,
    this.color = AppColors.warmGray,
    this.textColor = AppColors.espresso,
    this.icon,
  });

  final String label;
  final Color color;
  final Color textColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: textColor),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: textColor,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Rounded surface card with soft shadow.
class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color = Colors.white,
    this.radius = 20,
    this.onTap,
    this.gradient,
    this.border,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final double radius;
  final VoidCallback? onTap;
  final Gradient? gradient;
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) {
    final decorated = Container(
      decoration: BoxDecoration(
        color: gradient == null ? color : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        border: border,
        boxShadow: [
          BoxShadow(
            color: AppColors.espresso.withValues(alpha: 0.07),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
    return decorated;
  }
}

/// Stepper for quantities.
class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 1,
    this.max = 20,
    this.compact = false,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 32.0 : 40.0;
    Widget btn(IconData icon, VoidCallback? onTap) => Material(
          color: onTap == null ? AppColors.warmGray : AppColors.espresso,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: size,
              height: size,
              child: Icon(
                icon,
                size: compact ? 16 : 18,
                color: onTap == null ? AppColors.textMuted : AppColors.oatCream,
              ),
            ),
          ),
        );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        btn(Icons.remove_rounded,
            value > min ? () => onChanged(value - 1) : null),
        SizedBox(
          width: compact ? 32 : 40,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: compact ? 15 : 17,
              fontWeight: FontWeight.w800,
              color: AppColors.espresso,
            ),
          ),
        ),
        btn(Icons.add_rounded, value < max ? () => onChanged(value + 1) : null),
      ],
    );
  }
}
