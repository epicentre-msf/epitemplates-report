# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
