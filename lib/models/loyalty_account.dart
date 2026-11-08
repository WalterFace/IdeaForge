enum LoyaltyTier {
  bronze('Bronze', 0),
  silver('Silver', 500),
  gold('Gold', 1000),
  platinum('Platinum', 1500);

  const LoyaltyTier(this.label, this.threshold);
  final String label;
  final int threshold;

  static LoyaltyTier forPoints(int lifetimePoints) {
    var tier = LoyaltyTier.bronze;
    for (final t in LoyaltyTier.values) {
      if (lifetimePoints >= t.threshold) tier = t;
    }
    return tier;
  }

  LoyaltyTier? get next {
    final i = LoyaltyTier.values.indexOf(this);
    return i + 1 < LoyaltyTier.values.length ? LoyaltyTier.values[i + 1] : null;
  }
}

class LoyaltyActivity {
  const LoyaltyActivity({
    required this.id,
    required this.title,
    required this.pointsDelta,
    required this.timestamp,
    this.orderId,
  });

  final String id;
  final String title;
  final int pointsDelta;
  final DateTime timestamp;
  final String? orderId;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'pointsDelta': pointsDelta,
        'timestamp': timestamp.toIso8601String(),
        'orderId': orderId,
      };

  factory LoyaltyActivity.fromJson(Map<String, dynamic> json) =>
      LoyaltyActivity(
        id: json['id'] as String,
        title: json['title'] as String,
        pointsDelta: json['pointsDelta'] as int,
        timestamp: DateTime.parse(json['timestamp'] as String),
        orderId: json['orderId'] as String?,
      );
}

class RewardOption {
  const RewardOption({
    required this.id,
    required this.title,
    required this.pointsCost,
    required this.valueAed,
    required this.description,
  });

  final String id;
  final String title;
  final int pointsCost;
  final double valueAed;
  final String description;
}

class LoyaltyAccount {
  const LoyaltyAccount({
    required this.lifetimePoints,
    required this.spendablePoints,
    required this.activity,
  });

  /// Points earned over the account lifetime. Drives the tier.
  final int lifetimePoints;

  /// Points currently available to redeem. Separate from tier progress.
  final int spendablePoints;
  final List<LoyaltyActivity> activity;

  LoyaltyTier get tier => LoyaltyTier.forPoints(lifetimePoints);
  LoyaltyTier? get nextTier => tier.next;

  int get pointsToNextTier => nextTier == null
      ? 0
      : (nextTier!.threshold - lifetimePoints).clamp(0, 1 << 30);

  double get tierProgress {
    final next = nextTier;
    if (next == null) return 1;
    final span = next.threshold - tier.threshold;
    if (span <= 0) return 1;
    return ((lifetimePoints - tier.threshold) / span).clamp(0, 1);
  }

  /// Demo earning rule: 10 points per AED 1 of post-discount total.
  static int pointsForTotal(double total) => (total * 10).round();

  LoyaltyAccount copyWith({
    int? lifetimePoints,
    int? spendablePoints,
    List<LoyaltyActivity>? activity,
  }) =>
      LoyaltyAccount(
        lifetimePoints: lifetimePoints ?? this.lifetimePoints,
        spendablePoints: spendablePoints ?? this.spendablePoints,
        activity: activity ?? this.activity,
      );

  Map<String, dynamic> toJson() => {
        'lifetimePoints': lifetimePoints,
        'spendablePoints': spendablePoints,
        'activity': activity.map((a) => a.toJson()).toList(),
      };

  factory LoyaltyAccount.fromJson(Map<String, dynamic> json) => LoyaltyAccount(
        lifetimePoints: json['lifetimePoints'] as int,
        spendablePoints: json['spendablePoints'] as int,
        activity: (json['activity'] as List<dynamic>)
            .map((e) => LoyaltyActivity.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
