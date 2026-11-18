-- Starts a new scene file with the standard canvas, layers, slices and guide,
-- so every scene is set up the same way (see art/README.md and art/BRIEF.md).
--
--   "C:\aseprite\build\bin\aseprite.exe" -b --script-param name=arcade --script scripts/art/new-scene.lua
--
-- Params:
--   name=<scene>      required; writes art/scenes/<scene>.aseprite
--   width=<px>        the scene's least width (default 640, two screens); it
--                     grows to fit the things below
--   placeholder=1     fill the layers with flat grey boxes to test the engine
--   things=<list>     with placeholder=1: what stands along the back wall, left
--                     to right, separated by commas. Each is kind:id:WxH:...
--                       object:<id>:WxH:<opens>:<prompt>  a thing that opens a panel
--                                                          (an arcade cabinet)
--                       show:<id>:WxH:<look>              content shown on the wall
--                                                          (look = paper, screen, shelf)
--                       prop:<id>:WxH:<tip>               a prop that shows a card
--                                                          when pointed at or reached
--   exit=right       put the exit at the right end (default: left)
--   out=<file>        write somewhere else instead
-- It never draws over an existing file.
--
-- The phase 3 placeholders are made by scripts/art/placeholders.sh.

local NAME = assert(app.params["name"], "pass --script-param name=<scene>")
local OUT = app.params["out"] or ("art/scenes/" .. NAME .. ".aseprite")
local PLACEHOLDER = app.params["placeholder"] == "1"
local H = 270
local EXIT_RIGHT = app.params["exit"] == "right"

-- The canvas is taller than the screen: only the band SAFE_TOP..SAFE_BOTTOM
-- (180 rows) is sure to be seen; the rest shows on wider or taller windows.
local SAFE_TOP, SAFE_BOTTOM = 45, 224
local FLOOR_TOP = 176   -- the floor's back edge; it runs down to SAFE_BOTTOM
local WALL_TOP = 56     -- the top of a room's back wall
local DOOR_W = 24       -- the exit, at the left end

-- What stands along the wall, laid out left to right.
local THINGS = {}
local x = DOOR_W + 24
for item in (app.params["things"] or ""):gmatch("[^,]+") do
  local parts = {}
  for p in item:gmatch("[^:]+") do parts[#parts + 1] = p end
  local kind, id, size = parts[1], parts[2], parts[3]
  local w, h = (size or ""):match("^(%d+)x(%d+)$")
  if not (kind and id and w) then error("things: write each as kind:id:WxH:..., not " .. item) end
  w, h = tonumber(w), tonumber(h)
  local t = { kind = kind, id = id, w = w, h = h, x = x }
  if kind == "object" then
    t.y = FLOOR_TOP + 6 - h
    t.data = ("opens=%s; prompt=%s"):format(parts[4] or id, parts[5] or "Open")
  elseif kind == "show" then
    t.y = math.max(WALL_TOP + 4, FLOOR_TOP - 12 - h)
    t.look = parts[4] or "paper"
    t.data = "look=" .. t.look
  elseif kind == "prop" then
    t.y = FLOOR_TOP + 6 - h
    t.data = "tip=" .. (parts[4] or id)
  else
    error("things: unknown kind " .. kind)
  end
  THINGS[#THINGS + 1] = t
  x = x + w + 20
end
local W = math.max(tonumber(app.params["width"] or "640"), x + 60)
-- With the exit on the right, keep the last thing clear of it.
if app.params["exit"] == "right" then W = math.max(W, x + DOOR_W + 40) end
local CRATE = { x = math.floor(W * 0.45), w = 32, front = 18, depth = 10, bottom = 214 }

local existing = io.open(OUT, "rb")
if existing then
  existing:close()
  error(OUT .. " already exists. Delete or rename it first.")
end

local spr = Sprite(W, H, ColorMode.RGB)
local pal = Palette { fromFile = "art/palette.gpl" }
if pal then spr:setPalette(pal) end

local function colour(r, g, b, a) return Color { r = r, g = g, b = b, a = a or 255 } end
local function box(layer, bx, by, w, h, c)
  local image = Image(W, H, ColorMode.RGB)
  for yy = math.max(0, by), math.min(H, by + h) - 1 do
    for xx = math.max(0, bx), math.min(W, bx + w) - 1 do image:drawPixel(xx, yy, c.rgbaPixel) end
  end
  local cel = layer:cel(1)
  if cel then
    cel.image:drawImage(image, Point(-cel.position.x, -cel.position.y))
  else
    spr:newCel(layer, 1, image, Point(0, 0))
  end
end
local function framed(layer, bx, by, w, h, edge, fill)
  box(layer, bx, by, w, h, edge)
  box(layer, bx + 1, by + 1, w - 2, h - 2, fill)
end

-- Back to front. Layer user data: speed = how fast it moves past compared
-- with the floor (1); `over` = drawn in front of the player.
local LAYERS = {
  { "sky", "speed=0.1" },
  { "far", "speed=0.3" },
  { "mid", "speed=0.6" },
  { "back", "" },
  { "floor", "" },
  { "props", "" },
  { "front", "speed=1.2; over" },
}
local layers = {}
spr.layers[1].name = LAYERS[1][1]
spr.layers[1].data = LAYERS[1][2]
layers.sky = spr.layers[1]
for i = 2, #LAYERS do
  local layer = spr:newLayer()
  layer.name, layer.data = LAYERS[i][1], LAYERS[i][2]
  layers[LAYERS[i][1]] = layer
end

-- The guide: never exported (its name starts with "_"). Turn it off with the eye.
local guide = spr:newLayer()
guide.name = "_guide"
guide.opacity = 160
local line = colour(70, 230, 225)
box(guide, 0, SAFE_TOP - 1, W, 1, line)          -- top of the safe band
box(guide, 0, SAFE_BOTTOM + 1, W, 1, line)       -- bottom of the safe band
box(guide, 0, FLOOR_TOP, W, 1, colour(255, 79, 154)) -- back edge of the floor
for gx = 320, W - 1, 320 do box(guide, gx, SAFE_TOP, 1, SAFE_BOTTOM - SAFE_TOP + 1, colour(255, 226, 77)) end -- one screen

local INK, PALE = colour(13, 11, 26), colour(179, 182, 201)
if PLACEHOLDER then
  box(layers.sky, 0, 0, W, H, colour(23, 20, 51))
  for fx = 0, W - 1, 96 do box(layers.far, fx, 20, 64, WALL_TOP - 20, colour(38, 37, 56)) end
  for mx = 40, W - 1, 128 do box(layers.mid, mx, 36, 72, WALL_TOP - 36, colour(53, 53, 76)) end
  box(layers.back, 0, WALL_TOP, W, FLOOR_TOP - WALL_TOP, colour(75, 76, 100))
  box(layers.floor, 0, FLOOR_TOP, W, H - FLOOR_TOP, colour(104, 106, 132))
  -- The exit: a dark doorway at the left end.
  box(layers.back, EXIT_RIGHT and (W - DOOR_W) or 2, FLOOR_TOP - 44, DOOR_W - 2, 44, colour(26, 25, 38))
  for _, t in ipairs(THINGS) do
    if t.kind == "object" then
      -- Things that open: a pale cabinet with an ink outline and a lit screen.
      framed(layers.props, t.x, t.y, t.w, t.h, INK, PALE)
      box(layers.props, t.x + 4, t.y + 4, t.w - 8, 12, colour(70, 230, 225))
    elseif t.kind == "show" then
      if t.look == "screen" then
        framed(layers.back, t.x, t.y, t.w, t.h, colour(53, 53, 76), INK)
      elseif t.look == "shelf" then
        framed(layers.back, t.x, t.y, t.w, t.h, colour(74, 46, 31), colour(110, 72, 44))
      else
        framed(layers.back, t.x, t.y, t.w, t.h, colour(53, 53, 76), PALE)
      end
    elseif t.kind == "prop" then
      framed(layers.props, t.x, t.y, t.w, t.h, INK, colour(196, 104, 36))
    end
  end
  -- A crate to jump on: its top face, then its front face.
  local c = CRATE
  box(layers.props, c.x, c.bottom - c.front - c.depth, c.w, c.depth, colour(153, 104, 62))
  box(layers.props, c.x, c.bottom - c.front, c.w, c.front, colour(110, 72, 44))
  box(layers.front, W - 120, 232, 40, 38, colour(26, 25, 38))
end

-- Slices. For a point (spawn), the middle of the bottom edge is the spot.
local function slice(name, sx, sy, w, h, data)
  local s = spr:newSlice(Rectangle(sx, sy, w, h))
  s.name = name
  s.data = data or ""
  return s
end
slice("floor", 0, FLOOR_TOP, W, SAFE_BOTTOM - FLOOR_TOP + 1)
slice("spawn", 28, 196, 8, 2)
slice("exit", EXIT_RIGHT and (W - 12) or 0, FLOOR_TOP, 12, SAFE_BOTTOM - FLOOR_TOP + 1, "to=map")
if PLACEHOLDER then
  for _, t in ipairs(THINGS) do
    slice(t.kind .. ":" .. t.id, t.x, t.y, t.w, t.h, t.data)
  end
  -- A platform slice covers the thing's front face: its top edge is the surface
  -- and its bottom edge is where it meets the floor; `depth` is how far back it goes.
  slice("platform", CRATE.x, CRATE.bottom - CRATE.front, CRATE.w, CRATE.front, "depth=" .. CRATE.depth)
end

spr.frames[1].duration = 0.1
spr:saveAs(OUT)
print("saved " .. OUT)
