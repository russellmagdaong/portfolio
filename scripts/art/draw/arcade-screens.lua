-- art/objects/arcade/*.aseprite: gives each cabinet's dark screen a small attract loop (8 frames in its
-- `idle` tag). Only the pixels inside the screen change; the cabinet, its lettering and its `base` slice
-- are left as they are.
--
--   "C:\aseprite\build\bin\aseprite.exe" -b --script scripts/art/draw/arcade-screens.lua
--
-- It only touches a file that still has ONE frame, so a cabinet that has been animated already (by this
-- script or by hand in Aseprite) is never drawn over. To redo one, delete its extra frames first.
local m=dofile('scripts/art/draw/common.lua')
local C=m.C
local N=8

local draw={}
-- NOVA, still being built: a planet with its moon going round, over a loading bar that fills
function draw.nova(p,x,y,w,h,f)
 local cx=x+w//2
 p.rect(cx-1,y+1,3,3,'holo'); p.rect(cx,y+2,1,1,'screen glow')
 local orbit={{-4,1},{-3,0},{0,-1},{3,0},{4,1},{3,3},{0,4},{-3,3}}; local o=orbit[f]
 p.rect(cx+o[1],y+1+o[2],1,1,'neon cyan')
 p.rect(x+2,y+h-4,w-4,3,'holo dim'); p.rect(x+3,y+h-3,w-6,1,'ink')
 p.rect(x+3,y+h-3,math.floor((w-6)*f/N+0.5),1,(f==N) and 'W white' or 'neon cyan')
end
-- ODIN, the dungeon crawler that teaches code: lines of code being typed, and the enemy they hit
function draw.odin(p,x,y,w,h,f)
 local len={{3,0,0},{6,0,0},{9,0,0},{9,4,0},{9,7,0},{9,7,3},{9,7,5},{9,7,5}}; local l=len[f]
 for i=1,3 do if l[i]>0 then p.rect(x+2,y+(i-1)*3+1,l[i],1,(i==2) and 'sodium 3' or 'sodium 4') end end
 if f%2==1 then local row=(l[3]>0) and 3 or ((l[2]>0) and 2 or 1); p.rect(x+3+l[row],y+(row-1)*3+1,1,1,'W white') end
 local hit=(f>=7)
 p.rect(x+w-7,y+3,5,5,hit and 'W white' or 'neon red dim'); p.rect(x+w-6,y+2,3,1,hit and 'W white' or 'neon red dim')
 if not hit then p.rect(x+w-6,y+4,1,1,'neon yellow'); p.rect(x+w-4,y+4,1,1,'neon yellow') end
 p.rect(x+w-7,y+h-1,5,1,'neon green dim'); p.rect(x+w-7,y+h-1,hit and 2 or 5,1,'neon green')
end
-- TAKO: the octopus swimming across, bubbles rising
function draw.tako(p,x,y,w,h,f)
 p.rect(x,y+h-1,w,1,'neon violet dim'); p.rect(x+3,y+h-2,2,1,'neon violet dim'); p.rect(x+w-6,y+h-2,3,1,'neon violet dim')
 local ox=x+2+(f-1)*2; local oy=y+2+(f%2)
 p.rect(ox+1,oy,3,1,'neon cyan'); p.rect(ox,oy+1,5,2,'neon cyan'); p.rect(ox+1,oy+1,1,1,'ink'); p.rect(ox+3,oy+1,1,1,'ink')
 if f%2==0 then p.rect(ox,oy+3,1,1,'neon cyan'); p.rect(ox+2,oy+3,1,1,'neon cyan'); p.rect(ox+4,oy+3,1,1,'neon cyan')
 else p.rect(ox+1,oy+3,1,1,'neon cyan'); p.rect(ox+3,oy+3,1,1,'neon cyan') end
 for i,b in ipairs({{w-4,0},{w-9,3},{5,5}}) do p.rect(x+b[1],y+h-3-((f+b[2])%7),1,1,'holo') end
end
-- Algebrawl: two fighters under their health bars, trading a hit
function draw.algebrawl(p,x,y,w,h,f)
 local lunge=(f==3 or f==4) and 4 or 0; local back=(f==6 or f==7) and 3 or 0
 local hpR=(f>=4) and 5 or 8; local hpL=(f>=7) and 6 or 8
 p.rect(x+1,y+1,8,1,'neon red dim'); p.rect(x+1,y+1,hpL,1,'neon green')
 p.rect(x+w-9,y+1,8,1,'neon red dim'); p.rect(x+w-1-hpR,y+1,hpR,1,'neon green')
 p.rect(x,y+h-1,w,1,'leaf 2')
 local lx=x+4+lunge; local rx=x+w-7-back
 p.rect(lx,y+4,3,5,(f==7) and 'W white' or 'sodium 4'); p.rect(lx,y+3,2,1,'sodium 5'); p.rect(lx+3,y+5,2,1,'sodium 5')
 p.rect(rx,y+4,3,5,(f==4) and 'W white' or 'neon cyan'); p.rect(rx+1,y+3,2,1,'screen glow'); p.rect(rx-2,y+5,2,1,'screen glow')
 if f==4 then p.rect(rx-2,y+3,1,1,'neon yellow'); p.rect(rx-1,y+6,1,1,'neon yellow') end
 if f==7 then p.rect(lx+4,y+4,1,1,'neon yellow'); p.rect(lx+3,y+7,1,1,'neon yellow') end
end

for _,id in ipairs({'nova','odin','tako','algebrawl'}) do
 local path='art/objects/arcade/'..id..'.aseprite'
 local s=app.open(path)
 if #s.frames>1 then print('  '..path..': already has '..#s.frames..' frames, left alone'); s:close()
 else
  local layer=s.layers[1]; local cel=layer:cel(1)
  -- the screen: the box of `night` pixels in the cabinet's upper half
  local x0,y0,x1,y1
  for y=0,cel.image.height//2+8 do for x=0,cel.image.width-1 do
   if cel.image:getPixel(x,y)==C['night'] then x0=math.min(x0 or x,x); x1=math.max(x1 or x,x); y0=math.min(y0 or y,y); y1=math.max(y1 or y,y) end
  end end
  assert(x0,path..': no screen found')
  local base=cel.image:clone(); local pos=cel.position
  for f=2,N do s:newEmptyFrame(f) end
  for f=1,N do
   local im=base:clone()
   draw[id](m.pen(im),x0,y0,x1-x0+1,y1-y0+1,f)
   local old=layer:cel(f); if old then s:deleteCel(old) end
   s:newCel(layer,f,im,pos); s.frames[f].duration=0.15
  end
  for _,t in ipairs(s.tags) do if t.name=='idle' then t.toFrame=s.frames[N] end end
  s:saveAs(path); s:close()
  print('  '..path..': screen '..(x1-x0+1)..'x'..(y1-y0+1)..', '..N..' frames')
 end
end
