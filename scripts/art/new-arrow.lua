-- Draws the first version of art/arrow.aseprite: the marker over the spot
-- Russell is running to after a click. Once the file exists it is the source
-- of truth and is edited in Aseprite; this script never draws over it.
--
--   "C:\aseprite\build\bin\aseprite.exe" -b --script scripts/art/new-arrow.lua
--
-- What the engine reads from the file (src/game/scene.ts):
--   tag `bob`      the animation it plays while he is on his way (its frame
--                  durations are the speed; with reduced motion only frame 1 shows)
--   slice `base`   the middle of its bottom edge sits on the spot on the floor

local OUT = app.params["out"] or "art/arrow.aseprite"
local f = io.open(OUT, "rb")
if f then
  f:close()
  error(OUT .. " already exists. Delete or rename it first.")
end

local W, H = 13, 18
local MID = 6                    -- the column the arrow points down
local BOB = { 0, 1, 2, 1 }       -- how far the arrow is lowered in each frame
local FRAME_MS = 140

local INK = Color { r = 13, g = 11, b = 26 }
local YELLOW = Color { r = 255, g = 226, b = 77 }
local DIM = Color { r = 150, g = 120, b = 30 }

local spr = Sprite(W, H, ColorMode.RGB)
local pal = Palette { fromFile = "art/palette.gpl" }
if pal then spr:setPalette(pal) end
local arrowLayer = spr.layers[1]
arrowLayer.name = "arrow"
local markLayer = spr:newLayer()
markLayer.name = "floor mark"
spr:newFrame() spr:newFrame() spr:newFrame()

local function row(image, y, x0, x1, c)
  for x = x0, x1 do image:drawPixel(x, y, c.rgbaPixel) end
end

-- A downward arrow, five rows narrowing to a point, with a one-pixel ink outline.
local WIDTHS = { 9, 7, 5, 3, 1 }
for i, drop in ipairs(BOB) do
  local image = Image(W, H, ColorMode.RGB)
  local top = 2 + drop
  row(image, top - 1, MID - 5, MID + 5, INK)
  for r, w in ipairs(WIDTHS) do
    local half = (w - 1) // 2
    local y = top + r - 1
    row(image, y, MID - half - 1, MID + half + 1, INK)
    row(image, y, MID - half, MID + half, YELLOW)
  end
  image:drawPixel(MID, top + #WIDTHS, INK.rgbaPixel)
  spr:newCel(arrowLayer, i, image, Point(0, 0))
  spr.frames[i].duration = FRAME_MS / 1000
end

-- Two dashes on the floor either side of the spot; the same in every frame.
local mark = Image(W, H, ColorMode.RGB)
row(mark, H - 1, MID - 3, MID - 2, DIM)
row(mark, H - 1, MID + 2, MID + 3, DIM)
for i = 1, #BOB do spr:newCel(markLayer, i, mark, Point(0, 0)) end

local tag = spr:newTag(1, #BOB)
tag.name = "bob"
local base = spr:newSlice(Rectangle(MID, H - 1, 1, 1))
base.name = "base"

spr:saveAs(OUT)
print("saved " .. OUT)
