-- deck-shortcodes.lua (deck) — Quarto shortcodes for the deck's inline /
-- atomic vocabulary (plan §5.1) drawn with the shared offline icon registry
-- (`deck-icons.lua`, plan §5.4).
-- Contributed via `contributes.shortcodes` in _extension.yml (NOT a Pandoc
-- `filters:` entry — these run as Quarto shortcode handlers).
--
-- Five shortcodes, each emitting the DOM the B3/B4 theme scss already styles
-- (`.eyebrow`, `.chip`, `.card.stat .viz/.big/.kicker`):
--
--   {{< eyebrow "How the pieces fit together" >}}   block  -> .eyebrow
--   {{< chip "DuckDB" accent >}}                     inline -> .chip(.accent)
--   {{< stat value="120k" label="Enrolments" icon=people accent >}}
--                                                    block  -> .card.stat
--   {{< icon database >}}                            inline -> <svg>
--   {{< dots >}}                                     block  -> scatter <svg>
--
-- Glyphs come from `deck-icons.lua` (Bootstrap Icons, MIT), each drawn with
-- `fill="currentColor"` so context (a teal chip, a coral stat) tints it;
-- `{{< dots >}}` is a deterministic precomputed scatter (a fixed-seed MINSTD
-- walk evaluated once at load), recovering the title decoration the source
-- decks generated at runtime — no JS, no network.
--
-- Reads ONLY shortcode args + the shared registry: no network, no external deps.

-- The icon registry now lives in the shared `deck-icons.lua` (same dir), loaded
-- by both this shortcode set and `deck-layout.lua` so the `:::{.card .stat}` Div
-- path draws the same glyph. dofile re-runs that module and returns its table;
-- PANDOC_SCRIPT_FILE locates this script so the sibling resolves no matter which
-- directory Quarto renders from.
local deck_icons = dofile(
  pandoc.path.join({
    pandoc.path.directory(PANDOC_SCRIPT_FILE),
    "deck-icons.lua",
  })
)
local icon_svg = deck_icons.icon_svg

--- Emit a deck warning, falling back to stderr outside Quarto.
-- @param msg string
local function warn(msg)
  local full = "deck-shortcodes: " .. msg
  if quarto ~= nil and quarto.log ~= nil and quarto.log.warning ~= nil then
    quarto.log.warning(full)
  else
    io.stderr:write(full .. "\n")
  end
end


--- Test whether any positional arg from `from_index` on is the bare flag `name`.
-- @param args table  the shortcode positional args (lists of inlines)
-- @param from_index integer  first index to scan (1 for stat, 2 for chip)
-- @param name string  the flag token to match
-- @return boolean
local function has_flag(args, from_index, name)
  for i = from_index, #args do
    if pandoc.utils.stringify(args[i]) == name then
      return true
    end
  end
  return false
end

--- Precompute the title-slide scatter as static SVG (plan §5.1 / §5.4).
-- A fixed-seed Park-Miller MINSTD walk drives the positions so the figure is
-- byte-identical on every render (no math.random, no per-render drift). Drawn
-- with currentColor so a teal title slide tints the dots; the author sizes it.
-- @return string  a self-contained decorative <svg>
local function build_dots_svg()
  local seed = 2779097 -- fixed → deterministic
  local function rnd()
    seed = (seed * 16807) % 2147483647
    return seed / 2147483647
  end
  local width, height, count = 1920, 1080, 44
  local parts = {
    table.concat({
      '<svg xmlns="http://www.w3.org/2000/svg" class="deck-dots"',
      ' viewBox="0 0 ',
      width,
      " ",
      height,
      '" width="100%" height="100%"',
      ' preserveAspectRatio="xMidYMid slice" aria-hidden="true">',
    }),
  }
  for _ = 1, count do
    local cx = math.floor(rnd() * width)
    local cy = math.floor(rnd() * height)
    local r = 2 + math.floor(rnd() * 6)
    local op = 0.06 + rnd() * 0.30
    parts[#parts + 1] = string.format(
      '<circle cx="%d" cy="%d" r="%d" fill="currentColor" fill-opacity="%.3f"/>',
      cx,
      cy,
      r,
      op
    )
  end
  parts[#parts + 1] = "</svg>"
  return table.concat(parts)
end

local DOTS_SVG = build_dots_svg()

--- `{{< eyebrow "text" >}}` — the mono uppercase kicker above a slide title.
local function eyebrow(args, kwargs, meta)
  local text = args[1] or {}
  return pandoc.Div(pandoc.Plain(text), pandoc.Attr("", { "eyebrow" }))
end

--- `{{< chip "Label" [solid|accent] >}}` — an inline pill.
local function chip(args, kwargs, meta)
  local label = args[1] or {}
  local classes = { "chip" }
  if has_flag(args, 2, "solid") then
    table.insert(classes, "solid")
  end
  if has_flag(args, 2, "accent") then
    table.insert(classes, "accent")
  end
  return pandoc.Span(label, pandoc.Attr("", classes))
end

--- `{{< stat value="120k" label="Enrolments" icon=people [accent] >}}` —
--- a stat card: `.viz` (icon) + `.big` (value) + `.kicker` (label). Mirrors
--- the inner DOM the B5 deck-layout.lua filter injects for `:::{.card .stat}`,
--- so the two authoring paths render identically. Any of value/label/icon may
--- be omitted; an unknown icon warns and drops the `.viz` well.
local function stat(args, kwargs, meta)
  local value = kwargs["value"]
  local label = kwargs["label"]
  local icon_name = nil
  if kwargs["icon"] ~= nil then
    icon_name = pandoc.utils.stringify(kwargs["icon"])
    if icon_name == "" then
      icon_name = nil
    end
  end

  local classes = { "card", "stat" }
  if has_flag(args, 1, "accent") then
    table.insert(classes, "accent")
  end

  local inner = pandoc.List({})
  if icon_name ~= nil then
    local svg = icon_svg(icon_name)
    if svg == nil then
      warn("unknown icon '" .. icon_name .. "' in {{< stat >}}")
    else
      inner:insert(
        pandoc.Div(
          { pandoc.RawBlock("html", svg) },
          pandoc.Attr("", { "viz" })
        )
      )
    end
  end
  if value ~= nil and #value > 0 then
    inner:insert(pandoc.Div(pandoc.Plain(value), pandoc.Attr("", { "big" })))
  end
  if label ~= nil and #label > 0 then
    inner:insert(
      pandoc.Div(pandoc.Plain(label), pandoc.Attr("", { "kicker" }))
    )
  end

  return pandoc.Div(inner, pandoc.Attr("", classes))
end

--- `{{< icon name >}}` — an inline currentColor glyph from the registry.
local function icon(args, kwargs, meta)
  local name = ""
  if args[1] ~= nil then
    name = pandoc.utils.stringify(args[1])
  end
  local svg = icon_svg(name)
  if svg == nil then
    warn("unknown icon '" .. name .. "'")
    return pandoc.RawInline(
      "html",
      '<span class="deck-icon-missing" title="unknown deck icon">['
        .. name
        .. "?]</span>"
    )
  end
  return pandoc.RawInline("html", svg)
end

--- `{{< dots >}}` — the precomputed title-scatter decoration.
local function dots(args, kwargs, meta)
  return pandoc.RawBlock("html", DOTS_SVG)
end

return {
  ["eyebrow"] = eyebrow,
  ["chip"] = chip,
  ["stat"] = stat,
  ["icon"] = icon,
  ["dots"] = dots,
}
