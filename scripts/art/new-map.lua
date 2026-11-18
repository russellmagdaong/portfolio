-- Starts the town map with grey placeholders: art/map.aseprite (the background
-- and the slices the engine reads) and one sprite per building in
-- art/map-objects/<id>.aseprite. See art/README.md.
--
--   "C:\aseprite\build\bin\aseprite.exe" -b --script scripts/art/new-map.lua
--
-- It never draws over existing files. Once they exist they are the source of
-- truth and are edited in Aseprite.

local MAP = "art/map.aseprite"
local OBJECTS = "art/map-objects/"
local W, H = 480, 270

-- The streets: points and the straight stretches between them, a main road that
-- winds across town with side streets off it. Points are where the paths bend,
-- meet or end; the engine walks him along these lines.
local POINTS = {
  { "west", 86, 206 }, { "bend-1", 140, 184 }, { "square", 222, 168 }, { "bend-2", 304, 150 },
  { "east", 392, 132 }, { "north-lane", 212, 106 }, { "lane-top", 200, 60 }, { "west-lane", 126, 128 },
  { "south-lane", 318, 200 }, { "east-lane", 372, 200 },
}
local ROADS = {
  { "west", "bend-1" }, { "bend-1", "square" }, { "square", "bend-2" }, { "bend-2", "east" },
  { "square", "north-lane" }, { "north-lane", "lane-top" }, { "bend-1", "west-lane" },
  { "bend-2", "south-lane" }, { "south-lane", "east-lane" },
}
-- Buildings, scattered, all inside the middle 320x180 that is always on screen
-- (x 80-400, y 45-224). x = the middle of the front, bottom = the front's
-- baseline, then size. A footpath runs from the door to the street point `via`,
-- by way of `around` (a corner, so the path does not cross the building).
local BUILDINGS = {
  { id = "home", x = 112, bottom = 112, w = 50, h = 40, via = "west-lane" },
  { id = "school", x = 272, bottom = 100, w = 76, h = 52, via = "north-lane" },
  { id = "arcade", x = 362, bottom = 112, w = 56, h = 46, via = "east" },
  { id = "store", x = 178, bottom = 220, w = 44, h = 30, via = "bend-1", around = { 148, 224 } },
  { id = "trophy-shop", x = 262, bottom = 220, w = 50, h = 36, via = "south-lane", around = { 296, 224 } },
  { id = "post-office", x = 372, bottom = 190, w = 48, h = 38, via = "east-lane" },
}

local function exists(path)
  local f = io.open(path, "rb")
  if f then f:close() return true end
  return false
end
if exists(MAP) then error(MAP .. " already exists. Delete or rename it first.") end

local pal = Palette { fromFile = "art/palette.gpl" }
local function rgb(r, g, b) return Color { r = r, g = g, b = b, a = 255 }.rgbaPixel end
local function fill(image, x, y, w, h, c)
  for yy = math.max(0, y), math.min(image.height, y + h) - 1 do
    for xx = math.max(0, x), math.min(image.width, x + w) - 1 do image:drawPixel(xx, yy, c) end
  end
end
-- A thick line: a square stamped every pixel along it.
local function stroke(image, x0, y0, x1, y1, size, c)
  local steps = math.max(math.abs(x1 - x0), math.abs(y1 - y0), 1)
  for i = 0, steps do
    local x = math.floor(x0 + (x1 - x0) * i / steps + 0.5)
    local y = math.floor(y0 + (y1 - y0) * i / steps + 0.5)
    fill(image, x - size // 2, y - size // 2, size, size, c)
  end
end

local pos = {}
for _, p in ipairs(POINTS) do pos[p[1]] = { p[2], p[3] } end
for _, b in ipairs(BUILDINGS) do
  b.door = b.id .. "-door"
  pos[b.door] = { b.x, math.min(b.bottom + 4, 224) }
  if b.around then
    b.corner = b.id .. "-corner"
    pos[b.corner] = b.around
  end
end

-- The background ------------------------------------------------------------

local spr = Sprite(W, H, ColorMode.RGB)
if pal then spr:setPalette(pal) end
local ground = spr.layers[1]
ground.name = "ground"
local roads = spr:newLayer()
roads.name = "roads"
local guide = spr:newLayer()
guide.name = "_guide"
guide.opacity = 160

local g = Image(W, H, ColorMode.RGB)
fill(g, 0, 0, W, H, rgb(16, 36, 30))
for y = 0, H - 1, 6 do for x = (y // 6) % 2 * 3, W - 1, 6 do g:drawPixel(x, y, rgb(28, 58, 42)) end end
-- A few trees, so the town is not just boxes.
for _, t in ipairs { { 100, 160 }, { 178, 142 }, { 252, 130 }, { 322, 126 }, { 418, 170 }, { 96, 238 }, { 330, 240 }, { 160, 78 }, { 60, 120 }, { 420, 96 } } do
  fill(g, t[1] - 6, t[2] - 10, 12, 10, rgb(44, 88, 58))
  fill(g, t[1] - 4, t[2] - 12, 8, 2, rgb(76, 125, 72))
  fill(g, t[1] - 1, t[2], 2, 4, rgb(74, 46, 31))
end
spr:newCel(ground, 1, g, Point(0, 0))

local r = Image(W, H, ColorMode.RGB)
for _, road in ipairs(ROADS) do
  local a, b = pos[road[1]], pos[road[2]]
  stroke(r, a[1], a[2], b[1], b[2], 12, rgb(53, 53, 76))
end
for _, road in ipairs(ROADS) do
  local a, b = pos[road[1]], pos[road[2]]
  stroke(r, a[1], a[2], b[1], b[2], 2, rgb(75, 76, 100))
end
-- Footpaths from each door to its street.
for _, b in ipairs(BUILDINGS) do
  local stops = { b.door, b.corner, b.via }
  if not b.corner then stops = { b.door, b.via } end
  for i = 1, #stops - 1 do
    local a, v = pos[stops[i]], pos[stops[i + 1]]
    stroke(r, a[1], a[2], v[1], v[2], 6, rgb(92, 64, 66))
  end
end
spr:newCel(roads, 1, r, Point(0, 0))

local gd = Image(W, H, ColorMode.RGB)
local cyan = rgb(70, 230, 225)
fill(gd, 80, 44, 320, 1, cyan); fill(gd, 80, 225, 320, 1, cyan)
fill(gd, 79, 45, 1, 180, cyan); fill(gd, 400, 45, 1, 180, cyan)
spr:newCel(guide, 1, gd, Point(0, 0))

local function slice(name, x, y, w, h, data)
  local s = spr:newSlice(Rectangle(x, y, w, h))
  s.name = name
  s.data = data or ""
end

-- Each point lists the points a straight path joins it to.
local links = {}
local function join(a, b)
  links[a] = links[a] or {}; links[b] = links[b] or {}
  table.insert(links[a], b); table.insert(links[b], a)
end
for _, road in ipairs(ROADS) do join(road[1], road[2]) end
for _, b in ipairs(BUILDINGS) do
  if b.corner then
    join(b.door, b.corner)
    join(b.corner, b.via)
  else
    join(b.door, b.via)
  end
end

for _, b in ipairs(BUILDINGS) do
  slice("building:" .. b.id, b.x - b.w // 2, b.bottom - b.h, b.w, b.h, ("scene=%s; door=%s"):format(b.id, b.door))
end
for name, p in pairs(pos) do
  -- A point is a 2x2 slice; the spot is the middle of its bottom edge.
  slice("point:" .. name, p[1] - 1, p[2] - 2, 2, 2, "links=" .. table.concat(links[name], ","))
end
slice("spawn", pos["home-door"][1] - 1, pos["home-door"][2] - 2, 2, 2, "at=home-door")
spr.frames[1].duration = 0.1
spr:saveAs(MAP)
print("saved " .. MAP)

-- One sprite per building ----------------------------------------------------

for _, b in ipairs(BUILDINGS) do
  local path = OBJECTS .. b.id .. ".aseprite"
  if exists(path) then
    print("kept " .. path .. " (it already exists)")
  else
    local bw, bh = b.w, b.h
    local s = Sprite(bw + 4, bh + 4, ColorMode.RGB)
    if pal then s:setPalette(pal) end
    s.layers[1].name = b.id
    s:newEmptyFrame(2)
    local function building(outline)
      local im = Image(s.width, s.height, ColorMode.RGB)
      local x0, y0 = 2, 2
      fill(im, x0, y0, bw, bh, outline)                                   -- outline
      fill(im, x0 + 1, y0 + 1, bw - 2, bh // 3, rgb(96, 48, 38))          -- roof
      fill(im, x0 + 1, y0 + 1 + bh // 3, bw - 2, bh - 2 - bh // 3, rgb(104, 106, 132)) -- front wall
      fill(im, x0 + bw // 2 - 5, y0 + bh - 15, 10, 14, rgb(26, 25, 38))   -- door
      fill(im, x0 + 5, y0 + bh // 3 + 5, 9, 7, rgb(255, 205, 120))       -- windows
      fill(im, x0 + bw - 14, y0 + bh // 3 + 5, 9, 7, rgb(255, 205, 120))
      return im
    end
    s:newCel(s.layers[1], 1, building(rgb(13, 11, 26)), Point(0, 0))
    s:newCel(s.layers[1], 2, building(rgb(255, 226, 77)), Point(0, 0))
    local idle = s:newTag(1, 1); idle.name = "idle"
    local hover = s:newTag(2, 2); hover.name = "hover"
    for i = 1, 2 do s.frames[i].duration = 0.1 end
    -- `base`: the middle of its bottom edge sits on the building's spot.
    local base = s:newSlice(Rectangle(2, bh + 1, bw, 1))
    base.name = "base"
    s:saveAs(path)
    print("saved " .. path)
  end
end
