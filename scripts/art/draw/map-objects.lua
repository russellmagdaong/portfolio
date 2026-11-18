-- map-objects/<id>: the six buildings on the town map, one sprite each, drawn
-- from Codex's map study (art/_work/concept/map-study-v1.png) with the specific
-- titles Russell asked for (2026-11-16) as their signs. Two frames: idle and
-- hover (the same building with a warm 1-px rim). The `base` slice, the layer
-- name and the tags are left as they are.
--
--   "C:\aseprite\build\bin\aseprite.exe" -b --script scripts/art/draw/map-objects.lua
--
-- The view is the map's: from above and in front, so a building shows its
-- corrugated roof (ridges running down the slope) over a short front wall with
-- the door in the middle of the bottom edge. Light comes from the upper left.
local K=dofile('scripts/art/draw/kit.lua')
local m=K.m

local function glyph(p,g,x,y,c)
 local yy=0
 for row in g:gmatch('[^/]+') do for i=1,#row do if row:sub(i,i)=='1' then p.px(x+i-1,y+yy,c) end end; yy=yy+1 end
end
local function textw(t) return #t*4-1 end
-- 3x5 text that knows an apostrophe (1 px wide, 2 tall, then a 1-px gap)
local function label(p,t,x,y,c)
 for part,ap in t:gmatch("([^']*)(')") do p.text(part,x,y,c,5); x=x+textw(part)+1; p.rect(x,y,1,2,c); x=x+2 end
 local last=t:match("([^']*)$"); p.text(last,x,y,c,5)
end
local function labelw(t) local n=0; for ch in t:gmatch('.') do n=n+((ch=="'") and 3 or 4) end; return n-1 end

-- A corrugated roof seen from above: ridges run down the slope. Lit at the top left.
local function roof(p,x,y,w,h,base,rib,r,patches)
 p.rect(x,y,w,h,base)
 for xx=x+1,x+w-1,3 do p.vl(xx,y,h,rib) end
 for i=1,(patches or 0) do local pw=4+r(6); local px=x+r(math.max(1,w-pw)); local c=({'concrete 4','wood 3','plaster 1','rust iron 1'})[1+r(4)]
  p.rect(px,y+1,pw,h-2,c); for xx=px+1,px+pw-1,3 do p.vl(xx,y+1,h-2,rib) end end
 p.hl(x,y,w,'plaster 3'); p.hl(x,y+h-1,w,'wood 1'); p.vl(x,y,h,'plaster 3')
end
local function door(p,x,y,w,h,glow)
 p.rect(x-1,y-1,w+2,h+1,'wood 2'); p.rect(x,y,w,h,'night'); p.rect(x,y,w,2,glow or 'sodium 1'); p.px(x+w-2,y+h//2,'sodium 4')
end
local function window(p,x,y,w,h,lit)
 p.rect(x-1,y-1,w+2,h+2,'wood 2'); p.rect(x,y,w,h,lit or 'sodium 3'); p.hl(x,y,w,'sodium 4')
 for xx=x+2,x+w-2,3 do p.vl(xx,y,h,'wood 2') end; p.hl(x,y+h//2,w,'wood 2')
end
-- a lit sign board centred on cx, its bottom at y: lines of 3x5 in colour c (neon ones get a dim ring)
local function sign(p,cx,y,lines,c,dim,board,edge)
 local w=0; for _,t in ipairs(lines) do w=math.max(w,labelw(t)) end
 local h=#lines*6+3; local x=cx-(w+6)//2
 p.frame(x,y-h,w+6,h,edge or 'concrete 2',board or 'night')
 local ty=y-h+2
 for _,t in ipairs(lines) do local tx=cx-labelw(t)//2
  if dim then for dx=-1,1 do for dy=-1,1 do if dx~=0 or dy~=0 then label(p,t,tx+dx,ty+dy,dim) end end end end
  label(p,t,tx,ty,c); ty=ty+6 end
 return x,y-h,w+6,h
end
local function sidewalk(p,x,y,w) p.rect(x,y,w,3,'concrete 4'); p.hl(x,y+2,w,'concrete 3'); p.hl(x,y,w,'concrete 5') end
local function pot(p,x,y) p.rect(x,y-3,4,3,'rust iron 2'); p.hl(x,y-3,4,'r rust'); p.oval(x-1,y-7,6,4,'leaf 3'); p.px(x+1,y-7,'leaf 4') end
local function ac(p,x,y) p.rect(x,y,8,5,'concrete 5'); p.hl(x,y,8,'concrete 6'); p.rect(x+1,y+1,6,3,'concrete 4'); p.px(x+6,y+1,'neon green') end
local function tank(p,x,y) p.disc(x,y,3,'concrete 5'); p.ring(x,y,3,'concrete 4'); p.px(x-1,y-1,'concrete 6') end

-- The warm rim for the hover frame: every clear pixel next to a drawn one.
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

local B={}
-- home 50x40: a small house, capiz windows, a water tank, a clothesline, plants
B.home=function(p,x,y,w,h)
 local r=K.rng(1)
 roof(p,x,y+4,w,12,'rust iron 2','rust iron 1',r,2); tank(p,x+42,y+4); p.vl(x+42,y+6,3,'concrete 4')
 p.vl(x+6,y,8,'concrete 5'); p.hl(x+4,y,5,'concrete 5'); p.px(x+9,y+1,'neon red')
 p.rect(x+1,y+16,w-2,21,'plaster 2'); p.vl(x+1,y+16,21,'plaster 3'); p.rect(x+w-4,y+16,3,21,'plaster 1'); p.hl(x+1,y+32,w-2,'wood 2')
 window(p,x+5,y+21,10,7); window(p,x+35,y+21,10,7)
 door(p,x+21,y+25,8,12)
 sign(p,x+25,y+21,{"RUSSELL'S",'ROOM'},'neon cyan','neon cyan dim','night','wood 3')
 sidewalk(p,x,y+37,w); pot(p,x+3,y+37); pot(p,x+43,y+37)
 p.hl(x+30,y+18,16,'concrete 6'); p.rect(x+33,y+19,2,3,'concrete 7'); p.rect(x+39,y+19,2,3,'d denim'); p.rect(x+43,y+19,1,2,'r rust')
end
-- school 76x52: the campus block, breeze blocks, many lit windows, a flag and a clock
B.school=function(p,x,y,w,h)
 local r=K.rng(2)
 roof(p,x,y+6,w,14,'plaster 1','wood 1',r,1); p.rect(x+32,y+2,12,6,'concrete 5'); p.hl(x+32,y+2,12,'concrete 6'); p.ring(x+38,y+5,2,'concrete 3'); p.px(x+38,y+5,'sodium 4')
 p.vl(x+66,y,16,'concrete 6'); p.rect(x+67,y+1,6,4,'d denim'); p.rect(x+67,y+3,6,2,'r rust'); p.px(x+68,y+2,'sodium 4')
 p.rect(x+1,y+20,w-2,29,'concrete 5'); p.vl(x+1,y+20,29,'concrete 6'); p.rect(x+w-4,y+20,3,29,'concrete 4'); p.hl(x+1,y+44,w-2,'concrete 3')
 for xx=x+4,x+22,4 do for yy=y+24,y+32,4 do p.rect(xx,yy,3,3,'concrete 3'); p.px(xx+1,yy+1,'concrete 6') end end
 for xx=x+54,x+70,4 do for yy=y+24,y+32,4 do p.rect(xx,yy,3,3,'concrete 3'); p.px(xx+1,yy+1,'concrete 6') end end
 window(p,x+6,y+37,8,6); window(p,x+17,y+37,8,6); window(p,x+51,y+37,8,6); window(p,x+62,y+37,8,6)
 p.rect(x+28,y+26,20,23,'concrete 6'); p.vl(x+28,y+26,23,'concrete 7'); door(p,x+33,y+36,10,13,'sodium 2'); p.vl(x+38,y+36,13,'wood 2')
 sign(p,x+38,y+34,{'ABOUT ME'},'neon violet','neon violet dim','night','concrete 3')
 sidewalk(p,x,y+49,w); p.rect(x+26,y+46,24,3,'concrete 6'); pot(p,x+2,y+49); pot(p,x+71,y+49)
end
-- arcade 56x46: the pink frontage, cabinets in the windows, an AC unit, a pennant string
B.arcade=function(p,x,y,w,h)
 local r=K.rng(3)
 roof(p,x,y+5,w,13,'concrete 4','concrete 3',r,2); ac(p,x+44,y+1); p.vl(x+6,y,5,'concrete 5'); p.hl(x+3,y+1,7,'concrete 5')
 p.rect(x+1,y+18,w-2,25,'plaster 1'); p.vl(x+1,y+18,25,'plaster 2'); p.rect(x+w-4,y+18,3,25,'concrete 2')
 p.rect(x+2,y+20,w-4,3,'neon pink dim'); p.hl(x+2,y+20,w-4,'neon pink')
 for _,wx in ipairs({x+5,x+40}) do p.rect(wx-1,y+26,13,11,'concrete 2'); p.rect(wx,y+27,11,9,'night')
  p.rect(wx+1,y+28,4,7,'d denim'); p.rect(wx+1,y+28,4,2,'neon cyan'); p.rect(wx+6,y+28,4,7,'r rust'); p.rect(wx+6,y+28,4,2,'sodium 4'); p.hl(wx,y+35,11,'neon pink dim') end
 door(p,x+24,y+31,8,12,'neon pink dim'); p.hl(x+22,y+37,12,'neon pink dim')
 sign(p,x+28,y+30,{'PROJECTS'},'neon pink','neon pink dim','night','concrete 3')
 sidewalk(p,x,y+43,w); p.hl(x+10,y+44,36,'neon pink dim'); pot(p,x+2,y+43)
 for i=0,8 do local px=x+8+i*5; local c=({'neon pink','neon cyan','sodium 4'})[1+i%3]; p.px(px,y+19,c); p.px(px,y+20,c) end
end
-- store 44x30: the sari-sari store, a striped awning, sachet strips, a grille, a crate
B.store=function(p,x,y,w,h)
 local r=K.rng(4)
 roof(p,x,y+2,w,10,'rust iron 1','wood 1',r,1); tank(p,x+38,y+3)
 p.rect(x+1,y+12,w-2,15,'plaster 2'); p.vl(x+1,y+12,15,'plaster 3'); p.rect(x+w-4,y+12,3,15,'plaster 1')
 for xx=x+1,x+w-3,4 do p.rect(xx,y+14,2,3,'r rust'); p.rect(xx+2,y+14,2,3,'concrete 7') end; p.hl(x+1,y+17,w-2,'wood 2')
 p.rect(x+3,y+19,16,7,'night'); for i=0,3 do local c=({'sodium 3','neon cyan dim','r rust','leaf 4','k khaki','neon pink'})[1+(i*2+r(2))%6]; p.rect(x+4+i*4,y+20,3,5,c); p.px(x+5+i*4,y+21,'concrete 7') end
 for xx=x+3,x+18,3 do p.vl(xx,y+19,7,'concrete 4') end
 door(p,x+24,y+16,7,10); p.rect(x+34,y+20,7,6,'wood 3'); p.hl(x+34,y+20,7,'wood 4'); p.vl(x+37,y+20,6,'wood 2')
 sign(p,x+22,y+12,{'TOOLS'},'neon green','neon green dim','night','wood 3')
 sidewalk(p,x,y+27,w); p.rect(x+2,y+25,5,4,'r rust'); p.hl(x+2,y+25,5,'sodium 2')
end
-- trophy shop 50x36: a glass front, brass trophies on shelves, a flower on the board
B['trophy-shop']=function(p,x,y,w,h)
 local r=K.rng(5)
 roof(p,x,y+4,w,12,'wood 2','wood 1',r,1); ac(p,x+2,y+1)
 p.rect(x+1,y+16,w-2,17,'plaster 1'); p.vl(x+1,y+16,17,'plaster 2'); p.rect(x+w-4,y+16,3,17,'concrete 2')
 for _,wx in ipairs({x+3,x+33}) do p.rect(wx,y+21,14,9,'wood 3'); p.rect(wx+1,y+22,12,7,'concrete 2'); p.hl(wx+1,y+26,12,'wood 4')
  for i=0,2 do local tx=wx+2+i*4; p.rect(tx,y+23,3,3,'g gold'); p.px(tx+1,y+26,'g gold'); p.rect(tx,y+27,3,1,'sodium 2'); p.px(tx,y+23,'sodium 5') end end
 door(p,x+21,y+22,8,11)
 sign(p,x+25,y+20,{'AWARDS AND','CERTIFICATES'},'sodium 4',nil,'wood 2','wood 3')
 p.px(x+2,y+9,'neon pink'); p.px(x+1,y+10,'neon pink'); p.px(x+3,y+10,'neon pink'); p.px(x+2,y+11,'neon pink'); p.px(x+2,y+10,'sodium 4')
 sidewalk(p,x,y+33,w); pot(p,x+45,y+33)
end
-- post office 48x38: a cyan sign, a letterbox, a basket of parcels, mail cubbies in the window
B['post-office']=function(p,x,y,w,h)
 local r=K.rng(6)
 roof(p,x,y+4,w,12,'concrete 4','concrete 3',r,2); ac(p,x+38,y+1); p.vl(x+4,y,6,'concrete 5'); p.hl(x+2,y+1,5,'concrete 5')
 p.rect(x+1,y+16,w-2,19,'concrete 5'); p.vl(x+1,y+16,19,'concrete 6'); p.rect(x+w-4,y+16,3,19,'concrete 4'); p.hl(x+1,y+30,w-2,'concrete 3')
 p.rect(x+4,y+22,14,8,'wood 3'); for yy=y+23,y+29,3 do for xx=x+5,x+16,4 do p.rect(xx,yy,3,2,'wood 1'); p.px(xx+1,yy,'k khaki') end end
 door(p,x+20,y+24,8,11)
 p.rect(x+32,y+24,6,8,'r rust'); p.hl(x+32,y+24,6,'sodium 2'); p.hl(x+33,y+26,4,'night')
 p.rect(x+40,y+28,6,6,'k khaki'); p.hl(x+40,y+28,6,'Q khaki shadow'); p.rect(x+41,y+26,4,2,'plaster 3'); p.px(x+42,y+30,'Q khaki shadow')
 sign(p,x+24,y+22,{'CONTACT'},'neon cyan','neon cyan dim','night','concrete 3')
 sidewalk(p,x,y+35,w); pot(p,x+2,y+35)
end

for _,id in ipairs({'home','school','arcade','store','trophy-shop','post-office'}) do
 local s=m.open('map-objects/'..id)
 local layer=s.layers[1]
 local base; for _,sl in ipairs(s.slices) do if sl.name=='base' then base=sl end end
 local bw,bh=base.bounds.width,base.bounds.height+base.bounds.y-2
 local x0,y0=base.bounds.x,2
 for f=1,2 do
  local im=m.canvas(s,layer,f); local p=K.pen(im)
  B[id](p,x0,y0,bw,bh)
  if f==2 then rim(im,'sodium 4') end
 end
 for _,l in ipairs(s.layers) do if l.name:sub(1,1)=='_' then l.isVisible=false end end
 s:saveAs('art/map-objects/'..id..'.aseprite')
 print('saved map-objects/'..id..' '..bw..'x'..bh)
end
