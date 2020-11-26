; -------------------------------------------------------------
; NAME:
; -------------------------------------------------------------
;       SLICEDESPIKE
;
;       ver 4.0 - after despike.pro
;       author: Lu Pan (Caltech) and John Carter (IAS)
;
; -------------------------------------------------------------
; VERSION HISTORY:
; -------------------------------------------------------------
;     - v 4.0 (dec 2014)
;     Deleted the n-blocks part for clarifications in dimension.
;     Now despiking only in the spectral dimention
;     [Added for-loops may slow down the process.]
;     
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

FUNCTION slicedespike, input, threshold, pass, step, bad_spectel,ratio
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

  threshold1=threshold
  output = input
  ; -----------------------------------
  ; FIND GOOD DATA
  ; Only perform despike on valid data 
  ; if skipped may have problem when replace with smoothed spectral data 
  ; -----------------------------------
min_x=0 & min_y=0 & max_x=0 & max_y=0

  if size_x gt 1 then begin
    ;Find CRISM no data values on the edge of file.
    for i=0,size_x/4,1 do begin
      check_min=where(finite(input(i,size_l/2,*)) eq 0 or input(i,size_l/2,*) le 0. or input(i,size_l/2,*) gt 2.,count_min)
      if count_min lt size_y/4 then break
    endfor
    min_x=i
    for i=size_x-1,3*size_x/4,-1 do begin
      check_max=where(finite(input(i,size_l/2,*)) eq 0 or input(i,size_l/2,*) le 0. or input(i,size_l/2,*) gt 2.,count_max)
      if count_max lt size_y/4 then break
    endfor
    max_x=i
    for i=0,size_y/4,1 do begin
      check_min=where(finite(input(*,size_l/2,i)) eq 0 or input(*,size_l/2,i) le 0. or input(*,size_l/2,i) gt 2.,count_min)
      if count_min lt size_x/4 then break
    endfor
    min_y=i
    for i=size_y-1,3*size_y/4,-1 do begin
      check_max=where(finite(input(*,size_l/2,i)) eq 0 or input(*,size_l/2,i) le 0. or input(*,size_l/2,i) gt 2.,count_max)
      if count_max lt size_x/4 then break
    endfor
    max_y=i
    check_min=0b & check_max=0b & count_min=0b &  count_max=0b
  endif

  ;Check off-channels for original image before ratio
  ;Skip if it's a ratioed cube.

 
  for i=min_y,max_y do begin

    threshold=threshold1

    slice_xl=input(min_x:max_x,0:size_l-1,i)
    slice_xl=reform(temporary(slice_xl))
;    count_bad=0l
;    check_bad=where(finite(slice_xl) eq 0,count_bad)
;    if count_bad gt 0 then slice_xl(check_bad)=0.    
    medderivdat=fltarr(max_x-min_x+1,size_l)
    derivdat3=medderivdat
    derivdat=medderivdat     
    for loop=0,pass-1 do begin
      for j=0,max_x-min_x do begin
      ;medderivdat=fltarr(max_x-min_x+1,size_l)
      ;derivdat=medderivdat
      medderivdat(j,*)=smooth(slice_xl(j,*),10,/edge_truncate,/NAN)
      derivdat(j,*)=deriv(slice_xl(j,*))
      endfor
      ;derivdat3=medderivdat
      derivdat3=abs(slice_xl-medderivdat)/abs(medderivdat)
      
      w1=where(derivdat gt 0.,c1)
      w2=where(derivdat le 0.,c2)
      if c1 gt 0. then derivdat(w1)=2.
      if c2 gt 0. then derivdat(w2)=1.
      derivdat=byte(derivdat)
      derivdat2 = fltarr(max_x-min_x+1,size_l)
      for j=0,max_x-min_x do begin
        derivdat2(j,*)=shift(derivdat(j,*),-1)+shift(derivdat(j,*),+1)
        test=where(derivdat3(j,*) gt threshold and derivdat2(j,*) eq 3, c3)
        if c3 gt 0 then begin
          medderivdat(j,*)=smooth(slice_xl(j,*),30,/edge_truncate,/NAN)
          slice_xl(j,test)=medderivdat(j,test)
         endif
      endfor
      medderivdat=0b & test=0b & derivdat2=0b & derivdat3=0b & derivdat = 0b
      threshold=(threshold-step)>0.
    endfor
      output(min_x:max_x,0:size_l-1,i)=slice_xl
      slice_xl=0
  endfor
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
