; Name:
;     FLATTEN
;
; Version history:
;     - Ver 3.1
;       Add band threshold option for this
;     - Ver 3.0 (nov 2011)
;       Lower memory requirement
;       Improved processing time
;       Removed poor thermal correction option
;       Improved and unified cube flattening procedure
;
;     - Ver 2.2 (jul 2010)
;       Improved multilinear algorithm
;       Improved processing time
;
;     - Original version - march 2010
;
; Author:
;     John Carter (IAS)
;     Lu Pan (Caltech)
; Purpose:
;     Removes continuum and flattens hyperspectral cubes
;
; Input:
;     input:  a radiance hyperspectral cube
;     wvlc :  2D wavelength array
;
; Output:
;     output: flattened  hyperspectral cube
;
; Optional keyword:
;     /FLATTEN           : neutral mineralogy subtraction
;     /LINEAR            : linear continuum removal
;     /MLINEAR           : multi (curve) continnum removal
;     /BANDTHRES         : remove neutral mineralogy with band threshold
;
; Calling sequence: 
;     IDL> FLATTEN,wvlc,input,output,bad_spectel,[,/FLATTEN,/LINEAR,/MLINEAR,/BANDTHRES])
;


PRO FLATTEN, wvlc, input, output,bad_spectel,MLINEAR=MLINEAR, LINEAR=LINEAR, FLATTEN=FLATTEN, BANDTHRES=BANDTHRES

  ; verify data
  if n_elements(input) le 1 then goto,finish
  input=reform(input)
  input_size=size(input,/dimension)
  if n_elements(input_size) ne 3 then goto,finish
  size_x=input_size(0)
  size_l=input_size(1)
  size_y=input_size(2)
  size_wvl=size(wvlc,/dimensions)
  if n_elements(size_wvl) ne 2 then goto,finish
  if size_wvl(0) ne size_x then goto,finish
  if size_wvl(1) ne size_l then goto,finish
  
  output=fltarr(size_x,size_l,size_y,/nozero)
  
  if keyword_set(FLATTEN) then begin
  
    ; linear continuum ajustement (tie points at 1.76 and 2.14 um)
    tmp=min(abs(wvlc(size_x/2,*)-1.70),wpos1)
    tmp=min(abs(wvlc(size_x/2,*)-1.82),wpos2)
    tmp=min(abs(wvlc(size_x/2,*)-2.12),wpos3)
    tmp=min(abs(wvlc(size_x/2,*)-2.165),wpos4)
    slicea=median(input(*,wpos1:wpos2,*),dim=2)
    sliceb=median(input(*,wpos3:wpos4,*),dim=2)
    slope=(slicea-sliceb)/(1.76-2.1425)
    offset1=slicea-slope*1.76
    offset2=sliceb-slope*2.1425
    offset=(offset1+offset2)/2.
    offset1=0b & offset2=0b & slicea=0b & sliceb=0b
    
    ; remove linear continuum
    iy=indgen(size_y)
    wvlctemp=reform(wvlc,size_x,size_l,1)
    for l=0,size_l-1 do output(*,l,iy)=input(*,l,iy)/(offset+slope*wvlctemp(*,l,iy*0)) ;
    
    ; flatten cube : old method
    il=indgen(size_l)
    med_col1=MEDIAN(output(*,*,10:size_y/3.),dimension=3)
    med_col2=MEDIAN(output(*,*,size_y/3.+1:2.*size_y/3.),dimension=3)
    med_col3=MEDIAN(output(*,*,2.*size_y/3.+1:size_y-11),dimension=3)
    med_col=(med_col1*0.3+med_col2*0.4+med_col3*0.3)
    
    ; temporary over-ride :
    ;   med_col=MEDIAN(output(*,*,120:124),dimension=3)
    
    
    med_col=reform(med_col,size_x,size_l,1)
    med_col1=0b & med_col2=0b &  med_col3=0b
    
    ;  ; flatten cube : alternate method
    ;  iterations=10 ; set > 5, more => slower but better accuracy
    ;  randy=fix(randomu(seed,iterations)*(size_y-20.))+10
    ;  randyw=randy & randyw(*)=150.
    ;  randy1=(randy-fix(randyw/2.))>10<(size_y-11)
    ;  randy2=(randy+fix(randyw/2.))>10<(size_y-11)
    ;  med_colrand=fltarr(size_x,size_l,iterations)
    ;  for i=0,iterations-1 do med_colrand(*,*,i)=MEDIAN(output(*,*,randy1(i):randy2(i)),dimension=3)
    ;  med_col=reform(MEDIAN(med_colrand,dimension=3),size_x,size_l,1)
    
    
    for l=0,size_l-1 do output(*,l,iy)=output(*,l,iy)/med_col(*,l,iy*0)
    
    ; remove linear continuum on flattened cube
    slicea=median(output(*,wpos1:wpos2,*),dim=2)
    sliceb=median(output(*,wpos3:wpos4,*),dim=2)
    slope=(slicea-sliceb)/(1.76-2.1425)
    offset1=slicea-slope*1.76
    offset2=sliceb-slope*2.1425
    offset=(offset1+offset2)/2.
    offset1=0b & offset2=0b & slicea=0b & sliceb=0b
    for l=0,size_l-1 do output(*,l,iy)=output(*,l,iy)/(offset+slope*wvlctemp(*,l,iy*0)) ;
    
  endif
  
  
  if keyword_set(LINEAR) then begin
  
    ; remove linear continuum
    iy=indgen(size_y)
    wvlctemp=reform(wvlc,size_x,size_l,1)
    tmp=min(abs(wvlc(size_x/2,*)-1.70),wpos1)
    tmp=min(abs(wvlc(size_x/2,*)-1.82),wpos2)
    tmp=min(abs(wvlc(size_x/2,*)-2.12),wpos3)
    tmp=min(abs(wvlc(size_x/2,*)-2.165),wpos4)
    slicea=median(input(*,wpos1:wpos2,*),dim=2)
    sliceb=median(input(*,wpos3:wpos4,*),dim=2)
    slope=(slicea-sliceb)/(1.76-2.1425)
    offset1=slicea-slope*1.76
    offset2=sliceb-slope*2.1425
    offset=(offset1+offset2)/2.
    offset1=0b & offset2=0b & slicea=0b & sliceb=0b
    for l=0,size_l-1 do output(*,l,iy)=input(*,l,iy)/(offset+slope*wvlctemp(*,l,iy*0)) ;
    
  endif
  
  if keyword_set(MLINEAR) then begin
  
    ; set smooth width for curve fitting
    smooth_width=25 ;  <!> always keep >14 <!>
    
    ; avoid spurrious spectels at spectral boundaries
    padder1=fltarr(size_x,smooth_width/2,size_y,/nozero)
    padder2=padder1
    pw=indgen(smooth_width/2)
    tmp=min(abs(wvlc(size_x/2,*)-2.55),pad1)
    tmp=min(abs(wvlc(size_x/2,*)-2.65),pad2)
    tmp=reform(median(input[*,pad1:pad2,*],dimension=2),size_x,1,size_y)
    padder2(*,pw,*)=tmp(*,pw*0,*)
    tmp=min(abs(wvlc(size_x/2,*)-1.03),pad1)
    tmp=min(abs(wvlc(size_x/2,*)-1.13),pad2)
    tmp=reform(median(input[*,pad1:pad2,*],dimension=2),size_x,1,size_y)
    padder1(*,pw,*)=tmp(*,pw*0,*)
    
    
    ; define wavelengths on which to tie points
    tie_points=[1.025,1.125,1.23,1.325,1.45,1.575,1.725,1.845,2.125,2.225,2.275,2.49,2.61]
    
    ; build tie points
    npoints=n_elements(tie_points)
    wvc=reform(wvlc(size_x/2,*))
    tie_points_bins=fix(tie_points)
    for p=0,npoints-1 do begin
      tmp=min(abs(wvc-tie_points(p)),ctmp)
      tie_points_bins(p)=ctmp
    endfor
    tmp=where(wvc gt 2.0 and wvc lt 2.05,wvl_res)
    wvl_res=max([floor((wvl_res-1.)/2.),1])
    tie_points_arrays=intarr(npoints,2*wvl_res+1)
    for p=0,npoints-1 do tie_points_arrays(p,*)=indgen(2*wvl_res+1)+tie_points_bins(p)-(wvl_res)
    tie_points_arrays=tie_points_arrays>0<(size_l-1)
    tie_points_median=fltarr(size_x,npoints,size_y,/nozero)
    for p=0,npoints-1 do tie_points_median(*,p,*)=median(input(*,tie_points_arrays(p,*),*),dimension=2)
    wi=indgen(tie_points_bins(npoints-1)-tie_points_bins(0)+1)+tie_points_bins(0)
    interp_wvl=interpol(findgen(npoints),tie_points_bins,wi)
    
    ; build curve continnum adjustment
    output(*,tie_points_bins(0):tie_points_bins(npoints-1),*)=interpolate(tie_points_median,findgen(size_x),interp_wvl,findgen(size_y),/grid)
    output(*,0:max([tie_points_bins(0),0]),*)=1.
    output(*,min([tie_points_bins(npoints-1),size_l-1]):size_l-1,*)=1.
    
    ; deal with border effects
    tmp=min(abs(wvlc(size_x/2,*)-1.05),wpos1)
    tmp=min(abs(wvlc(size_x/2,*)-2.60),wpos2)
    output=[[padder1],[output(*,wpos1:wpos2,*)],[padder2]]
    output=smooth(output,[1,smooth_width,1],/NAN,/EDGE_TRUNCATE)
    output=output(*,smooth_width/2-wpos1:*,*)
    output=output(*,0:wpos2+smooth_width/2-1,*)
    output=[[output],[make_array(size_x,size_l-wpos2-smooth_width/2,size_y,value=1.)]]
    
    output=input/output
    
  endif
  
  if keyword_set(BANDTHRES) then begin
    crismcube=0b
    namecube=''
    ;   ; linear continuum ajustement (tie points at 1.76 and 2.14 um)
    tmp=min(abs(wvlc(size_x/2,*)-1.70),wpos1)
    tmp=min(abs(wvlc(size_x/2,*)-1.82),wpos2)
    tmp=min(abs(wvlc(size_x/2,*)-2.12),wpos3)
    tmp=min(abs(wvlc(size_x/2,*)-2.165),wpos4)
    iy=indgen(size_y)
    wvlctemp=reform(wvlc,size_x,size_l,1)
    
    ;FLATTEN CUBE  : NEW METHOD WITH BAND THRESHOLD
    ;calculate ALL the parameters first
    CRITERIA,wvlc,input,crismcube,namecube,bad_spectel,/CRISM
    ;ENVI_WRITE_ENVI_FILE, crismcube, out_name='bandmap4flat.img',interleave=0,Wavelength_units=0L
    
    ;bandname=['BD19','BDKAO','BDAL','BDFE','BDMG','BDPSUL','BDPRE','BDMSUL','BDOP','OLIVINE','PYROXENE','PLAGEOCLASE','BDEPI','BDCARB']
    paramselect=[0,1,2,3,5,7,8,9,10,13]
    bpix=intarr(size_x,size_y)
    bpix(*,*) = 1
    ;for each band parameter, find a threshold and flag boring pixels.
    for k=0,n_elements(paramselect)-1 do begin
      bd = reform(crismcube(*,*,paramselect(k)))
      threshold = median(bd(32:size_x-1,15:size_y-16))+1.5*STDDEV(bd(32:size_x-1,15:size_y-16),/NAN)
      bdmask_tmp = bd lt threshold
      bpix = bdmask_tmp*bpix
    endfor
    
    boringcube=fltarr(size_x,size_l,size_y)
    
    for l=0,size_l-1 do begin
      boringcube(*,l,*) = bpix * input(*,l,*)
    endfor
    med_col=fltarr(size_x,size_l)
    column = fltarr(size_x,size_l);
    
    for j=0,size_x-1 do begin
      for l=0,size_l-1 do begin 
        ;    ******** Use the median of all the boring pixels in the column.***************************
        check = where(boringcube(j,l,*) ne 0, count)
        if n_elements(check) eq 1 then begin
          if check eq -1 then med_col(j,l) = median(input(j,l,*),dimension=3) else med_col(j,l) = input(j,l,check)
        endif else begin
          med_col(j,l) = median(input(j,l,check),dimension=3)
        endelse
      endfor
    endfor
    ;save,file='bpix_medcol.sav', bpix,med_col,boringcube
    
    for l=0,size_l-1 do output(*,l,iy)=input(*,l,iy)/med_col(*,l,iy*0)
    
    ; remove linear continuum on flattened cube
    slicea=median(output(*,wpos1:wpos2,*),dim=2)
    sliceb=median(output(*,wpos3:wpos4,*),dim=2)
    slope=(slicea-sliceb)/(1.76-2.1425)
    offset1=slicea-slope*1.76
    offset2=sliceb-slope*2.1425
    offset=(offset1+offset2)/2.
    offset1=0b & offset2=0b & slicea=0b & sliceb=0b
    for l=0,size_l-1 do output(*,l,iy)=output(*,l,iy)/(offset+slope*wvlctemp(*,l,iy*0)) ;
    
  endif
  
  
  
  finish:
  
END