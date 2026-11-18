-- scenes/school: MY COLLEGE LIFE, a classroom at night, after class: nobody in it, but everything
-- left as it was. Cream walls over a sea-green wainscot, a red waxed checker floor, a pale ceiling with
-- fluorescent tubes and fans, the chalkboard (About), the corkboard with the profile pinned on it,
-- two rows of tablet-arm chairs with things left on them, a jalousie window onto the campus, the
-- library corner (the thesis), and at the right end the teacher's desk under a small side board.
--
--   "C:\aseprite\build\bin\aseprite.exe" -b --script scripts/art/draw/school.lua
--
-- Rewrites the whole room (and art/anim/school.aseprite). Do not run it after hand edits to the room.
--
-- Still layers (back to front): sky 0.1, far 0.3, mid 0.6, back, floor, props, furniture (sort=189),
-- desk (sort=204), front (1.2, over).
-- Moving layers, 20 frames of 100 ms (K.save moves them to art/anim/school.aseprite). Each is small and
-- on its own layer, so its exported strip stays narrow:
--   rain (0.6, behind the wall)             the rain seen through the window
--   flicker, clock, fan1-3, drips (on back) the third tube, the pendulum, the ceiling fans, drops on the glass
--   glow (on floor)                         the flickering tube's shine on the waxed floor
--   water, umbrella (on props)              bubbles in the dispenser, the wet umbrella's drip
--   spin (sort=189, on furniture)           the stand fan's blades, and the sheet it lifts on the last chair
--   desktop (sort=204, on desk)             steam off the mug on the teacher's desk
-- No people or other characters, still or moving: Russell does not want them in any scene.
local K=dofile('scripts/art/draw/kit.lua')
local m=K.m
local s=m.open('scenes/school'); local W=s.width
while #s.frames>1 do s:deleteFrame(#s.frames) end
-- 2026-11-17: the room grew to 576 for the library corner, then to 672 for the teacher's end
-- (posters, the water dispenser, the side board, the desk).
local ROOM=672
if s.width<ROOM then app.activeSprite=s; app.command.CanvasSize{ui=false,left=0,top=0,right=ROOM-s.width,bottom=0} end
W=s.width
local function slice(name,rect,data)
 for _,sl in ipairs(s.slices) do if sl.name==name then sl.bounds=rect; sl.data=data; return end end
 local sl=s:newSlice(rect); sl.name=name; sl.data=data
end
slice('floor',Rectangle(0,176,W,49),'')
-- the thesis on the bookshelf: points at the page's <Tip id="thesis">; its sprite is art/objects/school/thesis
slice('prop:thesis',Rectangle(500,113,20,19),'tip=thesis')
-- the teacher's desk, at the right end of the room (it stood in the middle, between the boards)
local DX=628
slice('platform',Rectangle(DX,196,32,18),'depth=10')
local L={}
for _,l in ipairs(s.layers) do L[l.name]=l end
-- the teacher's desk on its own layer: in front of him while his feet are behind its back edge
-- (the platform's front 214 less its depth 10), so he walks behind it
L.desk=K.layer(s,'desk','sort=204',L.props)
-- the chairs, the stand fan and the bin along the back of the floor (their feet at y 189): in front of
-- him while he stands behind them
L.furniture=K.layer(s,'furniture','sort=189',L.props)
local STILL={'sky','far','mid','back','floor','props','furniture','desk','front'}
local P={}
for _,n in ipairs(STILL) do P[n]=K.pen(m.canvas(s,L[n])) end
-- The About board is a chalkboard: its text is chalk (src/pages/about.astro styles look=chalk).
for _,sl in ipairs(s.slices) do if sl.name=='show:about' then sl.data='look=chalk' end end

-- Slices: exit 0-12 (left) · spawn 28 · show:about 48-248 x 60-164 · show:profile 268-400 x 60-164
--         · prop:thesis 500-520 x 113-132 on the left bookshelf
--         · platform (the teacher's desk) 628-660 x 196-214, top face 186-196, on the `desk` layer (sort=204)
-- Nothing is drawn over the two boards, so their text stays clear.
-- The window: x 413-465, y 76-139 (louvres; the campus, trees and the rain behind).
local WX0,WX1,WY0,WY1=413,465,76,139
local TUBES={{60,108},{150,198},{290,338},{404,452},{500,548},{596,644}}
local FLICKER=3            -- the tube that flickers (on the `flicker` layer, not on `back`)
local FANS={129,371,572}   -- ceiling fans, between the tubes
local CHAIRS={86,112,138,164,190,216,300,326,352,378}  -- each chair's back; its tablet reaches 15 px left
local SFX,SFY=446,150      -- the stand fan's hub

---------------------------------------------------------------- sky / far / mid (the campus, through the window)
-- far and mid reach well left of the window: the further right the camera, the further left it looks.
K.sky(P.sky,W)
K.farCity(P.far,100,W,150,21)
local p=P.mid
-- the building across the quad: a lit corridor of classrooms, and acacias in front of it
p.rect(200,96,280,60,'mist 2'); p.hl(200,96,280,'mist 3')
for _,y in ipairs({104,124}) do p.rect(200,y+12,280,2,'mist 3'); for x=202,476,12 do p.rect(x,y,7,9,'mist 1'); p.rect(x+1,y+1,5,7,(x//12+y)%3==0 and 'sodium 2' or 'mist 1'); if (x//12+y)%3==0 then p.hl(x+1,y+1,5,'sodium 3') end end end
local r=K.rng(77)
for i=1,60 do local cx=360+r(110); local cy=78+r(30); p.oval(cx-5,cy-3,10+r(6),6+r(4),(r(3)==0) and 'leaf 2' or 'leaf 1') end
p.rect(408,104,4,50,'leaf 1'); p.line(410,112,396,100,'leaf 1'); p.line(410,110,428,98,'leaf 1')
for i=1,44 do local cx=232+r(90); local cy=82+r(26); p.oval(cx-5,cy-3,10+r(6),6+r(4),(r(3)==0) and 'leaf 2' or 'leaf 1') end
p.rect(280,104,4,50,'leaf 1'); p.line(282,112,268,100,'leaf 1'); p.line(282,110,298,100,'leaf 1')
p.rect(200,150,280,8,'mist 1')

---------------------------------------------------------------- back: ceiling, walls, boards, window
p=P.back
-- the ceiling: pale painted plywood panels, seen from below, and the cornice
p.rect(0,0,W,52,'concrete 5'); p.dither(0,0,W,14,'concrete 4','concrete 5')
for x=0,W,40 do p.vl(x,14,38,'concrete 4') end; p.hl(0,30,W,'concrete 4')
p.rect(0,52,W,3,'concrete 7'); p.hl(0,55,W,'Q khaki shadow')
-- the tube fittings, and every tube but the one that flickers
for i,t in ipairs(TUBES) do local x0,x1=t[1],t[2]
 p.rect(x0-3,36,x1-x0+6,3,'concrete 6'); p.hl(x0-3,36,x1-x0+6,'concrete 7'); p.vl(x0+6,22,14,'concrete 4'); p.vl(x1-6,22,14,'concrete 4')
 if i~=FLICKER then p.rect(x0,39,x1-x0,2,'W white'); p.hl(x0+2,41,x1-x0-4,'screen glow') end
end
-- the ceiling fans: the rod and the motor (the blades are on fan1-3)
for _,cx in ipairs(FANS) do
 p.vl(cx,26,17,'concrete 4'); p.rect(cx-1,24,3,2,'concrete 6'); p.rect(cx-2,43,5,4,'concrete 6'); p.hl(cx-2,43,5,'concrete 7'); p.hl(cx-1,47,3,'concrete 4'); p.px(cx,47,'sodium 4')
end
-- the wall: cream above, sea green below a rail, a dark baseboard
p.rect(0,56,W,94,'k khaki')
p.dither(0,56,W,2,'Q khaki shadow','k khaki')
p.rect(0,150,W,3,'mist 5'); p.hl(0,150,W,'concrete 7'); p.hl(0,152,W,'mist 3')
p.rect(0,153,W,21,'mist 4'); for x=6,W,30 do p.vl(x,153,21,'mist 3') end
p.rect(0,174,W,2,'mist 2')
-- the sign, hung from the ceiling over the chalkboard
p.vl(200,30,15,'concrete 3'); p.vl(280,30,15,'concrete 3')
p.frame(190,42,101,13,'wood 3','wood 2'); p.hl(191,43,99,'wood 4'); p.text('MY COLLEGE LIFE',196,45,'sodium 4',7)
-- the chalkboard (show:about): wooden frame, green slate with old erasing marks, the chalk tray
p.rect(44,57,208,110,'wood 3'); p.hl(44,57,208,'wood 4'); p.rect(46,58,204,107,'wood 2'); p.rect(48,60,200,104,'leaf 2')
r=K.rng(9)
for i=1,14 do local w=10+r(24); local x=52+r(190-w); local y=66+r(88); for k=0,w-1 do if r(3)>0 then p.px(x+k,y+math.floor(math.sin(k/4)*2),'leaf 3') end end end
p.rect(42,164,212,3,'wood 4'); p.hl(42,164,212,'k khaki'); p.hl(42,167,212,'wood 2')
p.rect(70,162,4,2,'W white'); p.rect(78,162,3,2,'sodium 4'); p.rect(86,162,2,2,'neon pink'); p.rect(210,161,10,3,'wood 3'); p.rect(210,163,10,1,'concrete 2')
-- chalk dust under the tray, on the wainscot
for _,x in ipairs({68,72,73,79,84,88,212,216,219}) do p.px(x,168+(x%3),'concrete 7') end
-- the corkboard (show:profile): a cork border with a sheet pinned on it, notes in the margins
p.rect(263,55,142,114,'wood 3'); p.rect(264,56,140,112,'wood 4')
r=K.rng(5); for i=1,260 do p.px(264+r(140),56+r(112),(r(2)==0) and 'Q khaki shadow' or 'wood 3') end
p.rect(270,62,132,104,'wood 2'); p.rect(268,60,132,104,'sodium 5')
for _,c in ipairs({{269,61,'neon red'},{398,61,'d denim'},{269,162,'leaf 4'},{398,162,'neon red'}}) do p.rect(c[1],c[2],2,2,c[3]); p.px(c[1],c[2],'W white') end
-- between the boards: the class bell and a light switch
p.disc(257,70,4,'neon red dim'); p.disc(257,70,3,'neon red'); p.px(256,69,'sodium 5'); p.rect(256,75,3,2,'concrete 5')
p.rect(255,118,5,8,'concrete 7'); p.vl(257,120,3,'concrete 4')
-- the left of the room: a pendulum clock over the class programme (the pendulum is on `clock`)
p.disc(30,67,6,'wood 2'); p.disc(30,67,5,'W white'); p.vl(30,63,4,'ink'); p.hl(30,67,4,'ink'); p.px(30,67,'neon red')
for _,d in ipairs({{0,-5},{5,0},{0,5},{-5,0}}) do p.px(30+d[1],67+d[2],'concrete 5') end
p.rect(26,74,9,13,'wood 2'); p.rect(27,75,7,11,'wood 1'); p.hl(26,74,9,'wood 3')
p.rect(20,90,20,22,'W white'); p.hl(20,90,20,'concrete 7'); p.text('CLASS',21,92,'d denim',5)
for y=99,109,3 do p.hl(22,y,16,'concrete 6'); p.px(22,y,'neon red dim') end
p.px(29,89,'neon red')
-- the window: a white frame, louvres of frosted glass, a sill with plants; a PA speaker over it
p.rect(WX0-4,WY0-4,WX1-WX0+8,WY1-WY0+8,'concrete 7'); p.rect(WX0-2,WY0-2,WX1-WX0+4,WY1-WY0+4,'concrete 6')
p.rect(WX0,WY0,WX1-WX0,WY1-WY0,0)
for y=WY0+2,WY1-2,6 do p.hl(WX0,y,WX1-WX0,'mist 5'); p.hl(WX0,y+1,WX1-WX0,'concrete 6'); p.px(WX0+2,y,'concrete 7') end
p.vl(WX0+(WX1-WX0)//2,WY0,WY1-WY0,'concrete 7')
p.rect(WX0-6,WY1+2,WX1-WX0+12,3,'concrete 7'); p.hl(WX0-6,WY1+5,WX1-WX0+12,'mist 3')
p.rect(433,59,13,10,'concrete 4'); p.rect(434,60,11,8,'concrete 2'); for y=61,66,2 do for x=435,443,2 do p.px(x,y,'concrete 5') end end; p.px(439,69,'concrete 3')
-- the corner column at the right of the window
p.rect(472,56,8,120,'Q khaki shadow'); p.vl(472,56,94,'k khaki')
-- the library corner: two tall bookshelves full of books, a gap on the middle shelf for the thesis
p.rect(568,56,8,120,'Q khaki shadow'); p.vl(568,56,94,'k khaki')
local br=K.rng(52)
for _,bx in ipairs({482,525}) do
 p.rect(bx,62,42,114,'wood 2'); p.rect(bx+2,64,38,110,'wood 1'); p.hl(bx,62,42,'wood 4'); p.vl(bx,62,114,'wood 3'); p.vl(bx+41,62,114,'wood 1')
 for _,sy in ipairs({86,108,130,152}) do p.rect(bx+2,sy+2,38,3,'wood 3'); p.hl(bx+2,sy+2,38,'wood 4') end
 for _,sy in ipairs({86,108,130,152,174}) do
  if bx==482 and sy==130 then K.books(p,bx+3,sy+2,4,br,12,17)
  else local x=bx+3; while x<bx+36 do local w=2+br(3); if x+w>bx+40 then break end; local h=12+br(6)
   p.rect(x,sy+2-h,w,h,({'rust iron 2','D denim dark','leaf 2','plaster 2','wood 4','concrete 5','r rust','sky low','R rust dark'})[1+br(9)])
   p.hl(x,sy+2-h+2+br(4),w,({'k khaki','plaster 3','concrete 7'})[1+br(3)]); x=x+w end end
 end
end
p.rect(504,133,12,2,'g gold'); p.px(509,133,'sodium 5')
K.plant(p,496,62,'small'); p.disc(552,57,4,'d denim'); p.rect(551,61,3,1,'concrete 4'); p.rect(550,55,2,2,'leaf 4')
-- the teacher's end. Two posters: a periodic table, and the Dean's list
p.rect(583,63,34,25,'Q khaki shadow'); p.rect(582,62,34,25,'W white'); p.hl(584,64,14,'ink'); p.hl(600,64,6,'concrete 5')
local PT={'neon red','sodium 3','sodium 4','sodium 4','sodium 4','sodium 4','leaf 4','neon cyan dim','d denim','neon violet'}
for row=0,4 do for col=0,9 do
 local show=(row>=3) or (col==0) or (col==9) or (row>=1 and (col==1 or col>=6))
 if show then p.rect(584+col*3,68+row*3,2,2,PT[col+1]) end
end end
p.px(599,61,'neon red')
p.rect(585,93,29,35,'Q khaki shadow'); p.rect(584,92,29,35,'d denim'); p.hl(584,92,29,'l denim light'); p.vl(612,92,35,'D denim dark'); p.hl(584,126,29,'D denim dark')
-- a gold star
p.rect(596,97,5,5,'g gold'); p.vl(598,95,9,'g gold'); p.hl(594,99,9,'g gold'); p.px(598,99,'sodium 5'); p.px(595,103,'g gold'); p.px(601,103,'g gold')
p.text('DEAN',587,108,'W white',5); p.vl(603,107,2,'W white'); p.text('S',605,108,'W white',5); p.text('LIST',591,116,'sodium 4',5); p.hl(589,123,19,'l denim light')
p.px(598,91,'neon yellow')
-- the side board over the teacher's desk: a to-do list in chalk (the first one is done), and doodles
p.rect(619,70,46,54,'wood 3'); p.hl(619,70,46,'wood 4'); p.rect(620,71,44,52,'wood 2'); p.rect(621,72,42,50,'leaf 2')
for _,c in ipairs({{630,80},{648,91},{636,104},{655,112},{627,117},{644,75}}) do p.hl(c[1],c[2],5,'leaf 3'); p.px(c[1]+2,c[2]+1,'leaf 3') end
p.text('TO DO',624,75,'sodium 4',5); p.hl(624,81,19,'sodium 4')
p.text('- THESIS',624,85,'concrete 7',5); p.text('- CODE',624,93,'concrete 7',5); p.text('- SLEEP ?',624,101,'concrete 7',5)
p.px(657,88,'neon green'); p.px(658,89,'neon green'); p.px(659,88,'neon green'); p.px(660,87,'neon green'); p.px(661,86,'neon green')
-- a space invader and a heart
for _,d in ipairs({{2,0},{6,0},{1,1},{2,1},{3,1},{4,1},{5,1},{6,1},{7,1},{0,2},{1,2},{3,2},{4,2},{5,2},{7,2},{8,2},{0,3},{1,3},{2,3},{3,3},{4,3},{5,3},{6,3},{7,3},{8,3},{0,4},{2,4},{6,4},{8,4},{3,5},{5,5}}) do p.px(626+d[1],111+d[2],'concrete 7') end
for _,d in ipairs({{0,0},{1,0},{3,0},{4,0},{0,1},{1,1},{2,1},{3,1},{4,1},{1,2},{2,2},{3,2},{2,3}}) do p.px(642+d[1],112+d[2],'neon pink') end
p.rect(617,123,50,3,'wood 4'); p.hl(617,123,50,'k khaki'); p.hl(617,126,50,'wood 2'); p.rect(626,121,3,2,'W white'); p.rect(652,121,7,2,'wood 3'); p.hl(652,122,7,'concrete 2')
K.exitLeft(p)

---------------------------------------------------------------- floor: red waxed tiles, a straight checker
p=P.floor
local TA,TB,JOINT='rust iron 2','R rust dark','rust iron 1'
local function joint(x,y) return x%24==0 or (y-176)%12==0 end
for ty=176,269,12 do for tx=0,W-1,24 do
 p.rect(tx,ty,24,12,(((tx//24)+((ty-176)//12))%2==0) and TA or TB)
end end
for y=176,269,12 do p.hl(0,y,W,JOINT) end
for x=0,W,24 do p.vl(x,176,94,JOINT) end
-- the wax catches the light along the top edge of each tile
for ty=176,269,12 do for tx=0,W-1,24 do if ((tx//24)+((ty-176)//12))%2==0 then p.hl(tx+2,ty+1,20,'r rust') end end end
-- the shine of a light on the wax: a hatch of lit pixels that thins out towards the front
local function sheen(q,x0,x1,y0,y1,c)
 for y=y0,y1 do local t=(y-y0)/(y1-y0)
  for x=x0,x1 do if not joint(x,y) then
   local on
   if t<0.35 then on=((x+y)%4==0) elseif t<0.7 then on=((x+y)%4==0 and y%2==0) else on=((x+y)%8==0 and y%2==0) end
   if on then q.px(x,y,c) end
  end end
 end
end
for i,t in ipairs(TUBES) do if i~=FLICKER then sheen(p,t[1]+6,t[2]-6,188,218,'r rust') end end
sheen(p,WX0+4,WX1-4,180,198,'plaster 2')
-- shade where the floor meets the wall, and under the furniture
p.rect(0,176,W,2,JOINT); for x=0,W-1 do if x%2==0 then p.px(x,178,JOINT) end end
for _,x in ipairs(CHAIRS) do p.hl(x-11,189,15,JOINT); p.hl(x-9,190,11,JOINT) end
p.hl(SFX-7,189,15,JOINT); p.hl(455,189,12,JOINT)
p.rect(DX-2,214,36,2,JOINT); p.hl(DX,216,32,JOINT)
p.rect(482,178,86,1,JOINT); p.hl(588,178,16,JOINT); p.hl(658,183,13,JOINT)
-- scuffs and worn spots
r=K.rng(31)
for i=1,70 do local x=4+r(W-8); local y=182+r(84); if not joint(x,y) and not joint(x+2,y) then
 if r(3)==0 then p.hl(x,y,2+r(2),JOINT) else p.px(x,y,'plaster 2') end end end
-- the doormat inside the door, a puddle off the umbrella
p.rect(15,189,26,15,'concrete 2'); p.rect(16,190,24,13,'concrete 3'); for y=192,200,2 do p.hl(18,y,20,'concrete 4') end; p.hl(15,204,26,JOINT)
p.hl(17,180,8,JOINT); p.hl(18,181,6,JOINT); p.hl(19,180,3,'plaster 2')
-- left on the floor: a paper plane in the aisle, paper balls that missed the bin, a pencil
p.hl(254,203,7,'W white'); p.hl(256,202,4,'concrete 7'); p.px(259,204,'concrete 6'); p.hl(255,205,6,JOINT)
p.rect(470,186,2,2,'W white'); p.px(471,187,'concrete 6'); p.hl(470,188,3,JOINT)
p.rect(449,193,2,2,'W white'); p.px(449,194,'concrete 6'); p.hl(449,195,3,JOINT)
p.hl(182,208,5,'neon yellow'); p.px(187,208,'k khaki'); p.px(181,208,'neon pink')

---------------------------------------------------------------- props (against the wall: always behind him)
p=P.props
-- the thesis, face-out on the left bookshelf (cut off this layer into art/objects/school/thesis.aseprite)
p.rect(501,113,18,19,'D denim dark'); p.vl(501,113,19,'d denim'); p.hl(501,113,18,'d denim'); p.vl(518,114,18,'ink')
p.hl(503,116,14,'g gold'); p.text('ODIN',503,119,'g gold',5); p.hl(503,126,14,'g gold'); p.px(509,129,'g gold'); p.px(510,129,'g gold')
-- a low book cabinet left of the chalkboard, books and a plant on top
p.rect(18,152,24,24,'wood 3'); p.hl(18,152,24,'wood 4'); p.hl(18,163,24,'wood 2')
K.books(p,20,162,6,K.rng(3),6,9); K.books(p,20,174,5,K.rng(4),6,10)
p.rect(21,149,10,3,'d denim'); p.hl(21,149,10,'l denim light'); p.hl(22,151,8,'W white'); p.rect(22,146,8,3,'r rust'); p.hl(22,146,8,'sodium 3'); p.hl(23,148,6,'W white')
K.plant(p,36,152,'small')
-- a wet umbrella leaning on the cabinet by the door (its drip is on `umbrella`)
p.line(17,154,21,175,'neon pink dim'); p.line(18,154,22,175,'neon pink'); p.line(19,158,22,172,'neon pink dim')
p.vl(17,149,5,'wood 4'); p.px(16,149,'wood 4'); p.px(15,150,'wood 4'); p.px(15,151,'wood 4'); p.px(22,176,'concrete 6')
-- plants on the sill
K.plant(p,420,WY1+2,'small'); K.plant(p,458,WY1+2,'cactus')
-- the water dispenser under the posters (its bubbles are on `water`)
p.rect(589,150,14,26,'concrete 7'); p.vl(589,150,26,'W white'); p.rect(601,150,2,26,'concrete 6'); p.hl(589,150,14,'W white')
p.rect(591,154,10,7,'concrete 6'); p.rect(593,156,2,2,'neon red'); p.rect(597,156,2,2,'d denim'); p.rect(591,161,10,2,'concrete 4')
p.rect(591,166,10,8,'concrete 6'); p.hl(591,166,10,'concrete 5'); p.px(599,169,'concrete 4')
p.rect(591,136,10,13,'holo dim'); p.rect(592,137,8,11,'holo'); p.vl(592,138,9,'screen glow'); p.hl(592,136,8,'holo'); p.px(591,136,0); p.px(600,136,0)
p.rect(594,149,4,1,'holo dim'); p.hl(592,140,8,'screen glow')
-- a stack of paper cups on it, a chair for the teacher behind the desk, a plant in the corner
p.rect(603,144,3,6,'W white'); p.hl(603,146,3,'concrete 6'); p.hl(603,148,3,'concrete 6')
p.vl(DX+10,160,23,'wood 2'); p.vl(DX+21,160,23,'wood 2'); p.rect(DX+10,160,12,3,'wood 3'); p.hl(DX+10,160,12,'wood 4'); p.rect(DX+11,167,10,2,'wood 3')
p.rect(DX+8,174,16,2,'wood 4'); p.vl(DX+9,176,7,'wood 2'); p.vl(DX+22,176,7,'wood 2')
K.plant(p,663,183,'bush')

---------------------------------------------------------------- furniture (sort=189): the chairs, the stand fan, the bin
p=P.furniture
-- a tablet-arm chair facing left, its feet at y, its back at x (the tablet reaches left)
local function armchair(x,y)
 p.rect(x-10,y-9,12,2,'wood 3'); p.hl(x-10,y-9,12,'wood 4')
 p.rect(x,y-20,3,11,'wood 3'); p.vl(x+2,y-20,11,'wood 2'); p.hl(x,y-20,3,'wood 4')
 p.vl(x-9,y-7,7,'concrete 2'); p.vl(x+1,y-7,7,'concrete 2'); p.hl(x-9,y-3,11,'concrete 2')
 p.rect(x-15,y-14,10,2,'wood 4'); p.vl(x-6,y-12,3,'wood 2')
end
for _,x in ipairs(CHAIRS) do armchair(x,189) end
-- what was left on them (seat top y 180, tablet top y 175)
p.hl(72,174,7,'W white'); p.px(75,174,'concrete 6'); p.hl(73,173,2,'d denim')                       -- 86: an open notebook, a pen
p.rect(103,172,8,8,'neon red dim'); p.hl(103,172,8,'neon red'); p.vl(103,173,6,'neon red')           -- 112: a bag left on the seat
p.rect(105,176,4,3,'R rust dark'); p.px(107,177,'g gold'); p.px(104,171,'neon red dim'); p.px(109,171,'neon red dim'); p.hl(105,170,4,'neon red dim')
p.rect(124,173,7,2,'d denim'); p.hl(124,173,7,'l denim light'); p.rect(125,171,6,2,'leaf 3'); p.hl(125,171,6,'leaf 4'); p.rect(124,169,7,2,'r rust'); p.hl(124,169,7,'sodium 3') -- 138: books
p.rect(189,168,5,10,'d denim'); p.hl(189,168,5,'l denim light'); p.vl(193,169,9,'D denim dark'); p.vl(188,171,6,'d denim'); p.px(188,177,'D denim dark') -- 190: a jacket over the back
p.hl(202,174,5,'W white'); p.rect(208,171,2,4,'neon cyan dim'); p.hl(208,171,2,'neon cyan')           -- 216: a sheet and a tumbler
p.rect(293,178,2,2,'W white'); p.px(294,179,'concrete 6')                                           -- 300: a ball of paper on the seat
p.rect(330,180,8,9,'leaf 2'); p.hl(330,180,8,'leaf 3'); p.vl(330,181,7,'leaf 3'); p.rect(332,184,4,3,'leaf 1'); p.hl(332,179,4,'leaf 1'); p.px(334,185,'g gold') -- 326: a backpack on the floor
p.hl(338,174,6,'W white'); p.px(341,174,'concrete 6'); p.rect(345,173,2,2,'concrete 2'); p.px(345,173,'neon green dim') -- 352: a notebook and a calculator
-- the stand fan by the window (its blades are on `spin`), the bin
p.ring(SFX,SFY,7,'concrete 6'); p.vl(SFX,SFY+7,31,'concrete 5'); p.rect(SFX-1,SFY+7,3,3,'concrete 4'); p.rect(SFX-6,186,13,3,'concrete 4'); p.hl(SFX-6,186,13,'concrete 5')
p.rect(456,177,10,12,'d denim'); p.hl(456,177,10,'l denim light'); p.vl(465,178,11,'D denim dark'); p.rect(458,175,6,2,'sodium 5'); p.px(460,174,'W white'); p.px(462,175,'concrete 7')

---------------------------------------------------------------- desk (sort=204): the teacher's desk on the platform
p=P.desk
p.rect(DX-2,186,36,4,'wood 4'); p.hl(DX-2,186,36,'k khaki'); p.rect(DX-1,190,34,6,'wood 3')
p.rect(DX,196,32,18,'wood 3'); p.vl(DX,196,18,'wood 4'); p.vl(DX+31,196,18,'wood 2'); p.hl(DX,213,32,'wood 2')
p.rect(DX+3,198,26,6,'wood 2'); p.rect(DX+14,200,4,1,'sodium 3'); p.rect(DX+3,206,26,6,'wood 2'); p.rect(DX+14,208,4,1,'sodium 3')
-- on it: a globe, a pile of test papers under a red book and an apple, a mug (its steam is on `desktop`), a lamp
p.vl(DX+5,175,11,'concrete 4'); p.rect(DX+2,184,7,2,'concrete 4'); p.disc(DX+5,177,5,'d denim'); p.rect(DX+2,175,3,2,'leaf 4'); p.rect(DX+6,178,3,3,'leaf 4'); p.px(DX+3,174,'l denim light')
p.rect(DX+11,182,11,4,'sodium 5'); p.hl(DX+12,181,9,'W white'); p.hl(DX+11,184,11,'concrete 7'); p.rect(DX+12,179,8,2,'neon red'); p.hl(DX+12,179,8,'sodium 3')
p.rect(DX+15,176,3,3,'neon red'); p.px(DX+15,176,'sodium 3'); p.px(DX+16,175,'leaf 3')
local MX=DX+24
p.rect(MX,183,3,3,'W white'); p.px(MX+3,184,'concrete 7'); p.hl(MX,183,3,'concrete 7')
p.rect(DX+29,184,4,2,'concrete 3'); p.vl(DX+31,176,8,'concrete 4'); p.line(DX+31,176,DX+28,173,'concrete 4'); p.rect(DX+25,171,5,2,'leaf 3'); p.hl(DX+25,171,5,'leaf 4'); p.hl(DX+26,173,3,'sodium 5')
-- sheets laid out on the top
p.hl(DX+3,191,8,'W white'); p.hl(DX+4,193,8,'concrete 7'); p.hl(DX+20,192,7,'W white'); p.px(DX+28,192,'neon red')

---------------------------------------------------------------- front (1.2, over): the front row of chairs
p=P.front
local function bigchair(x)
 p.rect(x,226,5,44,'wood 1'); p.vl(x+4,226,44,'wood 2'); p.hl(x,226,5,'wood 2')
 p.rect(x-26,244,26,4,'wood 1'); p.hl(x-26,244,26,'wood 2'); p.rect(x-34,236,18,3,'wood 2'); p.vl(x-18,239,6,'wood 1')
 p.vl(x-24,248,22,'concrete 1'); p.vl(x+2,248,22,'concrete 1')
end
bigchair(150); bigchair(372); bigchair(600)
-- a sheet and a pen on the first one's tablet, a closed book on the second's, a bag by the aisle
p.hl(119,235,9,'W white'); p.hl(120,234,7,'concrete 7'); p.hl(129,235,4,'neon red')
p.rect(341,233,10,3,'d denim'); p.hl(341,233,10,'l denim light'); p.hl(342,235,8,'W white')
p.rect(222,230,12,3,'D denim dark'); p.rect(220,233,16,18,'d denim'); p.hl(220,233,16,'l denim light'); p.rect(224,239,8,5,'D denim dark'); p.vl(235,234,17,'D denim dark'); p.px(228,241,'g gold')

---------------------------------------------------------------- frames and the moving layers
for _,n in ipairs(STILL) do K.trim(s,L[n]) end
local FRAMES=20
K.frames(s,FRAMES,0.1)
-- A moving layer: made just above `after`, draw(q,f) paints frame f (1..FRAMES). Frame 1 is what
-- shows with reduced motion, so it should be a good still.
local function moving(name,data,after,draw)
 local l=K.layer(s,name,data,after)
 for f=1,FRAMES do draw(K.pen(m.canvas(s,l,f)),f); K.trim(s,l,f) end
 L[name]=l; return l
end
moving('rain','speed=0.6',L.mid,function(q,f) K.rain(q,236,60,468,156,(f-1)%4,7,'mist 4','mist 5',0.16) end)
-- the third tube: out for a frame or two now and then
local function tubeOn(f) return not (f==7 or f==8 or f==11 or f==16) end
moving('flicker','',L.back,function(q,f) local t=TUBES[FLICKER]; local x0,x1=t[1],t[2]
 if tubeOn(f) then q.rect(x0,39,x1-x0,2,'W white'); q.hl(x0+2,41,x1-x0-4,'screen glow')
 else q.rect(x0,39,x1-x0,2,'concrete 6'); q.hl(x0,40,x1-x0,'concrete 4') end
end)
-- the pendulum: left, middle, right, middle, a second each way
moving('clock','',L.flicker,function(q,f) local off=({-1,0,1,0})[((f-1)//5)%4+1]
 q.line(30,76,30+off*2,82,'g gold'); q.rect(29+off*2,82,3,3,'g gold'); q.px(29+off*2,82,'sodium 5')
end)
-- the ceiling fans, seen from the side: the blades swing through as they turn
local after=L.clock
for i,cx in ipairs(FANS) do
 after=moving('fan'..i,'',after,function(q,f) local st=(f-1+i)%4
  local a,b=({18,13,7,13})[st+1],({7,13,18,13})[st+1]; local c=(st%2==0) and 'concrete 7' or 'concrete 6'
  q.hl(cx-2-a,44,a,c); q.hl(cx+3,44,b,c); q.hl(cx-2-a,45,a,'concrete 4'); q.hl(cx+3,45,b,'concrete 4')
 end)
end
-- drops running down the window glass
moving('drips','',after,function(q,f)
 for _,d in ipairs({{418,0},{426,23},{433,41},{444,9},{451,33},{459,50},{422,47},{455,15}}) do
  local y=WY0+1+((f-1)*3+d[2])%60
  q.px(d[1],y,'concrete 7'); q.px(d[1],y+1,'screen glow')
 end
end)
-- the flickering tube's shine on the floor
moving('glow','',L.floor,function(q,f) local t=TUBES[FLICKER]
 if tubeOn(f) then sheen(q,t[1]+6,t[2]-6,188,218,'r rust') end
end)
-- bubbles rising in the dispenser's bottle
moving('water','',L.props,function(q,f)
 if f<=10 then q.px(594+(f%2),148-(f-1),'W white') end
 if f>=8 and f<=17 then q.px(597+((f+1)%2),148-(f-8),'W white') end
 if f>=13 then q.px(595,148-(f-13),'screen glow') end
end)
-- a drop off the umbrella's tip, and the ring it leaves in the puddle
moving('umbrella','',L.water,function(q,f) local t=(f-1)%10
 if t<3 then q.px(22,177+t,'screen glow')
 elseif t<5 then q.hl(20,180,4,'screen glow')
 elseif t<7 then q.px(18,180,'plaster 2'); q.px(25,180,'plaster 2') end
end)
-- the stand fan's blades, and the sheet on the last chair's tablet lifting in its draught
moving('spin','sort=189',L.furniture,function(q,f)
 local a0=((f-1)%4)*math.pi/6
 for k=0,2 do local a=a0+k*2*math.pi/3
  q.line(SFX,SFY,SFX+math.floor(5*math.cos(a)+0.5),SFY+math.floor(5*math.sin(a)+0.5),(f%2==0) and 'concrete 5' or 'concrete 7') end
 q.disc(SFX,SFY,1,'concrete 4'); q.px(SFX,SFY,'concrete 7')
 local lift=({0,0,0,0,0,0,1,1,2,2,2,1,1,0,0,0,1,1,0,0})[f]
 if lift==0 then q.hl(365,174,6,'W white')
 elseif lift==1 then q.hl(366,174,5,'W white'); q.px(365,173,'W white')
 else q.hl(367,174,4,'W white'); q.px(366,173,'W white'); q.px(365,172,'concrete 7') end
end)
-- steam off the mug on the teacher's desk
moving('desktop','sort=204',L.desk,function(q,f)
 for k=0,1 do local t=((f-1)+k*5)%10
  q.px(MX+1+((t//2+k)%2),182-t//2,(t<6) and 'concrete 7' or 'concrete 6') end
end)
K.note(s,'_lighting','Main light: six fluorescent tubes on the ceiling (cool white; the third flickers, and so does its shine on the floor). Lit faces top. The red waxed floor carries the shine of the tubes and of the window. Night outside the jalousie window: the classroom block across the quad, acacias, rain; drops run down the glass. Nobody in the room: no people or characters, still or moving.')
-- the interactables live in art/objects/school/: keep them off the props layer (scripts/art/objects.lua)
dofile('scripts/art/objects.lua').cut(s,'school')
K.save(s,'scenes/school')
