# Altitude — Your Campus Coffee Companion

A Flutter prototype for the **ideaForge × AIRC hackathon** at RIT Dubai. Altitude lets students browse the campus cafe menu, customize and order drinks ahead of time, track their order through the queue, earn loyalty points, and discover club events — all from one app.

The prototype runs **fully on-device and offline**. Every backend (point-of-sale, payments, queue, order status) is simulated and clearly labelled as such, so the app can be demoed anywhere without network access or real cafe data.

---

## Features

### Ordering
- **Menu** with 16 seeded items across Coffee, Iced, Tea, Bakery and Snacks, with search and category filters.
- **Product customization**: sizes with upcharges, milk options and paid add-ons. Identical customizations merge into a single cart line.
- **Cart** with quantity controls, a demo coupon (`CAMPUS10` for 10% off) and one redeemable loyalty reward per order.
- **Checkout** with Takeaway or At-Table fulfilment (table number required) and two simulated payment methods: Demo Card and Pay at Counter.
- **Order tracking** through Received → Preparing → Ready → Collected, with a timestamped status timeline, queue position and a "ready" alert. One-tap reorder from history.

### Rush Mode
Between classes and short on time? Pick a window (10, 15, 20 or 30 minutes) and Rush Mode ranks the menu by whether it will be ready in time.

The model is deliberately transparent and rule-based, not machine learning:

```
estimated wait = simulated queue delay + item preparation time
queue delay    = 2 min hand-off + 2 min per order already in queue
```

Items are classified as **Likely fits** (3-minute safety buffer), **May be tight**, or **Too long**, and sorted accordingly. The estimation rule is shown to the student inside the app.

### Loyalty
- Earn **10 points per AED 1** on the post-discount total, awarded exactly once when the order is marked Collected.
- **Lifetime points** set the tier (Silver 500 · Gold 1,000 · Platinum 1,500) and never go down.
- **Spendable points** are a separate balance redeemed for AED 5 / 12 / 25 rewards at checkout.
- Activity feed of earned and redeemed points.

### Campus
- Sample club events across Tech, Arts, Sports, Social and Academic categories, some with a cafe perk tied in.
- RSVP (Going / Not going) that persists across restarts.

### Demo Controls (judge-facing)
A visually distinct screen, reachable from the app bar, for driving the demo:
- Generate a sample active order and step it through each status.
- Restore the initial loyalty state, reset sample data, or reset the whole demo back to the welcome screen.
- An **About the prototype** panel that states exactly what runs on-device, what is simulated, what needs real cafe integration, and what is planned for production.

---

## Architecture

```
lib/
├── main.dart                 App entry, splash, onboarding switch
├── data/seed_data.dart       Menu, promos, coupons, rewards, events, seeded history
├── models/                   MenuItem, CartLine, CafeOrder, LoyaltyAccount, Promo, ClubEvent
├── services/
│   ├── pos_gateway.dart      Abstract POS boundary (authorize, submit, fetch status)
│   ├── mock_pos_gateway.dart Offline simulated adapter used in the prototype
│   ├── rush_mode_engine.dart Rule-based wait-time recommendation engine
│   └── local_storage_service.dart  JSON wrapper over SharedPreferences
├── state/                    AppState (single source of truth) + InheritedWidget scope
├── screens/                  Welcome, Home, Menu, Product details, Cart, Checkout,
│                             Orders, Rewards, Rush Mode, Campus, Demo Controls
├── theme/                    Coffee-inspired palette and Material theme
├── utils/formatters.dart     Currency and date helpers
└── widgets/                  Navigation shell, product cards, loyalty card, timeline…
```

**State management** is a single `AppState` (`ChangeNotifier`) exposed through an `InheritedWidget`. No third-party state library is used.

**Persistence** uses `shared_preferences`. Cart, orders, loyalty, RSVPs and onboarding all survive refresh and restart.

**POS boundary.** The UI never talks to a backend directly. Everything goes through the `PosGateway` interface, which has three methods: authorize a payment, submit an order and fetch an order's status. The hackathon build wires in `MockPosGateway`, which adds a short latency, approves every payment, returns a simulated queue position and never touches the network. A production adapter for the cafe's MOBIPOS system would implement the same interface, so swapping it in requires no UI changes. No real endpoints, credentials or card data exist anywhere in this codebase.

---

## Getting started

### Prerequisites
- Flutter SDK (Dart ≥ 3.5)
- A device, emulator, or Chrome for web

### Run

```bash
flutter pub get
flutter run            # pick a connected device or emulator
flutter run -d chrome  # run in the browser
```

On first launch the app shows a welcome screen with an optional nickname. There is no login.

### Test

```bash
flutter test
```

The test suite covers cart maths and line merging, coupon rules, Rush Mode classification and sorting, order placement and status transitions, loyalty point awarding and redemption, popular-pick ranking, and RSVP persistence.

---

## What is simulated

| Area | In this prototype | Needed for production |
|---|---|---|
| Point of sale | `MockPosGateway`, offline | Vendor-approved MOBIPOS adapter |
| Payments | Always approved, no card data collected | Approved payment provider, reconciliation |
| Queue and wait times | Fixed formula, fake queue depth | Live queue data from the cafe |
| Order status | Advanced manually from Demo Controls | Staff-side order management, status sync |
| Notifications | In-app "ready" alert only | Push notifications |
| Menu and prices | Hard-coded seed data | Menu/price sync from POS |
| Authentication | Optional nickname | Real student auth |
| Club events | Sample content | Submission flow via Student Life |

Nothing in the app reflects live cafe data, and the app says so on screen.

---

## Tech stack

- Flutter / Dart
- `shared_preferences` for local persistence
- No other runtime dependencies

## License

Hackathon prototype. Not yet licensed for redistribution.
