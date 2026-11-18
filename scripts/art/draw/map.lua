-- map: the town's background, drawn from Codex's map study
-- (art/_work/concept/map-study-v1.png) and Russell's note (2026-11-16) that the
-- town should be crowded, full of life and more futuristic. Only scenery nobody
-- uses: the ground, the lanes and footpaths between the slices' points, the
-- neighbours' blocks and towers, a monorail, an estero, stalls, poles, a jeepney.
-- The six buildings are their own sprites (map-objects/<id>) and are NOT painted
-- here. Every slice is left as it is.
--
--   "C:\aseprite\build\bin\aseprite.exe" -b --script scripts/art/draw/map.lua
--
-- Layers: ground, roads (the originals), over (cables, string lights; over),
-- lights (over, animated: neon, antenna blinks, holo boards, drones), rain
-- (over, animated). Twelve frames of 100 ms.
local K=dofile('scripts/art/draw/kit.lua')
local m=K.m
local s=m.open('map'); local W,H=s.width,s.height
while #s.frames>1 do s:deleteFrame(#s.frames) end
local L={}
for _,l in ipairs(s.layers) do L[l.name]=l end
L.over=K.layer(s,'over','over',L.roads)
L.lights=K.layer(s,'lights','over',L.over)
L.rain=K.layer(s,'rain','over',L.lights)
local P={}
for _,n in ipairs({'ground','roads','over'}) do P[n]=K.pen(m.canvas(s,L[n])) end

-- The points and the stretches between them, read from the slices (the spot is
-- the middle of a point's bottom edge). Buildings' rectangles too.
local pt,bld={},{}
for _,sl in ipairs(s.slices) do
 local b=sl.bounds
 local name=sl.name:match('^point:(.+)$'); if name then pt[name]={x=b.x+b.width//2,y=b.y+b.height,links=sl.data:match('links=([^;]*)') or ''} end
 local id=sl.name:match('^building:(.+)$'); if id then bld[#bld+1]={x=b.x,y=b.y,w=b.width,h=b.height,id=id} end
end
local segs,seen={},{}
for a,p in pairs(pt) do for bname in p.links:gmatch('[^,]+') do local q=pt[bname]
 if q then local key=(a<bname) and a..'|'..bname or bname..'|'..a
  if not seen[key] then seen[key]=true
   local foot=a:find('door') or bname:find('door') or a:find('corner') or bname:find('corner')
   segs[#segs+1]={p.x,p.y,q.x,q.y,foot=foot and true or false} end end end end
local function segdist(px,py,ax,ay,bx,by)
 local dx,dy=bx-ax,by-ay; local l2=dx*dx+dy*dy
 local t=l2>0 and math.max(0,math.min(1,((px-ax)*dx+(py-ay)*dy)/l2)) or 0
 local cx,cy=ax+t*dx,ay+t*dy; return math.sqrt((px-cx)^2+(py-cy)^2)
end
local function clear(x,y,w,h,margin,bm)
 for _,b in ipairs(bld) do if x<b.x+b.w+bm and x+w>b.x-bm and y<b.y+b.h+bm and y+h>b.y-bm then return false end end
 for yy=y,y+h,3 do for xx=x,x+w,3 do
  for _,g in ipairs(segs) do if segdist(xx,yy,g[1],g[2],g[3],g[4])<margin then return false end end
 end end
 return true
end
local function stroke(p,x0,y0,x1,y1,size,c)
 local steps=math.max(math.abs(x1-x0),math.abs(y1-y0),1)
 for i=0,steps do local x=math.floor(x0+(x1-x0)*i/steps+0.5); local y=math.floor(y0+(y1-y0)*i/steps+0.5)
  p.rect(x-size//2,y-size//2,size,size,c) end
end
-- what the animated layer must light later
local blinks,neons,holos={},{},{}

---------------------------------------------------------------- ground
local p=P.ground
local r=K.rng(77)
p.rect(0,0,W,H,'concrete 2')
for i=1,3000 do local x,y=r(W),r(H); p.px(x,y,(r()<0.8) and 'concrete 3' or 'concrete 1') end
for _,d in ipairs({{60,60,40,30},{150,230,60,24},{300,60,40,22},{420,200,40,30},{90,150,30,20}}) do p.oval(d[1],d[2],d[3],d[4],'wood 1'); for i=1,20 do p.px(d[1]+r(d[3]),d[2]+r(d[4]),'wood 2') end end
-- the fogged city beyond everything, along the top edge
p.rect(0,0,W,18,'mist 1'); p.dither(0,16,W,3,'mist 1','concrete 2')
p.disc(436,8,7,'mist 2'); p.disc(436,8,5,'sodium 5'); p.px(434,7,'concrete 7'); p.px(438,10,'sodium 4')
K.skyline(p,{x0=-4,x1=W+4,base=18,topMin=1,topMax=12,wMin=8,wMax=22,fill='mist 2',win='mist 4',winP=0.06,rng=K.rng(3),gap=2,cap=true,ant=true})
-- grass and weeds in the open corners
local grass={{150,150,44,20},{246,118,48,16},{330,168,30,14},{100,138,30,16},{196,200,48,16},{392,146,30,22},{80,96,24,14},{316,78,26,12},{160,230,60,14},{120,66,30,12},{40,120,30,20}}
for _,g in ipairs(grass) do p.oval(g[1],g[2],g[3],g[4],'leaf 1'); for i=1,g[3] do p.px(g[1]+r(g[3]),g[2]+r(g[4]),'leaf 2') end end
-- the estero along the west edge: dark water, ripples, a concrete bank, a footbridge
p.rect(0,56,28,214,'mist 1'); p.rect(28,56,4,214,'concrete 4'); p.vl(28,56,214,'concrete 5'); for i=1,60 do p.hl(2+r(22),60+r(206),3,'mist 2') end; for i=1,20 do p.vl(3+r(22),70+r(190),2+r(3),'sodium 1') end; for i=1,8 do p.vl(4+r(20),80+r(170),2,'neon cyan dim') end; for i=1,5 do p.vl(6+r(18),90+r(150),2,'neon pink dim') end
p.rect(0,150,32,6,'wood 3'); p.hl(0,150,32,'wood 4'); p.hl(0,155,32,'wood 2'); for x=2,30,4 do p.px(x,149,'concrete 6'); p.px(x,156,'concrete 6') end
p.rect(8,214,12,4,'wood 3'); p.hl(8,214,12,'wood 4'); p.px(7,215,'wood 2'); p.px(20,215,'wood 2'); p.rect(11,212,6,2,'k khaki')
-- the square: paving, a hoop, benches, a food cart
p.rect(194,144,62,48,'concrete 3'); for x=194,256,8 do p.vl(x,144,48,'concrete 2') end; for y=144,192,8 do p.hl(194,y,62,'concrete 2') end
for i=1,30 do p.px(194+r(62),144+r(48),'concrete 4') end; p.ring(225,168,9,'concrete 4'); p.hl(216,168,19,'concrete 4')
p.rect(198,178,10,3,'wood 3'); p.hl(198,178,10,'wood 4'); p.rect(240,184,10,3,'wood 3'); p.hl(240,184,10,'wood 4')
p.rect(241,150,7,4,'concrete 7'); p.rect(243,151,3,2,'r rust'); p.vl(244,154,8,'concrete 6'); p.px(244,162,'concrete 4'); p.rect(243,163,3,1,'concrete 1')
p.rect(260,176,12,8,'concrete 7'); p.rect(260,176,12,2,'r rust'); p.rect(262,174,8,2,'r rust'); p.rect(261,184,3,2,'ink'); p.rect(268,184,3,2,'ink'); p.px(266,172,'sodium 4'); p.vl(266,173,1,'concrete 6'); p.rect(263,179,6,3,'sodium 1')
-- the neighbours: blocks with lit fronts and sign boxes, towers at the edges
local houses={}
local roofs={{'rust iron 2','rust iron 1'},{'rust iron 1','wood 1'},{'wood 2','wood 1'},{'concrete 4','concrete 3'},{'plaster 1','wood 1'},{'concrete 3','concrete 2'}}
local walls={'plaster 1','plaster 2','concrete 3','wood 2','concrete 4','plaster 1'}
local neonsets={{'neon pink','neon pink dim'},{'neon cyan','neon cyan dim'},{'neon green','neon green dim'},{'neon violet','neon violet dim'},{'sodium 4','sodium 1'}}
local function rooftop(x,y,w,h)
 local q=r()
 if q<0.2 then p.rect(x+w-8,y+2,6,4,'concrete 5'); p.rect(x+w-7,y+3,4,2,'concrete 4'); p.px(x+w-3,y+3,'neon green')
 elseif q<0.4 then p.disc(x+4,y+4,2,'concrete 5'); p.px(x+3,y+3,'concrete 6')
 elseif q<0.55 then p.rect(x+2,y+2,7,4,'holo dim'); for yy=y+2,y+5,2 do p.hl(x+2,yy,7,'holo') end; p.hl(x+2,y+6,7,'concrete 3')
 elseif q<0.7 then p.ring(x+w-5,y+4,2,'concrete 6'); p.px(x+w-5,y+4,'concrete 7'); p.vl(x+w-5,y+5,3,'concrete 5')
 elseif q<0.85 then for xx=x+2,x+w-3,3 do p.px(xx,y+2,({'concrete 7','d denim','r rust','k khaki'})[1+r(4)]) end; p.hl(x+1,y+1,w-2,'concrete 1')
 else for i=1,4 do p.px(x+1+r(w-2),y+1+r(math.max(1,h-2)),'leaf 3') end end
 if r()<0.4 then local ax=x+2+r(math.max(1,w-4)); p.vl(ax,y-5,6,'concrete 5'); p.hl(ax-1,y-3,3,'concrete 5'); if r()<0.6 then blinks[#blinks+1]={ax,y-6} end end
end
local function block(x,y,w,h)
 local c=roofs[1+r(#roofs)]; local rh=math.max(5,math.floor(h*0.55)); local flat=(r()<0.35)
 if flat then p.rect(x,y,w,rh,'concrete 4'); p.rect(x+1,y+1,w-2,rh-2,'concrete 3'); p.hl(x,y,w,'concrete 5')
 else p.rect(x,y,w,rh,c[1]); for xx=x+1,x+w-1,3 do p.vl(xx,y,rh,c[2]) end; if r()<0.3 then local pw=3+r(5); local px=x+1+r(math.max(1,w-pw-1)); local cc=roofs[1+r(#roofs)]; p.rect(px,y+1,pw,rh-2,cc[1]) end; p.hl(x,y,w,'concrete 5') end
 p.vl(x,y,rh,'concrete 5')
 rooftop(x,y,w,rh)
 -- the front wall facing the viewer: windows, a door, maybe a sign box or an awning
 local wc=walls[1+r(#walls)]; local wy=y+rh; local wh=h-rh
 p.rect(x,wy,w,wh,wc); p.hl(x,wy,w,'wood 1'); p.hl(x,y+h,w,'concrete 1')
 for xx=x+2,x+w-3,4 do local q=r(); p.rect(xx,wy+2,2,2,(q<0.6) and 'sodium 3' or ((q<0.8) and 'sodium 1' or 'night')) end
 if wh>=6 and r()<0.5 then local dx=x+2+r(math.max(1,w-5)); p.rect(dx,wy+wh-4,3,4,'night'); p.px(dx+1,wy+wh-4,'sodium 1') end
 local q=r()
 if q<0.35 and w>=12 then local n=neonsets[1+r(#neonsets)]; local sw=4+r(math.max(1,w-10)); local sx=x+2+r(math.max(1,w-sw-3)); p.rect(sx,wy+1,sw,3,'night'); neons[#neons+1]={sx,wy+1,sw,n[1],n[2]}
 elseif q<0.55 then for xx=x+1,x+w-2,2 do p.px(xx,wy+1,(xx%4<2) and 'r rust' or 'concrete 7') end end
 houses[#houses+1]={x,y,w,h}
end
local function tower(x,y,w,h)
 p.rect(x,y,w,h,'concrete 3'); for xx=x+2,x+w-2,5 do p.vl(xx,y,h,'concrete 2') end; p.hl(x,y,w,'concrete 5'); p.vl(x,y,h,'concrete 4')
 for yy=y+3,y+h-4,3 do for xx=x+3,x+w-3,5 do local q=r(); if q<0.5 then p.px(xx,yy,'mist 5') elseif q<0.65 then p.px(xx,yy,'sodium 1') end end end
 local n=neonsets[1+r(#neonsets)]
 if r()<0.5 then p.rect(x+w-4,y+2,2,h-6,'night'); neons[#neons+1]={x+w-4,y+2,2,n[1],n[2],vert=h-6}
 else local bw=math.min(w-4,10); p.rect(x+2,y+2,bw,6,'night'); holos[#holos+1]={x+2,y+2,bw,6} end
 if r()<0.7 then local ax=x+2+r(math.max(1,w-4)); p.vl(ax,y-7,8,'concrete 5'); blinks[#blinks+1]={ax,y-8} end
 p.rect(x,y+h-2,w,2,'concrete 2'); p.hl(x,y+h,w,'concrete 1')
 houses[#houses+1]={x,y-8,w,h+8}
end
local function free(x,y,w,h) for _,o in ipairs(houses) do if x<o[1]+o[3]+1 and x+w>o[1]-1 and y<o[2]+o[4]+2 and y+h>o[2]-2 then return false end end return true end
local reserved={{40,160,70,36},{190,140,84,56},{54,100,20,30},{0,56,34,214},{90,192,50,34}}
local function reservedHit(x,y,w,h) for _,o in ipairs(reserved) do if x<o[1]+o[3] and x+w>o[1] and y<o[2]+o[4] and y+h>o[2] then return true end end return false end
-- the outer ring: towers first, then everything else packed around the lanes
for i=1,60 do
 local x,y=-10+r(W+10),-6+r(H+6); local w,h=14+r(14),30+r(30)
 local outside=(x+w<84 or x>396 or y+h<48 or y>222)
 if outside and clear(x,y-8,w,h+8,8,4) and free(x,y-8,w,h+8) and not reservedHit(x,y-8,w,h+8) then tower(x,y,w,h) end
end
for pass=1,3 do
 for gy=14,H+6,11 do for gx=-12,W+8,13 do
  local x,y=gx+r(12),gy+r(10); local w,h=10+r(26),10+r(16)
  local inside=(x+w>80 and x<400 and y+h>45 and y<225)
  local want=inside and 0.6 or 0.95
  if r()<want and clear(x,y,w,h,inside and 8 or 6,4) and free(x,y,w,h) and not reservedHit(x,y,w,h) then block(x,y,w,h) end
 end end
end
-- the monorail across the top, on pylons, with a train standing on it
p.rect(0,30,W,4,'concrete 5'); p.hl(0,30,W,'concrete 6'); p.hl(0,34,W,'concrete 3'); for x=14,W,40 do p.rect(x,34,3,12,'concrete 4'); p.px(x+1,34,'concrete 6') end
p.rect(300,24,70,7,'mist 5'); p.hl(300,24,70,'concrete 7'); for x=304,366,6 do p.rect(x,26,3,3,'sodium 3') end; p.rect(300,28,70,1,'neon cyan dim'); p.px(369,27,'sodium 4'); p.px(300,27,'neon red')
-- market stalls by the store lane: tarps on poles, crates, a lamp
for i,c in ipairs({{'d denim','l denim light'},{'r rust','sodium 2'},{'k khaki','Q khaki shadow'}}) do local sx=96+(i-1)*13
 p.rect(sx,198,12,8,c[1]); for yy=198,205,2 do p.hl(sx,yy,12,c[2]) end; p.hl(sx,206,12,'concrete 1'); p.rect(sx+1,208,10,6,'wood 3'); p.hl(sx+1,208,10,'wood 4'); p.rect(sx+2,215,3,3,'rust iron 2'); p.rect(sx+6,215,4,3,'k khaki'); p.px(sx,197,'concrete 6'); p.px(sx+11,197,'concrete 6')
end
p.vl(134,196,8,'concrete 5'); p.rect(135,196,3,2,'sodium 3')
-- trees: canopies seen from above, a shadow to the lower right; banana plants
local function tree(x,y,rad)
 if not clear(x-rad,y-rad,2*rad,2*rad,4,2) then print('tree skipped at '..x..','..y) return end
 p.oval(x-rad+2,y-rad+3,2*rad,2*rad,'concrete 1')
 p.disc(x,y,rad,'leaf 2'); p.disc(x-1,y-2,rad-2,'leaf 3'); p.px(x-2,y-3,'leaf 4'); p.px(x+1,y-1,'leaf 4'); p.px(x+2,y+2,'leaf 1'); p.px(x-3,y+1,'leaf 1')
 p.rect(x,y+rad-1,2,2,'wood 2')
end
for _,t in ipairs({{202,152,6},{100,146,5},{168,158,6},{258,128,5},{328,176,5},{90,232,6},{312,236,5},{428,98,5},{64,140,5},{176,80,5},{216,60,5},{404,206,5},{250,180,6}}) do tree(t[1],t[2],t[3]) end
local function banana(x,y) for _,d in ipairs({{-4,-3},{4,-3},{-3,-6},{3,-6},{0,-8}}) do p.line(x,y,x+d[1],y+d[2],'leaf 3'); p.px(x+d[1],y+d[2],'leaf 4') end; p.vl(x,y-2,3,'leaf 2') end
banana(152,120); banana(286,112); banana(396,160); banana(60,96)
for _,b in ipairs({{150,118},{282,110},{320,136},{356,140},{248,214},{128,196},{380,180},{180,112}}) do p.oval(b[1]-3,b[2]-2,7,5,'leaf 2'); p.px(b[1]-1,b[2]-1,'leaf 3'); p.px(b[1]+1,b[2],'leaf 3') end
-- the jeepney parked by the west lane, facing east; a tricycle behind the post office; a scooter
p.oval(50,170,46,16,'concrete 1')
p.rect(50,168,44,14,'r rust'); p.rect(50,168,44,1,'R rust dark'); p.rect(50,181,44,1,'R rust dark'); p.rect(54,170,28,10,'concrete 6'); for x=56,80,4 do p.vl(x,170,10,'concrete 7') end; p.rect(54,170,28,1,'concrete 7')
p.rect(83,170,3,10,'holo dim'); p.px(84,171,'holo'); p.rect(87,170,7,10,'R rust dark'); p.rect(88,171,5,8,'r rust'); p.hl(88,171,5,'sodium 2'); p.px(93,171,'sodium 4'); p.px(93,178,'sodium 4'); p.rect(50,170,2,10,'concrete 5'); p.px(51,174,'sodium 3')
p.rect(56,166,3,3,'ink'); p.rect(80,166,3,3,'ink'); p.rect(56,181,3,3,'ink'); p.rect(80,181,3,3,'ink')
for x=58,78,4 do p.px(x,168,'sodium 4'); p.px(x,181,'neon cyan') end
p.rect(404,166,6,9,'d denim'); p.hl(404,166,6,'l denim light'); p.rect(410,168,5,6,'sodium 2'); p.hl(410,168,5,'sodium 3'); p.rect(405,175,2,2,'ink'); p.rect(411,174,2,2,'ink'); p.rect(405,164,2,2,'ink')
p.rect(300,196,3,7,'concrete 6'); p.px(301,195,'neon cyan dim'); p.rect(300,203,3,2,'ink')
-- a water tower at the west edge, breeze-block walls either side of the school's gate
p.rect(56,106,10,2,'concrete 4'); p.vl(57,108,20,'concrete 4'); p.vl(64,108,20,'concrete 4'); p.hl(57,118,8,'concrete 4'); p.disc(61,105,5,'concrete 5'); p.ring(61,105,5,'concrete 4'); p.px(59,103,'concrete 6')
for _,x in ipairs({236,282}) do p.rect(x,101,26,4,'concrete 5'); for xx=x+1,x+24,3 do p.rect(xx,102,2,2,'concrete 3') end; p.hl(x,105,26,'concrete 2') end
-- poles (their cables are on `over`)
local poles={{132,172},{230,160},{312,142},{392,124},{206,98},{326,208},{96,214},{364,146},{150,130},{270,206},{344,100},{250,96},{36,118},{36,232}}
for _,q in ipairs(poles) do p.vl(q[1],q[2]-10,10,'concrete 5'); p.px(q[1],q[2]-10,'concrete 6'); p.hl(q[1]-2,q[2]-9,5,'concrete 5'); p.rect(q[1]+1,q[2]-8,3,2,'sodium 3'); p.px(q[1]+2,q[2]-8,'sodium 5'); p.rect(q[1]-1,q[2],3,1,'concrete 1'); p.rect(q[1]-1,q[2]-4,3,3,'concrete 4') end

---------------------------------------------------------------- roads
p=P.roads
for _,g in ipairs(segs) do if not g.foot then stroke(p,g[1],g[2],g[3],g[4],14,'concrete 2') end end
for _,g in ipairs(segs) do if not g.foot then stroke(p,g[1],g[2],g[3],g[4],12,'concrete 3') end end
for _,g in ipairs(segs) do if g.foot then stroke(p,g[1],g[2],g[3],g[4],7,'concrete 2'); stroke(p,g[1],g[2],g[3],g[4],5,'concrete 4') end end
-- kerbs lined with small lights, like a lane at fiesta time
local kerbLamps={}
for _,g in ipairs(segs) do if not g.foot then
 local dx,dy=g[3]-g[1],g[4]-g[2]; local len=math.sqrt(dx*dx+dy*dy); local nx,ny=-dy/len,dx/len
 for i=0,math.floor(len),2 do local x,y=g[1]+dx*i/len,g[2]+dy*i/len
  for _,sgn in ipairs({-1,1}) do local kx,ky=math.floor(x+nx*7*sgn+0.5),math.floor(y+ny*7*sgn+0.5)
   if i%22==0 then kerbLamps[#kerbLamps+1]={kx,ky} else p.px(kx,ky,'concrete 5') end end
 end
end end
r=K.rng(5)
for _,g in ipairs(segs) do
 local len=math.max(math.abs(g[3]-g[1]),math.abs(g[4]-g[2]))
 for i=0,len,3 do local t=i/len; local x=math.floor(g[1]+(g[3]-g[1])*t); local y=math.floor(g[2]+(g[4]-g[2])*t)
  local off=g.foot and (r(3)-1) or (r(9)-4)
  if g.foot then if i%6==0 then p.rect(x+off,y+(r(3)-1),2,1,'concrete 4') end
  else local q=r()
   if q<0.14 then p.rect(x+off,y,1+r(3),1,'concrete 4') elseif q<0.18 then p.px(x+off,y,'concrete 2') elseif q<0.21 then p.rect(x+off,y,2,2,'concrete 2') end
  end
 end
end
local function pool(cx,cy,rad,c1,c2)
 for y=-rad,rad do for x=-rad,rad do local d=x*x+y*y
  if d<=(rad*rad)//2 then p.px(cx+x,cy+y,c1) elseif d<=rad*rad and (x+y)%2==0 then p.px(cx+x,cy+y,c1) end end end
 for i=1,7 do local a=r()*6.283; local d=r()*rad*0.6; p.px(cx+math.floor(math.cos(a)*d),cy+math.floor(math.sin(a)*d*0.6),c2) end
end
for _,q in ipairs(poles) do pool(q[1]+2,q[2]+4,9,'concrete 4','sodium 1') end
for _,k in ipairs(kerbLamps) do pool(k[1],k[2]+1,3,'concrete 4','sodium 1'); p.px(k[1],k[2],'sodium 3'); p.px(k[1],k[2]-1,'sodium 4') end
for i=1,16 do p.px(344+r(44),118+r(14),'neon pink dim') end
for i=1,10 do p.px(352+r(40),194+r(6),'neon cyan dim') end
for i=1,8 do p.px(104+r(28),118+r(8),'neon cyan dim') end
for i=1,8 do p.px(246+r(40),106+r(6),'neon violet dim') end
for i=1,8 do p.px(150+r(40),218+r(6),'neon green dim') end
for i=1,8 do p.px(262+r(30),218+r(6),'sodium 1') end
-- the signs' colours in the wet along every lane, faint
for _,n in ipairs(neons) do for i=1,3 do local x=n[1]+r(n[3]); local y=n[2]+6+r(10); p.px(x,y,n[5]) end end

---------------------------------------------------------------- over: cables slung between the poles, string lights, banderitas
p=P.over
local function cable(x0,y0,x1,y1,sag,c)
 local n=math.max(math.abs(x1-x0),1)
 for i=0,n do local t=i/n; local x=math.floor(x0+(x1-x0)*t+0.5); local y=math.floor(y0+(y1-y0)*t+sag*4*t*(1-t)+0.5); p.px(x,y,c) end
end
local runs={{1,2},{2,3},{3,4},{5,2},{1,7},{3,6},{8,4},{9,1},{9,5},{10,6},{11,4},{12,5},{12,11}}
for _,u in ipairs(runs) do local a,b=poles[u[1]],poles[u[2]]
 cable(a[1],a[2]-10,b[1],b[2]-10,6,'ink'); cable(a[1],a[2]-9,b[1],b[2]-9,7,'concrete 4') end
for i=0,13 do local x=198+i*4; local y=140+math.floor(3*math.sin(i/13*math.pi)+0.5); p.px(x,y,({'neon pink','neon cyan','sodium 4'})[1+i%3]); p.px(x,y-1,'concrete 1') end
for i=0,9 do local x=340+i*5; local y=108+math.floor(2*math.sin(i/9*math.pi)+0.5); p.px(x,y,({'neon pink','sodium 4'})[1+i%2]); p.px(x,y-1,'concrete 1') end
for i=0,11 do local x=140+i*5; local y=200+math.floor(3*math.sin(i/11*math.pi)+0.5); p.px(x,y-1,'concrete 1'); p.rect(x,y,2,2,({'r rust','sodium 4','d denim','leaf 4','concrete 7'})[1+i%5]) end

---------------------------------------------------------------- frames, the lights and the rain
for _,n in ipairs({'ground','roads','over'}) do K.trim(s,L[n]) end
local FRAMES=12
K.frames(s,FRAMES,0.1)
local drones={{236,120},{372,96},{176,186}}
for f=1,FRAMES do
 local q=K.pen(m.canvas(s,L.lights,f))
 for i,n in ipairs(neons) do local on=((i+f)%11)~=0
  if n.vert then for yy=n[2],n[2]+n.vert-1 do q.px(n[1],yy,(on and (yy%3~=0)) and n[4] or n[5]) end
  else q.rect(n[1],n[2],n[3],3,n[5]); if on then q.hl(n[1],n[2]+1,n[3],n[4]) end end
 end
 for i,b in ipairs(blinks) do q.px(b[1],b[2],(((i+f)%6)<3) and 'neon red' or 'neon red dim') end
 for i,h in ipairs(holos) do local off=((i+f)%7==0) and 1 or 0
  q.rect(h[1],h[2],h[3],h[4],'holo dim'); for yy=h[2]+off,h[2]+h[4]-1,2 do q.hl(h[1],yy,h[3],'holo') end
  if (i+f)%5==0 then q.rect(h[1]+1,h[2]+1,2,2,'neon pink') end
 end
 for i,d in ipairs(drones) do local bob=(((f+i*3)//3)%2==0) and 0 or 1; local x,y=d[1],d[2]+bob
  q.hl(x-2,y,5,'concrete 6'); q.px(x,y-1,'concrete 6'); q.px(x,y+1,'concrete 6'); q.px(x,y,(f%2==0) and 'holo' or 'holo dim'); q.px(x-2,y,(f%4<2) and 'neon red' or 'concrete 6')
 end
 K.trim(s,L.lights,f)
 local w=K.pen(m.canvas(s,L.rain,f)); local phase=(f-1)%4
 K.rain(w,0,0,W,H,phase,9,'concrete 4','concrete 5',0.05)
 K.trim(s,L.rain,f)
end
K.note(s,'_lighting','Night from above: sodium lamps on the poles throw warm pools on the wet lanes; each building sprite carries its own sign colour, reflected in the puddles by its door. The neighbours have unlettered lit-box signs, holo boards and antenna lights on the lights layer (over, animated). Rain on the rain layer (over). Only scenery here; the buildings are map-objects/<id>.')
K.save(s,'map')
