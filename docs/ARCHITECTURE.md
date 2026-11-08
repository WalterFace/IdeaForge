# Altitude — Architecture

This document explains how the prototype is put together, what is real, what is simulated,
and how it would grow into a production app connected to the Altitude cafe's MOBIPOS system.

## 1. High-level architecture

```
┌──────────────────────────────────────────────────────────────────┐
│ Flutter UI (Material 3)                                          │
│  NavigationShell ── IndexedStack ── Home | Menu | Orders |       │
│                                     Rewards | Campus             │
│  Pushed routes: ProductDetailsSheet, Cart, Checkout,             │
│                 RushMode, DemoControls                           │
└───────────────▲───────────────────────────────┬──────────────────┘
                │ AppStateScope.of(context)      │ user actions
┌───────────────┴───────────────────────────────▼──────────────────┐
│ AppState (ChangeNotifier)  — single source of truth              │
│  cart · orders · loyalty · rsvps · nickname · tab · alerts       │
│  business rules: coupons, rewards, points, popularity, queue     │
└───────┬───────────────────────┬─────────────────────┬────────────┘
        │                       │                     │
┌───────▼────────┐    ┌─────────▼─────────┐  ┌────────▼───────────┐
│ RushModeEngine │    │ PosGateway (abstract)│ │ LocalStorageService│
│ pure functions │    │  └ MockPosGateway   │  │ JSON ⇄ SharedPrefs │
└────────────────┘    │  └ (future) Mobipos │  └────────────────────┘
                      └─────────────────────┘
         SeedData — menu, events, promos, seeded orders & loyalty
```

Design principles:

- **One state object, no third-party state library.** `AppState extends ChangeNotifier` is
  exposed through `AppStateScope` (an `InheritedNotifier`). Widgets that render state call
  `AppStateScope.of(context)` and rebuild on `notifyListeners()`. Callbacks use
  `AppStateScope.read(context)` to avoid unnecessary subscriptions.
- **Business logic lives outside widgets.** Cart math, coupon rules, points, order lifecycle,
  popularity aggregation and Rush Mode scoring are in `state/` and `services/` and are unit
  tested without any widget.
- **The POS is behind an interface.** `PosGateway` is the only contract between the app and a
  point-of-sale system. The hackathon build injects `MockPosGateway`.
- **No remote assets.** Product art and hero backgrounds are drawn with gradients, Material
  icons and `CustomPainter` (`widgets/product_art.dart`).

## 2. State management

| Concern | Implementation |
| --- | --- |
| Container | `AppState` (`lib/state/app_state.dart`) |
| Exposure | `AppStateScope` (`InheritedNotifier<AppState>`) wrapping `MaterialApp` |
| Rebuilds | `dependOnInheritedWidgetOfExactType` in screens; `ListenableBuilder` not needed because the scope rebuilds dependents |
| Initialization | `main()` creates `LocalStorageService` and `AppState`; `AltitudeApp` awaits `state.init()` behind a `FutureBuilder` splash |
| Routing | `IndexedStack` keeps tab state; `AppState.tabIndex` lets business flows switch tabs (e.g. after placing an order) |
| Mutation pattern | mutate private fields → `_commit()` → `notifyListeners()` + `_persist()` |

Every public mutation on `AppState` is synchronous except `placeOrder` (awaits the gateway)
and `resetEverything` (clears storage).

## 3. Data models

| Model | Purpose | Persisted |
| --- | --- | --- |
| `MenuItem` | Product definition: id, name, description, AED price, category, tags, prep minutes, art style, sizes with upcharges, milks, add-ons | No (static seed) |
| `AddOn` | Named extra with a price | No |
| `CartLine` | A product with chosen size/milk/add-ons, unit price and quantity. `mergeKey` merges identical customizations | Yes |
| `CafeOrder` | Immutable order snapshot: lines, subtotal, coupon discount, reward discount, total, payment method, fulfilment, table, status, queue position, status timestamps, `pointsAwarded`, `isSeeded`, POS reference | Yes |
| `OrderStatus` | `received → preparing → ready → collected` with `next` | — |
| `LoyaltyAccount` | Lifetime points (tier), spendable points (balance), activity log | Yes |
| `LoyaltyTier` | Bronze 0 · Silver 500 · Gold 1,000 · Platinum 1,500 | — |
| `RewardOption` | Points cost → AED value | No (static) |
| `ClubEvent` | Sample event with category and optional cafe perk | No (static); RSVP map is persisted |
| `Promo`, `CouponRule` | Spotlight content and the `CAMPUS10` rule | No |
| `CampusLocation` | Fixed list of campus spots with walk minutes to the cafe | Selected id persisted |
| `GiftVoucher` | Pay-it-forward code, gifted item, redeemed timestamp | Yes |
| `ChallengeProgress` | Derived weekly challenge state (not stored; claimed ids are) | Claimed ids persisted |

All persisted models implement `toJson` / `fromJson` by hand (no code generation).

## 4. Persistence

- `LocalStorageService` wraps `SharedPreferences` with `readJson` / `writeJson`.
- `AppState` serializes **one document** under `altitude_state_v1`:
  `hasOnboarded, nickname, cart, appliedCoupon, pendingRewardId, ownCup, cartGiftCode, orders,
  loyalty, rsvps, nextOrderNumber, dismissedReadyAlerts, claimedChallenges, gifts,
  campusLocationId`.
- On `init()`: if the document exists and parses, restore it; otherwise (first launch,
  corrupted data or after reset) load `SeedData`.
- Writes happen after every mutation. Reads happen once at startup. SharedPreferences is
  backed by `localStorage` on web and platform preferences on Android/iOS, so a page refresh
  or app restart restores the demo.
- Tests use `SharedPreferences.setMockInitialValues({})` and verify a second `AppState`
  instance restores nickname, RSVP and cart.

## 5. Order lifecycle

```
Cart ──placeOrder()──▶ PosGateway.authorizePayment ──▶ PosGateway.submitOrder
                                                            │
                        CafeOrder(status: received, queuePosition, posReference)
                                                            │
      Demo Controls / "Demo" button ──▶ setOrderStatus(preparing)
                                     ──▶ setOrderStatus(ready)      → in-app banner
                                     ──▶ setOrderStatus(collected)  → points awarded once
```

Rules enforced in `AppState.setOrderStatus`:

- Status only moves **forward**; collected orders are frozen.
- Skipped steps receive timestamps so the timeline is always complete.
- On `collected`, if `pointsAwarded == false`: `points = round(total × 10)`, lifetime and
  spendable both increase, an activity row is appended, and the order is marked
  `pointsAwarded = true`. Repeated calls are no-ops.
- A pending reward redemption deducts spendable points when the order is placed and records a
  negative activity row.

Simulated queue:

- `ordersInQueue = 2 (fixed "other students") + active demo orders`
- New order `queuePosition = ordersInQueue + 1`; the mock gateway echoes this back.
- `ordersAhead = queuePosition − 1` while *Received*, `0` afterwards.
- `estimatedWait = ordersAhead × 2 + max(prep of lines)` while Received, half the prep while
  Preparing, `0` when Ready.

Everything above is labeled *simulated* in the UI.

## 6. Rush Mode 2.0 engine

`RushModeEngine.recommend(items, queueDelayMinutes, windowMinutes, walkMinutes)`:

1. `effectiveWindow = window − walk` (the student's chosen `CampusLocation`).
2. `estimate = queueDelay + item.prepMinutes` and `leaveIn = max(0, estimate − walk)` for
   every item.
3. Classify against the effective window: `likelyFits` if `estimate ≤ effective − 3`,
   `mayBeTight` if `estimate ≤ effective`, else `tooLong`.
4. Sort by fit, then estimate, then name. Return fits/tight as recommendations and the rest as
   `excluded` (shown collapsed).

`queueDelay = 2 + 2 × ordersInQueue + busyExtra`, where `busyExtra = round(4 × busyness)` and
`busyness` comes from `BusynessModel.levelAt(now)`: a fixed hourly campus curve (morning
rush 9 AM, lunch peak 12-1 PM, quiet evenings) plus a +0.15 spike within ten minutes of the
hour for class changeovers. The Rush Mode screen prints every term so judges can see it is a
rule, not a model.

## 6b. Streaks, challenges, Green Cup, gifts

- `ChallengesEngine.streakDays` counts consecutive days (ending today or yesterday) with a
  collected order. `evaluate` derives five weekly challenges from orders; only the set of
  *claimed* challenge ids is stored, so progress always matches the visible history.
  `AppState.claimChallenge` awards the bonus exactly once.
- Green Cup: `AppState.ownCup` is a cart-level toggle. `greenCupDiscount = AED 1 × paid drink
  units`, applied after coupon and reward. On collection the order's `ownCup` flag adds a
  20-point bonus alongside the regular points, still exactly once.
- Scheduled pickup: `placeOrder(scheduledFor:)` stores the slot on the order; slots are the
  next 15/30/45/60 minutes rounded to 5 minutes. Nothing auto-advances; Demo Controls still
  drive status.
- Pay it forward: `giftCoffee` deducts `price × 10` points, creates a `GiftVoucher` with a
  `GIFT-XXXX` code; `redeemGift` adds the drink as a zero-priced cart line and marks the
  voucher redeemed. Codes live only on this device in the prototype.

## 7. POS integration boundary

```dart
abstract class PosGateway {
  String get displayName;
  bool get isSimulated;
  Future<PosPaymentResult> authorizePayment({amountAed, method, idempotencyKey});
  Future<PosOrderResult> submitOrder(CafeOrder order);
  Future<OrderStatus?> fetchStatus(String orderId);
}
```

- `MockPosGateway` approves every payment, accepts every order, returns a `MOCK-xxxx`
  reference and a queue position, and adds a short artificial latency so the UI's loading state
  is visible. It never touches the network.
- A production `MobiposGateway` would implement the same interface. **We have not invented any
  MOBIPOS endpoints, payloads or authentication**; those require vendor-approved documentation
  and access. The idempotency key (the order ID) is already threaded through so retries are safe.
- Status synchronization (webhook vs polling) would feed `AppState.setOrderStatus`, replacing
  the manual Demo Controls. The UI needs no change.

## 8. Technical limitations

- No backend, accounts or multi-device sync; all data is local to one device/browser.
- Status changes are manual (Demo Controls). No timers auto-advance orders, to keep the pitch
  deterministic.
- Payment flows are simulated and intentionally collect **no** card data.
- Push notifications are replaced by an in-app banner.
- Prep times, prices, menu and events are sample data.
- Web `localStorage` can be cleared by the browser; the app simply reseeds.

## 9. Future implementation milestones

1. **Vendor access** — obtain MOBIPOS API documentation, sandbox credentials and menu export.
2. **Auth** — student sign-in (campus SSO) and staff roles; secure token storage.
3. **Catalogue sync** — map product/modifier IDs; nightly or webhook-driven menu and price sync.
4. **Order creation** — `MobiposGateway.submitOrder` with idempotency and error mapping.
5. **Status sync** — documented webhook or polling into `AppState.setOrderStatus`; push
   notifications for Ready.
6. **Payments** — approved, tokenized payment provider; reconciliation against POS tickets.
7. **Resilience** — offline cart, retry with backoff, clear failure states.
8. **Privacy & security** — data minimization, consent for notifications, audit of stored data.
9. **Rush Mode calibration** — replace the fixed rule with measured prep times from the POS,
   still presented as transparent estimates.
10. **Operator pilot** — test with Altitude baristas during peak hours; adjust queue model.
11. **Campus events** — submission and approval flow with Student Life; club admin roles.

## 10. Repository map

```
lib/main.dart                      bootstrap, splash, welcome/shell switch
lib/theme/                         AppColors, AppTheme (Material 3)
lib/models/                        data classes + JSON
lib/data/seed_data.dart            all sample content
lib/services/pos_gateway.dart      interface
lib/services/mock_pos_gateway.dart simulated adapter
lib/services/local_storage_service.dart
lib/services/rush_mode_engine.dart
lib/services/busyness_model.dart   simulated campus busyness curve
lib/services/challenges_engine.dart streaks and weekly challenges
lib/state/app_state.dart           ChangeNotifier
lib/state/app_state_scope.dart     InheritedNotifier
lib/screens/                       11 screens
lib/widgets/                       shell, cards, painters, buttons
test/app_state_test.dart           17 unit tests
test/innovations_test.dart         12 unit tests (v2 features)
test/widget_test.dart              4 widget tests
docs/DEMO_GUIDE.md                 90-second script
```
