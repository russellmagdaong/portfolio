-- Draws art/font.aseprite: the sign lettering as a font (scripts/art/font/build.mjs turns it into
-- src/assets/fonts/russm-sign.woff2 with `npm run font`).
--
-- A to Z are the 5x7 capitals of the shop signs, unchanged (M.big in common.lua, the large set in
-- art/lettering.aseprite). The digits and marks are drawn here in the same style: one-pixel
-- strokes, a corner pixel knocked off for curves, open bowls. Each glyph is drawn from its cell's
-- top-left at its own width; rows 1-7 are the capitals, row 8 the one row of descent (, ;).
-- Grid: 16 columns of 8 x 9 px cells, in the order of scripts/art/font/chars.txt.
--
-- Run once to create the file; after that it is Russell's to edit by hand. Re-running replaces it.
local m = dofile('scripts/art/draw/common.lua')

local MARKS = {
  ['0'] = '01110/10001/10011/10101/11001/10001/01110',
  ['1'] = '010/110/010/010/010/010/111',
  ['2'] = '01110/10001/00001/00010/00100/01000/11111',
  ['3'] = '11110/00001/00001/01110/00001/00001/11110',
  ['4'] = '10001/10001/10001/11111/00001/00001/00001',
  ['5'] = '11111/10000/10000/11110/00001/00001/11110',
  ['6'] = '01110/10000/10000/11110/10001/10001/01110',
  ['7'] = '11111/00001/00010/00100/00100/00100/00100',
  ['8'] = '01110/10001/10001/01110/10001/10001/01110',
  ['9'] = '01110/10001/10001/01111/00001/00001/01110',
  ['.'] = '0/0/0/0/0/0/1',
  [','] = '00/00/00/00/00/00/01/10',
  ["'"] = '1/1/0/0/0/0/0',
  ['’'] = '01/01/10/00/00/00/00',
  [':'] = '0/0/1/0/0/1/0',
  [';'] = '00/00/01/00/00/01/01/10',
  ['-'] = '000/000/000/111/000/000/000',
  ['–'] = '00000/00000/00000/11111/00000/00000/00000',
  ['!'] = '1/1/1/1/1/0/1',
  ['?'] = '01110/10001/00001/00010/00100/00000/00100',
  ['&'] = '01100/10010/10100/01000/10101/10010/01101',
  ['/'] = '00001/00001/00010/00100/01000/10000/10000',
  ['·'] = '0/0/0/1/0/0/0',
  ['('] = '01/10/10/10/10/10/01',
  [')'] = '10/01/01/01/01/01/10',
  ['"'] = '101/101/000/000/000/000/000',
}

local f = io.open('scripts/art/font/chars.txt', 'rb')
local chars = f:read('l')
f:close()

local count = 0
for _ in utf8.codes(chars) do count = count + 1 end
local rows = (count + 15) // 16

local sprite = Sprite(16 * 8, rows * 9, ColorMode.RGB)
sprite:setPalette(Palette { fromFile = 'art/palette.gpl' })
sprite.layers[1].name = 'glyphs'
local pen = m.pen(m.canvas(sprite, sprite.layers[1]))

local i = 0
for _, code in utf8.codes(chars) do
  local ch = utf8.char(code)
  local glyph = m.big[ch] or MARKS[ch]
  if not glyph then error('no glyph drawn for ' .. ch) end
  local cx, cy = (i % 16) * 8, (i // 16) * 9
  local y = 0
  for row in glyph:gmatch('[^/]+') do
    for x = 1, #row do
      if row:sub(x, x) == '1' then pen.rect(cx + x - 1, cy + y, 1, 1, 'sodium 4') end
    end
    y = y + 1
  end
  i = i + 1
end

sprite:saveAs('art/font.aseprite')
sprite:close()
