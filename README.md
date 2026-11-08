# ALTITUDE — Your Campus Coffee Companion

*Your campus, in a cup.*

Flutter prototype built for the **ideaForge hackathon (AIRC × Altitude, RIT Dubai)**.
Altitude reimagines the campus cafe experience with ordering, a simulated live queue,
loyalty rewards, campus events and our signature feature, **Rush Mode**: tell the app how
many minutes you have before class and it recommends drinks and food estimated to be
ready in time.

> **Honesty note.** This is an **offline hackathon prototype**. Payments, queue positions,
> wait times, order status changes and the POS itself are **simulated on-device**. Nothing
> in the app is live cafe data. See [Simulated vs real](#simulated-vs-real-functionality).

---

## Contents

- [Prerequisites](#prerequisites)
- [Setup](#setup)
- [Run commands](#run-commands)
- [Feature overview](#feature-overview)
- [Rush Mode](#rush-mode)
- [Architecture](#architecture)
- [Local persistence](#local-persistence)
- [Demo walkthrough](#demo-walkthrough)
- [Simulated vs real functionality](#simulated-vs-real-functionality)
- [Testing & quality](#testing--quality)
- [Current limitations](#current-limitations)
- [Future integration roadmap](#future-integration-roadmap)

---

## Prerequisites

| Tool | Version |
| --- | --- |
| Flutter | stable channel, 3.24 or newer (built and verified with **Flutter 3.47.9 / Dart 3.13.7**) |
| Dart | ships with Flutter |
| Chrome | any recent version, for `flutter run -d chrome` |
| Android Studio / Xcode | optional, only for device builds |

Only one third-party package is used: `shared_preferences` for local persistence.
There is no Firebase, no backend, no API keys and no runtime network calls.

## Setup

```bash
git clone <this-repo> challenge
cd challenge
flutter pub get
```

If you copied only the `lib/`, `test/`, `docs/` and `pubspec.yaml` files into an empty
folder, generate the platform folders first:

```bash
flutter create . --project-name altitude_app --platforms=android,ios,web
flutter pub get
```

## Run commands

```bash
flutter run -d chrome        # Flutter Web in Chrome (recommended for the pitch)
flutter run                  # first connected device / emulator
flutter build apk --debug    # Android debug APK
flutter build web            # static web bundle in build/web
flutter analyze              # static analysis
flutter test                 # unit + widget tests
```

Tip for the demo: run in Chrome and resize the window to roughly 420 × 860 so it looks like
a phone. The layout caps content width on wide screens so it still looks right full-screen.

---

## Feature overview

| Area | What works |
| --- | --- |
| **Welcome** | First-launch panel, optional nickname (default `RIT Student`), no login |
| **Home** | Greeting, Gold loyalty card (1,240 lifetime pts, 260 to Platinum), Order Now, Rush Mode hero, Drink of the Month spotlight, Popular Now carousel, campus teaser, active-order card |
| **Menu** | 16 products across Coffee / Iced / Tea / Bakery / Snacks, live search, category filters, product sheet with size, milk, add-ons and quantity |
| **Cart** | Edit quantities, remove lines, subtotal, `CAMPUS10` coupon (10 %, cannot be applied twice), reward redemption, total |
| **Checkout** | Takeaway or At Table (table number required), Demo Card Payment **(SIMULATED)** or Pay at Counter **(DEMO)**, Place Demo Order |
| **Orders** | Unique order ID, simulated queue position, orders ahead, estimated wait, Received → Preparing → Ready → Collected timeline, "Your order is ready for pickup!" alert, order history with Reorder |
| **Rewards** | Tier, lifetime vs spendable points, progress bar, earning rules, three redeemable rewards, activity history |
| **Campus** | 5 sample club events with Going / Not going RSVP that persists |
| **Popular & Promos** | Popular Now ranked from seeded + demo order history; Caramel Cloud Latte spotlight; CAMPUS10 promo |
| **Rush Mode** | 10 / 15 / 20 / 30 minute windows, transparent wait model, Likely fits / May be tight, direct add-to-cart |
| **Demo Controls** | Generate sample order, move to Preparing / Ready / Collected, restore loyalty, reset data, About the Prototype |

Points rule: **10 points per AED 1** on the post-discount total, rounded, awarded **once**
when an order is marked Collected. Lifetime points drive the tier; spendable points are a
separate balance used for rewards (100 pts → AED 5).

## Rush Mode

Rush Mode is deliberately **rule-based and transparent** (no machine learning claims):

```
estimated wait = simulated queue delay + product preparation time
simulated queue delay = 2 min + 2 min × orders currently in queue
Likely fits  : estimate ≤ window − 3 min
May be tight : estimate ≤ window
Too long     : hidden by default, shown on request
```

Every estimate is labeled *Demo estimates only. Actual cafe preparation times may vary.*
Rush Mode needs no GPS, class schedule or any permission.

---

## Architecture

```
lib/
  main.dart                       app bootstrap, splash, welcome ↔ shell switch
  theme/        app_colors.dart, app_theme.dart        Material 3 theme, brand palette
  models/       menu_item, cart_line, cafe_order, loyalty_account, club_event, promo
  data/         seed_data.dart                          all sample content
  services/     pos_gateway.dart (interface)            POS boundary
                mock_pos_gateway.dart                   simulated adapter used in the demo
                local_storage_service.dart              JSON over SharedPreferences
                rush_mode_engine.dart                   pure recommendation logic
  state/        app_state.dart (ChangeNotifier)         single source of truth
                app_state_scope.dart (InheritedNotifier)
  screens/      home, menu, product_details, cart, checkout, orders,
                rewards, campus, rush_mode, demo_controls, welcome
  widgets/      navigation_shell, product_card, product_art (CustomPainter),
                loyalty_card, order_status_timeline, section_header, app_button, content_frame
test/           app_state_test.dart, widget_test.dart
docs/           DEMO_GUIDE.md, ARCHITECTURE.md
```

- **State**: one `AppState extends ChangeNotifier`, exposed via `AppStateScope`
  (an `InheritedNotifier`). Screens call `AppStateScope.of(context)`; callbacks use `.read`.
- **Navigation**: `IndexedStack` + Material 3 `NavigationBar` for the five tabs; `Navigator`
  pushes for cart, checkout, Rush Mode and Demo Controls.
- **POS boundary**: UI and state only talk to the abstract `PosGateway`. The prototype injects
  `MockPosGateway`. A future MOBIPOS adapter implements the same interface; no UI rewrite needed.
- **Visuals**: all product art and backgrounds are drawn locally with gradients, icons and
  `CustomPainter`. There are no bundled or remote images.

Full details in [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

## Local persistence

The whole app state is serialized to a single JSON document under the key
`altitude_state_v1` in `SharedPreferences` after every mutation. Persisted: nickname and
onboarding flag, cart lines, applied coupon, pending reward redemption, all orders (seeded and
demo), loyalty account and activity, RSVP selections, next order number and dismissed alerts.
On first launch (or after Reset) the seed data is loaded. Refreshing the browser or restarting
the app restores the demo exactly where it was.

---

## Demo walkthrough

Target: 60–90 seconds. The tap-by-tap script is in [docs/DEMO_GUIDE.md](docs/DEMO_GUIDE.md).

1. **Launch** → Home with Gold loyalty card and Drink of the Month.
2. **Rush Mode** → tap the hero, choose **15 min**, see Likely fits / May be tight.
3. **Select** → tap Iced Latte, pick size and oat milk, Add.
4. **Checkout** → cart icon, apply `CAMPUS10`, Takeaway, Demo Card Payment, Place Demo Order.
5. **Track** → Demo Controls (sliders icon in the app bar) → Mark Ready → Orders tab shows
   *Your order is ready for pickup!*
6. **Loyalty** → Mark Collected → Rewards shows the points increase (awarded once).
7. **Campus** → open an event, RSVP Going.

## Simulated vs real functionality

| Capability | Status in this prototype |
| --- | --- |
| Menu, cart, customization, coupons | Real app logic, running locally |
| Order placement and IDs | Real logic; accepted by `MockPosGateway` |
| Queue position, orders ahead, wait time | **Simulated** by a transparent rule |
| Order status progression | **Simulated**; driven by Demo Controls (no auto-advance) |
| Card payment | **Simulated**; never collects card numbers, CVV or PINs |
| Pay at counter | Demo selection only |
| Push notifications | Not available; replaced by an **in-app** ready banner |
| Loyalty points and tiers | Real logic, local persistence |
| Popular Now ranking | Real aggregation over seeded + demo orders |
| Campus events | Sample content, clearly labeled; RSVP persists locally |
| MOBIPOS integration | **Not implemented**; interface boundary only |

## Testing & quality

Executed on this machine with Flutter 3.47.9:

```
dart format .      → 38 files formatted
flutter analyze    → No issues found
flutter test       → 21 tests passed (17 unit, 4 widget)
flutter build web  → √ Built build/web (release bundle compiles cleanly)
```

Unit tests cover cart subtotal, line merging, quantity updates, coupon discount and duplicate
prevention, Rush Mode classification and ordering, order placement, status transitions,
exactly-once points, reward redemption, popularity ranking and persistence across instances.
Widget tests cover the welcome flow, Home rendering, tab switching, cart badge updates and
Rush Mode.

## Current limitations

- No real payments, POS connection or push notifications.
- Order status only changes through Demo Controls or the "Demo" button on an active order.
- Single device: data lives in this browser / app sandbox only; no accounts or sync.
- Sample menu, prices, preparation times and events are placeholders.
- Only one reward can be applied per order; rewards are not transferable.

## Future integration roadmap

To take Altitude to production with the cafe:

1. Obtain vendor-approved **MOBIPOS** API documentation and sandbox access.
2. Establish authentication and authorization for the app and for cafe staff.
3. Map Altitude menu/product IDs and modifiers to POS catalogue IDs.
4. Implement `MobiposGateway implements PosGateway` for order creation.
5. Synchronize order statuses through the documented webhook or polling mechanism.
6. Integrate an approved payment provider (tokenized, PCI-compliant; no card data in-app).
7. Reconcile payments against POS tickets.
8. Guarantee idempotent order submission (the prototype already passes an idempotency key).
9. Handle network failures with retries, offline cart and clear user messaging.
10. Add privacy and security controls (data minimization, consent, secure storage).
11. Pilot with cafe operators and iterate on prep-time calibration for Rush Mode.

No API shapes or endpoints are assumed in this repository; the interface in
`lib/services/pos_gateway.dart` is the only contract.

---

Credits: built for **ideaForge × AIRC**, RIT Dubai. Team Altitude.
