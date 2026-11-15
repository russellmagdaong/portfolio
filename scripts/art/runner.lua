-- Turns art/russell.aseprite into the sprite sheet the runner minigame uses
-- (src/components/Runner.astro). Run it from the repo root whenever the
-- sprite changes:
--
--   npm run art -- russell        (or, without npm:)
--   "C:\aseprite\build\bin\aseprite.exe" -b --script scripts/art/runner.lua
--
-- Each of the game's animations becomes one row of
-- src/assets/runner/russell.png, a frame per column, cropped to the space he
-- actually uses. russell.json beside it records the frame size, where he
-- stands in a frame, the length and speed of each row, and the two hit boxes.
--
-- Everything is read from the Aseprite file, so it can be tuned there:
--   tags              the moves (idle, run, jump, fall, fall_loop, slide, death)
--   frame durations   the speed of each row (taken from its first frame)
--   slice `feet`      its bottom edge is the ground, its middle is where he stands
--   slice `body`      the hit box while he is up
--   slice `slide`     the hit box while he slides
-- Optional: --script-param file=<sprite> --script-param out=<folder>

local FILE = app.params["file"] or "art/russell.aseprite"
local OUT = app.params["out"] or "src/assets/runner"

-- The game's animations, each made of whole tags or parts of them
-- ({ tag, first frame, last frame }, counted from 1).
local CLIPS = {
  { name = "idle", parts = { { "idle" } } },
  { name = "run", parts = { { "run" } } },
  -- The jump opens with a crouch, which the game has no time for: he leaves
  -- the ground the moment the key goes down. So the clip starts on frame 2,
  -- runs through the fall, and ends on the first frame of the fall's loop.
  -- The game moves him up and down itself, so the little rise that is drawn
  -- into these frames is taken out: each is dropped until it touches the ground.
  { name = "jump", parts = { { "jump", 2, 6 }, { "fall" }, { "fall_loop", 1, 1 } }, grounded = true },
  { name = "slide", parts = { { "slide" } } },
  { name = "death", parts = { { "death" } } },
}

local spr = Sprite { fromFile = FILE }
if not spr then error("cannot open " .. FILE) end

local tags, slices = {}, {}
for _, tag in ipairs(spr.tags) do tags[tag.name] = tag end
for _, slice in ipairs(spr.slices) do slices[slice.name] = slice.bounds end
for _, name in ipairs { "feet", "body", "slide" } do
  if not slices[name] then error(FILE .. " has no slice named " .. name) end
end
local ground = slices.feet.y + slices.feet.height      -- the first row below his feet
local middle = slices.feet.x + slices.feet.width // 2  -- the column he stands on

-- Every frame of every clip, as a full picture with the box its pixels fall in.
local rows = {}
for _, clip in ipairs(CLIPS) do
  local row = { name = clip.name, frames = {} }
  for _, part in ipairs(clip.parts) do
    local tag = tags[part[1]]
    if not tag then error(FILE .. " has no tag named " .. part[1]) end
    local first = tag.fromFrame.frameNumber
    local from, to = first + (part[2] or 1) - 1, part[3] and (first + part[3] - 1) or tag.toFrame.frameNumber
    for n = from, to do
      local image = Image(spr.width, spr.height, ColorMode.RGB)
      image:drawSprite(spr, n)
      local box = image:shrinkBounds()
      local drop = clip.grounded and (ground - (box.y + box.height)) or 0
      row.frames[#row.frames + 1] = { image = image, box = box, drop = drop }
      row.fps = row.fps or math.floor(1 / spr.frames[n].duration + 0.5)
    end
  end
  rows[#rows + 1] = row
end

-- One cell size for everything: the smallest box that holds every frame of
-- every animation, so that he does not shift when the animation changes.
local left, right, top, columns = spr.width, 0, spr.height, 0
for _, row in ipairs(rows) do
  columns = math.max(columns, #row.frames)
  for _, frame in ipairs(row.frames) do
    left = math.min(left, frame.box.x)
    right = math.max(right, frame.box.x + frame.box.width)
    top = math.min(top, frame.box.y + frame.drop)
    if frame.box.y + frame.box.height + frame.drop > ground then
      error(row.name .. " has pixels below the ground line (the bottom of the `feet` slice)")
    end
  end
end
local cellWidth, cellHeight = right - left, ground - top

local sheet = Image(columns * cellWidth, #rows * cellHeight, ColorMode.RGB)
for r, row in ipairs(rows) do
  for c, frame in ipairs(row.frames) do
    for y = frame.box.y, frame.box.y + frame.box.height - 1 do
      for x = frame.box.x, frame.box.x + frame.box.width - 1 do
        local pixel = frame.image:getPixel(x, y)
        if app.pixelColor.rgbaA(pixel) > 0 then
          sheet:drawPixel((c - 1) * cellWidth + x - left, (r - 1) * cellHeight + y + frame.drop - top, pixel)
        end
      end
    end
  end
end
sheet:saveAs(OUT .. "/russell.png")

-- A hit box as the game wants it: how far it reaches behind and in front of
-- the column he stands on, and how tall it is from the ground.
local function hitBox(b)
  return string.format('{ "back": %d, "front": %d, "height": %d }', middle - b.x, b.x + b.width - middle, ground - b.y)
end

local lines = {
  "{",
  string.format('  "width": %d,', cellWidth),
  string.format('  "height": %d,', cellHeight),
  string.format('  "anchor": %d,', middle - left),
  string.format('  "body": %s,', hitBox(slices.body)),
  string.format('  "slidingBody": %s,', hitBox(slices.slide)),
  '  "clips": {',
}
for r, row in ipairs(rows) do
  lines[#lines + 1] = string.format('    "%s": { "row": %d, "frames": %d, "fps": %d }%s',
    row.name, r - 1, #row.frames, row.fps, r < #rows and "," or "")
end
lines[#lines + 1] = "  }"
lines[#lines + 1] = "}"
local file = assert(io.open(OUT .. "/russell.json", "w"))
file:write(table.concat(lines, "\n") .. "\n")
file:close()

print(string.format("Frames are %dx%d, with the column he stands on at %d.", cellWidth, cellHeight, middle - left))
for _, row in ipairs(rows) do print(string.format("  %s: %d frames at %d a second", row.name, #row.frames, row.fps)) end
print("Wrote " .. OUT .. "/russell.png and russell.json")
