/// Pay-it-forward gift: a drink bought with points for someone else.
///
/// In this prototype the code is redeemed on the same device (demo). In
/// production it would be shared by message and validated by the backend.
class GiftVoucher {
  const GiftVoucher({
    required this.code,
    required this.itemId,
    required this.createdAt,
    required this.fromNickname,
    this.size,
    this.redeemedAt,
  });

  /// Sample "community" count shown on the kindness board before the demo.
  static const int seededGiftsThisMonth = 37;

  final String code;
  final String itemId;
  final String? size;
  final DateTime createdAt;
  final String fromNickname;
  final DateTime? redeemedAt;

  bool get isRedeemed => redeemedAt != null;

  GiftVoucher copyWith({DateTime? redeemedAt}) => GiftVoucher(
        code: code,
        itemId: itemId,
        size: size,
        createdAt: createdAt,
        fromNickname: fromNickname,
        redeemedAt: redeemedAt ?? this.redeemedAt,
      );

  Map<String, dynamic> toJson() => {
        'code': code,
        'itemId': itemId,
        'size': size,
        'createdAt': createdAt.toIso8601String(),
        'fromNickname': fromNickname,
        'redeemedAt': redeemedAt?.toIso8601String(),
      };

  factory GiftVoucher.fromJson(Map<String, dynamic> json) => GiftVoucher(
        code: json['code'] as String,
        itemId: json['itemId'] as String,
        size: json['size'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        fromNickname: json['fromNickname'] as String? ?? 'A fellow student',
        redeemedAt: json['redeemedAt'] == null
            ? null
            : DateTime.parse(json['redeemedAt'] as String),
      );
}
