import 'dart:math';

import '../models/cafe_order.dart';
import 'pos_gateway.dart';

/// Fully local, simulated POS adapter used for the hackathon prototype.
///
/// It never contacts a network, never stores payment credentials and always
/// labels itself as simulated.
class MockPosGateway implements PosGateway {
  MockPosGateway({
    this.latency = const Duration(milliseconds: 650),
    int Function()? queueSeed,
    Random? random,
  })  : _queueSeed = queueSeed ?? (() => 2),
        _random = random ?? Random();

  final Duration latency;
  final int Function() _queueSeed;
  final Random _random;
  final Map<String, OrderStatus> _statuses = {};

  @override
  String get displayName => 'MockPosGateway (simulated, offline)';

  @override
  bool get isSimulated => true;

  @override
  Future<PosPaymentResult> authorizePayment({
    required double amountAed,
    required PaymentMethod method,
    required String idempotencyKey,
  }) async {
    await Future<void>.delayed(latency);
    final ref = 'SIM-${idempotencyKey.hashCode.abs().toRadixString(36).toUpperCase()}';
    return PosPaymentResult(
      approved: true,
      reference: ref,
      message: method == PaymentMethod.demoCard
          ? 'Simulated card authorization approved.'
          : 'Marked for payment at counter (demo).',
    );
  }

  @override
  Future<PosOrderResult> submitOrder(CafeOrder order) async {
    await Future<void>.delayed(latency);
    _statuses[order.id] = OrderStatus.received;
    final suffix = _random.nextInt(9000) + 1000;
    return PosOrderResult(
      accepted: true,
      posReference: 'MOCK-$suffix',
      queuePosition: _queueSeed() + 1,
      message: 'Order accepted by simulated POS.',
    );
  }

  @override
  Future<OrderStatus?> fetchStatus(String orderId) async => _statuses[orderId];
}
