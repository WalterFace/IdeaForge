import 'dart:math';

import 'package:flutter/foundation.dart';

import '../data/seed_data.dart';
import '../models/cafe_order.dart';
import '../models/campus_location.dart';
import '../models/cart_line.dart';
import '../models/club_event.dart';
import '../models/gift_voucher.dart';
import '../models/loyalty_account.dart';
import '../models/menu_item.dart';
import '../models/promo.dart';
import '../services/busyness_model.dart';
import '../services/challenges_engine.dart';
import '../services/local_storage_service.dart';
import '../services/mock_pos_gateway.dart';
import '../services/pos_gateway.dart';
import '../services/rush_mode_engine.dart';

enum CouponResult { applied, invalid, alreadyApplied, emptyCart }

enum RewardResult { applied, insufficientPoints, alreadyApplied, emptyCart }

enum GiftRedeemResult { applied, invalid, alreadyRedeemed }

class PopularPick {
  const PopularPick(this.item, this.quantitySold);
  final MenuItem item;
  final int quantitySold;
}

/// Single source of truth for the prototype.
///
/// Everything is persisted as one JSON document in SharedPreferences so a
/// refresh or restart keeps the demo exactly where it was.
class AppState extends ChangeNotifier {
  AppState({
    required LocalStorageService storage,
    PosGateway? posGateway,
    DateTime Function()? clock,
  })  : _storage = storage,
        _clock = clock ?? DateTime.now {
    _pos = posGateway ?? MockPosGateway(queueSeed: () => ordersInQueue);
  }

  static const String storageKey = 'altitude_state_v1';

  /// Pretend there are always a couple of other students in line.
  static const int simulatedBaseQueue = 2;

  /// Green Cup programme: AED off per drink and bonus points on collection.
  static const double greenCupDiscountPerDrink = 1;
  static const int greenCupBonusPoints = 20;

  /// Scheduled pickup slots offered at checkout.
  static const List<int> pickupOffsetsMinutes = [15, 30, 45, 60];

  final LocalStorageService _storage;
  final DateTime Function() _clock;
  late final PosGateway _pos;

  PosGateway get posGateway => _pos;
  DateTime get now => _clock();

  // ---------------------------------------------------------------- content
  final List<MenuItem> menu = SeedData.menuItems;
  final List<RewardOption> rewards = SeedData.rewards;
  final List<Promo> promos = SeedData.promos;
  late final List<ClubEvent> events = SeedData.events(_clock());

  // ------------------------------------------------------------------ state
  bool _initialized = false;
  bool _hasOnboarded = false;
  String _nickname = SeedData.defaultNickname;
  List<CartLine> _cart = [];
  String? _appliedCoupon;
  String? _pendingRewardId;
  bool _ownCup = false;
  String? _cartGiftCode;
  List<CafeOrder> _orders = [];
  LoyaltyAccount _loyalty =
      const LoyaltyAccount(lifetimePoints: 0, spendablePoints: 0, activity: []);
  Map<String, RsvpStatus> _rsvps = {};
  int _nextOrderNumber = SeedData.firstDemoOrderNumber;
  final Set<String> _dismissedReadyAlerts = {};
  final Set<String> _claimedChallenges = {};
  List<GiftVoucher> _gifts = [];
  String _campusLocationId = CampusLocation.all.first.id;
  int _tabIndex = 0;
  bool _placingOrder = false;
  String? _lastError;

  bool get isInitialized => _initialized;
  bool get hasOnboarded => _hasOnboarded;
  String get nickname => _nickname;
  List<CartLine> get cart => List.unmodifiable(_cart);
  String? get appliedCoupon => _appliedCoupon;
  RewardOption? get pendingReward => _pendingRewardId == null
      ? null
      : rewards.firstWhere((r) => r.id == _pendingRewardId);
  bool get ownCup => _ownCup;
  String? get cartGiftCode => _cartGiftCode;
  List<CafeOrder> get orders => List.unmodifiable(_orders);
  LoyaltyAccount get loyalty => _loyalty;
  Map<String, RsvpStatus> get rsvps => Map.unmodifiable(_rsvps);
  List<GiftVoucher> get giftVouchers => List.unmodifiable(_gifts);
  CampusLocation get campusLocation => CampusLocation.byId(_campusLocationId);
  int get tabIndex => _tabIndex;
  bool get isPlacingOrder => _placingOrder;
  String? get lastError => _lastError;

  // ------------------------------------------------------------------- init
  Future<void> init() async {
    final json = _storage.readJson(storageKey);
    if (json != null) {
      try {
        _restore(json);
      } catch (_) {
        _seed();
      }
    } else {
      _seed();
    }
    _initialized = true;
    notifyListeners();
  }

  void _seed() {
    final now = _clock();
    _cart = [];
    _appliedCoupon = null;
    _pendingRewardId = null;
    _ownCup = false;
    _cartGiftCode = null;
    _orders = SeedData.seedOrders(now);
    _loyalty = SeedData.seedLoyalty(now);
    _rsvps = {};
    _nextOrderNumber = SeedData.firstDemoOrderNumber;
    _dismissedReadyAlerts.clear();
    _claimedChallenges.clear();
    _gifts = [];
    _campusLocationId = CampusLocation.all.first.id;
  }

  void _restore(Map<String, dynamic> json) {
    _hasOnboarded = json['hasOnboarded'] as bool? ?? false;
    _nickname = json['nickname'] as String? ?? SeedData.defaultNickname;
    _cart = (json['cart'] as List<dynamic>? ?? const [])
        .map((e) => CartLine.fromJson(e as Map<String, dynamic>))
        .toList();
    _appliedCoupon = json['appliedCoupon'] as String?;
    _pendingRewardId = json['pendingRewardId'] as String?;
    if (_pendingRewardId != null &&
        !rewards.any((r) => r.id == _pendingRewardId)) {
      _pendingRewardId = null;
    }
    _ownCup = json['ownCup'] as bool? ?? false;
    _cartGiftCode = json['cartGiftCode'] as String?;
    _orders = (json['orders'] as List<dynamic>? ?? const [])
        .map((e) => CafeOrder.fromJson(e as Map<String, dynamic>))
        .toList();
    final loyaltyJson = json['loyalty'] as Map<String, dynamic>?;
    _loyalty = loyaltyJson == null
        ? SeedData.seedLoyalty(_clock())
        : LoyaltyAccount.fromJson(loyaltyJson);
    _rsvps = (json['rsvps'] as Map<String, dynamic>? ?? const {}).map(
      (k, v) => MapEntry(k, RsvpStatus.values.byName(v as String)),
    );
    _nextOrderNumber =
        json['nextOrderNumber'] as int? ?? SeedData.firstDemoOrderNumber;
    _dismissedReadyAlerts
      ..clear()
      ..addAll(
        (json['dismissedReadyAlerts'] as List<dynamic>? ?? const [])
            .map((e) => e as String),
      );
    _claimedChallenges
      ..clear()
      ..addAll(
        (json['claimedChallenges'] as List<dynamic>? ?? const [])
            .map((e) => e as String),
      );
    _gifts = (json['gifts'] as List<dynamic>? ?? const [])
        .map((e) => GiftVoucher.fromJson(e as Map<String, dynamic>))
        .toList();
    _campusLocationId =
        json['campusLocationId'] as String? ?? CampusLocation.all.first.id;
  }

  Map<String, dynamic> _toJson() => {
        'hasOnboarded': _hasOnboarded,
        'nickname': _nickname,
        'cart': _cart.map((l) => l.toJson()).toList(),
        'appliedCoupon': _appliedCoupon,
        'pendingRewardId': _pendingRewardId,
        'ownCup': _ownCup,
        'cartGiftCode': _cartGiftCode,
        'orders': _orders.map((o) => o.toJson()).toList(),
        'loyalty': _loyalty.toJson(),
        'rsvps': _rsvps.map((k, v) => MapEntry(k, v.name)),
        'nextOrderNumber': _nextOrderNumber,
        'dismissedReadyAlerts': _dismissedReadyAlerts.toList(),
        'claimedChallenges': _claimedChallenges.toList(),
        'gifts': _gifts.map((g) => g.toJson()).toList(),
        'campusLocationId': _campusLocationId,
      };

  Future<void> _persist() => _storage.writeJson(storageKey, _toJson());

  void _commit() {
    notifyListeners();
    _persist();
  }

  // ---------------------------------------------------------------- profile
  void completeOnboarding({String? nickname}) {
    final trimmed = nickname?.trim();
    _nickname = (trimmed == null || trimmed.isEmpty)
        ? SeedData.defaultNickname
        : trimmed;
    _hasOnboarded = true;
    _commit();
  }

  void setNickname(String value) {
    final trimmed = value.trim();
    _nickname = trimmed.isEmpty ? SeedData.defaultNickname : trimmed;
    _commit();
  }

  void setTab(int index) {
    if (_tabIndex == index) return;
    _tabIndex = index;
    notifyListeners();
  }

  void clearError() {
    _lastError = null;
    notifyListeners();
  }

  void setCampusLocation(String id) {
    _campusLocationId = CampusLocation.byId(id).id;
    _commit();
  }

  // ------------------------------------------------------------------- menu
  MenuItem itemById(String id) => SeedData.itemById(id);

  int prepMinutesFor(String itemId) => itemById(itemId).prepMinutes;

  MenuItem get drinkOfTheMonth => itemById(SeedData.drinkOfTheMonthId);

  static bool isDrink(MenuItem item) =>
      item.category == MenuCategory.coffee ||
      item.category == MenuCategory.iced ||
      item.category == MenuCategory.tea;

  List<MenuItem> searchMenu({String query = '', MenuCategory? category}) {
    final q = query.trim().toLowerCase();
    return menu.where((m) {
      if (category != null && m.category != category) return false;
      if (q.isEmpty) return true;
      return m.name.toLowerCase().contains(q) ||
          m.description.toLowerCase().contains(q) ||
          m.tags.any((t) => t.toLowerCase().contains(q));
    }).toList();
  }

  // ------------------------------------------------------------------- cart
  int get cartCount => _cart.fold(0, (sum, l) => sum + l.quantity);

  double get subtotal => _cart.fold(0.0, (sum, l) => sum + l.lineTotal);

  double get couponDiscount {
    if (_appliedCoupon == null) return 0;
    return SeedData.campusCoupon.discountFor(subtotal);
  }

  double get rewardDiscount {
    final r = pendingReward;
    if (r == null) return 0;
    return min(r.valueAed, max(0, subtotal - couponDiscount));
  }

  /// Number of paid drink units in the cart (gift lines excluded).
  int get drinkCountInCart => _cart
      .where((l) => l.unitPrice > 0 && isDrink(itemById(l.itemId)))
      .fold(0, (sum, l) => sum + l.quantity);

  double get greenCupDiscount {
    if (!_ownCup) return 0;
    final raw = drinkCountInCart * greenCupDiscountPerDrink;
    return min(raw, max(0, subtotal - couponDiscount - rewardDiscount));
  }

  double get total => max(
      0,
      double.parse(
          (subtotal - couponDiscount - rewardDiscount - greenCupDiscount)
              .toStringAsFixed(2)));

  void addToCart(
    MenuItem item, {
    String? size,
    String? milk,
    List<AddOn> addOns = const [],
    int quantity = 1,
  }) {
    if (quantity <= 0) return;
    final line = CartLine(
      id: _newId('line'),
      itemId: item.id,
      name: item.name,
      unitPrice: item.priceFor(size: size, selectedAddOns: addOns),
      quantity: quantity,
      size: size,
      milk: milk,
      addOns: addOns.map((a) => a.name).toList(),
    );
    final existingIndex = _cart.indexWhere((l) => l.mergeKey == line.mergeKey);
    if (existingIndex >= 0) {
      final existing = _cart[existingIndex];
      _cart[existingIndex] =
          existing.copyWith(quantity: existing.quantity + quantity);
    } else {
      _cart.add(line);
    }
    _commit();
  }

  void setLineQuantity(String lineId, int quantity) {
    final index = _cart.indexWhere((l) => l.id == lineId);
    if (index < 0) return;
    if (quantity <= 0) {
      _cart.removeAt(index);
    } else {
      _cart[index] = _cart[index].copyWith(quantity: quantity.clamp(1, 20));
    }
    if (_cart.isEmpty) _resetCartExtras();
    _commit();
  }

  void removeLine(String lineId) => setLineQuantity(lineId, 0);

  void clearCart() {
    _cart = [];
    _resetCartExtras();
    _commit();
  }

  void _resetCartExtras() {
    _appliedCoupon = null;
    _pendingRewardId = null;
    _ownCup = false;
    _cartGiftCode = null;
  }

  CouponResult applyCoupon(String code) {
    if (_cart.isEmpty) return CouponResult.emptyCart;
    final normalized = code.trim().toUpperCase();
    if (normalized != SeedData.campusCoupon.code) return CouponResult.invalid;
    if (_appliedCoupon == normalized) return CouponResult.alreadyApplied;
    _appliedCoupon = normalized;
    _commit();
    return CouponResult.applied;
  }

  void removeCoupon() {
    _appliedCoupon = null;
    _commit();
  }

  RewardResult applyReward(RewardOption reward) {
    if (_cart.isEmpty) return RewardResult.emptyCart;
    if (_pendingRewardId != null) return RewardResult.alreadyApplied;
    if (_loyalty.spendablePoints < reward.pointsCost) {
      return RewardResult.insufficientPoints;
    }
    _pendingRewardId = reward.id;
    _commit();
    return RewardResult.applied;
  }

  void removeReward() {
    _pendingRewardId = null;
    _commit();
  }

  void setOwnCup(bool value) {
    if (_ownCup == value) return;
    _ownCup = value;
    _commit();
  }

  // ----------------------------------------------------------- your usual
  /// The customization the student orders most often, from all history.
  CartLine? get usualLine {
    final counts = <String, int>{};
    final samples = <String, CartLine>{};
    for (final o in _orders) {
      for (final l in o.lines) {
        if (l.unitPrice <= 0) continue;
        counts.update(l.mergeKey, (v) => v + l.quantity,
            ifAbsent: () => l.quantity);
        samples.putIfAbsent(l.mergeKey, () => l);
      }
    }
    if (counts.isEmpty) return null;
    final best = counts.entries.reduce((a, b) => b.value > a.value ? b : a);
    return samples[best.key];
  }

  void addUsualToCart() {
    final line = usualLine;
    if (line == null) return;
    final item = itemById(line.itemId);
    final addOns =
        item.addOns.where((a) => line.addOns.contains(a.name)).toList();
    addToCart(item, size: line.size, milk: line.milk, addOns: addOns);
  }

  // ----------------------------------------------------------------- orders
  List<CafeOrder> get activeOrders => _orders.where((o) => o.isActive).toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  CafeOrder? get activeOrder =>
      activeOrders.isEmpty ? null : activeOrders.first;

  List<CafeOrder> get pastOrders => _orders.where((o) => !o.isActive).toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  CafeOrder? orderById(String id) {
    for (final o in _orders) {
      if (o.id == id) return o;
    }
    return null;
  }

  /// Orders currently "in the cafe queue" for the simulation.
  int get ordersInQueue => simulatedBaseQueue + activeOrders.length;

  double get busynessNow => BusynessModel.levelAt(_clock());
  String get busynessLabel => BusynessModel.labelFor(busynessNow);
  int get busyExtraMinutes => BusynessModel.extraQueueMinutes(busynessNow);

  int get queueDelayMinutes => RushModeEngine.queueDelayFor(
        ordersInQueue: ordersInQueue,
        busyExtraMinutes: busyExtraMinutes,
      );

  /// Pickup slots offered at checkout (15-minute steps, next hour).
  List<DateTime> get pickupSlots {
    final base = _clock();
    final rounded = DateTime(
        base.year, base.month, base.day, base.hour, (base.minute ~/ 5) * 5);
    return [
      for (final m in pickupOffsetsMinutes) rounded.add(Duration(minutes: m)),
    ];
  }

  CafeOrder? get orderAwaitingPickup {
    for (final o in activeOrders) {
      if (o.status == OrderStatus.ready &&
          !_dismissedReadyAlerts.contains(o.id)) {
        return o;
      }
    }
    return null;
  }

  void dismissReadyAlert(String orderId) {
    _dismissedReadyAlerts.add(orderId);
    _commit();
  }

  Future<CafeOrder> placeOrder({
    required PaymentMethod paymentMethod,
    required FulfillmentType fulfillment,
    String? tableNumber,
    DateTime? scheduledFor,
  }) async {
    if (_cart.isEmpty) throw StateError('Your cart is empty.');
    if (fulfillment == FulfillmentType.atTable &&
        (tableNumber == null || tableNumber.trim().isEmpty)) {
      throw StateError('Please enter a table number.');
    }
    if (_placingOrder) throw StateError('An order is already being placed.');

    _placingOrder = true;
    _lastError = null;
    notifyListeners();

    try {
      final now = _clock();
      final orderId = 'ALT-$_nextOrderNumber';
      final amount = total;
      final reward = pendingReward;

      final payment = await _pos.authorizePayment(
        amountAed: amount,
        method: paymentMethod,
        idempotencyKey: orderId,
      );
      if (!payment.approved) {
        throw StateError(payment.message ?? 'Payment was not approved.');
      }

      var order = CafeOrder(
        id: orderId,
        createdAt: now,
        lines: List<CartLine>.from(_cart),
        subtotal: subtotal,
        discount: couponDiscount,
        rewardDiscount: rewardDiscount,
        greenCupDiscount: greenCupDiscount,
        total: amount,
        couponCode: _appliedCoupon,
        paymentMethod: paymentMethod,
        fulfillment: fulfillment,
        tableNumber:
            fulfillment == FulfillmentType.atTable ? tableNumber!.trim() : null,
        status: OrderStatus.received,
        queuePosition: ordersInQueue + 1,
        statusTimestamps: {OrderStatus.received: now},
        scheduledFor: scheduledFor,
        ownCup: _ownCup,
        giftCode: _cartGiftCode,
      );

      final submission = await _pos.submitOrder(order);
      if (!submission.accepted) {
        throw StateError(submission.message ?? 'The order was not accepted.');
      }
      order = order.copyWith(
        queuePosition: submission.queuePosition,
        posReference: submission.posReference,
      );

      _orders.add(order);
      _nextOrderNumber += 1;

      if (reward != null) {
        _loyalty = _loyalty.copyWith(
          spendablePoints: _loyalty.spendablePoints - reward.pointsCost,
          activity: [
            LoyaltyActivity(
              id: _newId('la'),
              title: 'Redeemed ${reward.title} on $orderId',
              pointsDelta: -reward.pointsCost,
              timestamp: now,
              orderId: orderId,
            ),
            ..._loyalty.activity,
          ],
        );
      }

      _cart = [];
      _resetCartExtras();
      _tabIndex = 2;
      return order;
    } catch (e) {
      _lastError = e.toString().replaceFirst('Bad state: ', '');
      rethrow;
    } finally {
      _placingOrder = false;
      _commit();
    }
  }

  /// Moves an order to [status]. Only forward moves are allowed; a collected
  /// order never changes again. Points are awarded exactly once.
  bool setOrderStatus(String orderId, OrderStatus status) {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index < 0) return false;
    final order = _orders[index];
    if (status.index <= order.status.index) return false;

    final now = _clock();
    final stamps = Map<OrderStatus, DateTime>.from(order.statusTimestamps);
    for (final s in OrderStatus.values) {
      if (s.index > order.status.index && s.index <= status.index) {
        stamps.putIfAbsent(s, () => now);
      }
    }
    var updated = order.copyWith(status: status, statusTimestamps: stamps);

    if (status == OrderStatus.collected && !updated.pointsAwarded) {
      final earned = LoyaltyAccount.pointsForTotal(updated.total);
      final bonus = updated.ownCup ? greenCupBonusPoints : 0;
      _loyalty = _loyalty.copyWith(
        lifetimePoints: _loyalty.lifetimePoints + earned + bonus,
        spendablePoints: _loyalty.spendablePoints + earned + bonus,
        activity: [
          if (bonus > 0)
            LoyaltyActivity(
              id: _newId('la'),
              title: 'Green Cup bonus on ${updated.id}',
              pointsDelta: bonus,
              timestamp: now,
              orderId: updated.id,
            ),
          LoyaltyActivity(
            id: _newId('la'),
            title: 'Order ${updated.id} collected',
            pointsDelta: earned,
            timestamp: now,
            orderId: updated.id,
          ),
          ..._loyalty.activity,
        ],
      );
      updated = updated.copyWith(pointsAwarded: true);
    }

    _orders[index] = updated;
    _commit();
    return true;
  }

  bool advanceOrder(String orderId) {
    final order = orderById(orderId);
    final next = order?.status.next;
    if (order == null || next == null) return false;
    return setOrderStatus(orderId, next);
  }

  void reorder(CafeOrder order) {
    for (final line in order.lines) {
      if (line.unitPrice <= 0) continue; // gift lines are not re-orderable
      final item = itemById(line.itemId);
      final addOns =
          item.addOns.where((a) => line.addOns.contains(a.name)).toList();
      addToCart(
        item,
        size: line.size,
        milk: line.milk,
        addOns: addOns,
        quantity: line.quantity,
      );
    }
  }

  // ---------------------------------------------------------- popular picks
  /// Ranks products by quantity across seeded history and demo orders.
  List<PopularPick> get popularPicks {
    final counts = <String, int>{};
    for (final o in _orders) {
      for (final l in o.lines) {
        counts.update(l.itemId, (v) => v + l.quantity,
            ifAbsent: () => l.quantity);
      }
    }
    final picks = counts.entries
        .map((e) => PopularPick(itemById(e.key), e.value))
        .toList()
      ..sort((a, b) {
        final byQty = b.quantitySold.compareTo(a.quantitySold);
        return byQty != 0 ? byQty : a.item.name.compareTo(b.item.name);
      });
    return picks;
  }

  // -------------------------------------------------------------- rush mode
  RushResult rushRecommendations(int windowMinutes) => RushModeEngine.recommend(
        items: menu,
        queueDelayMinutes: queueDelayMinutes,
        windowMinutes: windowMinutes,
        walkMinutes: campusLocation.walkMinutes,
      );

  // -------------------------------------------------- streaks & challenges
  int get streakDays => ChallengesEngine.streakDays(_orders, _clock());

  List<ChallengeProgress> get challenges => ChallengesEngine.evaluate(
        orders: _orders,
        now: _clock(),
        claimed: _claimedChallenges,
        itemById: itemById,
      );

  /// Awards a completed challenge's bonus points exactly once.
  bool claimChallenge(String id) {
    final challenge = challenges.where((c) => c.id == id).firstOrNull;
    if (challenge == null || !challenge.claimable) return false;
    _claimedChallenges.add(id);
    _loyalty = _loyalty.copyWith(
      lifetimePoints: _loyalty.lifetimePoints + challenge.bonusPoints,
      spendablePoints: _loyalty.spendablePoints + challenge.bonusPoints,
      activity: [
        LoyaltyActivity(
          id: _newId('la'),
          title: 'Challenge complete: ${challenge.title}',
          pointsDelta: challenge.bonusPoints,
          timestamp: _clock(),
        ),
        ..._loyalty.activity,
      ],
    );
    _commit();
    return true;
  }

  /// Reusable cups used on collected orders.
  int get cupsSaved => _orders
      .where((o) => o.ownCup && o.status == OrderStatus.collected)
      .length;

  // --------------------------------------------------------- pay it forward
  int giftCostPoints(MenuItem item, {String? size}) =>
      (item.priceFor(size: size) * 10).round();

  /// Community count for the kindness board (seeded + gifts made here).
  int get kindnessCount => GiftVoucher.seededGiftsThisMonth + _gifts.length;

  /// Buys a drink for someone else with points. Returns null if the student
  /// cannot afford it.
  GiftVoucher? giftCoffee(MenuItem item, {String? size}) {
    final cost = giftCostPoints(item, size: size);
    if (_loyalty.spendablePoints < cost) return null;
    final now = _clock();
    final code = 'GIFT-${_giftSuffix(now)}';
    final voucher = GiftVoucher(
      code: code,
      itemId: item.id,
      size: size,
      createdAt: now,
      fromNickname: _nickname,
    );
    _gifts = [voucher, ..._gifts];
    _loyalty = _loyalty.copyWith(
      spendablePoints: _loyalty.spendablePoints - cost,
      activity: [
        LoyaltyActivity(
          id: _newId('la'),
          title: 'Gifted a ${item.name} ($code)',
          pointsDelta: -cost,
          timestamp: now,
        ),
        ..._loyalty.activity,
      ],
    );
    _commit();
    return voucher;
  }

  String _giftSuffix(DateTime now) {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final seed = now.microsecondsSinceEpoch + _gifts.length * 7919;
    final rnd = Random(seed);
    return List.generate(4, (_) => alphabet[rnd.nextInt(alphabet.length)])
        .join();
  }

  /// Redeems a gift code: the gifted drink is added to the cart for free.
  GiftRedeemResult redeemGift(String code) {
    final normalized = code.trim().toUpperCase();
    final index = _gifts.indexWhere((g) => g.code == normalized);
    if (index < 0) return GiftRedeemResult.invalid;
    final voucher = _gifts[index];
    if (voucher.isRedeemed) return GiftRedeemResult.alreadyRedeemed;

    final item = itemById(voucher.itemId);
    _cart.add(
      CartLine(
        id: _newId('line'),
        itemId: item.id,
        name: '${item.name} (gift)',
        unitPrice: 0,
        quantity: 1,
        size: voucher.size,
        addOns: ['From ${voucher.fromNickname}'],
      ),
    );
    _gifts[index] = voucher.copyWith(redeemedAt: _clock());
    _cartGiftCode = normalized;
    _commit();
    return GiftRedeemResult.applied;
  }

  // ----------------------------------------------------------------- campus
  RsvpStatus rsvpFor(String eventId) => _rsvps[eventId] ?? RsvpStatus.none;

  void setRsvp(String eventId, RsvpStatus status) {
    if (status == RsvpStatus.none) {
      _rsvps.remove(eventId);
    } else {
      _rsvps[eventId] = status;
    }
    _commit();
  }

  // --------------------------------------------------------------- demo ops
  void resetDemoData() {
    _seed();
    _tabIndex = 0;
    _commit();
  }

  Future<void> resetEverything() async {
    _seed();
    _hasOnboarded = false;
    _nickname = SeedData.defaultNickname;
    _tabIndex = 0;
    await _storage.remove(storageKey);
    notifyListeners();
  }

  void restoreInitialLoyalty() {
    _loyalty = SeedData.seedLoyalty(_clock());
    _pendingRewardId = null;
    _claimedChallenges.clear();
    _commit();
  }

  CafeOrder generateSampleActiveOrder() {
    final now = _clock();
    final latte = itemById('iced_latte');
    final cookie = itemById('choc_chip_cookie');
    final lines = [
      CartLine(
        id: _newId('line'),
        itemId: latte.id,
        name: latte.name,
        unitPrice: latte.priceFor(size: 'Medium'),
        quantity: 1,
        size: 'Medium',
        milk: 'Oat',
      ),
      CartLine(
        id: _newId('line'),
        itemId: cookie.id,
        name: cookie.name,
        unitPrice: cookie.price,
        quantity: 1,
      ),
    ];
    final subtotal = lines.fold(0.0, (s, l) => s + l.lineTotal);
    final order = CafeOrder(
      id: 'ALT-$_nextOrderNumber',
      createdAt: now,
      lines: lines,
      subtotal: subtotal,
      discount: 0,
      rewardDiscount: 0,
      total: subtotal,
      paymentMethod: PaymentMethod.payAtCounter,
      fulfillment: FulfillmentType.takeaway,
      status: OrderStatus.received,
      queuePosition: ordersInQueue + 1,
      statusTimestamps: {OrderStatus.received: now},
      posReference: 'DEMO-SAMPLE',
    );
    _orders.add(order);
    _nextOrderNumber += 1;
    _commit();
    return order;
  }

  // ---------------------------------------------------------------- helpers
  int _idCounter = 0;
  String _newId(String prefix) {
    _idCounter += 1;
    return '${prefix}_${_clock().microsecondsSinceEpoch}_$_idCounter';
  }
}
