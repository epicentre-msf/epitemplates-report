# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] — Unreleased

First stable release of the `epitemplates-report` Quarto template,
distributing five branded output formats (HTML, PDF, DOCX, PPTX,
RevealJS) for Epicentre / EpiDS reports.

### Added
- MIT `LICENSE`.
- `CHANGELOG.md`.
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

### Fixed
- `README.md` typos: `mutiple` → `multiple`, `.img/` → `img/`, and
  alt-text `word screenshot` → `powerpoint screenshot` / `revealjs
  screenshot` on the pptx and revealjs entries.

### Removed
- Revealjs `title-slide-attributes:` block (referenced the nonexistent
  `img/title-bg.png`).
- Committed iCloud placeholder `img/.title-bg.png.icloud`.
- Tracked `.Rhistory` (now gitignored).
