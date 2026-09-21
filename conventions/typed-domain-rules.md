---
name: typed-domain-rules
applies: anything where behaviour varies by kind — scoring, prompts, validation, pricing, permissions
---

# Domain rules live in types, not in strings

**Never ask about this in the interview.** It is how the work is done.

## The failure it prevents

A fitting scorer graded hairstyles against clothing criteria — "fabric and pattern", "seams and
pockets" — and passed. The criteria were one global prompt string, so adding a new kind of cut
changed nothing, broke nothing, and was silently scored by the wrong rules. Prose has no arity:
nothing tells you a case is missing.

## The rule

**Anything that varies by kind becomes an enum plus a lookup keyed by that enum, and the lookup must
be exhaustive.** Adding a kind then fails to compile or fails a test — it cannot be forgotten.

```ts
// The kinds are a closed set, not strings passed around
export const CUT_KINDS = ['hair_front', 'hair_side', 'hair_back', 'garment_detail'] as const
export type CutKind = (typeof CUT_KINDS)[number]

type Criteria = {
  readonly preserve: readonly string[]   // what must survive from the input
  readonly judge: readonly string[]      // what is actually being scored
  readonly ignore: readonly string[]     // what this kind must NOT be penalised for
}

// Record<CutKind, …> — miss a kind and this does not compile
export const CRITERIA: Record<CutKind, Criteria> = {
  hair_front: { preserve: ['the face', 'the person'], judge: ['hairline', 'volume'], ignore: ['fabric', 'seams'] },
  ...
}
```

Then the prompt is **assembled from that data**, never written per branch:

```ts
const c = CRITERIA[kind]                      // not: if (kind.startsWith('hair')) prompt += '...'
buildScoringPrompt({ preserve: c.preserve, judge: c.judge, ignore: c.ignore })
```

## What follows from it

- **Pass the resolved rules into the call.** A scorer that reaches for a global is a scorer nobody
  can give different rules to — which is exactly how the wrong criteria stay invisible.
- **No string matching on domain words.** `kind.includes('hair')` is a lookup table with the safety
  removed. Branch on the enum.
- **One golden test per kind.** The suite should fail when a kind is added without its criteria, and
  the assertion should name what that kind must *not* be judged on.
- **Weights and thresholds are data too.** A number that differs by kind belongs in the same record,
  not in an `if` further down.
- **When the set is open-ended** (categories from a database), keep the shape: a validated record
  loaded once, with a startup check that every live kind has an entry. Prose is still not allowed.

## Smell list

Long prompt strings holding domain nouns · `if (type === …)` repeated in more than one file ·
a criteria constant imported by the thing it is supposed to configure · a new kind that needed no
other change · tests that only assert "it passed" rather than what was judged.
