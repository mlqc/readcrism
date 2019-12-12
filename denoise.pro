; -------------------------------------------------------------
; NAME:
; -------------------------------------------------------------
;       OCAT   -  "OMEGA and CRISM Analysis Tool" 
;
;       ver 2.0 - released feb 2010    
;       author: John Carter (IAS) 
;         
; -------------------------------------------------------------
; VERSION HISTORY:
; -------------------------------------------------------------
;     - v 2.0 (feb 2010)
;       Revamped
;
;     - Original version - 2009
;         
; -------------------------------------------------------------


FUNCTION DENOISE, input, SUPER=SUPER, yc1, yc2
if n_elements(input) lt 1 then return,0

input=reform(input)
input_size=size(input,/dimensions)

if n_elements(input_size) eq 1 then return,0
if n_elements(input_size) eq 2 then begin
    size_x=input_size(0)
    size_y=input_size(1)
    size_c=1
    input=reform(input,size_x,size_y,size_c)
endif
if n_elements(input_size) eq 3 then begin
    size_x=input_size(0)
    size_y=input_size(1)
    size_c=input_size(2)
endif

output=fltarr(size_x,size_y,size_c,/nozero)
output=reform(output,size_x,size_y,size_c)

if not keyword_set(SUPER) then begin
    if n_elements(yc1) eq 0 and n_elements(yc2) eq 0 then begin 
        print,'<> Select BOTTOM line on map'
        cursor, xc,yc1,/DEVICE,/DOWN
        print,yc1
        print,'<> Select TOP line on map'
        cursor, xc2,yc2,/DEVICE,/DOWN
        print,yc2
    endif
    yc1=fix(yc1)
    yc2=fix(yc2)
    if yc1 eq yc2 then begin
        yc2=size_y-10
        yc1=10
    endif

    y1=min([yc1,yc2])
    y2=max([yc1,yc2])
    for c=0,size_c-1 do begin
        slice=reform(input(*,*,c))
        med_slice=median(slice(*,y1:y2),dimension=2)
        for i=0,size_x-1 do slice(i,*)=slice(i,*)-med_slice(i)
        output(*,*,c)=slice
    endfor
    
endif

if keyword_set(SUPER) and n_elements(input_size) eq 2 then begin


;    seed= 1001L
;    tries=300
;    y1=fix(RANDOMU(seed,tries)*(size_y-1))
;    y2=fix(RANDOMU(seed,tries)*(size_y-1))
;    tmp_layer=fltarr(size_x,size_y,tries,/nozero)
;    tt=-1
;    for t=0,tries-1 do begin
;        tt=tt+1
;        y1t=min([y1(t),y2(t)])
;        y2t=max([y1(t),y2(t)])
;        if y1t eq y2t then continue
;        med=median(input(*,y1t:y2t),dimension=2)
;        med=reform(med,size_x,1)
;        tmp_layer(*,indgen(size_y),tt)=input(*,indgen(size_y))-med(*,indgen(size_y)/99999)
;    endfor
;    output=median(tmp_layer(*,*,0:tt),dimension=3)


 seed= 1001L
seed2=1002L	
    tries=100
    y1=fix(RANDOMU(seed,tries)*(size_y/2.-1))
	y2=y1	
    y2=fix(RANDOMU(seed2,tries)*(size_y/2.-1))+fix(size_y/2.)
  tmp_layer=fltarr(size_x,size_y,tries,/nozero)
tt=-1
    for t=0,tries-1 do begin
        tt=tt+1
       y1t=y1(t); y1t=min([y1(t),y2(t)])
       y2t=y2(t); y2t=max([y1(t),y2(t)])
   if abs(y1t-y2t) lt 10 then continue
 med=median(input(*,y1t:y2t),dimension=2)
 med=reform(med,size_x,1)
 tmp_layer(*,indgen(size_y),tt)=input(*,indgen(size_y))-med(*,indgen(size_y)/99999)
endfor
output=median(tmp_layer(*,*,0:tt),dimension=3)






endif



return, output
END
