-- Shared single-pixel primitives and the two canonical alphabets.
local M={}; local C={}
for line in io.lines('art/palette.gpl') do
 local r,g,b,n=line:match('^%s*(%d+)%s+(%d+)%s+(%d+)%s+(.+)$')
 if r then C[n]=Color{r=tonumber(r),g=tonumber(g),b=tonumber(b),a=255}.rgbaPixel end
end
M.C=C
M.small={A='010/101/111/101/101',B='110/101/110/101/110',C='011/100/100/100/011',D='110/101/101/101/110',E='111/100/110/100/111',F='111/100/110/100/100',G='011/100/101/101/011',H='101/101/111/101/101',I='111/010/010/010/111',J='001/001/001/101/010',K='101/101/110/101/101',L='100/100/100/100/111',M='101/111/111/101/101',N='101/111/111/111/101',O='010/101/101/101/010',P='110/101/110/100/100',Q='010/101/101/111/011',R='110/101/110/101/101',S='011/100/010/001/110',T='111/010/010/010/010',U='101/101/101/101/111',V='101/101/101/101/010',W='101/101/111/111/101',X='101/101/010/101/101',Y='101/101/010/010/010',Z='111/001/010/100/111',['0']='111/101/101/101/111',['1']='010/110/010/010/111',['2']='110/001/010/100/111',['3']='110/001/010/001/110',['4']='101/101/111/001/001',['5']='111/100/110/001/110',['6']='011/100/111/101/111',['7']='111/001/010/010/010',['8']='111/101/111/101/111',['9']='111/101/111/001/110',['-']='000/000/111/000/000',['!']='010/010/010/000/010',['?']='110/001/010/000/010',['.']='000/000/000/000/010',['/']='001/001/010/100/100',[':']='000/010/000/010/000',['+']='000/010/111/010/000'}
local big={'01110/11011/10001/11111/10001/10001/10001','11110/10001/10001/11110/10001/10001/11110','01111/10000/10000/10000/10000/10000/01111','11110/10001/10001/10001/10001/10001/11110','11111/10000/10000/11110/10000/10000/11111','11111/10000/10000/11110/10000/10000/10000','01111/10000/10000/10111/10001/10001/01110','10001/10001/10001/11111/10001/10001/10001','11111/00100/00100/00100/00100/00100/11111','00111/00010/00010/00010/10010/10010/01100','10001/10010/10100/11000/10100/10010/10001','10000/10000/10000/10000/10000/10000/11111','10001/11011/10101/10101/10001/10001/10001','10001/11001/11001/10101/10011/10011/10001','01110/10001/10001/10001/10001/10001/01110','11110/10001/10001/11110/10000/10000/10000','01110/10001/10001/10001/10101/10010/01101','11110/10001/10001/11110/10100/10010/10001','01111/10000/10000/01110/00001/00001/11110','11111/00100/00100/00100/00100/00100/00100','10001/10001/10001/10001/10001/10001/01110','10001/10001/10001/10001/01010/01010/00100','10001/10001/10001/10101/10101/11011/10001','10001/10001/01010/00100/01010/10001/10001','10001/10001/01010/00100/00100/00100/00100','11111/00001/00010/00100/01000/10000/11111'}
M.big={};for i,g in ipairs(big) do M.big[string.char(64+i)]=g end
function M.canvas(s,l,f)
 local im=Image(s.width,s.height,ColorMode.RGB)
 local old=l:cel(f or 1);if old then s:deleteCel(old) end
 local cel=s:newCel(l,f or 1,im,Point(0,0));return cel.image
end
function M.pen(im)
 local p={}
 function p.rect(x,y,w,h,c) c=C[c] or c;for yy=math.max(0,y),math.min(im.height-1,y+h-1) do for xx=math.max(0,x),math.min(im.width-1,x+w-1) do im:drawPixel(xx,yy,c) end end end
 function p.line(x,y,X,Y,c) local dx,dy=math.abs(X-x),math.abs(Y-y);local sx=x<X and 1 or -1;local sy=y<Y and 1 or -1;local e=dx-dy;while true do p.rect(x,y,1,1,c);if x==X and y==Y then break end;local z=e*2;if z>-dy then e=e-dy;x=x+sx end;if z<dx then e=e+dx;y=y+sy end end end
 function p.frame(x,y,w,h,edge,fill) p.rect(x,y,w,h,edge);p.rect(x+1,y+1,w-2,h-2,fill) end
 function p.oval(x,y,w,h,c) for yy=0,h-1 do for xx=0,w-1 do if ((xx+.5-w/2)/(w/2))^2+((yy+.5-h/2)/(h/2))^2<=1 then p.rect(x+xx,y+yy,1,1,c) end end end end
 function p.text(str,x,y,c,size) local font=size==7 and M.big or M.small;local advance=size==7 and 6 or 4;for ch in str:gmatch('.') do local glyph=font[ch];if glyph then local yy=0;for row in glyph:gmatch('[^/]+') do for xx=1,#row do if row:sub(xx,xx)=='1' then p.rect(x+xx-1,y+yy,1,1,c) end end;yy=yy+1 end end;x=x+advance end end
 function p.plant(x,y) p.rect(x-4,y-5,9,5,'rust iron 1');p.rect(x-5,y-6,11,2,'rust iron 2');p.line(x,y-7,x,y-20,'leaf 3');p.oval(x-7,y-18,7,4,'leaf 3');p.oval(x+1,y-23,7,5,'leaf 4');p.oval(x-5,y-26,5,7,'leaf 2');p.line(x,y-7,x+4,y-16,'leaf 4') end
 return p
end
function M.open(path) local s=app.open('art/'..path..'.aseprite');s:setPalette(Palette{fromFile='art/palette.gpl'});return s end
function M.finish(s,path)
 for _,l in ipairs(s.layers) do if l.name:sub(1,1)=='_' then l.isVisible=false end end
 s:saveAs('art/'..path..'.aseprite');s:saveCopyAs('art/_work/codex/'..path:gsub('/','-')..'.png')
end
return M

