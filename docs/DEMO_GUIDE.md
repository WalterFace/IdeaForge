# Altitude — 90-Second Demo Guide

Run with `flutter run -d chrome`, then resize the Chrome window to about **420 × 860** so it
reads as a phone. Everything below works offline. Nothing is live cafe data.

If the app has been used before, open **Demo Controls** (sliders icon, top-right) →
**Reset sample data** so you start from the seeded state. If you want the welcome panel,
use **Reset demo (show welcome again)**.

---

## The script (tap by tap)

### 0:00 — Launch (≈10 s)

1. Welcome panel appears. Optionally type a nickname (e.g. *Sara*). Tap **Get Started**.
2. Home loads. Point out:
   - **ALTITUDE** brand and the greeting.
   - **Gold** loyalty card: *1,240 lifetime pts*, *260 pts to Platinum*.
   - **Rush Mode** hero card (caramel) and **Caramel Cloud Latte — Drink of the Month**.
   - **Popular Now** carousel ("ranked from order history", not hardcoded).

> Pitch line: "Altitude is the campus cafe in your pocket. But the thing we are proudest of
> is Rush Mode."

### 0:10 — Rush Mode (≈15 s)

3. Tap **I'm in a rush** on the Rush Mode card (note the "Cafe is Busy/Quiet now" pill).
4. Headline reads *Running late for class? We've got you.* Tap **15 min**, then pick
   **Engineering labs · 4 min** under *Where are you?*.
5. Show the **How we estimate** box: queue delay (orders in line + how busy the cafe is),
   walk time, and the time left for the order. Rule-based, demo estimates only.
6. Scroll: **Likely fits** items first (Cookie, Cold Brew, Iced Latte...), then **May be
   tight**. Each shows *ready in ~N min* and *leave in N min*: the student knows exactly
   when to start walking.

### 0:25 — Select a product (≈10 s)

7. Tap the **Iced Latte** card (or its **Customize** button).
8. In the sheet: size **Medium**, milk **Oat**, tick **Vanilla syrup**. Quantity 1.
9. Tap **Add & checkout**. You land on the cart. (Cart badge shows **1**.)

### 0:35 — Checkout (≈20 s)

10. In the coupon box type `CAMPUS10` → **Apply**. Totals update, 10 % off appears.
    Try **Apply** again: *That coupon is already applied.* (duplicate prevented).
11. Optional: tap a reward chip (**AED 5 off · 100 pts**) to show redemption.
12. Tap **Checkout**.
13. Fulfilment: **Takeaway** (already selected). Under **When?** leave **ASAP** (or show the
    scheduled slots). Flip **I'm bringing my own cup**: AED 1 off and +20 points appear.
    Payment: **Demo Card Payment — SIMULATED**. Point to the line: *No real payment is
    processed. No card numbers requested.*
14. Tap **Place Demo Order**.
15. Confirmation dialog: **Order placed!**, unique ID (e.g. `ALT-1042`), **Queue position #3**,
    **2 ahead**, total. Tap **Track my order**.

You are now on the **Orders** tab with the live (simulated) tracking card: queue position,
orders ahead, estimated wait, timeline on **Received**.

### 0:55 — Order tracking (≈10 s)

16. Tap the **sliders icon** (Demo Controls) top-right.
17. Tap **Move to Preparing**, then **Mark Ready**. Tap **Open Orders tab**.
18. A green banner reads **Your order is ready for pickup!** at the top, and the order card
    header turns green with the same message. Timeline shows **Ready**.

> Pitch line: "In production this is a push notification from the POS. Today it is an in-app
> alert driven by our demo controls, and we say so."

### 1:05 — Loyalty (≈10 s)

19. On the order card tap **Demo: mark collected** (or use Demo Controls → **Mark Collected**).
    A toast shows *+NNN points*.
20. Tap **Rewards**. Lifetime points rose from 1,240 (order points + 20 Green Cup bonus).
    Progress bar to Platinum jumped. **Weekly challenges**: *Green Cup* is now claimable; tap
    **Claim +30 points**. Scroll to **Pay it forward**, gift a Karak Chai, show the
    `GIFT-XXXX` code (optional: redeem it in the cart later for a free drink).
21. Optional: go back to Orders and show the order in **Order history** with **Reorder**.
    Tapping *mark collected* twice is impossible; points are awarded exactly once.

### 1:15 — Campus (≈10 s)

22. Tap **Campus**. Note the label *Sample events for the prototype*.
23. On **Hack Night: Build in 3 Hours** tap **Going**. Button turns green with a check and the
    card reads *Your RSVP: Going (saved on this device)*. The header counts your events.
24. Refresh the browser (F5) if you have time: nickname, order, points and RSVP all persist.

### 1:25 — Close (≈5 s)

25. Back to **Home**: the active-order card is gone, points are up, Popular Now may have
    re-ranked. Mention the **ideaForge × AIRC** credit on Home/About.

> Pitch line: "Everything you saw runs on-device today. The one interface we would swap for
> launch is the POS adapter; the UI never changes."

---

## Recovery tips

| Problem | Fix |
| --- | --- |
| Started on a used device | Demo Controls → **Reset sample data** |
| No active order to show | Demo Controls → **Generate sample active order** |
| Points look odd | Demo Controls → **Restore initial loyalty state** |
| Want the welcome panel back | Demo Controls → **Reset demo (show welcome again)** |
| Cart has leftovers | Cart → **Clear** |

## Timing summary

| Segment | Seconds |
| --- | --- |
| Launch + Home (streak, Best time to go) | 10 |
| Rush Mode | 15 |
| Product | 10 |
| Cart + Checkout | 20 |
| Tracking + Ready alert | 10 |
| Collected + Rewards | 10 |
| Campus RSVP | 10 |
| Close | 5 |
| **Total** | **≈ 90** |
