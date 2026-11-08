import 'package:altitude_app/data/seed_data.dart';
import 'package:altitude_app/models/cafe_order.dart';
import 'package:altitude_app/services/busyness_model.dart';
import 'package:altitude_app/services/challenges_engine.dart';
import 'package:altitude_app/services/local_storage_service.dart';
import 'package:altitude_app/services/mock_pos_gateway.dart';
import 'package:altitude_app/services/rush_mode_engine.dart';
import 'package:altitude_app/state/app_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A quiet mid-afternoon moment so busyness is deterministic in tests.
final DateTime kQuietNow = DateTime(2026, 11, 9, 15, 25);

Future<AppState> buildState({DateTime? now}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final state = AppState(
    storage: LocalStorageService(prefs),
    posGateway: MockPosGateway(latency: Duration.zero),
    clock: () => now ?? kQuietNow,
  );
  await state.init();
  state.completeOnboarding(nickname: 'Tester');
  return state;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Busyness model', () {
    test('lunch is busier than late afternoon and spikes on the hour', () {
      final lunch = BusynessModel.levelAt(DateTime(2026, 11, 9, 12, 30));
      final afternoon = BusynessModel.levelAt(DateTime(2026, 11, 9, 15, 30));
      final onTheHour = BusynessModel.levelAt(DateTime(2026, 11, 9, 15, 2));
      expect(lunch, greaterThan(afternoon));
      expect(onTheHour, greaterThan(afternoon));
      expect(
          BusynessModel.levelAt(DateTime(2026, 11, 9, 3, 30)), lessThan(0.2));
      expect(BusynessModel.labelFor(0.9), 'Packed');
      expect(BusynessModel.labelFor(0.2), 'Quiet');
    });

    test('quietest upcoming hour is later than now', () {
      final q = BusynessModel.quietestUpcoming(DateTime(2026, 11, 9, 12, 0));
      expect(q, isNotNull);
      expect(q!.hour, greaterThan(12));
      expect(BusynessModel.quietestUpcoming(DateTime(2026, 11, 9, 19, 30)),
          isNull);
    });

    test('queue delay grows with busyness', () {
      final quiet = RushModeEngine.queueDelayFor(ordersInQueue: 2);
      final busy =
          RushModeEngine.queueDelayFor(ordersInQueue: 2, busyExtraMinutes: 4);
      expect(busy - quiet, 4);
    });
  });

  group('Rush Mode 2.0 walk time', () {
    test('walking reduces the effective window and sets leave-in', () {
      final result = RushModeEngine.recommend(
        items: SeedData.menuItems,
        queueDelayMinutes: 6,
        windowMinutes: 15,
        walkMinutes: 4,
      );
      expect(result.effectiveWindow, 11);
      final cookie = [...result.recommendations, ...result.excluded]
          .firstWhere((r) => r.item.id == 'choc_chip_cookie');
      expect(cookie.estimatedMinutes, 7);
      expect(cookie.leaveInMinutes, 3);
      expect(cookie.fit, RushFit.likelyFits);
      // 7-minute wrap: 13 min > 11 min effective window → excluded.
      expect(result.excluded.any((r) => r.item.id == 'halloumi_wrap'), isTrue);
    });

    test('state applies the selected campus location', () async {
      final s = await buildState();
      final before = s.rushRecommendations(15);
      s.setCampusLocation('dorms');
      final after = s.rushRecommendations(15);
      expect(s.campusLocation.walkMinutes, 7);
      expect(after.effectiveWindow, lessThan(before.effectiveWindow));
      expect(after.recommendations.length,
          lessThanOrEqualTo(before.recommendations.length));
    });
  });

  group('Scheduled pickup', () {
    test('order stores the pickup slot and the Planner challenge counts it',
        () async {
      final s = await buildState();
      final slot = s.pickupSlots.first;
      expect(slot.isAfter(kQuietNow), isTrue);
      s.addToCart(s.itemById('americano'), size: 'Small');
      final order = await s.placeOrder(
        paymentMethod: PaymentMethod.demoCard,
        fulfillment: FulfillmentType.takeaway,
        scheduledFor: slot,
      );
      expect(order.isScheduled, isTrue);
      expect(order.scheduledFor, slot);
      s.setOrderStatus(order.id, OrderStatus.collected);
      final planner = s.challenges.firstWhere((c) => c.id == 'planner');
      expect(planner.completed, isTrue);
    });
  });

  group('Green Cup', () {
    test('discount applies per drink and bonus points once on collection',
        () async {
      final s = await buildState();
      s.addToCart(s.itemById('flat_white'), size: 'Small'); // drink, 18
      s.addToCart(s.itemById('butter_croissant')); // not a drink, 11
      expect(s.greenCupDiscount, 0);
      s.setOwnCup(true);
      expect(s.drinkCountInCart, 1);
      expect(s.greenCupDiscount, 1);
      expect(s.total, closeTo(28, 0.001));

      final spendableBefore = s.loyalty.spendablePoints;
      final order = await s.placeOrder(
        paymentMethod: PaymentMethod.payAtCounter,
        fulfillment: FulfillmentType.takeaway,
      );
      expect(order.ownCup, isTrue);
      expect(order.greenCupDiscount, 1);
      expect(s.ownCup, isFalse, reason: 'toggle resets with the cart');

      s.setOrderStatus(order.id, OrderStatus.collected);
      final expected =
          (order.total * 10).round() + AppState.greenCupBonusPoints;
      expect(s.loyalty.spendablePoints, spendableBefore + expected);
      expect(s.cupsSaved, 1);
      s.advanceOrder(order.id);
      expect(s.loyalty.spendablePoints, spendableBefore + expected);
    });
  });

  group('Streaks and challenges', () {
    test('streak counts consecutive collected days', () {
      CafeOrder make(DateTime d) => CafeOrder(
            id: 'x${d.day}',
            createdAt: d,
            lines: const [],
            subtotal: 0,
            discount: 0,
            rewardDiscount: 0,
            total: 0,
            paymentMethod: PaymentMethod.payAtCounter,
            fulfillment: FulfillmentType.takeaway,
            status: OrderStatus.collected,
            queuePosition: 1,
            statusTimestamps: {OrderStatus.collected: d},
          );
      final now = DateTime(2026, 11, 9, 10);
      final orders = [
        make(DateTime(2026, 11, 9, 8)),
        make(DateTime(2026, 11, 8, 8)),
        make(DateTime(2026, 11, 7, 8)),
        make(DateTime(2026, 11, 4, 8)), // gap
      ];
      expect(ChallengesEngine.streakDays(orders, now), 3);
      expect(ChallengesEngine.streakDays(orders.sublist(1), now), 2,
          reason: 'yesterday still counts');
      expect(ChallengesEngine.streakDays(orders.sublist(3), now), 0);
    });

    test('challenge bonus can be claimed exactly once', () async {
      final s = await buildState();
      // Seed history already includes 3 collected orders this week?
      // Make sure by collecting demo orders.
      for (var i = 0; i < 3; i++) {
        s.addToCart(s.itemById('karak_chai'), size: 'Regular');
        final o = await s.placeOrder(
          paymentMethod: PaymentMethod.payAtCounter,
          fulfillment: FulfillmentType.takeaway,
        );
        s.setOrderStatus(o.id, OrderStatus.collected);
      }
      final regular = s.challenges.firstWhere((c) => c.id == 'three_this_week');
      expect(regular.claimable, isTrue);
      final before = s.loyalty.lifetimePoints;
      expect(s.claimChallenge('three_this_week'), isTrue);
      expect(s.loyalty.lifetimePoints, before + regular.bonusPoints);
      expect(s.claimChallenge('three_this_week'), isFalse);
      expect(s.loyalty.lifetimePoints, before + regular.bonusPoints);
      expect(s.claimChallenge('planner'), isFalse,
          reason: 'incomplete challenges cannot be claimed');
    });
  });

  group('Your usual', () {
    test('picks the most frequent customization from history', () async {
      final s = await buildState();
      final usual = s.usualLine;
      expect(usual, isNotNull);
      // Seeded history: iced latte and flat white tie on 3; cookies 3.
      // Add a strong signal and check it wins.
      s.addToCart(s.itemById('mint_tea'), size: 'Regular', quantity: 10);
      await s.placeOrder(
        paymentMethod: PaymentMethod.demoCard,
        fulfillment: FulfillmentType.takeaway,
      );
      expect(s.usualLine!.itemId, 'mint_tea');
      s.addUsualToCart();
      expect(s.cart.single.itemId, 'mint_tea');
      expect(s.cart.single.size, 'Regular');
    });
  });

  group('Pay it forward', () {
    test('gifting spends points, redeeming adds a free line once', () async {
      final s = await buildState();
      final karak = s.itemById('karak_chai');
      final cost = s.giftCostPoints(karak, size: 'Regular');
      final before = s.loyalty.spendablePoints;
      final kindnessBefore = s.kindnessCount;

      final voucher = s.giftCoffee(karak, size: 'Regular');
      expect(voucher, isNotNull);
      expect(voucher!.code, startsWith('GIFT-'));
      expect(s.loyalty.spendablePoints, before - cost);
      expect(s.kindnessCount, kindnessBefore + 1);

      expect(s.redeemGift('gift-nope'), GiftRedeemResult.invalid);
      expect(
          s.redeemGift(voucher.code.toLowerCase()), GiftRedeemResult.applied);
      expect(s.cart.single.unitPrice, 0);
      expect(s.cart.single.itemId, 'karak_chai');
      expect(s.subtotal, 0);
      expect(s.redeemGift(voucher.code), GiftRedeemResult.alreadyRedeemed);

      final order = await s.placeOrder(
        paymentMethod: PaymentMethod.payAtCounter,
        fulfillment: FulfillmentType.takeaway,
      );
      expect(order.giftCode, voucher.code);
      expect(order.total, 0);
    });

    test('cannot gift without enough points', () async {
      final s = await buildState();
      // Spend down: gift until it fails.
      var created = 0;
      while (s.giftCoffee(s.itemById('caramel_cloud_latte'), size: 'Large') !=
          null) {
        created++;
        if (created > 20) fail('gifting never ran out of points');
      }
      expect(created, greaterThan(0));
      expect(s.loyalty.spendablePoints, lessThan(260));
    });
  });
}
