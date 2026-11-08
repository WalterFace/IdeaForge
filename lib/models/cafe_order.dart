import 'cart_line.dart';

enum OrderStatus {
  received('Received'),
  preparing('Preparing'),
  ready('Ready'),
  collected('Collected');

  const OrderStatus(this.label);
  final String label;

  bool get isActive => this != OrderStatus.collected;

  OrderStatus? get next => switch (this) {
        OrderStatus.received => OrderStatus.preparing,
        OrderStatus.preparing => OrderStatus.ready,
        OrderStatus.ready => OrderStatus.collected,
        OrderStatus.collected => null,
      };
}

enum PaymentMethod {
  demoCard('Demo Card Payment (Simulated)'),
  payAtCounter('Pay at Counter (Demo)');

  const PaymentMethod(this.label);
  final String label;
}

enum FulfillmentType {
  takeaway('Takeaway'),
  atTable('At Table');

  const FulfillmentType(this.label);
  final String label;
}

class CafeOrder {
  const CafeOrder({
    required this.id,
    required this.createdAt,
    required this.lines,
    required this.subtotal,
    required this.discount,
    required this.rewardDiscount,
    required this.total,
    required this.paymentMethod,
    required this.fulfillment,
    required this.status,
    required this.queuePosition,
    required this.statusTimestamps,
    this.couponCode,
    this.tableNumber,
    this.pointsAwarded = false,
    this.isSeeded = false,
    this.posReference,
  });

  final String id;
  final DateTime createdAt;
  final List<CartLine> lines;
  final double subtotal;
  final double discount;
  final double rewardDiscount;
  final double total;
  final String? couponCode;
  final PaymentMethod paymentMethod;
  final FulfillmentType fulfillment;
  final String? tableNumber;
  final OrderStatus status;

  /// Simulated queue position at the moment the order was placed.
  final int queuePosition;
  final Map<OrderStatus, DateTime> statusTimestamps;
  final bool pointsAwarded;

  /// Seeded sample history (used for popularity ranking).
  final bool isSeeded;
  final String? posReference;

  bool get isActive => status.isActive;

  int get itemCount => lines.fold(0, (sum, l) => sum + l.quantity);

  /// Simulated number of orders ahead, derived from status.
  int get ordersAhead => switch (status) {
        OrderStatus.received => (queuePosition - 1).clamp(0, 99),
        _ => 0,
      };

  /// Simulated estimated wait in minutes.
  int estimatedWaitMinutes(int Function(String itemId) prepFor) {
    if (!isActive) return 0;
    if (status == OrderStatus.ready) return 0;
    final prep = lines.isEmpty
        ? 0
        : lines.map((l) => prepFor(l.itemId)).reduce((a, b) => a > b ? a : b);
    final queue = ordersAhead * 2;
    return status == OrderStatus.preparing ? (prep / 2).ceil() : queue + prep;
  }

  CafeOrder copyWith({
    OrderStatus? status,
    Map<OrderStatus, DateTime>? statusTimestamps,
    bool? pointsAwarded,
    int? queuePosition,
    String? posReference,
  }) =>
      CafeOrder(
        id: id,
        createdAt: createdAt,
        lines: lines,
        subtotal: subtotal,
        discount: discount,
        rewardDiscount: rewardDiscount,
        total: total,
        couponCode: couponCode,
        paymentMethod: paymentMethod,
        fulfillment: fulfillment,
        tableNumber: tableNumber,
        status: status ?? this.status,
        queuePosition: queuePosition ?? this.queuePosition,
        statusTimestamps: statusTimestamps ?? this.statusTimestamps,
        pointsAwarded: pointsAwarded ?? this.pointsAwarded,
        isSeeded: isSeeded,
        posReference: posReference ?? this.posReference,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'lines': lines.map((l) => l.toJson()).toList(),
        'subtotal': subtotal,
        'discount': discount,
        'rewardDiscount': rewardDiscount,
        'total': total,
        'couponCode': couponCode,
        'paymentMethod': paymentMethod.name,
        'fulfillment': fulfillment.name,
        'tableNumber': tableNumber,
        'status': status.name,
        'queuePosition': queuePosition,
        'statusTimestamps': statusTimestamps.map(
          (k, v) => MapEntry(k.name, v.toIso8601String()),
        ),
        'pointsAwarded': pointsAwarded,
        'isSeeded': isSeeded,
        'posReference': posReference,
      };

  factory CafeOrder.fromJson(Map<String, dynamic> json) => CafeOrder(
        id: json['id'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        lines: (json['lines'] as List<dynamic>)
            .map((e) => CartLine.fromJson(e as Map<String, dynamic>))
            .toList(),
        subtotal: (json['subtotal'] as num).toDouble(),
        discount: (json['discount'] as num).toDouble(),
        rewardDiscount: (json['rewardDiscount'] as num? ?? 0).toDouble(),
        total: (json['total'] as num).toDouble(),
        couponCode: json['couponCode'] as String?,
        paymentMethod: PaymentMethod.values.byName(json['paymentMethod'] as String),
        fulfillment: FulfillmentType.values.byName(json['fulfillment'] as String),
        tableNumber: json['tableNumber'] as String?,
        status: OrderStatus.values.byName(json['status'] as String),
        queuePosition: json['queuePosition'] as int,
        statusTimestamps: (json['statusTimestamps'] as Map<String, dynamic>).map(
          (k, v) => MapEntry(
            OrderStatus.values.byName(k),
            DateTime.parse(v as String),
          ),
        ),
        pointsAwarded: json['pointsAwarded'] as bool? ?? false,
        isSeeded: json['isSeeded'] as bool? ?? false,
        posReference: json['posReference'] as String?,
      );
}
