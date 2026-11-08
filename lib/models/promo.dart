enum PromoKind { product, coupon }

class Promo {
  const Promo({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.kind,
    this.itemId,
    this.couponCode,
  });

  final String id;
  final String title;
  final String subtitle;
  final String badge;
  final PromoKind kind;
  final String? itemId;
  final String? couponCode;
}

class CouponRule {
  const CouponRule({
    required this.code,
    required this.percentOff,
    required this.description,
  });

  final String code;
  final int percentOff;
  final String description;

  double discountFor(double subtotal) =>
      double.parse((subtotal * percentOff / 100).toStringAsFixed(2));
}
