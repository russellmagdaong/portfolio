-- Starts a new scene file with the standard canvas, layers, slices and guide,
-- so every scene is set up the same way (see art/README.md and art/BRIEF.md).
--
--   "C:\aseprite\build\bin\aseprite.exe" -b --script-param name=arcade --script scripts/art/new-scene.lua
--
-- Params:
--   name=<scene>      required; writes art/scenes/<scene>.aseprite
--   width=<px>        the scene's width (default 640, two screens)
--   placeholder=1     fill the layers with flat grey boxes to test the engine
--   out=<file>        write somewhere else instead
-- It never draws over an existing file.

local NAME = assert(app.params["name"], "pass --script-param name=<scene>")
local W = tonumber(app.params["width"] or "640")
local H = 270
local OUT = app.params["out"] or ("art/scenes/" .. NAME .. ".aseprite")
local PLACEHOLDER = app.params["placeholder"] == "1"

-- The canvas is taller than the screen: only the band SAFE_TOP..SAFE_BOTTOM
-- (180 rows) is sure to be seen; the rest shows on wider or taller windows.
local SAFE_TOP, SAFE_BOTTOM = 45, 224
local FLOOR_TOP = 176 -- the floor's back edge; it runs down to SAFE_BOTTOM

local existing = io.open(OUT, "rb")
if existing then
  existing:close()
  error(OUT .. " already exists. Delete or rename it first.")
end

local spr = Sprite(W, H, ColorMode.RGB)
local pal = Palette { fromFile = "art/palette.gpl" }
if pal then spr:setPalette(pal) end

local function colour(r, g, b, a) return Color { r = r, g = g, b = b, a = a or 255 } end
local function box(layer, x, y, w, h, c)
  local image = Image(W, H, ColorMode.RGB)
  for yy = math.max(0, y), math.min(H, y + h) - 1 do
    for xx = math.max(0, x), math.min(W, x + w) - 1 do image:drawPixel(xx, yy, c.rgbaPixel) end
  end
  local cel = layer:cel(1)
  if cel then
    cel.image:drawImage(image, Point(-cel.position.x, -cel.position.y))
  else
    spr:newCel(layer, 1, image, Point(0, 0))
  end
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
for x = 320, W - 1, 320 do box(guide, x, SAFE_TOP, 1, SAFE_BOTTOM - SAFE_TOP + 1, colour(255, 226, 77)) end -- one screen

if PLACEHOLDER then
  box(layers.sky, 0, 0, W, H, colour(23, 20, 51))
  for x = 0, W - 1, 96 do box(layers.far, x, 70, 64, FLOOR_TOP - 70, colour(38, 37, 56)) end
  for x = 40, W - 1, 128 do box(layers.mid, x, 100, 72, FLOOR_TOP - 100, colour(53, 53, 76)) end
  box(layers.back, 0, 120, W, FLOOR_TOP - 120, colour(75, 76, 100))
  box(layers.floor, 0, FLOOR_TOP, W, H - FLOOR_TOP, colour(104, 106, 132))
  box(layers.props, 200, 150, 24, 40, colour(140, 143, 168))
  box(layers.front, W - 120, 210, 40, 60, colour(26, 25, 38))
end

-- Slices. For a point (spawn), the middle of the bottom edge is the spot.
local function slice(name, x, y, w, h, data)
  local s = spr:newSlice(Rectangle(x, y, w, h))
  s.name = name
  s.data = data or ""
  return s
end
slice("floor", 0, FLOOR_TOP, W, SAFE_BOTTOM - FLOOR_TOP + 1)
slice("spawn", 28, 196, 8, 2)
slice("exit", 0, FLOOR_TOP, 16, SAFE_BOTTOM - FLOOR_TOP + 1, "to=map")
if PLACEHOLDER then
  slice("object:sign", 200, 150, 24, 40, "opens=about; prompt=Read")
  slice("platform", 200, 150, 24, 4)
end

spr.frames[1].duration = 0.1
spr:saveAs(OUT)
print("saved " .. OUT)
