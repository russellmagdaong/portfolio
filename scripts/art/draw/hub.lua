-- hub: the front-view street that replaces the top-down town map, redrawn as
-- clean pixel art from Codex's concept D ("Market under a skyway",
-- art/_work/concept/hub/hub-d.png), which stays on a hidden _ref layer.
--
--   "C:\aseprite\build\bin\aseprite.exe" -b --script scripts/art/draw/hub.lua
--
-- Writes art/hub.aseprite (the background in depth layers, with the floor,
-- stair, spawn and door slices the engine reads) and art/hub-objects/<id>.aseprite
-- (the six destinations as sprites with idle/hover tags and a base slice).
-- See art/README.md, "The hub".
--
-- The place, in world coordinates (480x270; the middle 320x180, x 80-399 and
-- y 45-224, is always on screen):
--   skyway deck y 55-70 across the whole width, its girder y 70-80, lamps hung
--   from it at x 150, 237 and 340; pillars x 60-86 and x 394-421 down to the
--   street; the two landings at y 141 (Home x 95-182, School x 300-396) joined
--   by the footbridge x 182-300; the shops x 150-334 under the landings and
--   the bridge, y 147-210; the sidewalk y 210-218 and the wet road below.
--   Russell walks on the sidewalk (feet y 208-218) and on the upper level
--   (feet y 138-144); the stairs rise from x 100 to 151 and from 384 to 333.
--
-- With --script-param only=<id> (e.g. only=store) it redraws just that destination's sprite,
-- art/hub-objects/<id>.aseprite, and leaves art/hub.aseprite alone (it may have hand edits).
--
-- STATUS 2026-11-16: the arcade and trophy shopfronts, the street and the
-- reflections were approved as the test area. The rest below is the first
-- full draft and has not been checked at 4x yet.
local K=dofile('scripts/art/draw/kit.lua')
local m=K.m
local ONLY=app.params.only
if ONLY=='' then ONLY=nil end
local W,H=480,270
local FRAMES=12
local STREET=210    -- the sidewalk's top edge
local UPPER=141     -- the landings' top edge
local JEEP_Y=234    -- the jeepney's wheels touch the road here, in the near lane

local function shifted(p,ox,oy)
 local q={}
 for k,f in pairs(p) do q[k]=f end
 q.rect=function(x,y,w,h,c) p.rect(x-ox,y-oy,w,h,c) end
 q.px=function(x,y,c) p.px(x-ox,y-oy,c) end
 q.hl=function(x,y,w,c) p.hl(x-ox,y-oy,w,c) end
 q.vl=function(x,y,h,c) p.vl(x-ox,y-oy,h,c) end
 q.frame=function(x,y,w,h,e,f) p.frame(x-ox,y-oy,w,h,e,f) end
 q.line=function(x,y,X,Y,c) p.line(x-ox,y-oy,X-ox,Y-oy,c) end
 q.oval=function(x,y,w,h,c) p.oval(x-ox,y-oy,w,h,c) end
 q.text=function(t,x,y,c,sz) p.text(t,x-ox,y-oy,c,sz) end
 q.dither=function(x,y,w,h,a,b) p.dither(x-ox,y-oy,w,h,a,b) end
 q.disc=function(x,y,r,c) p.disc(x-ox,y-oy,r,c) end
 q.ring=function(x,y,r,c) p.ring(x-ox,y-oy,r,c) end
 return q
end
local function textw(t) return #t*4-1 end

-- ======================================================================
-- Shared pieces.
local ICON={}
ICON.home=function(p,x,y,c,d)
 p.px(x+3,y,c); p.hl(x+2,y+1,3,c); p.hl(x+1,y+2,5,c); p.hl(x,y+3,7,c)
 p.rect(x+1,y+4,5,3,c); p.rect(x+3,y+5,1,2,d)
end
ICON.school=function(p,x,y,c,d) -- an open book
 p.rect(x,y+1,3,5,c); p.rect(x+4,y+1,3,5,c); p.vl(x+3,y,7,d); p.px(x+1,y+3,d); p.px(x+5,y+3,d); p.px(x,y+6,c); p.px(x+6,y+6,c); p.hl(x+1,y+6,2,d); p.hl(x+4,y+6,2,d)
end
ICON.arcade=function(p,x,y,c,d)
 p.rect(x+2,y,3,2,c); p.px(x+3,y+2,c); p.vl(x+3,y+3,2,d); p.hl(x+1,y+5,5,c); p.hl(x,y+6,7,c); p.px(x+6,y+4,d)
end
ICON.store=function(p,x,y,c,d) -- a monitor (the PC repair shop)
 p.frame(x,y,7,5,c,d); p.hl(x+1,y+1,2,c); p.px(x+3,y+5,c); p.hl(x+1,y+6,5,c)
end
ICON['trophy-shop']=function(p,x,y,c,d)
 p.hl(x,y,7,c); p.rect(x+1,y+1,5,3,c); p.px(x,y+1,c); p.px(x+6,y+1,c); p.hl(x+2,y+4,3,c); p.px(x+3,y+5,d); p.hl(x+1,y+6,5,c); p.px(x+2,y+2,d)
end
ICON['post-office']=function(p,x,y,c,d)
 p.frame(x,y+1,7,5,c,d); p.px(x+1,y+2,c); p.px(x+5,y+2,c); p.hl(x+2,y+3,3,c)
end

-- A lit-box destination sign at x,y (w wide, 19 tall): a casing, a neon tube
-- ring, the icon over the word. state: 'on', 'off' (tube and letters dim), 'hover'.
local function sign(p,x,y,w,id,word,c,dim,fill,state)
 local h=19
 p.rect(x,y,w,h,'concrete 2'); p.px(x,y,'concrete 3'); p.px(x+w-1,y,'concrete 3')
 local tube=(state=='off') and dim or c
 p.frame(x+1,y+1,w-2,h-2,tube,(state=='hover') and dim or fill)
 p.frame(x+2,y+2,w-4,h-4,dim,(state=='hover') and dim or fill)
 if state=='hover' then p.frame(x+3,y+3,w-6,h-6,fill,fill) end
 local lc=(state=='off') and dim or ((state=='hover') and 'W white' or c)
 local ld=(state=='hover') and c or dim
 local tx=x+(w-textw(word))//2
 if state~='off' then for _,o in ipairs({{1,0},{0,1},{1,1}}) do p.text(word,tx+o[1],y+11+o[2],ld,5); ICON[id](p,x+w//2-3+o[1],y+3+o[2],ld,ld) end end
 ICON[id](p,x+w//2-3,y+3,lc,ld)
 p.text(word,tx,y+11,lc,5)
end
local function pot(p,x,y)
 p.rect(x-3,y-5,7,5,'rust iron 2'); p.vl(x+2,y-5,5,'rust iron 1'); p.hl(x-4,y-5,9,'r rust')
 p.oval(x-5,y-11,6,5,'leaf 2'); p.oval(x-1,y-12,6,5,'leaf 3'); p.oval(x-3,y-14,5,4,'leaf 3'); p.px(x-2,y-13,'leaf 4'); p.px(x+1,y-11,'leaf 4'); p.px(x-4,y-9,'leaf 1')
end
local function planter(p,x,y,w,r)
 p.rect(x,y,w,4,'concrete 4'); p.hl(x,y,w,'concrete 5')
 for xx=x,x+w-4,3 do local h=3+r(4); p.oval(xx,y-h,4+r(3),h+1,({'leaf 2','leaf 3','leaf 3','leaf 4'})[1+r(4)]) end
 for i=1,w//6 do p.px(x+r(w),y-1-r(4),'leaf 4') end
end
local function ac(p,x,y)
 p.rect(x,y,10,8,'concrete 5'); p.hl(x,y,10,'concrete 6'); p.vl(x,y,8,'concrete 6'); p.rect(x+1,y+1,8,6,'concrete 4')
 p.ring(x+4,y+4,2,'concrete 3'); p.px(x+4,y+4,'concrete 5'); p.vl(x+8,y+2,4,'concrete 3')
end
local function window(p,x,y,w,h,lit,frame)
 p.rect(x-1,y-1,w+2,h+2,frame or 'concrete 2')
 if lit==false then p.rect(x,y,w,h,'concrete 1'); p.px(x+1,y+1,'concrete 3') return end
 p.rect(x,y,w,h,lit or 'sodium 3'); p.hl(x,y,w,'sodium 4')
 for xx=x+(w//2),x+w-2,math.max(3,w//2) do p.vl(xx,y,h,frame or 'concrete 2') end; p.hl(x,y+h//2,w,frame or 'concrete 2')
end
local function hazard(p,x,y,w,h)
 for yy=y,y+h-1 do for xx=x,x+w-1 do p.px(xx,yy,(((xx+yy)//4)%2==0) and 'sodium 2' or 'concrete 1') end end
 p.hl(x,y,w,'concrete 3'); p.hl(x,y+h-1,w,'concrete 3')
end
local function eave(p,x,y,w,h,base,rib,lit)
 p.rect(x,y,w,h,base); for xx=x+1,x+w-1,3 do p.vl(xx,y+1,h-2,rib) end
 p.hl(x,y,w,lit or 'sodium 3'); p.hl(x,y+h-1,w,'wood 1')
end
-- Clay roof tiles seen end-on: courses of 4-wide barrels, 3 rows each, every other course offset by 2.
local function tiles(p,x,y,w,courses)
 for c=0,courses-1 do local yy=y+c*3; local off=(c%2==1) and 2 or 0
  p.rect(x,yy,w,3,'R rust dark')
  for xx=x-off,x+w-1,4 do
   for _,t in ipairs({{0,0,'r rust'},{1,0,'r rust'},{2,0,'rust iron 2'},{0,1,'r rust'},{1,1,'rust iron 2'},{2,1,'rust iron 2'},{1,2,'rust iron 2'}}) do
    local px=xx+t[1]; if px>=x and px<x+w then p.px(px,yy+t[2],t[3]) end
   end
  end
 end
end
local function box(p,x,y,w,h,led) p.frame(x,y,w,h,'concrete 4','concrete 3'); p.hl(x,y,w,'concrete 5'); if led then p.px(x+w-2,y+1,led) end end
-- A stair of 13 steps (rise 5, run 4) from its foot at fx on the sidewalk,
-- rising to the right (dir 1) or left (dir -1). The railing goes on q, the rail layer (user data
-- stair): drawn in front of him only while he is on a stairway, behind him on the street.
local function stairs(p,q,fx,dir)
 local n=13
 local function px0(i) return (dir>0) and fx+i*4 or fx-i*4-3 end
 for i=0,n-1 do
  local x0=px0(i); local ty=STREET-(i+1)*5
  p.rect(x0,ty,4,STREET-ty,'concrete 3'); p.rect(x0,ty,4,5,'concrete 4'); p.hl(x0,ty,4,'concrete 6'); p.hl(x0,ty+1,4,'concrete 5')
  if i<4 then p.px(x0+1+(i%2),ty+1,'plaster 3') end
 end
 for i=0,n-1,3 do local x=px0(i)+((dir>0) and 1 or 2); q.vl(x,STREET-(i+1)*5-11,11,'concrete 5') end
 local ax,ay=px0(0)+((dir>0) and 1 or 2),STREET-5-11; local bx,by=px0(12)+((dir>0) and 1 or 2),STREET-65-11
 q.line(ax,ay,bx,by,'concrete 7'); q.line(ax,ay+1,bx,by+1,'concrete 6')
end
local function banderitas(p,x0,y0,x1,y1,sag,seed)
 local cols={'neon pink','sodium 3','neon cyan','neon green','sodium 4','neon violet'}
 local r=K.rng(seed or 4)
 for x=x0,x1 do local t=(x-x0)/(x1-x0); local y=math.floor(y0+(y1-y0)*t+sag*4*t*(1-t)+0.5); p.px(x,y,'ink')
  if (x-x0)%6==3 then local c=cols[1+r(#cols)]; p.hl(x-1,y+1,3,c); p.px(x,y+2,c); p.px(x,y+3,c) end
 end
end
-- A jeepney, side-on with its front to the right; x its back edge, y its wheels' bottom.
local function jeepney(p,x,y,bob,puff)
 local b=y-bob
 -- its shadow on the wet road
 p.rect(x+2,y-2,76,3,'night'); p.dither(x,y-1,80,2,'night','concrete 2')
 for _,wx in ipairs({x+12,x+50}) do p.disc(wx,y-6,6,'ink'); p.disc(wx,y-6,3,'concrete 4'); p.px(wx,y-7,'concrete 6') end
 p.rect(x,b-34,66,28,'haze'); p.rect(x,b-10,66,4,'sky low'); p.hl(x,b-34,66,'horizon glow'); p.vl(x,b-34,28,'horizon glow')
 p.rect(x+60,b-22,14,16,'haze'); p.rect(x+60,b-10,14,4,'sky low'); p.hl(x+60,b-22,14,'horizon glow')
 p.rect(x-2,b-38,70,4,'concrete 6'); p.hl(x-2,b-38,70,'concrete 7'); p.rect(x+2,b-40,60,2,'concrete 5')
 for i=0,32 do p.px(x+1+i*2,b-35,({'neon cyan','neon pink','sodium 4'})[1+i%3]) end
 p.rect(x+3,b-31,56,11,'sky high'); p.hl(x+3,b-31,56,'D denim dark'); p.rect(x+3,b-23,56,3,'night')
 for wx=x+3,x+59,11 do p.vl(wx,b-31,11,'horizon glow') end; p.px(x+20,b-28,'sodium 4'); p.px(x+42,b-28,'sodium 4')
 p.hl(x,b-18,60,'sodium 3'); p.hl(x,b-17,60,'neon pink'); p.hl(x,b-15,60,'g gold'); for i=0,6 do p.rect(x+4+i*8,b-14,3,2,'neon cyan') end
 p.hl(x,b-6,66,'concrete 6'); p.vl(x+59,b-31,25,'concrete 6')
 p.rect(x+61,b-30,12,9,'sky high'); p.hl(x+61,b-30,12,'D denim dark'); p.rect(x+62,b-29,8,3,'holo dim'); p.hl(x+62,b-29,8,'holo'); p.px(x+64,b-28,'holo')
 p.rect(x+66,b-22,10,2,'horizon glow'); p.rect(x+70,b-16,4,4,'sodium 5'); p.ring(x+71,b-14,2,'sodium 3')
 p.rect(x+64,b-12,10,4,'concrete 4'); for xx=x+65,x+73,2 do p.vl(xx,b-11,2,'concrete 2') end
 p.rect(x+60,b-8,18,3,'concrete 6'); p.hl(x+60,b-8,18,'concrete 7'); p.px(x+77,b-9,'sodium 4')
 if puff then p.oval(x-6-puff,y-10-puff,3+puff,2+puff//2,'concrete 4'); p.px(x-5-puff,y-10-puff,'concrete 5') end
end

-- ======================================================================
-- The six destinations (the hub objects), each drawing its facade in world coordinates.
local FACADE={}
FACADE.arcade={x=196,y=144,w=45,h=66,id='arcade',word='PROJECTS',c='neon pink',dim='neon pink dim',flicker=true,
 draw=function(p,state)
  tiles(p,196,144,45,1); p.hl(196,147,45,'neon pink'); p.hl(196,148,45,'neon pink dim'); for x=198,238,4 do p.px(x,148,(x%8==2) and 'sodium 5' or 'neon pink') end
  sign(p,198,149,41,'arcade','PROJECTS','neon pink','neon pink dim','night',state)
  p.rect(196,168,45,2,'plaster 1'); for x=198,238,3 do p.px(x,168,(x%6==2) and 'sodium 4' or 'neon pink'); p.px(x,169,(x%6==2) and 'sodium 1' or 'neon pink dim') end
  p.rect(196,170,6,40,'neon pink dim'); p.rect(235,170,6,40,'neon pink dim'); p.vl(196,170,40,'neon pink'); p.vl(201,170,40,'plaster 1'); p.vl(235,170,40,'plaster 1'); p.vl(240,170,40,'plaster 1')
  p.vl(197,173,28,'neon pink'); p.vl(198,173,28,'W white'); p.vl(199,173,28,'neon pink'); p.rect(197,172,3,1,'sodium 5'); p.rect(197,201,3,1,'sodium 5')
  p.vl(237,173,28,'neon pink'); p.vl(238,173,28,'W white'); p.vl(239,173,28,'neon pink'); p.rect(237,172,3,1,'sodium 5'); p.rect(237,201,3,1,'sodium 5')
  p.rect(197,203,4,6,'holo dim'); p.hl(197,204,4,'holo'); p.hl(197,206,4,'holo'); p.rect(236,204,4,5,'concrete 7'); p.px(237,205,'neon red'); p.px(238,207,'concrete 5')
  -- the opening: lintel at 170, the back wall 172-199, floor 200-206, step 207-209
  p.rect(202,170,33,2,'plaster 1'); p.hl(202,171,33,'neon pink dim')
  p.rect(202,172,33,29,'sky high'); p.rect(202,172,33,3,'night'); p.vl(218,175,26,'night'); p.rect(203,175,15,4,'neon pink dim'); p.rect(219,175,15,4,'neon pink dim')
  p.dither(203,179,15,2,'neon pink dim','sky high'); p.dither(219,179,15,2,'neon pink dim','sky high')
  p.hl(202,200,33,'night'); p.rect(202,201,33,6,'concrete 2'); p.dither(202,201,33,2,'neon pink dim','concrete 2')
  for x=204,232,6 do p.hl(x,205,3,'neon pink dim') end; p.hl(208,203,5,'neon pink'); p.hl(224,204,4,'neon pink')
  p.vl(218,172,3,'concrete 4'); p.rect(216,175,5,2,'sodium 2'); p.hl(216,177,5,'sodium 5')
  for _,cx in ipairs({206,221}) do
   p.rect(cx,178,8,22,'D denim dark'); p.rect(cx,178,8,2,'neon pink'); p.px(cx+3,178,'sodium 5'); p.rect(cx+1,181,6,2,'neon pink dim'); p.px(cx+2,181,'sodium 4')
   p.rect(cx+1,185,6,5,'neon cyan'); p.px(cx+2,186,'holo'); p.rect(cx+4,188,2,1,'sky high'); p.px(cx+1,189,'neon cyan dim')
   p.rect(cx+1,191,6,2,'d denim'); p.px(cx+2,191,'neon red'); p.px(cx+5,191,'sodium 4'); p.rect(cx,194,8,6,'night'); p.vl(cx+7,178,22,'ink'); p.vl(cx,180,20,'d denim')
  end
  p.rect(230,183,4,16,'night'); p.rect(231,186,2,3,'neon cyan dim'); p.px(231,190,'neon red')
  p.rect(202,207,33,3,'concrete 4'); p.hl(202,207,33,'concrete 5'); p.dither(202,209,33,1,'neon pink dim','concrete 4')
 end}
FACADE['trophy-shop']={x=242,y=144,w=46,h=66,id='trophy-shop',word='AWARDS',c='neon yellow',dim='neon yellow dim',
 draw=function(p,state)
  eave(p,242,144,46,5,'rust iron 2','rust iron 1','sodium 3'); p.rect(262,145,6,2,'rust iron 1')
  sign(p,245,149,40,'trophy-shop','AWARDS','neon yellow','neon yellow dim','wood 1',state)
  p.rect(242,168,46,2,'wood 3'); p.hl(242,168,46,'wood 4'); for x=245,284,5 do p.px(x,168,'sodium 5'); p.px(x,169,'sodium 3') end
  p.rect(242,170,46,40,'wood 2'); p.vl(242,170,40,'wood 3'); p.vl(287,170,40,'wood 1')
  -- the window: three shelves of cups behind lit glass
  p.frame(247,170,23,33,'wood 4','sodium 2'); p.hl(248,171,21,'sodium 4'); p.rect(248,172,21,2,'sodium 3')
  for _,sy in ipairs({181,190,199}) do
   p.rect(248,sy-7,21,7,'sodium 2'); p.hl(248,sy+1,21,'sodium 3')
   p.hl(248,sy,21,'wood 4'); p.hl(248,sy+1,21,'wood 2')
   for _,cx in ipairs({250,256,262}) do
    p.hl(cx,sy-7,5,'sodium 5'); p.rect(cx+1,sy-6,3,2,'g gold'); p.px(cx,sy-6,'g gold'); p.px(cx+4,sy-6,'sodium 1'); p.px(cx+2,sy-4,'g gold'); p.hl(cx+1,sy-3,3,'sodium 1'); p.hl(cx+1,sy-2,3,'g gold'); p.px(cx+1,sy-5,'sodium 5'); p.px(cx+3,sy-5,'sodium 1')
   end
  end
  p.rect(248,201,21,1,'sodium 1'); for x=250,266,4 do p.px(x,201,'g gold') end
  -- the door: 14 x 40, a lit pane, a brass handle
  p.frame(271,170,14,40,'wood 4','wood 2'); p.rect(274,173,8,15,'sodium 2'); p.hl(274,180,8,'wood 3'); p.vl(278,173,15,'wood 3'); p.hl(274,173,8,'sodium 3'); p.px(281,193,'g gold'); p.px(281,194,'g gold')
  p.rect(273,199,10,10,'wood 3'); p.hl(273,199,10,'wood 4'); p.px(274,201,'wood 2')
  p.vl(270,170,40,'wood 3'); p.vl(285,170,40,'wood 3'); p.rect(286,186,2,4,'concrete 5'); p.px(286,187,'neon green')
  p.rect(247,203,23,7,'wood 2'); p.hl(247,203,23,'wood 1'); p.hl(248,208,21,'wood 3'); p.hl(249,206,10,'sodium 1')
 end}
FACADE.store={x=150,y=144,w=46,h=66,id='store',word='TOOLS',c='neon green',dim='neon green dim',
 -- PC CLINIC, the computer repair shop (was the sari-sari store until 2026-11-17): a metal awning with
 -- a green LED strip, aluminium cladding, a glass door at x 166-180 (door:store is 170-176), a window
 -- of monitors on the left and a PC with lit fans on the right.
 draw=function(p,state)
  p.rect(150,144,46,5,'concrete 4'); p.hl(150,144,46,'concrete 6'); p.hl(150,148,46,'concrete 2'); for x=151,195,3 do p.px(x,146,'concrete 3') end
  sign(p,152,149,41,'store','TOOLS','neon green','neon green dim','night',state)
  p.rect(150,168,46,2,'concrete 2'); for x=150,195,2 do p.px(x,168,(x%6==0) and 'neon green' or 'neon green dim') end
  p.rect(150,170,46,40,'concrete 5'); for x=150,195,8 do p.vl(x,170,40,'concrete 4') end; p.vl(150,170,40,'concrete 6'); p.vl(195,170,40,'concrete 3')
  -- the left window: two monitors on a shelf, lit screens
  p.frame(153,173,12,30,'concrete 2','night'); p.hl(154,174,10,'mist 2')
  p.rect(154,178,10,7,'concrete 1'); p.rect(155,179,8,5,'neon green dim'); p.hl(156,180,5,'neon green'); p.hl(156,182,3,'neon green')
  p.rect(154,188,10,7,'concrete 1'); p.rect(155,189,8,5,'holo dim'); p.hl(156,190,6,'holo'); p.px(159,195,'concrete 3')
  p.hl(154,196,10,'concrete 4'); p.rect(155,198,8,3,'concrete 3'); p.px(161,199,'neon green')
  -- the door: glass in a dark frame, OPEN hung inside, a handle
  p.frame(166,170,14,40,'concrete 2','mist 2'); p.rect(168,172,10,34,'mist 1'); p.vl(169,173,10,'mist 3'); p.px(170,174,'mist 4')
  p.hl(168,180,10,'concrete 3'); p.rect(169,183,8,4,'ink'); p.hl(170,184,6,(state=='off') and 'neon red dim' or 'neon red')
  p.vl(177,190,4,'concrete 6'); p.rect(167,206,12,4,'concrete 3'); p.hl(167,206,12,'concrete 4')
  -- the right window: a PC with its side off, the fans lit
  p.frame(182,173,12,30,'concrete 2','night'); p.hl(183,174,10,'mist 2')
  p.rect(184,179,8,20,'concrete 1'); p.rect(185,180,6,18,'ink')
  p.ring(188,184,2,(state=='off') and 'neon pink dim' or 'neon pink'); p.ring(188,191,2,(state=='off') and 'neon cyan dim' or 'neon cyan'); p.px(186,196,'neon green')
  -- a sticker of a wrench on the cladding, a socket box
  p.rect(150,204,3,6,'concrete 3'); p.rect(193,178,3,4,'concrete 7'); p.px(194,179,'neon green')
 end}
FACADE['post-office']={x=288,y=144,w=46,h=66,id='post-office',word='CONTACT',c='neon red',dim='neon red dim',flicker=true,
 draw=function(p,state)
  for x=288,333 do local c=(((x-288)//3)%2==0) and 'neon red' or 'R rust dark'; p.vl(x,144,4,c); if (x-288)%3~=2 then p.px(x,148,c) end end; p.hl(288,144,46,'neon red dim')
  sign(p,290,149,41,'post-office','CONTACT','neon red','neon red dim','wood 1',state)
  p.rect(288,168,46,2,'neon red dim'); p.hl(288,168,46,'neon red'); for x=288,332,4 do p.rect(x,169,2,1,'R rust dark') end
  p.rect(288,170,46,40,'plaster 1'); p.vl(288,170,40,'plaster 2'); p.vl(333,170,40,'wood 1')
  for y=176,206,8 do p.hl(289,y,44,'wood 1') end
  -- the door: 19 x 41 in a red frame, glass above with the envelope, panel below
  p.frame(298,169,19,41,'neon red dim','R rust dark'); p.frame(299,170,17,40,'neon red','R rust dark'); p.rect(301,173,13,19,'sodium 2'); p.hl(301,173,13,'sodium 4')
  p.rect(304,180,7,5,'W white'); p.hl(304,180,7,'concrete 6'); p.px(306,181,'concrete 6'); p.px(308,181,'concrete 6'); p.px(307,182,'concrete 6')
  p.hl(300,194,15,'neon red dim'); p.rect(300,196,15,13,'R rust dark'); p.rect(302,198,11,9,'neon red dim'); p.px(312,201,'g gold'); p.px(312,202,'g gold')
  p.rect(321,190,8,19,'neon red'); p.rect(321,190,8,2,'neon red dim'); p.hl(321,192,8,'sodium 4'); p.rect(322,195,6,2,'W white'); p.rect(322,199,6,6,'neon red dim'); p.vl(328,190,19,'neon red dim'); p.rect(323,207,4,3,'concrete 2')
  p.rect(290,174,5,4,'concrete 3'); p.rect(291,175,3,2,'sodium 4'); p.px(292,178,'sodium 3')
  p.rect(290,188,5,7,'concrete 7'); p.px(291,189,'neon red'); p.px(293,191,'concrete 5'); p.hl(291,193,3,'concrete 5')
 end}
FACADE.home={x=96,y=80,w=91,h=61,id='home',word='HOME',c='neon cyan',dim='neon cyan dim',
 draw=function(p,state)
  tiles(p,96,80,91,2); p.hl(96,86,91,'wood 2'); p.hl(96,87,91,'wood 1')
  p.rect(100,88,83,53,'wood 3'); for y=94,138,6 do p.hl(100,y,83,'wood 2') end; p.vl(100,88,53,'wood 4'); p.vl(182,88,53,'wood 2')
  for _,px0 in ipairs({103,128,154,179}) do p.vl(px0,88,53,'wood 2'); p.vl(px0+1,88,53,'wood 4') end
  p.rect(108,88,12,3,'wood 2'); p.hl(108,88,12,'wood 4'); p.rect(123,89,4,4,'concrete 7'); p.px(124,90,'neon pink'); p.rect(176,88,6,6,'concrete 4'); p.vl(178,94,4,'concrete 5'); p.px(177,89,'neon cyan')
  p.vl(181,96,40,'concrete 4'); p.rect(179,120,5,4,'rust iron 2'); p.hl(179,120,5,'r rust'); p.oval(178,114,7,6,'leaf 3'); p.px(180,115,'leaf 4')
  sign(p,133,88,41,'home','HOME','neon cyan','neon cyan dim','night',state)
  -- the door: 23 x 44 between the first two posts, two glazed leaves under a denim awning
  p.rect(102,93,28,4,'d denim'); for x=103,129,3 do p.vl(x,93,4,'D denim dark') end; p.hl(102,93,28,'l denim light'); p.hl(102,96,28,'D denim dark')
  p.frame(105,97,23,44,'wood 4','wood 2'); p.hl(105,97,23,'k khaki')
  for lx=107,117,10 do p.rect(lx,99,9,40,'wood 2'); for cy=0,5 do for cx=0,1 do p.rect(lx+1+cx*4,100+cy*6,3,5,'sodium 3'); p.px(lx+1+cx*4,100+cy*6,'sodium 4') end end end
  p.vl(116,99,40,'wood 1'); p.rect(107,136,19,3,'wood 3'); p.px(115,120,'g gold'); p.px(118,120,'g gold')
  -- the window under the sign, its plant box, the air-con beside it
  local wx=147
  p.frame(wx,112,20,24,'wood 4','wood 2')
  for cy=0,3 do for cx=0,2 do p.rect(wx+2+cx*6,114+cy*5,5,4,(cy<3) and 'sodium 3' or 'sodium 2'); p.px(wx+2+cx*6,114+cy*5,'sodium 4') end end
  p.hl(wx,136,20,'wood 4'); p.rect(wx+3,136,5,2,'leaf 3'); p.px(wx+4,135,'leaf 4'); p.rect(wx+12,136,4,2,'leaf 2')
  ac(p,168,110); p.rect(134,109,7,6,'concrete 4'); p.hl(134,109,7,'concrete 5'); p.px(139,110,'neon green')
  p.rect(176,100,5,2,'concrete 4'); p.rect(177,102,3,2,'sodium 4'); p.px(178,104,'sodium 5')
  p.vl(131,110,28,'wood 2'); p.rect(130,126,3,4,'concrete 7'); p.px(131,127,'neon pink')
  K.vine(p,97,88,14,K.rng(81)); K.vine(p,185,88,18,K.rng(83)); p.oval(96,87,5,3,'leaf 3'); p.px(97,87,'leaf 4'); p.oval(183,87,5,3,'leaf 3'); p.px(185,87,'leaf 4')
 end}
FACADE.school={x=301,y=82,w=67,h=59,id='school',word='ABOUT ME',c='neon violet',dim='neon violet dim',
 draw=function(p,state)
  p.rect(301,82,67,4,'rust iron 1'); p.hl(301,82,67,'rust iron 2'); p.hl(301,85,67,'wood 1')
  p.rect(301,86,67,55,'concrete 4'); p.vl(301,86,55,'concrete 5'); p.vl(367,86,55,'concrete 3'); p.hl(301,104,67,'concrete 3'); p.hl(301,105,67,'concrete 5')
  for y=112,136,8 do p.hl(302,y,65,'concrete 3') end
  sign(p,303,86,41,'school','ABOUT ME','neon violet','neon violet dim','night',state)
  -- the hall window under the sign: a lit hall behind violet bars
  p.rect(303,107,41,34,'night'); p.rect(303,107,41,3,'concrete 4'); p.hl(303,109,41,'neon violet')
  p.rect(304,110,39,29,'sky high'); p.rect(304,130,39,9,'concrete 2'); p.hl(304,129,39,'concrete 3')
  for x=304,342,3 do p.vl(x,110,29,'neon violet dim') end; p.hl(303,118,41,'neon violet dim'); p.hl(303,128,41,'neon violet dim'); p.vl(323,110,29,'neon violet')
  for x=305,341,3 do p.px(x,111,'neon violet') end
  p.rect(303,139,41,2,'concrete 5')
  -- the door: 22 x 44 double doors, glass above, a lamp over them
  p.frame(353,88,5,7,'concrete 2','sodium 4'); p.px(355,91,'sodium 5'); p.hl(354,95,3,'concrete 2'); p.hl(350,96,11,'sodium 1')
  p.frame(345,97,22,44,'concrete 6','concrete 2'); p.frame(346,98,20,42,'concrete 3','night'); p.hl(346,98,20,'neon violet')
  for _,lx in ipairs({347,356}) do
   p.rect(lx,99,9,40,'neon violet dim'); p.rect(lx+1,100,7,14,'sky high'); p.hl(lx+1,100,7,'neon violet'); p.hl(lx+1,107,7,'neon violet dim'); p.vl(lx+4,100,14,'neon violet dim')
   p.rect(lx+1,116,7,10,'concrete 3'); p.rect(lx+1,128,7,9,'concrete 3'); p.hl(lx+1,137,7,'concrete 2')
  end
  p.vl(355,99,40,'night'); p.vl(354,119,4,'g gold'); p.vl(357,119,4,'g gold'); p.hl(347,139,18,'concrete 5')
 end}

-- ======================================================================
-- The background: art/hub.aseprite.
local s=Sprite(W,H,ColorMode.RGB)
s:setPalette(Palette{fromFile='art/palette.gpl'})
local L={}
L.ref=s.layers[1]; L.ref.name='_ref'
local ref=Image{fromFile='art/_work/concept/hub/hub-d.png'}
if ref then s:newCel(L.ref,1,ref,Point(0,0)) end
local names={{'sky','speed=0.1'},{'far','speed=0.3'},{'skyway',''},{'buildings',''},{'rail','stair'},{'street',''},{'reflections',''},{'jeepney','sort=230'},{'front','over'},{'rain','over'}}
local prev=L.ref
for _,n in ipairs(names) do L[n[1]]=K.layer(s,n[1],n[2],prev); prev=L[n[1]] end
local P={}
for _,n in ipairs({'sky','far','skyway','buildings','rail','street','front'}) do P[n]=K.pen(m.canvas(s,L[n])) end

------------------------------------------------------------ the sky
do local p=P.sky
 p.rect(0,0,W,12,'night'); p.dither(0,12,W,3,'night','sky high'); p.rect(0,15,W,13,'sky high'); p.dither(0,28,W,4,'sky high','D denim dark')
 p.rect(0,32,W,58,'D denim dark'); p.dither(0,90,W,4,'D denim dark','d denim'); p.rect(0,94,W,176,'d denim')
 local r=K.rng(2); for i=1,14 do local x=r(W); local y=36+r(30); p.hl(x,y,8+r(30),'sky high') end
end
------------------------------------------------------------ the far city (speed 0.3)
do local p=P.far
 K.skyline(p,{x0=40,x1=480,base=56,topMin=12,topMax=34,wMin=10,wMax=26,fill='sky high',win='sodium 2',winP=0.05,rng=K.rng(31),gap=3,cap=true,ant=true})
 K.skyline(p,{x0=60,x1=480,base=56,topMin=26,topMax=44,wMin=8,wMax=20,fill='night',win='sodium 3',winP=0.07,win2='holo dim',win2P=0.02,rng=K.rng(37),gap=4,cap=true})
 p.rect(222,26,26,30,'sky high'); for yy=29,52,4 do for xx=224,246,4 do if (xx*7+yy)%5<3 then p.px(xx,yy,'sodium 3') end end end
 p.vl(300,14,42,'neon pink dim'); p.vl(301,14,42,'neon pink dim'); for yy=16,40,3 do p.px(300,yy,'neon pink') end
 -- the gap over the bridge: three layers of towers going into the mist, nearer ones darker and more lit
 local function misty(o)
  local r=o.rng; local x=o.x0
  while x<o.x1 do
   local w=o.wMin+r(o.wMax-o.wMin+1); local top=o.topMin+r(o.topMax-o.topMin+1); local k=r()
   if k<0.3 then p.rect(x+2,top-3,w-4,3,o.fill); p.hl(x+2,top-3,w-4,o.edge)
   elseif k<0.5 then local ax=x+2+r(math.max(1,w-4)); p.vl(ax,top-6,6,o.fill); if o.beacon then p.px(ax,top-7,o.beacon) end end
   p.rect(x,top,w,147-top,o.fill); p.hl(x,top,w,o.edge); p.vl(x,top,147-top,o.edge)
   -- a lit tower has its windows in a band of floors (and a few odd ones); a dark one only a stray light
   local lit=r()<o.litT; local f0=top+3+r(math.max(1,(147-top)//2)); local f1=f0+6+r(14)
   for yy=top+3,146-o.wh,o.sy do
    local row=r()<o.rowP
    for xx=x+2,x+w-1-o.ww,o.sx do
     local inband=lit and yy>=f0 and yy<=f1
     if (inband and r()<0.7) or (row and lit and r()<0.8) or r()<0.03 then p.rect(xx,yy,o.ww,o.wh,(r()<0.75) and o.win or o.win2) end
    end
   end
   x=x+w+r(o.gap+1)
  end
 end
 local function fog(y0,y1,n,c,g) for i=1,n do p.hl(60+g(370),y0+g(y1-y0+1),14+g(40),c) end end
 misty{x0=60,x1=430,topMin=82,topMax=104,wMin=9,wMax=20,gap=6,fill='mist 4',edge='mist 5',win='sodium 2',win2='sodium 1',litT=0.6,rowP=0.05,ww=1,wh=1,sx=3,sy=3,rng=K.rng(41)}
 fog(100,116,8,'mist 5',K.rng(42))
 misty{x0=56,x1=430,topMin=94,topMax=112,wMin=10,wMax=22,gap=5,fill='mist 3',edge='mist 4',win='sodium 3',win2='sodium 2',litT=0.6,rowP=0.06,ww=2,wh=1,sx=3,sy=3,beacon='neon red dim',rng=K.rng(43)}
 fog(112,126,7,'mist 4',K.rng(44))
 p.hl(100,109,300,'concrete 4'); p.hl(100,110,300,'concrete 3'); for x=104,400,16 do p.vl(x,111,5,'concrete 3') end
 p.rect(236,105,34,4,'concrete 5'); p.hl(236,105,34,'concrete 6'); for x=238,268,4 do p.rect(x,106,2,2,'holo') end
 misty{x0=52,x1=430,topMin=106,topMax=122,wMin=8,wMax=18,gap=4,fill='mist 2',edge='mist 3',win='sodium 4',win2='sodium 3',litT=0.65,rowP=0.08,ww=2,wh=2,sx=3,sy=4,beacon='neon red',rng=K.rng(47)}
 p.vl(228,96,14,'neon cyan dim'); p.px(228,98,'neon cyan'); p.px(228,102,'neon cyan'); p.px(228,106,'neon cyan')
 p.vl(278,112,12,'neon pink dim'); p.px(278,114,'neon pink'); p.px(278,118,'neon pink')
 p.rect(190,118,9,5,'holo dim'); p.hl(190,119,9,'holo'); p.hl(190,121,9,'holo')
end
------------------------------------------------------------ the skyway and what stands behind it or on it
do local p=P.skyway; local r=K.rng(13)
 p.rect(0,0,60,210,'concrete 3'); p.vl(59,0,210,'concrete 2'); p.rect(0,0,8,210,'concrete 2')
 for y=0,200,45 do p.hl(0,y+40,60,'concrete 2'); p.hl(0,y+41,60,'concrete 4') end
 window(p,12,4,10,12,'sodium 3'); window(p,30,4,10,12,'sodium 3'); window(p,46,6,8,10,false)
 window(p,12,24,10,12,'sodium 2'); window(p,30,24,10,12,'sodium 3')
 planter(p,2,46,52,r); p.hl(2,42,52,'concrete 5'); for x=4,54,6 do p.vl(x,42,4,'concrete 5') end
 window(p,12,60,10,10,'sodium 3'); window(p,30,60,10,10,false); p.rect(44,56,10,8,'concrete 4'); p.hl(44,56,10,'concrete 5')
 window(p,10,96,12,12,'sodium 3'); window(p,32,96,10,12,'sodium 3'); planter(p,4,92,22,r); p.rect(28,86,10,6,'concrete 4'); p.px(36,87,'neon green')
 window(p,10,116,12,12,'sodium 2'); window(p,32,116,10,12,'sodium 3')
 K.vine(p,4,44,60,r); K.vine(p,56,60,40,r)
 p.rect(10,140,50,70,'plaster 1'); p.vl(10,140,70,'plaster 2'); p.rect(0,140,10,70,'concrete 2')
 p.rect(12,143,46,9,'neon red dim'); p.hl(12,143,46,'neon red'); for x=12,56,4 do p.rect(x,151,2,1,'R rust dark') end; p.hl(12,150,46,'R rust dark')
 window(p,18,156,10,10,'sodium 3','wood 2'); window(p,36,156,12,10,'sodium 3','wood 2')
 p.rect(28,172,14,38,'wood 2'); p.rect(30,174,10,30,'wood 1'); p.px(38,190,'g gold'); box(p,46,178,6,8,'neon cyan'); p.rect(14,176,8,6,'concrete 4'); p.px(20,177,'neon red')
 p.rect(44,10,52,46,'concrete 2'); p.vl(44,10,46,'concrete 3'); p.hl(44,14,52,'concrete 3'); for x=46,94,5 do p.vl(x,8,6,'concrete 1') end; p.hl(44,8,52,'concrete 1')
 for xx=48,90,10 do for yy=20,44,10 do p.rect(xx,yy,4,5,(r()<0.6) and 'sodium 2' or 'concrete 1') end end
 p.rect(70,2,3,8,'concrete 1'); p.px(71,1,'neon red')
 p.rect(380,4,100,52,'plaster 1'); p.vl(380,4,52,'plaster 2'); p.rect(420,56,60,154,'plaster 1'); p.vl(420,56,154,'plaster 2'); p.vl(479,0,210,'concrete 2')
 p.hl(380,4,100,'concrete 3'); for x=382,478,5 do p.vl(x,0,4,'concrete 2') end; p.hl(380,0,100,'concrete 2')
 for _,wx in ipairs({386,404,428,446,462}) do window(p,wx,18,12,14,(wx==404) and false or 'sodium 3','wood 1'); p.hl(wx-1,33,14,'wood 2') end
 planter(p,424,46,54,r); p.hl(422,42,58,'concrete 4'); for x=424,478,6 do p.vl(x,42,4,'concrete 4') end
 p.hl(420,84,60,'concrete 3'); p.hl(420,85,60,'plaster 2'); p.hl(420,130,60,'concrete 3'); p.hl(420,131,60,'plaster 2')
 window(p,428,88,14,12,'sodium 3','wood 1'); window(p,454,90,12,10,'sodium 2','wood 1'); planter(p,452,104,24,r)
 window(p,430,110,12,12,'sodium 3','wood 1'); window(p,456,110,14,12,'sodium 3','wood 1'); p.rect(426,124,8,5,'concrete 4'); p.px(432,125,'neon cyan')
 K.vine(p,468,56,80,r); K.vine(p,474,70,50,r); ac(p,466,138)
 window(p,428,140,16,14,'sodium 3','wood 2'); p.rect(422,160,42,5,'d denim'); for x=423,463,3 do p.vl(x,160,5,'D denim dark') end; p.hl(422,160,42,'l denim light'); p.hl(422,164,42,'D denim dark')
 p.rect(424,166,40,44,'concrete 3'); p.rect(426,168,36,40,'concrete 4'); for y=170,206,3 do p.hl(426,y,36,'concrete 3') end; p.vl(426,168,40,'concrete 5'); p.rect(440,200,8,3,'concrete 2')
 p.rect(468,166,6,4,'concrete 4'); p.rect(469,170,4,3,'sodium 4'); p.px(470,173,'sodium 5'); box(p,470,184,7,9,'neon green'); p.rect(466,148,12,8,'holo dim'); p.hl(467,150,10,'holo'); p.hl(467,153,10,'holo')
 p.rect(0,55,W,15,'concrete 4'); p.hl(0,55,W,'concrete 7'); p.rect(0,56,W,2,'concrete 6'); p.hl(0,58,W,'concrete 5'); p.hl(0,69,W,'concrete 3')
 for x=0,W,48 do p.rect(x,59,24,10,'concrete 5'); p.vl(x,58,11,'concrete 3'); p.vl(x+24,58,11,'concrete 3'); p.rect(x+26,60,4,7,'concrete 6'); p.px(x+27,61,'concrete 4'); p.px(x+27,65,'concrete 4') end
 for i=1,16 do local x=r(W); p.vl(x,59+r(4),4+r(6),'concrete 3') end; for i=1,8 do local x=r(W); p.hl(x,62+r(6),2+r(5),'concrete 6') end
 p.rect(0,70,W,2,'concrete 3'); p.rect(0,72,W,8,'wood 2'); p.hl(0,72,W,'wood 3'); p.hl(0,75,W,'wood 1'); p.hl(0,79,W,'wood 1'); for x=4,W,8 do p.px(x,73,'wood 3'); p.px(x,77,'wood 3') end
 p.hl(0,76,W,'concrete 3'); p.hl(0,77,W,'concrete 2'); for x=16,W,40 do p.rect(x,75,3,4,'concrete 4') end
 hazard(p,100,72,28,8); hazard(p,356,72,28,8)
 for _,lx in ipairs({150,237,340}) do p.vl(lx,80,3,'concrete 2'); p.rect(lx-5,83,11,2,'concrete 4'); p.hl(lx-4,82,9,'concrete 5'); p.rect(lx-6,85,13,1,'sodium 2'); p.rect(lx-3,85,7,2,'sodium 5'); p.hl(lx-5,87,11,'sodium 3'); p.hl(lx-7,88,15,'sodium 1'); p.dither(lx-9,89,19,2,'sodium 1','neon haze (a sky tint where signs light the air)') end
 for x=86,134,6 do p.vl(x,45,10,'neon pink dim') end; p.hl(86,45,49,'neon pink'); p.hl(86,50,49,'neon pink dim')
 p.rect(163,32,22,23,'concrete 6'); p.vl(167,33,22,'concrete 7'); p.rect(179,32,6,23,'concrete 5'); p.hl(163,32,22,'concrete 7'); p.hl(163,38,22,'concrete 4'); p.hl(163,47,22,'concrete 4'); p.oval(163,29,22,6,'concrete 6'); p.hl(165,29,18,'concrete 7')
 p.rect(165,52,2,3,'ink'); p.rect(181,52,2,3,'ink'); p.vl(174,22,8,'concrete 4'); p.px(174,21,'neon red')
 for _,mx in ipairs({188,196}) do p.rect(mx,30,2,25,'ink'); p.hl(mx-3,34,8,'ink'); p.hl(mx-2,40,6,'ink'); p.px(mx,29,'neon red') end
 for x=208,250,6 do p.vl(x,48,7,'ink') end; p.hl(208,48,43,'ink'); p.hl(208,52,43,'ink')
 for _,mx in ipairs({345,378}) do p.rect(mx,20,2,35,'ink'); p.hl(mx-3,26,8,'ink'); p.hl(mx-2,32,6,'ink'); p.px(mx,19,'neon red') end
 p.rect(350,42,20,13,'haze'); p.vl(353,42,13,'horizon glow'); p.rect(365,42,5,13,'sky low'); p.oval(350,39,20,6,'haze'); p.hl(352,39,16,'horizon glow'); p.rect(352,52,2,3,'ink'); p.rect(366,52,2,3,'ink')
 planter(p,290,51,40,r); planter(p,20,51,30,r)
 p.rect(258,40,26,15,'concrete 3'); p.hl(258,40,26,'concrete 4'); p.rect(260,38,22,2,'rust iron 1'); for x=261,281,3 do p.px(x,38,'rust iron 2') end; p.rect(268,45,6,10,'concrete 1'); p.px(272,50,'sodium 4'); p.rect(262,44,4,4,'sodium 2')
 p.oval(142,36,12,8,'concrete 6'); p.oval(144,37,8,5,'concrete 4'); p.rect(147,43,2,12,'concrete 5'); p.px(153,38,'concrete 7')
 p.rect(300,34,30,14,'holo dim'); for yy=35,47,2 do p.hl(301,yy,28,'holo') end; p.rect(304,38,8,6,'neon pink dim'); p.rect(305,39,6,4,'neon pink'); for xx=315,325,3 do p.rect(xx,39,2,1,'holo dim'); p.rect(xx,42,2,1,'holo dim') end; p.rect(300,48,2,7,'ink'); p.rect(328,48,2,7,'ink')
 p.rect(120,47,8,8,'wood 3'); p.hl(120,47,8,'wood 4'); p.rect(129,50,6,5,'wood 2'); p.rect(230,49,10,6,'concrete 4'); p.hl(230,49,10,'concrete 5'); p.px(238,50,'neon red')
 p.line(190,31,345,22,'ink'); p.line(198,32,378,26,'ink'); p.line(174,23,188,30,'ink')
 p.rect(400,38,3,17,'ink'); p.hl(397,42,9,'ink'); p.px(401,37,'neon red'); p.oval(56,20,10,6,'concrete 5'); p.rect(60,26,2,10,'concrete 4')
 K.vine(p,70,54,22,r); K.vine(p,76,56,16,r); K.vine(p,404,54,14,r)
 for x=0,W-1 do local t=x/W; p.px(x,30+math.floor(6*math.sin(t*math.pi*3)+0.5),'ink') end
 local g=K.rng(73)
 for _,v in ipairs({{18,30},{36,16},{112,14},{206,22},{262,28},{296,20},{312,32},{326,14},{368,18},{432,26},{456,36}}) do
  p.oval(v[1]-2,52,6,4,'leaf 3'); p.px(v[1],52,'leaf 4'); p.px(v[1]-2,54,'leaf 2'); K.vine(p,v[1],56,v[2],g)
 end
 planter(p,440,80,22,g)
end
------------------------------------------------------------ the buildings: pillars, pipes, landings, bridge, shops, stairs
do local p=P.buildings; local q=P.front; local r=K.rng(17)
 p.rect(95,147,301,63,'concrete 3'); p.hl(95,147,301,'concrete 4')
 for _,x in ipairs({150,196,242,288,334}) do p.vl(x,147,63,'concrete 2'); p.vl(x-1,147,63,'concrete 4') end
 for _,x in ipairs({148,240,332}) do p.rect(x,150,3,60,'concrete 4'); p.vl(x,150,60,'concrete 5'); p.rect(x-1,150,5,3,'concrete 5'); p.rect(x-1,180,5,2,'concrete 5') end
 for _,x in ipairs({194,286}) do p.rect(x,160,4,8,'concrete 6'); p.px(x+1,162,'neon green'); p.rect(x,176,4,6,'concrete 7'); p.px(x+2,178,'neon red') end
 p.rect(95,150,55,60,'concrete 3'); window(p,102,162,14,14,'sodium 3','wood 2'); eave(p,97,155,22,5,'rust iron 2','rust iron 1','r rust')
 box(p,120,158,8,10,'neon cyan'); p.rect(132,160,8,10,'holo dim'); p.hl(133,162,6,'holo'); p.hl(133,166,6,'holo'); p.rect(118,180,9,12,'concrete 4'); p.hl(118,180,9,'concrete 5'); p.rect(120,183,5,3,'concrete 2')
 window(p,370,164,16,14,'sodium 3','wood 2'); p.rect(366,158,24,5,'neon red dim'); p.hl(366,158,24,'neon red'); for x=366,388,4 do p.rect(x,162,2,1,'R rust dark') end
 box(p,352,170,8,10,'neon green'); p.rect(340,178,10,14,'concrete 4'); p.hl(340,178,10,'concrete 5'); p.rect(342,181,6,3,'concrete 2'); p.px(347,187,'neon red')
 for _,lx in ipairs({{95,88},{300,97}}) do
  p.rect(lx[1],UPPER,lx[2],6,'concrete 4'); p.hl(lx[1],UPPER,lx[2],'concrete 6'); p.rect(lx[1],UPPER+1,lx[2],2,'concrete 5'); p.hl(lx[1],UPPER+6,lx[2],'concrete 2')
  for x=lx[1]+6,lx[1]+lx[2]-6,12 do p.px(x,UPPER+4,'concrete 3') end
 end
 pot(p,98,UPPER); pot(p,184,UPPER+1); pot(p,297,UPPER+1); pot(p,392,UPPER)
 p.rect(97,82,86,59,'wood 2'); p.rect(300,82,96,59,'concrete 4')
 p.rect(384,116,4,25,'wood 2'); p.vl(384,116,25,'wood 3')
 p.oval(370,96,28,18,'leaf 2'); p.oval(366,104,20,14,'leaf 2'); p.oval(374,90,22,16,'leaf 3'); p.oval(380,98,16,12,'leaf 3'); p.oval(378,92,10,7,'leaf 4')
 for i=1,12 do p.px(370+r(26),94+r(18),'leaf 4') end; for i=1,8 do p.px(368+r(26),104+r(10),'leaf 1') end
 for _,bx in ipairs({291,369}) do p.rect(bx,108,8,30,'neon violet dim'); p.hl(bx,108,8,'neon violet'); p.vl(bx,108,30,'neon violet'); p.rect(bx+2,118,4,4,'g gold'); p.px(bx+3,119,'neon violet dim'); p.px(bx+2,136,'neon violet dim'); p.px(bx+5,136,'neon violet dim'); p.hl(bx-1,107,10,'concrete 5') end
 for _,px0 in ipairs({60,394}) do
  p.rect(px0,70,27,140,'concrete 3'); p.rect(px0,70,7,140,'concrete 4'); p.vl(px0,70,140,'concrete 5'); p.vl(px0+1,70,140,'haze'); p.rect(px0+24,70,3,140,'concrete 2')
  for y=86,160,24 do p.hl(px0,y,27,'concrete 2'); p.hl(px0,y+1,27,'concrete 4') end
  p.rect(px0-3,70,33,12,'concrete 4'); p.hl(px0-3,70,33,'concrete 6'); p.hl(px0-3,71,33,'concrete 5'); p.hl(px0-3,81,33,'concrete 2'); p.rect(px0-1,82,29,4,'concrete 4'); p.hl(px0-1,85,29,'concrete 2')
  for i=1,6 do p.vl(px0+9+r(14),92+r(60),3+r(8),'concrete 2') end
  p.rect(px0+10,120,6,8,'concrete 6'); p.px(px0+12,122,'concrete 4'); p.hl(px0+11,125,4,'concrete 4'); box(p,px0+9,142,9,7,'neon cyan')
  p.rect(px0+7,100,2,60,'concrete 2'); p.vl(px0+8,100,60,'concrete 5'); p.rect(px0+6,110,4,2,'concrete 5'); p.rect(px0+6,150,4,2,'concrete 5')
  hazard(p,px0+1,166,25,30)
  p.rect(px0-3,196,33,14,'concrete 3'); p.hl(px0-3,196,33,'concrete 6'); p.hl(px0-3,197,33,'concrete 5'); p.hl(px0-3,209,33,'concrete 2'); p.rect(px0+2,201,6,6,'concrete 2'); p.px(px0+20,204,'concrete 7')
 end
 p.rect(87,92,5,118,'R rust dark'); p.vl(88,92,118,'r rust'); p.vl(91,92,118,'neon red dim'); for yy=100,200,22 do p.rect(86,yy,7,2,'concrete 5'); p.hl(86,yy+1,7,'concrete 3') end
 p.rect(87,92,10,5,'R rust dark'); p.hl(87,93,10,'r rust'); p.hl(87,96,10,'neon red dim'); p.rect(96,92,5,10,'R rust dark'); p.vl(97,93,9,'r rust')
 box(p,84,148,9,8,'neon green')
 p.rect(388,80,5,82,'R rust dark'); p.vl(389,80,82,'r rust'); p.vl(392,80,82,'neon red dim'); p.rect(384,162,9,5,'R rust dark'); p.hl(384,163,9,'r rust'); p.hl(384,166,9,'neon red dim')
 p.rect(384,162,5,48,'R rust dark'); p.vl(385,167,43,'r rust'); p.vl(388,167,43,'neon red dim'); for yy=96,200,22 do local bx=(yy<162) and 387 or 383; p.rect(bx,yy,7,2,'concrete 5'); p.hl(bx,yy+1,7,'concrete 3') end
 p.rect(182,UPPER,118,6,'concrete 4'); p.hl(182,UPPER,118,'concrete 6'); p.rect(182,UPPER+1,118,2,'concrete 5'); p.hl(182,UPPER+6,118,'concrete 2'); p.hl(182,UPPER+5,118,'concrete 3')
 for x=186,296,12 do p.px(x,UPPER+4,'concrete 3') end; for x=190,290,24 do p.rect(x,UPPER+7,3,2,'concrete 3') end
 p.vl(212,80,61,'concrete 3'); p.vl(270,80,61,'concrete 3'); p.px(212,80,'concrete 4'); p.px(270,80,'concrete 4')
 for x=184,298,12 do p.vl(x,127,14,'concrete 5') end; p.hl(182,127,118,'concrete 6'); p.hl(182,128,118,'concrete 5'); p.hl(182,134,118,'concrete 4')
 banderitas(p,183,118,299,118,16,4)
 for x=190,292,12 do q.vl(x,132,10,'concrete 6') end; q.hl(182,132,118,'concrete 7'); q.hl(182,133,118,'concrete 6'); q.hl(182,138,118,'concrete 5')
 q.rect(188,139,5,3,'rust iron 2'); q.hl(188,139,5,'r rust'); q.oval(187,135,7,5,'leaf 3'); q.px(189,136,'leaf 4'); q.rect(287,139,5,3,'rust iron 2'); q.hl(287,139,5,'r rust'); q.oval(286,135,7,5,'leaf 3'); q.px(290,136,'leaf 4')
 p.line(40,112,70,122,'ink'); p.line(70,122,86,118,'ink'); p.line(421,120,440,126,'ink'); p.line(440,126,470,118,'ink')
 local g=K.rng(71)
 K.vine(p,89,97,46,g); K.vine(p,90,150,22,g); p.oval(86,99,6,4,'leaf 3'); p.px(88,99,'leaf 4'); p.oval(87,121,5,4,'leaf 2'); p.px(88,122,'leaf 4')
 K.vine(p,390,82,40,g); K.vine(p,391,96,28,g); p.oval(387,95,7,4,'leaf 3'); p.px(389,96,'leaf 4'); p.oval(386,160,7,5,'leaf 3'); p.px(388,161,'leaf 4')
 for _,px0 in ipairs({60,394}) do K.vine(p,px0-2,82,22,g); K.vine(p,px0+28,82,14,g); p.oval(px0-4,80,7,4,'leaf 3'); p.oval(px0+25,80,7,4,'leaf 2'); p.px(px0-2,81,'leaf 4') end
 K.vine(p,97,148,16,g); K.vine(p,146,148,10,g); K.vine(p,338,148,12,g); K.vine(p,393,148,18,g)
 stairs(p,P.rail,100,1); stairs(p,P.rail,384,-1)
end
------------------------------------------------------------ the street (sidewalk and road)
do local p=P.street
 p.rect(0,STREET,W,6,'concrete 5'); p.hl(0,STREET,W,'concrete 6')
 for x=0,W,16 do p.vl(x,211,2,'concrete 4'); p.vl(x+8,213,3,'concrete 4') end; p.hl(0,213,W,'concrete 4'); for x=4,W,16 do p.px(x,213,'concrete 5') end
 p.hl(0,216,W,'concrete 4'); p.hl(0,217,W,'concrete 3'); p.hl(0,218,W,'concrete 1')
 for _,lx in ipairs({150,237,340}) do p.dither(lx-14,211,29,5,'concrete 6','concrete 5') end
 p.rect(0,219,W,51,'concrete 2')
 local r=K.rng(21)
 for i=1,420 do local x=r(W); local y=219+r(51); local w=2+r(9); local q=r()
  p.hl(x,y,w,(q<0.45) and 'concrete 3' or ((q<0.75) and 'D denim dark' or ((q<0.9) and 'night' or 'concrete 1'))) end
 for i=1,40 do local x=r(W); local y=219+r(30); p.hl(x,y,1+r(3),'d denim') end
 p.hl(0,219,W,'concrete 1'); p.hl(0,269,W,'concrete 1'); p.rect(300,250,16,2,'concrete 3'); p.rect(100,246,12,2,'concrete 3')
 pot(p,146,STREET); pot(p,193,STREET); pot(p,291,STREET); pot(p,338,STREET)
 p.rect(452,190,14,12,'wood 3'); p.hl(452,190,14,'wood 4'); p.hl(452,196,14,'wood 2'); p.rect(458,194,14,16,'wood 3'); p.hl(458,194,14,'wood 4'); p.hl(458,202,14,'wood 2'); p.vl(471,194,16,'wood 2'); p.line(459,195,471,209,'wood 2')
 K.stool(p,130,199,'concrete 7','concrete 5'); pot(p,440,STREET)
 p.rect(344,204,7,4,'ink'); p.rect(350,202,3,3,'ink'); p.px(351,203,'sodium 4'); p.px(343,203,'ink'); p.px(342,202,'ink')
end

------------------------------------------------------------ the slices the engine reads
local function slice(name,x,y,w,h,data) local sl=s:newSlice(Rectangle(x,y,w,h)); sl.name=name; sl.data=data or ''; return sl end
slice('floor',0,208,W,10,'level=street')
slice('floor',97,138,288,6,'level=upper')
-- A stairs slice's diagonal is the line his feet follow: from the sidewalk at the
-- foot (y STREET) to the landing (y UPPER), over the step tops (rise 5, run 4).
slice('stairs:home',98,UPPER,55,STREET-UPPER,'lower=street; upper=upper; up=right')
slice('stairs:school',331,UPPER,55,STREET-UPPER,'lower=street; upper=upper; up=left')
slice('spawn',118,STREET,6,4,'level=street')
-- the jeepney parked on the road; the hub rides it to the text version of the site
slice('jeep',6,JEEP_Y-41,80,42)
for id,F in pairs(FACADE) do
 slice('building:'..id,F.x,F.y,F.w,F.h,'scene='..id..'; level='..((F.y<100) and 'upper' or 'street'))
end
slice('door:store',170,211,6,4,'level=street'); slice('door:arcade',215,211,6,4,'level=street'); slice('door:trophy-shop',275,211,6,4,'level=street'); slice('door:post-office',304,211,6,4,'level=street')
slice('door:home',113,139,6,4,'level=upper'); slice('door:school',353,139,6,4,'level=upper')

------------------------------------------------------------ frames: the jeepney, the reflections and the rain
for _,n in ipairs({'sky','far','skyway','buildings','rail','street','front'}) do K.trim(s,L[n]) end
K.frames(s,FRAMES,0.1)
local glows={
 {x0=40,x1=52,c='neon cyan',d='holo dim',k=0.5},{x0=58,x1=78,c='sodium 3',d='sodium 1',k=0.8},
 {x0=104,x1=116,c='sodium 3',d='sodium 1',k=0.5},{x0=130,x1=150,c='neon cyan',d='neon cyan dim',k=0.4},
 {x0=155,x1=192,c='neon green',d='neon green dim',k=1},{x0=203,x1=234,c='neon pink',d='neon pink dim',k=1},
 {x0=248,x1=283,c='sodium 3',d='sodium 1',k=1},{x0=296,x1=330,c='neon red',d='neon red dim',k=1},
 {x0=340,x1=360,c='neon violet',d='neon violet dim',k=0.4},{x0=372,x1=388,c='sodium 3',d='sodium 1',k=0.6},
 {x0=400,x1=412,c='sodium 2',d='sodium 1',k=0.5},{x0=426,x1=446,c='l denim light',d='D denim dark',k=0.6},{x0=452,x1=470,c='sodium 3',d='sodium 1',k=0.6},
}
for f=1,FRAMES do
 local q=K.pen(m.canvas(s,L.reflections,f))
 for gi,g in ipairs(glows) do
  local r=K.rng(gi*100+((f-1)//2))
  local cx=(g.x0+g.x1)//2; local hw=(g.x1-g.x0)//2
  for y=219,268 do
   local depth=(y-219)/49
   local n=math.floor(((1-depth)*5+1)*g.k)
   for i=1,n do
    if r()<0.95-depth*0.6 then
     local w=3+r(math.max(2,math.floor((10-depth*6)*g.k))); local x=cx-hw+r(math.max(1,2*hw-w))
     local bright=(r()<(0.55-depth*0.5)*g.k)
     q.hl(x,y,w,bright and g.c or g.d)
    end
   end
  end
 end
 local r2=K.rng(7+f)
 for i=1,30 do local x=r2(W); local y=220+r2(48); q.hl(x,y,2+r2(3),'concrete 4') end
 for i=1,6 do local x=r2(W); local y=222+r2(44); q.hl(x-1,y,3,'concrete 5'); q.px(x,y-1,'concrete 5') end
 K.trim(s,L.reflections,f)
 local j=K.pen(m.canvas(s,L.jeepney,f))
 jeepney(j,8,JEEP_Y,((f//3)%2==0) and 0 or 1,(f%6<3) and (f%6) or nil)
 K.trim(s,L.jeepney,f)
 local w=K.pen(m.canvas(s,L.rain,f)); local phase=(f-1)%4
 K.rain(w,0,0,W,H,phase,9,'concrete 4','concrete 4',0.03)
 K.trim(s,L.rain,f)
end
K.note(s,'_lighting','Warm sodium lamps hang from the skyway (x 150, 237, 340) and light the street from above; the shops and houses carry their own neon on their signs, thrown onto the wet road as broken strokes on the reflections layer. The far city through the gap and above the deck is bluer and flatter with distance. The six destinations are hub-objects/<id> sprites placed on their building: slices.')
L.ref.isVisible=false
if not ONLY then K.save(s,'hub') end

-- ======================================================================
-- The destinations: art/hub-objects/<id>.aseprite, drawn in world coordinates
-- onto a canvas one pixel bigger all round for the hover rim.
local function rim(im,c)
 local col=K.C[c]; local marks={}
 for y=0,im.height-1 do for x=0,im.width-1 do
  if app.pixelColor.rgbaA(im:getPixel(x,y))==0 then
   for _,d in ipairs({{1,0},{-1,0},{0,1},{0,-1}}) do local xx,yy=x+d[1],y+d[2]
    if xx>=0 and yy>=0 and xx<im.width and yy<im.height and app.pixelColor.rgbaA(im:getPixel(xx,yy))>0 then marks[#marks+1]={x,y}; break end
   end
  end
 end end
 for _,q in ipairs(marks) do im:drawPixel(q[1],q[2],col) end
end
for id,F in pairs(FACADE) do if not ONLY or ONLY==id then
 local o=Sprite(F.w+2,F.h+2,ColorMode.RGB); o:setPalette(Palette{fromFile='art/palette.gpl'})
 local layer=o.layers[1]; layer.name=id
 local states,durs
 if F.flicker then states={'on','on','off','on','hover'}; durs={0.9,0.6,0.08,0.5,0.1} else states={'on','hover'}; durs={0.1,0.1} end
 K.frames(o,#states,0.1)
 for f,st in ipairs(states) do
  o.frames[f].duration=durs[f]
  local im=m.canvas(o,layer,f); local p=shifted(K.pen(im),F.x-1,F.y-1)
  F.draw(p,st)
  if st=='hover' then rim(im,F.c) end
 end
 local t=o:newTag(1,#states-1); t.name='idle'; local h=o:newTag(#states,#states); h.name='hover'
 local sl=o:newSlice(Rectangle(1,F.h,F.w,1)); sl.name='base'
 o:saveAs('art/hub-objects/'..id..'.aseprite'); print('saved art/hub-objects/'..id..'.aseprite')
end end
