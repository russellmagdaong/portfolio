-- Puts a room's still file and its anim file together for the export (scripts/art/export.mjs runs it).
--
--   aseprite -b --script-param still=<.aseprite> --script-param anim=<.aseprite> --script-param out=<.aseprite>
--            --script scripts/art/combine-stills.lua

local stills = dofile('scripts/art/stills.lua')
local still = assert(app.params.still, 'pass --script-param still=<.aseprite>')
local anim = assert(app.params.anim, 'pass --script-param anim=<.aseprite>')
local out = assert(app.params.out, 'pass --script-param out=<.aseprite>')
stills.combine(still, anim, out)
print('COMBINE-OK')
