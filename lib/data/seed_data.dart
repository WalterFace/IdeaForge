import '../models/cafe_order.dart';
import '../models/cart_line.dart';
import '../models/club_event.dart';
import '../models/loyalty_account.dart';
import '../models/menu_item.dart';
import '../models/promo.dart';

/// All sample content for the offline prototype.
///
/// Nothing in this file is live cafe data. Prices, prep times and events are
/// believable placeholders for the hackathon demo.
class SeedData {
  SeedData._();

  static const String defaultNickname = 'RIT Student';
  static const String drinkOfTheMonthId = 'caramel_cloud_latte';

  static const List<String> standardSizes = ['Small', 'Medium', 'Large'];
  static const Map<String, double> standardSizeUpcharge = {
    'Small': 0,
    'Medium': 2,
    'Large': 4,
  };
  static const List<String> standardMilks = [
    'Whole milk',
    'Skimmed',
    'Oat',
    'Almond',
  ];

  static const List<MenuItem> menuItems = [
    MenuItem(
      id: 'double_espresso',
      name: 'Double Espresso',
      description: 'Two tight shots of our house blend. Sharp, chocolatey, quick.',
      price: 12,
      category: MenuCategory.coffee,
      tags: ['quick', 'strong', 'classic'],
      prepMinutes: 2,
      art: ProductArt.espresso,
      addOns: [AddOn('Extra shot', 4)],
    ),
    MenuItem(
      id: 'americano',
      name: 'Americano',
      description: 'Espresso lengthened with hot water. Clean and no-nonsense.',
      price: 14,
      category: MenuCategory.coffee,
      tags: ['quick', 'classic'],
      prepMinutes: 3,
      art: ProductArt.espresso,
      sizes: standardSizes,
      sizeUpcharge: standardSizeUpcharge,
      addOns: [AddOn('Extra shot', 4), AddOn('Splash of milk', 0)],
    ),
    MenuItem(
      id: 'flat_white',
      name: 'Flat White',
      description: 'Velvety microfoam over a double ristretto. The campus favourite.',
      price: 18,
      category: MenuCategory.coffee,
      tags: ['popular', 'milky'],
      prepMinutes: 4,
      art: ProductArt.latte,
      sizes: ['Small', 'Medium'],
      sizeUpcharge: {'Small': 0, 'Medium': 2},
      milks: standardMilks,
      addOns: [AddOn('Extra shot', 4)],
    ),
    MenuItem(
      id: 'cappuccino',
      name: 'Cappuccino',
      description: 'Classic thirds: espresso, steamed milk, airy foam. Cocoa dusted.',
      price: 17,
      category: MenuCategory.coffee,
      tags: ['classic', 'milky'],
      prepMinutes: 4,
      art: ProductArt.latte,
      sizes: standardSizes,
      sizeUpcharge: standardSizeUpcharge,
      milks: standardMilks,
      addOns: [AddOn('Extra shot', 4), AddOn('Cinnamon dust', 0)],
    ),
    MenuItem(
      id: 'caramel_cloud_latte',
      name: 'Caramel Cloud Latte',
      description:
          'Drink of the Month. Silky latte topped with salted caramel cold foam.',
      price: 22,
      category: MenuCategory.coffee,
      tags: ['featured', 'sweet', 'new'],
      prepMinutes: 5,
      art: ProductArt.latte,
      sizes: standardSizes,
      sizeUpcharge: standardSizeUpcharge,
      milks: standardMilks,
      addOns: [
        AddOn('Extra caramel drizzle', 2),
        AddOn('Extra shot', 4),
        AddOn('Whipped cream', 2),
      ],
    ),
    MenuItem(
      id: 'iced_latte',
      name: 'Iced Latte',
      description: 'Double espresso over ice with cold milk. Fast and refreshing.',
      price: 19,
      category: MenuCategory.iced,
      tags: ['quick', 'popular', 'cold'],
      prepMinutes: 3,
      art: ProductArt.iced,
      sizes: standardSizes,
      sizeUpcharge: standardSizeUpcharge,
      milks: standardMilks,
      addOns: [AddOn('Vanilla syrup', 2), AddOn('Extra shot', 4)],
    ),
    MenuItem(
      id: 'cold_brew',
      name: 'Cold Brew',
      description: '18-hour steeped cold brew. Smooth, low acidity, high energy.',
      price: 18,
      category: MenuCategory.iced,
      tags: ['quick', 'strong', 'cold'],
      prepMinutes: 2,
      art: ProductArt.iced,
      sizes: ['Medium', 'Large'],
      sizeUpcharge: {'Medium': 0, 'Large': 3},
      addOns: [AddOn('Oat milk top', 2), AddOn('Vanilla syrup', 2)],
    ),
    MenuItem(
      id: 'iced_matcha',
      name: 'Iced Matcha Latte',
      description: 'Ceremonial-grade matcha whisked and poured over iced milk.',
      price: 21,
      category: MenuCategory.iced,
      tags: ['cold', 'green', 'caffeine-light'],
      prepMinutes: 4,
      art: ProductArt.matcha,
      sizes: standardSizes,
      sizeUpcharge: standardSizeUpcharge,
      milks: standardMilks,
      addOns: [AddOn('Honey', 1)],
    ),
    MenuItem(
      id: 'karak_chai',
      name: 'Karak Chai',
      description: 'Slow-simmered spiced tea with cardamom. A campus ritual.',
      price: 9,
      category: MenuCategory.tea,
      tags: ['quick', 'popular', 'spiced'],
      prepMinutes: 3,
      art: ProductArt.tea,
      sizes: ['Regular', 'Large'],
      sizeUpcharge: {'Regular': 0, 'Large': 2},
      addOns: [AddOn('Extra cardamom', 0), AddOn('Less sugar', 0)],
    ),
    MenuItem(
      id: 'mint_tea',
      name: 'Fresh Mint Tea',
      description: 'Green tea steeped with fresh mint leaves. Calm in a cup.',
      price: 10,
      category: MenuCategory.tea,
      tags: ['quick', 'herbal'],
      prepMinutes: 3,
      art: ProductArt.tea,
      sizes: ['Regular', 'Pot for two'],
      sizeUpcharge: {'Regular': 0, 'Pot for two': 6},
    ),
    MenuItem(
      id: 'butter_croissant',
      name: 'Butter Croissant',
      description: 'Flaky, golden, baked each morning. Ask for it warm.',
      price: 11,
      category: MenuCategory.bakery,
      tags: ['quick', 'breakfast'],
      prepMinutes: 1,
      art: ProductArt.pastry,
      addOns: [AddOn('Warm it up', 0), AddOn('Side of jam', 2)],
    ),
    MenuItem(
      id: 'almond_croissant',
      name: 'Almond Croissant',
      description: 'Twice-baked with frangipane and toasted almonds.',
      price: 14,
      category: MenuCategory.bakery,
      tags: ['sweet', 'breakfast'],
      prepMinutes: 1,
      art: ProductArt.pastry,
      addOns: [AddOn('Warm it up', 0)],
    ),
    MenuItem(
      id: 'blueberry_muffin',
      name: 'Blueberry Muffin',
      description: 'Bursting with blueberries, crunchy sugar top.',
      price: 12,
      category: MenuCategory.bakery,
      tags: ['sweet', 'quick'],
      prepMinutes: 1,
      art: ProductArt.pastry,
    ),
    MenuItem(
      id: 'choc_chip_cookie',
      name: 'Chocolate Chip Cookie',
      description: 'Chewy centre, crisp edges, sea salt finish.',
      price: 8,
      category: MenuCategory.snacks,
      tags: ['quick', 'sweet', 'popular'],
      prepMinutes: 1,
      art: ProductArt.cookie,
    ),
    MenuItem(
      id: 'halloumi_wrap',
      name: 'Grilled Halloumi Wrap',
      description: 'Grilled halloumi, rocket, roasted peppers and zaatar mayo.',
      price: 24,
      category: MenuCategory.snacks,
      tags: ['lunch', 'filling', 'vegetarian'],
      prepMinutes: 7,
      art: ProductArt.sandwich,
      addOns: [AddOn('Extra halloumi', 5), AddOn('Add chips', 6)],
    ),
    MenuItem(
      id: 'granola_cup',
      name: 'Yogurt Granola Cup',
      description: 'Greek yogurt, house granola, seasonal fruit and honey.',
      price: 16,
      category: MenuCategory.snacks,
      tags: ['healthy', 'quick', 'breakfast'],
      prepMinutes: 2,
      art: ProductArt.cookie,
    ),
  ];

  static MenuItem itemById(String id) =>
      menuItems.firstWhere((m) => m.id == id, orElse: () => menuItems.first);

  static const CouponRule campusCoupon = CouponRule(
    code: 'CAMPUS10',
    percentOff: 10,
    description: '10% off your order with code CAMPUS10',
  );

  static const List<Promo> promos = [
    Promo(
      id: 'promo_dotm',
      title: 'Caramel Cloud Latte',
      subtitle: 'Drink of the Month. Salted caramel cold foam over a silky latte.',
      badge: 'Drink of the Month',
      kind: PromoKind.product,
      itemId: drinkOfTheMonthId,
    ),
    Promo(
      id: 'promo_campus10',
      title: '10% off with CAMPUS10',
      subtitle: 'Apply the code at checkout. Demo coupon for the prototype.',
      badge: 'Coupon',
      kind: PromoKind.coupon,
      couponCode: 'CAMPUS10',
    ),
  ];

  static const List<RewardOption> rewards = [
    RewardOption(
      id: 'reward_5',
      title: 'AED 5 off',
      pointsCost: 100,
      valueAed: 5,
      description: 'Redeem 100 points for AED 5 off your next order.',
    ),
    RewardOption(
      id: 'reward_12',
      title: 'AED 12 off',
      pointsCost: 220,
      valueAed: 12,
      description: 'Redeem 220 points for AED 12 off. Great for a drink + snack.',
    ),
    RewardOption(
      id: 'reward_25',
      title: 'AED 25 off',
      pointsCost: 400,
      valueAed: 25,
      description: 'Redeem 400 points for AED 25 off a lunch run.',
    ),
  ];

  static const int seededLifetimePoints = 1240;
  static const int seededSpendablePoints = 420;

  static LoyaltyAccount seedLoyalty(DateTime now) => LoyaltyAccount(
        lifetimePoints: seededLifetimePoints,
        spendablePoints: seededSpendablePoints,
        activity: [
          LoyaltyActivity(
            id: 'la_1',
            title: 'Order ALT-1041 collected',
            pointsDelta: 190,
            timestamp: now.subtract(const Duration(days: 1, hours: 3)),
            orderId: 'ALT-1041',
          ),
          LoyaltyActivity(
            id: 'la_2',
            title: 'Redeemed AED 5 reward',
            pointsDelta: -100,
            timestamp: now.subtract(const Duration(days: 2, hours: 1)),
          ),
          LoyaltyActivity(
            id: 'la_3',
            title: 'Order ALT-1038 collected',
            pointsDelta: 270,
            timestamp: now.subtract(const Duration(days: 3, hours: 5)),
            orderId: 'ALT-1038',
          ),
          LoyaltyActivity(
            id: 'la_4',
            title: 'Reached Gold tier',
            pointsDelta: 0,
            timestamp: now.subtract(const Duration(days: 6)),
          ),
          LoyaltyActivity(
            id: 'la_5',
            title: 'Order ALT-1031 collected',
            pointsDelta: 160,
            timestamp: now.subtract(const Duration(days: 7, hours: 2)),
            orderId: 'ALT-1031',
          ),
        ],
      );

  static const int firstDemoOrderNumber = 1042;

  /// Seeded, already-collected sample orders. These drive Popular Now
  /// alongside any orders placed during the demo.
  static List<CafeOrder> seedOrders(DateTime now) {
    CafeOrder build(
      int number,
      Duration ago,
      List<(String, int, String?)> items,
    ) {
      final lines = <CartLine>[];
      var subtotal = 0.0;
      for (final (itemId, qty, size) in items) {
        final item = itemById(itemId);
        final unit = item.priceFor(size: size);
        subtotal += unit * qty;
        lines.add(
          CartLine(
            id: 'seed_${number}_$itemId',
            itemId: itemId,
            name: item.name,
            unitPrice: unit,
            quantity: qty,
            size: size,
          ),
        );
      }
      final created = now.subtract(ago);
      return CafeOrder(
        id: 'ALT-$number',
        createdAt: created,
        lines: lines,
        subtotal: subtotal,
        discount: 0,
        rewardDiscount: 0,
        total: subtotal,
        paymentMethod: PaymentMethod.payAtCounter,
        fulfillment: FulfillmentType.takeaway,
        status: OrderStatus.collected,
        queuePosition: 2,
        statusTimestamps: {
          OrderStatus.received: created,
          OrderStatus.preparing: created.add(const Duration(minutes: 2)),
          OrderStatus.ready: created.add(const Duration(minutes: 6)),
          OrderStatus.collected: created.add(const Duration(minutes: 9)),
        },
        pointsAwarded: true,
        isSeeded: true,
      );
    }

    return [
      build(1041, const Duration(days: 1, hours: 3), [
        ('iced_latte', 1, 'Medium'),
        ('choc_chip_cookie', 1, null),
      ]),
      build(1040, const Duration(days: 2, hours: 4), [
        ('flat_white', 2, 'Small'),
        ('butter_croissant', 1, null),
      ]),
      build(1039, const Duration(days: 2, hours: 6), [
        ('karak_chai', 2, 'Regular'),
      ]),
      build(1038, const Duration(days: 3, hours: 5), [
        ('caramel_cloud_latte', 1, 'Medium'),
        ('halloumi_wrap', 1, null),
      ]),
      build(1035, const Duration(days: 5, hours: 2), [
        ('iced_latte', 1, 'Large'),
        ('blueberry_muffin', 1, null),
      ]),
      build(1031, const Duration(days: 7, hours: 2), [
        ('flat_white', 1, 'Medium'),
        ('choc_chip_cookie', 2, null),
      ]),
    ];
  }

  static List<ClubEvent> events(DateTime now) {
    DateTime onDay(int daysAhead) {
      final d = now.add(Duration(days: daysAhead));
      return DateTime(d.year, d.month, d.day);
    }

    return [
      ClubEvent(
        id: 'evt_hack_night',
        title: 'Hack Night: Build in 3 Hours',
        club: 'RIT Dubai Coding Club',
        date: onDay(2),
        time: '6:00 PM – 9:00 PM',
        venue: 'Innovation Lab, Level 2',
        description:
            'Bring a laptop and an idea. Teams form on the spot, mentors float, '
            'and the best demo wins a month of free Altitude coffee.',
        category: EventCategory.tech,
        perk: 'Altitude keeps the espresso machine running until 9 PM',
      ),
      ClubEvent(
        id: 'evt_open_mic',
        title: 'Open Mic & Latte Art Showdown',
        club: 'Arts & Culture Society',
        date: onDay(4),
        time: '5:30 PM – 7:30 PM',
        venue: 'Altitude Cafe Terrace',
        description:
            'Poetry, acoustic sets and a friendly latte-art battle judged by '
            'the baristas. Sign up for a 5-minute slot at the counter.',
        category: EventCategory.arts,
        perk: 'Performers get a free drink of the month',
      ),
      ClubEvent(
        id: 'evt_futsal',
        title: 'Inter-Major Futsal Cup',
        club: 'Sports Committee',
        date: onDay(6),
        time: '4:00 PM – 8:00 PM',
        venue: 'Outdoor Courts',
        description:
            'Engineering vs Business vs Computing. Five-a-side, knockout '
            'format, bring your own supporters.',
        category: EventCategory.sports,
        perk: 'Cold brew 2-for-1 for players with a wristband',
      ),
      ClubEvent(
        id: 'evt_study_jam',
        title: 'Finals Study Jam',
        club: 'Student Government',
        date: onDay(9),
        time: '7:00 PM – 11:00 PM',
        venue: 'Library Atrium',
        description:
            'Quiet zones, peer tutors on rotation and late-night snacks. The '
            'cafe runs a karak cart from 9 PM.',
        category: EventCategory.academic,
        perk: 'Karak cart from 9 PM',
      ),
      ClubEvent(
        id: 'evt_board_games',
        title: 'Board Game Social',
        club: 'Tabletop Society',
        date: onDay(11),
        time: '6:00 PM – 9:00 PM',
        venue: 'Student Lounge',
        description:
            'Catan, Codenames and a few obscure imports. New players very '
            'welcome. Snacks are on the society.',
        category: EventCategory.social,
      ),
    ];
  }
}
