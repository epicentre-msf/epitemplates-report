-- deck-layout.lua (deck) — Pandoc Div filter for the deck's block-level
-- layout sugar (plan §5.2). Wired into the epitemplates-deck-revealjs
-- format `filters:` in _extension.yml.
--
-- All transforms are opt-in via fenced-div classes/attributes, so plain
-- Quarto Markdown stays plain. Two AST transforms + one documented native:
--
--   1. ::: {.deck-grid cols="260px 380px 1fr 80px"} … :::
--        -> inline CSS grid. Pandoc does not reliably pass arbitrary
--           `style=` through on fenced divs, so the filter is what makes
--           `cols="…"` ergonomic and safe (plan §5.2). Optional `gap="…"`.
--
--   2. ::: {.card .stat value="120k" label="Enrolments" icon="people"} … :::
--        -> inject the `.viz` / `.big` / `.kicker` inner DOM that the B4
--           theme scss (`.reveal .card.stat .big/.kicker`) styles, so
--           authors don't hand-write the stat structure. The `.viz` glyph is
--           drawn from the shared `deck-icons.lua` registry — the same source
--           the `{{< stat >}}` shortcode uses — so both authoring paths match.
--
--   3. ## Title {.divider}
--        -> divider slides render full-bleed via the B3 theme scss
--           (`section.divider`). Quarto already propagates a slide header's
--           classes onto the reveal `<section>` (verified B3), and a pandoc
--           Lua filter runs BEFORE Quarto's reveal sectioning, so it cannot
--           reach the `<section>` to add the class. The plan §5.2 "guarantee"
--           is thus met by Quarto's native propagation; this filter
--           deliberately does NOT touch dividers — no no-op code, one path.
--
-- Reads ONLY the Pandoc AST + the baked-in icon registry: no network, no
-- external deps. HTML/revealjs target only (the deck is an HTML-based format).

-- The shared icon registry (deck-icons.lua, same dir) lets the `.card .stat`
-- Div path draw the same glyph the `{{< stat >}}` shortcode does (closes PL-1).
-- PANDOC_SCRIPT_FILE locates this filter so the sibling resolves regardless of
-- the directory Quarto renders from.
local deck_icons = dofile(
  pandoc.path.join({
    pandoc.path.directory(PANDOC_SCRIPT_FILE),
    "deck-icons.lua",
  })
)

--- Emit a deck warning, falling back to stderr outside Quarto.
-- @param msg string
local function warn(msg)
  local full = "deck-layout: " .. msg
  if quarto ~= nil and quarto.log ~= nil and quarto.log.warning ~= nil then
    quarto.log.warning(full)
  else
    io.stderr:write(full .. "\n")
  end
end

--- Build the inline grid style string for a `.deck-grid` div.
-- @param cols string  the `grid-template-columns` track list (verbatim)
-- @param gap  string|nil  optional gap; defaults to the decks' 40px
-- @return string  a `;`-joined CSS declaration list
local function build_grid_style(cols, gap)
  return table.concat({
    "display:grid",
    "grid-template-columns:" .. cols,
    "gap:" .. (gap or "40px"),
    "align-items:center",
  }, ";")
end

--- Apply the `.deck-grid` transform in place.
-- @param el pandoc.Div
local function apply_deck_grid(el)
  local cols = el.attributes["cols"]
  if cols == nil or cols == "" then
    return
  end
  local grid = build_grid_style(cols, el.attributes["gap"])
  local existing = el.attributes["style"]
  if existing ~= nil and existing ~= "" then
    el.attributes["style"] = existing .. ";" .. grid
  else
    el.attributes["style"] = grid
  end
  el.attributes["cols"] = nil
  el.attributes["gap"] = nil
end

--- Enrich a `.card.stat` div from its `value` / `label` / `icon` attributes.
-- Prepends `.viz` (icon placeholder), `.big` (value), `.kicker` (label) to
-- the card's content, then consumes the attributes so they don't leak to
-- HTML. If none are present, the card is left untouched (the author wrote
-- the inner DOM by hand).
-- @param el pandoc.Div
local function apply_stat(el)
  local value = el.attributes["value"] or el.attributes["data-value"]
  local label = el.attributes["label"] or el.attributes["data-label"]
  local icon = el.attributes["icon"] or el.attributes["data-icon"]
  if value == nil and label == nil and icon == nil then
    return
  end

  local injected = pandoc.List({})
  if icon ~= nil then
    -- Draw the glyph from the shared registry (PL-1). An unknown name warns
    -- and falls back to an empty `.viz` carrying the name, so a typo shows in
    -- the log without breaking the card.
    local svg = deck_icons.icon_svg(icon)
    if svg == nil then
      warn("unknown icon '" .. icon .. "' in `.card .stat`")
      injected:insert(
        pandoc.Div({}, pandoc.Attr("", { "viz" }, { { "data-icon", icon } }))
      )
    else
      injected:insert(
        pandoc.Div({ pandoc.RawBlock("html", svg) }, pandoc.Attr("", { "viz" }))
      )
    end
  end
  if value ~= nil then
    injected:insert(
      pandoc.Div(pandoc.Plain(pandoc.Str(value)), pandoc.Attr("", { "big" }))
    )
  end
  if label ~= nil then
    injected:insert(
      pandoc.Div(
        pandoc.Plain(pandoc.Str(label)),
        pandoc.Attr("", { "kicker" })
      )
    )
  end

  for _, block in ipairs(el.content) do
    injected:insert(block)
  end
  el.content = injected

  for _, key in ipairs({
    "value",
    "label",
    "icon",
    "data-value",
    "data-label",
    "data-icon",
  }) do
    el.attributes[key] = nil
  end
end

--- Wrap a `.card` carrying `link="#/2"` in a navigable anchor.
-- reveal.js follows an internal `#/n` href to that slide, so the card becomes
-- click-navigable — recovering the source decks' clickable agenda cards
-- (plan Gap #7 / B8 review #3) without a data-goto engine. The anchor uses
-- `display:contents` (theme) so the card stays the grid/flex item. Returns the
-- 3-block sequence [<a …>, card, </a>] or nil if there is no link.
-- @param el pandoc.Div
-- @return table|nil
local function wrap_link(el)
  local href = el.attributes["link"]
  if href == nil or href == "" then
    return nil
  end
  el.attributes["link"] = nil
  return {
    pandoc.RawBlock("html", '<a class="deck-cardlink" href="' .. href .. '">'),
    el,
    pandoc.RawBlock("html", "</a>"),
  }
end

--- Div filter entry point.
-- @param el pandoc.Div
-- @return pandoc.Div|table
function Div(el)
  if el.classes:includes("deck-grid") then
    apply_deck_grid(el)
  end
  if el.classes:includes("card") and el.classes:includes("stat") then
    apply_stat(el)
  end
  if el.classes:includes("card") and el.attributes["link"] ~= nil then
    local wrapped = wrap_link(el)
    if wrapped ~= nil then
      return wrapped
    end
  end
  return el
end
