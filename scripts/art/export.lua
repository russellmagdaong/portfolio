-- Exports one .aseprite file for the site. `npm run art` (scripts/art/export.mjs)
-- runs this once per file; it never changes the .aseprite file itself.
--
-- Params:
--   file=<.aseprite>   the source
--   out=<folder>       where the PNG(s) and JSON go
--   name=<name>        the base name of the outputs
--   mode=sprite        an animated sprite: one sheet, one row per tag
--   mode=layers        a scene or the map: one image per layer, back to front
--   palette=<.gpl>     optional: warn about colours that are not in it
--
-- What is read from the file (see art/README.md):
--   tags, frame durations, slices and their user data, layers and their user
--   data. Hidden layers, and layers whose names start with "_", are left out.
-- User data is written as `key=value` pairs separated by ";" or new lines
-- (`speed=0.3; over`); a bare word means `word=true`.

local FILE = assert(app.params["file"], "pass --script-param file=<.aseprite>")
local OUT = assert(app.params["out"], "pass --script-param out=<folder>")
local NAME = assert(app.params["name"], "pass --script-param name=<name>")
local MODE = app.params["mode"] or "sprite"
local PALETTE = app.params["palette"]

local pc = app.pixelColor
local spr = Sprite { fromFile = FILE }
if not spr then error("cannot open " .. FILE) end

---------------------------------------------------------------------------
-- A small JSON writer (keys keep the order they are listed in).

local function encode(v, indent)
  indent = indent or ""
  local t = type(v)
  if t == "number" then
    if v == math.floor(v) then return string.format("%d", v) end
    return (string.format("%.4f", v):gsub("0+$", ""))
  elseif t == "boolean" then
    return tostring(v)
  elseif t == "string" then
    return '"' .. v:gsub('[%c"\\]', function(c)
      local map = { ['"'] = '\\"', ["\\"] = "\\\\", ["\n"] = "\\n", ["\r"] = "\\r", ["\t"] = "\\t" }
      return map[c] or string.format("\\u%04x", c:byte())
    end) .. '"'
  elseif t == "table" then
    local inner = indent .. "  "
    if v.__keys then -- an object
      if #v.__keys == 0 then return "{}" end
      local parts = {}
      for _, k in ipairs(v.__keys) do
        parts[#parts + 1] = inner .. encode(k) .. ": " .. encode(v[k], inner)
      end
      return "{\n" .. table.concat(parts, ",\n") .. "\n" .. indent .. "}"
    end
    if #v == 0 then return "[]" end
    local flat = true
    for _, x in ipairs(v) do if type(x) == "table" then flat = false end end
    local parts = {}
    for _, x in ipairs(v) do parts[#parts + 1] = encode(x, inner) end
    if flat then return "[" .. table.concat(parts, ", ") .. "]" end
    return "[\n" .. inner .. table.concat(parts, ",\n" .. inner) .. "\n" .. indent .. "]"
  end
  return "null"
end

-- An object that remembers the order its keys were set in.
local function object(pairsList)
  local o = { __keys = {} }
  for i = 1, #pairsList, 2 do
    local k, v = pairsList[i], pairsList[i + 1]
    if v ~= nil then
      o.__keys[#o.__keys + 1] = k
      o[k] = v
    end
  end
  return o
end
local function set(o, k, v)
  if o[k] == nil then o.__keys[#o.__keys + 1] = k end
  o[k] = v
end

local function writeJson(path, value)
  local f = assert(io.open(path, "w"))
  f:write(encode(value) .. "\n")
  f:close()
end

---------------------------------------------------------------------------

-- "speed=0.3; over" -> { speed = 0.3, over = true }
local function parseData(text)
  local o = object {}
  for piece in (text or ""):gmatch("[^;\n]+") do
    piece = piece:match("^%s*(.-)%s*$")
    if piece ~= "" then
      local k, v = piece:match("^([^=]-)%s*=%s*(.*)$")
      if not k then
        set(o, piece, true)
      elseif tonumber(v) then
        set(o, k, tonumber(v))
      elseif v == "true" or v == "false" then
        set(o, k, v == "true")
      else
        set(o, k, v)
      end
    end
  end
  return o
end

local function slug(text)
  local s = text:lower():gsub("[^%w]+", "-"):gsub("^%-+", ""):gsub("%-+$", "")
  return s ~= "" and s or "layer"
end

local function ms(frame) return math.floor(frame.duration * 1000 + 0.5) end

local DIRECTIONS = { [0] = "forward", [1] = "reverse", [2] = "pingpong", [3] = "pingpong-reverse" }

-- Colours outside the shared palette, counted once per file.
local allowed, stray = nil, {}
if PALETTE then
  local pal = Palette { fromFile = PALETTE }
  if pal then
    allowed = {}
    for i = 0, #pal - 1 do
      local c = pal:getColor(i)
      allowed[(c.red << 16) | (c.green << 8) | c.blue] = true
    end
  else
    print("warning: cannot read the palette " .. PALETTE)
  end
end
-- Returns how many pixels of the image are off the palette.
local function checkColours(image)
  if not allowed then return 0 end
  local count = 0
  for p in image:pixels() do
    local v = p()
    if pc.rgbaA(v) > 0 then
      local key = (pc.rgbaR(v) << 16) | (pc.rgbaG(v) << 8) | pc.rgbaB(v)
      if not allowed[key] then
        stray[key] = (stray[key] or 0) + 1
        count = count + 1
      end
    end
  end
  return count
end
local strayWhere = {} -- the tags (or layers) the stray colours are in

local function render(n)
  local image = Image(spr.width, spr.height, ColorMode.RGB)
  image:drawSprite(spr, n)
  return image
end

local function union(a, b)
  if a.isEmpty then return b end
  if b.isEmpty then return a end
  return a:union(b)
end

local function exportedSlices(dx, dy)
  local list = {}
  for _, s in ipairs(spr.slices) do
    local b = s.bounds
    list[#list + 1] = object {
      "name", s.name,
      "x", b.x - dx, "y", b.y - dy, "width", b.width, "height", b.height,
      "data", parseData(s.data),
    }
  end
  return list
end

-- Guide layers ("_..." names) are never exported, even when they are visible.
local function exported(layer)
  return layer.name:sub(1, 1) ~= "_"
end

---------------------------------------------------------------------------
-- mode=sprite

local function exportSprite()
  -- Leave out the guide layers while rendering.
  for _, layer in ipairs(spr.layers) do
    if layer.name:sub(1, 1) == "_" then layer.isVisible = false end
  end

  local rows = {}
  if #spr.tags == 0 then
    rows[1] = { name = "default", from = 1, to = #spr.frames, dir = 0, repeats = 0 }
  end
  local seen = {}
  for _, tag in ipairs(spr.tags) do
    if seen[tag.name] then error(FILE .. ": two tags are called " .. tag.name) end
    seen[tag.name] = true
    rows[#rows + 1] = {
      name = tag.name, from = tag.fromFrame.frameNumber, to = tag.toFrame.frameNumber,
      dir = tag.aniDir, repeats = tag.repeats or 0,
    }
  end

  -- The cell is the smallest box that holds every frame, so the sprite does
  -- not shift from one animation to the next.
  local images, box, off = {}, Rectangle(), {}
  for n = 1, #spr.frames do
    images[n] = render(n)
    off[n] = checkColours(images[n]) > 0
    box = union(box, images[n]:shrinkBounds())
  end
  for _, row in ipairs(rows) do
    local frames = {}
    for n = row.from, row.to do
      if off[n] then frames[#frames + 1] = tostring(n - row.from + 1) end
    end
    if #frames > 0 then strayWhere[#strayWhere + 1] = row.name .. " " .. table.concat(frames, ",") end
  end
  if box.isEmpty then error(FILE .. " has nothing drawn in it") end

  local columns = 0
  for _, row in ipairs(rows) do columns = math.max(columns, row.to - row.from + 1) end
  local sheet = Image(columns * box.width, #rows * box.height, ColorMode.RGB)
  local tags = object {}
  for r, row in ipairs(rows) do
    local durations = {}
    for n = row.from, row.to do
      local c = n - row.from
      sheet:drawImage(images[n], Point(c * box.width - box.x, (r - 1) * box.height - box.y))
      durations[#durations + 1] = ms(spr.frames[n])
    end
    set(tags, row.name, object {
      "row", r - 1,
      "frames", row.to - row.from + 1,
      "durations", durations,
      "direction", DIRECTIONS[row.dir] or "forward",
      "repeats", row.repeats > 0 and row.repeats or nil,
    })
  end
  sheet:saveAs(OUT .. "/" .. NAME .. ".png")

  -- Where he stands: the middle of the bottom edge of the `feet` slice, or
  -- the bottom of the drawing in the middle of the canvas when there is none.
  local origin
  for _, s in ipairs(spr.slices) do
    if s.name == "feet" then
      local b = s.bounds
      origin = object { "x", b.x + b.width // 2 - box.x, "y", b.y + b.height - box.y }
    end
  end
  if not origin then
    origin = object { "x", spr.width // 2 - box.x, "y", box.height }
    print(("  note: no `feet` slice, so he stands at %d,%d of the frame (bottom middle)"):format(origin.x, origin.y))
  end

  writeJson(OUT .. "/" .. NAME .. ".json", object {
    "source", FILE:gsub("\\", "/"),
    "width", box.width, "height", box.height,
    "columns", columns, "rows", #rows,
    "origin", origin,
    "tags", tags,
    "slices", exportedSlices(box.x, box.y),
  })
  print(("  %s.png: %d frames of %dx%d in %d rows"):format(NAME, #spr.frames, box.width, box.height, #rows))
end

---------------------------------------------------------------------------
-- mode=layers

local function exportLayers()
  -- Visibility is read once here, because rendering one layer at a time
  -- below switches the others off.
  local wasVisible = {}
  for i, layer in ipairs(spr.layers) do wasVisible[i] = layer.isVisible end

  local layers, used = {}, {}
  for i, layer in ipairs(spr.layers) do -- bottom (back) to top (front)
    if wasVisible[i] and exported(layer) then
      for j, other in ipairs(spr.layers) do other.isVisible = (j == i) end
      local images, box = {}, Rectangle()
      local animated = false
      for n = 1, #spr.frames do
        images[n] = render(n)
        box = union(box, images[n]:shrinkBounds())
        if n > 1 and not images[n]:isEqual(images[1]) then animated = true end
      end
      if box.isEmpty then
        print("  note: layer `" .. layer.name .. "` is empty and was skipped")
      else
        local count = animated and #spr.frames or 1
        local strip = Image(count * box.width, box.height, ColorMode.RGB)
        local durations = {}
        for n = 1, count do
          strip:drawImage(images[n], Point((n - 1) * box.width - box.x, -box.y))
          if checkColours(images[n]) > 0 and strayWhere[#strayWhere] ~= layer.name then
            strayWhere[#strayWhere + 1] = layer.name
          end
          durations[n] = ms(spr.frames[n])
        end
        local base = slug(layer.name)
        local file, k = base, 2
        while used[file] do file = base .. "-" .. k; k = k + 1 end
        used[file] = true
        strip:saveAs(OUT .. "/" .. file .. ".png")
        layers[#layers + 1] = object {
          "name", layer.name,
          "image", file .. ".png",
          "x", box.x, "y", box.y, "width", box.width, "height", box.height,
          "frames", count,
          "durations", animated and durations or nil,
          "data", parseData(layer.data),
        }
      end
    end
  end
  for i, layer in ipairs(spr.layers) do layer.isVisible = wasVisible[i] end

  writeJson(OUT .. "/" .. NAME .. ".json", object {
    "source", FILE:gsub("\\", "/"),
    "width", spr.width, "height", spr.height,
    "layers", layers,
    "slices", exportedSlices(0, 0),
  })
  print(("  %s: %d layers, %d slices"):format(NAME, #layers, #spr.slices))
end

---------------------------------------------------------------------------

if MODE == "sprite" then
  exportSprite()
elseif MODE == "layers" then
  exportLayers()
else
  error("unknown mode " .. MODE)
end

local keys = {}
for k in pairs(stray) do keys[#keys + 1] = k end
if #keys > 0 then
  table.sort(keys, function(a, b) return stray[a] > stray[b] end)
  local list = {}
  for i = 1, math.min(#keys, 8) do list[i] = string.format("#%06x (%d px)", keys[i], stray[keys[i]]) end
  print(("  warning: %d colour(s) not in the shared palette, in %s: %s%s"):format(
    #keys, table.concat(strayWhere, "; "), table.concat(list, ", "), #keys > 8 and ", ..." or ""))
end
print("EXPORT-OK")
