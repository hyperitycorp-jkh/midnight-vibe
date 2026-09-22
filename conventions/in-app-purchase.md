---
name: in-app-purchase
applies: any app that sells App Store / Google Play in-app purchases or subscriptions
---

# In-app purchases — the server credits first, then the store is told

**Never ask about this in the interview.** A bug here charges people for nothing. Review every
purchase path against this list; one miss is a rejection.

- **Nothing is consumed, acknowledged or finished before the backend has validated and credited it.**
  Flutter: `buyConsumable(autoConsume: Platform.isIOS)` — Play's default `true` consumes the token
  before your server sees it, and a failed validation then loses the purchase for good.
- **Android: consume a validated consumable, complete everything else** — within 3 days, or Play refunds.
- **Android re-syncs on launch** (`restorePurchases` → validate what comes back, silently). Play neither
  replays failed validations nor delivers renewals to the app; skip this and subscriptions stop after
  one period. Not on iOS: StoreKit replays by itself and a restore can prompt for the Apple ID.
- **iOS: finish a transaction the server rejects for good** (invalid receipt, expired, wrong account);
  keep it pending on transient errors. Unfinished transactions replay on every launch.
- **One active subscription at a time.** Switch plans with `changeSubscriptionParam` or hide the other
  plan while one is active — separate products otherwise bill twice on Play.
- **Server:** idempotent on the store order / transaction id; App Store receipt 21007 → retry against
  sandbox (App Review buys in sandbox); the *primary* shared secret, not one app's; the runtime Play
  service account has View-financial-data access to every package it validates.
- **One shared policy module per repo** — every app imports it. A second hand-written billing path is
  how these rules get lost; the review asks where the shared one is.

Test the rules as pure functions (no billing channel) and the cubit/store glue with a fake repository:
consume-after-credit, silent launch re-sync, user restore still reported, final vs transient rejection.
