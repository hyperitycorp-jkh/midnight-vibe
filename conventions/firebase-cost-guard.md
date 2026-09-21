---
name: firebase-cost-guard
applies: any Firebase / Google Cloud project — set this up before the first deploy, not after the bill
---

# Firebase — the bill is a design constraint

**Never ask about this in the interview.** A new project gets these before anything ships.

## Two projects, always

Dev and prod are separate projects. Never one project with a `dev` collection prefix — a runaway loop
in dev then bills production, and a rules mistake exposes real user data.

## Dev: stay cheap, and cap what you can't

Stay on the free tier where the work allows it. Cloud Functions force Blaze, and from that moment the
project can bill without limit, so a dev project on Blaze gets a kill switch:

**A budget alert does not cap spending.** It sends mail while the meter runs. The only thing that
actually stops it is removing billing:

```
Budget (Cloud Billing) → Pub/Sub topic → Cloud Function → projects.updateBillingInfo
                                                          with an empty billingAccountName
```

That function detaches the billing account when the budget is exceeded. It breaks the project on
purpose — that is the entire point, and it is the right trade for a dev project. Set the dev budget
to what a surprise may cost, not to what you expect to spend.

## Prod: bound the blast radius with billing on

Prod can't be killed by a switch, so nothing may be unbounded in the first place.

- **`maxInstances` on every function, explicitly.** One function that scales without a ceiling is the
  most common way a Firebase bill becomes a story. Size memory and timeout down while you're there.
- **No self-retriggering writes.** A Firestore trigger that writes into the collection it watches is
  an infinite loop with a price tag. If a trigger writes near its own path, prove the guard.
- **Rules deny by default.** An unauthenticated write path is someone else's bill, and they will find it.
- **App Check enforced**, not monitoring — that's what makes abuse from outside your apps stop being
  billable in the first place.
- **Budget alerts at 50 / 90 / 100%** that reach a human who is awake, not just a project-owner inbox.
- **Storage lifecycle rules** for temp uploads, and resize on write rather than on every read.
- **Paid AI and third-party calls get a hard per-user daily cap in code.** A prompt is not a limit.

## Keys

The Firebase web key is public by design, so restriction is the whole defence.

- **Browser keys: HTTP referrer restrictions** to your domains, plus **API restrictions** to the APIs
  actually used. Mobile keys restricted per app (package name / bundle id and signature).
- **One key per surface.** One key with every API enabled means one leak opens everything.
- **Never a service-account key in the repo** — prefer ADC or workload identity. Some organizations
  block creating them at all, which is a feature.
- Rotating a key means nothing if the new one is unrestricted.

## Before the first deploy

- [ ] dev and prod are separate projects
- [ ] dev budget + kill-switch function, tested by forcing the alert once
- [ ] prod budget alerts reaching a person
- [ ] `maxInstances` set on every function
- [ ] rules deny by default, App Check enforced
- [ ] browser key restricted by referrer and API; mobile keys restricted per app
- [ ] no service-account key anywhere in the repo
