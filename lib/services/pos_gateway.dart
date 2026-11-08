import '../models/cafe_order.dart';

/// Result of a payment authorization attempt.
class PosPaymentResult {
  const PosPaymentResult({
    required this.approved,
    required this.reference,
    this.message,
  });

  final bool approved;
  final String reference;
  final String? message;
}

/// Result of submitting an order to the point-of-sale system.
class PosOrderResult {
  const PosOrderResult({
    required this.accepted,
    required this.posReference,
    required this.queuePosition,
    this.message,
  });

  final bool accepted;
  final String posReference;
  final int queuePosition;
  final String? message;
}

/// Boundary between the Altitude app and any point-of-sale backend.
///
/// The UI and [AppState] only talk to this interface. The hackathon build
/// uses [MockPosGateway]. A future MOBIPOS adapter would implement this same
/// interface using vendor-approved documentation. No real endpoints or
/// authentication are assumed or invented here.
abstract class PosGateway {
  /// Human-readable adapter name shown in the About panel.
  String get displayName;

  /// True when results are simulated locally.
  bool get isSimulated;

  /// Authorize a payment for [amountAed]. Must never receive raw card data in
  /// this prototype; a real adapter would delegate to an approved provider.
  Future<PosPaymentResult> authorizePayment({
    required double amountAed,
    required PaymentMethod method,
    required String idempotencyKey,
  });

  /// Submit an order and receive a queue position.
  Future<PosOrderResult> submitOrder(CafeOrder order);

  /// Fetch the latest known status, or null if unknown.
  Future<OrderStatus?> fetchStatus(String orderId);
}
