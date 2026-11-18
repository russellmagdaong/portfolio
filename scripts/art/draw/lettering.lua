local m=dofile('scripts/art/draw/common.lua')
local s=Sprite(192,112,ColorMode.RGB);s:setPalette(Palette{fromFile='art/palette.gpl'});s.layers[1].name='alphabets';local p=m.pen(m.canvas(s,s.layers[1]))
p.rect(0,0,192,112,'night');p.text('PIXEL TOWN / LETTERING',7,6,'sodium 4',5)
local chars='ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-!?./:+'
for i=1,#chars do local n=i-1;p.text(chars:sub(i,i),8+(n%24)*7,20+math.floor(n/24)*10,'plaster 3',5) end
for i=1,26 do local n=i-1;p.text(string.char(64+i),8+(n%20)*9,53+math.floor(n/20)*13,'sodium 4',7) end
p.text('SARI-SARI / PASADA / TAMBAY',8,88,'neon cyan',5)
p.text('3X5 SMALL  5X7 LARGE',8,100,'concrete 6',5)
s:saveAs('art/lettering.aseprite');s:saveCopyAs('art/_work/codex/lettering.png')
