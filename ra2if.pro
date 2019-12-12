function ra2if,RA,SF,SD
  ;input: radiance cube, solar spectrum (SF), Solar distance (SD)
sizes=size(RA)
size_x=sizes(1)
size_y=sizes(3)
size_l=sizes(2)
AU=1
IoF=RA
yind=indgen(size_y)  
for i=0,size_x-1 do begin 
 FOR j=0,size_l-1 do IoF(i,j,yind)=!pi*RA(i,j,yind)*(SD/AU)^2/SF(i,j)
 endfor
 return,IoF
end