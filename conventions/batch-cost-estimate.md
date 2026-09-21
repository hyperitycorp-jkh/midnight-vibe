---
name: batch-cost-estimate
applies: any run that multiplies — items × locales × variants, or any loop calling a paid model
---

# If there's a multiplication, the plan carries the number

**Never ask about this in the interview.** It is a precondition for running the job at all.

## What goes wrong

"Translate the UI strings" is a few hundred lines. "Translate the content" was 950 chapters — each one
a full body of scenes, dialogue and choices — times 19 locales. Same sentence, three orders of
magnitude apart, and the bill arrives after the run, not before it.

The multiplication is always visible in advance. Nobody looks because the command is one line.

## The rule

**Measure three, multiply, and put the number in `## Plan`.** A fan-out without an estimate is not
approvable.

```
items × locales × (input + output tokens per item) × unit price = the number
```

Measured, not guessed: run three real items, log the actual token counts, extrapolate. Guessing the
per-item size is how a 40× surprise happens — long bodies are not UI strings.

## What every bulk script has before it runs once

- **`--dry-run` as the default.** Printing what it would do, how many calls, and the estimate, is the
  normal mode. Spending money is the flag you have to pass.
- **`--limit N`.** There is no reason for the first real run to be the whole catalog.
- **Idempotent and resumable.** Hash the source and skip what hasn't changed — not just "skip if a
  translation exists", which re-pays for every edited item and never notices a stale one. A rerun
  after a crash must not pay twice.
- **A ceiling that stops the run**, not just a log line: stop at N calls or an estimated spend.
- **Per-run spend logged** where the next person will find it, so the second estimate is real.

## Scope before speed

- Translate **what users actually see**. Prompt bodies, system instructions and world settings are
  not user-visible strings — a language directive handles the output language for a fraction of it.
- **Stage the locales.** Ship the top few, look at them, then the rest. Nineteen at once is nineteen
  times whatever you got wrong.
- **Cheap model for bulk, expensive one only where the quality is visible.** Most of a catalog is not.
- A budget alert on the project **before** the run, not after the invoice — see `firebase-cost-guard`.

## Smell list

A one-line command that touches a whole collection · "it's just translation" · a loop over locales
inside a loop over documents with no counter · a script whose default mode spends money · an estimate
written as "should be cheap" · a rerun after a crash that starts from zero.
