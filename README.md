# epitemplates-report

EpiDS templates for quarto documents and presentations in multiple formats.

## Installation and usage

This project is distributed as a **Quarto template**, not a standalone extension.

It includes a complete project scaffold (e.g. `img/`, template file, etc.),
which **cannot be installed via `quarto add`**.

To create a new report using this template:

```bash
quarto use template epicentre-msf/epitemplates-report
```

And add the format to your YAML configuration, along with other HTML format options if needed:

```yaml
format:
    epitemplates-report-html:
        toc: true
        toc-depth: 3
        logo: img/epicentre_msf_logo_transparent.png # top left of header
        logo2: img/another_logo.png # top right of header
```

Alternatively, you can also use the [epitemplates](https://github.com/epicentre-msf/epitemplates) R package from within R/Rstudio.
The template provides different formats, presented below.

## Available formats

The extension exposes five Quarto formats. Use any of these names under the
`format:` key in your document's YAML front matter:

- `epitemplates-report-html` — HTML report (recommended working format)
- `epitemplates-report-pdf` — PDF via LaTeX (KOMA-Script)
- `epitemplates-report-docx` — Microsoft Word document
- `epitemplates-report-pptx` — PowerPoint presentation
- `epitemplates-report-revealjs` — Browser-based reveal.js presentation

## Requirements

- **Quarto** ≥ 1.8.24 (the colour re-branding below was verified on
  1.9.37; brand support landed in 1.6 and the brand-extension type
  in 1.8.24)
- **LaTeX** with a KOMA-Script document class (for the `pdf` format —
  Quarto's default `scrartcl` satisfies this; setting
  `documentclass: article` will not work because the bundled header loads
  `scrlayer-scrpage`)
- **R packages** used by the demo `template.qmd`:
  - `bslib`, `bsicons`, `scales` — required for the value-box showcase
  - `tidyverse`, `rio`, `janitor`, `fs`, `here`, `lubridate` — optional,
    only needed if you adapt the demo data-processing chunks

## Re-branding (colours)

By default your report uses the Epicentre / EpiDS palette. To
recolour the whole thing — headings, links, callouts, code blocks,
the RevealJS slide gradient, and the PDF — you ship your own
**brand file** and point your project at it. No SCSS, and the same
file drives HTML, RevealJS, and PDF.

1. Create a `brand.yml` (or any name) in your project with the
   colours you want to change, under `color.palette`:

   ```yaml
   # brand.yml
   color:
     palette:
       primary: "#B5179E"        # headings, links, callout-note, TOC
       primary-light: "#F6D6F0"  # inline-code background
       secondary: "#119DA4"      # subtitle, muted text
       secondary-bg: "#FBEFF9"   # code-block / navbar background
       danger: "#7A0C2E"         # callout-important border
       red-sec: "#FBE0F4"        # callout-important background
       warning: "#E07A00"        # callout-caution border
       yellow-sec: "#FBF0D6"     # callout-caution background
       success: "#0B7A4B"        # callout-tip border
       green-sec: "#D6F6E6"      # callout-tip background
       subtitle: "#222222"       # subtitle text
       bg-gradient-start: "#FF8800" # RevealJS slide gradient
       bg-gradient-end: "#8800FF"
   ```

2. Point your `_quarto.yml` at it with an **explicit** `brand:`
   key:

   ```yaml
   # _quarto.yml
   project:
     type: default
   brand: brand.yml
   ```

That's it — re-render and your colours flow through every format.

Notes:

- You only list the keys you want to change; anything you omit
  keeps the Epicentre default.
- The `brand:` key must be **explicit**. A bare auto-detected
  `_brand.yml` (with no `brand:` key) is shadowed by the template's
  own bundled brand, so the override would silently do nothing.
- The default render (no `brand:` key) is unchanged from before —
  this is purely additive.

## Logo overrides

Every format gives you a way to swap the bundled Epicentre / EpiDS
logos for your own. Paths are always resolved **relative to your
project's root**, so by convention you keep them in an `img/`
folder:

```
your-project/
├── _quarto.yml          # or your .qmd directly
├── report.qmd
└── img/
    ├── epicentre_msf_logo_transparent.png   # bundled default
    └── partner_logo.png                     # your override
```

### HTML and RevealJS — `logo` (+ `logo2` for HTML only)

Both HTML and RevealJS read the same `logo:` YAML key (RevealJS via
Quarto's built-in field; HTML via the custom title-block partial),
so a single value works across both formats. The HTML format also
accepts an optional second logo `logo2:` for the top-right corner
of the header.

- `logo`  — primary logo (HTML: top-left of the header; RevealJS:
  slide overlay, per Quarto's default behaviour)
- `logo2` — secondary logo, top-right of the HTML header
  (HTML only; ignored by RevealJS)

```yaml
format:
  epitemplates-report-html:
    logo: img/epicentre_msf_logo_transparent.png
    logo2: img/partner_logo.png
  epitemplates-report-revealjs:
    logo: img/epicentre_msf_logo_transparent.png
```

The bundled default for `logo` is
`img/epicentre_msf_logo_transparent.png` in both formats; `logo2`
is unset by default.

### PDF — same `logo:`, optional `pdf-logo-width:`

The PDF format reads the same top-level `logo:` YAML key as HTML and
RevealJS, so a single `logo:` value covers all three. Behind the
scenes a small Lua filter (`scripts/inject-pdf-logo.lua`, bundled
with the extension) picks up your `logo:` value and injects
`\def\pdflogo{...}` into the LaTeX preamble before
`pdf/header.tex` runs its `\providecommand` defaults — so your
value wins. The page-header logo width defaults to `5cm`; override
it with the optional `pdf-logo-width:` key:

```yaml
logo: img/partner_logo.png
pdf-logo-width: 4cm  # optional, default 5cm

format:
  epitemplates-report-pdf: default
```

If you'd rather skip the YAML key, the original macro-override
pattern still works for advanced users:

```yaml
format:
  epitemplates-report-pdf:
    header-includes:
      - \def\pdflogo{img/partner_logo.png}
      - \def\pdflogowidth{4cm}
```

## Security

The template treats your YAML front matter as trusted input — but
the few values that flow directly into rendered HTML or LaTeX are
validated before they reach the output:

- `logo:` / `logo2:` must be local file paths. URL schemes
  (`javascript:`, `data:`, `http://`, `file://`, …) are blocked
  by `scripts/validate-logo.lua` so a malicious value cannot
  inject script tags into the HTML `<img src>` or escape the
  `\def\pdflogo{...}` macro.
- `pdf-logo-width:` must be a LaTeX dimension (`<number><unit>`,
  e.g. `5cm`); anything else is rejected.
- The HTML title-block sets `referrerpolicy="no-referrer"` on
  the logo `<img>` tags as a defence-in-depth measure.
- The PDF format pins `documentclass: scrartcl` so the bundled
  `\usepackage{scrlayer-scrpage}` always has a matching
  KOMA-Script class. If you need a different document class, swap
  the package in your own `header-includes:`.

If you render a report from untrusted input (e.g. a `.qmd` you
received from outside your team), treat the embedded YAML as code
you are about to run — these checks reduce the blast radius but
do not replace reading what you are about to render.

## Formats

<div align="center">

**`epitemplates-report-html`: html document**

![html screenshot](screenshots/html_document.png)

**`epitemplates-report-pdf`: pdf document**

![pdf screenshot](screenshots/pdf_document.png)

**`epitemplates-report-docx`: word document**

![word screenshot](screenshots/docx_document.png)

**`epitemplates-report-pptx`: powerpoint presentation**

![powerpoint screenshot](screenshots/pptx_presentation.png)

**`epitemplates-report-revealjs`: revealjs presentation**

![revealjs screenshot](screenshots/revealjs_presentation.png)
</div>

## Deck format

Alongside the five report formats, this repo ships a separate, slide-first
RevealJS format for **decks**: `epitemplates-deck-revealjs`. It renders on a
fixed, full-bleed 1920×1080 stage with a teal/coral palette, dark code blocks,
and offline-embedded Inter + JetBrains Mono fonts — so you write plain Quarto
Markdown and get a designed deck, no per-slide CSS.

Select it the same way you select any format:

```yaml
title: "My deck"
subtitle: "A short standfirst"
author: "You"
format:
  epitemplates-deck-revealjs: default
footer: "Part 1 · Global overview"
brand: false
```

The deck has its **own** brand (teal/coral, no logo), fully separate from the
report's. Add `brand: false` to every deck: it tells Quarto not to apply the
report's project-wide brand — which would otherwise tint your slides navy and
inject the report logo. The deck ships **without** a logo by design; if you want
a mark on your slides, add `logo: img/your_logo.png`.

A worked deck exercising every component lives in
`component-gallery.qmd`.

### Authoring cheatsheet

You compose slides from a small vocabulary — about six classes plus five
shortcodes. Everything else is ordinary Markdown (headings, bold/italic,
links, fenced code, native columns).

> For the richer components — part dividers, callout boxes, before→after
> deltas, light code blocks — and the slide-authoring gotchas worth knowing
> before a long deck, see the full
> [deck authoring guide](AUTHORING.md).

**Slide kinds**

- A normal `## Heading` is your slide title (styled automatically).
- `## Heading {.divider}` is a full-bleed teal section break.
- The title slide is built from the YAML `title` / `subtitle`.

**Block classes** (fenced divs, `:::{.class}` … `:::`)

| Class | What it gives you |
|---|---|
| `.cards` | a responsive 3-up grid wrapping `.card`s |
| `.card` | a white surface card; add `.top-accent` (teal top border), `.left-accent` (coral left border), or a `[01]{.tag}` corner tag |
| `.card .stat` | a stat card — pass `value=` `label=` `icon=` and the inner `.big` / `.kicker` / `.viz` are built for you |
| `.card .photo` | a media banner (`.media` with a `background-image`) over a `.body` |
| `.deck-grid cols="260px 380px 1fr 80px"` | the signature multi-column card row — `cols` becomes a real CSS grid |
| `.heatmap` | a coverage matrix from `.th.row` / `.th.col` / `.cell` (use `data-v="0"` for empty cells) |

**Shortcodes** (inline/atomic)

| Shortcode | Renders |
|---|---|
| `{{< eyebrow "How it fits" >}}` | the mono uppercase kicker above a title |
| `{{< chip "DuckDB" >}}` | an outlined pill — add `solid` (filled teal) or `accent` (coral) |
| `{{< stat value="120k" label="Enrolments" icon=people accent >}}` | a stat card with the icon drawn |
| `{{< icon graph-up >}}` | an inline icon (Bootstrap Icons, offline, tinted by surrounding text colour) |
| `{{< dots >}}` | the decorative title-scatter SVG |

Split slides use native Quarto columns:

````markdown
:::: {.columns}
::: {.column width="55%"}
…left card(s)…
:::
::: {.column width="45%"}
```r
library(duckdb)            # syntax-coloured by the theme, no hand-tokenizing
con <- dbConnect(duckdb(), "analysis.duckdb")
```
:::
::::
````

### Tier switch — colours

The deck ships **deck-faithful** (teal `#0E7A7A` + coral `#F06E58`) by default.
To recolour it to the Epicentre navy brand instead, flip a single line in
`_extensions/epitemplates-deck/css/_deck-tokens.scss`:

```scss
$deck-primary: $deck-teal-700;  // default (deck-faithful)
// $deck-primary: $col-primary;  // brand-aligned (Epicentre navy)
```

Every component reads `$deck-primary` / `$deck-accent`, so the whole deck
re-skins from that one change — coral stays the accent in both.
