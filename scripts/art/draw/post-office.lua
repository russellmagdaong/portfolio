-- scenes/post-office: the POST OFFICE, an old neighbourhood post office at night. Reworked 2026-11-17
-- on Russell's word: the sign reads POST OFFICE, the floor is a straight checker (the skewed one was
-- messy), the parcel in the way is a pile of four, a testimonials board hangs in a new bay at the
-- right (show:testimonials, a postcard pinned to a corkboard), and the room is busy: a clerk stamping
-- behind the grille, people at the PO boxes, on the bench, at the mailbox and at the sorting rack, a
-- pigeon on the sill, a delivery drone.
--
--   "C:\aseprite\build\bin\aseprite.exe" -b --script scripts/art/draw/post-office.lua
--
-- Rewrites the whole room (and art/anim/post-office.aseprite). Do not run it after hand edits to it.
-- The counter is art/objects/post-office/counter.aseprite (never written by this script).
-- Layers (back to front): sky 0.1, far 0.3, mid 0.6, rain 0.6 (animated, through the window), back,
-- lights (animated, on the wall: LETTERS, NOW SERVING, the clock, the clerk in his booth), floor,
-- props (the grille's bars are here, so the clerk moves behind them), life (animated, in front of
-- the props: the people, the pigeon, the drone), parcels (sort=204: the pile he can jump on and walk
-- behind), front 1.2 over. 12 frames of 100 ms.
-- Everything but the pile stands against the wall (feet at y 183 or less; his stop at 184).
local K=dofile('scripts/art/draw/kit.lua')
local m=K.m
local s=m.open('scenes/post-office')
while #s.frames>1 do s:deleteFrame(#s.frames) end
local WIDTH=640
if s.width<WIDTH then app.activeSprite=s; app.command.CanvasSize{ui=false,left=0,top=0,right=WIDTH-s.width,bottom=0} end
local W=s.width

-- The boards. show:socials is as it was. show:testimonials is the postcard on the corkboard: the
-- page's text is laid over it (src/pages/contact.astro fits it), so its middle is left plain.
local SOC={x=48,y=114,w=84,h=50}
local CARD={x=506,y=104,w=80,h=56}
-- The pile: each box's front face, as a platform slice (its top edge is where he lands, its bottom
-- edge the floor under the pile, so a box on another is as tall as both). All reach 10 back.
local PILE={
 a={x=264,y=196,w=32,h=18},   -- the big parcel on the floor
 b={x=266,y=182,w=20,h=32},   -- the one on top of it (14 high, on a's 18)
 c={x=298,y=198,w=16,h=16},   -- the one beside it
 d={x=300,y=190,w=12,h=24},   -- the small one on that (8 high, on c's 16)
}
local function slice(name,r,data)
 local rect=Rectangle(r.x,r.y,r.w,r.h)
 for _,sl in ipairs(s.slices) do if sl.name==name then sl.bounds=rect; sl.data=data; return end end
 local sl=s:newSlice(rect); sl.name=name; sl.data=data
end
slice('floor',{x=0,y=176,w=W,h=49},'')
slice('show:socials',SOC,'look=paper')
slice('show:testimonials',CARD,'look=postcard')
for i=#s.slices,1,-1 do if s.slices[i].name=='platform' then s:deleteSlice(s.slices[i]) end end
for _,k in ipairs({'a','b','c','d'}) do local sl=s:newSlice(Rectangle(PILE[k].x,PILE[k].y,PILE[k].w,PILE[k].h)); sl.name='platform'; sl.data='depth=10' end

local L={}
for _,l in ipairs(s.layers) do L[l.name]=l end
L.rain=K.layer(s,'rain','speed=0.6',L.mid)
L.lights=K.layer(s,'lights','',L.back)
L.parcels=K.layer(s,'parcels','sort=204',L.props)
L.life=K.layer(s,'life','',L.props)
local STILL={'sky','far','mid','back','floor','props','parcels','front'}
local P={}
for _,n in ipairs(STILL) do P[n]=K.pen(m.canvas(s,L[n])) end

-- Other slices, unchanged: exit 0-12 · spawn 28 · object:counter 152-200 x 152-182.
local WX0,WX1,WY0,WY1=434,474,74,150               -- the window (arched top)
local PIL={140,214,334,424,484,602}                -- the pilasters
local LAMPS={90,270,390,546}                       -- the globe lamps
local SIGN=90                                      -- the middle of the POST OFFICE sign
local BOXES={x=222,y=74}                           -- the wall of PO boxes (9 x 7 doors, 11 x 10 apart)
local RACK={x=612,y=96}                            -- the sorting rack at the far end
local QUEUE,BOXER,SITTER,KID,SORTER=228,324,357,398,625   -- where the people are
local DRONE=312

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
-- an envelope, w x h, with its flap and a seal
local function envelope(p,x,y,w,h,paper,seal)
 p.rect(x,y,w,h,paper or 'W white'); p.hl(x,y+h-1,w,'concrete 6')
 for i=0,(w-1)//2 do local yy=y+math.min(i,h-2); p.px(x+i,yy,'concrete 6'); p.px(x+w-1-i,yy,'concrete 6') end
 if seal then p.px(x+w//2,y+math.min((w-1)//2,h-2),seal) end
end

---------------------------------------------------------------- sky / far / mid (the lane, through the window)
K.sky(P.sky,W)
K.farCity(P.far,236,480,150,41)
local p=P.mid
K.nearRoofs(p,316,480,176,42)
p.rect(316,116,164,4,'mist 2'); p.hl(316,116,164,'mist 3'); for x=320,476,24 do p.rect(x,120,3,56,'mist 2') end

---------------------------------------------------------------- back
p=P.back
-- the ceiling: a shallow cream vault in bays between beams, a dentil cornice, globe lamps
p.rect(0,0,W,56,'k khaki')
for x=0,W,60 do for y=0,40 do local t=math.abs(((y)/40)-0.5); p.hl(x,y,60,(t>0.35) and 'Q khaki shadow' or 'k khaki') end; p.rect(x,0,4,46,'Q khaki shadow'); p.vl(x+4,0,46,'sodium 5') end
p.rect(0,42,W,4,'concrete 7'); p.hl(0,42,W,'P pale steel')
p.rect(0,46,W,6,'P pale steel'); for x=1,W,4 do p.rect(x,48,2,3,'concrete 6') end
p.rect(0,52,W,4,'concrete 7'); p.hl(0,55,W,'concrete 5')
for _,x in ipairs(LAMPS) do p.vl(x,30,12,'concrete 2'); p.disc(x,46,5,'sodium 5'); p.disc(x,46,4,'W white'); p.hl(x-3,41,7,'g gold') end
-- the walls: pale above, pilasters with capitals, a mail-red wainscot
p.rect(0,56,W,90,'P pale steel')
p.dither(0,56,W,2,'concrete 7','P pale steel')
for _,x in ipairs(PIL) do
 p.rect(x-5,56,10,90,'concrete 7'); p.vl(x-5,56,90,'W white'); p.vl(x+4,56,90,'concrete 6')
 p.rect(x-7,60,14,4,'P pale steel'); p.hl(x-7,60,14,'W white'); p.hl(x-7,63,14,'concrete 6'); p.rect(x-6,64,12,2,'concrete 6')
end
p.rect(0,146,W,4,'R rust dark'); p.hl(0,146,W,'r rust')
p.rect(0,150,W,22,'neon red dim'); for x=4,W,24 do p.frame(x,153,20,16,'R rust dark','neon red dim'); p.hl(x+1,154,18,'r rust') end
p.rect(0,172,W,4,'rust iron 1')

-- POST OFFICE: a red enamel plaque in a brass rim, cream letters at twice the size of the 5x7 ones
do local x,y,w,h=SIGN-42,59,84,41
 p.rect(x-1,y+h,w+2,1,'concrete 6'); p.rect(x,y,w,h,'sodium 1'); p.rect(x+1,y+1,w-2,h-2,'g gold'); p.rect(x+2,y+2,w-4,h-4,'neon red dim')
 p.hl(x+2,y+2,w-4,'neon red'); p.hl(x+2,y+h-3,w-4,'R rust dark'); p.hl(x+1,y+1,w-2,'sodium 5')
 for _,c in ipairs({{x+4,y+4},{x+w-5,y+4},{x+4,y+h-5},{x+w-5,y+h-5}}) do p.px(c[1],c[2],'g gold') end
 bigtext(p,'POST',SIGN-23+1,y+5+1,'R rust dark',2); bigtext(p,'POST',SIGN-23,y+5,'sodium 5',2)
 bigtext(p,'OFFICE',SIGN-35+1,y+22+1,'R rust dark',2); bigtext(p,'OFFICE',SIGN-35,y+22,'sodium 5',2)
end
-- the stamp machine by the door (its lamp is on `lights`)
p.rect(16,84,30,22,'R rust dark'); p.rect(17,85,28,20,'neon red dim'); p.hl(17,85,28,'neon red')
p.rect(18,87,26,7,'W white'); p.text('STAMPS',20,88,'neon red dim',5)
p.rect(20,97,8,6,'ink'); p.rect(21,98,6,2,'W white'); p.px(22,99,'d denim'); p.rect(32,98,7,2,'ink'); p.px(41,101,'g gold')
-- the socials board (show:socials): a glass-fronted notice case in dark wood
p.rect(SOC.x-4,SOC.y-4,SOC.w+8,SOC.h+8,'wood 2'); p.rect(SOC.x-3,SOC.y-3,SOC.w+6,SOC.h+6,'wood 3'); p.rect(SOC.x,SOC.y,SOC.w,SOC.h,'plaster 3'); p.hl(SOC.x-3,SOC.y-3,SOC.w+6,'wood 4')
p.px(46,112,'g gold'); p.px(133,112,'g gold'); p.px(46,165,'g gold'); p.px(133,165,'g gold')
-- the teller window behind the counter: the clerk's dark booth (the clerk is on `lights`, the brass
-- grille in front of him on `props`); LETTERS above it
K.lightbox(p,178,68,{'LETTERS'},5,'concrete 4','night')
p.rect(148,84,60,58,'wood 2'); p.rect(150,86,56,54,'night'); p.hl(148,84,60,'wood 3')
-- pigeonholes on the booth's back wall, a shaded lamp
for i=0,3 do for j=0,1 do local x,y=152+i*7,88+j*6; p.frame(x,y,7,6,'concrete 2','ink'); if (i+j)%3~=1 then p.hl(x+2,y+3+((i+j)%2),3,'concrete 7') end end end
p.vl(198,86,5,'concrete 3'); p.rect(195,91,7,2,'sodium 2'); p.hl(196,93,5,'sodium 4'); p.dither(194,94,9,4,'concrete 1','night')
p.rect(150,120,56,20,'concrete 2'); p.hl(150,120,56,'concrete 4')
p.rect(154,106,14,10,'concrete 3'); p.rect(160,116,3,4,'concrete 3')
p.oval(166,126,24,8,'night'); p.hl(166,130,24,'g gold')
-- a ticket machine on the pilaster: take a number
p.rect(210,118,9,12,'neon red dim'); p.hl(210,118,9,'neon red'); p.rect(212,121,5,3,'ink'); p.rect(213,126,3,5,'W white'); p.px(214,128,'concrete 5')
-- the PO boxes: a wall of small brass doors, numbered; a plaque over them
p.rect(BOXES.x,BOXES.y,104,72,'wood 1'); p.hl(BOXES.x,BOXES.y,104,'wood 3')
for row=0,6 do for col=0,8 do local x=BOXES.x+2+col*11; local y=BOXES.y+2+row*10
 p.frame(x,y,10,9,'sodium 1','g gold'); p.rect(x+2,y+2,6,3,'wood 1'); p.px(x+7,y+6,'sodium 5'); p.px(x+2,y+6,'sodium 1')
end end
K.plaque(p,240,62,'PO BOXES','sodium 4')
-- NOW SERVING (digits on `lights`)
p.frame(340,68,50,24,'concrete 4','ink'); p.text('NOW',342,70,'concrete 6',5); p.text('SERVING',358,70,'concrete 6',5)
-- a price list, an airmail poster, a clock (its second hand is on `lights`)
p.rect(346,100,30,34,'W white'); p.hl(346,133,30,'concrete 6'); p.text('RATES',351,102,'neon red dim',5); for y=110,130,4 do p.hl(349,y,24,'concrete 6'); p.hl(368,y,5,'concrete 4') end
do local x,y,w,h=382,100,24,34
 p.rect(x,y,w,h,'W white')
 for i=0,w-1 do local c=({'neon red','neon red','W white','d denim','d denim','W white'})[1+i%6]; p.px(x+i,y,c); p.px(x+i,y+h-1,c) end
 for i=0,h-1 do local c=({'neon red','neon red','W white','d denim','d denim','W white'})[1+i%6]; p.px(x,y+i,c); p.px(x+w-1,y+i,c) end
 p.rect(x+3,y+3,w-6,13,'l denim light'); p.hl(x+6,y+9,10,'W white'); p.rect(x+11,y+6,3,7,'W white'); p.px(x+16,y+8,'W white'); p.hl(x+4,y+13,5,'W white'); p.hl(x+14,y+5,5,'W white')
 p.text('AIR',x+6,y+19,'d denim',5); p.text('MAIL',x+4,y+26,'neon red dim',5)
end
p.disc(414,74,7,'g gold'); p.disc(414,74,6,'W white'); p.vl(414,69,5,'ink'); p.hl(414,74,4,'ink')
for i=0,3 do local a=i*math.pi/2; p.px(414+math.floor(math.cos(a)*5+0.5),74+math.floor(math.sin(a)*5+0.5),'concrete 5') end
-- the arched window onto the lane
p.rect(WX0-4,WY0,WX1-WX0+8,WY1-WY0+4,'concrete 7'); p.oval(WX0-4,WY0-14,WX1-WX0+8,28,'concrete 7')
p.rect(WX0,WY0,WX1-WX0,WY1-WY0,0); p.oval(WX0,WY0-10,WX1-WX0,20,0)
p.vl(WX0+(WX1-WX0)//2,WY0-10,WY1-WY0+10,'concrete 7'); for y=WY0+12,WY1-6,18 do p.hl(WX0,y,WX1-WX0,'concrete 7') end
p.rect(WX0-6,WY1,WX1-WX0+12,4,'P pale steel'); p.hl(WX0-6,WY1+3,WX1-WX0+12,'concrete 5')
-- the testimonials board (show:testimonials): a corkboard in dark wood, LETTERS RECEIVED on its
-- plaque, and pinned to it a big airmail postcard (the page's words go on it) among small letters
do local c=CARD; local bx,by,bw,bh=c.x-13,c.y-17,c.w+26,c.h+23
 p.rect(bx-1,by+bh,bw+2,1,'concrete 6'); p.rect(bx,by,bw,bh,'wood 2'); p.rect(bx+1,by+1,bw-2,bh-2,'wood 3'); p.hl(bx+1,by+1,bw-2,'wood 4')
 p.rect(bx+3,by+3,bw-6,bh-6,'plaster 2'); p.hl(bx+3,by+3,bw-6,'plaster 1'); p.vl(bx+3,by+3,bh-6,'plaster 1')
 local r=K.rng(77); for _=1,90 do p.px(bx+4+r(bw-8),by+4+r(bh-8),(r(3)==0) and 'plaster 1' or 'plaster 3') end
 for _,q in ipairs({{bx+1,by+1},{bx+bw-2,by+1},{bx+1,by+bh-2},{bx+bw-2,by+bh-2}}) do p.px(q[1],q[2],'g gold') end
 local pw=K.plaque(p,c.x+c.w//2-33,by+5,'LETTERS RECEIVED','sodium 4','g gold','wood 1'); p.px(c.x+c.w//2-33+1,by+6,'sodium 5'); p.px(c.x+c.w//2-33+pw-2,by+6,'sodium 5')
 -- the postcard: its shadow on the cork, the airmail edge, a stamp and a postmark in the corner
 p.rect(c.x+1,c.y+1,c.w,c.h,'plaster 1'); p.rect(c.x,c.y,c.w,c.h,'sodium 5')
 local stripe={'neon red','neon red','neon red','sodium 5','d denim','d denim','d denim','sodium 5'}
 for i=0,c.w-1 do local col=stripe[1+i%8]; p.px(c.x+i,c.y,col); p.px(c.x+i,c.y+c.h-1,col) end
 for i=0,c.h-1 do local col=stripe[1+i%8]; p.px(c.x,c.y+i,col); p.px(c.x+c.w-1,c.y+i,col) end
 local sx,sy=c.x+c.w-14,c.y+3
 p.rect(sx,sy,11,13,'W white'); for i=0,10,2 do p.px(sx+i,sy,'sodium 5'); p.px(sx+i,sy+12,'sodium 5') end; for i=0,12,2 do p.px(sx,sy+i,'sodium 5'); p.px(sx+10,sy+i,'sodium 5') end
 p.rect(sx+2,sy+2,7,9,'d denim'); p.rect(sx+2,sy+7,7,4,'neon red dim'); p.disc(sx+5,sy+5,2,'neon yellow'); p.hl(sx+2,sy+7,7,'sodium 5')
 p.ring(sx-5,sy+6,5,'concrete 5'); for i=0,2 do p.hl(sx-2,sy+3+i*3,6,'concrete 5') end
 p.rect(c.x+c.w//2-1,c.y-2,3,3,'neon red'); p.px(c.x+c.w//2-1,c.y-2,'W white'); p.px(c.x+c.w//2+1,c.y+1,'neon red dim')
 -- the small letters round it
 envelope(p,bx+4,c.y+2,8,6,'W white','neon red'); p.px(bx+8,c.y+1,'neon yellow')
 p.rect(bx+4,c.y+16,8,7,'l denim light'); p.rect(bx+4,c.y+20,8,3,'leaf 3'); p.px(bx+9,c.y+17,'neon yellow'); p.px(bx+8,c.y+15,'neon cyan')
 envelope(p,bx+4,c.y+31,8,6,'k khaki','neon red dim'); p.px(bx+8,c.y+30,'neon green')
 p.rect(bx+4,c.y+44,8,8,'neon pink'); p.rect(bx+6,c.y+46,4,4,'W white'); p.px(bx+8,c.y+43,'neon yellow')
 local rx=c.x+c.w+2
 p.rect(rx,c.y+3,8,8,'neon yellow'); p.hl(rx+1,c.y+5,6,'wood 3'); p.hl(rx+1,c.y+7,4,'wood 3'); p.px(rx+4,c.y+2,'neon red')
 envelope(p,rx,c.y+17,8,6,'W white','d denim'); p.px(rx+4,c.y+16,'neon pink')
 p.rect(rx,c.y+29,8,7,'holo'); p.rect(rx,c.y+33,8,3,'sodium 3'); p.px(rx+2,c.y+31,'W white'); p.px(rx+4,c.y+28,'neon yellow')
 envelope(p,rx,c.y+43,8,6,'sodium 5','neon red'); p.px(rx+4,c.y+42,'neon cyan')
end
-- the sorting rack at the far end: pigeonholes with letters in them, SORTING over it
do local x,y=RACK.x,RACK.y
 K.plaque(p,x-2,y-13,'SORTING','sodium 4')
 p.rect(x-1,y-1,W-x+1,53,'wood 2'); p.hl(x-1,y-1,W-x+1,'wood 4')
 local r=K.rng(5)
 for row=0,4 do for col=0,2 do local cx,cy=x+col*9,y+row*10
  p.rect(cx,cy,8,9,'wood 1')
  local n=r(4); for i=0,n-1 do p.hl(cx+1,cy+7-i*2,5+r(2),(r(4)==0) and 'k khaki' or 'W white') end
  if r(5)==0 then p.px(cx+5,cy+7,'neon red') end
 end end
end
K.exitLeft(p)

---------------------------------------------------------------- floor: a straight black-and-white checker
p=P.floor
local rows={176,184,194,206,221,240,270}
local TW=24
for i=1,#rows-1 do local y0,y1=rows[i],rows[i+1]
 for x=0,W,TW do p.rect(x,y0,TW,y1-y0,(((x//TW)+i)%2==0) and 'P pale steel' or 'concrete 3') end
end
-- a thin joint between the tiles, so each reads as a tile
for i=2,#rows-1 do for x=0,W,TW do local light=(((x//TW)+i)%2==0); p.hl(x,rows[i],TW,light and 'concrete 7' or 'concrete 2') end end
for i=1,#rows-1 do for x=0,W,TW do local light=(((x//TW)+i)%2==0); p.vl(x,rows[i],rows[i+1]-rows[i],light and 'concrete 7' or 'concrete 2') end end
-- where the wall meets the floor: the skirting's shade, deeper under the furniture
p.rect(0,176,W,2,'ink'); p.hl(0,178,W,'concrete 2')
local function shade(x0,x1) p.rect(x0,178,x1-x0,2,'ink'); p.dither(x0,180,x1-x0,2,'ink','concrete 2') end
shade(150,202); shade(334,398); shade(402,424); shade(494,598); shade(444,462)
-- the doormat, a red runner in front of the counter
p.rect(14,190,34,14,'rust iron 1'); p.rect(15,191,32,12,'rust iron 2'); for x=17,45,3 do p.vl(x,192,10,'rust iron 1') end
p.rect(146,187,60,13,'R rust dark'); p.rect(147,188,58,11,'neon red dim'); p.hl(148,189,56,'g gold'); p.hl(148,197,56,'g gold'); p.vl(148,189,9,'g gold'); p.vl(203,189,9,'g gold')
-- the pile's shadow
p.rect(262,213,54,3,'ink'); p.hl(264,216,50,'concrete 2')

---------------------------------------------------------------- props
p=P.props
-- the brass grille of the teller window (the clerk moves behind it)
for x=152,204,4 do p.vl(x,86,34,'g gold') end; p.hl(150,86,56,'g gold'); p.hl(150,102,56,'sodium 1'); p.hl(150,119,56,'g gold')
-- a queue post by the counter
p.rect(208,160,3,22,'g gold'); p.disc(209,159,2,'g gold'); p.px(208,158,'sodium 5'); p.rect(205,180,9,2,'g gold'); p.hl(205,181,9,'sodium 1')
-- the waiting bench under the price list, a parcel left on it, a wet umbrella against its end
p.rect(338,150,56,3,'wood 3'); p.hl(338,150,56,'wood 4'); p.rect(338,156,56,3,'wood 3'); p.hl(338,156,56,'wood 4')
p.rect(336,166,60,4,'wood 3'); p.hl(336,166,60,'wood 4'); p.hl(336,169,60,'wood 1')
for _,x in ipairs({340,365,390}) do p.vl(x,150,16,'wood 2') end
for _,x in ipairs({338,392}) do p.vl(x,170,12,'wood 2'); p.vl(x+1,170,12,'wood 1') end
p.rect(372,158,12,8,'k khaki'); p.hl(372,158,12,'concrete 7'); p.vl(377,158,8,'wood 3'); p.hl(372,165,12,'Q khaki shadow'); p.rect(379,161,4,3,'W white')
p.line(343,152,340,180,'neon pink dim'); p.line(344,152,341,180,'neon pink'); p.px(344,150,'wood 4'); p.px(345,149,'wood 4'); p.px(346,150,'wood 4'); p.hl(338,181,5,'holo dim')
-- the red mailbox
p.rect(404,140,16,42,'neon red dim'); p.vl(404,140,42,'neon red'); p.oval(403,134,18,10,'neon red dim'); p.hl(406,135,12,'neon red')
p.rect(406,148,12,3,'ink'); p.rect(407,158,10,8,'W white'); p.hl(408,160,8,'concrete 5'); p.hl(408,162,6,'concrete 5'); p.text('MAIL',407,170,'sodium 4',5); p.rect(402,180,20,2,'R rust dark')
-- a plant under the window
K.plant(p,453,182,'bush')
-- under the testimonials board: two tubs of letters and two mail sacks
for i,x in ipairs({498,524}) do
 p.rect(x,170,22,12,'d denim'); p.hl(x,170,22,'l denim light'); p.rect(x,180,22,2,'D denim dark'); p.vl(x,170,12,'l denim light'); p.rect(x+8,174,6,2,'D denim dark')
 for k=0,5 do p.rect(x+2+k*3,166+((k+i)%3),2,4+(k+i)%3-((k+i)%3),((k+i)%4==0) and 'k khaki' or 'W white') end
 p.hl(x+1,170,20,'l denim light')
end
for i,x in ipairs({552,574}) do
 p.oval(x,164,18,19,'Q khaki shadow'); p.oval(x+1,164,15,17,'k khaki'); p.rect(x+5,160,8,5,'k khaki'); p.hl(x+4,165,10,'wood 3'); p.rect(x+6,158,6,2,'Q khaki shadow')
 p.text((i==1) and 'PO' or 'ST',x+5,171,'neon red dim',5)
end

---------------------------------------------------------------- parcels (sort=204): the pile
p=P.parcels
-- one box: its front face (the platform slice's top `fh` rows) and the top face 10 rows above it
local function box(r,fh,front,top,lit,dark)
 local fy=r.y
 p.rect(r.x,fy-10,r.w,10,top); p.hl(r.x,fy-10,r.w,lit); p.vl(r.x,fy-10,10,lit); p.vl(r.x+r.w-1,fy-9,9,front)
 p.rect(r.x,fy,r.w,fh,front); p.hl(r.x,fy,r.w,lit); p.vl(r.x,fy+1,fh-1,top); p.hl(r.x,fy+fh-1,r.w,dark); p.vl(r.x+r.w-1,fy+1,fh-1,dark)
end
do local a,b,c,d=PILE.a,PILE.b,PILE.c,PILE.d
 -- a: the big one, taped down the middle, an address label and a red FRAGILE sticker
 box(a,18,'Q khaki shadow','k khaki','concrete 7','wood 3')
 p.vl(a.x+15,a.y-10,28,'wood 3'); p.vl(a.x+16,a.y-10,28,'wood 4'); p.hl(a.x,a.y+4,a.w,'wood 3')
 p.rect(a.x+3,a.y+7,9,7,'W white'); p.hl(a.x+4,a.y+9,6,'concrete 5'); p.hl(a.x+4,a.y+11,4,'concrete 5')
 p.rect(a.x+20,a.y+6,9,9,'neon red dim'); p.rect(a.x+23,a.y+8,3,3,'W white'); p.vl(a.x+24,a.y+11,2,'W white'); p.hl(a.x+23,a.y+13,3,'W white')
 -- c: beside it, tied with string
 box(c,16,'plaster 2','plaster 3','sodium 5','plaster 1')
 p.vl(c.x+7,c.y-10,26,'W white'); p.hl(c.x,c.y+7,c.w,'W white'); p.px(c.x+6,c.y+6,'W white'); p.px(c.x+8,c.y+6,'W white'); p.px(c.x+7,c.y-5,'concrete 6')
 -- b: on top of a, with this-way-up arrows
 box(b,14,'wood 4','k khaki','sodium 5','wood 3')
 p.hl(b.x,b.y+3,b.w,'wood 3'); p.vl(b.x+9,b.y-10,10,'wood 3')
 for _,x in ipairs({b.x+3,b.x+13}) do p.px(x+1,b.y+5,'wood 1'); p.hl(x,b.y+6,3,'wood 1'); p.vl(x+1,b.y+7,4,'wood 1'); p.hl(x,b.y+11,3,'wood 1') end
 p.rect(b.x+3,b.y-7,6,4,'W white'); p.hl(b.x+4,b.y-5,4,'concrete 5')
 -- d: the small airmail one on top of c
 box(d,8,'P pale steel','W white','W white','concrete 6')
 for i=0,d.w-1 do local col=({'neon red','neon red','W white','d denim','d denim','W white'})[1+i%6]; p.px(d.x+i,d.y+6,col) end
 p.rect(d.x+7,d.y-8,3,4,'d denim'); p.hl(d.x+2,d.y-5,4,'concrete 5'); p.hl(d.x+2,d.y+3,5,'concrete 5')
end

---------------------------------------------------------------- front (1.2, over)
p=P.front
-- a writing desk with forms, a pen on its chain and an ink pad in the foreground; a bin; a trolley of parcels
p.rect(110,232,80,5,'wood 3'); p.hl(110,232,80,'wood 4'); p.rect(112,237,4,33,'wood 1'); p.rect(184,237,4,33,'wood 1'); p.hl(110,236,80,'wood 2')
p.rect(126,229,16,3,'W white'); p.hl(126,231,16,'concrete 6'); p.rect(128,228,16,2,'W white'); p.hl(130,229,10,'concrete 5')
p.rect(150,229,10,3,'neon red dim'); p.hl(150,229,10,'neon red'); p.rect(166,230,3,2,'concrete 4'); p.line(167,229,174,227,'concrete 6'); p.rect(174,226,5,1,'ink'); p.px(179,226,'g gold')
p.rect(380,246,18,24,'concrete 4'); p.hl(380,246,18,'concrete 6'); p.vl(380,246,24,'concrete 5'); p.rect(383,243,6,4,'W white'); p.px(390,245,'P pale steel')
p.rect(560,238,34,32,'Q khaki shadow'); p.rect(560,232,34,7,'k khaki'); p.hl(560,232,34,'concrete 7'); p.vl(576,232,38,'wood 3'); p.rect(564,245,10,8,'W white'); p.hl(565,247,7,'concrete 5'); p.hl(565,249,5,'concrete 5')
p.rect(596,246,22,24,'plaster 2'); p.rect(596,241,22,6,'plaster 3'); p.hl(596,241,22,'sodium 5'); p.hl(596,252,22,'W white'); p.vl(606,241,29,'W white')
p.vl(622,228,42,'concrete 5'); p.vl(623,228,42,'concrete 3'); p.hl(618,228,8,'concrete 6')

---------------------------------------------------------------- frames and the animated layers
for _,n in ipairs(STILL) do K.trim(s,L[n]) end
local FRAMES=12
K.frames(s,FRAMES,0.1)
-- a person standing with their back to us (the arcade's figure). An arm is 'down', 'fwd' (bent in
-- front of them, out of sight) or 'up' (reaching over their head).
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
   elseif a=='up' then g.rect(ax,ty-11,2,14,o.top); g.rect(ax,ty-13,2,2,'s skin')
   else g.rect(ax,ty+1,2,torH-3,o.top); g.rect(ax,ty+torH-2,2,2,'s skin') end
  end
  local hy=ty-headH
  g.rect(cx-4,hy,8,headH,o.hair); g.hl(cx-3,hy+headH-1,6,'S skin shadow'); g.px(cx-5,hy+4,'s skin'); g.px(cx+4,hy+4,'s skin')
  if o.cap then g.rect(cx-4,hy,8,3,o.cap) end
 end)
end
for f=1,FRAMES do
 ------------------------------------------------ lights: on the wall, behind the props
 local q=K.pen(m.canvas(s,L.lights,f))
 K.lightboxText(q,178,68,{'LETTERS'},5,'neon cyan','neon cyan dim',f~=6)
 local n=(f<=6) and 'A-041' or 'A-042'
 q.text(n,355,79,(f==7) and 'neon red dim' or 'neon red',5)
 -- the clock's second hand, once round in the twelve frames; the stamp machine's and the ticket machine's lamps
 local a=(f-1)/12*math.pi*2-math.pi/2
 q.line(414,74,414+math.floor(math.cos(a)*5+0.5),74+math.floor(math.sin(a)*5+0.5),'neon red')
 q.px(41,101,(f%6<3) and 'neon green' or 'neon green dim'); q.px(213,122,(f%4<2) and 'neon green' or 'neon green dim')
 -- the clerk in the booth: a postal cap, stamping letters (the stamp comes down twice a loop); his monitor
 do local down=(f==3 or f==4 or f==9 or f==10); local cx=181
  q.rect(cx-7,109,15,11,'d denim'); q.vl(cx-7,109,11,'l denim light'); q.px(cx,109,'W white'); q.px(cx,111,'g gold'); q.px(cx,114,'g gold')
  q.rect(cx-3,101,7,8,'s skin'); q.hl(cx-3,108,7,'S skin shadow'); q.rect(cx-4,98,9,3,'D denim dark'); q.hl(cx-5,101,11,'d denim'); q.px(cx,99,'g gold')
  if f~=7 then q.px(cx-2,104,'h hair'); q.px(cx+2,104,'h hair') end
  q.hl(cx-1,106,3,'S skin shadow')
  if down then q.rect(cx+8,111,3,5,'d denim'); q.rect(cx+8,116,3,2,'s skin'); q.rect(cx+8,117,3,3,'wood 3'); q.px(cx+7,119,'neon red'); q.px(cx+11,119,'neon red')
  else q.rect(cx+8,109,3,4,'d denim'); q.rect(cx+8,106,3,3,'s skin'); q.rect(cx+8,103,3,3,'wood 3'); q.hl(cx+8,105,3,'neon red dim') end
  q.rect(cx+6,118,8,2,'W white'); if f>=5 and f<=10 then q.rect(cx+8,118,3,1,'neon red dim') end
  q.rect(cx-10,116,5,4,'W white'); q.hl(cx-10,117,5,'concrete 6')
  q.rect(156,107,10,7,'holo dim'); q.hl(157,108+((f-1)//2)%5,7,'holo'); q.px(165,107,'W white')
 end
 K.trim(s,L.lights,f)

 ------------------------------------------------ life: in front of the props
 q=K.pen(m.canvas(s,L.life,f))
 -- next in the queue: a parcel under one arm, checking a phone now and then
 do local look=(f>=7 and f<=11)
  person(q,QUEUE,183,{hair='h hair',top='leaf 3',pants='concrete 3',shoe='b shoe',armL=look and 'fwd' or 'down',armR='fwd'})
  q.hl(QUEUE-5,165,10,'leaf 4')
  outlined(q,function(g) g.rect(QUEUE+5,164,7,7,'k khaki') end); q.hl(QUEUE+5,164,7,'concrete 7'); q.vl(QUEUE+8,164,7,'wood 3')
  if look then q.px(QUEUE-7,163,'screen glow'); q.px(QUEUE-7,164,'holo') end
 end
 -- at the PO boxes: reaches up, opens a box in the bottom row, takes the letter out
 do local reach=(f<=7); local bx,by=BOXES.x+2+8*11,BOXES.y+2+6*10
  if f>=2 and f<=10 then q.rect(bx,by,10,9,'ink'); q.vl(bx-1,by,9,'g gold'); q.vl(bx-2,by+1,7,'sodium 1'); if f<=5 then q.hl(bx+2,by+6,6,'W white') end end
  person(q,BOXER,183,{hair='H hair light',top='r rust',pants='D denim dark',shoe='h hair',armL=reach and 'up' or 'fwd',armR='down'})
  q.hl(BOXER-5,166,10,'R rust dark')
  if f>=6 and f<=7 then q.rect(BOXER-8,145,4,3,'W white') end
  if not reach then outlined(q,function(g) g.rect(BOXER-9,165,6,4,'W white') end); q.hl(BOXER-8,167,4,'concrete 5') end
 end
 -- on the bench: reading a letter, looking up at the board when the number changes
 do local cx=SITTER; local up=(f>=7 and f<=10); local hy=143+(up and 0 or 1)
  outlined(q,function(g)
   g.rect(cx-5,152,10,13,'neon cyan dim'); g.rect(cx-7,153,2,8,'neon cyan dim'); g.rect(cx+5,153,2,8,'neon cyan dim')
   g.rect(cx-5,165,4,13,'concrete 2'); g.rect(cx+1,165,4,13,'concrete 2'); g.rect(cx-6,178,5,2,'b shoe'); g.rect(cx+1,178,5,2,'b shoe')
   g.rect(cx-4,hy,8,9,'s skin'); g.rect(cx-4,hy,8,3,'wood 2'); g.px(cx-4,hy+3,'wood 2'); g.px(cx+3,hy+3,'wood 2')
  end)
  q.hl(cx-5,152,10,'neon cyan'); q.hl(cx-5,165,10,'concrete 4'); q.vl(cx,153,11,'concrete 1')
  if up then q.px(cx-2,hy+5,'h hair'); q.px(cx+1,hy+5,'h hair') else q.hl(cx-2,hy+6,2,'S skin shadow'); q.hl(cx+1,hy+6,2,'S skin shadow') end
  q.hl(cx-1,hy+8,3,'S skin shadow')
  local ly=157+((f==3 or f==4) and 1 or 0)
  outlined(q,function(g) g.rect(cx-4,ly,8,6,'W white') end); q.hl(cx-3,ly+2,6,'concrete 5'); q.hl(cx-3,ly+4,4,'concrete 5'); q.px(cx-5,ly+3,'s skin'); q.px(cx+4,ly+3,'s skin')
  -- the umbrella drips
  local d=(f-1)%6; if d<4 then q.px(340,174+d*2,'holo') end
 end
 -- at the mailbox: a kid on tiptoe posts a letter, then hops
 do local cx=KID; local post=(f<=6); local lift=(post and f>=2) and 1 or ((f==9 or f==11) and 1 or 0); local fy=183-lift
  outlined(q,function(g)
   g.rect(cx-3,fy-1,3,2,'W white'); g.rect(cx+1,fy-1,3,2,'W white')
   g.rect(cx-3,fy-7,3,6,'d denim'); g.rect(cx+1,fy-7,3,6,'d denim')
   g.rect(cx-4,fy-15,9,8,'neon yellow')
   g.rect(cx-4,fy-22,8,7,'h hair')
   if post then g.rect(cx+4,fy-27,2,13,'neon yellow'); g.rect(cx+4,fy-29,2,2,'s skin') else g.rect(cx+5,fy-14,2,6,'neon yellow'); g.rect(cx+5,fy-8,2,2,'s skin') end
   g.rect(cx-6,fy-14,2,6,'neon yellow'); g.rect(cx-6,fy-8,2,2,'s skin')
  end)
  q.hl(cx-4,fy-9,9,'neon yellow dim'); q.hl(cx-3,fy-16,6,'S skin shadow'); q.px(cx+4,fy-19,'s skin'); q.rect(cx-5,fy-21,1,3,'neon pink'); q.px(cx-3,fy-23,'neon pink')
  if f<=4 then outlined(q,function(g) g.rect(cx+3,fy-32,5,3,'W white') end); q.px(cx+6,fy-31,'neon red')
  elseif f==5 then q.rect(cx+6,150,3,2,'W white') end
 end
 -- at the sorting rack: a postal worker puts letters away, one hand then the other
 do local right=(f<=3) or (f>=7 and f<=9); local rest=(f==6 or f==12)
  person(q,SORTER,183,{hair='h hair',cap='D denim dark',top='d denim',pants='D denim dark',shoe='h hair',armL=(not right and not rest) and 'up' or 'fwd',armR=(right and not rest) and 'up' or 'fwd'})
  q.hl(SORTER-5,166,10,'l denim light'); q.hl(SORTER-5,153,10,'d denim')
  if not rest then local ax=right and SORTER+5 or SORTER-7; q.rect(ax-1,144,4,3,'W white'); q.px(ax+2,145,'concrete 5') end
  outlined(q,function(g) g.rect(SORTER-13,170,7,12,'k khaki') end); q.hl(SORTER-13,170,7,'concrete 7'); for i=0,2 do q.vl(SORTER-12+i*2,167+(i%2),3,'W white') end
 end
 -- a pigeon on the window sill: bobs its head, pecks
 do local x,y=438,WY1; local peck=(f==4 or f==5 or f==10); local bob=(f==7 or f==8) and 1 or 0
  outlined(q,function(g)
   g.rect(x,y-5,7,4,'concrete 5'); g.rect(x-2,y-4,2,2,'concrete 4')
   if peck then g.rect(x+6,y-4,3,3,'concrete 6') else g.rect(x+5+bob,y-8,3,4,'concrete 6') end
  end)
  q.hl(x+1,y-3,4,'concrete 6'); q.px(x+5,y-5,'leaf 4'); q.px(x+4,y-5,'neon violet')
  if peck then q.px(x+9,y-2,'sodium 3'); q.px(x+7,y-4,'ink') else q.px(x+8+bob,y-7,'sodium 3'); q.px(x+6+bob,y-7,'ink') end
  q.px(x+2,y-1,'neon pink'); q.px(x+4,y-1,'neon pink')
 end
 -- a delivery drone hovering over the PO boxes with a letter in its clamp
 do local bob=({0,0,1,1,2,2,2,1,1,0,0,0})[f]; local cx,y=DRONE,60+bob
  outlined(q,function(g) g.rect(cx-4,y,9,4,'concrete 3'); g.rect(cx-9,y+1,19,1,'concrete 4'); g.rect(cx-9,y-1,1,2,'concrete 4'); g.rect(cx+9,y-1,1,2,'concrete 4') end)
  q.hl(cx-4,y,9,'concrete 5'); q.px(cx-2,y+2,'holo'); q.px(cx+2,y+2,'holo')
  if f%2==1 then q.hl(cx-12,y-2,7,'concrete 7'); q.hl(cx+6,y-2,7,'concrete 7') else q.hl(cx-10,y-2,3,'P pale steel'); q.hl(cx+8,y-2,3,'P pale steel') end
  q.px(cx,y+4,(f%4<2) and 'neon red' or 'neon red dim')
  q.px(cx-2,y+5,'concrete 5'); q.px(cx+2,y+5,'concrete 5')
  envelope(q,cx-3,y+6,7,4,'W white','neon red')
 end
 K.trim(s,L.life,f)

 ------------------------------------------------ rain, through the window
 local w=K.pen(m.canvas(s,L.rain,f)); local phase=(f-1)%4
 K.rain(w,316,50,480,156,phase,17,'mist 4','mist 5',0.10)
 K.trim(s,L.rain,f)
end
K.note(s,'_lighting','Main light: four globe lamps under the cornice; the pale walls and the vault take it evenly. Accent: mail red (the POST OFFICE plaque, the wainscot, the mailbox, NOW SERVING) and cyan (LETTERS). Brass on the PO boxes and the teller grille. Airmail red and blue on the postcard, the poster and the small parcel. The arched window shows the lane in the rain.')
-- the interactables live in art/objects/post-office/: keep them off the props layer (scripts/art/objects.lua)
dofile('scripts/art/objects.lua').cut(s,'post-office')
K.save(s,'scenes/post-office')
