-- Splits the interactable objects out of the scenes (see scripts/art/objects.lua).
--
--   aseprite -b --script-param scene=home --script scripts/art/split-objects.lua
--   aseprite -b --script scripts/art/split-objects.lua          (every scene that has objects)
--
-- Makes art/objects/<scene>/<id>.aseprite for each object that has no file yet, and takes the objects
-- off the scene's props layer. Existing object files are left as they are.

local objects = dofile('scripts/art/objects.lua')

local scenes = {}
if app.params.scene and app.params.scene ~= '' then
  scenes[1] = app.params.scene
else
  for scene in pairs(objects.boxes) do scenes[#scenes + 1] = scene end
  table.sort(scenes)
end

for _, scene in ipairs(scenes) do
  local path = 'art/scenes/' .. scene .. '.aseprite'
  local s = app.open(path)
  if not s then error('cannot open ' .. path) end
  local made = objects.cut(s, scene)
  s:saveAs(path)
  s:close()
  print(('%s: %d object file(s) made, objects cleared from its props layer'):format(scene, made))
end
