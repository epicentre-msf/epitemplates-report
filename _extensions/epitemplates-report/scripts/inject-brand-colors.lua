--[[
inject-brand-colors.lua

Single source of truth for the PDF palette. Emits the
`\definecolor{...}{HTML}{...}` block that pdf/header.tex used to
hard-code, sourcing every hex value from brand.yml instead. This
removes the duplicated palette that previously lived in
pdf/header.tex (v2 Session 3 of the brand-migration plan).

Colour resolution (v2 Session 4 — consumer rebrand):
  1. The extension's bundled brand.yml is read from disk (relative
     to this script) and used as the BASE palette — this is the
     default Epicentre identity.
  2. If the consuming project activates its own brand (an explicit
     `brand:` key in its `_quarto.yml`), that brand is read too and
     OVERLAID on the base, so a consumer recolours the PDF without
     editing this extension. The consumer's brand file path is
     taken from `meta.brand` (Quarto exposes the `brand:` value to
     filters even though `quarto.brand.get_color` asserts on
     1.9.37); the file is read relative to the render working
     directory. Inline `brand:` maps are honoured directly. When a
     consumer omits a key, the bundled value is kept.

The resolved `\definecolor` lines are prepended to
`header-includes`, which Quarto emits BEFORE `include-in-header`
files, so the colours are defined before pdf/header.tex's
`\newmdenv` / `\newenvironment` / callout machinery reads them.

Format scope: registered only under the pdf format in
_extension.yml, so it never runs for html or revealjs builds
(those consume the palette through css/_brand.scss instead).
]]

-- LaTeX colour name -> brand colour key. The brand key is looked
-- up first in a brand's semantic `color:` block, then in its
-- `color.palette:` extras. These names mirror exactly what
-- pdf/header.tex defined before the migration; do not drop any
-- without checking that no document references the colour.
local COLOR_MAP = {
  { latex = "primary", key = "primary" },
  { latex = "primarylight", key = "primary-light" },
  { latex = "primarylightinline", key = "primary-light" },
  { latex = "secondary", key = "secondary" },
  { latex = "secondarybg", key = "secondary-bg" },
  { latex = "darkgrey", key = "dark-grey" },
  { latex = "lightgrey", key = "light" },
  { latex = "impredprim", key = "danger" },
  { latex = "impredsec", key = "red-sec" },
  -- Quarto's LaTeX callout template references these colour names.
  -- If a future Quarto release renames them the \definecolor lines
  -- become inert (no error) and callouts fall back to defaults.
  { latex = "quarto-callout-note-color", key = "primary" },
  { latex = "quarto-callout-note-color-frame", key = "primary" },
  { latex = "quarto-callout-caution-color", key = "warning" },
  { latex = "quarto-callout-caution-color-frame", key = "warning" },
  { latex = "quarto-callout-important-color", key = "danger" },
  { latex = "quarto-callout-important-color-frame", key = "danger" },
  { latex = "quarto-callout-tip-color", key = "success" },
  { latex = "quarto-callout-tip-color-frame", key = "success" },
  { latex = "quarto-callout-warning-color", key = "warning" },
  { latex = "quarto-callout-warning-color-frame", key = "warning" },
}

-- Normalise a colour value to a bare 6-digit uppercase hex string
-- (no leading '#'), the form \definecolor{}{HTML}{} expects.
-- Returns nil for anything that is not a #RRGGBB / RRGGBB hex.
local function normalize_hex(value)
  if value == nil then
    return nil
  end
  local hex = tostring(value):gsub("%s", ""):gsub("^#", "")
  if hex:match("^%x%x%x%x%x%x$") then
    return hex:upper()
  end
  return nil
end

-- Look up a brand key in a parsed brand meta table: semantic
-- `color:` block first, then `color.palette:` extras.
local function brand_lookup(brand_meta, key)
  local color = brand_meta and brand_meta.color
  if color == nil then
    return nil
  end
  if color[key] ~= nil then
    return pandoc.utils.stringify(color[key])
  end
  if color.palette ~= nil and color.palette[key] ~= nil then
    return pandoc.utils.stringify(color.palette[key])
  end
  return nil
end

-- Parse YAML text into a meta table using Pandoc's own reader
-- (wrap as front matter, read as markdown, take `.meta`) rather
-- than a hand-rolled parser. Returns nil on failure.
local function parse_brand_yaml(content)
  if content == nil or content == "" then
    return nil
  end
  local ok, doc = pcall(pandoc.read, "---\n" .. content .. "\n---\n", "markdown")
  if not ok or doc == nil then
    return nil
  end
  return doc.meta
end

-- Read and parse a brand file from disk. Returns nil if the file
-- cannot be read or parsed.
local function read_brand_file(path)
  if path == nil or path == "" then
    return nil
  end
  local fh = io.open(path, "r")
  if fh == nil then
    return nil
  end
  local content = fh:read("*a")
  fh:close()
  return parse_brand_yaml(content)
end

-- Load the extension's bundled brand.yml (the base palette), found
-- relative to this script via PANDOC_SCRIPT_FILE.
local function load_bundled_brand()
  if PANDOC_SCRIPT_FILE == nil then
    return nil
  end
  local dir = tostring(PANDOC_SCRIPT_FILE):match("^(.*)[/\\][^/\\]+$")
  if dir == nil then
    return nil
  end
  return read_brand_file(dir .. "/../brand.yml")
end

-- Collect the consuming project's brand sources from `meta.brand`,
-- in declaration order (later sources override earlier ones, per
-- Quarto's brand-merge semantics). Handles a single file path, a
-- list of file paths, and inline brand maps.
local function load_consumer_brands(brandmeta)
  local sources = {}
  if brandmeta == nil then
    return sources
  end
  local t = brandmeta.t
  if t == "MetaMap" then
    -- inline `brand: { color: ... }`
    table.insert(sources, brandmeta)
  elseif t == "MetaList" then
    for _, item in ipairs(brandmeta) do
      if item.t == "MetaMap" then
        table.insert(sources, item)
      else
        local parsed = read_brand_file(pandoc.utils.stringify(item))
        if parsed ~= nil then
          table.insert(sources, parsed)
        end
      end
    end
  else
    local parsed = read_brand_file(pandoc.utils.stringify(brandmeta))
    if parsed ~= nil then
      table.insert(sources, parsed)
    end
  end
  return sources
end

-- Resolve a brand key across the ordered source list, keeping the
-- last source that defines it (so consumer brands override the
-- bundled base).
local function resolve_color(sources, key)
  local value = nil
  for _, src in ipairs(sources) do
    local found = brand_lookup(src, key)
    if found ~= nil then
      value = found
    end
  end
  return value
end

function Meta(meta)
  local bundled = load_bundled_brand()
  if bundled == nil then
    error(
      "epitemplates-report: inject-brand-colors.lua could not read the "
        .. "bundled brand.yml next to the extension's scripts directory. "
        .. "The PDF palette is sourced from that file; without it the "
        .. "report would render with undefined colours."
    )
  end

  -- Base = bundled palette; consumer brands (if any) overlaid after.
  local sources = { bundled }
  for _, src in ipairs(load_consumer_brands(meta.brand)) do
    table.insert(sources, src)
  end

  local lines = {}
  local callout_lines = {}
  local unresolved = {}
  for _, entry in ipairs(COLOR_MAP) do
    local hex = normalize_hex(resolve_color(sources, entry.key))
    if hex == nil then
      table.insert(unresolved, entry.latex .. " (" .. entry.key .. ")")
    else
      local def = "\\definecolor{"
        .. entry.latex
        .. "}{HTML}{"
        .. hex
        .. "}"
      -- Quarto re-defines the quarto-callout-* colours in ITS OWN
      -- preamble, AFTER this header-includes block, so a plain
      -- \definecolor here is clobbered (the .callout-* boxes would
      -- keep Quarto's defaults). Defer those to \AtBeginDocument,
      -- which runs after the whole preamble, so the brand colours
      -- win and the callouts pick them up. The non-callout colours
      -- stay early because pdf/header.tex consumes them (\color{
      -- primary}, mdframed boxes) while the preamble is still open.
      if entry.latex:match("^quarto%-callout%-") then
        table.insert(callout_lines, def)
      else
        table.insert(lines, def)
      end
    end
  end

  if #unresolved > 0 then
    io.stderr:write(
      "epitemplates-report: inject-brand-colors.lua could not resolve "
        .. "these PDF colours from brand.yml: "
        .. table.concat(unresolved, ", ")
        .. ". Affected callouts/boxes will fall back to LaTeX defaults.\n"
    )
  end

  if #lines == 0 and #callout_lines == 0 then
    return nil
  end

  local blocks = {}
  if #lines > 0 then
    table.insert(blocks, table.concat(lines, "\n"))
  end
  if #callout_lines > 0 then
    table.insert(
      blocks,
      "\\AtBeginDocument{%\n" .. table.concat(callout_lines, "\n") .. "%\n}"
    )
  end

  local injected = pandoc.MetaBlocks({
    pandoc.RawBlock("latex", table.concat(blocks, "\n")),
  })

  local existing = meta["header-includes"]
  if existing == nil then
    meta["header-includes"] = pandoc.MetaList({ injected })
  elseif existing.t == "MetaList" then
    table.insert(existing, 1, injected)
    meta["header-includes"] = existing
  else
    meta["header-includes"] = pandoc.MetaList({ injected, existing })
  end

  return meta
end
