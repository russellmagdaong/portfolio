-- scenes/home: Russell's room, drawn from Codex's home study (art/_work/concept/home-study-v1.png)
-- and the sign schedule in art/concept/visual-studies.md, fitted to the file's slices.
--
--   "C:\aseprite\build\bin\aseprite.exe" -b --script scripts/art/draw/home.lua
--
-- Layers (back to front): sky 0.1, far 0.3, mid 0.6, lights 0.6 (animated: the
-- NIGHT FERN box and two red antenna lights), rain 0.6 (animated), back, floor,
-- props, front 1.2 over. Twelve frames of 100 ms. Slices and the original
-- layers' user data are left as they are.
local K=dofile('scripts/art/draw/kit.lua')
local m=K.m
local s=m.open('scenes/home'); local W=s.width
while #s.frames>1 do s:deleteFrame(#s.frames) end

local L={}
for _,l in ipairs(s.layers) do L[l.name]=l end
L.lights=K.layer(s,'lights','speed=0.6',L.mid)
L.rain=K.layer(s,'rain','speed=0.6',L.lights)
-- The couch stands out on the floor, so it has its own layer: sort=208 (6 behind its back's foot)
-- makes the engine draw it in front of him while he is behind it, and behind him otherwise.
L.couch=K.layer(s,'couch','sort=208',L.props); L.couch.data='sort=208'
local P={}
for _,n in ipairs({'sky','far','mid','back','floor','props','couch','front'}) do P[n]=K.pen(m.canvas(s,L[n])) end
-- the couch's platform: the back of its backrest, 296-358 x 196-214, 6 deep
for _,sl in ipairs(s.slices) do if sl.name=='platform' then sl.bounds=Rectangle(296,196,62,18); sl.data='depth=6' end end
-- How to play is painted on the wall, not on a board (Russell, 2026-11-16)
-- the interests stand closer together (Russell, 2026-11-17): their prop: slices follow the art
local PROPX={['prop:camera']=498,['prop:flag']=520,['prop:trophy']=540}
for _,sl in ipairs(s.slices) do local nx=PROPX[sl.name]; if nx and sl.bounds.x~=nx then sl.bounds=Rectangle(nx,sl.bounds.y,sl.bounds.width,sl.bounds.height) end end
-- the mirror's glass (reflect): the game draws him in it
do local g; for _,sl in ipairs(s.slices) do if sl.name=='reflect' then g=sl end end
 if not g then g=s:newSlice(Rectangle(168,142,22,36)); g.name='reflect' else g.bounds=Rectangle(168,142,22,36) end end
for _,sl in ipairs(s.slices) do if sl.name=='show:corkboard' then sl.data='look=wall'; sl.bounds=Rectangle(48,95,96,64) end end

-- Where things are (the slices):
--   corkboard 48-144 x 100-164 · mirror 164-194 x 138-182 · poster 214-310 x 100-164
--   pc 330-414 x 108-164 · guitar 434-448 · console 468-492 · camera 512-528
--   flag 548-562 · trophy 582-596 · couch (platform) 298-354 x 203-214 · exit 668-680
-- Light: one sodium tube hung at x 44-200, y 58 (above-left). Lit faces are top and left.
-- Signs: RUSSELL'S ROOM nameplate over the poster, EXIT over the door (Russell, 2026-11-16).
-- Accent: cyan (PC tower, monitor LED, the NIGHT FERN box outside the right window).

---------------------------------------------------------------- sky (0.1)
local p=P.sky
p.rect(0,0,W,62,'night'); p.dither(0,62,W,3,'night','sky high'); p.rect(0,65,W,13,'sky high')
p.dither(0,78,W,3,'sky high','sky'); p.rect(0,81,W,11,'sky'); p.dither(0,92,W,3,'sky','sky low')
p.rect(0,95,W,8,'sky low'); p.dither(0,103,W,4,'sky low','mist 4'); p.rect(0,107,W,163,'mist 4')

---------------------------------------------------------------- far (0.3)
p=P.far
K.skyline(p,{x0=-6,x1=W+6,base=140,topMin=98,topMax=118,wMin=10,wMax=26,fill='mist 3',win='mist 5',winP=0.035,rng=K.rng(7),gap=2,cap=true,ant=true})
-- one tall tower, in view through the left window at the start
p.rect(166,72,14,68,'mist 3'); p.rect(170,66,6,6,'mist 3'); p.vl(173,58,8,'mist 3')
for y=78,128,5 do if (y//5)%3~=1 then p.px(169,y,'mist 4'); p.px(176,y,'mist 4') end end
p.px(169,83,'mist 5'); p.px(176,108,'mist 5'); p.rect(172,70,2,1,'mist 4')
K.skyline(p,{x0=-6,x1=W+6,base=140,topMin=108,topMax=128,wMin=12,wMax=30,fill='mist 2',win='mist 3',winP=0.10,win2='mist 4',win2P=0.03,rng=K.rng(11),gap=3,cap=true,ant=true})

---------------------------------------------------------------- mid (0.6)
p=P.mid
-- the elevated rail, its deck above the near roofs
p.hl(0,101,W,'mist 3'); p.rect(0,102,W,3,'mist 1'); p.hl(0,105,W,'mist 2')
for x=6,W,28 do p.rect(x,106,2,34,'mist 1') end
-- a train standing in the stretch the right window shows (layer x 473-564)
p.rect(478,93,80,8,'mist 2'); p.hl(478,93,80,'mist 3'); p.rect(476,95,2,5,'mist 2'); p.rect(558,95,2,5,'mist 2')
for x=481,553,6 do p.rect(x,95,3,3,'mist 5') end
p.px(559,98,'sodium 3'); p.px(476,98,'neon red dim'); p.hl(478,100,80,'mist 1')
-- near silhouettes with roof clutter
K.skyline(p,{x0=-6,x1=W+6,base=142,topMin=112,topMax=134,wMin=14,wMax=34,fill='mist 1',win='mist 4',winP=0.07,win2='sodium 1',win2P=0.025,rng=K.rng(5),gap=2,cap=true})
local r=K.rng(21)
for _,b in ipairs({{70,118},{128,114},{186,122},{250,116},{330,120},{398,114},{452,118},{612,116}}) do
 local x,y=b[1],b[2]
 p.rect(x,y,10,22-(y-112),'mist 2'); p.hl(x,y,10,'mist 3')
 p.rect(x+2,y-7,6,7,'mist 2'); p.hl(x+1,y-7,8,'mist 3'); p.rect(x+2,y,1,2,'mist 1'); p.rect(x+7,y,1,2,'mist 1')
 if r()<0.6 then p.disc(x+14,y+2,2,'mist 3'); p.px(x+14,y+2,'mist 2') end
end
-- the antenna in view through the left window (its red light is on `lights`)
p.vl(172,98,20,'mist 1'); p.hl(169,102,7,'mist 1'); p.hl(170,106,5,'mist 1'); p.hl(171,110,3,'mist 1')
-- the neighbour's corrugated roof outside the right window, a tank, a clothesline, the sign's post
p.rect(466,122,110,20,'concrete 3'); p.hl(466,122,110,'concrete 4')
for x=468,574,3 do p.vl(x,123,19,'concrete 2') end
p.rect(470,126,1,8,'rust iron 1'); p.rect(506,124,1,6,'rust iron 1'); p.rect(548,128,1,10,'rust iron 1')
p.rect(538,110,14,12,'concrete 4'); p.vl(540,111,10,'concrete 5'); p.rect(549,110,3,12,'concrete 3'); p.hl(537,110,16,'concrete 5'); p.rect(539,120,2,3,'concrete 2'); p.rect(549,120,2,3,'concrete 2')
p.line(474,116,530,113,'concrete 4'); p.vl(474,112,10,'concrete 3'); p.vl(530,109,13,'concrete 3')
for i,c in ipairs({'concrete 6','r rust','leaf 4','d denim','concrete 7'}) do local x=478+i*9; p.rect(x,115-(i//3),3,4,c) end
p.rect(499,114,2,8,'mist 1') -- the NIGHT FERN box's post
p.hl(492,126,5,'neon cyan dim'); p.hl(501,127,3,'neon cyan dim'); p.hl(496,129,4,'neon cyan dim')
p.vl(556,100,22,'mist 1'); p.hl(553,104,7,'mist 1'); p.hl(554,108,5,'mist 1')

---------------------------------------------------------------- back
p=P.back
-- the wall, lit to the left under the tube
p.rect(0,45,W,131,'plaster 1')
for y=58,175 do local rgt=236+((y-58)//6)*3; p.rect(0,y,rgt,1,'plaster 2') end
p.rect(54,58,138,8,'plaster 3'); p.rect(68,66,110,6,'plaster 3'); p.rect(90,72,66,4,'plaster 3')
-- shadow in the far corner
p.rect(604,140,76,36,'concrete 3'); p.rect(620,150,60,26,'concrete 3')
-- panel seams, chips and stains
for _,sx in ipairs({30,146,210,316,430,544,598}) do p.vl(sx,58,118,(sx<240) and 'plaster 1' or 'concrete 2') end
r=K.rng(33)
for i=1,40 do local x,y=r(W),58+r(90)
 local onObject=(x>140 and x<215 and y>128) or (x>44 and x<150 and y>95 and y<168) or (x>210 and x<314 and y>95 and y<168) or (x>324 and x<420 and y>102 and y<168)
 if not onObject then local c=(x<236) and 'plaster 1' or 'concrete 3'; p.rect(x,y,1+r(2),1+r(2),c) end
end
p.vl(313,58,48,'concrete 2'); p.vl(446,98,70,'concrete 2')
-- plywood wainscot and baseboard
p.rect(0,150,W,26,'wood 2'); p.rect(0,150,270,26,'wood 3'); p.hl(0,149,W,'wood 3'); p.hl(0,149,270,'wood 4')
for x=46,W,48 do p.vl(x,150,26,(x<270) and 'wood 2' or 'wood 1') end
p.rect(0,172,W,4,'wood 1'); p.hl(0,172,270,'wood 2')
-- ceiling joists and the cables slung under them
p.rect(0,45,W,12,'wood 1'); p.rect(0,56,W,2,'wood 2'); p.hl(0,56,270,'wood 3')
for x=8,W,26 do p.rect(x,45,3,11,'wood 2'); if x<270 then p.vl(x,45,11,'wood 3') end end
for x=0,W,26 do p.line(x,48,x+13,51,'concrete 2'); p.line(x+13,51,x+26,48,'concrete 2'); p.line(x,52,x+13,54,'concrete 1'); p.line(x+13,54,x+26,52,'concrete 1') end
p.rect(300,46,12,9,'concrete 4'); p.hl(300,46,12,'concrete 5'); p.px(305,50,'concrete 2')
-- the sodium tube: the room's main light
p.vl(56,45,9,'concrete 4'); p.vl(128,45,9,'concrete 4')
p.rect(40,54,104,4,'concrete 3'); p.hl(40,54,104,'concrete 4'); p.rect(40,57,4,4,'concrete 5'); p.rect(140,57,4,4,'concrete 5')
p.rect(44,58,96,2,'sodium 4'); p.hl(52,58,80,'sodium 5'); p.hl(42,60,100,'sodium 2')
-- left window (jalousie) over the mirror: a hole onto the city
p.rect(146,58,64,78,'wood 2'); p.hl(146,58,64,'wood 3'); p.vl(146,58,78,'wood 3')
p.rect(150,62,56,70,0)
for y=70,124,10 do p.hl(150,y,56,'concrete 3') end; p.hl(150,70,56,'concrete 4')
p.vl(177,62,70,'wood 2')
p.rect(144,132,68,4,'wood 3'); p.hl(144,132,68,'wood 4'); p.rect(144,136,68,2,'wood 2')
K.plant(p,160,132,'small'); p.rect(192,125,6,7,'concrete 5'); p.hl(192,125,6,'concrete 6'); p.vl(197,125,7,'concrete 4')
-- capiz clerestory, three panels, lit from the left
local function tone(panel) return function(cx,cy)
 if panel==1 and cx==9 and cy==1 then return nil end
 if panel==3 and cx==3 and cy==2 then return nil end
 if panel==2 and cx==14 and cy==0 then return nil end
 if panel==1 then return 'plaster 3','plaster 2',(cx<8) and 'sodium 4' or nil
 elseif panel==2 then return 'plaster 3','plaster 2',nil
 else return 'plaster 2','plaster 1',nil end
end end
K.capiz(p,212,58,18,4,tone(1)); K.capiz(p,330,58,18,4,tone(2)); K.capiz(p,448,58,18,4,tone(3))
p.rect(210,56,112,2,'wood 3'); p.rect(328,56,112,2,'wood 3'); p.rect(446,56,112,2,'wood 2')
p.rect(210,83,112,3,'wood 2'); p.rect(328,83,112,3,'wood 2'); p.rect(446,83,112,3,'wood 2')
-- right window, a sash with a curtain, a hole onto the city
p.rect(596,56,58,82,'wood 2'); p.hl(596,56,58,'wood 3'); p.vl(596,56,82,'wood 3')
p.rect(600,60,50,74,0)
p.vl(624,60,74,'wood 2'); p.hl(600,96,50,'wood 2'); p.hl(600,97,50,'wood 1')
p.hl(601,61,22,'concrete 4'); p.hl(626,61,23,'concrete 4')
p.hl(594,54,64,'wood 3'); p.rect(592,53,3,3,'wood 4'); p.rect(656,53,3,3,'wood 4')
p.rect(641,56,11,86,'plaster 3'); for x=643,650,3 do p.vl(x,56,86,'plaster 2') end
p.rect(640,98,13,3,'r rust'); p.rect(642,101,9,41,'plaster 3'); p.vl(645,101,41,'plaster 2'); p.vl(649,101,41,'plaster 2')
p.rect(594,134,62,4,'wood 3'); p.hl(594,134,62,'wood 4'); p.rect(594,138,62,2,'wood 2')
p.rect(604,142,7,5,'concrete 5'); p.px(606,144,'concrete 2'); p.px(608,144,'concrete 2')
p.ring(620,146,4,'concrete 6'); p.disc(620,146,3,'concrete 7'); p.vl(620,143,3,'concrete 2'); p.hl(620,146,2,'concrete 2')
-- the door out, at the right edge: the opening is cut by the canvas, the leaf is off-screen
p.rect(654,126,26,4,'wood 2'); p.hl(654,126,26,'wood 3'); p.rect(656,130,4,46,'wood 2'); p.vl(659,130,46,'wood 3')
p.rect(660,130,20,46,'concrete 2'); p.rect(660,130,20,10,'concrete 1')
p.hl(664,158,16,'concrete 3'); p.hl(668,166,12,'concrete 3'); p.rect(660,160,4,16,'concrete 1')
p.rect(675,133,3,3,'sodium 1'); p.px(676,134,'sodium 3')
p.frame(654,114,25,10,'wood 3','wood 2'); p.text('EXIT',659,116,'sodium 4',5)
p.rect(646,142,5,7,'concrete 6'); p.vl(646,142,7,'concrete 4'); p.rect(648,145,1,2,'concrete 3')
-- left bay: breaker box, calendar, the jacket on its hook
p.vl(12,56,14,'concrete 4'); p.vl(18,56,14,'concrete 4')
p.rect(8,70,16,22,'concrete 5'); p.vl(8,70,22,'concrete 6'); p.hl(8,70,16,'concrete 6'); p.rect(22,70,2,22,'concrete 4'); p.hl(10,80,12,'concrete 4'); p.px(20,74,'neon green'); p.px(12,74,'concrete 3')
p.vl(16,92,12,'concrete 2'); p.line(16,104,22,106,'concrete 2')
p.rect(28,64,14,20,'concrete 7'); p.rect(28,64,14,4,'r rust'); for y=70,80,3 do for x=30,40,3 do p.px(x,y,'concrete 5') end end; p.px(36,76,'r rust')
p.px(22,106,'concrete 6'); p.rect(21,107,3,2,'concrete 5'); p.rect(17,109,10,2,'d denim'); p.rect(14,111,16,23,'d denim'); p.rect(25,111,5,23,'D denim dark'); p.rect(20,109,4,3,'l denim light'); p.vl(22,111,23,'D denim dark'); p.rect(17,120,4,4,'l denim light'); p.hl(14,133,16,'D denim dark')
-- shelf over the corkboard and what lives on it
p.rect(38,88,114,2,'wood 4'); p.rect(38,90,114,3,'wood 3'); p.line(42,93,46,99,'wood 2'); p.line(146,93,142,99,'wood 2')
p.rect(48,78,18,10,'concrete 5'); p.hl(48,78,18,'concrete 6'); p.rect(63,78,3,10,'concrete 4'); p.px(56,83,'g gold')
p.dither(72,80,18,8,'wood 4','wood 3'); p.hl(71,80,20,'wood 4'); p.rect(74,76,14,4,'k khaki'); p.hl(74,76,14,'Q khaki shadow')
r=K.rng(2); K.books(p,96,88,6,r,7,10)
K.plant(p,132,88,'trail'); K.vine(p,128,88,40,K.rng(9)); K.vine(p,44,92,36,K.rng(4))
p.rect(140,81,10,7,'concrete 3'); p.hl(140,81,10,'concrete 4'); p.px(147,84,'sodium 3'); p.rect(142,83,3,3,'concrete 2'); p.vl(149,76,5,'concrete 4')
-- How to play is painted straight on the wall (Russell, 2026-11-16): no board, just a few
-- drips and a stencilled arrow under the lettering, which is HTML (show:corkboard, look=wall).
p.hl(50,164,92,'plaster 1'); p.px(58,165,'plaster 1'); p.px(58,166,'plaster 1'); p.px(97,165,'plaster 1'); p.px(131,165,'plaster 1'); p.px(131,166,'plaster 1'); p.px(131,167,'plaster 1')
p.rect(60,166,20,4,'concrete 5'); p.hl(60,166,20,'concrete 6'); for x=63,76,4 do p.rect(x,167,2,2,'concrete 2') end; p.line(80,168,86,176,'concrete 2')
-- poster: cream paper taped to the wall, left plain
p.rect(212,98,100,68,'wood 2'); p.rect(213,99,98,66,'wood 3'); p.rect(214,100,96,64,'plaster 3')
p.rect(212,98,3,2,'concrete 7'); p.rect(309,98,3,2,'concrete 7'); p.rect(212,164,3,2,'concrete 7'); p.rect(309,164,3,2,'concrete 7')
-- the room's nameplate over the poster: a painted wooden board, RUSSELL'S ROOM in 3x5
p.frame(232,85,63,11,'wood 3','wood 2'); p.hl(233,86,61,'wood 4'); p.text('RUSSELL',237,88,'sodium 4',5); p.rect(265,88,1,2,'sodium 4'); p.text('S ROOM',267,88,'sodium 4',5)
p.px(233,86,'concrete 6'); p.px(293,86,'concrete 6'); p.px(233,94,'concrete 6'); p.px(293,94,'concrete 6')
p.rect(204,110,5,6,'plaster 3'); p.rect(204,118,5,4,'sodium 4'); p.rect(204,124,5,5,'concrete 7')
-- conduit, junction boxes and sockets
p.rect(308,106,9,12,'concrete 4'); p.hl(308,106,9,'concrete 5'); p.vl(308,106,12,'concrete 5'); p.rect(315,106,2,12,'concrete 3'); p.px(312,110,'neon green'); p.px(310,115,'concrete 2')
p.vl(313,118,32,'concrete 4'); p.rect(310,150,8,6,'concrete 5'); p.px(312,152,'concrete 2'); p.px(315,152,'concrete 2')
p.hl(317,100,114,'concrete 4'); p.hl(317,101,114,'concrete 3')
p.rect(428,98,10,12,'concrete 4'); p.hl(428,98,10,'concrete 5'); p.rect(436,98,2,12,'concrete 3'); p.px(432,103,'neon green dim'); p.vl(432,56,42,'concrete 4')
p.hl(438,104,130,'concrete 4'); p.hl(438,105,130,'concrete 3')
-- shelf over the desk: headphones, router, books, a lens
p.rect(316,92,114,2,'wood 4'); p.rect(316,94,114,3,'wood 3'); p.line(320,97,324,103,'wood 2'); p.line(426,97,422,103,'wood 2')
p.px(326,97,'concrete 5'); p.ring(326,102,5,'concrete 3'); p.rect(320,102,3,5,'concrete 4'); p.rect(330,102,3,5,'concrete 4'); p.rect(321,103,1,3,'concrete 2'); p.rect(331,103,1,3,'concrete 2')
p.rect(338,86,20,6,'concrete 4'); p.hl(338,86,20,'concrete 5'); p.px(341,89,'neon green'); p.px(344,89,'neon green'); p.px(347,89,'neon green dim'); p.vl(352,80,6,'concrete 4'); p.vl(355,80,6,'concrete 4')
r=K.rng(14); local bx=K.books(p,362,92,8,r,8,13); p.rect(bx,89,10,3,'D denim dark'); p.hl(bx,89,10,'concrete 5')
p.rect(410,85,7,7,'concrete 2'); p.ring(413,88,3,'concrete 4'); p.px(413,88,'sky low'); p.rect(419,88,6,4,'concrete 3')
p.line(358,90,426,90,'concrete 2')
-- the big screen on its bracket (the screen itself is HTML)
p.rect(366,97,12,8,'concrete 3')
p.rect(326,104,92,64,'concrete 2'); p.rect(327,105,90,62,'concrete 4'); p.rect(328,106,88,60,'concrete 2'); p.rect(330,108,84,56,'night')
p.hl(328,106,88,'concrete 5'); p.px(372,166,'neon cyan'); p.px(413,166,'concrete 3')
-- the wall fan, its cage and pull chain
p.rect(576,118,10,4,'concrete 4'); p.rect(579,112,4,6,'concrete 3')
p.disc(581,100,12,'concrete 2'); p.ring(581,100,12,'concrete 5'); p.ring(581,100,8,'concrete 4'); p.ring(581,100,4,'concrete 4')
for a=0,7 do local ang=a*math.pi/4; p.line(581,100,581+math.floor(11*math.cos(ang)+0.5),100+math.floor(11*math.sin(ang)+0.5),'concrete 4') end
for a=0,2 do local ang=a*2*math.pi/3+0.5; p.line(581,100,581+math.floor(9*math.cos(ang)+0.5),100+math.floor(9*math.sin(ang)+0.5),'concrete 3'); p.line(582,100,582+math.floor(9*math.cos(ang)+0.5),100+math.floor(9*math.sin(ang)+0.5),'concrete 3') end
p.disc(581,100,2,'concrete 6'); p.vl(592,112,8,'concrete 5'); p.px(592,120,'g gold')
-- the long shelf over the interests
p.rect(432,124,166,2,'wood 3'); p.rect(432,126,166,3,'wood 2'); p.line(438,129,442,135,'wood 1'); p.line(592,129,588,135,'wood 1'); p.line(514,129,516,134,'wood 1')
r=K.rng(27); K.books(p,436,124,8,r,8,12)
p.rect(474,112,11,12,'wood 3'); p.rect(476,114,7,8,'plaster 3'); p.rect(477,115,5,6,'sky low'); p.rect(478,118,3,2,'leaf 3')
p.rect(492,116,26,6,'plaster 3'); p.rect(494,113,22,3,'concrete 7'); for x=496,512,5 do p.rect(x,117,3,2,'sky high') end; p.hl(492,120,26,'r rust'); p.hl(492,121,26,'sodium 2'); p.rect(494,122,3,2,'concrete 2'); p.rect(512,122,3,2,'concrete 2'); p.px(518,118,'g gold'); p.rect(492,116,2,2,'neon cyan dim')
K.plant(p,534,124,'cactus')
for i=0,3 do local c=({'D denim dark','concrete 5','leaf 2','r rust'})[i+1]; p.rect(546,122-i*2,20,2,c); p.rect(548,122-i*2,3,1,'concrete 7') end
p.rect(570,114,10,10,'wood 2'); p.rect(572,116,6,6,'screen glow'); p.rect(573,117,4,4,'holo dim'); p.px(574,118,'screen glow')
p.vl(588,130,10,'r rust'); p.disc(588,142,2,'g gold'); p.px(588,142,'sodium 4')
p.rect(500,136,6,5,'neon cyan dim'); p.rect(508,135,4,6,'r rust'); p.rect(514,137,7,4,'leaf 3'); p.px(509,137,'sodium 4'); p.px(516,138,'concrete 7')
p.rect(566,140,7,5,'concrete 5'); p.px(568,142,'concrete 2'); p.px(570,142,'concrete 2')

---------------------------------------------------------------- floor
p=P.floor
p.rect(0,176,W,94,'wood 2')
for y=183,269,8 do p.hl(0,y,W,'wood 1') end
r=K.rng(41)
for y=176,269,8 do for x=r(40),W,44+r(12) do p.vl(x,y,7,'wood 1') end end
-- the pool of light under the tube, narrowing away from the wall
local pr=K.rng(43)
for k=0,5 do local y=176+k*8; local l=10+k*5+pr(6); local rgt=240-k*12-pr(8)
 p.rect(l,y,rgt-l,7,'wood 3')
 for x=l+pr(30),rgt,40+pr(14) do p.vl(x,y,7,'wood 2') end
end
p.hl(0,176,W,'wood 3'); p.hl(12,176,228,'wood 4')
-- the mat under the desk
p.rect(296,184,150,38,'wood 3'); p.rect(296,184,150,1,'rust iron 2'); p.rect(296,221,150,1,'rust iron 1'); p.vl(296,184,38,'rust iron 2'); p.vl(445,184,38,'rust iron 1')
for y=188,216,6 do for x=300+((y//6)%2)*3,440,6 do p.rect(x,y,2,2,'wood 4'); p.px(x+1,y+1,'wood 2') end end
-- doormat, slippers, a cable from the PC
p.rect(648,178,32,8,'rust iron 1'); p.rect(649,179,30,6,'rust iron 2'); p.dither(650,180,28,4,'rust iron 2','rust iron 1')
p.rect(10,186,4,6,'r rust'); p.rect(16,187,4,6,'r rust'); p.hl(10,188,4,'R rust dark'); p.hl(16,189,4,'R rust dark')
p.line(412,186,440,192,'concrete 2'); p.line(440,192,462,190,'concrete 2')
-- the strip under the safe band: more planks and a rug edge
p.rect(90,236,220,34,'rust iron 1'); p.hl(90,236,220,'rust iron 2'); for x=92,308,6 do p.rect(x,238,3,1,'rust iron 2') end

---------------------------------------------------------------- props
-- A pen that draws everything dx to the side, so a prop can be moved without rewriting it.
local function shifted(p,dx)
 local q={}
 for _,f in ipairs({'rect','px','hl','vl','oval','disc','ring','dither','frame','text'}) do
  q[f]=function(x,...) return p[f](x+dx,...) end
 end
 q.line=function(x,y,X,Y,c) p.line(x+dx,y,X+dx,Y,c) end
 q.pennant=function(x,...) p.pennant(x+dx,...) end
 return q
end
p=P.props
-- standing mirror (opens): ink outline on the slice, a glint, plain glass
p.rect(160,180,38,4,'wood 2'); p.hl(160,180,38,'wood 3'); p.rect(162,184,4,2,'wood 1'); p.rect(192,184,4,2,'wood 1')
p.rect(164,138,30,44,'ink'); p.rect(165,139,28,42,'wood 3'); p.vl(165,139,42,'wood 4'); p.hl(165,139,28,'wood 4'); p.rect(167,141,24,38,'concrete 3')
p.rect(168,142,22,36,'concrete 3'); p.line(169,143,173,143,'concrete 6'); p.line(169,144,169,149,'concrete 6'); p.line(186,176,189,176,'concrete 4'); p.vl(188,142,36,'concrete 4'); p.rect(168,152,22,1,'concrete 4')
-- low cabinet under the poster, books and a mug on it
p.rect(216,166,80,5,'wood 4'); p.rect(216,171,80,11,'wood 3'); p.vl(216,166,16,'wood 4'); p.hl(216,176,80,'wood 2')
p.rect(220,173,34,7,'wood 2'); p.rect(258,173,34,7,'wood 2'); p.px(236,176,'g gold'); p.px(274,176,'g gold')
r=K.rng(51); K.books(p,222,166,5,r,6,9); p.rect(246,161,6,5,'rust iron 2'); p.hl(246,161,6,'plaster 3'); p.px(252,163,'rust iron 2')
p.rect(262,158,22,8,'concrete 3'); p.hl(262,158,22,'concrete 5'); p.rect(264,160,18,4,'night'); p.px(265,161,'neon cyan')
-- a plastic chair (14 tall) by the cabinet
p.rect(300,168,14,2,'concrete 7'); p.rect(300,170,14,3,'concrete 6'); p.rect(300,163,2,5,'concrete 7'); p.rect(300,160,14,3,'concrete 7'); p.hl(300,160,14,'P pale steel')
p.rect(301,173,2,9,'concrete 6'); p.rect(311,173,2,9,'concrete 6'); p.rect(305,173,1,8,'concrete 5')
-- the couch (on its own layer, see above), turned to face the PC screen: we see its back. Green,
-- lit from the left; the rust pillow and the denim blanket show over the top, the blanket hanging
-- down the back. Jumpable: the back of the backrest is the platform slice (296-358 x 196-214, 6 deep).
do local q=P.couch
 -- the arms, a little lower than the back, and their tops
 q.rect(294,198,6,16,'leaf 2'); q.hl(294,198,6,'leaf 4'); q.vl(294,199,15,'leaf 3')
 q.rect(354,198,6,16,'leaf 1'); q.hl(354,198,6,'leaf 3')
 -- the pillow and the blanket over the top
 q.rect(306,190,12,5,'r rust'); q.hl(306,190,12,'sodium 2'); q.vl(317,191,4,'R rust dark')
 q.rect(338,191,10,4,'d denim'); q.hl(338,191,10,'l denim light')
 -- the backrest: its rounded top (lit), its back face with a middle seam and buttons
 q.rect(298,194,58,3,'leaf 3'); q.hl(299,193,56,'leaf 4'); q.px(298,194,'leaf 4')
 q.rect(298,197,58,15,'leaf 2'); q.vl(298,197,15,'leaf 3'); q.vl(355,197,15,'leaf 1')
 q.vl(327,197,15,'leaf 1'); q.hl(298,211,58,'leaf 1')
 for _,x in ipairs({312,342}) do q.px(x,203,'leaf 1'); q.px(x,204,'leaf 3') end
 -- the blanket hanging down the back
 q.rect(339,195,8,10,'d denim'); q.vl(346,195,10,'D denim dark'); q.hl(339,204,8,'D denim dark'); q.px(341,205,'d denim'); q.px(344,205,'d denim')
 -- the base and the legs
 q.rect(296,212,62,2,'wood 2'); q.rect(299,214,2,1,'wood 1'); q.rect(353,214,2,1,'wood 1')
end
-- the desk, keyboard, mouse, mug, speakers and the PC tower (cyan accent)
p.rect(318,166,110,5,'wood 4'); p.hl(318,166,110,'plaster 3'); p.rect(318,171,110,4,'wood 3'); p.hl(318,174,110,'wood 2')
p.rect(320,175,20,9,'wood 2'); p.rect(322,176,16,3,'wood 3'); p.rect(322,180,16,3,'wood 3'); p.px(329,177,'g gold'); p.px(329,181,'g gold')
p.rect(424,175,3,9,'wood 2')
p.rect(404,170,16,14,'concrete 2'); p.rect(405,171,14,12,'concrete 3'); p.rect(406,172,6,10,'concrete 1'); p.rect(407,173,4,8,'neon cyan dim'); p.px(416,172,'neon cyan'); p.rect(414,176,3,1,'concrete 5'); p.rect(414,178,3,1,'concrete 5')
p.rect(350,167,40,3,'concrete 3'); for x=352,388,3 do p.px(x,168,'concrete 5') end; p.rect(394,167,6,3,'concrete 5'); p.px(396,167,'concrete 3')
p.rect(330,161,6,5,'r rust'); p.hl(330,161,6,'plaster 3'); p.px(336,163,'r rust')
p.rect(320,152,8,14,'concrete 2'); p.disc(324,158,2,'concrete 4'); p.px(324,163,'neon cyan dim'); p.rect(418,152,8,14,'concrete 2'); p.disc(422,158,2,'concrete 4')
p.rect(366,164,12,2,'concrete 3'); p.rect(360,166,24,1,'concrete 4')
-- the interests, each on its slice
-- guitar 434-448 x 146-182: an electric guitar on a stand, plugged into a small amp beside it.
-- A double-cutaway red body (row by row: y, x from, x to), a maple neck with one string down it,
-- two black humbuckers, a bridge and three knobs; no pickguard, so it never reads as keys.
p.line(437,181,441,176,'concrete 3'); p.line(446,181,441,176,'concrete 3'); p.vl(441,176,2,'concrete 4'); p.px(437,181,'ink'); p.px(446,181,'ink')
for _,r in ipairs({{158,436,437},{159,436,438},{160,436,439},{160,445,446},{161,436,440},{161,444,447},{162,435,447},{163,435,447},{164,435,447},{165,435,447},{166,436,446},{167,436,446},{168,436,446},{169,435,447},{170,435,447},{171,435,447},{172,435,447},{173,435,447},{174,435,447},{175,436,446},{176,437,445}}) do p.hl(r[2],r[1],r[3]-r[2]+1,'neon red') end
for _,r in ipairs({{158,436,437},{159,436,438},{160,436,439},{160,445,446},{161,436,440},{161,444,447},{162,435,447},{163,435,447},{164,435,447},{165,435,447},{166,436,446},{167,436,446},{168,436,446},{169,435,447},{170,435,447},{171,435,447},{172,435,447},{173,435,447},{174,435,447},{175,436,446},{176,437,445}}) do p.px(r[3],r[1],'neon red dim') end
p.hl(437,176,9,'neon red dim'); p.px(436,159,'sodium 4'); p.px(436,163,'sodium 4'); p.px(437,162,'sodium 4')
p.rect(440,146,4,4,'wood 4'); p.px(440,146,'wood 3'); p.px(444,147,'concrete 6'); p.px(444,149,'concrete 6')
p.rect(440,150,3,13,'wood 4'); p.vl(442,150,13,'wood 3'); p.px(441,153,'concrete 7'); p.px(441,157,'concrete 7')
p.rect(440,164,4,2,'ink'); p.rect(440,168,4,2,'ink'); p.hl(440,172,4,'concrete 7')
p.vl(441,162,10,'concrete 6')
p.px(445,169,'sodium 4'); p.px(446,171,'sodium 4'); p.px(444,173,'sodium 4')
-- the amp, and the cable from the guitar's jack
p.line(446,172,452,179,'ink')
p.rect(451,169,13,13,'concrete 1'); p.hl(451,169,13,'concrete 3'); p.dither(452,173,11,8,'concrete 2','concrete 3')
p.px(453,171,'concrete 6'); p.px(456,171,'concrete 6'); p.px(459,171,'concrete 6'); p.px(462,171,'neon red')
-- console 468-492 x 166-182
p.rect(466,178,28,4,'wood 2'); p.hl(466,178,28,'wood 3')
p.rect(468,172,24,6,'concrete 2'); p.hl(468,172,24,'concrete 4'); p.rect(470,175,8,1,'concrete 1'); p.px(489,175,'neon cyan'); p.rect(484,174,3,1,'concrete 3')
p.rect(470,167,10,5,'concrete 3'); p.hl(470,167,10,'concrete 4'); p.px(472,169,'concrete 5'); p.px(477,169,'concrete 5'); p.line(480,170,486,172,'concrete 2')
-- camera 512-528 x 156-182 (drawn 14 further left, so the interests stand closer together)
do local p=shifted(p,-14)
p.rect(512,156,16,10,'concrete 3'); p.hl(512,156,16,'concrete 4'); p.rect(512,158,4,6,'concrete 2'); p.rect(512,159,3,4,'sky low'); p.px(513,160,'screen glow'); p.px(526,158,'neon red'); p.rect(518,154,6,2,'concrete 4'); p.rect(521,160,5,4,'concrete 2')
p.line(520,166,513,182,'concrete 4'); p.line(520,166,527,182,'concrete 3'); p.vl(520,166,15,'concrete 3'); p.hl(516,174,8,'concrete 3')
end
-- CTF flag 548-562 x 142-182 (drawn 28 further left, so the interests stand closer together)
do local p=shifted(p,-28)
p.rect(550,180,10,2,'wood 2'); p.rect(553,178,4,2,'wood 1'); p.rect(554,142,2,38,'wood 4'); p.vl(554,142,38,'wood 3'); p.px(554,141,'g gold'); p.px(555,141,'g gold')
p.pennant(556,144,11,8,1,'r rust'); p.pennant(556,146,8,4,1,'sodium 4'); p.px(557,147,'R rust dark'); p.px(558,148,'R rust dark')
end
-- hackathon trophy 582-596 x 162-182, on a stool (drawn 42 further left, so the interests stand closer together)
do local p=shifted(p,-42)
p.rect(580,176,18,2,'wood 3'); p.rect(580,178,18,4,'wood 2'); p.rect(581,180,2,2,'wood 1'); p.rect(595,180,2,2,'wood 1')
p.rect(584,173,10,3,'wood 1'); p.hl(584,173,10,'Q khaki shadow'); p.rect(587,170,4,3,'g gold'); p.rect(588,168,2,2,'g gold')
p.rect(584,162,10,7,'g gold'); p.oval(584,165,10,4,'g gold'); p.hl(584,162,10,'sodium 4'); p.px(585,163,'sodium 5'); p.rect(592,163,2,5,'Q khaki shadow'); p.vl(582,163,5,'g gold'); p.vl(595,163,5,'g gold'); p.px(582,162,'sodium 4')
end
-- the bed under the right window
p.rect(598,148,56,4,'wood 3'); p.hl(598,148,56,'wood 4'); p.rect(598,152,3,30,'wood 3'); p.rect(651,152,3,30,'wood 2')
p.rect(601,152,50,14,'concrete 6'); p.rect(601,160,50,6,'concrete 5'); p.hl(601,152,50,'concrete 7'); p.rect(601,166,50,14,'wood 3'); p.hl(601,166,50,'wood 2'); p.rect(600,180,54,2,'wood 1')
p.rect(603,150,16,7,'concrete 7'); p.hl(603,156,16,'concrete 5'); p.vl(618,151,5,'concrete 6'); p.rect(617,151,2,5,'concrete 6')
p.rect(622,154,29,12,'r rust'); for y=156,164,4 do p.hl(622,y,29,'k khaki') end; for x=626,646,8 do p.vl(x,154,12,'R rust dark') end; p.rect(622,164,29,2,'R rust dark')
p.rect(606,170,8,4,'concrete 2'); p.rect(630,170,12,4,'concrete 2')
-- a plant by the door, and the laundry hamper by the bed
K.plant(p,668,182,'bush')
p.rect(584,186,10,3,'concrete 4'); p.hl(584,186,10,'concrete 5')

---------------------------------------------------------------- front (1.2, over)
p=P.front
-- a big plant in a clay pot at the left, cut by the bottom edge
p.rect(16,244,34,26,'rust iron 2'); p.rect(44,244,6,26,'rust iron 1'); p.rect(14,242,38,3,'r rust'); p.rect(18,241,30,2,'wood 1')
p.line(33,241,22,214,'leaf 2'); p.line(33,241,44,208,'leaf 2'); p.line(33,241,33,204,'leaf 2'); p.line(33,241,52,222,'leaf 2'); p.line(33,241,12,228,'leaf 2')
for _,l in ipairs({{22,212},{44,206},{33,201},{52,220},{12,226}}) do p.oval(l[1]-7,l[2]-4,14,9,'leaf 3'); p.oval(l[1]-5,l[2]-4,7,5,'leaf 4'); p.rect(l[1]-1,l[2]-1,2,6,'leaf 2'); p.px(l[1]+4,l[2]+2,'leaf 2') end
-- a plastic basin of laundry
p.rect(236,240,36,30,'r rust'); p.rect(266,240,6,30,'R rust dark'); p.hl(234,239,40,'r rust'); p.rect(238,236,32,4,'concrete 7'); p.rect(240,234,10,3,'d denim'); p.rect(254,235,12,2,'k khaki')
-- a stand fan, its base off the bottom edge
p.disc(449,218,12,'concrete 3'); p.ring(449,218,12,'concrete 5'); p.ring(449,218,7,'concrete 4')
for a=0,5 do local ang=a*math.pi/3; p.line(449,218,449+math.floor(11*math.cos(ang)+0.5),218+math.floor(11*math.sin(ang)+0.5),'concrete 4') end
p.disc(449,218,2,'concrete 6'); p.rect(447,230,4,40,'concrete 4'); p.vl(447,230,40,'concrete 5')
-- a plastic stool
p.rect(560,246,22,4,'r rust'); p.hl(560,246,22,'sodium 3'); p.rect(561,250,3,20,'R rust dark'); p.rect(578,250,3,20,'R rust dark'); p.rect(569,250,2,20,'R rust dark')

---------------------------------------------------------------- frames and the animated layers
for _,n in ipairs({'sky','far','mid','back','floor','props','couch','front'}) do K.trim(s,L[n]) end
local FRAMES=12
K.frames(s,FRAMES,0.1)
for f=1,FRAMES do
 -- lights: the NIGHT FERN box blinks off on frame 7; the antenna lights blink slowly
 local q=K.pen(m.canvas(s,L.lights,f))
 local on=(f~=7); local red=(f<=6) and 'neon red' or 'neon red dim'
 q.frame(488,98,26,16,on and 'neon cyan dim' or 'mist 2','night')
 q.text('NIGHT',491,100,on and 'neon cyan' or 'neon cyan dim',5); q.text('FERN',493,107,on and 'neon cyan' or 'neon cyan dim',5)
 q.px(172,97,red); q.px(556,99,red)
 K.trim(s,L.lights,f)
 -- rain, only where the windows can show it (layer x 40-240 and 440-600)
 local w=K.pen(m.canvas(s,L.rain,f)); local phase=(f-1)%4
 K.rain(w,40,52,240,140,phase,3,'mist 4','mist 5',0.10); K.rain(w,440,52,600,140,phase,8,'mist 4','mist 5',0.10)
 K.trim(s,L.rain,f)
end

K.note(s,'_lighting','Main light: one sodium tube hung at x 44-200, y 58 (above-left); lit faces are top and left, the right end of the room is in violet shadow. Accent: cyan (PC tower, monitor LED, NIGHT FERN box outside the right window). Red only as tiny antenna and REC LEDs. Indoor floor dry; rain outside on the rain layer.')
-- the interactables live in art/objects/home/: keep them off the props layer (scripts/art/objects.lua)
dofile('scripts/art/objects.lua').cut(s,'home')
K.save(s,'scenes/home')
