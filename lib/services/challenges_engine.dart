import 'package:flutter/material.dart';

import '../models/cafe_order.dart';
import '../models/menu_item.dart';

/// A weekly challenge with its current progress.
class ChallengeProgress {
  const ChallengeProgress({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.progress,
    required this.target,
    required this.bonusPoints,
    required this.claimed,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
  final int progress;
  final int target;
  final int bonusPoints;
  final bool claimed;

  bool get completed => progress >= target;
  bool get claimable => completed && !claimed;
  double get fraction => target == 0 ? 1 : (progress / target).clamp(0, 1);
}

/// Rule-based streaks and challenges computed from order history.
///
/// Nothing is stored except which challenges were already claimed, so the
/// numbers always agree with the orders on screen.
class ChallengesEngine {
  ChallengesEngine._();

  static DateTime _day(DateTime t) => DateTime(t.year, t.month, t.day);

  /// Consecutive days (ending today or yesterday) with a collected order.
  static int streakDays(List<CafeOrder> orders, DateTime now) {
    final days = orders
        .where((o) => o.status == OrderStatus.collected)
        .map((o) =>
            _day(o.statusTimestamps[OrderStatus.collected] ?? o.createdAt))
        .toSet();
    if (days.isEmpty) return 0;

    var cursor = _day(now);
    if (!days.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
      if (!days.contains(cursor)) return 0;
    }
    var streak = 0;
    while (days.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  static List<ChallengeProgress> evaluate({
    required List<CafeOrder> orders,
    required DateTime now,
    required Set<String> claimed,
    required MenuItem Function(String itemId) itemById,
  }) {
    final collected =
        orders.where((o) => o.status == OrderStatus.collected).toList();
    final weekAgo = now.subtract(const Duration(days: 7));
    final thisWeek =
        collected.where((o) => o.createdAt.isAfter(weekAgo)).toList();

    final categories = <MenuCategory>{};
    for (final o in thisWeek) {
      for (final l in o.lines) {
        categories.add(itemById(l.itemId).category);
      }
    }

    final greenCups = collected.where((o) => o.ownCup).length;
    final earlyBird = thisWeek.where((o) => o.createdAt.hour < 10).length;
    final scheduled = collected.where((o) => o.isScheduled).length;

    return [
      ChallengeProgress(
        id: 'three_this_week',
        title: 'Regular',
        description: 'Collect 3 orders this week',
        icon: Icons.local_fire_department_rounded,
        progress: thisWeek.length,
        target: 3,
        bonusPoints: 50,
        claimed: claimed.contains('three_this_week'),
      ),
      ChallengeProgress(
        id: 'explorer',
        title: 'Explorer',
        description: 'Order from 3 different menu categories this week',
        icon: Icons.explore_rounded,
        progress: categories.length,
        target: 3,
        bonusPoints: 40,
        claimed: claimed.contains('explorer'),
      ),
      ChallengeProgress(
        id: 'green_cup',
        title: 'Green Cup',
        description: 'Bring your own cup once',
        icon: Icons.eco_rounded,
        progress: greenCups,
        target: 1,
        bonusPoints: 30,
        claimed: claimed.contains('green_cup'),
      ),
      ChallengeProgress(
        id: 'planner',
        title: 'Planner',
        description: 'Schedule a pickup ahead of time',
        icon: Icons.event_available_rounded,
        progress: scheduled,
        target: 1,
        bonusPoints: 25,
        claimed: claimed.contains('planner'),
      ),
      ChallengeProgress(
        id: 'early_bird',
        title: 'Early Bird',
        description: 'Order before 10 AM twice this week',
        icon: Icons.wb_twilight_rounded,
        progress: earlyBird,
        target: 2,
        bonusPoints: 30,
        claimed: claimed.contains('early_bird'),
      ),
    ];
  }
}
