# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] — v2.0.0 consumer re-branding

Migration toward `brand.yml` as the canonical brand surface (see
the brand-migration plan). The headline feature: a
downstream project can now recolour the whole report — HTML,
RevealJS, and PDF — by shipping its own brand and pointing
`_quarto.yml` at it with an explicit `brand:` key, with no SCSS
knowledge (see the "Re-branding (colours)" section of the README).
The **default render is unchanged** — with no `brand:` key the
report still uses the Epicentre palette, so existing reports look
identical.

### Added
- **New `epitemplates-deck-revealjs` format** — a full-bleed
  1920×1080 RevealJS deck theme that reproduces Epicentre's bespoke
  HTML decks from pure Quarto Markdown (no hand-written HTML). Author
  a `.qmd` with `format: epitemplates-deck-revealjs` and compose
  slides from a small vocabulary:
  - **Components:** cards (`.top-accent`/`.left-accent`/`.stat`/
    `.photo`/`.delta`), chips, teal/amber callout boxes
    (`.callout-key`/`.callout-warn`), an opt-in rich `.part-divider`,
    `.deck-grid` arbitrary-column rows, dark + opt-in light code
    blocks (with a skylighting token remap, so normal fenced code
    shows deck colours), and a heatmap.
  - **Shortcodes:** `{{< eyebrow >}}`, `{{< chip >}}`, `{{< stat >}}`,
    `{{< icon >}}` (a ~31-icon Bootstrap Icons registry, MIT), and
    `{{< dots >}}`.
  - **Lua filters:** `deck-layout.lua` (grid layout + click-navigable
    agenda cards via `link="#section-id"`) and `deck-shortcodes.lua`.
  - **Self-contained output:** Inter + JetBrains Mono (both SIL OFL
    1.1) are embedded offline via `include-in-header` (`fonts-head.html`),
    so a rendered deck is a single portable HTML file with no network
    fetch at view time.
  - **Colour Tier switch:** every component reads semantic tokens in
    `css/_deck-tokens.scss`, so the whole deck re-skins from one file
    (teal/coral by default, or the Epicentre navy).
  - An authoring cheatsheet (the "Deck format" section of `README.md`)
    plus a full prose `AUTHORING.md` guide document the vocabulary. The
    existing five report formats are unaffected (the deck ships as a
    separate `epitemplates-deck` extension).
- **Consumer colour re-branding** across HTML, RevealJS, and PDF.
  Ship your own brand file and add an explicit `brand:` key to your
  `_quarto.yml`; the `color.palette` keys you set recolour
  headings, links, callouts, code surfaces, the RevealJS slide
  gradient, and the PDF — no SCSS required. Keys you omit keep the
  Epicentre default. New "Re-branding (colours)" section in
  `README.md`. (A bare auto-detected `_brand.yml` with no `brand:`
  key is intentionally shadowed by the bundled brand, so the
  default identity is stable; the override needs the explicit key.)
- `_extensions/epitemplates-report/brand.yml` — canonical brand
  definition (palette + logo slots). Mapped onto Quarto's brand
  schema (semantic `color:` block + `color.palette` extras), so
  the v1 palette has a documented brand-aware home. Declared as a
  brand contribution in `_extension.yml` (`contributes: metadata:
  project: brand: brand.yml`), so consumers who install via
  `quarto add` get the file bundled and can opt in by adding
  `brand: epitemplates-report` to their own `_quarto.yml`.
- `_extensions/epitemplates-report/scripts/inject-brand-colors.lua`
  — PDF-only Lua filter that reads the bundled `brand.yml` and
  prepends the matching `\definecolor{...}{HTML}{...}` block to
  `header-includes` (emitted before `pdf/header.tex`). This makes
  `brand.yml` the single source of the PDF palette and lets
  `pdf/header.tex` drop every hard-coded hex value (v2 Session 3).

### Changed
- **Deck brand separated from the report brand.** The deck format no
  longer borrows the report extension's palette. Two changes make the
  `epitemplates-deck` and `epitemplates-report` extensions fully
  independent:
  The deck theme now imports its **own** palette,
  `_extensions/epitemplates-deck/css/_brand.scss` (the single source of
  truth for the deck colours), instead of the cross-extension
  `@import "../../epitemplates-report/css/brand"`. A deck now renders even
  when the report extension is absent (verified), so moving, renaming, or
  uninstalling one extension never breaks the other. The deck has no
  brand.yml of its own — its look is SCSS-driven (compile-time `$deck-*`
  tokens, not runtime `var(--brand-*)`), so a brand file would have no
  effect.
- **The deck ships without a logo.** Removed the `logo:` key from the
  deck format (`_extensions/epitemplates-deck/_extension.yml`), and the
  deck brand carries no logo slot. The source decks carry no persistent
  mark and the fixed stage has no room for one. An author who wants a
  logo can still add `logo: img/…` to their own deck YAML (still guarded
  by `validate-logo.lua`). Authoring docs now tell deck authors to set
  `brand: false` so the report's project-wide brand (logo + navy) does
  not bleed into their slides.

### Fixed
- **RevealJS styling reconnected.** `css/epicentre_revealjs_style.scss`
  was orphaned — the `revealjs` format had no `theme:` key, so the
  Epicentre slide styling (green→blue slide-background gradient,
  navy headings, the `.important` box) had never been applied and
  presentations rendered as stock Quarto reveal. Added
  `theme: [default, css/epicentre_revealjs_style.scss]`. **Visual
  change:** RevealJS slides now show the Epicentre gradient design
  by default (and re-brand with a consumer's palette).
- HTML title banner spans the full page width again. v1.0.0 had
  dropped `title-block-banner: true`, which shrank the banner to
  the content column (the logo/title no longer ran edge-to-edge as
  in the original design). Restored `title-block-banner: true` in
  the html format defaults; it coexists cleanly with the custom
  `partials/title-block.html` (logo flush-left, title centred, TOC
  below).

### Changed
- `_extensions/epitemplates-report/css/epicentre_qmd_style.scss`
  and `.../css/epicentre_revealjs_style.scss`: every colour rule
  now reads a `--brand-*` CSS custom property (emitted from
  `brand.yml`'s `palette:` block) instead of a hard-coded `$col-*`
  value, so a consumer brand recolours the visible surfaces.
  `scss:defaults` is unchanged (CSS custom properties cannot be
  assigned to colour-typed SCSS variables there), so the default
  render is identical. Added override rules for the
  Quarto/Bootstrap-generated surfaces (inline-code background,
  `div.sourceCode`, right-hand TOC active/hover, navbar) and a
  `.reveal h1–h4` heading rule so those re-brand too.
- `_extensions/epitemplates-report/scripts/inject-brand-colors.lua`
  now reads the bundled `brand.yml` as a BASE and overlays the
  consuming project's brand (resolved from `meta.brand` — a single
  path, a list, or an inline map; later wins) before emitting the
  `\definecolor` block, so the PDF re-brands with the consumer's
  palette. Keys the consumer omits fall back to the bundled value.
  The `quarto-callout-*` colour overrides are emitted inside
  `\AtBeginDocument{…}` so they run after Quarto's own callout-colour
  block (which is in the preamble) and therefore win — the PDF
  `.callout-note/-important/-tip/-caution/-warning` boxes now carry
  the brand palette (matching HTML) instead of Quarto's defaults.
- `_extensions/epitemplates-report/pdf/header.tex`: the PDF now
  paints its brand. `\addtokomafont{disposition}{\color{primary}}`
  colours the title, subtitle, every section heading and the TOC
  with the brand primary; `\hypersetup{linkcolor=primary,…}`
  (deferred via `\AtBeginDocument`) colours hyperlinks. **Visual
  change:** PDF headings/title/links are the brand colour (navy by
  default) instead of black/blue, and re-brand with a consumer's
  palette. Known gap (unchanged from before): the `:::{.important}`
  / `:::{.hint}` custom divs still render as plain text in PDF (no
  div→environment mapping); use the standard `.callout-*` boxes,
  which are now brand-coloured.
- `_extensions/epitemplates-report/_extension.yml`:
  `quarto-required: ">=1.4.0"` → `">=1.8.24"` (first stable Quarto
  release with brand-extension support; brand.yml itself shipped
  in 1.6, the brand-extension *type* in 1.8.24). New top-level
  `contributes: metadata: project: brand: brand.yml` block
  declares this extension as a brand provider. The pdf format's
  `filters:` now includes `scripts/inject-brand-colors.lua`.
- `_extensions/epitemplates-report/pdf/header.tex`: the two
  `\definecolor` blocks (palette + `quarto-callout-*`) are gone;
  every hex value now comes from `brand.yml` via
  `inject-brand-colors.lua`. The file keeps only the box /
  environment / logo machinery, which references the injected
  colour names. No hex is duplicated in LaTeX any more (v2
  Session 3).
- `_extensions/epitemplates-report/css/_brand.scss` is still the
  wired source-of-truth for the HTML / RevealJS SCSS layer (the
  SCSS palette stays there because Quarto's brand SCSS layer does
  not yet expose `$brand-*` in `scss:defaults`). `brand.yml` and
  `css/_brand.scss` must be edited in lockstep until that layer
  matures (deferred to a later session); `pdf/header.tex` is no
  longer part of that lockstep.

## [1.0.0] — First stable version (Authoring + Claude code)

First stable release of the `epitemplates-report` Quarto template,
distributing five branded output formats (HTML, PDF, DOCX, PPTX,
RevealJS) for Epicentre / EpiDS reports.

### Added
- MIT `LICENSE`.
- `CHANGELOG.md`.
- Logo-validation Lua filter
  (`_extensions/epitemplates-report/scripts/validate-logo.lua`)
  wired into html, revealjs, and pdf. `logo:` / `logo2:` must be
  local file paths; URL schemes (`javascript:`, `data:`, `http:`,
  `file:`, …) are rejected. `pdf-logo-width:` must be a LaTeX
  dimension. Values that arrive as Pandoc `RawInline (tex)` /
  `RawInline (html)` — the standard LaTeX/HTML injection bypass
  — are rejected outright before they reach the rendered output.
- `referrerpolicy="no-referrer"` on the two header `<img>` tags
  in `partials/title-block.html`, so a maliciously-pointed
  external `logo:` cannot leak the report's URL to the host it
  references.
- Branded Quarto callout colours in `pdf/header.tex`
  (`\definecolor{quarto-callout-note-color}` and the four other
  flavours), so PDF callouts pick up the same primary / yellow /
  red / green palette as the HTML SCSS.
- "Available formats", "Requirements", and "Logo paths" sections in
  `README.md`.
- GitHub Actions workflow (`.github/workflows/render.yml`) that renders
  `template.qmd` in all five formats on every push and pull request.
- `*.icloud` and `.Rhistory` entries in `.gitignore`.
- Binary-file declarations in `.gitattributes` (`*.png`, `*.docx`,
  `*.pptx`, `*.pdf`, `*.rda`, `*.rds`, etc.).

### Changed
- Revealjs `logo:` now points at the bundled
  `img/epicentre_msf_logo_transparent.png` (was the nonexistent
  `img/epicentre_logo.png`).
- `.quartoignore` reordered and de-typoed (`DESCRPTION` and `LICENCE`
  entries removed; `LICENSE`, `CHANGELOG.md`, `README.md`,
  `.gitattributes` added so the dev metadata does not ship to
  consumers via `quarto use template`).
- HTML title-block: dropped `title-block-banner: true` from the
  format defaults. The custom `partials/title-block.html` is now
  the sole source of the title-block layout — no more banner /
  partial overlap.
- **Breaking:** HTML primary logo is now `logo:` instead of
  `logo1:`, matching the YAML key RevealJS already uses (Quarto
  built-in). A single `logo:` value now works across HTML and
  RevealJS. The secondary right-side HTML logo stays `logo2:`.
  Consumers using `logo1:` need to rename it to `logo:`.
- PDF page-header logo now also reads the top-level `logo:` YAML
  key (via the new
  `_extensions/epitemplates-report/scripts/inject-pdf-logo.lua`
  filter), so a single `logo:` covers all three formats. An
  optional `pdf-logo-width:` key controls the width (default
  `5cm`). The original `\def\pdflogo` / `\def\pdflogowidth` in
  `header-includes:` continues to work for advanced overrides.
- PDF format now pins `documentclass: scrartcl` so the bundled
  `\usepackage{scrlayer-scrpage}` in `pdf/header.tex` always has
  a matching KOMA-Script class. Setting `documentclass: article`
  used to break the build with an obscure LaTeX error.
- PDF format: page-header logo is now overridable. The bundled
  default lives behind `\providecommand{\pdflogo}` /
  `\providecommand{\pdflogowidth}` in `pdf/header.tex`, so
  consumers override via `header-includes:` (see README).
- SCSS palette now lives in a single
  `_extensions/epitemplates-report/css/_brand.scss` partial,
  imported (`@import "brand";`) by both
  `epicentre_qmd_style.scss` and `epicentre_revealjs_style.scss`.
  Brand-refresh = edit `_brand.scss` only.
- SCSS cleanup in `_extensions/epitemplates-report/css/`:
  - `$sidebar-item-color` now points at `$col-primary` (was a
    leftover debug `red`).
  - Removed the deprecated global `darken()` call; subtitle colour
    is now exposed as `$col-subtitle: #464646` (precomputed
    equivalent), so no more Dart Sass deprecation warnings.
  - Extracted magic numbers in the title block, banner, and
    hyperlink-underline animation into named SCSS variables
    (`$title-block-font-size`, `$banner-logo-size`,
    `$banner-padding-x`, `$link-underline-*`).
  - Revealjs slide-background gradient stops moved out of the rule
    into `$col-bg-gradient-start` / `$col-bg-gradient-end`
    variables (visual unchanged).
  - The `.important` callout selector is now scoped to
    `.reveal .important` to avoid colliding with Bootstrap /
    other themes' `.important` rules.
  - Variable declarations normalised: no spaces before colons,
    consistent 2-space indentation throughout.

### Fixed
- `README.md` typos: `mutiple` → `multiple`, `.img/` → `img/`, and
  alt-text `word screenshot` → `powerpoint screenshot` / `revealjs
  screenshot` on the pptx and revealjs entries.
- `template.qmd` value-box chunks now guard on
  `knitr::is_html_output()` so PDF / DOCX / PPTX builds no longer
  fail with "Functions that produce HTML output found in document
  targeting pdf output". Value boxes still render in HTML and
  RevealJS; non-HTML formats cleanly omit them.

### Removed
- Revealjs `title-slide-attributes:` block (referenced the nonexistent
  `img/title-bg.png`).
- Committed iCloud placeholder `img/.title-bg.png.icloud`.
- Tracked `.Rhistory` (now gitignored).
- Duplicate `.reveal .slide-background-content` rule from
  `epicentre_qmd_style.scss` (kept only in the revealjs SCSS where
  it actually applies).
- `.quarto-title-block .quarto-title-banner` SCSS rule (its job was
  to patch the layout overlap caused by `title-block-banner: true`
  coexisting with the custom partial; both gone).
