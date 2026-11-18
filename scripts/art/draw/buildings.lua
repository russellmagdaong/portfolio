-- Six related but distinct barangay buildings. Existing frames/tags/base are kept.
local m=dofile('scripts/art/draw/common.lua')
return function(id)
 local s=m.open('map-objects/'..id);local W,H=s.width,s.height;local l=s.layers[1];local b=H-3
 local accents={home={'neon cyan','neon cyan dim'},arcade={'neon pink','neon pink dim'},store={'neon green','neon green dim'},school={'neon violet','neon violet dim'},['trophy-shop']={'neon yellow','neon yellow dim'},['post-office']={'neon cyan','neon cyan dim'}}
 local a=accents[id];local titles={home='BAHAY',arcade='LARO LAB',store='TINDA',school='ARALAN',['trophy-shop']='GAWAD',['post-office']='LIHAM'}
 for f=1,#s.frames do
  local im=m.canvas(s,l,f);local p=m.pen(im)
  local x=3;local y=(id=='school' and 18 or (id=='arcade' and 18 or 13));local w=W-8;local fh=b-y
  -- Thin right wall and warm main facade; upper-left light throughout the set.
  p.rect(x,y,w,fh,'plaster 2');p.rect(x+w,y+1,3,fh-1,'plaster 1');p.rect(x,y,2,fh,'plaster 3');p.rect(x,y+fh-3,w,3,'concrete 3');p.rect(x+1,b-1,w+2,1,'concrete 4')
  -- Roof from above: 1 across for 2 up on both receding edges.
  for row=0,9 do local shift=math.floor((9-row)/2);p.rect(x-1+shift,y-10+row,w+1,1,'rust iron 1') end
  for xx=x+4,x+w,5 do p.line(xx+4,y-10,xx,y-1,'rust iron 2') end
  p.line(x+4,y-10,x+w+3,y-10,'plaster 2');p.rect(x-1,y-1,w+4,2,'wood 2');p.rect(x-1,y-1,w+4,1,'rust iron 2')
  -- Shared door: 14 map-pixels tall, warm transom and one brass glint.
  local dx=math.floor(W/2)-4;local dy=b-15
  p.frame(dx,dy,10,14,'ink','sky high');p.rect(dx+1,dy+1,8,2,'sodium 3');p.rect(dx+7,dy+8,1,1,'g gold');p.rect(dx-1,b-1,13,1,'concrete 5')
  -- Invented shop names painted from the shared 3x5 alphabet.
  local title=titles[id];local tw=#title*4-1;local sy=id=='store' and 5 or (id=='trophy-shop' and y+1 or y+2)
  p.frame(math.floor((W-tw)/2)-2,sy,tw+4,8,a[2],'night');p.text(title,math.floor((W-tw)/2),sy+2,a[1],5)
  if id=='home' then
   -- Capiz windows, corrugated roof tank, tiny potted ledge.
   for _,wx in ipairs({6,W-17}) do p.frame(wx,y+13,11,10,'wood 2','sky');p.rect(wx+1,y+14,9,1,'sodium 3');p.rect(wx+5,y+14,1,8,'wood 4');p.rect(wx+1,y+18,9,1,'wood 4') end
   p.rect(34,1,10,4,'concrete 3');p.oval(33,0,12,3,'concrete 5');p.rect(34,5,2,3,'concrete 2');p.rect(42,5,2,3,'concrete 2');p.line(12,1,12,5,'concrete 5');p.line(10,1,14,1,'concrete 5');p.rect(7,b-5,5,4,'rust iron 2');p.rect(8,b-8,2,4,'leaf 3');p.rect(10,b-10,3,3,'leaf 4')
  elseif id=='arcade' then
   -- Deep arcade entrance, small cabinets behind the two windows.
   for _,wx in ipairs({7,W-19}) do p.frame(wx,y+12,12,13,'concrete 2','night');p.rect(wx+2,y+14,8,5,'sky');p.rect(wx+3,y+15,6,2,a[2]);p.rect(wx+2,y+20,8,2,'concrete 4');p.rect(wx+3,y+22,6,2,'D denim dark') end
   p.rect(dx-2,dy-2,14,1,'sodium 4');p.rect(5,3,22,3,'concrete 3');p.line(7,4,8,1,'concrete 5');p.line(8,1,13,1,'concrete 5');p.rect(44,5,6,3,'concrete 4');p.line(47,5,47,0,'concrete 4')
  elseif id=='store' then
   -- Striped shallow awning and shuttered goods window.
   for xx=3,W-4,4 do p.rect(xx,y+2,4,3,(xx%8==3) and 'rust iron 2' or 'plaster 3') end
   p.frame(5,y+6,14,10,'wood 2','night');for xx=7,16,3 do p.rect(xx,y+8,2,4,'g gold');p.rect(xx,y+13,1,2,'concrete 5') end
   p.rect(W-14,y+6,8,8,'wood 2');p.rect(W-13,y+7,6,5,'plaster 2');p.rect(W-12,y+8,4,1,'sodium 3')
  elseif id=='school' then
   -- Campus wings, capiz classroom windows and central roof clock.
   for _,wx in ipairs({7,19,48,60}) do p.frame(wx,y+13,10,15,'concrete 3','sky high');p.rect(wx+1,y+14,8,4,'sodium 3');p.rect(wx+4,y+14,1,12,'plaster 2');p.rect(wx+1,y+21,8,1,'plaster 2') end
   p.rect(32,4,16,8,'plaster 2');p.rect(31,3,18,2,'concrete 5');p.oval(37,5,6,6,'plaster 3');p.line(40,6,40,8,'wood 2');p.line(40,8,42,8,'wood 2');p.rect(4,b-5,22,2,'plaster 3');p.rect(54,b-5,20,2,'plaster 3');p.rect(6,b-8,18,3,'leaf 2');p.rect(56,b-8,16,3,'leaf 3');p.line(67,1,67,8,'concrete 5');p.rect(68,1,7,4,'rust iron 2')
  elseif id=='trophy-shop' then
   for _,wx in ipairs({6,W-18}) do p.frame(wx,y+12,11,11,'wood 2','night');p.rect(wx+1,y+21,9,1,'wood 4');p.oval(wx+3,y+14,5,4,'g gold');p.rect(wx+5,y+18,1,3,'g gold');p.rect(wx+3,y+20,5,1,'Q khaki shadow') end
   p.line(6,2,29,2,'concrete 5');for xx=7,25,6 do p.rect(xx,3,3,2,'rust iron 2');p.rect(xx+1,5,1,1,'rust iron 2') end
  else
   -- Neighbourhood post office: painted letter emblem, service window, mailbox.
   p.frame(6,y+12,11,10,'wood 2','sky');p.rect(7,y+13,9,2,'sodium 3');p.rect(7,y+19,9,2,'wood 4');p.rect(W-16,y+13,10,7,'plaster 3');p.line(W-16,y+13,W-11,y+17,'rust iron 2');p.line(W-7,y+13,W-11,y+17,'rust iron 2');p.frame(W-15,b-9,8,8,'concrete 2','D denim dark');p.rect(W-14,b-7,6,1,'sodium 4');p.rect(W-12,b-4,2,1,'concrete 5');p.line(12,0,12,3,'concrete 5');p.line(12,0,18,2,'concrete 5')
  end
  if id=='store' then p.frame(dx,dy,10,14,'ink','sky high');p.rect(dx+1,dy+1,8,2,'sodium 3');p.rect(dx+7,dy+8,1,1,'g gold') end
  -- Hover is a one-pixel warm silhouette rim, retaining every painted pixel.
  if f==2 then local copy=Image(im);for yy=0,H-1 do for xx=0,W-1 do
   if app.pixelColor.rgbaA(copy:getPixel(xx,yy))==0 then local near=false;for _,d in ipairs({{-1,0},{1,0},{0,-1},{0,1}}) do local X,Y=xx+d[1],yy+d[2];if X>=0 and Y>=0 and X<W and Y<H and app.pixelColor.rgbaA(copy:getPixel(X,Y))>0 then near=true end end;if near then im:drawPixel(xx,yy,m.C['sodium 4']) end end
  end end end
 end
 m.finish(s,'map-objects/'..id)
end
