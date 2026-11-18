-- The icon on each shop's sign (house, book, joystick, monitor, trophy, envelope), cut from its
-- shopfront in art/hub-objects/<id>.aseprite (frame 0) for the text version's sidebar and panel
-- signs. Run by scripts/art/export.mjs after the shopfronts are exported:
--   aseprite -b --script-param root=<repo> --script-param out=<dir> --script scripts/art/sign-logos.lua
--
-- Each box below sits between the sign's top border and its word. Inside it, the icon's pixels are
-- the bright ones (the sign's ink is dark); they are kept and trimmed to their bounding box.
local boxes = {
  { id = "home", x = 51, y = 12, w = 14 },
  { id = "school", x = 20, y = 9, w = 9 },
  { id = "arcade", x = 16, y = 9, w = 14 },
  { id = "store", x = 16, y = 9, w = 14 },
  { id = "trophy-shop", x = 16, y = 9, w = 14 },
  { id = "post-office", x = 16, y = 9, w = 14 },
}
local H = 8
local root = app.params["root"]
local out = app.params["out"]

for _, b in ipairs(boxes) do
  local spr = app.open(root .. "/art/hub-objects/" .. b.id .. ".aseprite")
  local img = Image(spr.spec)
  img:drawSprite(spr, 1)
  local icon = Image(b.w, H, ColorMode.RGB)
  local x0, y0, x1, y1 = b.w, H, -1, -1
  for y = 0, H - 1 do
    for x = 0, b.w - 1 do
      local px = Color(img:getPixel(b.x + x, b.y + y))
      local lum = 0.299 * px.red + 0.587 * px.green + 0.114 * px.blue
      if px.alpha > 0 and lum > 45 then
        icon:drawPixel(x, y, px)
        if x < x0 then x0 = x end
        if y < y0 then y0 = y end
        if x > x1 then x1 = x end
        if y > y1 then y1 = y end
      end
    end
  end
  if x1 < 0 then error(b.id .. ": no icon pixels in its box") end
  Image(icon, Rectangle(x0, y0, x1 - x0 + 1, y1 - y0 + 1)):saveAs(out .. "/" .. b.id .. ".png")
  spr:close()
end
