import 'package:flutter/material.dart';

import '../services/busyness_model.dart';
import '../theme/app_colors.dart';

/// "Best time to go" bar chart of the simulated cafe busyness profile.
class BusyTimesChart extends StatelessWidget {
  const BusyTimesChart({super.key, required this.now, this.height = 72});

  final DateTime now;
  final double height;

  @override
  Widget build(BuildContext context) {
    final profile = BusynessModel.dayProfile();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: height,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final h in profile) ...[
                Expanded(
                  child: Tooltip(
                    message: '${_hourLabel(h.hour)} · ${h.label}',
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: h.level),
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOutCubic,
                      builder: (context, v, _) => Container(
                        height: (height - 4) * (0.12 + 0.88 * v),
                        decoration: BoxDecoration(
                          color: _colorFor(h, now),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ),
                ),
                if (h != profile.last) const SizedBox(width: 4),
              ],
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (final h in profile) ...[
              Expanded(
                child: Text(
                  h.hour % 3 == 2 ? _hourLabel(h.hour) : '',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight:
                        h.hour == now.hour ? FontWeight.w800 : FontWeight.w600,
                    color: h.hour == now.hour
                        ? AppColors.espresso
                        : AppColors.textMuted,
                  ),
                ),
              ),
              if (h != profile.last) const SizedBox(width: 4),
            ],
          ],
        ),
      ],
    );
  }

  static String _hourLabel(int hour) {
    final h12 = hour % 12 == 0 ? 12 : hour % 12;
    return '$h12${hour < 12 ? 'a' : 'p'}';
  }

  static Color _colorFor(HourBusyness h, DateTime now) {
    if (h.hour == now.hour) return AppColors.espresso;
    if (h.hour < now.hour) return AppColors.warmGrayDark;
    if (h.level >= 0.8) return AppColors.danger.withValues(alpha: 0.75);
    if (h.level >= 0.6) return AppColors.caramel;
    if (h.level >= 0.35) return AppColors.latte;
    return AppColors.softGreen.withValues(alpha: 0.8);
  }
}
