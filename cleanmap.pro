; -------------------------------------------------------------
; NAME:
; -------------------------------------------------------------
;       CLEANMAP
;
;       ver 2.1 - released march 2010    
;       author: John Carter (IAS) 
;
; -------------------------------------------------------------
; VERSION HISTORY:
; -------------------------------------------------------------
;     - v 2.1 (march 2010)
;       Revamped: faster execution
;                 new architecture
;
;     - v 2.0 (feb 2010)
;       Revamped
;
;     - Original version - jul 2009
;         
; -------------------------------------------------------------



FUNCTION CLEANMAP, input, FILTER=FILTER,PASS=N_PASS


input=reform(input)
input_size=size(input,/dimensions)
if n_elements(input_size) ne 2 then return,0
size_x=input_size(0)
size_y=input_size(1)
if n_elements(n_pass) eq 0 then n_pass=1
n_pass=fix(n_pass)
if n_pass lt 1 then n_pass=1
if n_elements(filter) eq 0 then filter=3

output=input>0.

mask=input>0.-min(input>0.)
mask=bytscl(input>0.)
wmask=where(mask gt 0.,count)
if count le 1 then return,0
mask(wmask)=1.

for pass=1,n_pass do begin
mask=reform(mask,size_x,size_y,1)
mask2=mask
mask2(indgen(size_x-2)+1,indgen(size_y-2)+1,*)=  $
  mask(indgen(size_x-2)+1,indgen(size_y-2)+1,*)+ $
  mask(indgen(size_x-2)+0,indgen(size_y-2)+1,*)+ $
  mask(indgen(size_x-2)+0,indgen(size_y-2)+2,*)+ $
  mask(indgen(size_x-2)+0,indgen(size_y-2)+0,*)+ $
  mask(indgen(size_x-2)+2,indgen(size_y-2)+0,*)+ $
  mask(indgen(size_x-2)+2,indgen(size_y-2)+1,*)+ $
  mask(indgen(size_x-2)+2,indgen(size_y-2)+2,*)
bad=where(mask2 le filter,count)
if count gt 0 then output(bad)=min(input>0.)
if count gt 0 then mask(bad)=0.

endfor



RETURN,OUTPUT

END
