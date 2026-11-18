-- Shared scene pieces for the scene scripts (home, arcade, ...), on top of
-- common.lua's pen. Everything draws with palette names only.
--
--   local K=dofile('scripts/art/draw/kit.lua')
--   local p=K.pen(image)   -- common.lua's pen plus the helpers below
local m=dofile('scripts/art/draw/common.lua')
local K={m=m,C=m.C}

-- A seeded generator, so a redraw gives the same picture.
-- r() is a float in [0,1); r(n) is an integer in [0,n-1].
function K.rng(seed)
 local s=(seed or 1)%2147483647
 if s==0 then s=1 end
 return function(n) s=(s*48271)%2147483647; if n then return s%n end; return s/2147483647 end
end

function K.pen(im)
 local p=m.pen(im)
 function p.px(x,y,c) p.rect(x,y,1,1,c) end
 function p.hl(x,y,w,c) p.rect(x,y,w,1,c) end
 function p.vl(x,y,h,c) p.rect(x,y,1,h,c) end
 -- 2-pixel checker between two colours (the brief's dither for sky bands).
 function p.dither(x,y,w,h,c1,c2)
  for yy=y,y+h-1 do for xx=x,x+w-1 do
   p.px(xx,yy,((xx//2+yy//2)%2==0) and c1 or c2) end end
 end
 function p.disc(cx,cy,r,c) p.oval(cx-r,cy-r,2*r+1,2*r+1,c) end
 function p.ring(cx,cy,r,c)
  for yy=-r,r do for xx=-r,r do local d=math.sqrt(xx*xx+yy*yy)
   if d>=r-0.5 and d<r+0.5 then p.px(cx+xx,cy+yy,c) end end end
 end
 -- A pennant pointing right (dir=1) or left (dir=-1) from x; w long, h tall at the pole.
 function p.pennant(x,y,w,h,dir,c)
  for i=0,w-1 do local hh=math.max(1,math.floor(h*(w-i)/w+0.5)); local top=y+math.floor((h-hh)/2)
   p.rect(x+i*dir,top,1,hh,c) end
 end
 -- A box with its top face lit: front face, thin top face, lit left edge.
 function p.block(x,y,w,h,front,top,topH,edge)
  p.rect(x,y,w,h,front); p.rect(x,y,w,topH or 2,top); if edge then p.vl(x,y,h,edge) end
 end
 return p
end

-- Irregular towers from x0 to x1 standing on o.base, tops between o.topMin and
-- o.topMax, filled with o.fill; o.win dots lit windows with probability o.winP.
function K.skyline(p,o)
 local r=o.rng or K.rng(1); local x=o.x0
 while x<o.x1 do
  local w=o.wMin+r(o.wMax-o.wMin+1); local top=o.topMin+r(o.topMax-o.topMin+1)
  p.rect(x,top,w,o.base-top,o.fill)
  if o.cap and r()<0.5 then p.rect(x+1+r(math.max(1,w-4)),top-2,2+r(2),2,o.fill) end
  if o.ant and r()<0.35 then local h=5+r(5); p.rect(x+2+r(math.max(1,w-4)),top-h,1,h,o.fill) end
  if o.win then
   for yy=top+3,o.base-4,(o.wy or 4) do for xx=x+2,x+w-3,(o.wx or 3) do
    local q=r(); if q<o.winP then p.px(xx,yy,o.win) elseif o.win2 and q<o.winP+(o.win2P or 0) then p.px(xx,yy,o.win2) end
   end end
  end
  x=x+w+(o.gap and r(o.gap+1) or 0)
 end
end

-- A row of book spines standing on y (their bottom edge), n of them, from x.
function K.books(p,x,y,n,r,hMin,hMax,extra)
 local cols=extra or {'rust iron 2','D denim dark','leaf 2','plaster 2','wood 4','concrete 5','r rust','sky low','R rust dark'}
 local labels={'k khaki','plaster 3','concrete 7'}
 for i=1,n do
  local w=2+r(3); local h=hMin+r(hMax-hMin+1); local c=cols[1+r(#cols)]
  p.rect(x,y-h,w,h,c); p.hl(x,y-h+2+r(math.max(1,h//3)),w,labels[1+r(#labels)])
  x=x+w
 end
 return x
end

-- A potted plant whose pot bottom is at y, centred on x.
-- kind: 'small' (sill plant), 'bush' (leafy), 'cactus', 'trail' (a pot for a vine)
function K.plant(p,x,y,kind,r)
 r=r or K.rng(x*7+y)
 local function pot(w,h,c1,c2,rim)
  p.rect(x-w//2,y-h,w,h,c1); p.rect(x+w//2-2,y-h,2,h,c2); p.hl(x-w//2-1,y-h,w+2,rim or c1)
 end
 if kind=='small' then
  pot(7,5,'rust iron 2','rust iron 1','r rust')
  p.oval(x-4,y-11,5,4,'leaf 3'); p.oval(x,y-12,5,4,'leaf 3'); p.oval(x-2,y-14,4,4,'leaf 4'); p.px(x-1,y-13,'leaf 2'); p.vl(x,y-9,4,'leaf 2')
 elseif kind=='cactus' then
  pot(8,5,'plaster 2','plaster 1','plaster 3')
  p.rect(x-1,y-13,3,8,'leaf 3'); p.vl(x-1,y-13,8,'leaf 4'); p.rect(x-4,y-10,2,2,'leaf 3'); p.rect(x-4,y-12,1,3,'leaf 3'); p.px(x,y-14,'neon pink')
 elseif kind=='bush' then
  pot(11,8,'rust iron 2','rust iron 1','r rust')
  p.oval(x-8,y-18,9,7,'leaf 2'); p.oval(x-1,y-20,9,8,'leaf 3'); p.oval(x-6,y-24,7,7,'leaf 3'); p.oval(x+1,y-26,6,6,'leaf 4')
  p.px(x-4,y-22,'leaf 4'); p.px(x+3,y-18,'leaf 4'); p.px(x-7,y-15,'leaf 1'); p.px(x+2,y-14,'leaf 1'); p.vl(x,y-13,5,'leaf 1')
 elseif kind=='trail' then
  pot(9,6,'concrete 5','concrete 4','concrete 6')
  p.oval(x-5,y-11,6,5,'leaf 3'); p.oval(x,y-12,6,5,'leaf 3'); p.px(x-3,y-10,'leaf 4'); p.px(x+2,y-11,'leaf 4')
 end
end
-- A vine wandering down from (x,y) for len rows, with leaf pairs.
function K.vine(p,x,y,len,r)
 r=r or K.rng(x+y)
 local xx=x
 for i=0,len-1 do
  p.px(xx,y+i,'leaf 2')
  if i%5==2 then local lx=(r(2)==0) and xx-2 or xx+1; p.rect(lx,y+i-1,2,2,'leaf 3'); p.px(lx,y+i-1,'leaf 4') end
  if r()<0.3 then xx=xx+(r(3)-1) end
 end
end

-- Rain over the box x0,y0..x1,y1 as thin slanted streaks that loop over 4
-- frames: phase is 0..3. Streaks fall by (-1,+3) a frame.
function K.rain(p,x0,y0,x1,y1,phase,seed,col,col2,density)
 local r=K.rng(seed or 3)
 local n=math.floor((x1-x0)*(density or 0.12))
 for i=1,n do
  local bx=x0+r(x1-x0); local by=y0-12+r(12); local bright=(r()<0.25)
  local c=bright and (col2 or col) or col
  for k=0,((y1-y0)//12)+1 do
   local x=bx-4*k-phase; local y=by+12*k+3*phase
   for j=0,3 do local sx=x-(j//2); local sy=y+j
    if sx>=x0 and sx<x1 and sy>=y0 and sy<y1 then p.px(sx,sy,c) end end
  end
 end
end

-- Capiz-shell lattice: cols x rows cells of 5x5 with 1 px muntins, from x,y.
-- tone(col,row) returns fill,shade,glint (or nil for a missing shell, transparent).
function K.capiz(p,x,y,cols,rows,tone)
 p.rect(x,y,cols*6+1,rows*6+1,'wood 2')
 for cy=0,rows-1 do for cx=0,cols-1 do
  local f,s,g=tone(cx,cy); local px,py=x+1+cx*6,y+1+cy*6
  if f==nil then p.rect(px,py,5,5,0)
  else p.rect(px,py,5,5,f); p.hl(px,py+4,5,s); p.vl(px+4,py,5,s); if g then p.px(px,py,g); p.px(px+1,py,g) end end
 end end
end

-- Shrinks a layer's cel to what is drawn (smaller file). Frame f (default 1).
function K.trim(s,layer,f)
 f=f or 1; local cel=layer:cel(f); if not cel then return end
 local b=cel.image:shrinkBounds(); if b.isEmpty then s:deleteCel(cel) return end
 if b.width==cel.image.width and b.height==cel.image.height then return end
 local im=Image(b.width,b.height,ColorMode.RGB); im:drawImage(cel.image,Point(-b.x,-b.y))
 local pos=Point(cel.position.x+b.x,cel.position.y+b.y)
 s:deleteCel(cel); s:newCel(layer,f,im,pos)
end

-- Makes the sprite n frames long (copies of frame 1), all dur seconds.
function K.frames(s,n,dur)
 while #s.frames>n do s:deleteFrame(#s.frames) end
 while #s.frames<n do s:newFrame(#s.frames) end
 for _,fr in ipairs(s.frames) do fr.duration=dur end
end

-- Finds a layer by name, or makes it with that user data just above `after`.
function K.layer(s,name,data,after)
 for _,l in ipairs(s.layers) do if l.name==name then return l end end
 local l=s:newLayer(); l.name=name; l.data=data or ''
 if after then l.stackIndex=after.stackIndex+1 end
 return l
end

-- A hidden note layer (never exported) carrying text in its user data.
function K.note(s,name,text)
 local l=K.layer(s,name,''); l.data=text; l.isVisible=false; return l
end

function K.save(s,path)
 for _,l in ipairs(s.layers) do if l.name:sub(1,1)=='_' then l.isVisible=false end end
 s:saveAs('art/'..path..'.aseprite')
 local flat=Image(s); flat:saveAs('art/_work/claude/'..path:gsub('/','-')..'.png')
 print('saved art/'..path..'.aseprite')
 -- A room's moving layers go to art/anim/<name>.aseprite, leaving its file one still frame
 -- (scripts/art/stills.lua).
 if path:match('^scenes/') or path=='hub' then
  dofile('scripts/art/stills.lua').split('art/'..path..'.aseprite', path:match('([^/]+)$'))
 end
end

-- ======================================================================
-- Shared interior pieces (scenes): the sky, the fogged city, doors, lights.

-- The night sky as horizontal bands with 2-px dithers, full width.
function K.sky(p,W)
 p.rect(0,0,W,62,'night'); p.dither(0,62,W,3,'night','sky high'); p.rect(0,65,W,13,'sky high')
 p.dither(0,78,W,3,'sky high','sky'); p.rect(0,81,W,11,'sky'); p.dither(0,92,W,3,'sky','sky low')
 p.rect(0,95,W,8,'sky low'); p.dither(0,103,W,4,'sky low','mist 4'); p.rect(0,107,W,163,'mist 4')
end
-- Fogged towers on the far layer between x0 and x1 standing on `base`.
function K.farCity(p,x0,x1,base,seed)
 K.skyline(p,{x0=x0,x1=x1,base=base,topMin=base-46,topMax=base-20,wMin=10,wMax=24,fill='mist 3',win='mist 5',winP=0.04,rng=K.rng(seed or 11),gap=2,cap=true,ant=true})
 K.skyline(p,{x0=x0+10,x1=x1,base=base+10,topMin=base-26,topMax=base-6,wMin=8,wMax=20,fill='mist 2',win='mist 4',winP=0.05,win2='sodium 1',win2P=0.02,rng=K.rng((seed or 11)+3),gap=3,cap=true})
end
-- The roofs next door on the mid layer: corrugated silhouettes, a tank, an antenna.
function K.nearRoofs(p,x0,x1,base,seed)
 local r=K.rng(seed or 5); local x=x0
 while x<x1 do local w=30+r(40); local top=base-20-r(26)
  p.rect(x,top,w,base-top,'mist 1'); p.hl(x,top,w,'mist 2'); for xx=x+2,x+w-2,4 do p.px(xx,top+1,'mist 2') end
  if r()<0.5 then p.rect(x+3+r(math.max(1,w-10)),base-6-r(8),3,4,'sodium 1') end
  if r()<0.4 then local tx=x+w-10; p.rect(tx,top-12,10,10,'mist 2'); p.hl(tx,top-12,10,'mist 3') end
  if r()<0.4 then local ax=x+4+r(math.max(1,w-8)); p.vl(ax,top-26,26,'mist 2'); p.hl(ax-3,top-20,7,'mist 2'); p.px(ax,top-27,'neon red') end
  x=x+w
 end
end
-- The exit at the left edge: the opening is cut by the canvas; EXIT plaque over it.
function K.exitLeft(p)
 p.rect(0,126,16,4,'wood 2'); p.hl(0,126,16,'wood 3'); p.rect(12,130,4,46,'wood 2'); p.vl(15,130,46,'wood 3')
 p.rect(0,130,12,46,'concrete 2'); p.rect(0,130,12,10,'concrete 1'); p.hl(0,158,10,'concrete 3'); p.hl(0,166,6,'concrete 3'); p.rect(0,160,3,16,'concrete 1')
 p.rect(2,133,3,3,'sodium 1'); p.px(3,134,'sodium 3')
 p.frame(0,114,19,10,'wood 3','wood 2'); p.text('EXIT',2,116,'sodium 4',5)
end
-- A sodium tube from x0 to x1 hung at y under a housing, chains to the ceiling.
function K.tube(p,x0,x1,y)
 p.rect(x0-2,y-2,x1-x0+4,2,'concrete 4'); p.rect(x0,y,x1-x0,2,'sodium 4'); p.hl(x0+2,y,x1-x0-4,'sodium 5')
 for yy=45,y-3,2 do p.px(x0+8,yy,'concrete 5'); p.px(x1-8,yy,'concrete 5') end
end
-- A hanging pendant lamp: cord from the ceiling, a cone shade, the bulb.
function K.pendant(p,x,y)
 p.vl(x,45,y-45,'concrete 1'); p.rect(x-6,y,13,3,'sodium 2'); p.rect(x-4,y-2,9,2,'sodium 1'); p.rect(x-7,y+3,15,1,'sodium 2'); p.px(x,y+4,'sodium 5'); p.hl(x-2,y+4,5,'sodium 4')
end
-- The pool a tube or lamp throws down a wall, solid then dithered out.
function K.litzone(p,cx,y0,y1,w0,w1,c,base)
 for y=y0,y1 do local t=(y-y0)/(y1-y0); local hw=math.floor(w0+(w1-w0)*t+0.5)
  if t<0.72 then p.hl(cx-hw,y,2*hw,c) elseif t<0.88 then p.dither(cx-hw,y,2*hw,1,c,base) else p.dither(cx-hw+4,y,2*hw-8,1,base,c) end
 end
end
-- A corrugated ceiling with a girder and sagging wires, y 45-58, full width.
function K.ceiling(p,W,base,rib,rib2)
 p.rect(0,45,W,3,base or 'concrete 2')
 for y=48,55 do local c=(y%4==0) and (rib or 'concrete 4') or ((y%4==1) and (rib2 or 'concrete 3') or (base or 'concrete 2')); p.hl(0,y,W,c) end
 p.rect(0,56,W,2,'concrete 4'); p.hl(0,58,W,'concrete 2'); for x=12,W,24 do p.px(x,57,'concrete 6') end
 for i,c in ipairs({'concrete 1','ink','wood 1'}) do local d=i-1
  for x=0,W,80 do p.line(x,49+d,x+40,54+d,c); p.line(x+40,54+d,x+80,49+d,c); p.px(x,48+d,'concrete 5') end
 end
end
-- A wall fan in its cage at cx,cy.
function K.fan(p,cx,cy)
 p.ring(cx,cy,12,'concrete 5'); p.ring(cx,cy,8,'concrete 4'); p.line(cx,cy,cx,cy-11,'concrete 6'); p.line(cx,cy,cx+9,cy+6,'concrete 6'); p.line(cx,cy,cx-9,cy+6,'concrete 6')
 p.oval(cx-3,cy-10,7,5,'concrete 5'); p.oval(cx+4,cy+2,6,6,'concrete 5'); p.oval(cx-10,cy+2,6,6,'concrete 5'); p.disc(cx,cy,2,'concrete 3'); p.px(cx-1,cy-1,'concrete 6')
 p.rect(cx-2,cy+12,4,6,'concrete 4'); p.rect(cx-6,cy+18,12,3,'concrete 5'); for y=cy+12,cy+26,2 do p.px(cx+11,y,'concrete 6') end
end
-- A ceiling fan hanging at cx with its hub at y.
function K.ceilingFan(p,cx,y)
 p.vl(cx,45,y-45,'concrete 4'); p.rect(cx-2,y-2,5,4,'concrete 5'); p.rect(cx-20,y+1,17,2,'concrete 6'); p.rect(cx+4,y+1,17,2,'concrete 6'); p.rect(cx-7,y+3,15,1,'concrete 5'); p.px(cx,y+4,'concrete 6')
end
-- A conduit run with elbows: a list of {x,y} corners.
function K.conduit(p,pts,c)
 for i=1,#pts-1 do p.line(pts[i][1],pts[i][2],pts[i+1][1],pts[i+1][2],c or 'concrete 5') end
 for i=2,#pts-1 do p.px(pts[i][1],pts[i][2],'concrete 6') end
end
function K.junction(p,x,y,led) p.frame(x,y,9,8,'concrete 4','concrete 3'); p.px(x+6,y+2,led or 'neon cyan') end
-- A plaque: a board with one line of 3x5 text, its top-left at x,y. Returns its width.
function K.plaque(p,x,y,text,c,edge,fill)
 local w=#text*4+3; p.frame(x,y,w,10,edge or 'wood 3',fill or 'wood 2'); p.text(text,x+2,y+2,c,5); return w
end
-- A lit box sign centred on cx with its top at y: the box only (letters go on `lights`).
function K.lightbox(p,cx,y,lines,size,edge,fill)
 local adv=(size==7) and 6 or 4; local lh=(size==7) and 9 or 7
 local w=0; for _,t in ipairs(lines) do w=math.max(w,#t*adv-1) end
 local bw,bh=w+10,#lines*lh+5; local x=cx-bw//2
 p.frame(x,y,bw,bh,edge or 'concrete 4',fill or 'night'); p.px(x+1,y+1,'concrete 6'); p.px(x+bw-2,y+1,'concrete 6'); p.px(x+1,y+bh-2,'concrete 6'); p.px(x+bw-2,y+bh-2,'concrete 6')
 return x,y,bw,bh
end
-- The letters of a lightbox (on the lights layer): same geometry, lit (with a dim ring) or dim.
function K.lightboxText(q,cx,y,lines,size,c,dim,on)
 local adv=(size==7) and 6 or 4; local lh=(size==7) and 9 or 7
 local ty=y+3
 for _,t in ipairs(lines) do local tw=#t*adv-1; local tx=cx-tw//2
  if on and dim then for dx=-1,1 do for dy=-1,1 do if dx~=0 or dy~=0 then q.text(t,tx+dx,ty+dy,dim,size) end end end end
  q.text(t,tx,ty,on and c or (dim or c),size); ty=ty+lh end
end
-- The jumpable crate on its platform slice (x, 32 wide, top face 186-196, front 196-214).
function K.crate(p,x,kind)
 if kind=='drinks' then
  p.rect(x,186,32,10,'r rust'); p.hl(x,186,32,'sodium 2'); for i=0,3 do p.rect(x+3+i*8,187,5,8,'leaf 2'); p.px(x+5+i*8,188,'leaf 4') end
  p.rect(x,196,32,18,'R rust dark'); p.rect(x+1,198,30,6,'r rust'); p.rect(x+1,207,30,6,'r rust'); p.vl(x,196,18,'r rust')
 else
  p.rect(x,186,32,10,'wood 4'); p.hl(x,186,32,'k khaki'); p.rect(x,196,32,18,'wood 3'); p.hl(x,201,32,'wood 2'); p.hl(x,207,32,'wood 2'); p.line(x+1,197,x+31,213,'wood 2'); p.line(x+31,197,x+1,213,'wood 2'); p.vl(x,196,18,'wood 2'); p.vl(x+31,186,28,'wood 2')
 end
end
-- A plastic stool, its seat top at y, centred on x.
function K.stool(p,x,y,c,dark) p.rect(x-6,y,13,3,c); p.hl(x-6,y,13,'sodium 3'); p.vl(x-5,y+3,11,dark); p.vl(x+5,y+3,11,dark); p.vl(x,y+3,11,dark) end
-- A stack of n plastic chairs, their feet at y, left edge x.
function K.chairs(p,x,y,n)
 for i=n-1,0,-1 do local cy=y-i*4
  p.rect(x+2,cy-14,12,3,'concrete 7'); p.rect(x+2,cy-11,12,2,'concrete 6'); p.vl(x+2,cy-9,9,'concrete 6'); p.vl(x+13,cy-9,9,'concrete 6'); p.rect(x+12,cy-22,3,9,'concrete 7'); p.vl(x+14,cy-22,9,'concrete 6')
 end
end
-- A framed cream board for a show: slice x,y,w,h; the frame sits outside the slice.
function K.board(p,x,y,w,h,edge,inner,paper)
 p.rect(x-3,y-3,w+6,h+6,edge or 'wood 3'); p.rect(x-2,y-2,w+4,h+4,inner or 'wood 2'); p.rect(x,y,w,h,paper or 'plaster 3')
 p.px(x-2,y-2,'sodium 4'); p.px(x+w+1,y-2,'sodium 4'); p.px(x-2,y+h+1,'sodium 4'); p.px(x+w+1,y+h+1,'sodium 4')
end
-- Breeze blocks: a row of hollow blocks from x,y, n long, 8 px square.
function K.breeze(p,x,y,n)
 for i=0,n-1 do local bx=x+i*8; p.rect(bx,y,8,8,'concrete 5'); p.rect(bx+2,y+2,4,4,'concrete 2'); p.px(bx+3,y+3,'concrete 4'); p.vl(bx,y,8,'concrete 6') end
end
-- Sachet strips hanging from y at x: n columns, each 3 wide with coloured packets.
function K.sachets(p,x,y,n,len,r)
 r=r or K.rng(x+y)
 local cols={'sodium 3','neon cyan dim','r rust','leaf 4','k khaki','neon pink','d denim','plaster 3'}
 for i=0,n-1 do local sx=x+i*5; p.vl(sx+1,y,len,'concrete 5')
  for k=0,(len-2)//5 do local c=cols[1+r(#cols)]; p.rect(sx,y+2+k*5,3,4,c); p.px(sx,y+2+k*5,'concrete 7') end
 end
end
return K
