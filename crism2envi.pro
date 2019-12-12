; NAME:     crism2envi
;
; PURPOSE:
;     Restore a saved cube file from readcrism.pro procedure and write into an ENVI readable format
;     ENVI event handler routine to read in CRISM PDS files
;     (EDRs, TRRs, RTR, MRR)
;     and convert them to ENVI .img files in appropriate
;     format with necessary hdr info.
;

; CALLING SEQUENCE:
;     (need to specify crism data path before running)
;     crism2envi, 'crismlist.sav'
;
; INPUTS:
;    filename: data file name (with path)
;    keywords: string array containing the list of keyword
;
; OUTPUTS:
;    save the 3 image files as standard .img file and write ENVI header information at CRISM_SAV_PATH
;    
; NOTES:
; --program first checks for label file, if not found, '-1' is returned
; --CAT will prompt to ask if it could re-write the original ENVI header file. click "Yes"
;
; CREATED: August 2014
;      BY: L. Pan
;      
; Updated: Jan 2017
;   changed default rgb maps into regular crism combination
;   changed flattened cube name into "_ratioed_cube"
;   changed band names into more intuitive description with "namecube"
;
; Updated: Oct 2018
;    Added write CAT header based on original file label file
;    for consistency with ENVI CAT software
;    The CRISM_DATA_PATH will be restored from "mypaths.sav", so the script can be run in the same directory.

pro crism2envi,crism
  cd,'D:\IDL_routines\readcrism\readcrism2017'
  restore,'mypaths.sav'
  plat=!VERSION.OS_FAMILY
  if (strupcase(plat) eq 'UNIX') then begin
    plat='unix'
    slash='/'
    out_byte_order=1
  endif else begin
    plat='win'
    slash='\'
    out_byte_order=0
  endelse
  ID = strmid(crism,0,11)
  cd,crism_sav_path
  restore, crism
  
  ID = strmid(crism,0,11)  
  ; -----------------------------------
  ;find the label file with all PDS information:
  ; -----------------------------------
  
  seek_crism=file_search(crism_data_path+slash+ID+slash+ID+'*0*_IF*L_TRR3.LBL',count=count)
  if count eq 0 then begin
     seek_crism = file_search(crism_data_path+slash+ID+slash+ID+'*0*_IF*L_TRR3.lbl',count=count)
  endif
  if count eq 0 then begin
    seek_crism = file_search(crism_data_path+slash+strlowcase(ID+'*0*_IF*L_TRR3.lbl'),count=count)
  endif
  print,"Found data file label: "+seek_crism
  if count eq 0 then return ; goto,finish
  data_lbl_file=seek_crism(0)
  
  ; -----------------------------------
  ; READ DATA LABEL
  ; -----------------------------------
  
  print,'<> Reading auxiliary files'
  ;Here we find the related keywords in the data files.
  lblvalues=''
  keywords=['RECORD_BYTES','FILE_RECORDS','LINES','LINE_SAMPLES','BANDS','SOLAR_LONGITUDE', $
    'MRO:WAVELENGTH_FILE_NAME','SOLAR_DISTANCE', 'MRO:SENSOR_ID', 'MRO:WAVELENGTH_FILTER', $
    'PIXEL_AVERAGING_WIDTH','START_TIME','SPACECRAFT_CLOCK_START_COUNT','PRODUCT_ID', $
    'MRO:DETECTOR_TEMPERATURE','MRO:OPTICAL_BENCH_TEMPERATURE','MRO:SPECTROMETER_HOUSING_TEMP']
  
  READ_CRISM_LBL,STRCOMPRESS(data_lbl_file),keywords,lblvalues
  lblvalues=strtrim(lblvalues,2)
  ;size_y=fix(lblvalues(2));LINES
  ;size_x=fix(lblvalues(3));LINE_SAMPLES
  ;size_l=fix(lblvalues(4));BANDS
  ls=float(lblvalues(5));SOLAR_LONGITUDE
  wvl_file=strtrim(string(strsplit(reform(lblvalues(6)),'"',/EXTRACT)),2);WAVELENGTH FILE
  channel=string(strsplit(reform(lblvalues(8)),'"',/EXTRACT)) ;SENSOR ID
  wvlfilter=string(strsplit(reform(lblvalues(9)),'"',/EXTRACT)); WAVELENGTH FILTER
  binning=fix(lblvalues(10));PIXEL_AVERAGING_WIDTH
  if binning eq 1 then binmode='0'
  if binning eq 2 then binmode='1'
  if binning eq 5 then binmode='2'
  if binning eq 10 then binmode='3'
  start_time = string(strsplit(reform(lblvalues(11)),'"',/EXTRACT)) ;START_TIME
  sc_clock=string(lblvalues(12)) ;SPACECRAFT_CLOCK_START_COUNT

  file_name=strtrim(string(strsplit(reform(lblvalues(13)),'"',/EXTRACT)),2);TRR3 file name
  obs_name=strtrim(string((strsplit(file_name,'_',/extract))[0]),2); 'FRT00018AEF'
  crism_detector_temp = float(lblvalues(14));MRO:DETECTOR_TEMPERATURE
  crism_bench_temp = float(lblvalues(15));MRO:OPTICAL_BENCH_TEMPERATURE
  crism_housing_temp = float(lblvalues(16));MRO:SPECTROMETER_HOUSING_TEMP
 
  obs_type=strmid(obs_name,0,3)
   
  ; -----------------------------------
  ;Find crism cube file, wavelength file
  ;for crism full resolution targeted tiles
  ; -----------------------------------


  crism_size=size(ifdat_corr,/dimensions)
  if n_elements(crism_size) eq 1 then return
  if n_elements(crism_size) eq 2 then return
  if n_elements(crism_size) eq 3 then begin
    size_x=crism_size(0)
    size_y=crism_size(2)
    size_l=crism_size(1)
  endif
  params_size = size(crismcube,/dimensions)
  band_num = params_size(2)
  
  print,''
  print,'   . Reading file :',crism
  print,''
  print,'   . Cube sizes  (X, L, Y)',size_x,size_l,size_y
  print,'   . Latitude      (deg N), . Longitude     (deg E)',mean(infocube(*,*,1)), mean(infocube(*,*,0))
  print,'   . Solar incidence (deg)',min(infocube(*,*,3)),max(infocube(*,*,3))
  print,'   . Solar emergence (deg)',min(infocube(*,*,4)),max(infocube(*,*,4))
  print,'   . Altitude MOLA     (m)',mean(infocube(*,*,2))
  print,''

  ;find where the non zero values in wavelength is.
  if n_elements(meanwvl) eq 0 then begin
    meanwvl=fltarr(size_l)
    for i=0,size_l-1 do begin
      if size_x lt 100 then begin
        print,'Bad data: wvlc file less than 100 rows'
        return
        endif
        if size_x eq 510 then sweetspot=270 else sweetspot=size_x-101
        sweetspot = sweetspot+indgen(100)
        flag = intarr(100)
       for k=0,100-1 do begin
        if wvlc(sweetspot(k),i) eq 0 then flag(k)= 0 else flag(k)=1
       endfor
       meanwvl(i) = total(wvlc(sweetspot(*),i)*flag)/total(flag)
    endfor
  endif
  
  ;--------------------------
  ;change NAN into 65535 again.
  ;--------------------------
  print,'Formatting sample detector with NAN into 65535...'
  for i=0,size_y-1 do begin
    for l=0,size_l-1 do begin
      check_nan = where(finite(ifdat_corr(*,l,i),/NAN))
      ifdat_corr(check_nan,l,i) = 65535
      ifdat_corr_dsp(check_nan,l,i) = 65535
      if (l eq size_l/3) then begin
        for b = 0,band_num-1 do begin
          crismcube(check_nan,i,b) = 65535
        endfor
      endif
    endfor
  endfor

  ; If writing files, output filenames are forced to convention
  ; and checked for redundancy:
  ;Write into ENVI readable format
;
  print, "Writing IF envi file with label information..."
  if (size_l le 60) then begin
    bands = [42,16,3]
  endif else begin
    if (size_l le 155) then bands = [129,32,3] else bands =[232,77,12]
  endelse
  
  ENVI_WRITE_ENVI_FILE, ifdat_corr, out_name=CRISM_SAV_PATH+slash+ID+'_IF.img',DEF_BANDS=bands,interleave=1,Wavelength_units=0L, WL=meanwvl,zplot_titles='CRISM Spectral Plot'
  header1 = WRITE_CAT_HEADER(FNAME=CRISM_SAV_PATH+slash+ID+'_IF.img', NS=size_x, NL=size_y, NB=size_l, $                  ; required
  DATA_TYPE=4, INTERLEAVE=1, OFFSET=0, CLOSEFILE=closefile, OVERWRITE=overwrite, R_FID=fid,  $        ; operational
  BBL=bbl, BNAMES=bnames, CLASS_NAMES=class_names, $   ; optional ENVI                   ; ENVI
  DATA_GAINS=data_gains, DATA_IGNORE_VALUE=65535, $
  DATA_OFFSETS=0, DEF_BANDS=bands, DEF_STRETCH=def_stretch, $
  DESCRIP=descrip, FWHM=fwhm, GEO_POINTS=geo_points, $
  LOOKUP=lookup, MAP_INFO=map_info, NUM_CLASSES=num_classes, $
  PIXEL_SIZE=pixel_size, REFLECTANCE_SCALE_FACTOR=reflectance_scale_factor, $
  SPEC_NAMES=spec_names, UNITS=units, $
  WAVELENGTH_UNIT=0L, WL=meanwvl, XSTART=xstart, YSTART=ystart, $
  ZPLOT_AVERAGE=zplot_average, ZPLOT_TITLES='CRISM Spectral Plot', ZRANGE=zrange, $
  CAT_START_TIME  = start_time, $
  CAT_SCLK_START          = sc_clock, $
  CAT_CRISM_OBSID         = obs_name, $
  CAT_OBS_TYPE            = obs_type, $
  CAT_PRODUCT_VERSION     = 3, $
  CAT_CRISM_DETECTOR_ID   = 'L',  $                          ; CAT
  CAT_BIN_MODE            = binmode, $
  CAT_WAVELENGTH_FILTER = wvlfilter, $
  CAT_CRISM_DETECTOR_TEMP = crism_detector_temp, $
  CAT_CRISM_BENCH_TEMP = crism_bench_temp, $
  CAT_CRISM_HOUSING_TEMP = crism_housing_temp, $
  CAT_SOLAR_LONGITUDE = ls, $
  CAT_PDS_LABEL_FILE = data_lbl_file, $
  CAT_WA_WAVE_FILE = wvl_file)
  
  print, "Writing ratioed image into ENVI file with header information..."
  ENVI_WRITE_ENVI_FILE, ifdat_corr_dsp, out_name=CRISM_SAV_PATH+slash+ID+'_ratioed_cube'+'.img',DEF_BANDS=bands,interleave=1,Wavelength_units=0L, WL=meanwvl,zplot_titles='CRISM Spectral Plot'
  header2 = WRITE_CAT_HEADER(FNAME=CRISM_SAV_PATH+slash+ID+'_ratioed_cube.img', NS=size_x, NL=size_y, NB=size_l, $                  ; required
  DATA_TYPE=4, INTERLEAVE=1, OFFSET=0, $
  CLOSEFILE=closefile,  OVERWRITE=overwrite, R_FID=fid,  $        ; operational
  BBL=bbl, BNAMES=bnames, CLASS_NAMES=class_names, $   ; optional ENVI                   ; ENVI
  DATA_GAINS=data_gains, DATA_IGNORE_VALUE=65535, $
  DATA_OFFSETS=0, DEF_BANDS=bands, DEF_STRETCH=def_stretch, $
  DESCRIP=descrip, FWHM=fwhm, GEO_POINTS=geo_points, $
  LOOKUP=lookup, MAP_INFO=map_info, NUM_CLASSES=num_classes, $
  PIXEL_SIZE=pixel_size, REFLECTANCE_SCALE_FACTOR=reflectance_scale_factor, $
  SPEC_NAMES=spec_names, UNITS=units, $
  WAVELENGTH_UNIT=0L, WL=meanwvl, XSTART=xstart, YSTART=ystart, $
  ZPLOT_AVERAGE=zplot_average, ZPLOT_TITLES='CRISM Spectral Plot', ZRANGE=zrange, $
  CAT_START_TIME  = start_time, $
  CAT_SCLK_START          = sc_clock, $
  CAT_CRISM_OBSID         = obs_name, $
  CAT_OBS_TYPE            = obs_type, $
  CAT_PRODUCT_VERSION     = 3, $
  CAT_CRISM_DETECTOR_ID   = 'L',  $                          ; CAT
  CAT_BIN_MODE            = binmode, $
  CAT_WAVELENGTH_FILTER = wvlfilter, $
  CAT_CRISM_DETECTOR_TEMP = crism_detector_temp, $
  CAT_CRISM_BENCH_TEMP = crism_bench_temp, $
  CAT_CRISM_HOUSING_TEMP = crism_housing_temp, $
  CAT_SOLAR_LONGITUDE = ls, $
  CAT_PDS_LABEL_FILE = data_lbl_file, $
  CAT_WA_WAVE_FILE = wvl_file)

  
  print, "Writing spectral parameters into ENVI file with header information..."
  
  ENVI_WRITE_ENVI_FILE, crismcube, out_name=CRISM_SAV_PATH+slash+ID+'_ratioed_bandmap.img',BNAMES=namecube
  header3 = WRITE_CAT_HEADER(FNAME=CRISM_SAV_PATH+slash+ID+'_ratioed_bandmap.img', NS=size_x, NL=size_y, NB=band_num, $                  ; required
  DATA_TYPE=4,INTERLEAVE='bsq',OFFSET=0, BNAMES=namecube,$
  CLOSEFILE=closefile, OVERWRITE=overwrite, R_FID=fid,  $        ; operational
  DATA_IGNORE_VALUE=65535, $
  DATA_OFFSETS=data_offsets,  $
  CAT_START_TIME  = start_time, $
  CAT_SCLK_START          = sc_clock, $
  CAT_CRISM_OBSID         = obs_name, $
  CAT_OBS_TYPE            = obs_type, $
  CAT_PRODUCT_VERSION     = 3, $
  CAT_CRISM_DETECTOR_ID   = 'L',  $                          ; CAT
  CAT_BIN_MODE            = binmode, $
  CAT_WAVELENGTH_FILTER = wvlfilter, $
  CAT_CRISM_DETECTOR_TEMP = crism_detector_temp, $
  CAT_CRISM_BENCH_TEMP = crism_bench_temp, $
  CAT_CRISM_HOUSING_TEMP = crism_housing_temp, $
  CAT_SOLAR_LONGITUDE = ls, $
  CAT_PDS_LABEL_FILE = data_lbl_file, $
  CAT_WA_WAVE_FILE = wvl_file)
  
  ;release memories
  ifdat_corr=0b &  ifdat_corr_dsp = 0b &  crismcube = 0b
   
end