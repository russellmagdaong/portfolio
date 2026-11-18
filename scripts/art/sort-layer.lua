-- Moves the pixels of one thing standing out on the floor off a layer (props) onto a layer of its own
-- with `sort=<y>`, so Russell is hidden behind it while his feet are behind that line (art/README.md,
-- "Layers"). Nothing is redrawn: the same pixels move from one layer to the other, and the new layer
-- goes just above the one they came from. Run it on a room's still file (one frame).
--
--   aseprite -b --script-param file=art/scenes/store.aseprite --script-param rect=300,184,38,31
--            --script-param name=boxes --script-param sort=204 [--script-param from=props]
--            --script scripts/art/sort-layer.lua
--
-- Add `--script-param platform=x,y,w,h --script-param depth=10` to also add a `platform` slice.
-- It refuses to run if a layer with that name exists already.

local file = assert(app.params.file, 'pass --script-param file=<.aseprite>')
local name = assert(app.params.name, 'pass --script-param name=<new layer>')
local sort = assert(tonumber(app.params.sort), 'pass --script-param sort=<y>')
local from = app.params.from or 'props'
local function rect(s)
  local x, y, w, h = s:match('^(%-?%d+),(%-?%d+),(%d+),(%d+)$')
  assert(x, 'a rectangle is x,y,w,h: ' .. tostring(s))
  return Rectangle(tonumber(x), tonumber(y), tonumber(w), tonumber(h))
end
local box = rect(assert(app.params.rect, 'pass --script-param rect=x,y,w,h'))

local spr = app.open(file)
assert(spr, 'could not open ' .. file)
assert(#spr.frames == 1, file .. ' has ' .. #spr.frames .. ' frames: run this on the still file')
local src
for _, l in ipairs(spr.layers) do
  assert(l.name ~= name, 'a layer called ' .. name .. ' exists already')
  if l.name == from then src = l end
end
assert(src and src.isImage, 'no image layer called ' .. from)
local cel = assert(src:cel(1), from .. ' is empty')

local old = cel.image
local keep = old:clone()
local out = Image(box.width, box.height, spr.colorMode)
out:clear()
local moved = 0
for y = box.y, box.y + box.height - 1 do
  for x = box.x, box.x + box.width - 1 do
    local ix, iy = x - cel.position.x, y - cel.position.y
    if ix >= 0 and iy >= 0 and ix < old.width and iy < old.height then
      local px = old:getPixel(ix, iy)
      local alpha = spr.colorMode == ColorMode.RGB and app.pixelColor.rgbaA(px) or (px ~= old.spec.transparentColor and 255 or 0)
      if alpha > 0 then
        out:drawPixel(x - box.x, y - box.y, px)
        keep:drawPixel(ix, iy, spr.colorMode == ColorMode.RGB and 0 or old.spec.transparentColor)
        moved = moved + 1
      end
    end
  end
end
assert(moved > 0, 'nothing drawn on ' .. from .. ' inside ' .. app.params.rect)

app.transaction('Sort layer ' .. name, function()
  local layer = spr:newLayer()
  layer.name = name
  layer.data = 'sort=' .. sort
  layer.stackIndex = src.stackIndex + 1
  spr:newCel(layer, 1, out, Point(box.x, box.y))
  cel.image = keep
  if app.params.platform then
    local s = spr:newSlice(rect(app.params.platform))
    s.name = 'platform'
    s.data = 'depth=' .. (app.params.depth or '10')
  end
end)
spr:saveAs(file)
print(('%s: moved %d px from %s to %s (sort=%d)'):format(file, moved, from, name, sort))
