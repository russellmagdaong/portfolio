-- Splits rooms into a still file and an anim file (see scripts/art/stills.lua).
--
--   aseprite -b --script-param name=home --script scripts/art/split-stills.lua
--   aseprite -b --script scripts/art/split-stills.lua        (every scene, and the hub)
--
-- A room that is already one frame is left alone.

local stills = dofile('scripts/art/stills.lua')

local function pathOf(name)
  return name == 'hub' and 'art/hub.aseprite' or ('art/scenes/' .. name .. '.aseprite')
end

local names = {}
if app.params.name and app.params.name ~= '' then
  names[1] = app.params.name
else
  for _, file in ipairs(app.fs.listFiles('art/scenes')) do
    local name = file:match('^(.+)%.aseprite$')
    if name then names[#names + 1] = name end
  end
  table.sort(names)
  names[#names + 1] = 'hub'
end

for _, name in ipairs(names) do
  if stills.split(pathOf(name), name) == 0 then print('  ' .. name .. ': nothing moves, or already split') end
end
