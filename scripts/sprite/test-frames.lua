-- Phase 1 test frames: Russell's look painted over two frames of the Ozzbit
-- "male hero" template (idle frame 1 and walk frame 6).
--
-- Output: an indexed .aseprite with
--   layer "russell"   the repaint
--   layer "template"  the original template frame, hidden, as a guide
-- Because of the guide layer the output must stay in the git-ignored
-- art/_work/ folder.
--
-- Run from the repo root:
--   "C:\aseprite\build\bin\aseprite.exe" -b ^
--     --script-param out=<absolute path to .aseprite> ^
--     --script scripts/sprite/test-frames.lua

local TEMPLATE_DIR = app.params["template"]
  or [[C:\RUSSDM\Projects\GameDev_Templates\template_pro\individual_sheets]]
local OUT = app.params["out"]
if not OUT then error("pass --script-param out=<path to .aseprite>") end

local CELL = 128

-- Palette, taken from the photo and pushed a little brighter and more
-- saturated so it holds up at 1x on a night street.
-- Index 0 is transparent. The letter is what the frame grids below use.
local PALETTE = {
  { "K", "outline",      0x00, 0x00, 0x00 },
  { "h", "hair",         0x1c, 0x1a, 0x23 },
  { "H", "hair light",   0x3a, 0x35, 0x45 },
  { "s", "skin",         0xdb, 0xa2, 0x84 },
  { "S", "skin shadow",  0xad, 0x76, 0x58 },
  { "d", "denim",        0x3c, 0x61, 0x98 },
  { "D", "denim dark",   0x26, 0x3f, 0x6c },
  { "l", "denim light",  0x5c, 0x83, 0xb8 },
  { "P", "pale steel",   0xc5, 0xcf, 0xdb }, -- pocket patch, earring, chain
  { "r", "rust",         0xc8, 0x64, 0x2e },
  { "R", "rust dark",    0x83, 0x3b, 0x1d },
  { "k", "khaki",        0xdc, 0xbb, 0x85 },
  { "Q", "khaki shadow", 0xb2, 0x94, 0x60 },
  { "b", "shoe",         0x46, 0x29, 0x1f },
  { "B", "shoe light",   0x6a, 0x42, 0x30 },
  { "g", "gold",         0xdc, 0xb5, 0x5a },
}

-- Each frame: which template sheet and column it sits over, where the grid's
-- top-left corner goes in the 128x128 cell, and the pixels.
local FRAMES = {
  {
    tag = "idle", sheet = "idle", col = 0, x0 = 52, y0 = 47,
    rows = {
      ".........KKK..........", -- 47
      ".......KKhhhKKK.......",
      "......KhhHhhhhhK......",
      ".....KhhHhhhHhHhK.....", -- 50
      ".....KhHhhhHhhhHK.....",
      ".....KhhhhHhhhhhK.....",
      ".....KhhhhHhssshK.....",
      "......KhhhsKKssKK.....",
      "......KhhSsKKssKK.....", -- 55
      "......KHhPsssssSK.....",
      ".....KHhhKSsssSK......",
      "......KKKddrSSrdK.....",
      ".....KKldddDrSrDK.....",
      "....KldddddDrPrDKK....", -- 60
      "...KlddddddDrrRDKK....",
      "...KlddDKddDRrrDKDK...",
      "..KlddDKKddDrrrDKDK...",
      "..KldDK..KdDrRrDKDK...",
      "..KldDK..KdDrrRlKDDK..", -- 65
      ".KldddDK.KdDRrrPlKDK..",
      ".KddddDKKddDrRrDPKSK..",
      ".KssssSKKdddDrrDDKSK..",
      ".KsssSsKKkkkkkQQQKK...",
      "..KssSKKkkkkkQQQQQK...", -- 70
      "...KKKKkkkkQKKQQQQK...",
      "......KkkkQKKKQQQQK...",
      ".....KkkkQK..KQQQQK...",
      "....KkkkkQK..KQQQQK...",
      "...KkkkkQK...KQQQQK...", -- 75
      "...KkkkkQK...KQQQQK...",
      "..KkkkkQK....KQQQBBK..",
      "..KBBBgBK....KBBBgBBK.",
      "..KbbbbbK....KbbbbbbK.", -- 79
    },
  },
  {
    tag = "walk", sheet = "walk", col = 5, x0 = 53, y0 = 48,
    rows = {
      "..........KKK...........", -- 48
      "........KKhhhKKK........",
      ".......KhhHhhhhhK.......", -- 50
      "......KhhHhhhHhHhK......",
      "......KhHhhhHhhhHK......",
      "......KhhhhHhhhhhK......",
      "......KhhhhHhssshK......",
      ".......KhhhsKKssKK......", -- 55
      ".......KhhSsKKssKK......",
      ".......KHhPsssssSK......",
      "......KHhhKSsssSK.......",
      ".......KldKKKKKKK.......",
      "......KlddDKdSrKDK......", -- 60
      ".....KldddDKdrPDKK......",
      "....KldddDKdDrrDKK......",
      "....KlddDKddDRrDKDK.....",
      "...KldddDKddDrrDKDDKK...",
      "...KlddDKKddDrRDKDDDDK..", -- 65
      "...KlddDKKddDRrPKDDDSSK.",
      "...KddddDKddDrrlKDDDSSK.",
      "...KssssSKddDrRDKDDSSSK.",
      "...KsssSsKdddDrkKKDSSK..",
      "....KssSKKkkkkkkQKKKK...", -- 70
      ".....KKKKQKKkkkkkQK.....",
      ".......KQQQQKkkkkQK.....",
      "......KQQQQQQKkkkkQK....",
      "....KKQQQQQQKKkkkkQK....",
      "...KQQQQQQQK.KkkkkQK....", -- 75
      "..KQQQQQQQK...KkkkQK....",
      ".KQQQQQQQK....KkkQBBK...",
      ".KBBBBBBK.....KBBBgBBK..",
      ".KbbbbbK......KbbbbbbK..", -- 79
    },
  },
}

---------------------------------------------------------------------------

local pc = app.pixelColor

-- Load one 128x128 cell of a template sheet as an RGB image.
local function loadTemplateCell(sheet, col)
  local path = TEMPLATE_DIR .. "\\male_hero_template-" .. sheet .. ".png"
  local s = Sprite { fromFile = path }
  if not s then error("cannot open " .. path) end
  if s.colorMode ~= ColorMode.RGB then
    app.sprite = s
    app.command.ChangePixelFormat { format = "rgb" }
  end
  local full = Image(s.spec)
  full:drawSprite(s, 1)
  s:close()
  local cell = Image(CELL, CELL, ColorMode.RGB)
  cell:drawImage(full, Point(-col * CELL, 0))
  return cell
end

-- Gather the template cells and their colours first, so the palette can be
-- built in one go: ours, then the template's own colours after it.
local templateCells = {}
local templateColours, templateIndex = {}, {}
for i, f in ipairs(FRAMES) do
  local cell = loadTemplateCell(f.sheet, f.col)
  templateCells[i] = cell
  for y = 0, CELL - 1 do
    for x = 0, CELL - 1 do
      local p = cell:getPixel(x, y)
      if pc.rgbaA(p) > 0 then
        local key = pc.rgbaR(p) * 65536 + pc.rgbaG(p) * 256 + pc.rgbaB(p)
        if not templateIndex[key] then
          templateColours[#templateColours + 1] = key
          templateIndex[key] = #PALETTE + #templateColours
        end
      end
    end
  end
end

local spr = Sprite(CELL, CELL, ColorMode.INDEXED)
local pal = Palette(1 + #PALETTE + #templateColours)
pal:setColor(0, Color { r = 0, g = 0, b = 0, a = 0 })
local letterIndex = { ["."] = 0 }
for i, c in ipairs(PALETTE) do
  pal:setColor(i, Color { r = c[3], g = c[4], b = c[5], a = 255 })
  letterIndex[c[1]] = i
end
for i, key in ipairs(templateColours) do
  pal:setColor(#PALETTE + i, Color {
    r = key // 65536, g = (key // 256) % 256, b = key % 256, a = 255 })
end
spr:setPalette(pal)
spr.transparentColor = 0

local templateLayer = spr.layers[1]
templateLayer.name = "template"
templateLayer.data = "Ozzbit Games male hero template. Guide only: never commit a file that has this layer."
local artLayer = spr:newLayer()
artLayer.name = "russell"

for i, f in ipairs(FRAMES) do
  if i > 1 then spr:newEmptyFrame(i) end

  local guide = Image(CELL, CELL, ColorMode.INDEXED)
  local cell = templateCells[i]
  for y = 0, CELL - 1 do
    for x = 0, CELL - 1 do
      local p = cell:getPixel(x, y)
      if pc.rgbaA(p) > 0 then
        local key = pc.rgbaR(p) * 65536 + pc.rgbaG(p) * 256 + pc.rgbaB(p)
        guide:drawPixel(x, y, templateIndex[key])
      end
    end
  end

  local art = Image(CELL, CELL, ColorMode.INDEXED)
  local width = #f.rows[1]
  for r, row in ipairs(f.rows) do
    if #row ~= width then
      error(string.format("%s: row %d is %d wide, expected %d", f.tag, f.y0 + r - 1, #row, width))
    end
    for c = 1, #row do
      local ch = row:sub(c, c)
      local idx = letterIndex[ch]
      if idx == nil then
        error(string.format("%s: unknown letter '%s' in row %d", f.tag, ch, f.y0 + r - 1))
      end
      if idx > 0 then art:drawPixel(f.x0 + c - 1, f.y0 + r - 1, idx) end
    end
  end

  -- How far the repaint strays from the template's silhouette.
  local added, dropped = 0, 0
  for y = 0, CELL - 1 do
    for x = 0, CELL - 1 do
      local a, g = art:getPixel(x, y) ~= 0, guide:getPixel(x, y) ~= 0
      if a and not g then added = added + 1 end
      if g and not a then dropped = dropped + 1 end
    end
  end
  print(string.format("%s (template %s frame %d): %d px outside the template outline, %d template px left empty",
    f.tag, f.sheet, f.col + 1, added, dropped))

  spr:newCel(templateLayer, i, guide, Point(0, 0))
  spr:newCel(artLayer, i, art, Point(0, 0))
  spr.frames[i].duration = 0.1
end

-- Tags go on once every frame exists: a frame added right after a tag's last
-- frame would stretch the tag over it.
for i, f in ipairs(FRAMES) do
  local tag = spr:newTag(i, i)
  tag.name = f.tag
end

templateLayer.isVisible = false
app.sprite = spr
app.layer = artLayer
spr:saveAs(OUT)
print("saved " .. OUT)
