import '../models/menu_item.dart';

enum RushFit {
  likelyFits('Likely fits'),
  mayBeTight('May be tight'),
  tooLong('Too long');

  const RushFit(this.label);
  final String label;
}

class RushRecommendation {
  const RushRecommendation({
    required this.item,
    required this.estimatedMinutes,
    required this.fit,
  });

  final MenuItem item;

  /// queue delay + preparation time (demo estimate).
  final int estimatedMinutes;
  final RushFit fit;
}

class RushResult {
  const RushResult({
    required this.windowMinutes,
    required this.queueDelayMinutes,
    required this.recommendations,
    required this.excluded,
  });

  final int windowMinutes;
  final int queueDelayMinutes;

  /// Likely-fits items first, then may-be-tight, each sorted by wait.
  final List<RushRecommendation> recommendations;

  /// Items that would not fit in the window.
  final List<RushRecommendation> excluded;
}

/// Rule-based (not machine learning) recommendation engine for Rush Mode.
///
/// The model is deliberately transparent and shown to the student:
///   estimated wait = simulated queue delay + product preparation time.
class RushModeEngine {
  RushModeEngine._();

  static const List<int> windows = [10, 15, 20, 30];

  /// Safety margin, in minutes, between "likely fits" and "may be tight".
  static const int comfortBufferMinutes = 3;

  /// Simulated queue delay: a fixed hand-off time plus ~2 minutes per order
  /// in the queue.
  static int queueDelayFor({required int ordersInQueue}) =>
      2 + 2 * ordersInQueue.clamp(0, 20);

  static RushFit classify({
    required int estimatedMinutes,
    required int windowMinutes,
  }) {
    if (estimatedMinutes <= windowMinutes - comfortBufferMinutes) {
      return RushFit.likelyFits;
    }
    if (estimatedMinutes <= windowMinutes) return RushFit.mayBeTight;
    return RushFit.tooLong;
  }

  static RushResult recommend({
    required List<MenuItem> items,
    required int queueDelayMinutes,
    required int windowMinutes,
  }) {
    final all = items.map((item) {
      final est = queueDelayMinutes + item.prepMinutes;
      return RushRecommendation(
        item: item,
        estimatedMinutes: est,
        fit: classify(estimatedMinutes: est, windowMinutes: windowMinutes),
      );
    }).toList();

    int rank(RushFit f) => switch (f) {
          RushFit.likelyFits => 0,
          RushFit.mayBeTight => 1,
          RushFit.tooLong => 2,
        };

    all.sort((a, b) {
      final byFit = rank(a.fit).compareTo(rank(b.fit));
      if (byFit != 0) return byFit;
      final byTime = a.estimatedMinutes.compareTo(b.estimatedMinutes);
      if (byTime != 0) return byTime;
      return a.item.name.compareTo(b.item.name);
    });

    return RushResult(
      windowMinutes: windowMinutes,
      queueDelayMinutes: queueDelayMinutes,
      recommendations: all.where((r) => r.fit != RushFit.tooLong).toList(),
      excluded: all.where((r) => r.fit == RushFit.tooLong).toList(),
    );
  }
}
