-- scenes/arcade: the PROJECTS arcade at night. Re-laid 2026-11-17 (see below).
--
--   "C:\aseprite\build\bin\aseprite.exe" -b --script scripts/art/draw/arcade.lua
--
-- Rewrites the whole room (and art/anim/arcade.aseprite). Do not run it after hand edits to the room.
-- Layers (back to front): sky 0.1, far 0.3, mid 0.6, rain 0.6 (animated, seen through the open shutter),
-- back, lights (animated: the signs and the chaser on the wall), floor, props, life (animated: the people,
-- the cat, the moths, the machines' screens and bulbs; the cabinets in art/objects/arcade/ are drawn between
-- props and life), tape (the cordon round the repair corner), front 1.2 over. 12 frames of 100 ms.
-- Nothing stands out on the floor: there is no platform slice, and every machine and person is against the
-- wall (feet at y 183 or higher, behind the line where his feet stop, y 184), so he is in front of all of it.
local K=dofile('scripts/art/draw/kit.lua')
local m=K.m
local s=m.open('scenes/arcade'); local W=s.width
while #s.frames>1 do s:deleteFrame(#s.frames) end

-- Where things are (x). The finished projects come first from the door; NOVA, the one being built,
-- is the last cabinet before the cordon. Past the cordon the floor slice ends: he cannot go in.
-- ODIN stands clear of the door, so the Exit button and its own prompt never show together.
local CAB={odin={64,30},tako={124,30},algebrawl={184,30},nova={464,26}}
local TOKEN,DANCE,CLAW,PRIZE=232,268,312,364   -- left edges of the token, dance and claw machines, the prize counter
local FLOOR_END=504                            -- the floor slice's right edge (his feet stop 4 px short of it)
local M1,LADDER,M2=522,553,563                 -- the repair corner: the open machine, the ladder, the machine under a tarp

local todo={}; for _,sl in ipairs(s.slices) do todo[#todo+1]=sl end
for _,sl in ipairs(todo) do
 local id=sl.name:match('^object:(.+)$')
 if id=='runner' or sl.name=='platform' then s:deleteSlice(sl)
 elseif id and CAB[id] then sl.bounds=Rectangle(CAB[id][1],142,CAB[id][2],40)
 elseif sl.name=='floor' then sl.bounds=Rectangle(0,176,FLOOR_END,49) end
end
-- the dance pad's layer went with its platform
local gone={}; for _,l in ipairs(s.layers) do if l.name=='pad' then gone[#gone+1]=l end end
for _,l in ipairs(gone) do s:deleteLayer(l) end

local L={}
for _,l in ipairs(s.layers) do L[l.name]=l end
L.rain=K.layer(s,'rain','speed=0.6',L.mid)
L.lights=K.layer(s,'lights','',L.back)
L.life=K.layer(s,'life','',L.props)
L.tape=K.layer(s,'tape','',L.life)
local P={}
for _,n in ipairs({'sky','far','mid','back','floor','props','tape','front'}) do P[n]=K.pen(m.canvas(s,L[n])) end

-- Signs (Russell, 2026-11-17): EXIT over the door; PROJECTS on the marquee; FINISHED over ODIN, TAKO and
-- Algebrawl; NOW BUILDING over NOVA; MORE PROJECTS / COMING SOON over the repair corner.

local function glyph(p,g,x,y,c)
 local yy=0
 for row in g:gmatch('[^/]+') do for i=1,#row do if row:sub(i,i)=='1' then p.px(x+i-1,y+yy,c) end end; yy=yy+1 end
end
local function ellipse(q,cx,cy,rx,ry,c)
 for i=0,95 do local a=i/96*math.pi*2; q.px(cx+math.floor(math.cos(a)*rx+0.5),cy+math.floor(math.sin(a)*ry+0.5),c) end
end
-- 5x7 letters drawn k times as large (the marquee)
local function bigtext(q,str,x,y,c,k)
 for ch in str:gmatch('.') do
  local g=m.big[ch]
  if g then local yy=0
   for row in g:gmatch('[^/]+') do for i=1,#row do if row:sub(i,i)=='1' then q.rect(x+(i-1)*k,y+yy*k,k,k,c) end end; yy=yy+1 end
  end
  x=x+6*k
 end
end
-- a pen that draws dx to the right (the machines keep the coordinates they were first drawn at)
local function shift(p,dx)
 local q={}
 function q.rect(x,y,w,h,c) p.rect(x+dx,y,w,h,c) end
 function q.px(x,y,c) p.px(x+dx,y,c) end
 function q.hl(x,y,w,c) p.hl(x+dx,y,w,c) end
 function q.vl(x,y,h,c) p.vl(x+dx,y,h,c) end
 function q.line(x,y,X,Y,c) p.line(x+dx,y,X+dx,Y,c) end
 function q.frame(x,y,w,h,e,f) p.frame(x+dx,y,w,h,e,f) end
 function q.oval(x,y,w,h,c) p.oval(x+dx,y,w,h,c) end
 function q.text(t,x,y,c,sz) p.text(t,x+dx,y,c,sz) end
 function q.disc(cx,cy,r,c) p.disc(cx+dx,cy,r,c) end
 function q.ring(cx,cy,r,c) p.ring(cx+dx,cy,r,c) end
 return q
end
-- draws a figure twice: first every piece one pixel fatter in ink (its outline), then the figure
local function outlined(q,draw)
 local o={}
 function o.rect(x,y,w,h) q.rect(x-1,y-1,w+2,h+2,'ink') end
 function o.px(x,y) o.rect(x,y,1,1) end
 function o.hl(x,y,w) o.rect(x,y,w,1) end
 function o.vl(x,y,h) o.rect(x,y,1,h) end
 draw(o); draw(q)
end
-- caution tape from one point to another, sagging in the middle
local function tape(p,x0,y0,x1,y1,sag)
 local n=math.max(math.abs(x1-x0),math.abs(y1-y0))
 local flat=math.abs(x1-x0)>=math.abs(y1-y0)
 for i=0,n do local t=i/n
  local x=math.floor(x0+(x1-x0)*t+0.5); local y=math.floor(y0+(y1-y0)*t+(sag or 0)*4*t*(1-t)+0.5)
  local c=((i//3)%2==0) and 'neon yellow' or 'ink'
  if flat then p.vl(x,y,2,c) else p.hl(x,y,2,c) end
 end
end
-- a cordon post standing at x, feet at y
local function post(p,x,y)
 p.rect(x-3,y-1,7,2,'concrete 2'); p.hl(x-3,y-1,7,'concrete 4')
 p.rect(x-1,y-17,3,16,'sodium 3'); p.vl(x-1,y-17,16,'sodium 4'); p.rect(x-1,y-13,3,2,'W white'); p.rect(x-1,y-7,3,2,'W white')
 p.rect(x-2,y-19,5,2,'neon yellow'); p.hl(x-2,y-17,5,'neon yellow dim')
end
local ARROW={l='00100/01000/11111/01000/00100',r='00100/00010/11111/00010/00100',u='00100/01110/10101/00100/00100',d='00100/00100/10101/01110/00100'}
local INVADER='00100000100/00010001000/00111111100/01101110110/11111111111/10111111101/10100000101/00011011000'
local toys={'neon pink','neon cyan dim','neon yellow dim','r rust','leaf 4','l denim light','k khaki','haze','sodium 3'}

---------------------------------------------------------------- sky (0.1)
local p=P.sky
p.rect(0,0,W,62,'night'); p.dither(0,62,W,3,'night','sky high'); p.rect(0,65,W,13,'sky high')
p.dither(0,78,W,3,'sky high','sky'); p.rect(0,81,W,11,'sky'); p.dither(0,92,W,3,'sky','sky low')
p.rect(0,95,W,8,'sky low'); p.dither(0,103,W,4,'sky low','mist 4'); p.rect(0,107,W,163,'mist 4')

---------------------------------------------------------------- far (0.3): fogged towers (the shutter shows layer x 400-485)
p=P.far
K.skyline(p,{x0=300,x1=600,base=150,topMin=104,topMax=130,wMin=10,wMax=24,fill='mist 3',win='mist 5',winP=0.04,rng=K.rng(11),gap=2,cap=true,ant=true})
-- one tall block with a lit crown, in view through the shutter
p.rect(436,94,14,56,'mist 3'); p.rect(440,90,6,4,'mist 3'); p.vl(443,84,6,'mist 3')
for y=98,140,5 do for x=438,448,4 do if ((x+y)%3)~=0 then p.px(x,y,'mist 5') end end end
K.skyline(p,{x0=320,x1=600,base=160,topMin=124,topMax=144,wMin=8,wMax=20,fill='mist 2',win='mist 4',winP=0.05,win2='sodium 1',win2P=0.02,rng=K.rng(5),gap=3,cap=true})

---------------------------------------------------------------- mid (0.6): the roofs next door (layer x 480-555 shows)
p=P.mid
p.rect(440,152,70,30,'mist 1'); p.rect(488,136,54,46,'mist 1'); p.rect(534,158,80,24,'mist 1')
p.hl(440,152,70,'mist 2'); p.hl(488,136,54,'mist 2'); p.hl(534,158,80,'mist 2')
for x=442,508,4 do p.px(x,153,'mist 2') end; for x=490,540,4 do p.px(x,137,'mist 2') end; for x=536,612,4 do p.px(x,159,'mist 2') end
-- a water tank on legs, an antenna with its red light, a lit stair window
p.rect(504,124,12,12,'mist 2'); p.hl(504,124,12,'mist 3'); p.vl(506,136,4,'mist 2'); p.vl(513,136,4,'mist 2')
p.vl(524,108,28,'mist 2'); p.hl(521,114,7,'mist 2'); p.hl(522,120,5,'mist 2'); p.px(524,107,'neon red')
p.rect(496,144,3,4,'sodium 1'); p.px(497,145,'sodium 2'); p.rect(548,166,4,3,'sodium 1')
p.rect(460,160,8,6,'mist 2'); p.rect(470,160,8,6,'mist 2'); p.hl(458,159,22,'mist 3')

---------------------------------------------------------------- back
p=P.back
-- the ceiling: painted black, a lighting truss, spot cans
p.rect(0,0,W,56,'ink')
p.rect(0,28,W,2,'concrete 2'); p.rect(0,38,W,2,'concrete 2')
for x=0,W,10 do p.line(x,30,x+5,37,'concrete 1'); p.line(x+5,30,x+10,37,'concrete 1') end
for _,x in ipairs({60,150,250,330,420,520}) do p.rect(x-2,40,5,6,'concrete 2'); p.px(x,46,'concrete 4'); p.px(x-1,45,'concrete 3') end
p.rect(0,52,W,4,'night'); p.hl(0,55,W,'sky high')
-- the walls: dark violet panels, a few painted stars, the racing stripe, a padded checker wainscot
p.rect(0,56,W,120,'night')
for x=0,586,32 do p.vl(x,56,94,'ink') end
local r=K.rng(61)
for i=1,70 do local x=r(586); local y=60+r(80); p.px(x,y,(r(4)==0) and 'haze' or 'sky low') end
p.rect(0,140,586,2,'neon pink dim'); p.rect(0,143,586,1,'neon cyan dim'); p.hl(0,145,586,'neon violet dim')
p.rect(0,150,586,24,'sky high')
for y=150,172,4 do for x=0,584,4 do if ((x//4)+(y//4))%2==0 then p.rect(x,y,4,4,'night') end end end
p.hl(0,150,586,'sky low'); p.rect(0,174,586,2,'ink')
-- a string of pennants under the ceiling's edge
local pc={'neon pink dim','neon cyan dim','neon yellow dim','neon violet dim'}
for i=0,62 do local x=22+i*9; local c=pc[1+i%4]; p.hl(x,57,5,c); p.hl(x+1,58,3,c); p.px(x+2,59,c) end
-- the door out, at the left edge (the opening is cut by the canvas)
K.exitLeft(p)

-- the neon moth's backing board (the tube is on `lights`)
p.frame(30,62,66,56,'concrete 2','ink')
-- PROJECTS: the marquee box on its hangers (the letters and the bulbs are on `lights`)
p.vl(120,46,14,'concrete 3'); p.vl(209,46,14,'concrete 3')
p.frame(108,60,114,30,'concrete 4','ink'); p.hl(109,61,112,'concrete 5'); p.hl(109,88,112,'concrete 2')
-- under the marquee: a poster, the clock, the house rules, a fire extinguisher
p.frame(112,96,19,26,'concrete 3','sky'); glyph(p,INVADER,116,100,'neon green'); p.hl(115,112,13,'neon pink dim'); p.hl(115,115,9,'sky low'); p.hl(115,118,11,'sky low')
p.disc(146,108,7,'concrete 4'); p.disc(146,108,6,'concrete 7'); p.vl(146,103,6,'ink'); p.hl(146,108,4,'ink'); p.px(146,108,'neon red')
p.frame(160,98,41,18,'wood 3','wood 2'); p.text('FREE PLAY',163,100,'sodium 4',5); p.text('FRIDAYS',167,108,'sodium 3',5)
p.rect(210,110,5,14,'neon red dim'); p.vl(210,110,14,'neon red'); p.rect(211,107,3,3,'concrete 5'); p.px(214,108,'ink'); p.vl(216,109,8,'ink'); p.hl(209,117,7,'concrete 7')
-- the long FINISHED board over ODIN, TAKO and Algebrawl (its bulbs are on `lights`)
p.frame(60,128,158,11,'wood 2','wood 3'); p.hl(61,129,156,'wood 4'); p.hl(61,137,156,'wood 2')
p.rect(120,129,39,9,'wood 2'); p.text('FINISHED',124,131,'sodium 4',5)
-- the high-score board over the token machine (its rows are on `lights`)
p.frame(228,62,38,50,'concrete 4','ink'); p.hl(229,63,36,'concrete 5'); p.text('HI SCORE',231,66,'neon yellow',5)
p.hl(231,73,32,'neon yellow dim')
-- a pair of speakers high on the wall
for _,x in ipairs({280,500}) do p.rect(x,66,14,20,'ink'); p.frame(x,66,14,20,'concrete 2','ink'); p.ring(x+7,78,4,'concrete 3'); p.px(x+7,78,'concrete 4'); p.ring(x+7,70,1,'concrete 3') end
-- PRIZES: the lit box over the prize wall (letters on `lights`)
p.frame(380,62,56,14,'concrete 4','ink')
-- the prize wall: three shelves of plushies, boxes and toys
p.rect(PRIZE,78,88,64,'sky high'); p.frame(PRIZE,78,88,64,'wood 2','sky high')
r=K.rng(14)
for i,y in ipairs({98,118,138}) do p.rect(PRIZE+1,y,86,2,'wood 3'); p.hl(PRIZE+1,y,86,'wood 4')
 local x=PRIZE+3
 while x<PRIZE+78 do local kind=r(3); local c=toys[1+r(#toys)]
  if kind==0 then p.oval(x,y-9,9,9,c); p.px(x+2,y-7,'ink'); p.px(x+6,y-7,'ink'); p.rect(x+1,y-11,2,2,c); p.rect(x+6,y-11,2,2,c); x=x+11
  elseif kind==1 then local h=6+r(8); p.rect(x,y-h,8,h,c); p.hl(x,y-h,8,'concrete 7'); p.rect(x+2,y-h+2,4,2,'ink'); x=x+10
  else p.disc(x+3,y-4,3,c); p.px(x+2,y-5,'W white'); x=x+8 end
 end
end
-- NOW BUILDING over NOVA (a lit cyan box on two hangers), and the cabinet's drawing pinned over it
p.frame(459,122,35,17,'neon cyan dim','ink'); p.hl(460,123,33,'holo dim')
p.text('NOW',471,125,'neon cyan',5); p.text('BUILDING',461,131,'neon cyan',5)
p.px(459,121,'concrete 5'); p.px(493,121,'concrete 5'); p.vl(459,118,3,'concrete 5'); p.vl(493,118,3,'concrete 5')
p.rect(463,84,28,30,'holo dim'); p.hl(463,84,28,'holo'); p.frame(470,89,13,20,'screen glow','holo dim'); p.hl(472,92,9,'screen glow'); p.rect(472,95,9,5,'holo'); p.hl(471,103,11,'screen glow')
p.hl(465,111,10,'screen glow'); p.hl(486,90,3,'screen glow'); p.hl(486,93,3,'screen glow'); p.vl(466,90,12,'holo'); p.px(463,84,'neon red'); p.px(490,84,'neon red')
-- the repair corner's sign, on two chains: hazard stripes round MORE PROJECTS / COMING SOON (the second line is on `lights`)
for y=56,92,2 do p.px(531,y,'concrete 4'); p.px(579,y,'concrete 4') end
for y=94,117 do for x=525,584 do p.px(x,y,(((x+y)//3)%2==0) and 'neon yellow' or 'ink') end end
p.rect(527,96,56,20,'ink'); p.text('MORE PROJECTS',529,99,'sodium 4',5)
-- the wall behind the machines being fixed: a panel off, the conduit and a junction box showing
p.rect(530,124,50,16,'concrete 1'); p.frame(530,124,50,16,'concrete 3','concrete 1')
K.conduit(p,{{533,136},{548,136},{548,128},{566,128},{566,134},{577,134}},'concrete 4'); K.junction(p,552,129,'neon red')

-- the shutter at the right end, half up: its box, rails, the rolled leaf, and the hole to the street
p.rect(586,56,54,14,'concrete 4'); p.hl(586,56,54,'concrete 5'); for y=58,68,2 do p.hl(588,y,52,'concrete 3') end
p.rect(586,70,4,106,'concrete 5'); p.vl(586,70,106,'concrete 4'); p.vl(589,70,106,'concrete 3')
p.rect(590,70,50,33,'concrete 3'); for y=72,100,3 do p.hl(590,y,50,'concrete 2') end; p.rect(590,100,50,3,'concrete 5'); p.hl(590,102,50,'concrete 2')
p.rect(590,103,50,73,0)

---------------------------------------------------------------- floor: arcade carpet
p=P.floor
p.rect(0,176,W,94,'sky high')
r=K.rng(90)
local motif={'010/101/010','11/10','101/010','1/1/1','111'}
local mc={'neon pink dim','neon cyan dim','neon yellow dim','sky low','neon violet dim','haze'}
for y=178,268,7 do for x=(y//7)%2*5,W,10 do
 local g=motif[1+r(#motif)]; local c=mc[1+r(#mc)]; local yy=0
 for row in g:gmatch('[^/]+') do for i=1,#row do if row:sub(i,i)=='1' then p.px(x+i-1+r(2),y+yy,c) end end; yy=yy+1 end
end end
p.rect(0,176,586,2,'night'); p.dither(0,178,586,2,'night','sky high')
-- shadows under the cabinets and the machines
for _,c in ipairs({{64,30},{124,30},{184,30},{464,26},{TOKEN,30},{DANCE,38},{CLAW,44},{PRIZE,88},{M1,30},{M2,24}}) do p.rect(c[1]-1,176,c[2]+2,7,'night') end
-- the dance machine's mat: flat on the carpet, he runs straight over it (its arrows light up on `life`)
p.rect(DANCE+2,185,34,11,'concrete 3'); p.rect(DANCE+3,186,32,9,'ink')
for i,d in ipairs({'l','d','u','r'}) do p.rect(DANCE+3+(i-1)*8,186,8,9,'concrete 1'); p.vl(DANCE+3+(i-1)*8,186,9,'concrete 2'); glyph(p,ARROW[d],DANCE+5+(i-1)*8,188,(i%2==0) and 'neon cyan dim' or 'neon pink dim') end
-- things dropped on the carpet: tokens, a strip of prize tickets
for _,c in ipairs({{116,190},{250,201},{331,188},{440,196},{186,214}}) do p.px(c[1],c[2],'g gold'); p.px(c[1]+1,c[2],'sodium 5') end
p.hl(410,188,9,'neon yellow dim'); p.px(412,188,'neon yellow'); p.px(415,188,'neon yellow'); p.px(418,188,'neon yellow')
-- the drop cloth under the machines being fixed
p.rect(512,178,74,18,'plaster 2'); p.hl(512,178,74,'plaster 1'); p.rect(514,196,70,1,'plaster 2'); p.hl(512,195,74,'plaster 1')
for _,c in ipairs({{520,184,9},{538,190,14},{560,183,7},{571,191,10}}) do p.hl(c[1],c[2],c[3],'plaster 1') end
for _,c in ipairs({{527,188},{546,185},{565,188},{579,186},{533,193}}) do p.px(c[1],c[2],'plaster 3') end
-- the threshold under the shutter, the street's wet concrete beyond it
p.rect(586,176,54,94,'concrete 3'); p.rect(590,176,50,3,'concrete 4'); p.hl(590,176,50,'concrete 5')
for x=592,638,6 do p.px(x,190+(x%4),'neon pink dim') end

---------------------------------------------------------------- props
p=P.props
-- by the door: the sweeper robot on its charging dock (its light blinks on `life`)
p.rect(18,170,4,13,'concrete 3'); p.vl(18,170,13,'concrete 5'); p.px(20,172,'neon green dim')
p.oval(22,178,14,6,'concrete 5'); p.hl(25,178,8,'concrete 6'); p.hl(24,183,10,'concrete 2'); p.rect(27,179,4,2,'concrete 3')
-- between the cabinets: a bin, a plant, a gumball machine
p.rect(42,166,10,16,'concrete 2'); p.hl(42,166,10,'concrete 4'); p.hl(43,169,8,'neon cyan dim')
K.plant(p,169,182,'bush')
p.rect(104,176,6,6,'concrete 3'); p.rect(102,180,10,2,'concrete 2'); p.rect(102,166,10,10,'neon red dim'); p.hl(102,166,10,'neon red'); p.rect(105,170,4,3,'ink'); p.px(106,171,'concrete 6')
p.disc(107,159,6,'concrete 7'); p.disc(107,159,5,'mist 1')
r=K.rng(8); for i=1,14 do p.px(103+r(9),157+r(7),toys[1+r(#toys)]) end
p.px(104,155,'W white'); p.px(105,154,'W white'); p.rect(105,151,5,2,'neon red dim')

-- the token machine
local t=shift(p,TOKEN-318)
t.rect(318,118,30,64,'concrete 3'); t.vl(318,118,64,'concrete 5'); t.hl(318,118,30,'concrete 5'); t.vl(347,118,64,'concrete 2')
t.rect(321,122,24,10,'ink'); t.text('TOKEN',322,124,'sodium 4',5)
t.rect(324,138,8,12,'concrete 2'); t.rect(325,140,6,3,'holo dim'); t.rect(336,140,6,2,'ink'); t.rect(336,146,6,2,'ink')
t.rect(322,160,22,8,'ink'); t.hl(322,160,22,'concrete 2'); t.px(328,166,'g gold'); t.px(331,166,'g gold'); t.px(330,165,'g gold')
-- the dance machine: the tall cabinet against the wall (its mat is on the floor layer)
t=shift(p,DANCE-350)
t.rect(350,92,38,90,'sky low'); t.vl(350,92,90,'haze'); t.vl(387,92,90,'sky'); t.rect(352,94,34,10,'ink')
t.rect(354,108,30,22,'concrete 2'); t.rect(356,110,26,18,'ink')
t.rect(352,134,8,26,'ink'); t.rect(378,134,8,26,'ink'); for _,x in ipairs({356,382}) do t.ring(x,141,2,'concrete 3'); t.ring(x,152,2,'concrete 3') end
t.rect(362,138,14,24,'sky'); t.hl(362,138,14,'haze'); t.rect(350,180,38,2,'ink')
-- the claw machine: pink cabinet, glass box of plushies (the claw on its gantry is on `life`)
t=shift(p,CLAW-396)
t.rect(396,96,44,10,'neon pink dim'); t.hl(396,96,44,'neon pink'); t.text('CLAW',410,99,'sodium 5',5)
t.rect(396,106,44,46,'concrete 6'); t.rect(398,107,40,44,'night'); t.hl(398,107,40,'mist 2')
t.hl(399,110,38,'concrete 5')
r=K.rng(3)
for i=1,16 do local x=399+r(32); local y=139+r(8); t.oval(x,y,6,5,toys[1+r(#toys)]); t.px(x+1,y+1,'ink'); t.px(x+4,y+1,'ink') end
t.rect(399,147,38,4,'wood 3'); t.rect(428,136,9,11,'ink'); t.hl(428,136,9,'concrete 4')
for x=400,436,6 do t.px(x,108,'W white') end; t.vl(399,108,40,'concrete 7')
t.rect(396,152,44,30,'neon pink dim'); t.vl(396,152,30,'neon pink'); t.rect(400,156,36,8,'ink'); t.disc(412,160,2,'neon red'); t.rect(420,159,6,2,'concrete 5'); t.vl(422,157,2,'concrete 6')
t.rect(410,168,16,8,'ink'); t.hl(410,168,16,'concrete 2'); t.rect(396,180,44,2,'ink')
-- the prize counter: glass front, prizes inside, a bell, the till
p.rect(PRIZE,150,88,32,'sky high'); p.rect(PRIZE,148,88,3,'concrete 6'); p.hl(PRIZE,148,88,'concrete 7')
p.rect(PRIZE+3,152,82,20,'mist 1'); p.hl(PRIZE+3,152,82,'mist 3')
r=K.rng(40)
for x=PRIZE+6,PRIZE+76,9 do local c=toys[1+r(#toys)]; p.rect(x,164,6,7,c); p.hl(x,164,6,'concrete 7') end
p.rect(PRIZE,172,88,10,'ink'); for x=PRIZE+4,PRIZE+84,8 do p.px(x,176,'neon pink dim') end
p.disc(PRIZE+10,145,3,'g gold'); p.hl(PRIZE+7,147,7,'concrete 5'); p.px(PRIZE+9,143,'sodium 5')
p.rect(PRIZE+62,136,20,12,'concrete 2'); p.rect(PRIZE+64,138,12,5,'holo dim'); p.px(PRIZE+66,140,'holo'); p.rect(PRIZE+78,140,3,6,'concrete 3')

-- the repair corner, behind the cordon. A machine with its front off: the board and the wires showing.
p.frame(M1,142,30,40,'ink','concrete 3'); p.vl(M1+1,143,38,'concrete 5')
p.rect(M1+2,144,26,8,'concrete 2'); p.rect(M1+4,145,9,6,'concrete 7'); p.hl(M1+5,147,7,'concrete 4'); p.hl(M1+5,149,5,'concrete 4')
p.rect(M1+3,154,24,12,'ink'); p.rect(M1+5,156,9,8,'leaf 2'); p.px(M1+6,157,'leaf 4'); p.px(M1+9,159,'g gold'); p.px(M1+11,161,'leaf 4'); p.px(M1+7,162,'neon red'); p.hl(M1+6,160,3,'leaf 4')
p.line(M1+15,158,M1+18,171,'neon red'); p.line(M1+16,157,M1+22,175,'neon yellow'); p.line(M1+14,160,M1+11,173,'neon cyan')
p.rect(M1+1,168,28,5,'concrete 4'); p.hl(M1+1,168,28,'concrete 5'); p.rect(M1+4,175,10,6,'ink'); p.px(M1+6,177,'concrete 4')
-- the ladder up to the sign
p.vl(LADDER,118,65,'concrete 6'); p.vl(LADDER+7,118,65,'concrete 5'); for y=123,178,6 do p.hl(LADDER+1,y,6,'concrete 6') end
p.px(LADDER,182,'ink'); p.px(LADDER+7,182,'ink')
-- a machine still under its blue tarp, roped, with a question mark on its tag
p.rect(M2+2,178,20,4,'concrete 2')
p.rect(M2,145,24,33,'d denim'); p.rect(M2+1,143,22,2,'d denim'); p.hl(M2+2,143,20,'l denim light'); p.vl(M2,146,30,'l denim light')
for _,c in ipairs({{5,147,22},{11,150,26},{17,146,24},{21,151,20}}) do p.vl(M2+c[1],c[2],c[3],'D denim dark') end
for x=M2,M2+23 do if (x%3)~=0 then p.px(x,178,'d denim') end end
p.hl(M2,160,24,'k khaki'); p.px(M2+12,161,'k khaki'); p.px(M2+13,162,'Q khaki shadow')
p.rect(M2+7,148,9,10,'concrete 7'); p.text('?',M2+10,150,'ink',5)
-- tools on the drop cloth: the toolbox, a wrench, a cone, a coil of cable
p.rect(567,186,14,7,'neon red dim'); p.hl(567,186,14,'neon red'); p.hl(571,184,6,'concrete 5'); p.px(571,185,'concrete 5'); p.px(576,185,'concrete 5'); p.px(574,189,'g gold')
p.hl(527,192,7,'concrete 6'); p.px(526,191,'concrete 6'); p.px(526,193,'concrete 6'); p.px(534,192,'concrete 7')
p.rect(553,193,9,2,'sodium 2'); p.rect(555,189,5,4,'sodium 3'); p.hl(555,190,5,'W white'); p.rect(556,185,3,4,'sodium 3'); p.px(557,184,'sodium 3')
p.ring(590,190,3,'ink'); p.ring(590,190,2,'concrete 2')
-- in the open shutter: the next machine, still boxed, on a hand truck
p.vl(630,126,55,'neon red dim'); p.hl(626,126,5,'neon red dim'); p.rect(601,181,31,2,'concrete 6'); p.disc(604,183,2,'ink'); p.px(604,183,'concrete 5')
p.rect(604,140,24,41,'wood 4'); p.vl(604,140,41,'k khaki'); p.hl(604,140,24,'k khaki'); p.vl(627,140,41,'wood 3'); p.vl(615,141,40,'Q khaki shadow')
p.hl(604,158,24,'wood 2'); p.hl(604,172,24,'wood 2'); p.text('NEW',610,147,'wood 1',5)
glyph(p,ARROW.u,607,162,'wood 1'); glyph(p,ARROW.u,620,162,'wood 1')

---------------------------------------------------------------- tape: the cordon round the repair corner
p=P.tape
tape(p,518,167,640,165,4)                         -- along the back, in front of the machines
tape(p,518,168,521,187,0); tape(p,521,187,524,206,0)  -- down the side he would walk in from
tape(p,524,206,640,203,5)                         -- along the front
post(p,518,186); post(p,521,205); post(p,524,224)
-- a board hung on the side tape
p.frame(509,192,20,10,'neon yellow','ink'); p.text('SOON',511,194,'neon yellow',5)

---------------------------------------------------------------- front (1.2, over)
p=P.front
-- the corner of an air hockey table, a stool
p.rect(150,232,120,6,'mist 2'); p.hl(150,232,120,'neon cyan'); p.rect(150,238,120,8,'sky low'); p.hl(150,238,120,'haze')
p.disc(210,234,2,'neon red'); p.oval(176,233,8,3,'neon yellow dim')
p.rect(160,246,6,24,'ink'); p.rect(254,246,6,24,'ink')
p.rect(470,240,22,4,'neon pink dim'); p.hl(470,240,22,'neon pink'); p.rect(472,244,3,26,'ink'); p.rect(487,244,3,26,'ink')

---------------------------------------------------------------- the people (back to us unless said), on `life`
-- o: kid, hair, top, stripe, pants, shoe, bob (0/1: knees bent), armL/armR ('down', 'up', 'fwd'), hat, tail (ponytail side)
local function person(q,cx,fy,o)
 outlined(q,function(g)
  local legH=o.kid and 7 or 10; local torH=o.kid and 8 or 11; local headH=o.kid and 7 or 8; local hw=o.kid and 4 or 5
  local b=o.bob or 0
  g.rect(cx-hw,fy-1,hw-1,2,o.shoe or 'b shoe'); g.rect(cx+1,fy-1,hw-1,2,o.shoe or 'b shoe')
  local ly=fy-1-legH+b
  g.rect(cx-hw,ly,hw-1,legH-b,o.pants); g.rect(cx+1,ly,hw-1,legH-b,o.pants)
  local ty=ly-torH
  g.rect(cx-hw,ty,hw*2,torH,o.top); if o.stripe then g.hl(cx-hw,ty+3,hw*2,o.stripe); g.hl(cx-hw,ty+7,hw*2,o.stripe) end
  g.rect(cx-hw,ly-2,hw*2,2,o.pants)
  for side=-1,1,2 do
   local ax=(side<0) and cx-hw-2 or cx+hw; local a=(side<0) and o.armL or o.armR
   if a=='up' then g.rect(ax,ty-6,2,8,o.top); g.rect(ax,ty-8,2,2,'s skin')
   elseif a=='fwd' then g.rect(ax,ty+1,2,5,o.top)
   else g.rect(ax,ty+1,2,torH-3,o.top); g.rect(ax,ty+torH-2,2,2,'s skin') end
  end
  local hy=ty-headH
  g.rect(cx-4,hy,8,headH,o.hair); g.hl(cx-3,hy+headH-1,6,'S skin shadow'); g.px(cx-5,hy+4,'s skin'); g.px(cx+4,hy+4,'s skin')
  if o.tail then g.rect(cx+o.tail,hy+headH-2,2,6,o.hair) end
  if o.hat then g.rect(cx-4,hy-2,8,4,o.hat); g.hl(cx-5,hy+2,10,o.hat) end
 end)
end

---------------------------------------------------------------- frames and the animated layers
for _,n in ipairs({'sky','far','mid','back','floor','props','tape','front'}) do K.trim(s,L[n]) end
local FRAMES=12
K.frames(s,FRAMES,0.1)
local ring8={{-1,-1},{0,-1},{1,-1},{-1,0},{1,0},{-1,1},{0,1},{1,1}}
local scores={'RSM 9900','NVA 8150','ODN 7720','TKO 6400','ALG 5210'}
local clawX={0,3,6,9,12,12,12,12,9,6,3,0}; local clawY={0,0,0,0,0,5,10,5,0,0,0,0}
for f=1,FRAMES do
 ------------------------------------------------ lights: on the wall, behind everything standing in the room
 local q=K.pen(m.canvas(s,L.lights,f))
 -- PROJECTS in pink, twice the size of the 5x7 letters, with its dim ring; it drops out for frame 9
 if f~=9 then
  for _,d in ipairs(ring8) do bigtext(q,'PROJECTS',118+d[1],68+d[2],'neon pink dim',2) end
  bigtext(q,'PROJECTS',118,68,'neon pink',2)
 else bigtext(q,'PROJECTS',118,68,'neon pink dim',2) end
 -- the marquee's bulbs, chasing round the box
 local n=0
 local function bulb(x,y) n=n+1; q.px(x,y,((n+f)%3==0) and 'neon yellow' or 'neon yellow dim') end
 for x=113,215,6 do bulb(x,63) end; for y=69,81,6 do bulb(218,y) end
 for x=215,113,-6 do bulb(x,86) end; for y=81,69,-6 do bulb(111,y) end
 -- the neon moth: two pairs of wings and a body, violet; a wing flickers
 local wc=(f==3 or f==4) and 'neon violet dim' or 'neon violet'
 ellipse(q,53,82,10,12,wc); ellipse(q,73,82,10,12,wc); ellipse(q,55,104,7,8,'neon violet'); ellipse(q,71,104,7,8,'neon violet')
 q.vl(63,74,38,'neon pink'); q.line(63,74,58,66,'neon pink'); q.line(63,74,68,66,'neon pink')
 -- the strip along the ceiling's edge: pink and cyan segments chasing
 for x=0,W-1,8 do local k=((x//8)+f)%3; q.hl(x,53,6,k==0 and 'neon pink' or (k==1 and 'neon cyan' or 'neon violet dim')) end
 -- the FINISHED board's bulbs, twinkling in turn
 for x=64,214,6 do if x<118 or x>160 then q.px(x,133,(((x//6)+(f-1)//2)%2==0) and 'sodium 5' or 'sodium 2') end end
 -- the high scores (the top row blinks)
 for i,tx in ipairs(scores) do if not (i==1 and f%4<2) then q.text(tx,231,76+(i-1)*7,i==1 and 'neon cyan' or 'concrete 6',5) end end
 -- PRIZES
 q.text('PRIZES',389,66,(f==7) and 'neon yellow dim' or 'neon yellow',5)
 -- NOW BUILDING's lamp, and COMING SOON blinking slowly under MORE PROJECTS
 q.rect(475,119,3,2,(f%6<3) and 'neon cyan' or 'neon cyan dim')
 q.text('COMING SOON',533,107,(f<=8) and 'neon yellow' or 'neon yellow dim',5)
 K.trim(s,L.lights,f)

 ------------------------------------------------ life: in front of the machines and the cabinets
 q=K.pen(m.canvas(s,L.life,f))
 -- the sweeper's light; the token machine's display
 q.px(29,179,(f%6<3) and 'neon green' or 'neon green dim')
 q.rect(TOKEN+7,140,6,3,(f%4<2) and 'holo' or 'holo dim')
 -- the dance machine: its screen, the arrows on its header, the mat's arrows lighting in turn
 local sc={'neon pink dim','neon cyan dim','neon violet dim','neon pink dim'}
 local d=shift(q,DANCE-350)
 d.rect(356,110,26,18,sc[1+(f-1)//3]); for i=0,2 do d.hl(358,113+i*5,22,'ink') end
 glyph(d,ARROW[({'l','d','u','r'})[1+(f-1)//3]],367,116,'W white')
 for i,dir in ipairs({'l','d','u','r'}) do glyph(d,ARROW[dir],354+(i-1)*8,96,((i+f)%4==0) and 'W white' or 'neon cyan') end
 local lit=1+(f-1)//3
 glyph(q,ARROW[({'l','d','u','r'})[lit]],DANCE+5+(lit-1)*8,188,(lit%2==0) and 'neon cyan' or 'neon pink')
 -- the claw machine: its bulbs chase, the claw runs along the gantry, drops and comes back up
 d=shift(q,CLAW-396)
 for i=0,10 do d.px(398+i*4,104,((i+f)%3==0) and 'neon yellow' or 'neon yellow dim') end
 local cx,cy=411+clawX[f],113+clawY[f]
 d.rect(cx-2,111,4,2,'concrete 6'); d.vl(cx,113,cy-113+9,'concrete 6')
 d.line(cx,cy+9,cx-4,cy+14,'concrete 7'); d.line(cx,cy+9,cx+4,cy+14,'concrete 7'); d.px(cx-4,cy+15,'concrete 7'); d.px(cx+4,cy+15,'concrete 7')
 -- a girl dancing at the dance machine
 local step=(f-1)//3
 person(q,DANCE+19,183,{hair='h hair',top='neon cyan dim',pants='concrete 2',shoe='W white',bob=step%2,armL=(step%2==0) and 'up' or 'down',armR=(step%2==1) and 'up' or 'down',tail=(step%2==0) and 3 or -5})
 -- a kid at the claw machine's stick, bouncing when the claw drops; an orange cat asleep on top, tail swinging
 person(q,CLAW+18,183,{kid=true,hair='H hair light',top='r rust',pants='d denim',shoe='B shoe light',bob=(f>=6 and f<=8) and 1 or 0,armL='fwd',armR='fwd'})
 outlined(q,function(g)
  local x,y=CLAW+29,96
  g.rect(x,y-5,10,5,'sodium 3'); g.rect(x+7,y-8,5,5,'sodium 3'); g.px(x+7,y-9,'sodium 3'); g.px(x+11,y-9,'sodium 3')
  g.vl(x-1,y-3,5,'sodium 3'); g.px(x-1+({0,0,0,1,1,1,0,0,0,-1,-1,-1})[f],y+2,'sodium 3')
 end)
 q.px(CLAW+31,92,'sodium 2'); q.px(CLAW+34,92,'sodium 2'); q.px(CLAW+33,94,'sodium 2'); q.px(CLAW+37,91,'sodium 1'); q.px(CLAW+39,91,'sodium 1')
 -- the attendant behind the prize counter (facing us): cap, vest, blinking now and then
 outlined(q,function(g)
  local x=PRIZE+36; local b=(f>=7) and 1 or 0
  g.rect(x-6,139+b,12,8-b,'neon pink dim'); g.rect(x-2,139+b,4,8-b,'concrete 7'); g.rect(x-1,137+b,2,2,'s skin')
  g.rect(x-4,128+b,8,9,'s skin'); g.rect(x-4,126+b,8,3,'neon cyan dim'); g.hl(x-5,129+b,10,'neon cyan dim')
 end)
 do local x=PRIZE+36; local b=(f>=7) and 1 or 0
  q.px(x-4,130+b,'h hair'); q.px(x+3,130+b,'h hair'); q.vl(x-4,131+b,2,'h hair'); q.vl(x+3,131+b,2,'h hair')
  if f~=4 then q.px(x-2,132+b,'ink'); q.px(x+1,132+b,'ink') else q.hl(x-2,132+b,2,'S skin shadow'); q.px(x+1,132+b,'S skin shadow') end
  q.hl(x-1,135+b,2,'S skin shadow'); q.px(x+3,141+b,'neon yellow')
 end
 -- the repair man at the open machine: hard hat, striped vest, one arm working; sparks off the board
 local work=(f%4<2)
 person(q,M1+19,183,{hair='h hair',top='sodium 3',stripe='neon yellow',pants='D denim dark',hat='neon yellow',armL=work and 'up' or 'fwd',armR='down'})
 if f==2 or f==6 or f==7 or f==10 then
  local sp=K.rng(f*7)
  q.px(M1+10,158,'W white'); q.px(M1+11,157,'neon yellow')
  for i=1,5 do q.px(M1+6+sp(9),153+sp(9),(i%2==0) and 'neon yellow' or 'sodium 4') end
 end
 -- two moths round the marquee's bulbs
 for k=0,1 do
  local a=(f-1+k*5)/FRAMES*math.pi*2; local mx=({224,104})[k+1]+math.floor(math.cos(a)*4+0.5); local my=({58,66})[k+1]+math.floor(math.sin(a*((k==0) and 1 or -1))*3+0.5)
  q.px(mx,my,'sodium 5'); if f%2==0 then q.px(mx-1,my-1,'concrete 7'); q.px(mx+1,my-1,'concrete 7') else q.px(mx-1,my,'concrete 7'); q.px(mx+1,my,'concrete 7') end
 end
 K.trim(s,L.life,f)

 ------------------------------------------------ rain, only where the shutter can show it (layer x 460-580)
 local w=K.pen(m.canvas(s,L.rain,f)); local phase=(f-1)%4
 K.rain(w,460,96,580,176,phase,5,'mist 4','mist 5',0.10)
 K.trim(s,L.rain,f)
end

K.note(s,'_lighting','A dark room lit by its signs and machines: the pink/cyan chaser along the ceiling edge, the PROJECTS marquee (pink, yellow bulbs), the neon moth (violet), PRIZES (yellow), the dance and claw machines, the cabinets. Right end: the repair corner behind caution tape, and the shutter half up onto the wet street.')
-- the interactables live in art/objects/arcade/: keep them off the props layer (scripts/art/objects.lua)
dofile('scripts/art/objects.lua').cut(s,'arcade')
K.save(s,'scenes/arcade')
