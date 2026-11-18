-- scenes/trophy-shop: AWARDS, the awards and certificates gallery. Redrawn 2026-11-17 on Russell's
-- word (every room its own walls, floor and furniture): navy wallpaper with a gold damask over dark
-- wood panelling, a coffered ceiling with a brass spotlight track, gilt frames for the five boards,
-- small trophies under glass on slim pedestals in the gaps between the frames, a herringbone parquet
-- with a red runner, velvet ropes in the foreground and a tall window onto the city at the far end,
-- a palm under it. Nothing stands out on the floor (no platform): he walks the whole room. Calm on
-- purpose, and no people or characters.
--
--   "C:\aseprite\build\bin\aseprite.exe" -b --script scripts/art/draw/trophy-shop.lua
--
-- Rewrites the whole room (and art/anim/trophy-shop.aseprite). Do not run it after hand edits to it.
-- Layers (back to front): sky 0.1, far 0.3, mid 0.6, rain 0.6 (animated, through the window), back,
-- lights (animated: the AWARDS sign), floor, props, glints (animated: a glint travelling over the
-- trophies; above props, or the glass would hide it), front 1.2 over. 12 x 100 ms.
local K=dofile('scripts/art/draw/kit.lua')
local m=K.m
local s=m.open('scenes/trophy-shop'); local W=s.width
while #s.frames>1 do s:deleteFrame(#s.frames) end
local L={}
for _,l in ipairs(s.layers) do L[l.name]=l end
L.rain=K.layer(s,'rain','speed=0.6',L.mid)
L.lights=K.layer(s,'lights','',L.back)
L.glints=K.layer(s,'glints','',L.props)
-- The big trophy on a plinth used to stand out on the floor (layer `pedestal`, sort=204, and a
-- `platform` slice). Russell wants the floor clear, so both go if the file still has them.
if L.pedestal then s:deleteLayer(L.pedestal); L.pedestal=nil end
for i=#s.slices,1,-1 do if s.slices[i].name=='platform' then s:deleteSlice(s.slices[i]) end end
local P={}
for _,n in ipairs({'sky','far','mid','back','floor','props','front'}) do P[n]=K.pen(m.canvas(s,L[n])) end

-- Slices: exit 0-12 · spawn 28 · the frames (show, paper): achievements 48-172 x 68-164,
--   certifications 192-288 x 100-164, ctfs 308-458 x 80-164, hackathons 478-594 x 94-164,
--   academic 614-678 x 104-164. The gilt frames are 10 px apart; GAPS are the middles of the gaps.
-- The window: x 700-744, y 72-150.
local FR={{48,68,124,96},{192,100,96,64},{308,80,150,84},{478,94,116,70},{614,104,64,60}}
local GAPS={182,298,468,604}
local WX0,WX1,WY0,WY1=700,744,72,150

---------------------------------------------------------------- sky / far / mid (through the window)
K.sky(P.sky,W)
K.farCity(P.far,560,758,150,31)
local p=P.mid
K.nearRoofs(p,600,758,170,33)

---------------------------------------------------------------- back
p=P.back
-- the coffered ceiling: dark wood beams and panels; a brass track with spotlight cans
p.rect(0,0,W,56,'wood 1')
for x=0,W,40 do p.rect(x,0,4,48,'wood 2'); p.vl(x,0,48,'wood 3') end
p.rect(0,18,W,3,'wood 2'); p.hl(0,18,W,'wood 3'); p.rect(0,40,W,8,'wood 2'); p.hl(0,40,W,'wood 3'); p.hl(0,47,W,'wood 1')
p.rect(0,48,W,6,'wood 3'); p.hl(0,48,W,'wood 4'); for x=2,W,6 do p.rect(x,52,3,2,'wood 2') end
p.hl(0,54,W,'g gold'); p.hl(0,55,W,'sodium 1')
p.rect(0,30,W,2,'sodium 1'); p.hl(0,30,W,'g gold')
for _,f in ipairs(FR) do local cx=f[1]+f[3]//2; for _,dx in ipairs({-f[3]//4,f[3]//4}) do local x=cx+dx
 p.vl(x,32,3,'sodium 1'); p.rect(x-2,35,5,4,'concrete 2'); p.hl(x-2,35,5,'concrete 4'); p.px(x,39,'sodium 5') end end
-- the wallpaper: navy with a gold damask diamond, lighter where the spots fall
p.rect(0,56,W,84,'D denim dark')
for _,f in ipairs(FR) do local cx=f[1]+f[3]//2
 for y=58,f[2]-4 do local t=(y-58)/math.max(1,f[2]-62); local hw=math.floor(f[3]//2*(0.5+0.6*t))
  if y%2==0 or t<0.5 then p.hl(cx-hw,y,2*hw,'d denim') else p.dither(cx-hw,y,2*hw,1,'d denim','D denim dark') end end
end
for y=62,136,12 do for x=((y//12)%2)*8,W,16 do
 p.px(x,y,'neon yellow dim'); p.px(x-1,y+1,'neon yellow dim'); p.px(x+1,y+1,'neon yellow dim'); p.px(x,y+2,'neon yellow dim') end end
p.rect(0,56,W,3,'wood 3'); p.hl(0,56,W,'wood 4'); p.hl(0,59,W,'g gold')
-- the wainscot: dark wood panels with raised frames, a cap rail and a skirting
p.rect(0,140,W,36,'wood 2'); p.rect(0,140,W,3,'wood 4'); p.hl(0,140,W,'k khaki'); p.hl(0,143,W,'wood 1')
for x=4,W,28 do p.frame(x,147,22,22,'wood 3','wood 2'); p.hl(x+1,148,20,'wood 4'); p.vl(x+21,148,20,'wood 1') end
p.rect(0,172,W,4,'wood 1'); p.hl(0,172,W,'wood 3')
-- AWARDS over the big frame (letters on `lights`)
K.lightbox(p,383,61,{'AWARDS'},7,'g gold','ink')
-- the gilt frames round the five boards, and a brass plate under each
for i,f in ipairs(FR) do local x,y,w,h=f[1],f[2],f[3],f[4]
 p.rect(x-5,y-5,w+10,h+10,'sodium 1'); p.rect(x-4,y-4,w+8,h+8,'g gold'); p.rect(x-2,y-2,w+4,h+4,'sodium 2'); p.rect(x-1,y-1,w+2,h+2,'wood 1')
 p.hl(x-4,y-4,w+8,'sodium 4'); p.vl(x-4,y-4,h+8,'sodium 4'); p.hl(x-4,y+h+3,w+8,'sodium 1'); p.vl(x+w+3,y-4,h+8,'sodium 1')
 for _,c in ipairs({{x-5,y-5},{x+w+1,y-5},{x-5,y+h+1},{x+w+1,y+h+1}}) do p.rect(c[1],c[2],4,4,'g gold'); p.px(c[1]+1,c[2]+1,'sodium 5') end
 p.rect(x,y,w,h,'plaster 3')
end
-- the window at the far end: a tall arched frame in dark wood, mullions
p.rect(WX0-5,WY0-12,WX1-WX0+10,WY1-WY0+18,'wood 2'); p.oval(WX0-5,WY0-22,WX1-WX0+10,22,'wood 2')
p.rect(WX0,WY0-4,WX1-WX0,WY1-WY0+4,0); p.oval(WX0,WY0-16,WX1-WX0,24,0)
p.vl(WX0+(WX1-WX0)//2,WY0-16,WY1-WY0+16,'wood 3'); p.hl(WX0,WY0+24,WX1-WX0,'wood 3'); p.hl(WX0,WY0+52,WX1-WX0,'wood 3')
p.rect(WX0-7,WY1,WX1-WX0+14,4,'wood 4'); p.hl(WX0-7,WY1,WX1-WX0+14,'k khaki')
p.rect(WX0-14,WY0-10,6,WY1-WY0+10,'neon red dim'); p.rect(WX1+8,WY0-10,6,WY1-WY0+10,'neon red dim')
for y=WY0-10,WY1,4 do p.px(WX0-12,y,'rust iron 1'); p.px(WX1+10,y,'rust iron 1') end
p.rect(WX0-16,WY0-13,WX1-WX0+32,3,'g gold')
K.exitLeft(p)

---------------------------------------------------------------- floor: herringbone parquet and a red runner
p=P.floor
p.rect(0,176,W,94,'wood 3')
for y=176,269,4 do for x=-8,W,8 do local o=((y//4)%2)*4
 p.line(x+o,y,x+o+3,y+3,'wood 2'); p.px(x+o+4,y,'wood 4') end end
p.rect(0,176,W,3,'wood 1'); p.dither(0,179,W,2,'wood 1','wood 3')
p.rect(0,198,W,18,'neon red dim'); p.hl(0,198,W,'g gold'); p.hl(0,215,W,'g gold'); p.hl(0,199,W,'rust iron 1'); p.hl(0,214,W,'rust iron 1')
for x=4,W,12 do p.px(x,206,'R rust dark'); p.px(x+6,207,'R rust dark') end

---------------------------------------------------------------- props
p=P.props
-- a trophy under a glass dome on a slim pedestal: its foot at y, centred on x. 9 px wide at the cap,
-- so it fits the 10-px gap between two frames without covering either frame's corner. Against the
-- wall (foot y 182; his feet stop at 184), so he is always in front of it.
local function pedestal(x,y,kind)
 p.rect(x-3,y-24,7,22,'wood 2'); p.vl(x-3,y-24,22,'wood 3'); p.vl(x+3,y-24,22,'wood 1'); p.rect(x-4,y-26,9,2,'wood 4'); p.rect(x-4,y-2,9,2,'wood 1')
 p.rect(x-1,y-14,3,2,'g gold'); p.px(x,y-13,'sodium 5')
 p.rect(x-3,y-44,7,18,'mist 2'); p.vl(x-3,y-44,18,'mist 4'); p.hl(x-3,y-44,7,'mist 5'); p.px(x-2,y-42,'concrete 7')
 if kind==1 then p.rect(x-1,y-38,3,4,'g gold'); p.px(x-2,y-38,'g gold'); p.px(x+2,y-38,'g gold'); p.vl(x,y-34,4,'g gold'); p.hl(x-1,y-30,3,'sodium 1'); p.px(x-1,y-37,'sodium 5')
 elseif kind==2 then p.disc(x,y-35,2,'concrete 6'); p.px(x-1,y-36,'concrete 7'); p.vl(x,y-32,3,'neon red'); p.hl(x-1,y-29,3,'wood 3')
 else p.rect(x-1,y-40,3,10,'g gold'); p.rect(x-2,y-40,5,2,'g gold'); p.px(x,y-42,'sodium 5'); p.hl(x-1,y-29,3,'wood 3') end
end
for i,x in ipairs(GAPS) do pedestal(x,182,(i%3)+1) end
-- a bench for looking at the frames (against the wall)
p.rect(520,168,44,4,'neon red dim'); p.hl(520,168,44,'neon red'); p.rect(520,172,44,2,'wood 2'); for _,x in ipairs({522,560}) do p.rect(x,174,3,8,'wood 1'); p.px(x,181,'g gold') end
-- a palm in a brass pot under the window, its fronds clear of the frames and the curtains
local PX=722
p.rect(PX-6,170,13,12,'g gold'); p.hl(PX-6,170,13,'sodium 4'); p.vl(PX+6,170,12,'sodium 1'); p.hl(PX-6,181,13,'sodium 1'); p.rect(PX-7,169,15,2,'sodium 2')
for _,fr in ipairs({{-14,-6,-16,0},{-9,-13,-13,-9},{-2,-17,-5,-16},{3,-17,6,-15},{9,-13,13,-8},{14,-6,16,0}}) do
 local mx,my,ex,ey=PX+fr[1],169+fr[2],PX+fr[3],169+fr[4]
 p.line(PX,168,mx,my,'leaf 3'); p.line(mx,my,ex,ey,'leaf 3'); p.line(PX,167,mx,my-1,'leaf 4')
end
p.vl(PX,160,9,'leaf 2')

---------------------------------------------------------------- front (1.2, over): the velvet rope
p=P.front
local posts={60,200,340,480,620}
for i,x in ipairs(posts) do
 p.rect(x-1,236,3,30,'g gold'); p.vl(x-1,236,30,'sodium 4'); p.disc(x,234,2,'g gold'); p.px(x-1,233,'sodium 5'); p.rect(x-4,266,9,4,'g gold')
 if i<#posts then local nx=posts[i+1]
  for xx=x+2,nx-2 do local t=(xx-x)/(nx-x); local sag=math.floor(math.sin(t*math.pi)*10); p.px(xx,238+sag,'neon red dim'); p.px(xx,239+sag,'neon red') end
 end
end

---------------------------------------------------------------- frames and the animated layers
for _,n in ipairs({'sky','far','mid','back','floor','props','front'}) do K.trim(s,L[n]) end
local FRAMES=12
K.frames(s,FRAMES,0.1)
for f=1,FRAMES do
 local q=K.pen(m.canvas(s,L.lights,f))
 K.lightboxText(q,383,61,{'AWARDS'},7,'neon violet','neon violet dim',f~=8)
 K.trim(s,L.lights,f)
 -- a glint travels over the trophies, 300 ms on each (on `glints`, in front of the glass)
 local gp=K.pen(m.canvas(s,L.glints,f))
 local gx=GAPS[1+(f-1)//3]; gp.px(gx-1,144,'W white'); gp.px(gx-2,145,'sodium 5'); gp.px(gx,143,'sodium 5')
 K.trim(s,L.glints,f)
 local w=K.pen(m.canvas(s,L.rain,f)); local phase=(f-1)%4
 K.rain(w,560,50,758,150,phase,13,'mist 4','mist 5',0.10)
 K.trim(s,L.rain,f)
end
K.note(s,'_lighting','Main light: brass spotlights on a track along the ceiling, two over each frame; their light falls on the navy wallpaper as lighter cones. Brass and gilt catch it (sodium glints). Accent: violet (the AWARDS sign). The tall window at the far end shows the city in the rain.')
K.save(s,'scenes/trophy-shop')
