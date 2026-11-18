-- A room's still art and its animation, in two files, so the still part can be edited once instead of
-- on every frame:
--
--   art/scenes/<scene>.aseprite (or art/hub.aseprite)   one frame: every layer that does not move, and
--                                                        the slices. This is the file to edit.
--   art/anim/<scene>.aseprite   (or art/anim/hub.aseprite)  only the layers that move (rain, lights,
--                                                        the jeepney...), with all their frames.
--
-- Each layer in the anim file says where it goes among the room's layers with `after=<layer below it>`
-- in its user data. `npm run art` puts the two back together (M.combine) before exporting, so the game
-- gets the same layers as before.
--
-- M.split turns one full, animated file into the two (scripts/art/split-stills.lua, and K.save in
-- scripts/art/draw/kit.lua after a draw script redraws a room).

local M = {}

local function samePlace(a, b)
  return a.position.x == b.position.x and a.position.y == b.position.y
end

-- Whether a layer changes from frame to frame.
local function moves(layer, frames)
  local first = layer:cel(1)
  for f = 2, frames do
    local cel = layer:cel(f)
    if (cel == nil) ~= (first == nil) then return true end
    if cel and not (samePlace(cel, first) and cel.image:isEqual(first.image)) then return true end
  end
  return false
end

-- `after=<name>` out of a layer's user data: returns the rest of the data, and the name.
local function takeAfter(data)
  local after
  local rest = {}
  for part in (data or ''):gmatch('[^;\n]+') do
    local value = part:match('^%s*after%s*=%s*(.-)%s*$')
    if value then after = value else
      local trimmed = part:match('^%s*(.-)%s*$')
      if trimmed ~= '' then rest[#rest + 1] = trimmed end
    end
  end
  return table.concat(rest, '; '), after
end

-- Splits a full room file: writes art/anim/<name>.aseprite and rewrites the room file as its one
-- still frame. Returns the number of moving layers (0 leaves both files alone).
function M.split(path, name)
  local s = app.open(path)
  if not s then error('cannot open ' .. path) end
  local n = #s.frames
  local moving = {}
  if n > 1 then
    for i, layer in ipairs(s.layers) do
      if not layer.isGroup and layer.name:sub(1, 1) ~= '_' and moves(layer, n) then moving[#moving + 1] = i end
    end
  end
  if #moving == 0 then
    s:close()
    return 0
  end

  -- The anim file: the moving layers, each with the layer that was below it.
  local a = Sprite(s.width, s.height, ColorMode.RGB)
  a:setPalette(s.palettes[1])
  for f = 2, n do a:newEmptyFrame(f) end
  for f = 1, n do a.frames[f].duration = s.frames[f].duration end
  local placeholder = a.layers[1]
  for _, i in ipairs(moving) do
    local layer = s.layers[i]
    local copy = a:newLayer()
    copy.name = layer.name
    local data = takeAfter(layer.data)
    local below = i > 1 and s.layers[i - 1].name or ''
    copy.data = (data ~= '' and (data .. '; ') or '') .. 'after=' .. below
    copy.opacity = layer.opacity
    copy.blendMode = layer.blendMode
    for f = 1, n do
      local cel = layer:cel(f)
      if cel then a:newCel(copy, f, cel.image, cel.position) end
    end
  end
  a:deleteLayer(placeholder)
  local animPath = 'art/anim/' .. name .. '.aseprite'
  app.fs.makeAllDirectories(app.fs.filePath(animPath))
  a:saveAs(animPath)
  a:close()

  -- The room file: the still layers, one frame.
  for k = #moving, 1, -1 do s:deleteLayer(s.layers[moving[k]]) end
  for f = n, 2, -1 do s:deleteFrame(f) end
  s:saveAs(path)
  s:close()
  print(('  %s: %d moving layer(s) to %s; %s is one still frame'):format(name, #moving, animPath, path))
  return #moving
end

-- Puts a room's still file and its anim file back together, saved as `out` (for the export).
function M.combine(stillPath, animPath, out)
  local s = app.open(stillPath)
  if not s then error('cannot open ' .. stillPath) end
  local a = app.open(animPath)
  if not a then error('cannot open ' .. animPath) end
  if #s.frames > 1 then
    error(stillPath .. ' has ' .. #s.frames .. ' frames: keep it to one, and put what moves in ' .. animPath)
  end
  local n = #a.frames
  for f = 2, n do s:newFrame(f - 1) end
  for f = 1, n do s.frames[f].duration = a.frames[f].duration end
  for _, layer in ipairs(a.layers) do
    if not layer.isGroup and layer.name:sub(1, 1) ~= '_' then
      local data, after = takeAfter(layer.data)
      local copy = s:newLayer()
      copy.name = layer.name
      copy.data = data
      copy.opacity = layer.opacity
      copy.blendMode = layer.blendMode
      copy.isVisible = layer.isVisible
      if after == '' then
        copy.stackIndex = 1
      elseif after then
        local target
        for _, l in ipairs(s.layers) do if l.name == after and l ~= copy then target = l end end
        if target then copy.stackIndex = target.stackIndex + 1
        else print('  note: ' .. animPath .. ' layer `' .. layer.name .. '` goes after `' .. after .. '`, which is not in the room; it was put on top') end
      end
      for f = 1, n do
        local cel = layer:cel(f)
        if cel then s:newCel(copy, f, cel.image, cel.position) end
      end
    end
  end
  app.fs.makeAllDirectories(app.fs.filePath(out))
  s:saveCopyAs(out)
  s:close()
  a:close()
end

return M
