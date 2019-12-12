; -------------------------------------------------------------
; NAME:
; -------------------------------------------------------------
;       DESPIKE
;
;       ver 3.0 - released dec 2011    
;       author: John Carter (IAS) 
;         
; -------------------------------------------------------------
; VERSION HISTORY:
; -------------------------------------------------------------
;     - v 3.0 (nov 2011)
;     Removed reduced lambda dimension option
;     Improved spike re-construction
;     Added block processing for memory limitations
;
;     - v 2.2 (jul 2010)
;     Improved efficiency > +300%
;     Added customizable parameters
;
;     - v 2.1 (apr 2010)
;     Does not overwrite input if 1D array
;     For memory considerations, 3D array is replaced by its despiked
;     version
;
;     - v 2.0 (feb 2010)
;     Revamped
;
;     - Original version - 2009
;
; ISSUE ! with N_blocks!!!! final output has wrong dimensions (SINFONI)
;
; -------------------------------------------------------------

FUNCTION DESPIKE, input, threshold, pass, step

n_blocks = 5


if n_elements(input) le 1 then return,0
input=reform(input)
input_size=size(input,/dimensions)
output=0
if n_elements(input_size) eq 1 then begin
    size_x=1
    size_y=1
    size_l=n_elements(input)
    input=reform(input,1,size_l,1)
endif
if n_elements(input_size) eq 2 then return,0
if n_elements(input_size) eq 3 then begin
size_x=input_size(0)
size_y=input_size(2)
size_l=input_size(1)
endif

; threshold settings
if n_elements(threshold) eq 0 then threshold = 0.02 ; 1 = 100%
threshold0=threshold
threshold=float(threshold)
;if threshold lt 0. then threshold=0.
if threshold gt 1. then threshold=1.

; pass settings
if n_elements(pass) eq 0 then pass=2 
pass0=pass
pass=fix(pass)
if pass lt 1 then pass=1

; step settings
if n_elements(step) eq 0 then step=0
step0=step
step=float(step)
if step lt 0 then step=0
;if step gt threshold then step=threshold
;if pass eq 1 then step=0

if n_elements(input_size) eq 1 then n_blocks=1
if n_elements(input_size) eq 3 then input=transpose(input(*,0:size_l-1,*),[1,0,2])

input=reform(input,float(size_l)*float(size_x)*float(size_y))



total_el=n_elements(input)
block_el=CEIL(total_el/n_blocks)

threshold1=threshold



 for blocks=0,n_blocks-1 do begin
 
   threshold=threshold1
  
   tmp_output=input(long(float(blocks)*block_el):min([long(float(blocks+1)*block_el)-1l,long(total_el)-1l]))

   count_bad=0l
   check_bad=where(finite(tmp_output) eq 0,count_bad)
   if count_bad gt 0 then tmp_output(check_bad)=0.
   
   for loop=0,pass-1 do begin
      
      medderivdat=smooth(tmp_output,10,/edge_truncate)
      derivdat3=abs(tmp_output-medderivdat)/abs(medderivdat)
      derivdat=deriv(tmp_output)
      
      w1=where(derivdat gt 0.,c1)
      w2=where(derivdat le 0.,c2)
      if c1 gt 0. then derivdat(w1)=2.
      if c2 gt 0. then derivdat(w2)=1.
      derivdat=byte(derivdat)
      derivdat2=shift(derivdat,-1)+shift(derivdat,+1)
      derivdat=0b
      test=where(derivdat3 gt threshold and derivdat2 eq 3, c3)
      derivdat2=0b & derivdat3=0b
      
      if c3 gt 0 then begin
         medderivdat=smooth(tmp_output,30,/edge_truncate)
         tmp_output(test)=medderivdat(test)
      endif
      
      medderivdat=0b & test=0b
      threshold=(threshold-step)>0.
   endfor
  
   output=[output,tmp_output]

   tmp_output=0   
endfor

output=output(1:*)

output=reform(output,size_l,size_x,size_y)
output=transpose(output,[1,0,2])

input=reform(input,size_l,size_x,size_y)
input=transpose(input,[1,0,2])


output=reform(output)

if n_elements(input_size) eq 3 then begin
   output(*,0:3,*)=input(*,0:3,*)
   output(*,size_l-10:size_l-1,*)=input(*,size_l-10:size_l-1,*)
endif
if n_elements(input_size) eq 1  then begin
   output(0:3)=input(0:3)
   output(size_l-10:size_l-1)=input(size_l-10:size_l-1)
endif

threshold=threshold0
pass=pass0
step=step0



return,output

end
