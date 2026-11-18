-- The interactable objects of the scenes, each in its own file:
--   art/objects/<scene>/<id>.aseprite, one per object:<id> or prop:<id> slice of art/scenes/<scene>.aseprite.
--
-- They used to be painted on the scene's `props` layer. `cut` takes each one off that layer (the pixels
-- inside its box below) and, the first time only, saves them as the object's own sprite. Once a file
-- exists it is never written again, so edits made in Aseprite are safe; `cut` still clears the box from
-- the scene, so redrawing a scene with scripts/art/draw/<scene>.lua never paints the object in twice.
--
-- Each object file has a `base` slice: the bottom edge of its slice in the scene. The game stands the
-- sprite with the middle of `base` on the middle of that slice's bottom edge, so the canvas can be
-- grown or shrunk freely (Sprite > Canvas Size moves the slice along). Tags: `idle`, and optionally
-- `hover` (played while it is pointed at or in reach).
--
-- Used by scripts/art/split-objects.lua and at the end of the scenes' draw scripts.

local M = {}

-- Per scene: the slice, then the box of scene pixels that belong to it (x, y, width, height). Boxes are
-- cut in this order; a pixel already taken by an earlier box stays with it.
M.boxes = {
  home = {
    { 'object:mirror', 160, 138, 38, 48 },  -- the glass, the frame, its foot and its two feet
    { 'prop:guitar',   434, 146, 30, 36 },  -- the guitar on its stand, the cable and the amp
    { 'prop:console',  466, 166, 28, 16 },  -- the console on its low table
    { 'prop:camera',   498, 154, 16, 29 },  -- the camera on its tripod
    { 'prop:trophy',   538, 162, 18, 20 },  -- the trophy on its stool
    { 'prop:flag',     520, 141, 19, 41 },  -- the flag, its pole and its foot
  },
  arcade = {
    { 'object:odin',      64, 142, 30, 40 },
    { 'object:tako',     124, 142, 30, 40 },
    { 'object:algebrawl', 184, 142, 30, 40 },
    { 'object:nova',     464, 142, 26, 40 },
  },
  school = {
    { 'prop:thesis', 500, 112, 20, 21 },  -- the thesis, face-out on the bookshelf
  },
  ['post-office'] = {
    { 'object:counter', 152, 141, 48, 41 },  -- the counter and the things on it
  },
}

-- Room round the object in a new file, so there is space to draw into.
local PAD = 4

local function find(list, name)
  for _, item in ipairs(list) do if item.name == name then return item end end
end

local function blank(img, x, y)
  return x < 0 or y < 0 or x >= img.width or y >= img.height
end

-- Takes the scene's objects off its `props` layer, making any object file that does not exist yet.
-- Returns the number of files made.
function M.cut(s, scene)
  local boxes = M.boxes[scene]
  if not boxes then return 0 end
  local props = find(s.layers, 'props')
  if not props then error('art/scenes/' .. scene .. '.aseprite has no props layer') end
  local made = 0
  local taken = {}
  for _, b in ipairs(boxes) do
    local name, bx, by, bw, bh = b[1], b[2], b[3], b[4], b[5]
    local slice = find(s.slices, name)
    if not slice then error('art/scenes/' .. scene .. '.aseprite has no slice ' .. name) end
    local id = name:match(':(.+)$')
    local path = 'art/objects/' .. scene .. '/' .. id .. '.aseprite'

    -- The object's pixels, from the first frame of the props layer.
    local cel = props:cel(1)
    if not app.fs.isFile(path) then
      local o = Sprite(bw + PAD * 2, bh + PAD * 2, ColorMode.RGB)
      o:setPalette(s.palettes[1])
      local img = Image(o.width, o.height, ColorMode.RGB)
      if cel then
        for y = by, by + bh - 1 do
          for x = bx, bx + bw - 1 do
            local key = x .. ',' .. y
            if not taken[key] then
              local ix, iy = x - cel.position.x, y - cel.position.y
              if not blank(cel.image, ix, iy) then
                local px = cel.image:getPixel(ix, iy)
                if app.pixelColor.rgbaA(px) > 0 then img:drawPixel(x - bx + PAD, y - by + PAD, px) end
              end
            end
          end
        end
      end
      o.layers[1].name = id
      o:newCel(o.layers[1], 1, img, Point(0, 0))
      local tag = o:newTag(1, 1); tag.name = 'idle'
      -- `base`: where the bottom of the slice in the scene falls in this file.
      local base = o:newSlice(Rectangle(slice.bounds.x - bx + PAD, slice.bounds.y + slice.bounds.height - 1 - by + PAD, slice.bounds.width, 1))
      base.name = 'base'
      app.fs.makeAllDirectories(app.fs.filePath(path))
      o:saveAs(path)
      o:close()
      made = made + 1
      print('  made ' .. path)
    end
    for y = by, by + bh - 1 do for x = bx, bx + bw - 1 do taken[x .. ',' .. y] = true end end
  end

  -- Clear every box from the props layer, on every frame (cels may differ or be linked).
  local done = {}
  for _, frame in ipairs(s.frames) do
    local cel = props:cel(frame.frameNumber)
    if cel and not done[cel.image.id] then
      local img = cel.image:clone()
      local clear = app.pixelColor.rgba(0, 0, 0, 0)
      for _, b in ipairs(boxes) do
        for y = b[3], b[3] + b[5] - 1 do
          for x = b[2], b[2] + b[4] - 1 do
            local ix, iy = x - cel.position.x, y - cel.position.y
            if not blank(img, ix, iy) then img:drawPixel(ix, iy, clear) end
          end
        end
      end
      local id = cel.image.id
      cel.image = img
      done[id] = true
      done[cel.image.id] = true
    end
  end
  return made
end

return M
