import 'package:altitude_app/data/seed_data.dart';
import 'package:altitude_app/models/cafe_order.dart';
import 'package:altitude_app/models/club_event.dart';
import 'package:altitude_app/services/local_storage_service.dart';
import 'package:altitude_app/services/mock_pos_gateway.dart';
import 'package:altitude_app/services/rush_mode_engine.dart';
import 'package:altitude_app/state/app_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<AppState> buildState() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final state = AppState(
    storage: LocalStorageService(prefs),
    posGateway: MockPosGateway(latency: Duration.zero),
  );
  await state.init();
  state.completeOnboarding(nickname: 'Tester');
  return state;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Cart', () {
    test('subtotal sums line totals with customizations', () async {
      final s = await buildState();
      final latte = s.itemById('iced_latte'); // 19, Medium +2, Vanilla +2
      final cookie = s.itemById('choc_chip_cookie'); // 8
      s.addToCart(latte, size: 'Medium', addOns: [latte.addOns.first]);
      s.addToCart(cookie, quantity: 2);
      expect(s.cartCount, 3);
      expect(s.subtotal, closeTo(23 + 16, 0.001));
    });

    test('identical customizations merge into one line', () async {
      final s = await buildState();
      final latte = s.itemById('iced_latte');
      s.addToCart(latte, size: 'Small', milk: 'Oat');
      s.addToCart(latte, size: 'Small', milk: 'Oat');
      s.addToCart(latte, size: 'Large', milk: 'Oat');
      expect(s.cart.length, 2);
      expect(s.cartCount, 3);
    });

    test('quantity updates and removal', () async {
      final s = await buildState();
      s.addToCart(s.itemById('karak_chai'), size: 'Regular');
      final lineId = s.cart.first.id;
      s.setLineQuantity(lineId, 4);
      expect(s.cart.first.quantity, 4);
      expect(s.subtotal, closeTo(36, 0.001));
      s.setLineQuantity(lineId, 0);
      expect(s.cart, isEmpty);
      expect(s.subtotal, 0);
    });
  });

  group('Coupons', () {
    test('CAMPUS10 gives 10% off and cannot be applied twice', () async {
      final s = await buildState();
      s.addToCart(s.itemById('flat_white'), size: 'Small'); // 18
      s.addToCart(s.itemById('butter_croissant')); // 11
      expect(s.applyCoupon('campus10'), CouponResult.applied);
      expect(s.couponDiscount, closeTo(2.9, 0.001));
      expect(s.total, closeTo(26.1, 0.001));
      expect(s.applyCoupon('CAMPUS10'), CouponResult.alreadyApplied);
      expect(s.applyCoupon('NOPE'), CouponResult.invalid);
      expect(s.total, closeTo(26.1, 0.001));
    });

    test('coupon on empty cart is rejected', () async {
      final s = await buildState();
      expect(s.applyCoupon('CAMPUS10'), CouponResult.emptyCart);
    });
  });

  group('Rush Mode', () {
    test('classification uses buffer and window', () {
      expect(
        RushModeEngine.classify(estimatedMinutes: 10, windowMinutes: 15),
        RushFit.likelyFits,
      );
      expect(
        RushModeEngine.classify(estimatedMinutes: 13, windowMinutes: 15),
        RushFit.mayBeTight,
      );
      expect(
        RushModeEngine.classify(estimatedMinutes: 16, windowMinutes: 15),
        RushFit.tooLong,
      );
    });

    test('recommendations are sorted likely-first and exclude too-long', () {
      final result = RushModeEngine.recommend(
        items: SeedData.menuItems,
        queueDelayMinutes: 6,
        windowMinutes: 10,
      );
      expect(result.recommendations, isNotEmpty);
      // Everything shown fits the window.
      for (final r in result.recommendations) {
        expect(r.estimatedMinutes, lessThanOrEqualTo(10));
        expect(r.fit, isNot(RushFit.tooLong));
      }
      // Likely-fits appear before may-be-tight.
      final fits = result.recommendations.map((r) => r.fit).toList();
      final firstTight = fits.indexOf(RushFit.mayBeTight);
      if (firstTight >= 0) {
        expect(fits.sublist(firstTight).contains(RushFit.likelyFits), isFalse);
      }
      // Halloumi wrap (7 min prep) + 6 queue = 13 > 10: excluded.
      expect(result.excluded.any((r) => r.item.id == 'halloumi_wrap'), isTrue);
    });

    test('state exposes queue-aware recommendations for 15 minutes', () async {
      final s = await buildState();
      final result = s.rushRecommendations(15);
      expect(result.queueDelayMinutes, s.queueDelayMinutes);
      final icedLatte = result.recommendations
          .firstWhere((r) => r.item.id == 'iced_latte');
      expect(icedLatte.fit, RushFit.likelyFits);
    });
  });

  group('Orders', () {
    test('placing an order clears the cart and creates a received order',
        () async {
      final s = await buildState();
      s.addToCart(s.itemById('iced_latte'), size: 'Medium', milk: 'Oat');
      s.applyCoupon('CAMPUS10');
      final expectedTotal = s.total;

      final order = await s.placeOrder(
        paymentMethod: PaymentMethod.demoCard,
        fulfillment: FulfillmentType.takeaway,
      );

      expect(order.id, 'ALT-${SeedData.firstDemoOrderNumber}');
      expect(order.status, OrderStatus.received);
      expect(order.total, closeTo(expectedTotal, 0.001));
      expect(order.couponCode, 'CAMPUS10');
      expect(order.queuePosition, greaterThan(0));
      expect(s.cart, isEmpty);
      expect(s.appliedCoupon, isNull);
      expect(s.activeOrder?.id, order.id);
      expect(s.tabIndex, 2);
    });

    test('at-table orders require a table number', () async {
      final s = await buildState();
      s.addToCart(s.itemById('cold_brew'), size: 'Medium');
      expect(
        () => s.placeOrder(
          paymentMethod: PaymentMethod.payAtCounter,
          fulfillment: FulfillmentType.atTable,
          tableNumber: '',
        ),
        throwsStateError,
      );
      expect(s.cart, isNotEmpty);
    });

    test('status moves forward only and stamps timestamps', () async {
      final s = await buildState();
      final order = s.generateSampleActiveOrder();
      expect(s.setOrderStatus(order.id, OrderStatus.preparing), isTrue);
      expect(s.orderById(order.id)!.status, OrderStatus.preparing);
      expect(s.setOrderStatus(order.id, OrderStatus.received), isFalse);
      expect(s.advanceOrder(order.id), isTrue);
      expect(s.orderById(order.id)!.status, OrderStatus.ready);
      expect(s.orderAwaitingPickup?.id, order.id);
      expect(s.advanceOrder(order.id), isTrue);
      final done = s.orderById(order.id)!;
      expect(done.status, OrderStatus.collected);
      expect(done.statusTimestamps.length, 4);
      expect(s.advanceOrder(order.id), isFalse);
    });

    test('jumping straight to collected stamps skipped steps', () async {
      final s = await buildState();
      final order = s.generateSampleActiveOrder();
      s.setOrderStatus(order.id, OrderStatus.collected);
      expect(s.orderById(order.id)!.statusTimestamps.keys,
          containsAll(OrderStatus.values));
    });
  });

  group('Loyalty', () {
    test('points are awarded exactly once per order', () async {
      final s = await buildState();
      final lifetimeBefore = s.loyalty.lifetimePoints;
      final spendableBefore = s.loyalty.spendablePoints;

      s.addToCart(s.itemById('cappuccino'), size: 'Medium', milk: 'Oat'); // 19
      final order = await s.placeOrder(
        paymentMethod: PaymentMethod.demoCard,
        fulfillment: FulfillmentType.takeaway,
      );
      final expected = (order.total * 10).round();

      s.setOrderStatus(order.id, OrderStatus.preparing);
      s.setOrderStatus(order.id, OrderStatus.ready);
      expect(s.loyalty.lifetimePoints, lifetimeBefore);

      s.setOrderStatus(order.id, OrderStatus.collected);
      expect(s.loyalty.lifetimePoints, lifetimeBefore + expected);
      expect(s.loyalty.spendablePoints, spendableBefore + expected);
      expect(s.orderById(order.id)!.pointsAwarded, isTrue);

      // Repeated attempts are no-ops.
      s.setOrderStatus(order.id, OrderStatus.collected);
      s.advanceOrder(order.id);
      expect(s.loyalty.lifetimePoints, lifetimeBefore + expected);
      expect(
        s.loyalty.activity.where((a) => a.orderId == order.id).length,
        1,
      );
    });

    test('seeded account is Gold with 260 to Platinum', () async {
      final s = await buildState();
      expect(s.loyalty.lifetimePoints, 1240);
      expect(s.loyalty.tier.label, 'Gold');
      expect(s.loyalty.pointsToNextTier, 260);
    });

    test('reward redemption discounts cart and deducts points on order',
        () async {
      final s = await buildState();
      final before = s.loyalty.spendablePoints;
      s.addToCart(s.itemById('halloumi_wrap')); // 24
      expect(s.applyReward(s.rewards.first), RewardResult.applied);
      expect(s.rewardDiscount, 5);
      expect(s.total, closeTo(19, 0.001));
      expect(s.applyReward(s.rewards.first), RewardResult.alreadyApplied);
      final order = await s.placeOrder(
        paymentMethod: PaymentMethod.payAtCounter,
        fulfillment: FulfillmentType.atTable,
        tableNumber: '7',
      );
      expect(order.rewardDiscount, 5);
      expect(order.tableNumber, '7');
      expect(s.loyalty.spendablePoints, before - 100);
      expect(s.pendingReward, isNull);
    });
  });

  group('Popular picks & campus', () {
    test('popular picks are ranked by aggregated quantity', () async {
      final s = await buildState();
      final picks = s.popularPicks;
      expect(picks, isNotEmpty);
      for (var i = 1; i < picks.length; i++) {
        expect(picks[i - 1].quantitySold >= picks[i].quantitySold, isTrue);
      }
      // Placing an order shifts ranking.
      final target = s.itemById('mint_tea');
      s.addToCart(target, size: 'Regular', quantity: 10);
      final order = await s.placeOrder(
        paymentMethod: PaymentMethod.demoCard,
        fulfillment: FulfillmentType.takeaway,
      );
      expect(order.lines.first.quantity, 10);
      expect(s.popularPicks.first.item.id, 'mint_tea');
    });

    test('RSVP state persists across state instances', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final a = AppState(
        storage: LocalStorageService(prefs),
        posGateway: MockPosGateway(latency: Duration.zero),
      );
      await a.init();
      a.completeOnboarding(nickname: 'Sam');
      final eventId = a.events.first.id;
      a.setRsvp(eventId, RsvpStatus.going);
      a.addToCart(a.itemById('cold_brew'), size: 'Large');
      await Future<void>.delayed(Duration.zero);

      final b = AppState(
        storage: LocalStorageService(prefs),
        posGateway: MockPosGateway(latency: Duration.zero),
      );
      await b.init();
      expect(b.hasOnboarded, isTrue);
      expect(b.nickname, 'Sam');
      expect(b.rsvpFor(eventId), RsvpStatus.going);
      expect(b.cartCount, 1);
    });
  });
}
