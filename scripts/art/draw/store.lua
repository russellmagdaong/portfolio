-- scenes/store: TOOLS, a computer shop at night (the Tools page). Reworked 2026-11-17 on Russell's
-- word: each group of tools has a corner and a board of its own, sized to its text:
--   Games                a wood-grain CRT television on a stand with a console (look=crt)
--   Web                  a white flat monitor on a desk, showing a browser window (look=browser)
--   Backend and data     a server rack and a wall terminal (look=terminal)
--   Also comfortable in  a whiteboard over the repair bench (look=whiteboard)
-- The sign reads TOOLS, the floor is pale raised-floor tiles with green insets, mats and gloss under
-- the light panels, and the boxed PC (the platform) stands at the right end, under the window.
--
--   "C:\aseprite\build\bin\aseprite.exe" -b --script scripts/art/draw/store.lua
--
-- Rewrites the whole room (and art/anim/store.aseprite). Do not run it after hand edits to the room.
-- Layers (back to front): sky 0.1, far 0.3, mid 0.6, rain 0.6 (animated, through the window), back,
-- lights (animated, on the wall and ceiling: the panels, the sign, the clock, the aircon's ribbons, OPEN),
-- floor, props, life (animated, in front of the props: the people, LEDs, fans, the printer, steam),
-- boxes (sort=204: the boxed PC he can jump on and walk behind), front 1.2 over. 12 frames of 100 ms.
-- Everything but the boxed PC stands against the wall (feet at y 183 or less; his stop at 184).
local K=dofile('scripts/art/draw/kit.lua')
local m=K.m
local s=m.open('scenes/store')
while #s.frames>1 do s:deleteFrame(#s.frames) end
local WIDTH=624
if s.width<WIDTH then app.activeSprite=s; app.command.CanvasSize{ui=false,left=0,top=0,right=WIDTH-s.width,bottom=0} end
local W=s.width

-- The boards: each show: slice is the part of its board the page's text is laid over, sized to that
-- text at 7 art pixels a letter (measured in the browser; src/pages/tools.astro fits the text to it).
local S={
 games={x=64,y=107,w=45,h=36},
 web={x=166,y=102,w=96,h=42},
 backend={x=340,y=100,w=95,h=46},
 also={x=478,y=110,w=87,h=28},
}
local BOX={x=584,y=196,w=32,h=18}        -- the boxed PC's front face (the platform slice)
local function slice(name,r,data)
 local rect=Rectangle(r.x,r.y,r.w,r.h)
 for _,sl in ipairs(s.slices) do if sl.name==name then sl.bounds=rect; sl.data=data; return end end
 local sl=s:newSlice(rect); sl.name=name; sl.data=data
end
slice('floor',{x=0,y=176,w=W,h=49},'')
slice('platform',BOX,'depth=10')
slice('show:tools-games',S.games,'look=crt')
slice('show:tools-web',S.web,'look=browser')
slice('show:tools-backend-and-data',S.backend,'look=terminal')
slice('show:tools-also-comfortable-in',S.also,'look=whiteboard')

local L={}
for _,l in ipairs(s.layers) do L[l.name]=l end
L.rain=K.layer(s,'rain','speed=0.6',L.mid)
L.lights=K.layer(s,'lights','',L.back)
L.boxes=K.layer(s,'boxes','sort=204',L.props)
L.life=K.layer(s,'life','',L.props)
local STILL={'sky','far','mid','back','floor','props','boxes','front'}
local P={}
for _,n in ipairs(STILL) do P[n]=K.pen(m.canvas(s,L[n])) end

local PANELS={{36,96},{166,226},{300,360},{430,490},{548,608}}
local WX0,WX1,WY0,WY1=582,618,72,134                 -- the window onto the alley
local SIGN=312                                        -- the middle of the TOOLS sign
local RACK=S.backend.x-44                             -- the server rack's left edge
local BX0,BX1=S.also.x-34,S.also.x+S.also.w+12        -- the repair bench
local KID=S.games.x+S.games.w+33                      -- the kid on the beanbag
local DEV=S.web.x+S.web.w//2                          -- the developer at the desk
local TECH=S.also.x+44                                -- the technician at the bench
local PRN=270                                         -- the 3D printer's left edge

-- 5x7 letters drawn k times as large (the sign)
local function bigtext(q,str,x,y,c,k)
 for ch in str:gmatch('.') do
  local g=m.big[ch]
  if g then local yy=0
   for row in g:gmatch('[^/]+') do for i=1,#row do if row:sub(i,i)=='1' then q.rect(x+(i-1)*k,y+yy*k,k,k,c) end end; yy=yy+1 end
  end
  x=x+6*k
 end
end
-- draws a figure twice: first as its ink outline (every piece grown by a pixel), then itself
local function outlined(q,draw)
 local o={}
 function o.rect(x,y,w,h) q.rect(x-1,y-1,w+2,h+2,'ink') end
 function o.px(x,y) o.rect(x,y,1,1) end
 function o.hl(x,y,w) o.rect(x,y,w,1) end
 function o.vl(x,y,h) o.rect(x,y,1,h) end
 draw(o); draw(q)
end

---------------------------------------------------------------- sky / far / mid (the alley)
K.sky(P.sky,W)
K.farCity(P.far,W-190,W,150,23)
local p=P.mid
K.nearRoofs(p,W-150,W,176,24)
p.vl(W-52,108,68,'mist 2'); p.hl(W-64,112,30,'mist 2'); p.px(W-52,107,'neon red')
p.rect(W-130,150,130,26,'mist 1'); for i=1,14 do p.px(W-126+(i*9)%118,154+(i*5)%10,'sodium 1') end

---------------------------------------------------------------- back: ceiling, walls, what hangs on them
p=P.back
-- the drop ceiling: white tiles in a grid, seen from below; the light panels (lit on `lights`)
p.rect(0,0,W,52,'concrete 6')
for y=0,52,13 do p.hl(0,y,W,'concrete 5') end
for x=0,W,26 do p.vl(x,0,52,'concrete 5') end
for _,t in ipairs(PANELS) do p.rect(t[1]-1,38,t[2]-t[1]+2,6,'concrete 5') end
p.rect(0,52,W,4,'concrete 7'); p.hl(0,55,W,'concrete 5')
-- an air vent and a sprinkler or two in the tiles, a camera dome under the edge
p.rect(118,40,22,6,'concrete 5'); for x=120,136,3 do p.vl(x,41,4,'concrete 4') end
p.rect(392,40,22,6,'concrete 5'); for x=394,410,3 do p.vl(x,41,4,'concrete 4') end
for _,x in ipairs({250,520}) do p.px(x,45,'concrete 4'); p.hl(x-1,46,3,'r rust') end
p.rect(262,56,7,2,'concrete 3'); p.rect(263,58,5,2,'ink'); p.px(264,58,'concrete 5')
-- the walls: pale grey slatwall, grooves every 4 rows; a skirting
p.rect(0,56,W,120,'concrete 6')
for y=59,170,4 do p.hl(0,y,W,'concrete 5') end
for x=0,W,96 do p.vl(x,56,118,'concrete 5') end
p.rect(0,172,W,4,'concrete 4'); p.hl(0,172,W,'concrete 5')

-- the door out at the left; over the shelves beside it, an aircon (its ribbons are on `lights`)
K.exitLeft(p)
p.rect(20,60,32,11,'concrete 7'); p.hl(20,60,32,'W white'); p.hl(22,66,28,'concrete 6'); p.hl(22,68,28,'concrete 5'); p.rect(20,70,32,1,'concrete 5'); p.px(48,62,'neon green')

-- GAMES: a dark feature wall with stars, two posters and a pair of pixel invaders
do local g=S.games
 local x0,x1=g.x-16,g.x+g.w+42
 p.rect(x0,60,x1-x0,112,'night'); p.vl(x0,60,112,'sky low'); p.vl(x1-1,60,112,'sky high'); p.hl(x0,60,x1-x0,'sky low')
 local r=K.rng(77)
 for i=1,46 do p.px(x0+2+r(x1-x0-4),62+r(108),(r(4)==0) and 'haze' or 'sky high') end
 -- posters: a sunset racer, a dungeon
 local ax=g.x-9
 p.frame(ax,64,24,30,'concrete 1','sky high'); p.rect(ax+1,65,22,10,'neon haze'); p.oval(ax+7,68,10,10,'sodium 3'); p.rect(ax+1,78,22,15,'ink')
 p.hl(ax+1,78,22,'neon pink'); for i=0,3 do p.hl(ax+1,81+i*3,22,'neon pink dim') end; p.line(ax+12,78,ax+3,92,'neon pink dim'); p.line(ax+12,78,ax+21,92,'neon pink dim'); p.vl(ax+12,78,15,'neon pink dim')
 local bx=g.x+g.w-13
 p.frame(bx,64,24,30,'concrete 1','leaf 1'); p.rect(bx+3,70,18,17,'ink'); p.rect(bx+9,76,6,11,'sodium 2'); p.rect(bx+10,74,4,2,'sodium 2'); p.px(bx+13,81,'neon yellow')
 p.px(bx+5,73,'sodium 3'); p.px(bx+5,72,'neon yellow'); p.px(bx+18,73,'sodium 3'); p.px(bx+18,72,'neon yellow'); p.text('LV 99',bx+3,88,'neon green dim',5)
 -- invaders on the wall by the beanbag
 local function invader(x,y,c)
  for i,row in ipairs({'00100000100','00010001000','00111111100','01101110110','11111111111','10111111101','10100000101','00011011000'}) do
   for k=1,#row do if row:sub(k,k)=='1' then p.px(x+k-1,y+i-1,c) end end end
 end
 invader(g.x+g.w+22,70,'neon cyan dim'); invader(g.x+g.w+26,96,'neon pink dim'); invader(g.x+g.w+20,122,'neon violet dim')
end

-- WEB: over the desk, a shelf of books and a plant, a framed </> print, sticky notes
do local w=S.web
 p.rect(w.x+2,80,44,2,'concrete 4'); p.hl(w.x+2,80,44,'concrete 7'); p.px(w.x+6,82,'concrete 4'); p.px(w.x+41,82,'concrete 4')
 local r=K.rng(5); local e=K.books(p,w.x+4,80,8,r,8,13,{'d denim','l denim light','holo dim','neon cyan dim','concrete 3','D denim dark'})
 K.plant(p,w.x+38,80,'small')
 p.frame(w.x+54,62,24,21,'concrete 3','ink')
 p.line(w.x+61,69,w.x+58,72,'neon cyan'); p.line(w.x+58,72,w.x+61,75,'neon cyan'); p.line(w.x+70,69,w.x+73,72,'neon cyan'); p.line(w.x+73,72,w.x+70,75,'neon cyan'); p.line(w.x+67,67,w.x+64,77,'holo')
 for i,c in ipairs({'neon yellow','neon pink','neon green','neon yellow'}) do local nx=w.x+82+((i-1)%2)*8; local ny=63+((i-1)//2)*9
  p.rect(nx,ny,6,6,c); p.hl(nx+1,ny+2,4,'concrete 3'); p.hl(nx+1,ny+4,3,'concrete 3') end
end

-- TOOLS: the lightbox hung from the ceiling (its letters are on `lights`), a plaque under it
p.vl(SIGN-30,50,8,'concrete 4'); p.vl(SIGN+29,50,8,'concrete 4')
p.frame(SIGN-38,58,76,24,'concrete 2','ink'); p.hl(SIGN-37,59,74,'concrete 4')
for _,c in ipairs({{-36,60},{35,60},{-36,79},{35,79}}) do p.px(SIGN+c[1],c[2],'concrete 6') end
p.frame(SIGN-37,84,74,10,'concrete 2','leaf 1'); p.text('WHAT I BUILD WITH',SIGN-33,86,'neon green dim',5)

-- BACKEND AND DATA: the wall terminal (its screen is the show: plain black), a conduit up to the ceiling
do local b=S.backend
 p.rect(b.x-4,b.y-11,b.w+8,b.h+15,'concrete 1'); p.hl(b.x-4,b.y-11,b.w+8,'concrete 3'); p.vl(b.x-4,b.y-11,b.h+15,'concrete 2')
 p.rect(b.x-1,b.y-8,b.w+2,6,'concrete 2'); p.text('DB-01',b.x+1,b.y-8,'neon green dim',5)
 for i=0,2 do p.rect(b.x+b.w-11+i*4,b.y-7,3,3,(i==2) and 'neon red dim' or 'concrete 4') end
 p.rect(b.x-1,b.y-1,b.w+2,b.h+2,'ink')
 p.rect(b.x+b.w-24,b.y-19,4,8,'concrete 4'); p.rect(b.x+b.w-23,56,2,b.y-75,'concrete 4'); p.px(b.x+b.w-23,b.y-19,'concrete 6')
 -- blister packs of parts on the slatwall over it
 local r=K.rng(31); local packs={'leaf 3','d denim','r rust','concrete 3','sky','k khaki'}
 for i=0,4 do local x=b.x+16+i*12
  p.px(x+3,60,'concrete 3'); p.vl(x+3,61,3,'concrete 4')
  p.rect(x,64,8,14,'concrete 7'); p.hl(x,64,8,'W white'); local c=packs[1+r(#packs)]
  if r(2)==0 then p.rect(x+1,67,6,2,c); for k=0,2 do p.px(x+2+k*2,69,'g gold') end else p.rect(x+2,66,4,8,c); p.vl(x+3,74,3,'concrete 4') end
  p.rect(x+1,75,6,2,'d denim')
 end
end

-- the wall clock (its hand is on `lights`)
p.disc(456,74,8,'concrete 2'); p.disc(456,74,7,'W white'); for i=0,3 do local a=i*math.pi/2; p.px(456+math.floor(math.cos(a)*6+0.5),74+math.floor(math.sin(a)*6+0.5),'concrete 3') end
p.line(456,74,456,70,'ink'); p.line(456,74,459,75,'ink')

-- ALSO COMFORTABLE IN: the whiteboard in its aluminium frame, magnets, a tray of markers
do local a=S.also
 p.rect(a.x-3,a.y-3,a.w+6,a.h+6,'concrete 4'); p.hl(a.x-3,a.y-3,a.w+6,'concrete 7'); p.vl(a.x-3,a.y-3,a.h+6,'concrete 5')
 p.rect(a.x-1,a.y-1,a.w+2,a.h+2,'P pale steel'); p.hl(a.x-1,a.y+a.h,a.w+2,'concrete 7')
 p.rect(a.x+8,a.y+a.h+3,a.w-16,2,'concrete 5'); p.hl(a.x+8,a.y+a.h+3,a.w-16,'concrete 7')
 p.rect(a.x+12,a.y+a.h+2,6,1,'neon red'); p.rect(a.x+20,a.y+a.h+2,6,1,'d denim'); p.rect(a.x+28,a.y+a.h+2,6,1,'leaf 4'); p.rect(a.x+a.w-24,a.y+a.h+1,8,2,'concrete 3')
 -- coiled cables and a headset on hooks over it
 for i=0,3 do local x=a.x+10+i*20
  p.vl(x,62,4,'concrete 3')
  if i==3 then p.ring(x,71,5,'concrete 2'); p.rect(x-6,72,3,6,'concrete 2'); p.rect(x+4,72,3,6,'concrete 2')
  else local c=({'concrete 1','d denim','neon yellow dim'})[i+1]; p.ring(x,72,6,c); p.ring(x,72,4,c); p.px(x,78,'concrete 6') end
 end
end

-- the window onto the alley
p.rect(WX0-3,WY0-3,WX1-WX0+6,WY1-WY0+6,'concrete 4'); p.rect(WX0,WY0,WX1-WX0,WY1-WY0,0)
p.vl(WX0+(WX1-WX0)//2,WY0,WY1-WY0,'concrete 4'); p.hl(WX0,WY0+30,WX1-WX0,'concrete 4')
p.rect(WX0-4,WY1+3,WX1-WX0+8,2,'concrete 5')

---------------------------------------------------------------- floor: pale raised-floor tiles
p=P.floor
local rows={176,184,194,206,221,240,270}
local TW=32
for i=1,#rows-1 do local y0,y1=rows[i],rows[i+1]
 for x=0,W,TW do p.rect(x,y0,TW,y1-y0,(((x//TW)+i)%2==0) and 'P pale steel' or 'concrete 7') end
end
-- gloss under each light panel: the panel's reflection, three bright bars
for _,t in ipairs(PANELS) do local cx=(t[1]+t[2])//2
 p.hl(cx-15,197,30,'W white'); p.rect(cx-22,199,44,2,'W white'); p.hl(cx-12,203,24,'W white')
end
-- the seams, and a green inset where four tiles meet
for i=1,#rows-1 do p.hl(0,rows[i],W,'concrete 6') end
for x=0,W,TW do p.vl(x,176,94,'concrete 6') end
for i=2,#rows-1 do for x=0,W,TW do local k=1+(i//3); p.rect(x-k,rows[i]-((i>3) and 1 or 0),k*2+1,(i>3) and 3 or 1,'leaf 3'); p.px(x,rows[i],'leaf 4') end end
-- where the wall meets the floor: a line of shade, deeper under the furniture
p.rect(0,176,W,2,'concrete 5'); p.hl(0,178,W,'concrete 6')
local function shade(x0,x1) p.rect(x0,176,x1-x0,3,'concrete 4'); p.dither(x0,179,x1-x0,2,'concrete 5','concrete 7') end
shade(18,50); shade(S.games.x-10,S.games.x+S.games.w+20); shade(S.web.x-12,S.web.x+S.web.w+12); shade(PRN-2,PRN+26)
shade(RACK-1,S.backend.x+S.backend.w+2); shade(BX0,BX1); shade(WX0-2,W)
-- perforated vent tiles in front of the rack
for _,tx in ipairs({288,320}) do for yy=186,192,2 do for xx=tx+3,tx+29,3 do p.px(xx+(yy%4)//2,yy,'concrete 5') end end end
-- a doormat inside the door
p.rect(14,186,26,20,'rust iron 2'); p.rect(15,187,24,18,'rust iron 1'); for y=189,203,2 do p.hl(17,y,20,'rust iron 2') end
-- the games corner's rug: night blue with a pink border and a row of pixels
do local g=S.games; local x0,x1=g.x-10,g.x+g.w+44
 p.rect(x0,181,x1-x0,13,'sky high'); p.rect(x0+1,182,x1-x0-2,11,'night'); p.hl(x0+2,183,x1-x0-4,'neon pink dim'); p.hl(x0+2,191,x1-x0-4,'neon pink dim')
 for x=x0+5,x1-6,6 do p.rect(x,186,2,2,((x//6)%2==0) and 'neon cyan dim' or 'neon violet dim') end
end
-- the chair mat at the desk
do local w=S.web; local x0,x1=DEV-22,DEV+22
 p.rect(x0,180,x1-x0,12,'concrete 7'); p.hl(x0,180,x1-x0,'W white'); p.hl(x0,191,x1-x0,'concrete 5'); p.vl(x0,180,12,'concrete 6'); p.vl(x1-1,180,12,'concrete 6')
end
-- hazard paint along the foot of the rack
for x=RACK-2,RACK+35 do p.rect(x,179,1,2,(((x-RACK)//3)%2==0) and 'neon yellow' or 'concrete 2') end
-- the anti-static mat in front of the bench
p.rect(BX0+4,180,BX1-BX0-8,15,'leaf 2'); p.hl(BX0+4,180,BX1-BX0-8,'leaf 3'); p.hl(BX0+4,194,BX1-BX0-8,'leaf 1')
for x=BX0+8,BX1-8,6 do for y=183,192,3 do p.px(x+(y%2),y,'leaf 1') end end
p.rect(BX1-22,184,9,7,'neon yellow dim'); p.rect(BX1-20,186,5,3,'leaf 2'); p.px(BX1-18,187,'neon yellow')
-- the boxed PC's shadow
p.rect(BOX.x-2,BOX.y+BOX.h-1,BOX.w+5,3,'concrete 5'); p.dither(BOX.x-3,BOX.y+BOX.h+2,BOX.w+7,1,'concrete 6','concrete 7')

---------------------------------------------------------------- props: what stands against the wall
p=P.props
-- by the door: shelves of boxed parts
p.rect(20,90,29,86,'concrete 3'); p.vl(20,90,86,'concrete 5'); p.rect(22,92,25,82,'concrete 2')
do local r=K.rng(9); local cols={'leaf 3','d denim','r rust','neon violet dim','holo dim','neon pink dim','k khaki','concrete 5'}
 for _,sy in ipairs({108,124,140,156,172}) do p.hl(22,sy,25,'concrete 5'); p.hl(22,sy+1,25,'concrete 1')
  local x=23
  while x<44 do local w=4+r(5); local h=8+r(6); if x+w>46 then w=46-x end; local c=cols[1+r(#cols)]
   p.rect(x,sy-h,w,h,c); p.hl(x,sy-h,w,'concrete 7'); if w>4 then p.rect(x+1,sy-h+3,w-2,2,'ink'); p.px(x+1,sy-3,'W white') end
   x=x+w+1 end
 end
end

-- GAMES: the television on its stand (the screen is the show: plain, dark green-black)
do local g=S.games
 local bx,by,bw,bh=g.x-6,g.y-6,g.w+24,g.h+13
 p.line(bx+bw//2,by,bx+bw//2-11,by-13,'concrete 4'); p.line(bx+bw//2+2,by,bx+bw//2+12,by-11,'concrete 4'); p.rect(bx+bw//2-2,by-2,6,2,'concrete 3')
 p.px(bx+bw//2-11,by-14,'concrete 6'); p.px(bx+bw//2+12,by-12,'concrete 6')
 p.rect(bx,by,bw,bh,'wood 3'); p.hl(bx,by,bw,'wood 4'); p.vl(bx,by,bh,'wood 4'); p.rect(bx,by+bh-2,bw,2,'wood 2'); p.vl(bx+bw-1,by,bh,'wood 2')
 for y=by+3,by+bh-4,5 do p.hl(bx+2,y,3,'wood 2') end
 p.rect(g.x-3,g.y-3,g.w+6,g.h+6,'concrete 1'); p.rect(g.x-1,g.y-1,g.w+2,g.h+2,'leaf 1')
 for _,c in ipairs({{g.x-1,g.y-1},{g.x+g.w,g.y-1},{g.x-1,g.y+g.h},{g.x+g.w,g.y+g.h}}) do p.px(c[1],c[2],'concrete 1') end
 p.hl(g.x+1,g.y-1,8,'leaf 2'); p.vl(g.x-1,g.y+1,5,'leaf 2')
 -- the speaker and the knobs beside the screen
 local cx=g.x+g.w+5
 p.rect(cx,g.y-3,11,g.h+6,'wood 2'); for y=g.y,g.y+12,2 do p.hl(cx+2,y,7,'wood 1') end
 p.disc(cx+5,g.y+20,2,'concrete 5'); p.px(cx+5,g.y+19,'concrete 7'); p.disc(cx+5,g.y+28,2,'concrete 5'); p.px(cx+6,g.y+28,'concrete 7')
 p.rect(cx+2,g.y+g.h-4,7,3,'ink')
 p.rect(bx+4,by+bh,5,2,'wood 1'); p.rect(bx+bw-9,by+bh,5,2,'wood 1')
 -- the stand: a console, two controllers' worth of cable, a stack of games
 local y0=by+bh+2
 p.rect(bx-3,y0,bw+6,176-y0,'concrete 3'); p.hl(bx-3,y0,bw+6,'concrete 5'); p.rect(bx,y0+3,bw,176-y0-5,'concrete 1'); p.rect(bx-3,174,bw+6,2,'concrete 2')
 p.rect(bx+4,y0+9,22,7,'concrete 6'); p.hl(bx+4,y0+9,22,'concrete 7'); p.rect(bx+7,y0+11,10,2,'concrete 2'); p.rect(bx+20,y0+12,3,2,'concrete 4')
 for i,c in ipairs({'neon red dim','d denim','leaf 3','neon yellow dim','neon violet dim'}) do p.rect(bx+34+(i%2),y0+16-i*3+1,20,2,c); p.px(bx+36+(i%2),y0+16-i*3+1,'W white') end
 p.rect(bx+58,y0+5,5,12,'holo dim'); p.rect(bx+64,y0+7,4,10,'r rust')
 -- the controller's cable to the beanbag, and the beanbag
 p.line(bx+24,y0+14,bx+bw+4,178,'ink'); p.hl(bx+bw+4,178,KID-8-(bx+bw+4),'ink')
 p.oval(KID-11,168,23,16,'rust iron 2'); p.oval(KID-9,168,17,7,'r rust'); p.rect(KID-10,181,21,2,'rust iron 1'); p.px(KID-6,170,'sodium 3')
end

-- WEB: the white monitor (a browser's tabs and address bar over the page, which is the show) on a desk
do local w=S.web
 local cx=w.x+w.w//2
 p.rect(w.x-3,w.y-16,w.w+6,w.h+22,'concrete 7'); p.hl(w.x-3,w.y-16,w.w+6,'W white'); p.vl(w.x+w.w+2,w.y-16,w.h+22,'concrete 6'); p.hl(w.x-3,w.y+w.h+5,w.w+6,'concrete 5')
 p.rect(w.x-1,w.y-14,w.w+2,w.h+15,'concrete 3')
 -- tabs
 p.rect(w.x,w.y-13,w.w,6,'concrete 4')
 p.px(w.x+2,w.y-11,'neon red'); p.px(w.x+5,w.y-11,'neon yellow'); p.px(w.x+8,w.y-11,'neon green')
 p.rect(w.x+12,w.y-12,26,5,'P pale steel'); p.px(w.x+14,w.y-10,'neon cyan dim'); p.hl(w.x+17,w.y-10,12,'concrete 4'); p.px(w.x+35,w.y-10,'concrete 4')
 p.rect(w.x+40,w.y-12,20,4,'concrete 5'); p.px(w.x+42,w.y-10,'r rust'); p.hl(w.x+45,w.y-10,9,'concrete 3'); p.px(w.x+63,w.y-10,'concrete 6')
 -- address bar
 p.rect(w.x,w.y-7,w.w,7,'P pale steel'); p.px(w.x+3,w.y-4,'concrete 4'); p.px(w.x+4,w.y-5,'concrete 4'); p.px(w.x+4,w.y-3,'concrete 4'); p.px(w.x+9,w.y-4,'concrete 4'); p.px(w.x+8,w.y-5,'concrete 4'); p.px(w.x+8,w.y-3,'concrete 4')
 p.rect(w.x+14,w.y-6,w.w-24,5,'W white'); p.px(w.x+16,w.y-4,'leaf 4'); p.text('LOCALHOST',w.x+19,w.y-6,'concrete 5',5); p.rect(w.x+w.w-7,w.y-5,4,3,'concrete 5')
 p.hl(w.x,w.y-1,w.w,'concrete 6')
 p.rect(w.x,w.y,w.w,w.h,'W white')
 p.rect(cx-2,w.y+w.h+2,5,1,'concrete 5')
 -- its foot, and the desk
 local dy=w.y+w.h+12
 p.rect(cx-3,w.y+w.h+6,7,5,'concrete 6'); p.vl(cx+3,w.y+w.h+6,5,'concrete 5'); p.rect(cx-11,dy-2,23,2,'concrete 7'); p.hl(cx-11,dy-1,23,'concrete 5')
 p.rect(w.x-12,dy,w.w+24,3,'W white'); p.hl(w.x-12,dy+2,w.w+24,'concrete 5'); p.rect(w.x-12,dy+3,w.w+24,1,'concrete 4')
 p.rect(w.x-10,dy+4,2,176-dy-4,'concrete 5'); p.rect(w.x+w.w+8,dy+4,2,176-dy-4,'concrete 5')
 -- drawers at the right, a tower and a bin under the desk
 p.rect(w.x+w.w-14,dy+4,20,176-dy-4,'concrete 7'); p.vl(w.x+w.w-14,dy+4,176-dy-4,'W white')
 for i=0,2 do local yy=dy+4+i*((176-dy-4)//3); p.hl(w.x+w.w-14,yy,20,'concrete 5'); p.hl(w.x+w.w-7,yy+3,6,'concrete 4') end
 p.rect(w.x-5,dy+6,12,176-dy-6,'concrete 1'); p.hl(w.x-5,dy+6,12,'concrete 3'); p.rect(w.x-3,dy+9,8,2,'concrete 2'); p.px(w.x+4,dy+13,'concrete 5')
 p.rect(w.x+14,168,9,8,'concrete 4'); p.hl(w.x+13,167,11,'concrete 5'); p.px(w.x+16,166,'W white'); p.px(w.x+19,165,'W white'); p.px(w.x+20,166,'concrete 7')
 -- on the desk: a plant, a keyboard and mouse, a mug (its steam is on `life`), a stack of sticky notes
 K.plant(p,w.x-5,dy,'small')
 p.rect(cx-22,dy-2,16,2,'concrete 4'); p.hl(cx-21,dy-2,14,'concrete 6'); p.rect(cx+14,dy-2,4,2,'concrete 5')
 p.rect(w.x+w.w+1,dy-6,5,6,'r rust'); p.hl(w.x+w.w+1,dy-6,5,'sodium 3'); p.px(w.x+w.w+6,dy-4,'r rust'); p.px(w.x+w.w+6,dy-3,'r rust')
 p.rect(w.x+w.w-12,dy-3,6,3,'neon yellow'); p.hl(w.x+w.w-12,dy-1,6,'neon yellow dim')
end

-- the 3D printer on its table, spools of filament under it (the print head is on `life`)
p.rect(PRN-2,162,28,2,'wood 4'); p.hl(PRN-2,162,28,'k khaki'); p.vl(PRN,164,12,'concrete 4'); p.vl(PRN+23,164,12,'concrete 4'); p.hl(PRN,172,24,'concrete 4')
p.ring(PRN+6,168,3,'neon green dim'); p.px(PRN+6,168,'concrete 3'); p.ring(PRN+14,168,3,'r rust'); p.px(PRN+14,168,'concrete 3'); p.ring(PRN+20,169,2,'holo dim')
p.rect(PRN+1,136,2,26,'concrete 3'); p.rect(PRN+21,136,2,26,'concrete 3'); p.rect(PRN+1,136,22,2,'concrete 3'); p.hl(PRN+1,136,22,'concrete 5')
p.rect(PRN,159,24,3,'concrete 2'); p.rect(PRN+2,160,5,1,'neon green dim'); p.rect(PRN+4,158,16,1,'concrete 5')
p.rect(PRN+9,153,6,5,'neon green dim'); p.rect(PRN+8,155,8,3,'neon green dim'); p.hl(PRN+10,153,4,'neon green'); p.vl(PRN+9,154,3,'leaf 4')
p.ring(PRN+12,131,3,'neon green dim'); p.px(PRN+12,131,'concrete 3'); p.vl(PRN+12,134,2,'concrete 4')

-- BACKEND AND DATA: the server rack (its LEDs are on `life`), and under the terminal a NAS, a UPS,
-- a stack of drives and a coil of network cable
do local b=S.backend
 p.rect(RACK,98,34,78,'concrete 1'); p.hl(RACK,98,34,'concrete 4'); p.vl(RACK,98,78,'concrete 3'); p.vl(RACK+33,98,78,'ink')
 for uy=102,166,8 do
  p.rect(RACK+3,uy,28,6,'concrete 2'); p.hl(RACK+3,uy,28,'concrete 3')
  if (uy//8)%3==0 then for i=0,5 do p.rect(RACK+12+i*3,uy+2,2,3,'concrete 1') end
  elseif (uy//8)%3==1 then for i=0,7 do p.px(RACK+12+i*2,uy+2,'concrete 4'); p.px(RACK+13+i*2,uy+4,'concrete 4') end
  else p.rect(RACK+12,uy+2,10,3,'ink'); p.hl(RACK+24,uy+3,5,'concrete 4') end
 end
 p.rect(RACK+2,174,6,2,'ink'); p.rect(RACK+26,174,6,2,'ink')
 -- a patch of blue and yellow leads between the units
 for i=0,3 do p.line(RACK+14+i*4,108,RACK+16+i*3,116,(i%2==0) and 'd denim' or 'neon yellow dim') end
 local y0=b.y+b.h+4
 p.vl(b.x+b.w//2,y0,6,'ink'); p.vl(b.x+b.w//2+2,y0,10,'concrete 2')
 -- NAS: four bays
 p.rect(b.x,158,28,18,'concrete 2'); p.hl(b.x,158,28,'concrete 4'); for i=0,3 do p.rect(b.x+2+i*6,161,5,11,'concrete 3'); p.hl(b.x+2+i*6,161,5,'concrete 5') end
 -- UPS
 p.rect(b.x+32,162,22,14,'concrete 1'); p.hl(b.x+32,162,22,'concrete 3'); p.rect(b.x+35,165,10,5,'leaf 2'); p.hl(b.x+36,167,5,'neon green dim'); p.rect(b.x+48,165,3,3,'concrete 4')
 -- drives
 for i=0,4 do p.rect(b.x+58,173-i*3,16,3,(i%2==0) and 'concrete 5' or 'concrete 4'); p.hl(b.x+58,173-i*3,16,'concrete 6'); p.px(b.x+60,174-i*3,'leaf 4') end
 -- the coil
 p.ring(b.x+86,169,6,'d denim'); p.ring(b.x+86,169,4,'d denim'); p.ring(b.x+86,169,5,'l denim light'); p.rect(b.x+90,174,4,2,'concrete 6')
end

-- ALSO COMFORTABLE IN: the repair bench under the whiteboard. An open PC at its left end (fans on
-- `life`), low things under the board, a lamp at the right end
do local a=S.also
 p.rect(BX0,152,BX1-BX0,4,'wood 3'); p.hl(BX0,152,BX1-BX0,'wood 4'); p.hl(BX0,155,BX1-BX0,'wood 2')
 p.rect(BX0+2,156,2,20,'concrete 2'); p.rect(BX1-4,156,2,20,'concrete 2'); p.rect(BX0+4,166,BX1-BX0-8,2,'wood 2')
 -- under it: a red tool chest, parts bins, a spool of cable
 p.rect(BX0+8,157,24,9,'neon red dim'); p.hl(BX0+8,157,24,'neon red'); p.hl(BX0+8,161,24,'ink'); p.rect(BX0+17,159,6,1,'concrete 6'); p.rect(BX0+17,163,6,1,'concrete 6')
 for i=0,3 do local c=({'d denim','neon yellow dim','leaf 3','r rust'})[i+1]; p.rect(BX0+38+i*10,159,9,7,c); p.hl(BX0+38+i*10,159,9,'concrete 7'); p.rect(BX0+40+i*10,161,5,2,'ink') end
 p.rect(BX0+10,169,14,7,'k khaki'); p.hl(BX0+10,169,14,'concrete 7'); p.rect(BX0+30,170,18,6,'concrete 3'); p.hl(BX0+30,170,18,'concrete 5')
 p.disc(BX1-20,171,4,'concrete 2'); p.disc(BX1-20,171,2,'neon cyan dim'); p.px(BX1-20,171,'concrete 6')
 -- the open PC
 local tx=BX0+4
 p.rect(tx,122,22,30,'concrete 2'); p.hl(tx,122,22,'concrete 4'); p.rect(tx+2,124,18,26,'ink'); p.rect(tx+3,126,8,7,'leaf 2'); p.hl(tx+3,126,8,'g gold'); p.px(tx+5,129,'g gold'); p.px(tx+8,130,'concrete 6')
 p.rect(tx+12,126,6,6,'concrete 3'); p.rect(tx+4,136,14,3,'concrete 4'); p.hl(tx+4,136,14,'concrete 5'); p.rect(tx+4,142,14,5,'concrete 4'); p.line(tx+6,133,tx+10,141,'neon red dim'); p.line(tx+8,133,tx+13,141,'neon yellow dim')
 p.rect(tx+24,138,3,14,'concrete 4'); p.vl(tx+24,138,14,'concrete 6')
 -- low on the bench: a tray of screws, a multimeter, a spool of solder, a board, a laptop
 p.rect(a.x+2,149,12,3,'concrete 4'); for i=0,4 do p.px(a.x+3+i*2,149,'concrete 7') end
 p.rect(a.x+18,146,7,6,'neon yellow dim'); p.rect(a.x+19,147,5,2,'leaf 1'); p.px(a.x+21,150,'ink'); p.line(a.x+25,150,a.x+30,151,'neon red dim')
 p.rect(a.x+33,148,5,4,'concrete 6'); p.hl(a.x+33,149,5,'concrete 4')
 p.rect(a.x+58,150,13,2,'leaf 3'); p.px(a.x+60,150,'g gold'); p.px(a.x+63,150,'ink'); p.px(a.x+64,150,'ink'); p.px(a.x+68,150,'g gold')
 p.rect(a.x+72,150,2,2,'r rust'); p.line(a.x+74,150,a.x+79,147,'concrete 6')
 -- the lamp
 local lx=BX1-5
 p.rect(lx-3,150,7,2,'concrete 3'); p.line(lx,150,lx+2,138,'concrete 4'); p.line(lx+2,138,lx-3,132,'concrete 4'); p.rect(lx-6,129,9,3,'concrete 5'); p.hl(lx-6,129,9,'concrete 7'); p.rect(lx-5,132,7,1,'sodium 5'); p.rect(lx-4,133,5,1,'sodium 4')
end

-- under the window: cartons and a hand truck
p.rect(WX0-2,160,20,16,'Q khaki shadow'); p.hl(WX0-2,160,20,'k khaki'); p.vl(WX0+7,160,16,'wood 3'); p.rect(WX0+1,150,14,10,'k khaki'); p.hl(WX0+1,150,14,'concrete 7'); p.hl(WX0+1,155,14,'Q khaki shadow')
p.rect(WX0+22,140,2,36,'concrete 4'); p.rect(WX0+34,140,2,36,'concrete 4'); p.hl(WX0+22,140,14,'concrete 5'); p.hl(WX0+22,152,14,'concrete 4'); p.hl(WX0+22,164,14,'concrete 4')
p.rect(WX0+20,174,18,2,'concrete 3'); p.disc(WX0+22,174,2,'ink'); p.disc(WX0+36,174,2,'ink')

---------------------------------------------------------------- boxes (sort=204): the boxed PC, at the right end
p=P.boxes
do local x=BOX.x
 p.rect(x,186,32,10,'k khaki'); p.hl(x,186,32,'concrete 7'); p.rect(x+15,186,2,10,'Q khaki shadow')
 p.rect(x,196,32,18,'Q khaki shadow'); p.vl(x,196,18,'k khaki'); p.hl(x,213,32,'wood 3'); p.rect(x+15,196,2,4,'k khaki')
 p.rect(x+4,200,10,10,'k khaki'); p.rect(x+6,202,6,5,'ink'); p.px(x+7,203,'neon green'); p.text('PC',x+18,203,'ink',5)
 p.px(x+27,198,'neon red'); p.px(x+28,198,'neon red'); p.px(x+27,199,'neon red')
end

---------------------------------------------------------------- front (1.2, over): low things nearest us
p=P.front
-- a crate of cables, a boxed monitor
p.rect(120,240,36,30,'d denim'); p.hl(120,240,36,'l denim light'); p.rect(120,241,36,3,'D denim dark')
for i=0,4 do p.ring(128+i*6,238,3,(i%2==0) and 'ink' or 'concrete 2') end
p.rect(404,236,44,34,'Q khaki shadow'); p.hl(404,236,44,'k khaki'); p.vl(404,236,34,'k khaki'); p.rect(412,243,18,13,'k khaki'); p.rect(414,245,14,8,'ink'); p.hl(415,246,6,'neon green dim'); p.rect(424,236,3,6,'wood 3')

---------------------------------------------------------------- frames and the animated layers
for _,n in ipairs(STILL) do K.trim(s,L[n]) end
local FRAMES=12
K.frames(s,FRAMES,0.1)
local ring8={{-1,-1},{0,-1},{1,-1},{-1,0},{1,0},{-1,1},{0,1},{1,1}}
-- a person standing with their back to us (the arcade's figure)
local function person(q,cx,fy,o)
 outlined(q,function(g)
  local legH,torH,headH,hw=10,11,8,5
  g.rect(cx-hw,fy-1,hw-1,2,o.shoe or 'b shoe'); g.rect(cx+1,fy-1,hw-1,2,o.shoe or 'b shoe')
  local ly=fy-1-legH
  g.rect(cx-hw,ly,hw-1,legH,o.pants); g.rect(cx+1,ly,hw-1,legH,o.pants)
  local ty=ly-torH
  g.rect(cx-hw,ty,hw*2,torH,o.top); g.rect(cx-hw,ly-2,hw*2,2,o.pants)
  for side=-1,1,2 do
   local ax=(side<0) and cx-hw-2 or cx+hw; local a=(side<0) and o.armL or o.armR
   if a=='fwd' then g.rect(ax,ty+1,2,5,o.top)
   else g.rect(ax,ty+1,2,torH-3,o.top); g.rect(ax,ty+torH-2,2,2,'s skin') end
  end
  local hy=ty-headH
  g.rect(cx-4,hy,8,headH,o.hair); g.hl(cx-3,hy+headH-1,6,'S skin shadow'); g.px(cx-5,hy+4,'s skin'); g.px(cx+4,hy+4,'s skin')
 end)
end
for f=1,FRAMES do
 ------------------------------------------------ lights: on the wall and the ceiling
 local q=K.pen(m.canvas(s,L.lights,f))
 -- the light panels (the second one flickers)
 for i,t in ipairs(PANELS) do local on=not (i==2 and (f==4 or f==10))
  q.rect(t[1],39,t[2]-t[1],4,on and 'W white' or 'concrete 6'); if on then q.hl(t[1]+2,40,t[2]-t[1]-4,'screen glow') end
 end
 -- TOOLS in green, twice the size of the 5x7 letters, with its dim ring; it drops out on frame 8
 if f~=8 then
  for _,d in ipairs(ring8) do bigtext(q,'TOOLS',SIGN-29+d[1],63+d[2],'neon green dim',2) end
  bigtext(q,'TOOLS',SIGN-29,63,'neon green',2)
 else bigtext(q,'TOOLS',SIGN-29,63,'neon green dim',2) end
 -- the clock's second hand, once round in the twelve frames
 local a=(f-1)/12*math.pi*2-math.pi/2
 q.line(456,74,456+math.floor(math.cos(a)*5+0.5),74+math.floor(math.sin(a)*5+0.5),'neon red')
 -- the aircon's ribbons
 for i=0,3 do local sway=((f+i*2)%6<3) and 0 or 1; q.vl(25+i*7,71,3,'neon red'); q.vl(25+i*7+sway,74,3,'neon red'); q.px(25+i*7+sway*2,77,'neon red dim') end
 -- the camera's lamp; OPEN in the window; the terminal's lamp
 q.px(266,59,(f%6<3) and 'neon red' or 'neon red dim')
 q.text('OPEN',WX0+11,WY0+8,(f==5) and 'neon red dim' or 'neon red',5)
 q.px(S.backend.x+S.backend.w+1,S.backend.y+S.backend.h+2,(f%4==0) and 'neon green dim' or 'neon green')
 K.trim(s,L.lights,f)

 ------------------------------------------------ life: in front of the props
 q=K.pen(m.canvas(s,L.life,f))
 -- GAMES: the television's lamp, the console's, and the kid on the beanbag with the controller
 do local g=S.games
  q.px(g.x+g.w+10,g.y+g.h,'neon red'); q.px(g.x+19,g.y+g.h+20,(f%6<3) and 'neon green' or 'neon green dim')
  local b=(f==3 or f==4 or f==9) and 1 or 0
  outlined(q,function(k)
   k.rect(KID-4,166+b,8,9-b,'neon yellow dim'); k.rect(KID-6,168+b,2,5,'neon yellow dim'); k.rect(KID+4,168+b,2,5,'neon yellow dim')
   k.rect(KID-4,159+b,8,7,'H hair light'); k.rect(KID-4,157+b,8,3,'neon red'); k.hl(KID-2,160+b,7,'neon red')
  end)
  q.hl(KID-3,165+b,6,'S skin shadow'); q.hl(KID-4,169+b,8,'neon yellow')
  q.rect(KID-10,175,21,3,'rust iron 2'); q.hl(KID-9,175,19,'r rust')
 end
 -- WEB: the developer at the desk, headphones on, typing; the tower's strip under the desk; steam off the mug
 do local w=S.web; local dy=w.y+w.h+12
  local nod=(f==6 or f==7) and 1 or 0; local l=(f%2==0) and 1 or 0
  outlined(q,function(k)
   k.rect(DEV-8,dy+3,16,5,'leaf 4'); k.rect(DEV-10,dy+3-l,2,5,'leaf 4'); k.rect(DEV+8,dy+2+l,2,5,'leaf 4')
   k.rect(DEV-4,dy-6+nod,8,8,'h hair')
   k.rect(DEV-7,dy+6,14,13,'concrete 2')
  end)
  q.hl(DEV-3,dy+1+nod,6,'S skin shadow'); q.hl(DEV-4,dy-7+nod,8,'concrete 1'); q.rect(DEV-6,dy-4+nod,2,4,'neon green dim'); q.rect(DEV+4,dy-4+nod,2,4,'neon green dim')
  q.hl(DEV-7,dy+6,14,'concrete 4'); q.hl(DEV-5,dy+10,10,'concrete 1'); q.hl(DEV-5,dy+14,10,'concrete 1')
  q.vl(DEV,dy+20,4,'concrete 3'); q.hl(DEV-7,180,15,'concrete 2'); q.px(DEV-7,181,'ink'); q.px(DEV,181,'ink'); q.px(DEV+7,181,'ink')
  local rgb={'neon pink','neon violet','neon cyan','neon green'}
  q.vl(w.x+5,dy+8,176-dy-10,rgb[1+((f-1)//3)%4])
  local sx=w.x+w.w+3; local t=(f-1)%6
  q.px(sx+(t//2)%2,dy-8-t,'W white'); if t>1 then q.px(sx+1-(t//2)%2,dy-6-t,'concrete 7') end
 end
 -- the 3D printer: the head runs along its bar, a lamp on the base
 do local tri={0,2,4,6,8,10,12,10,8,6,4,2}
  q.hl(PRN+3,149,18,'concrete 4'); q.rect(PRN+4+tri[f],148,3,4,'r rust'); q.px(PRN+5+tri[f],152,'sodium 5')
  q.px(PRN+19,160,(f%4<2) and 'neon cyan' or 'neon cyan dim')
 end
 -- BACKEND AND DATA: the rack's lamps, the NAS's, the UPS's
 do local b=S.backend
  for uy=102,166,8 do local k=uy//8
   q.px(RACK+5,uy+2,((k*7+f*3)%5==0) and 'neon green dim' or 'neon green')
   q.px(RACK+8,uy+2,((k*5+f)%4==0) and 'sodium 3' or 'sodium 1')
   if k%3==2 then q.hl(RACK+13,uy+3,1+((f+k)%8),'neon green dim') end
  end
  q.px(RACK+5,150+4,(f%6<3) and 'neon red' or 'neon red dim')
  for i=0,3 do q.px(b.x+4+i*6,170,((i*3+f)%4==0) and 'holo dim' or 'holo') end
  q.px(b.x+50,172,'neon green'); q.hl(b.x+36,167,3+(f%4),'neon green')
 end
 -- the bench: the open PC's fans cycling colour, the technician soldering, sparks and a thread of smoke
 do local tx=BX0+4
  local fan={'neon pink','neon cyan','neon violet','neon green'}
  q.ring(tx+15,129,2,fan[1+(f-1)//3]); q.ring(tx+15,144,2,fan[1+((f-1)//3+1)%4]); q.px(tx+6,148,(f%2==0) and 'neon green' or 'neon green dim')
  local work=(f>=3 and f<=9)
  person(q,TECH,183,{hair='h hair',top='d denim',pants='concrete 2',shoe='b shoe',armL='fwd',armR=work and 'fwd' or 'down'})
  q.hl(TECH-5,163,10,'k khaki'); q.vl(TECH-3,160,3,'k khaki'); q.vl(TECH+2,160,3,'k khaki')
  if work then
   local sx,sy=TECH+9,150
   if f%2==1 then q.px(sx,sy,'W white'); q.px(sx+1,sy-1,'neon yellow'); q.px(sx-1,sy-2,'sodium 3'); q.px(sx+2,sy+1,'sodium 4')
   else q.px(sx,sy,'neon yellow'); q.px(sx-2,sy-1,'sodium 4'); q.px(sx+2,sy-2,'sodium 3') end
   q.px(sx+((f//2)%2),sy-4-(f-3),'concrete 7'); q.px(sx+1-((f//2)%2),sy-2-(f-3),'concrete 7')
  end
 end
 K.trim(s,L.life,f)

 ------------------------------------------------ rain, through the window
 local w=K.pen(m.canvas(s,L.rain,f)); local phase=(f-1)%4
 K.rain(w,W-160,60,W,150,phase,9,'mist 4','mist 5',0.10)
 K.trim(s,L.rain,f)
end
K.note(s,'_lighting','Main light: five cool-white panels in the drop ceiling (the second flickers). Accent: green (TOOLS, LEDs). Each corner has its own colour: night blue and pink for games, white for web, black and green for the rack, wood and pale steel at the bench. The window at the right shows the wet alley.')
K.save(s,'scenes/store')
