-- Prints frames of a sprite as `full` entries for russell-fixes.lua, so that
-- frames edited by hand in Aseprite survive the next build.
--
--   "C:\aseprite\build\bin\aseprite.exe" -b ^
--     --script-param file=<abs path>\art\russell.aseprite ^
--     --script-param frames=jump:1,jump:6 ^
--     --script scripts/sprite/frame-to-fix.lua
--
-- The letters are the palette letters of build-russell.lua (index 1..17).

local spr = Sprite { fromFile = app.params["file"] }
local LETTERS = { [0] = ".", "K", "h", "H", "s", "S", "d", "D", "l", "P", "r", "R", "k", "Q", "b", "B", "g", "W" }

local function flatten(n)
  local im = Image(spr.width, spr.height, ColorMode.INDEXED)
  for _, layer in ipairs(spr.layers) do
    local cel = layer:cel(n)
    if cel and layer.isVisible then
      for it in cel.image:pixels() do
        local v = it()
        if v ~= 0 then im:drawPixel(it.x + cel.position.x, it.y + cel.position.y, v) end
      end
    end
  end
  return im
end

for move, k in string.gmatch(app.params["frames"], "([%a_]+):(%d+)") do
  local tag
  for _, t in ipairs(spr.tags) do if t.name == move then tag = t end end
  if not tag then error("no tag named " .. move) end
  local im = flatten(tag.fromFrame.frameNumber + tonumber(k) - 1)
  local x0, y0, x1, y1 = spr.width, spr.height, -1, -1
  for y = 0, spr.height - 1 do
    for x = 0, spr.width - 1 do
      if im:getPixel(x, y) ~= 0 then
        x0 = math.min(x0, x); x1 = math.max(x1, x); y0 = math.min(y0, y); y1 = math.max(y1, y)
      end
    end
  end
  print(('  ["%s:%s"] = {'):format(move, k))
  print(("    full = { %d, %d, {"):format(x0, y0))
  for y = y0, y1 do
    local row = ""
    for x = x0, x1 do
      local letter = LETTERS[im:getPixel(x, y)]
      if not letter then error(("%s:%s has a colour outside the palette at %d,%d"):format(move, k, x, y)) end
      row = row .. letter
    end
    print(('      "%s", -- %d'):format(row, y))
  end
  print("    } },")
  print("  },")
end
