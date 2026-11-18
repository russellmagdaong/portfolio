-- Reads the glyphs out of art/font.aseprite for scripts/art/font/build.mjs (npm run font).
-- The file is a grid of 16 columns of 8 x 9 px cells, one glyph per cell in the order of
-- chars.txt, each drawn from the cell's top-left: rows 0-6 are the capitals, row 7 the one row
-- of descent. Any opaque pixel is ink. Writes {"<char>": ["0110...", ...8 rows]} to $FONT_JSON.
local out = os.getenv('FONT_JSON')
if not out then error('set FONT_JSON to the file to write') end

local f = io.open('scripts/art/font/chars.txt', 'rb')
local chars = f:read('l')
f:close()

local sprite = app.open('art/font.aseprite')
local image = Image(sprite.width, sprite.height, ColorMode.RGB)
image:drawSprite(sprite, 1)

local function json(ch)
  if ch == '"' or ch == '\\' then return '"\\' .. ch .. '"' end
  return '"' .. ch .. '"'
end

local entries, i = {}, 0
for _, code in utf8.codes(chars) do
  local cx, cy = (i % 16) * 8, (i // 16) * 9
  local rows = {}
  for y = 0, 7 do
    local row = {}
    for x = 0, 7 do
      local inside = cx + x < image.width and cy + y < image.height
      local alpha = inside and app.pixelColor.rgbaA(image:getPixel(cx + x, cy + y)) or 0
      row[#row + 1] = alpha > 0 and '1' or '0'
    end
    rows[#rows + 1] = '"' .. table.concat(row) .. '"'
  end
  entries[#entries + 1] = json(utf8.char(code)) .. ':[' .. table.concat(rows, ',') .. ']'
  i = i + 1
end
sprite:close()

local file = io.open(out, 'wb')
file:write('{' .. table.concat(entries, ',\n') .. '}\n')
file:close()
