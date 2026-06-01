# Deck authoring guide

A companion to the **Deck format** section of the [README](README.md). The
README has the quick cheatsheet — the six block classes and five shortcodes you
reach for most. This guide goes one level deeper: the richer components, a
couple of slide-authoring gotchas worth knowing before you write a long deck,
and the full vocabulary a deck is built from.

Everything here renders from plain Quarto Markdown with
`format: epitemplates-deck-revealjs` — no raw HTML required.

Add `brand: false` to your deck's front matter. The deck carries its own brand
(teal/coral, no logo) and styles itself; `brand: false` stops the co-shipped
report extension's project-wide brand from bleeding in and recolouring your
slides navy (or injecting the report logo).

---

## A gotcha to know first: don't start a card with a heading

Reveal turns every `##` into a new slide, and Quarto extends that to any
heading it finds at the *start* of a block. So a card whose first line is a
`###` heading gets promoted into its own empty slide — you end up one slide
heavier than you wrote, with a stray blank section.

```markdown
::: {.card .left-accent}
### This heading splits the card into a phantom slide   <!-- avoid -->
Some supporting copy.
:::
```

Start cards with a *non-heading* instead — a tag, a kicker, a chip, or bold
text. That keeps the card headline inside the card, so it reads the way you
wrote it:

```markdown
::: {.card .left-accent}
[Layer 1 · The library]{.tag}
**Every record, parsed and cleaned up**
Some supporting copy.
:::
```

If your slide counter reads one higher than the number of `##` you wrote, a
heading-led card is almost always the cause.

---

## Part dividers

A richer section break than the plain `{.divider}` — a full part page: a giant
gold numeral on the left, a gold title and lede on the right, a "Part N of M"
kicker, and a tracker rail along the bottom that shows which part you are
entering.

```markdown
## Global overview. {.divider .part-divider data-num="01"}

{{< eyebrow "Part 1 of 3" >}}

The big picture — how the pieces fit together, and why.

:::: part-tracker
::: {.part .active}
[PART 01]{.num} Global overview
:::
::: part
[PART 02]{.num} The tech stack
:::
::: part
[PART 03]{.num} The dashboard
:::
::::
```

- `data-num="01"` on the heading draws the 260px numeral — pass `01`, `02`, …
- The `{{< eyebrow >}}` right after the heading becomes the top-left kicker.
- `:::: part-tracker` (four colons) wraps three `::: part` items (three
  colons). Mark the current one `{.part .active}` — it shows gold; the others
  fade back.
- In each item, `[PART 0N]{.num}` is the mono label and the trailing text is
  the part name.

The slide keeps the full-bleed teal background and the Tier switch, so it
recolours with the rest of the deck. A plain `## Heading {.divider}` still
gives you the simple section break when you don't need the part scaffolding.

---

## Callout boxes

Two tinted boxes for the "read this" moments — a teal **key point** and an
amber **warning**. Author them as fenced divs; an optional `{{< eyebrow >}}`
inside becomes the box's label.

```markdown
::: {.callout-key}
The same six steps run for every document, end to end, from a single command.
:::

::: {.callout-warn}
{{< eyebrow "Watch out" >}}
A document that fails the metadata check is held back, not silently dropped.
:::
```

`.callout-key` reads teal on a pale teal tint; `.callout-warn` reads amber on a
pale amber tint. Use them sparingly — they earn attention by being rare.

---

## Before → after delta

A compact stat card for showing a number moving. It is a `.card` with the
`.delta` modifier and three inline spans:

```markdown
::: {.card .left-accent .delta}
[Total elements]{.label}
[1,240]{.from} [→]{.arrow} [310]{.to}
:::
```

`.label` is the muted caption, `.from` is the old value (muted), `.to` is the
new value (teal, bold), and `.arrow` is the coral connector.

---

## Light code blocks

Code blocks render on the deck's dark surface by default. When you want a
light, paper-toned block instead — for a short snippet on an already-busy
slide — add `.light` to the fence:

````markdown
```{.r .light}
con <- dbConnect(duckdb(), "analysis.duckdb")
```
````

The `.light` class lands on the block and swaps in a cream surface with the
light syntax hues. Everything else about code authoring is unchanged: you write
a normal fenced block and the theme colours the tokens — never hand-tag spans.

---

## The `.mono` helper

Wrap any inline text in `[…]{.mono}` to render it in JetBrains Mono — handy for
file names, short code-ish fragments, or any monospace flourish you want inside
a callout.

```markdown
[data/clean.duckdb]{.mono}
```

---

## Linking between slides (agenda cards)

Any `.card` can be made click-navigable by adding `link="#target"` — handy for an
agenda slide whose cards jump to the section they introduce:

```markdown
## What this update covers.

{{< eyebrow "Agenda" >}}

:::{.cards}
:::{.card .top-accent link="#sec-pipeline"}
[01]{.kicker}

### The ingestion pipeline

The six steps every PDF goes through.
:::
:::
```

**Link to a section by its `id`, not its slide number.** Give the target slide a
stable id in its heading, then point the card at it:

```markdown
## What every PDF goes through. {#sec-pipeline}
```

- `link="#sec-pipeline"` survives adding, removing, or reordering slides.
- `link="#/5"` (a slide number) breaks the moment any earlier slide is inserted —
  adding one agenda slide shifts every index after it.
- The slide's **auto-generated** id (a slug of the heading text, trailing
  punctuation and all — e.g. `what-every-pdf-goes-through.`) also breaks the day
  you reword the title. An explicit `{#sec-…}` is rewording-proof.

A divider takes the id alongside its other attributes:
`## The worst case. {#sec-detail .divider data-state="divider"}`.

---

## Changing the colors

You never set a color in your slides — every component reads a small set of
**semantic tokens**, so re-coloring the whole deck is a one-file edit. The tokens
live in
[`_extensions/epitemplates-deck/css/_deck-tokens.scss`](_extensions/epitemplates-deck/css/_deck-tokens.scss).

### The two you reach for most

```scss
/* Tier A — deck-faithful (DEFAULT) */
$deck-primary: $deck-teal-700;   // headings accent, card top rule, footer dot,
                                 //   divider/title background, key callout, links
$deck-accent:  $deck-coral-500;  // card left rule, chip accent, code keywords,
                                 //   the "→" in a delta
```

Change `$deck-primary` and the entire deck re-skins — titles, dividers, cards,
callouts, code, the footer counter — because every rule downstream reads that one
name. `$deck-accent` is the secondary highlight. Use a palette name (e.g.
`$col-primary`, `$deck-teal-500`) or a plain hex (`#0E7A7A`).

### The special-slide gold

Divider and title pages use a separate accent — the gold on divider titles and
the divider rules:

```scss
$deck-divider-accent: #fcd34d;   // flip to e.g. $deck-accent for a coral identity
```

### Callout tints

```scss
$deck-key-bg:   $deck-teal-100;  // teal "key point" box fill
$deck-key-line: $deck-primary;   //   …and its left rule
$deck-warn-bg:  #fef3c7;         // amber "warning" box fill
$deck-warn-line:#f59e0b;         //   …and its left rule
```

### Switch to the Epicentre brand palette (Tier B)

To ride the Epicentre navy instead of the deck teal, comment the two Tier-A lines
and uncomment the Tier-B block at the foot of the same file:

```scss
// $deck-primary: $deck-teal-700;   ← comment these
// $deck-accent:  $deck-coral-500;
$deck-primary: $col-primary;        ← uncomment these
$deck-accent:  $deck-coral-500;
```

The raw palette those names resolve to (`$deck-teal-*`, `$deck-coral-*`,
`$col-primary`) lives in the deck's own
`_extensions/epitemplates-deck/css/_brand.scss` — the single source of truth
for the deck colours; edit there for a deck-wide change. The deck has its
**own** palette, fully independent of the report's
(`_extensions/epitemplates-report/css/_brand.scss`); changing one never touches
the other.

> After any token change, re-render the deck (`quarto render … --to
> epitemplates-deck-revealjs`) — SCSS is compiled at render time.

---

## Where to look next

- The README's **Deck format** section — the quick cheatsheet and the
  colour Tier switch.
- `_extensions/epitemplates-deck/css/epicentre_deck_style.scss` — the theme,
  where every class above is defined and commented.
- `_extensions/epitemplates-deck/scripts/` — the Lua filters behind the
  `.deck-grid` layout and the `{{< … >}}` shortcodes.
</content>
