---
name: design-flat-minimal
applies: any UI (the web kit ships these tokens in src/app/globals.css)
---

# Flat minimal

**Never ask about any of this in the interview.** New screens and components follow it by default.

## DNA

White background, black ink, 1px lines, pastel accents, one bold sans. Editorial spacing.
Dark mode is a class toggle that inverts the same tokens — never a second set of colors.

## Tokens

The kit defines these in `src/app/globals.css`. Everything references them; nothing hardcodes a color.

```css
--bg --surface --ink --muted-ink --muted --line
--accent --accent-ink --soft   /* pastel, derived from --accent-hue */
--radius        /* 20px cards, 12px small */
```

## Rules

**Color.** No arbitrary hex, ever — no `bg-[#fff]`. Use token classes (`bg-bg`, `text-ink`,
`border-line`, `bg-soft`). **One or two pastel accents per screen**, never three. Dark mode comes free
if you stay on `--ink` / `--bg`.

**Type.** One variable sans (the kit sets Pretendard; swap it once, globally, or not at all).
Hero: extrabold, tight tracking, large, and let it wrap. Body: `text-base leading-relaxed`.
Secondary: `text-sm text-muted-ink`.

**Borders and cards.** 1px solid `--line` only — no thick borders. Cards are `border border-line`
at `--radius`. Shadows are for emergencies, and then only `shadow-sm`. Default button is a white
fill with a black 1px border, fully rounded.

**Icons and illustration.** Outline icons at `strokeWidth 1.5`. Illustrations are a pastel circle
plus one symbol. Prefer type over photography.

**Interaction.** Hover goes as far as `hover:bg-muted` or `hover:border-ink`. Focus is a 2px accent
outline. Page entry is one 360ms fade-up. Nothing more.

**Layout.** Max width around `max-w-6xl mx-auto px-6`. Section rhythm `py-20`–`py-32`. Mobile first.

## Never

Gradient backgrounds. Shadows at `shadow-lg` or heavier. Primary red/blue/yellow — pastels only.
Mixing a serif in. Defining color per component instead of through tokens. Page-specific rules
dropped into global CSS.

## Checklist for a new component

- [ ] Every color through a token class
- [ ] Borders 1px `--line`
- [ ] Radius from `--radius`
- [ ] One or two pastel accents, no more
- [ ] Dark mode flips without extra work
