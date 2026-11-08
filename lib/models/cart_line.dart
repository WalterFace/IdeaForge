/// A single line in the cart or in a placed order.
class CartLine {
  const CartLine({
    required this.id,
    required this.itemId,
    required this.name,
    required this.unitPrice,
    required this.quantity,
    this.size,
    this.milk,
    this.addOns = const [],
  });

  final String id;
  final String itemId;
  final String name;
  final double unitPrice;
  final int quantity;
  final String? size;
  final String? milk;
  final List<String> addOns;

  double get lineTotal => unitPrice * quantity;

  /// Key that identifies identical customizations so they can be merged.
  String get mergeKey =>
      '$itemId|${size ?? ''}|${milk ?? ''}|${(List<String>.from(addOns)..sort()).join(',')}';

  String get customizationSummary {
    final parts = <String>[
      if (size != null) size!,
      if (milk != null) milk!,
      ...addOns,
    ];
    return parts.join(' · ');
  }

  CartLine copyWith({int? quantity}) => CartLine(
        id: id,
        itemId: itemId,
        name: name,
        unitPrice: unitPrice,
        quantity: quantity ?? this.quantity,
        size: size,
        milk: milk,
        addOns: addOns,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'itemId': itemId,
        'name': name,
        'unitPrice': unitPrice,
        'quantity': quantity,
        'size': size,
        'milk': milk,
        'addOns': addOns,
      };

  factory CartLine.fromJson(Map<String, dynamic> json) => CartLine(
        id: json['id'] as String,
        itemId: json['itemId'] as String,
        name: json['name'] as String,
        unitPrice: (json['unitPrice'] as num).toDouble(),
        quantity: json['quantity'] as int,
        size: json['size'] as String?,
        milk: json['milk'] as String?,
        addOns: (json['addOns'] as List<dynamic>? ?? const [])
            .map((e) => e as String)
            .toList(),
      );
}
