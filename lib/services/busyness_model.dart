import 'dart:math';

/// One hour of the simulated cafe busyness profile.
class HourBusyness {
  const HourBusyness(this.hour, this.level);

  /// 24-hour clock hour (8..20).
  final int hour;

  /// 0 (empty) .. 1 (packed).
  final double level;

  String get label => BusynessModel.labelFor(level);
}

/// Deterministic, rule-based model of how busy the campus cafe is.
///
/// It is NOT live data. It encodes a plausible campus rhythm: a morning
/// rush, a lunch peak, quieter afternoons, plus short spikes at class
/// changeovers on the hour. Rush Mode uses it to add realistic queue delay
/// and the Home screen shows it as "Best time to go".
class BusynessModel {
  BusynessModel._();

  static const int openHour = 8;
  static const int closeHour = 20;

  static const Map<int, double> _baseByHour = {
    8: 0.55,
    9: 0.80,
    10: 0.60,
    11: 0.50,
    12: 0.92,
    13: 0.85,
    14: 0.50,
    15: 0.40,
    16: 0.45,
    17: 0.35,
    18: 0.30,
    19: 0.25,
  };

  /// Extra minutes of queue delay added at maximum busyness.
  static const int maxExtraQueueMinutes = 4;

  static bool isOpen(DateTime t) => t.hour >= openHour && t.hour < closeHour;

  /// Busyness level at [t], including a class-changeover spike in the ten
  /// minutes either side of the hour.
  static double levelAt(DateTime t) {
    final base = _baseByHour[t.hour] ?? 0.08;
    final minute = t.minute;
    final nearHour = minute >= 50 || minute <= 10;
    final spike = nearHour ? 0.15 : 0.0;
    return min(1.0, base + spike);
  }

  static int extraQueueMinutes(double level) =>
      (level * maxExtraQueueMinutes).round();

  static String labelFor(double level) {
    if (level < 0.35) return 'Quiet';
    if (level < 0.6) return 'Moderate';
    if (level < 0.8) return 'Busy';
    return 'Packed';
  }

  /// Hourly profile for the chart (opening hours only, base curve).
  static List<HourBusyness> dayProfile() => [
        for (var h = openHour; h < closeHour; h++)
          HourBusyness(h, _baseByHour[h] ?? 0.08),
      ];

  /// The quietest upcoming hour today after [now], or null if the cafe is
  /// closing.
  static HourBusyness? quietestUpcoming(DateTime now) {
    HourBusyness? best;
    for (final h in dayProfile()) {
      if (h.hour <= now.hour) continue;
      if (best == null || h.level < best.level) best = h;
    }
    return best;
  }
}
