--[[
inject-pdf-logo.lua

Reads the document's `logo:` (and optional `pdf-logo-width:`) YAML
metadata and injects `\def\pdflogo{...}` / `\def\pdflogowidth{...}`
at the top of `header-includes`, so they are defined BEFORE
pdf/header.tex runs its `\providecommand{\pdflogo}` defaults.

This lets a consumer set `logo:` once at document level and have it
apply across html, revealjs, and pdf formats, instead of needing
the separate `header-includes:` override for pdf.

Format scope: registered only under the pdf format in _extension.yml,
so it never runs for html or revealjs builds.
]]

local function meta_to_string(value)
  if value == nil then
    return nil
  end
  return pandoc.utils.stringify(value)
end

function Meta(meta)
  local logo_path = meta_to_string(meta.logo)
  if logo_path == nil or logo_path == "" then
    return nil
  end

  local logo_width = meta_to_string(meta["pdf-logo-width"]) or "5cm"

  local injected = pandoc.MetaBlocks({
    pandoc.RawBlock(
      "latex",
      "\\def\\pdflogo{" .. logo_path .. "}\n" ..
      "\\def\\pdflogowidth{" .. logo_width .. "}"
    ),
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
