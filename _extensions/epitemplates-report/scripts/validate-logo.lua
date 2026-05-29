--[[
validate-logo.lua

Rejects unsafe values for the logo-related YAML keys before they
flow into the rendered output. Runs for html, revealjs, and pdf.

Why this exists
- partials/title-block.html injects $logo$ / $logo2$ verbatim
  into <img src="...">. A malicious YAML value such as
  `logo: javascript:alert(1)` or `logo: "data:image/svg+xml,...
  <script>..."` would end up in the rendered HTML.
- For pdf, inject-pdf-logo.lua emits the value into
  \def\pdflogo{...}; an attacker-supplied path containing LaTeX
  control sequences could escape the macro.
- The PDF logo width flows into \def\pdflogowidth{...}; only
  numeric-with-unit values are safe.

Policy
- logo / logo2: must be a local file path. URL schemes
  (http:, https:, javascript:, data:, file:, vbscript:, ...) are
  blocked. Windows drive letters (C:\, D:/) are explicitly allowed.
- pdf-logo-width: must match a LaTeX dimension (`<number><unit>`,
  e.g. 5cm, 4cm, 30mm, 1.5in).
- Newlines, NULs, and any inline element that is not a Str or
  Space (i.e. RawInline tex/html, Code, …) cause the build to
  abort. This blocks the bypass where Pandoc parses a YAML value
  starting with a backslash as RawInline (tex) so that
  pandoc.utils.stringify returns the empty string.

On rejection the build aborts with a clear error message so the
report cannot be rendered with the unsafe value silently in place.
]]

-- Convert a metadata value to a plain Lua string IF every inline
-- element is a Str or Space. Otherwise returns (nil, reason) and
-- the caller treats this as a hard rejection.
--
-- Pandoc Lua exposes a MetaInlines value as a list-like table of
-- inline elements (each with a `.t` tag like "Str", "Space",
-- "RawInline"). MetaString comes through as a plain Lua string.
local function meta_to_plain(value)
  if value == nil then
    return nil, "missing"
  end
  if type(value) == "string" then
    return value
  end
  if type(value) == "table" then
    local parts = {}
    for _, inline in ipairs(value) do
      local tag = inline.t
      if tag == "Str" then
        table.insert(parts, inline.text or "")
      elseif tag == "Space" then
        table.insert(parts, " ")
      else
        return nil,
          "contains a non-plain inline element ("
            .. tostring(tag)
            .. "); only plain strings are accepted here"
      end
    end
    return table.concat(parts)
  end
  return nil, "unexpected metadata type " .. type(value)
end

local function is_local_path(path)
  if path == nil or path == "" then
    return true
  end
  if path:match("[\r\n%z]") then
    return false
  end
  if path:find(":", 1, true) then
    -- Allow Windows drive letter: single ASCII letter + ':' + '\\' or '/'
    return path:match("^%a:[\\/]") ~= nil
  end
  return true
end

local function is_safe_dimension(dim)
  if dim == nil or dim == "" then
    return true
  end
  if dim:match("[\r\n%z]") then
    return false
  end
  return dim:match("^%s*[%d%.]+%s*%a+%s*$") ~= nil
end

local function reject(key, value, hint)
  error(
    "epitemplates-report: refusing to render with '"
      .. key
      .. ": "
      .. tostring(value)
      .. "'. "
      .. hint
  )
end

function Meta(meta)
  for _, key in ipairs({ "logo", "logo2" }) do
    if meta[key] ~= nil then
      local path, reason = meta_to_plain(meta[key])
      if path == nil then
        reject(
          key,
          "<non-plain>",
          "Logos must be plain string paths — " .. reason .. "."
        )
      end
      if not is_local_path(path) then
        reject(
          key,
          path,
          "Logos must be local file paths (e.g. img/foo.png). "
            .. "URLs and schemes (javascript:, data:, http://, file://, ...) "
            .. "are blocked to avoid injecting arbitrary content into the "
            .. "rendered report."
        )
      end
    end
  end

  if meta["pdf-logo-width"] ~= nil then
    local dim, reason = meta_to_plain(meta["pdf-logo-width"])
    if dim == nil then
      reject(
        "pdf-logo-width",
        "<non-plain>",
        "Width must be a plain string — " .. reason .. "."
      )
    end
    if not is_safe_dimension(dim) then
      reject(
        "pdf-logo-width",
        dim,
        "Use a LaTeX dimension: a number with a unit, e.g. 5cm, 4cm, 30mm, 1.5in."
      )
    end
  end

  return meta
end
