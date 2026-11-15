-- Builds Russell's sprite from the Ozzbit "male hero" template.
--
-- The template colours each body part differently (head, torso, near arm,
-- far arm, near leg, far leg). This script reads every frame of the moves in
-- MOVES, repaints each part with Russell's look, then applies the hand-made
-- corrections in FIXES. The pose, the outline and the timing stay the
-- template's.
--
-- It writes two files:
--   work   the repaint plus the template on a hidden guide layer. It holds
--          template pixels, so it must stay in the git-ignored art/_work/.
--   clean  the repaint only: tags = moves, slices `feet` and `body`.
--
-- Run from the repo root:
--   "C:\aseprite\build\bin\aseprite.exe" -b ^
--     --script-param work=<abs path>\art\_work\russell.aseprite ^
--     --script-param clean=<abs path>\art\russell.aseprite ^
--     --script scripts/sprite/build-russell.lua
-- Optional: --script-param sheets=<folder> also writes one PNG strip per move
-- (used for review sheets).
--
-- What is set by hand in Aseprite survives a rebuild. Before `clean` is
-- written again, the file already there is read, and these are carried over:
--   frames drawn on by hand   each cel remembers what the build last gave it
--                             (its user data, "built:<signature>"); a cel that
--                             no longer matches was edited, and is kept as is
--   frame durations, slices   kept as they are in the file
-- Pass --script-param fresh=1 to throw the hand edits away and take the
-- build's frames. To make an edit part of the build itself, print it with
-- frame-to-fix.lua and paste it into russell-fixes.lua.

local TEMPLATE_DIR = app.params["template"]
  or [[C:\RUSSDM\Projects\GameDev_Templates\template_pro\individual_sheets]]
local OUT_WORK = app.params["work"]
local OUT_CLEAN = app.params["clean"]
local OUT_SHEETS = app.params["sheets"]
local DUMP = app.params["dump"] -- "move:frame", prints that frame's grids
local FRESH = app.params["fresh"] == "1"

local CELL = 128
local FRAME_MS = 100

-- Letter, name, colour. Index 0 is transparent.
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
  { "W", "white",        0xff, 0xff, 0xff }, -- the death flash
}

local MOVES = {
  "idle", "idle_turn", "walk", "walk_turn", "run", "run_turn", "run_to_idle",
  "jump", "fall", "fall_loop", "slide", "hurt", "death",
}

-- Template colour -> body part.
--   A outline  B head  C torso  D near leg  E near arm  F far leg  G far arm
--   H the dark mark on the near hand  W white (death flash)
local PART = {
  [0x000000] = "A", [0x66becb] = "B", [0x78a66c] = "C", [0x5489b1] = "D",
  [0xd77e7e] = "E", [0x283584] = "F", [0xa94277] = "G", [0x5c2c4f] = "H",
  [0x285cc4] = "F", [0xffffff] = "W",
  -- the turns blend the near and far limb colours as they swap sides
  [0x4973a5] = "D", [0x43699f] = "D", [0x3a5796] = "F", [0x344d91] = "F",
  [0xcb6f7d] = "E", [0xc96c7c] = "E", [0xc6687b] = "E", [0xe17d7d] = "E",
  [0xb75579] = "G", [0xb65379] = "G", [0xbb597a] = "G", [0xb45078] = "G",
}

-- Frames the template tints as a whole (the hit flash, the fade to white).
-- `parts` reads the tinted colours; the repaint is tinted the same way.
local RED, WHITE = { 255, 0, 18 }, { 255, 255, 255 }
local TINTED = {
  ["hurt:1"] = { tint = RED, t = 0.6, parts = {
    [0x99000a] = "A", [0xc94336] = "C", [0xc14c5c] = "B", [0xba3751] = "D",
    [0xa92559] = "F", [0xdc1b3a] = "G", [0xef333d] = "E" } },
  ["hurt:2"] = { tint = RED, t = 0.3, parts = {
    [0x4d0005] = "A", [0xa07451] = "C", [0x948593] = "B", [0x876081] = "D",
    [0x68418e] = "F", [0xc22f59] = "G", [0xe3585e] = "E" } },
  ["death:11"] = { tint = WHITE, t = 0.23, parts = {
    [0x3b3b3b] = "A", [0x97ba8e] = "C", [0x7ba4c3] = "D", [0x89cdd7] = "B",
    [0xe09b9b] = "E", [0x5981d1] = "F", [0xbc6d96] = "G" } },
  ["death:12"] = { tint = WHITE, t = 0.55, parts = {
    [0x8c8c8c] = "A", [0xc2d6bc] = "C", [0xb1c9db] = "D", [0xbae1e7] = "B",
    [0xecc4c4] = "E", [0x9eb5e4] = "F", [0xd8a9c1] = "G" } },
  ["death:13"] = { tint = WHITE, t = 0.84, parts = {
    [0xd6d6d6] = "A", [0xe9f0e7] = "C", [0xe3ecf2] = "D", [0xe6f4f6] = "B",
    [0xf8eaea] = "E", [0xdce4f5] = "F", [0xf1e0e9] = "G" } },
}

-- Per-frame settings and corrections, loaded from the file beside this one.
--   view   = "right" | "left" | "front" | "none"   overrides the head's facing
--   full   = { x0, y0, rows }   replaces the whole frame
--   patch  = { { x0, y0, rows }, ... }   " " keeps a pixel, "." clears it
local scriptDir = debug.getinfo(1, "S").source:match("^@?(.*[/\\])") or "./"
local FIXES = dofile(scriptDir .. "russell-fixes.lua")

---------------------------------------------------------------------------
-- small helpers

local pc = app.pixelColor

local function newGrid(fill)
  local g = {}
  for y = 0, CELL - 1 do
    local row = {}
    for x = 0, CELL - 1 do row[x] = fill end
    g[y] = row
  end
  return g
end

local function at(g, x, y)
  if x < 0 or y < 0 or x >= CELL or y >= CELL then return "." end
  return g[y][x]
end

local function round(v) return math.floor(v + 0.5) end

-- All pixels whose part is in `codes`, split into 8-connected groups.
local function groups(T, codes)
  local seen, out = {}, {}
  for y = 0, CELL - 1 do
    for x = 0, CELL - 1 do
      if codes[T[y][x]] and not seen[y * CELL + x] then
        local comp, queue, head = {}, { { x, y } }, 1
        seen[y * CELL + x] = true
        while head <= #queue do
          local p = queue[head]; head = head + 1
          comp[#comp + 1] = p
          for dy = -1, 1 do
            for dx = -1, 1 do
              local nx, ny = p[1] + dx, p[2] + dy
              if (dx ~= 0 or dy ~= 0) and codes[at(T, nx, ny)] and not seen[ny * CELL + nx] then
                seen[ny * CELL + nx] = true
                queue[#queue + 1] = { nx, ny }
              end
            end
          end
        end
        out[#out + 1] = comp
      end
    end
  end
  return out
end

-- Distance along `comp` from its pixel nearest (ax, ay) to every other pixel
-- of it (a straight step counts 1, a diagonal one 1.41).
local function distances(comp, ax, ay)
  local inside, start, best = {}, nil, math.huge
  for _, p in ipairs(comp) do
    inside[p[2] * CELL + p[1]] = true
    local d = (p[1] - ax) ^ 2 + (p[2] - ay) ^ 2
    if d < best then best, start = d, p end
  end
  local dist, queue, head = {}, { start }, 1
  dist[start[2] * CELL + start[1]] = 0
  while head <= #queue do
    local p = queue[head]; head = head + 1
    local d = dist[p[2] * CELL + p[1]]
    for dy = -1, 1 do
      for dx = -1, 1 do
        if dx ~= 0 or dy ~= 0 then
          local k = (p[2] + dy) * CELL + p[1] + dx
          local nd = d + ((dx ~= 0 and dy ~= 0) and 1.41 or 1)
          if inside[k] and (dist[k] == nil or nd < dist[k] - 0.001) then
            dist[k] = nd
            queue[#queue + 1] = { p[1] + dx, p[2] + dy }
          end
        end
      end
    end
  end
  local maxd = 0
  for _, d in pairs(dist) do if d > maxd then maxd = d end end
  return dist, maxd, start
end

---------------------------------------------------------------------------
-- head

-- Hair highlights, as (columns from the back of the head, rows from its top).
local HAIR_LIGHT = {
  { 2, 0 }, { 1, 1 }, { 5, 1 }, { 7, 1 }, { 0, 2 }, { 4, 2 }, { 8, 2 }, { 3, 3 }, { 3, 4 },
}

local function paintHead(T, O, cfg)
  local hx0, hx1, hy0, hy1 = CELL, -1, CELL, -1
  for y = 0, CELL - 1 do
    for x = 0, CELL - 1 do
      if T[y][x] == "B" then
        if x < hx0 then hx0 = x end
        if x > hx1 then hx1 = x end
        if y < hy0 then hy0 = y end
        if y > hy1 then hy1 = y end
      end
    end
  end
  if hx1 < 0 then return nil end
  local function isB(x, y) return at(T, x, y) == "B" end

  -- A head drawn by hand for an unusual angle: letters land on head pixels only.
  if cfg.headStamp then
    for r, row in ipairs(cfg.headStamp) do
      for c = 1, #row do
        local ch = row:sub(c, c)
        local x, y = hx0 + c - 1, hy0 + r - 1
        if ch ~= " " and at(T, x, y) == "B" then O[y][x] = ch end
      end
    end
    for y = hy0, hy1 do
      for x = hx0, hx1 do
        if T[y][x] == "B" and not O[y][x] then O[y][x] = "h" end
      end
    end
    return { x0 = hx0, x1 = hx1, y0 = hy0, y1 = hy1, view = cfg.view or "right" }
  end

  -- Eyes: outline-coloured pixels with head above and below, and beside.
  local eyeCols, eyes = {}, {}
  for y = hy0, hy1 do
    for x = hx0, hx1 do
      if T[y][x] == "A" then
        local up, down, side = false, false, false
        for yy = math.max(hy0, y - 3), y - 1 do if isB(x, yy) then up = true end end
        for yy = y + 1, math.min(hy1, y + 3) do if isB(x, yy) then down = true end end
        for xx = hx0, hx1 do if xx ~= x and isB(xx, y) then side = true end end
        if up and down and side then
          eyes[#eyes + 1] = { x, y }
          eyeCols[x] = true
        end
      end
    end
  end
  local clusters = {}
  for x = hx0, hx1 do
    if eyeCols[x] then
      local c = clusters[#clusters]
      if c and c.x1 == x - 1 then c.x1 = x else clusters[#clusters + 1] = { x0 = x, x1 = x, y0 = CELL, y1 = -1 } end
    end
  end
  for _, e in ipairs(eyes) do
    for _, c in ipairs(clusters) do
      if e[1] >= c.x0 and e[1] <= c.x1 then
        if e[2] < c.y0 then c.y0 = e[2] end
        if e[2] > c.y1 then c.y1 = e[2] end
      end
    end
  end

  local view = cfg.view
  if not view then
    if #clusters == 0 then
      view = "none"
    else
      local first, last = clusters[1], clusters[#clusters]
      local touchL, touchR = true, true
      for x = hx0, first.x0 - 1 do if isB(x, first.y0) then touchL = false end end
      for x = last.x1 + 1, hx1 do if isB(x, last.y0) then touchR = false end end
      if touchR and not touchL then view = "right"
      elseif touchL and not touchR then view = "left"
      elseif #clusters >= 2 then view = "front"
      else view = ((first.x0 + first.x1) / 2 >= (hx0 + hx1) / 2) and "right" or "left" end
    end
  end

  local info = { x0 = hx0, x1 = hx1, y0 = hy0, y1 = hy1, view = view }
  local ext = {}
  -- Hair that grows past the template's head: only over empty space or outline.
  local function grow(x, y, letter)
    local t = at(T, x, y)
    if (t == "." or t == "A") and x >= 0 and y >= 0 and x < CELL and y < CELL then
      O[y][x] = letter or "h"
      ext[#ext + 1] = { x, y }
    end
  end
  local function closeOutline()
    for _, p in ipairs(ext) do
      for _, n in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
        local x, y = p[1] + n[1], p[2] + n[2]
        if at(T, x, y) == "." and x >= 0 and y >= 0 and x < CELL and y < CELL and not O[y][x] then
          O[y][x] = "K"
        end
      end
    end
  end

  if view == "none" or #clusters == 0 then
    -- The top or back of the head: all hair.
    for y = hy0, hy1 do
      for x = hx0, hx1 do if T[y][x] == "B" then O[y][x] = "h" end end
    end
    for _, h in ipairs(HAIR_LIGHT) do
      local x, y = hx0 + h[1], hy0 + h[2]
      if at(T, x, y) == "B" then O[y][x] = "H" end
    end
    info.view = cfg.view or "right"
    return info
  end

  local et = CELL
  for _, c in ipairs(clusters) do if c.y0 < et then et = c.y0 end end

  if view == "front" then
    local e1, e2 = clusters[1], clusters[#clusters]
    local g0 = math.floor((e1.x1 + e2.x0) / 2) - 1
    for y = hy0, hy1 do
      for x = hx0, hx1 do
        if T[y][x] == "B" then
          if y >= et and x >= e1.x0 - 1 and x <= e2.x1 + 1 then O[y][x] = "s"
          elseif y == et - 1 and x >= g0 and x <= g0 + 2 then O[y][x] = "s"
          else O[y][x] = "h" end
        end
      end
    end
    for _, h in ipairs(HAIR_LIGHT) do
      local x, y = hx0 + h[1], hy0 + h[2]
      if at(T, x, y) == "B" and O[y][x] == "h" then O[y][x] = "H" end
    end
    -- jaw shadow
    local first, last
    for x = hx0, hx1 do
      if O[hy1][x] == "s" then first = first or x; last = x end
    end
    if first then O[hy1][first] = "S"; O[hy1][last] = "S" end
    -- a little more hair on both sides, a tuft on top, the mullet behind the neck
    for y = hy0, hy1 do
      local l, r
      for x = hx0, hx1 do if T[y][x] == "B" then l = l or x; r = x end end
      if l then
        local d = y - et
        if d <= -1 or d == 2 or d == 3 then
          grow(l - 1, y); grow(r + 1, y)
        end
      end
    end
    local a
    for x = hx0, hx1 do if T[hy0][x] == "B" then a = a or x end end
    for k = 1, 3 do grow(a + k, hy0 - 1) end
    closeOutline()
    return info
  end

  -- Side view. u counts columns from the back of the head, whichever way he faces.
  local mirror = (view == "left")
  local function X(u) if mirror then return hx1 - u end return hx0 + u end
  local function U(x) if mirror then return hx1 - x end return x - hx0 end
  local near
  for _, c in ipairs(clusters) do
    local u0, u1 = U(c.x0), U(c.x1)
    if u0 > u1 then u0, u1 = u1, u0 end
    if not near or u0 < near.u0 then near = { u0 = u0, u1 = u1, y0 = c.y0, y1 = c.y1 } end
  end
  for y = hy0, hy1 do
    for x = hx0, hx1 do
      if T[y][x] == "B" then
        local u = U(x)
        if y >= et and u >= near.u0 - 1 then O[y][x] = "s"
        elseif y == et - 1 and u >= near.u1 and u <= near.u1 + 2 then O[y][x] = "s"
        else O[y][x] = "h" end
      end
    end
  end
  for _, h in ipairs(HAIR_LIGHT) do
    local x, y = X(h[1]), hy0 + h[2]
    if at(T, x, y) == "B" and O[y][x] == "h" then O[y][x] = "H" end
  end
  -- ear and earring
  local ex, ey = X(near.u0 - 2), near.y1
  if at(T, ex, ey) == "B" then O[ey][ex] = "S" end
  if at(T, ex, ey + 1) == "B" then O[ey + 1][ex] = "P" end
  -- jaw shadow
  local firstU, lastU
  for u = 0, hx1 - hx0 do
    if O[hy1][X(u)] == "s" then firstU = firstU or u; lastU = u end
  end
  if firstU then O[hy1][X(firstU)] = "S"; O[hy1][X(lastU)] = "S" end
  if hy1 - 1 >= et then
    local lastS
    for u = 0, hx1 - hx0 do if O[hy1 - 1][X(u)] == "s" then lastS = u end end
    if lastS then O[hy1 - 1][X(lastS)] = "S" end
  end
  -- The mop: fuller at the back of the head, a tuft on top, and the mullet:
  -- hair down the nape with a flick at the collar.
  local back = mirror and 1 or -1 -- x step toward the back
  for y = hy0, hy1 do
    local b
    for u = 0, hx1 - hx0 do if T[y][X(u)] == "B" then b = u; break end end
    if b then
      local L = X(b) + back -- the template's outline pixel behind this row
      local d = y - et
      if d == -4 or d == -5 then grow(L, y); grow(L + back, y)
      elseif d <= -1 then grow(L, y)
      elseif d == 1 then grow(L, y)
      elseif d == 2 then grow(L, y); grow(L + back, y, "H")
      elseif d == 3 then grow(L + back, y); grow(L + 2 * back, y); grow(L + 3 * back, y, "H") end
    end
  end
  local a, topWidth = nil, 0
  for u = 0, hx1 - hx0 do
    if T[hy0][X(u)] == "B" then a = a or u; topWidth = topWidth + 1 end
  end
  if topWidth >= 4 then
    for k = 0, 2 do grow(X(a + k), hy0 - 1) end
  end
  closeOutline()
  return info
end

---------------------------------------------------------------------------
-- torso: the open denim jacket over the rust shirt

local FLECK = { [0] = 1, [1] = 3, [2] = 0, [3] = 2 } -- which shirt column is dark, row by row

local function paintTorso(T, O, view, cfg)
  local top, bottom = CELL, -1
  local rowMin, rowMax = {}, {}
  for y = 0, CELL - 1 do
    for x = 0, CELL - 1 do
      if T[y][x] == "C" then
        if y < top then top = y end
        if y > bottom then bottom = y end
        if not rowMin[y] then rowMin[y] = x end
        rowMax[y] = x
      end
    end
  end
  if bottom < 0 then return nil end
  local info = { top = top, bottom = bottom }
  local left, right = CELL, -1
  for y = top, bottom do
    if rowMin[y] then left = math.min(left, rowMin[y]); right = math.max(right, rowMax[y]) end
  end

  if cfg.torso == "back" then
    -- curled over, or seen from behind: only the jacket shows
    for y = top, bottom do
      for x = left, right do if T[y][x] == "C" then O[y][x] = "d" end end
    end
    return info
  end

  local flat = cfg.torso == "flat"
    or (cfg.torso == nil and view ~= "front" and (right - left + 1) > (bottom - top + 1) * 1.4)
  if flat then
    -- Lying back (the slide): the chest is the top edge, so measure it by column.
    local pts = {}
    for x = left, right do
      local ty
      for y = top, bottom do if T[y][x] == "C" then ty = y; break end end
      if ty then
        local y, n = ty - 1, 0
        while at(T, x, y) == "A" and n < 3 do y = y - 1; n = n + 1 end
        local c = at(T, x, y)
        if n > 0 and (c == "." or c == "G" or c == "F") then pts[#pts + 1] = { x, ty } end
      end
    end
    if #pts >= 2 then
      if #pts >= 5 then table.remove(pts, 1); table.remove(pts) end
      local sx, sy, sxx, sxy, n = 0, 0, 0, 0, #pts
      for _, q in ipairs(pts) do sx = sx + q[1]; sy = sy + q[2]; sxx = sxx + q[1] * q[1]; sxy = sxy + q[1] * q[2] end
      local den, a = n * sxx - sx * sx, 0
      if den ~= 0 then a = (n * sxy - sx * sy) / den end
      local b = (sy - a * sx) / n
      local x0, x1 = pts[1][1], pts[#pts][1]
      info.valid, info.a, info.b = n, a, b
      for y = top, bottom do
        for x = left, right do
          if T[y][x] == "C" then
            local c = "d"
            if x >= x0 - 3 and x <= x1 + 3 then
              local e = y - round(a * x + b) -- pixels under the chest line
              local along = x - (x0 - 1)
              if e <= 0 then
                c = "D"
                if x >= x1 - 1 then c = ((x - e) % 2 == 0) and "P" or "l" end
              elseif e <= 3 then
                c = "r"
                if along <= 0 then c = (e == 1) and "r" or "S"
                elseif along == 1 and e == 2 then c = "S"
                elseif along == 2 and e == 2 then c = "P"
                elseif along >= 3 and FLECK[(along - 3) % 4] == e then c = "R" end
              elseif e == 4 then
                c = "D"
              end
            end
            O[y][x] = c
          end
        end
      end
      return info
    end
  end

  if view == "front" then
    local sum, n = 0, 0
    for y = top, bottom do
      if rowMin[y] then sum = sum + (rowMin[y] + rowMax[y]) / 2; n = n + 1 end
    end
    local cx = round(sum / n)
    for y = top, bottom do
      for x = 0, CELL - 1 do
        if T[y][x] == "C" then
          local e, dy, c = x - cx, y - top, "d"
          if math.abs(e) <= 1 then
            c = "r"
            if dy == 0 then c = "S"
            elseif dy == 1 and e == 0 then c = "S"
            elseif dy == 2 and e == 0 then c = "P"
            elseif dy >= 3 and FLECK[(dy - 3) % 4] == e + 2 then c = "R" end
          elseif math.abs(e) == 2 then
            c = (dy == 0) and "r" or "D"
          elseif (e == 3 or e == 4) and bottom - y >= 1 and bottom - y <= 3 then
            c = ((e + bottom - y) % 2 == 0) and "P" or "l"
          end
          O[y][x] = c
        end
      end
    end
    info.cx = cx
    return info
  end

  -- Side view. Find the line of the chest: the rows whose front pixel meets
  -- the outline with nothing of the near arm, head or legs in the way.
  local dir = (view == "left") and -1 or 1
  local pts = {}
  for y = top, bottom do
    if rowMin[y] then
      local fx = (dir == 1) and rowMax[y] or rowMin[y]
      local x, n = fx + dir, 0
      while at(T, x, y) == "A" and n < 3 do x = x + dir; n = n + 1 end
      local c = at(T, x, y)
      if n > 0 and (c == "." or c == "G") then pts[#pts + 1] = { y, fx } end
    end
  end
  if #pts >= 5 then table.remove(pts, 1); table.remove(pts) end
  local y0, y1 = top, bottom
  if #pts >= 1 then y0, y1 = pts[1][1] - 3, pts[#pts][1] + 3 end
  local a, b = 0, nil
  if #pts >= 2 then
    local sy, sx, syy, sxy = 0, 0, 0, 0
    for _, p in ipairs(pts) do sy = sy + p[1]; sx = sx + p[2]; syy = syy + p[1] * p[1]; sxy = sxy + p[1] * p[2] end
    local n = #pts
    local den = n * syy - sy * sy
    if den ~= 0 then a = (n * sxy - sy * sx) / den end
    b = (sx - a * sy) / n
  elseif #pts == 1 then
    b = pts[1][2]
  else
    b = (dir == 1) and -1 or CELL
    for y = top, bottom do
      if rowMin[y] then
        if dir == 1 then b = math.max(b, rowMax[y]) else b = math.min(b, rowMin[y]) end
      end
    end
  end
  info.a, info.b, info.valid = a, b, #pts
  local function frontAt(y) return round(a * math.max(y0, math.min(y1, y)) + b) end
  -- A piece of torso cut off by an arm, and wholly behind the lapel, is the
  -- side or back of the jacket.
  local plain, measured = {}, {}
  for _, p in ipairs(pts) do measured[p[1]] = true end
  for _, comp in ipairs(groups(T, { C = true })) do
    local has, sum = false, 0
    for _, p in ipairs(comp) do
      if measured[p[2]] then has = true end
      sum = sum + (frontAt(p[2]) - p[1]) * dir
    end
    if not has and sum / #comp > 4 then
      for _, p in ipairs(comp) do plain[p[2] * CELL + p[1]] = true end
    end
  end
  for y = top, bottom do
    local front = frontAt(y)
    for x = 0, CELL - 1 do
      if T[y][x] == "C" then
        local e = (front - x) * dir -- pixels behind the chest line
        if plain[y * CELL + x] then e = 99 end
        local dy, c = y - top, "d"
        if e <= 0 then
          c = "D"
          local up = bottom - y
          if up >= 1 and up <= 3 then c = ((up - e) % 2 == 0) and "P" or "l" end
        elseif e <= 3 then
          c = "r"
          if dy == 0 then c = (e == 1) and "r" or "S"
          elseif dy == 1 and e == 2 then c = "S"
          elseif dy == 2 and e == 2 then c = "P"
          elseif dy >= 3 and FLECK[(dy - 3) % 4] == e then c = "R" end
        elseif e == 4 then
          c = (dy == 0) and "r" or "D"
        end
        O[y][x] = c
      end
    end
  end
  return info
end

---------------------------------------------------------------------------
-- limbs

-- The end of a limb (a hand): the pixels within `depth` of its tip, measured
-- along the last stretch of the limb. Also returns the row of pixels before
-- them (the cuff).
local function limbEnd(comp, ax, ay, depth)
  local dist, maxd, start = distances(comp, ax, ay)
  if maxd < depth + 1 then return nil end
  local ex, ey, en, bx, by, bn = 0, 0, 0, 0, 0, 0
  for _, p in ipairs(comp) do
    local d = dist[p[2] * CELL + p[1]]
    if d >= maxd - 2 then ex = ex + p[1]; ey = ey + p[2]; en = en + 1
    elseif d >= maxd - 8 and d <= maxd - 4 then bx = bx + p[1]; by = by + p[2]; bn = bn + 1 end
  end
  if bn == 0 then bx, by, bn = start[1], start[2], 1 end
  local vx, vy = ex / en - bx / bn, ey / en - by / bn
  local len = math.sqrt(vx * vx + vy * vy)
  if len < 0.5 then vx, vy = 0, 1 else vx, vy = vx / len, vy / len end
  local ang, step = math.atan(vy, vx), math.pi / 4
  local snapped = round(ang / step) * step
  if math.abs(ang - snapped) < math.rad(20) then ang = snapped end
  vx, vy = math.cos(ang), math.sin(ang)
  local tmax, cand = -math.huge, {}
  for _, p in ipairs(comp) do
    if dist[p[2] * CELL + p[1]] >= maxd - 7 then
      local t = p[1] * vx + p[2] * vy
      cand[#cand + 1] = { p, t }
      if t > tmax then tmax = t end
    end
  end
  local tip, cuff = {}, {}
  for _, c in ipairs(cand) do
    if c[2] > tmax - depth + 0.01 then tip[#tip + 1] = c[1]
    elseif c[2] > tmax - depth - 0.99 then cuff[#cuff + 1] = c[1] end
  end
  return tip, cuff, vx, vy
end

local function pickGroup(comps, T, wantMark)
  local best
  for _, comp in ipairs(comps) do
    local mark = false
    if wantMark then
      for _, p in ipairs(comp) do if T[p[2]][p[1]] == "H" then mark = true end end
    end
    comp.mark = mark
    if not best or (mark and not best.mark) or (mark == best.mark and #comp > #best) then best = comp end
  end
  return best
end

local function paintArm(T, O, near, neck, view, cfg, shoulder)
  local codes = near and { E = true, H = true } or { G = true, I = true }
  local comps = groups(T, codes)
  if #comps == 0 then return end
  local main = pickGroup(comps, T, near)
  local dir = (view == "left") and -1 or 1
  local lit = near or view == "front"

  local hand, cuff = {}, {}
  if not cfg.noHand then
    local from = cfg.from or shoulder
    if not from then
      if view == "front" then from = { neck[1] + (near and -6 or 6), neck[2] + 1 }
      elseif near then from = { neck[1] - 5 * dir, neck[2] + 1 }
      else from = { neck[1], neck[2] + 2 } end
    end
    local tipPx, cuffPx = limbEnd(main, from[1], from[2], cfg.depth or (near and 3 or 2))
    for _, p in ipairs(tipPx or {}) do hand[p[2] * CELL + p[1]] = true end
    for _, p in ipairs(cuffPx or {}) do cuff[p[2] * CELL + p[1]] = true end
  end

  for _, comp in ipairs(comps) do
    local x0, x1, y0, y1 = CELL, -1, CELL, -1
    for _, p in ipairs(comp) do
      x0 = math.min(x0, p[1]); x1 = math.max(x1, p[1])
      y0 = math.min(y0, p[2]); y1 = math.max(y1, p[2])
    end
    local upright = (y1 - y0) >= (x1 - x0)
    local markRow = {}
    for _, p in ipairs(comp) do if T[p[2]][p[1]] == "H" then markRow[p[2]] = true end end
    for _, p in ipairs(comp) do
      local x, y = p[1], p[2]
      local k = y * CELL + x
      local c
      if hand[k] then
        if not lit then c = "S"
        elseif T[y][x] == "H" then c = "S"
        elseif not markRow[y] and not codes[at(T, x + dir, y)] then c = "S"
        else c = "s" end
      elseif not lit then
        c = "D"
      else
        c = "d"
        if upright then
          local w, xx = 1, x - 1
          while codes[at(T, xx, y)] do w = w + 1; xx = xx - 1 end
          xx = x + 1
          while codes[at(T, xx, y)] do w = w + 1; xx = xx + 1 end
          if not codes[at(T, x - dir, y)] and at(T, x - dir, y) ~= "C" then
            c = (cuff[k] or not near) and "d" or "l"
          elseif at(T, x + dir, y) == "A" and w >= 3 then
            c = "D"
          end
        else
          local hgt, yy = 1, y - 1
          while codes[at(T, x, yy)] do hgt = hgt + 1; yy = yy - 1 end
          yy = y + 1
          while codes[at(T, x, yy)] do hgt = hgt + 1; yy = yy + 1 end
          if not codes[at(T, x, y - 1)] and at(T, x, y - 1) ~= "C" then
            c = (cuff[k] or not near) and "d" or "l"
          elseif at(T, x, y + 1) == "A" and hgt >= 3 then
            c = "D"
          end
        end
      end
      O[y][x] = c
    end
  end
end

---------------------------------------------------------------------------
-- legs: khaki trousers and the loafers

local function paintLeg(T, O, near, hip, view, cfg)
  local code = near and "D" or "F"
  local codes = { [code] = true }
  local comps = groups(T, codes)
  if #comps == 0 then return end
  local dir = (view == "left") and -1 or 1

  -- trousers
  for _, comp in ipairs(comps) do
    for _, p in ipairs(comp) do
      local x, y = p[1], p[2]
      local c = near and "k" or "Q"
      if near and at(T, x + dir, y) == "A" then
        local w, xx = 1, x - dir
        while codes[at(T, xx, y)] do w = w + 1; xx = xx - dir end
        if w >= 3 then c = "Q" end
      end
      O[y][x] = c
    end
  end
  if cfg.noShoe then return end

  -- The foot is in the group that reaches furthest from the hip.
  local foot, far, tip = nil, -1, nil
  for _, comp in ipairs(comps) do
    for _, p in ipairs(comp) do
      local d = (p[1] - hip[1]) ^ 2 + (p[2] - hip[2]) ^ 2
      if d > far then far, foot, tip = d, comp, p end
    end
  end
  local start, near2, maxY = nil, math.huge, -1
  for _, p in ipairs(foot) do
    local d = (p[1] - hip[1]) ^ 2 + (p[2] - hip[2]) ^ 2
    if d < near2 then near2, start = d, p end
    if p[2] > maxY then maxY = p[2] end
  end
  local vx, vy = tip[1] - start[1], tip[2] - start[2]
  local shoe, sx, sy = {}, 0, 1
  if math.abs(vx) > math.abs(vy) * 1.5 then
    -- the leg lies flat (a slide, a kick): the shoe is its last columns
    sx, sy = (vx > 0) and 1 or -1, 0
    for _, p in ipairs(foot) do
      local back = (tip[1] - p[1]) * sx
      if math.abs(p[2] - tip[2]) <= 5 then
        if back <= 2 then shoe[#shoe + 1] = p
        elseif back == 3 and not cfg.noSock then O[p[2]][p[1]] = "h" end
      end
    end
  elseif tip[2] >= maxY - 1 then
    -- the foot points down: the shoe is the lowest rows
    local rows = 2
    repeat
      shoe = {}
      for _, p in ipairs(foot) do
        if p[2] > maxY - rows and math.abs(p[1] - tip[1]) <= 7 then shoe[#shoe + 1] = p end
      end
      rows = rows + 1
    until #shoe >= 5 or rows > 3
  else
    local tipPx, sockPx, ax, ay = limbEnd(foot, hip[1], hip[2], 2)
    shoe = tipPx or {}
    if not cfg.noSock then
      for _, q in ipairs(sockPx or {}) do O[q[2]][q[1]] = "h" end
    end
    if ax then
      sx, sy = round(ax), round(ay)
      if sx == 0 and sy == 0 then sy = 1 end
    end
  end
  if cfg.sole then sx, sy = cfg.sole[1], cfg.sole[2] end
  if #shoe == 0 then return end
  local inShoe = {}
  for _, p in ipairs(shoe) do inShoe[p[2] * CELL + p[1]] = true end
  local upper = {}
  for _, p in ipairs(shoe) do
    if codes[at(T, p[1] + sx, p[2] + sy)] then
      O[p[2]][p[1]] = "B"
      upper[#upper + 1] = p
    else
      O[p[2]][p[1]] = "b"
    end
  end
  -- the gold bit, toward the toe
  table.sort(upper, function(p, q)
    if p[1] ~= q[1] then return (p[1] - q[1]) * dir > 0 end
    return p[2] > q[2]
  end)
  if #upper >= 3 then
    local g = upper[(#upper >= 6) and 3 or 2]
    O[g[2]][g[1]] = "g"
  end
  -- Standing on the ground, the toe pokes out past the trouser hem.
  if sy == 1 then
    local topY, frontX = CELL, nil
    for _, p in ipairs(shoe) do if p[2] < topY then topY = p[2] end end
    for _, p in ipairs(shoe) do
      if p[2] == topY and (not frontX or (p[1] - frontX) * dir > 0) then frontX = p[1] end
    end
    local hemFront
    for x = 0, CELL - 1 do
      if codes[at(T, x, topY - 1)] and not inShoe[(topY - 1) * CELL + x] then
        if not hemFront or (x - hemFront) * dir > 0 then hemFront = x end
      end
    end
    if hemFront and (frontX - hemFront) * dir > 0 then
      O[topY - 1][hemFront] = "B"
      if codes[at(T, hemFront - dir, topY - 1)] then O[topY - 1][hemFront - dir] = "B" end
    end
  end
end

---------------------------------------------------------------------------
-- one frame

local function applyGrid(O, g, whole)
  if whole then
    for y = 0, CELL - 1 do for x = 0, CELL - 1 do O[y][x] = false end end
  end
  for r, row in ipairs(g[3]) do
    for c = 1, #row do
      local ch = row:sub(c, c)
      local x, y = g[1] + c - 1, g[2] + r - 1
      if ch == "." then
        if not whole then O[y][x] = false end
      elseif ch ~= " " then
        O[y][x] = ch
      end
    end
  end
end

local function paintFrame(T, key)
  local cfg = FIXES[key] or {}
  local O = newGrid(false)
  local notes = {}
  local white = false
  for y = 0, CELL - 1 do
    for x = 0, CELL - 1 do
      local t = T[y][x]
      if t == "A" then O[y][x] = "K"
      elseif t == "W" then O[y][x] = "W"; white = true end
    end
  end
  if not white then
    local head = paintHead(T, O, cfg)
    local view = cfg.view or (head and head.view) or "right"
    if view == "none" then view = "right" end
    local torso = paintTorso(T, O, cfg.torsoView or view, cfg)
    local neck = head and { (head.x0 + head.x1) / 2, head.y1 + 1 } or { 64, 58 }
    if cfg.neck then neck = cfg.neck end
    local hip = { neck[1], neck[2] + 11 }
    if torso then
      local sum, n = 0, 0
      for x = 0, CELL - 1 do
        if T[torso.bottom][x] == "C" then sum = sum + x; n = n + 1 end
      end
      hip = { sum / n, torso.bottom }
    end
    if cfg.hip then hip = cfg.hip end
    -- The shoulders: the back and front corners of the top of the torso.
    local shoulders = {}
    if torso then
      local lo, hi
      for y = torso.top, math.min(torso.bottom, torso.top + 1) do
        for x = 0, CELL - 1 do
          if T[y][x] == "C" then lo = math.min(lo or x, x); hi = math.max(hi or x, x) end
        end
      end
      local dir = (view == "left") and -1 or 1
      local back, front = (dir == 1) and lo or hi, (dir == 1) and hi or lo
      if view == "front" then
        shoulders.near, shoulders.far = { lo - 1, torso.top + 0.5 }, { hi + 1, torso.top + 0.5 }
      else
        shoulders.near, shoulders.far = { back - dir, torso.top + 0.5 }, { front, torso.top + 1 }
      end
    end
    paintArm(T, O, false, neck, view, cfg.farArm or {}, shoulders.far)
    paintArm(T, O, true, neck, view, cfg.nearArm or {}, shoulders.near)
    paintLeg(T, O, false, hip, view, cfg.farLeg or {})
    paintLeg(T, O, true, hip, view, cfg.nearLeg or {})
    notes[#notes + 1] = "view=" .. view
    if torso and torso.valid then notes[#notes + 1] = string.format("chest=%.2fy%+.1f(%d)", torso.a, torso.b, torso.valid) end
  end
  -- anything the rules missed keeps the outline colour, and is reported
  local missed = 0
  for y = 0, CELL - 1 do
    for x = 0, CELL - 1 do
      if T[y][x] ~= "." and not O[y][x] then O[y][x] = "K"; missed = missed + 1 end
    end
  end
  if missed > 0 then notes[#notes + 1] = missed .. " unpainted" end
  if cfg.full then applyGrid(O, cfg.full, true) end
  for _, g in ipairs(cfg.patch or {}) do applyGrid(O, g, false) end
  return O, notes
end

---------------------------------------------------------------------------
-- read the template

local function readSheet(move)
  local path = TEMPLATE_DIR .. "\\male_hero_template-" .. move .. ".png"
  local s = Sprite { fromFile = path }
  if not s then error("cannot open " .. path) end
  if s.colorMode ~= ColorMode.RGB then
    app.sprite = s
    app.command.ChangePixelFormat { format = "rgb" }
  end
  local full = Image(s.spec)
  full:drawSprite(s, 1)
  local count = s.width // CELL
  s:close()
  return full, count
end

local frames = {} -- { move, n, key, T (parts), rgb (template colours), O (letters), tint }
local unknown = {}
for _, move in ipairs(MOVES) do
  local full, count = readSheet(move)
  for f = 1, count do
    local key = move .. ":" .. f
    local tinted = TINTED[key]
    local T, rgb = newGrid("."), newGrid(false)
    for y = 0, CELL - 1 do
      for x = 0, CELL - 1 do
        local p = full:getPixel((f - 1) * CELL + x, y)
        if pc.rgbaA(p) > 0 then
          local v = pc.rgbaR(p) * 65536 + pc.rgbaG(p) * 256 + pc.rgbaB(p)
          rgb[y][x] = v
          local part = (tinted and tinted.parts[v]) or PART[v]
          if not part then
            unknown[string.format("%s #%06x", key, v)] = true
            part = "A"
          end
          T[y][x] = part
        end
      end
    end
    for y = 0, CELL - 1 do
      for x = 0, CELL - 1 do
        if T[y][x] == "H" then
          local nearArm, farArm = false, false
          for dy = -1, 1 do
            for dx = -1, 1 do
              local t = at(T, x + dx, y + dy)
              if t == "E" then nearArm = true elseif t == "G" then farArm = true end
            end
          end
          if farArm and not nearArm then T[y][x] = "I" end
        end
      end
    end
    local O, notes = paintFrame(T, key)
    frames[#frames + 1] = { move = move, n = f, key = key, T = T, rgb = rgb, O = O, tint = tinted }
    print(string.format("%-14s %s", key, table.concat(notes, "  ")))
    if DUMP == key then
      for y = 0, CELL - 1 do
        local a, b, any = {}, {}, false
        for x = 30, 99 do
          a[#a + 1] = T[y][x]
          b[#b + 1] = O[y][x] or "."
          if T[y][x] ~= "." or O[y][x] then any = true end
        end
        if any then print(string.format("%3d %s   %s", y, table.concat(a), table.concat(b))) end
      end
    end
  end
end
for k in pairs(unknown) do print("UNKNOWN TEMPLATE COLOUR " .. k) end

---------------------------------------------------------------------------
-- final colours, and what was changed by hand in the file already there

local BASE = {}
for _, c in ipairs(PALETTE) do BASE[c[1]] = { c[3], c[4], c[5] } end

-- A frame's colours as the build gives them: 0xRRGGBB, false where empty.
local function generated(fr)
  local g = newGrid(false)
  for y = 0, CELL - 1 do
    for x = 0, CELL - 1 do
      local ch = fr.O[y][x]
      if ch then
        local c = BASE[ch]
        if not c then error(fr.key .. ": unknown letter " .. ch) end
        local r, gg, b = c[1], c[2], c[3]
        if fr.tint and ch ~= "W" then
          local t, k = fr.tint.t, fr.tint.tint
          r, gg, b = round(r + (k[1] - r) * t), round(gg + (k[2] - gg) * t), round(b + (k[3] - b) * t)
        end
        g[y][x] = r * 65536 + gg * 256 + b
      end
    end
  end
  return g
end

local function signature(g)
  local h = 5381
  for y = 0, CELL - 1 do
    local row = g[y]
    for x = 0, CELL - 1 do h = (h * 33 + (row[x] or -1) + 1) & 0xffffffff end
  end
  return string.format("%08x", h)
end

for _, fr in ipairs(frames) do
  fr.gen = generated(fr)
  fr.built = signature(fr.gen)
  fr.final = fr.gen
end

local keptSlices = {}
local function readExisting(path)
  local f = io.open(path, "rb")
  if not f then return end
  f:close()
  local s = Sprite { fromFile = path }
  local layer
  for _, l in ipairs(s.layers) do
    if l.name == "russell" then
      layer = l
    else
      error(path .. " has a layer '" .. l.name .. "' that a rebuild would drop. Merge it into 'russell' first.")
    end
  end
  if not layer then error(path .. " has no layer named 'russell'") end
  local pal, rgbMode = s.palettes[1], s.colorMode == ColorMode.RGB
  local frameOf = {}
  for _, tag in ipairs(s.tags) do
    local first = tag.fromFrame.frameNumber
    for n = first, tag.toFrame.frameNumber do frameOf[tag.name .. ":" .. (n - first + 1)] = n end
  end
  for _, fr in ipairs(frames) do
    local n = frameOf[fr.key]
    local cel = n and layer:cel(n)
    if n then fr.duration = s.frames[n].duration end
    local built = cel and cel.data:match("^built:(%x+)$")
    if built and not FRESH then
      local g = newGrid(false)
      for it in cel.image:pixels() do
        local v = it()
        local x, y = it.x + cel.position.x, it.y + cel.position.y
        if x >= 0 and y >= 0 and x < CELL and y < CELL then
          if rgbMode then
            if pc.rgbaA(v) > 0 then g[y][x] = pc.rgbaR(v) * 65536 + pc.rgbaG(v) * 256 + pc.rgbaB(v) end
          elseif v ~= s.transparentColor then
            local c = pal:getColor(v)
            if c.alpha > 0 then g[y][x] = c.red * 65536 + c.green * 256 + c.blue end
          end
        end
      end
      if signature(g) ~= built then
        fr.final = g
        print("kept the hand-edited frame " .. fr.key)
      end
    end
  end
  for _, sl in ipairs(s.slices) do
    keptSlices[#keptSlices + 1] = { name = sl.name, bounds = Rectangle(sl.bounds), data = sl.data, color = sl.color }
  end
  s:close()
end
if OUT_CLEAN then readExisting(OUT_CLEAN) end

---------------------------------------------------------------------------
-- write the .aseprite files

-- Slices a new file starts with. Once the file exists, its own slices are used.
--   feet   where he stands: its bottom edge is the ground, its middle is him
--   body   the runner game's hit box while he is up
--   slide  the runner game's hit box while he slides
local SLICES = {
  { name = "feet", bounds = Rectangle(57, 78, 14, 2) },
  { name = "body", bounds = Rectangle(58, 50, 15, 30) },
  { name = "slide", bounds = Rectangle(49, 63, 28, 17) },
}

local function buildSprite(withTemplate)
  local colours, index = {}, {}
  local function colourIndex(r, g, b)
    local v = r * 65536 + g * 256 + b
    if not index[v] then
      colours[#colours + 1] = { r, g, b }
      index[v] = #colours
    end
    return index[v]
  end
  for _, c in ipairs(PALETTE) do colourIndex(c[3], c[4], c[5]) end

  local arts, guides = {}, {}
  for i, fr in ipairs(frames) do
    local art = Image(CELL, CELL, ColorMode.INDEXED)
    for y = 0, CELL - 1 do
      for x = 0, CELL - 1 do
        local v = fr.final[y][x]
        if v then art:drawPixel(x, y, colourIndex(v // 65536, (v // 256) % 256, v % 256)) end
      end
    end
    arts[i] = art
  end
  if withTemplate then
    for i, fr in ipairs(frames) do
      local guide = Image(CELL, CELL, ColorMode.INDEXED)
      for y = 0, CELL - 1 do
        for x = 0, CELL - 1 do
          local v = fr.rgb[y][x]
          if v then guide:drawPixel(x, y, colourIndex(v // 65536, (v // 256) % 256, v % 256)) end
        end
      end
      guides[i] = guide
    end
  end

  local spr = Sprite(CELL, CELL, ColorMode.INDEXED)
  local pal = Palette(1 + #colours)
  pal:setColor(0, Color { r = 0, g = 0, b = 0, a = 0 })
  for i, c in ipairs(colours) do pal:setColor(i, Color { r = c[1], g = c[2], b = c[3], a = 255 }) end
  spr:setPalette(pal)
  spr.transparentColor = 0

  local artLayer = spr.layers[1]
  local guideLayer
  if withTemplate then
    guideLayer = artLayer
    guideLayer.name = "template"
    guideLayer.data = "Ozzbit Games male hero template. Guide only: never commit a file that has this layer."
    artLayer = spr:newLayer()
  end
  artLayer.name = "russell"

  for i = 1, #frames do
    if i > 1 then spr:newEmptyFrame(i) end
    if withTemplate then spr:newCel(guideLayer, i, guides[i], Point(0, 0)) end
    local cel = spr:newCel(artLayer, i, arts[i], Point(0, 0))
    cel.data = "built:" .. frames[i].built
    spr.frames[i].duration = frames[i].duration or FRAME_MS / 1000
  end
  -- Tags go on once every frame exists, or a new frame would stretch the last tag.
  local from = 1
  for i, fr in ipairs(frames) do
    local last = (i == #frames) or frames[i + 1].move ~= fr.move
    if last then
      local tag = spr:newTag(from, i)
      tag.name = fr.move
      from = i + 1
    end
  end
  if withTemplate then guideLayer.isVisible = false end
  local have = {}
  for _, k in ipairs(keptSlices) do have[k.name] = true end
  local slices = {}
  for _, d in ipairs(SLICES) do if not have[d.name] then slices[#slices + 1] = d end end
  for _, k in ipairs(keptSlices) do slices[#slices + 1] = k end
  for _, d in ipairs(slices) do
    local slice = spr:newSlice(d.bounds)
    slice.name = d.name
    if d.data then slice.data = d.data end
    if d.color then slice.color = d.color end
  end
  app.sprite = spr
  app.layer = artLayer
  return spr, colours
end

if OUT_WORK then
  local spr = buildSprite(true)
  spr:saveAs(OUT_WORK)
  print("saved " .. OUT_WORK)
  spr:close()
end
if OUT_CLEAN then
  local spr = buildSprite(false)
  spr:saveAs(OUT_CLEAN)
  print("saved " .. OUT_CLEAN)
  spr:close()
end

-- Review strips: one PNG per move, a frame per 128 px.
if OUT_SHEETS then
  local i = 1
  while i <= #frames do
    local j = i
    while j < #frames and frames[j + 1].move == frames[i].move do j = j + 1 end
    local strip = Image((j - i + 1) * CELL, CELL, ColorMode.RGB)
    for f = i, j do
      local fr = frames[f]
      for y = 0, CELL - 1 do
        for x = 0, CELL - 1 do
          local v = fr.final[y][x]
          if v then
            strip:drawPixel((f - i) * CELL + x, y, pc.rgba(v // 65536, (v // 256) % 256, v % 256, 255))
          end
        end
      end
    end
    strip:saveAs(OUT_SHEETS .. "\\" .. frames[i].move .. ".png")
    i = j + 1
  end
  print("wrote review strips to " .. OUT_SHEETS)
end
