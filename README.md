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

- **Quarto** ≥ 1.4.0
- **LaTeX** with a KOMA-Script document class (for the `pdf` format —
  Quarto's default `scrartcl` satisfies this; setting
  `documentclass: article` will not work because the bundled header loads
  `scrlayer-scrpage`)
- **R packages** used by the demo `template.qmd`:
  - `bslib`, `bsicons`, `scales` — required for the value-box showcase
  - `tidyverse`, `rio`, `janitor`, `fs`, `here`, `lubridate` — optional,
    only needed if you adapt the demo data-processing chunks

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
