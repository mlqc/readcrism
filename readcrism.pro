; NAME:     readcrism
;
; PURPOSE:
;     Read crism files and use despike, destripe and flattening functions to improve parameter maps for detection of hydrated minerals
;     This is a simplified version of readcrism.pro by John Carter
;     Rewritten despike.pro; added band threshold option for flattening; kept destriping algorithm

; CALLING SEQUENCE:
;
;************************************************************
;********Need to specify paths before running****************
;IDL> @mypaths.def
;IDL> save,file='mypaths.sav'
;IDL> readcrism,crismlist
;************************************************************

; INPUTS:
;    filename: data file name (with path)
;    keywords: string array containing the list of keyword
;
; OUTPUTS:
;    
; NOTES:
;----
;01/16/2017 rewrite input code for harddrive
;           try to incorporate multispectral dataset
;11/24/2014 Reading files completed.
;
; CREATED: Nov 2014
;      BY: L. Pan



PRO READCRISM, crismlist
!QUIET=1
print,';;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;'
print,';         READCRISM XD          ;'
print,';           L. PAN              ;'
print,';          2014 Nov             ;'
print,';;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;'

;////Identify system used for running readcrism\\\\\

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

;/////START WITH RADIANCE FILE DOWNLOADED FROM PDS|\\\\\\\\\
;
;
ra_corr = 0


;/////photometric and atmospheric correction\\\\\\\\\
photo_corr = 0
atp_corr = 0
pds2cat = 0


;/////Find bad spectels and produce bad spectel list\\\\\
bad_spectels_corr = 1
list_bad_spec_only = 1



rm_tir = 1
;/////Remove spikes\\\\\\\\\\\\
rm_spikes = 1
lpfilter = 0
;///////Continuum removal and band threshold ratios\\\\\\\\\
rm_cont_bdt = 1

;///////Remove stripes after cube ratioing and continuum removal\\\\\\\\\\\
rm_stripes = 1

;///////Make spectral parameter maps\\\\\\\\\\\\\\\\\\
make_bands = 1


restore,'mypaths.sav'


; Looking for data
print, n_elements(crismlist)
if n_elements(crismlist) eq 0 then goto,finish
tmp=FILE_SEARCH(strcompress(pro_path+crismlist,/remove_all),count=countb)
if countb eq 0 then goto,finish
READCOL,pro_path+crismlist,folders,FORMAT='A'
folders=strtrim(folders,2)
END_BATCH=n_elements(folders)-1
print,'   Found '+strcompress( string(end_batch+1)+' cube(s) to process')
print,' --------------------------------'
print,' '

for ifolder=0,END_BATCH DO BEGIN
yearday=(strsplit(folders(ifolder),'\',/extract))[0]
year = uint((strsplit(yearday,'_',/extract))[0])
day = uint((strsplit(yearday,'_',/extract))[1])
ID=(strsplit(folders(ifolder),'\',/extract))[1]
ID_type = (strsplit(ID,'0',/extract))[0]
ID_no = (strsplit(ID,'0',/extract))[1]

print,'Reading CRISM file-'+ID
; initializing

close,/all

; ---------------------------------------
; FIND CUBE TO ANALYSE
; ---------------------------------------

restore,'mypaths.sav'
if (year LT 2008) then datano='data4'
if (year EQ 2008) and (day LE 325) then datano='data4'
if (year EQ 2008) and (day GT 325) then datano='data5'
if (year GT 2008) and (year LT 2014) then datano='data5'
if (year EQ 2008) and (day LE 325) then datano='data4'
if (year EQ 2014) and (day LE 144) then datano='data5'
if (year EQ 2015) then datano='data6'
if (year EQ 2014) and (day GT 144) then datano='data6'
if  strtrim(ID_no,0) EQ '3' then datano = 'data6'
path_seperate = strsplit(crism_data_path,slash,/extract)
crism_data_path=strcompress(slash+slash+path_seperate[0]+slash+datano+slash+path_seperate[2]+slash+path_seperate[3]+slash+yearday+slash+ID+slash,/remove_all)

;crism_nav_path=crism_nav_path.replace('data4',datano)
;crism_data_path=strcompress(crism_data_path+ID+slash,/remove_all)
crism_ddr_path=strcompress(crism_ddr_path+yearday+slash+ID+slash,/remove_all)
;Seek data file



if ra_corr eq 1 then begin
  seek_crism=file_search(crism_ra_path+slash+strlowcase(ID)+'*ra*l_trr3.img',count=count)
  print,"Found data file: "+seek_crism
  ;Read label file. These files are kept in the folders
  if count eq 0 then return ; goto,finish
  data_file=seek_crism(0)

  seek_crism=file_search(crism_ra_path+slash+strlowcase(ID)+'*ra*l_trr3.lbl',count=count)
  print,"Found data file label: "+seek_crism
  if count eq 0 then return ; goto,finish
  data_lbl_file=seek_crism(0)
endif else begin 
  
  seek_crism=file_search(crism_data_path+'*'+'*0*_IF*L_TRR3*CAT_corr.img',count=count)
  ;/////If found, skip photometric and atmospheric correction\\\\\\\\\
  photo_corr = 0
  atp_corr = 0
  pds2cat = 0
  if count eq 0 then begin
    seek_crism=file_search(crism_data_path+'*'+'*0*_IF*L_TRR3*CAT.img',count=count)
    photo_corr = 1
    atp_corr = 1
  endif
  if count eq 0 then begin
    seek_crism = file_search(crism_data_path+'*'+'*0*_IF*L_TRR3.IMG',count=count)
    pds2cat = 1
  endif
  print,"Found data file: "+seek_crism
  ;Read label file. These files are kept in the folders
  if count eq 0 then return ; goto,finish
  data_file=seek_crism(0)

  seek_crism=file_search(crism_data_path+'*0*_IF*L_TRR3.LBL',count=count)
  print,"Found data file label: "+seek_crism
  if count eq 0 then return ; goto,finish
  data_lbl_file=seek_crism(0)
;  seek_crism=file_search(crism_data_path+'*0*_IF*L_TRR3*CAT_corr*.hdr',count=count)
;  print,"Found cat data header file: "+seek_crism
;  if count eq 0 then return ; goto,finish
;  cat_header_file=seek_crism(0)
endelse

seek_crism=file_search(crism_ddr_path+'*07_de*l_ddr1.img',count=count)
if count eq 0 then seek_crism=file_search(crism_ddr_path+'*07_DE*L_DDR1.IMG',count=count)
if count eq 0 then seek_crism=file_search(crism_ddr_path+'*01_DE*L_DDR1.IMG',count=count)
print,"Found data ddr file: "+seek_crism
if count eq 0 then return ; goto,finish
geo_file=seek_crism(0)

seek_crism=file_search(crism_ddr_path+'*07_de*l_ddr1.lbl',count=count)
if count eq 0 then seek_crism=file_search(crism_ddr_path+'*07_DE*L_DDR1.LBL',count=count)
if count eq 0 then seek_crism=file_search(crism_ddr_path+'*01_DE*L_DDR1.LBL',count=count)
print,"Found data ddr file label: "+seek_crism
if count eq 0 then return ; goto,finish

geo_lbl_file=seek_crism(0)
;continue
; -----------------------------------
; READ DATA LABEL
; -----------------------------------

print,'<> Reading auxiliary files'
;Here we find the related keywords in the data files.
lblvalues=''
keywords=['RECORD_BYTES','FILE_RECORDS','LINES','LINE_SAMPLES','BANDS','SOLAR_LONGITUDE','MRO:WAVELENGTH_FILE_NAME','SOLAR_DISTANCE', 'MRO:SENSOR_ID', 'MRO:WAVELENGTH_FILTER', 'PIXEL_AVERAGING_WIDTH','SPACECRAFT_CLOCK_START_COUNT','PRODUCT_ID']

READ_CRISM_LBL,STRCOMPRESS(data_lbl_file),keywords,lblvalues
lblvalues=strtrim(lblvalues,2)
size_y=fix(lblvalues(2));LINES
size_x=fix(lblvalues(3));LINE_SAMPLES
size_l=fix(lblvalues(4));BANDS
ls=float(lblvalues(5));SOLAR_LONGITUDE
wvl_file=strtrim(string(strsplit(reform(lblvalues(6)),'"',/EXTRACT)),2);WAVELENGTH FILE
dmars=float(lblvalues(7))/149598000.;SOLAR DISTANCE
channel=string(strsplit(reform(lblvalues(8)),'"',/EXTRACT)) ;SENSOR ID
wvlfilter=string(strsplit(reform(lblvalues(9)),'"',/EXTRACT)); WAVELENGTH FILTER
binning=fix(lblvalues(10))
file_name=strtrim(string(strsplit(reform(lblvalues(12)),'"',/EXTRACT)),2);TRR3 file name
obs_name=strtrim(string((strsplit(file_name,'_',/extract))[0]),2); 'FRT00018AEF'
sc_clock=string(lblvalues(11)) ;
if binning eq 1 then binmode='0'
if binning eq 2 then binmode='1'
if binning eq 5 then binmode='2'
if binning eq 10 then binmode='3'
obs_type=strmid(obs_name,0,3)
endl=size_l-1
;readu,1,cat_header_file


; -----------------------------------
; SKIP IF PROCESSED CUBE ALREADY EXISTS
; -----------------------------------

tmp=(strsplit(file_name,'_',/extract))[0]
temp=file_search( strcompress(crism_sav_path+tmp+'.sav',/remove_all),count=counts)
if counts eq 1 then begin
    print,'<!> File already exists, skipping ',tmp
    continue
endif
tmp=0b & temp=0b
if obs_type ne 'FRT' then print,'<!> Warning : Processing non-FRT(Full Resolution Tile) data in BETA version !'

; -----------------------------------
; READ WAVELENGTH FILE
; -----------------------------------
wvlc=fltarr(size_x,size_l)
wvlc_subrows=bytarr(size_l)
CLOSE,1
OPENR,1,crism_ref_path+slash+'WA'+slash+wvl_file,ERROR=err
if err eq 0 then begin
    readu,1,wvlc
    readu,1,wvlc_subrows
endif
if err ne 0 then begin
    print,'<!> Error : Wavelength file not found'
    return
endif
CLOSE,1
wvlc=swap_endian(temporary(wvlc),/swap_if_big_endian) 
wvlc=wvlc*0.001
wvlc(*,0)=4.0
temp=where(wvlc eq 65.5350,count)
if count gt 0 then wvlc(temp)=0.
wvlc=reverse(wvlc,2)
wvlc_subrows=reverse(wvlc_subrows)
wvlc_subrows=0b

meanwvl=fltarr(size_l)
for i=0,size_l-1 do begin  
  if size_x lt 100 then begin
    print,'Bad data: wvlc file less than 100 rows'
    return
  endif
  if obs_type eq 'FRT' then sweetspot=270 else sweetspot=size_x-101
  sweetspot = sweetspot+indgen(100)
  flag = intarr(100)
  for k=0,100-1 do begin
    if wvlc(sweetspot(k),i) eq 0 then flag(k)= 0 else flag(k)=1
    endfor
   meanwvl(i) = total(wvlc(sweetspot(*),i)*flag)/total(flag)
endfor

; -----------------------------------
; READ DATA FILE
; -----------------------------------
print,'<> Reading data file'
radat = FLTARR(size_x,size_l,size_y,/nozero)
;radat_rownum=bytarr(size_l)
close,1
OPENR, 1, STRCOMPRESS(data_file),ERROR=errdat
if errdat ne 0 then return
readu,1,radat
;readu,1,radat_rownum
close,1
if ra_corr eq 1 or pds2cat eq 1 then begin
  radat=reverse(radat,2,/overwrite)
  endif
;  endif else begin
;  ifdat_corr = tmp(radat)
;  endelse
  
; -----------------------------------
; READ GEOMETRY LABEL
; -----------------------------------
print,'<> Reading geometry file'

keywords=['LINES','LINE_SAMPLES','BANDS','BAND_NAME','SOLAR_LONGITUDE','SOLAR_DISTANCE']
READ_CRISM_LBL,STRCOMPRESS(geo_lbl_file),keywords,lblvalues
if lblvalues(0) ne size_y or lblvalues(1) ne size_x then begin
    print,'<!> Error : bad geometry data file'
endif
dmars=float(lblvalues(5))/149598000.
ls=float(lblvalues(4))
geocube_size=lblvalues(2)
geocube_header=strsplit(lblvalues(3),'"',/extract)
geocube_header=strtrim(geocube_header,2)
temp=where(geocube_header ne '(' and geocube_header ne ',' and geocube_header ne ')')
geocube_header=geocube_header(temp)
; -----------------------------------
; READ GEOMETRY DATA
; -----------------------------------
geocube=fltarr(size_x,size_y,geocube_size,/nozero)
close,1
OPENR,1, STRCOMPRESS(geo_file),ERROR=errgeo
if errgeo ne 0 then return
readu,1,geocube

close,1
print,''
print,'   . Reading file :',file_name
print,''
print,'   . Cube sizes  (X, L, Y)',size_x,size_l,size_y
print,'   . Latitude      (deg N)',min(geocube(*,*,3)),max(geocube(*,*,3))
print,'   . Longitude     (deg E)',min(geocube(*,*,4)),max(geocube(*,*,4))
print,'   . Solar incidence (deg)',min(geocube(*,*,0)),max(geocube(*,*,0))
print,'   . Solar emergence (deg)',min(geocube(*,*,1)),max(geocube(*,*,1))
print,'   . Solar distance   (AU)',dmars
print,'   . Solar longitude (deg)',ls
print,'   . Altitude MOLA     (m)',mean(geocube(*,*,9))
print,'   . Local time    (hours)',mean(geocube(*,*,12))
print,''


; -----------------------------------
; READ ATM TRANSMISSION HEADER & FILE
; -----------------------------------
; Find the best atm file
if atp_corr eq 1 then begin

get_atm_file=file_search(crism_ref_path+slash+'AT'+slash+'CDR4*_AT'+'*'+binmode+'*'+wvlfilter+'*'+channel+'_*.LBL',count=count)
if count eq 0 then begin
  print,'<!> Error : Atmospheric transmission file not found'
  continue
endif


pos=strpos(get_atm_file(0),'_AT')
retbin=strmid(get_atm_file,pos+4,1)
w=where(retbin eq binmode)
get_atm_file=get_atm_file(w)
retwvf=strmid(get_atm_file,pos+8,1)
w=where(retwvf eq wvlfilter)
get_atm_file=get_atm_file(w)

if n_elements(get_atm_file) eq 1 then begin
  ;   sclk=long(strmid(sc_clock,3,10)) ;
  ;   corrected CAT<=v6.6 bug with
  ;   spacecraft clock
  sclk=long(strmid(sc_clock,stregex(sc_clock,'/')+1,10))
  startapp=lonarr(n_elements(get_atm_file))
  ver=strarr(n_elements(get_atm_file))

  for k=0,n_elements(get_atm_file)-1 do begin
    pos=strpos(get_atm_file[k],'_AT')
    startapp(k)=long(strmid(get_atm_file[k],pos-10,10))
    pos=strpos(get_atm_file(k),'.LBL')
    ver(k)=fix(strmid(get_atm_file(k),pos-1,1))
  endfor
  check=n_elements(startapp(uniq(startapp,bsort(startapp))))

  if (check gt 1)then begin
    get_atm_file=get_atm_file(bsort(startapp))
    startapp=startapp(bsort(startapp))
    ver=ver(bsort(startapp))
    app=intarr(n_elements(get_atm_file))
    for k=0,n_elements(get_atm_file)-2 do $
      if (sclk gt startapp(k)) and (sclk lt startapp(k+1)) then app(k)=1 else app(k)=0
    k=n_elements(get_atm_file)-1
    if (sclk gt startapp(k)) then app(k)=1 else app(k)=0
    wapp=where(app eq 1)
    get_atm_file=get_atm_file(wapp)
    ver=ver(wapp)
  endif
  if (n_elements(get_atm_file) gt 1) then begin
    ; Find highest version:
    wnew=where(ver eq max(ver))
    get_atm_file=get_atm_file(wnew[0])
  endif
endif




atm_len=strlen(get_atm_file)
atm_file=strmid(get_atm_file,0,atm_len-4)+'.IMG'
keywords=['MRO:WAVELENGTH_FILE_NAME']
READ_CRISM_LBL,STRCOMPRESS(get_atm_file),keywords,atmlblvalues
atmlblvalues=strsplit(atmlblvalues(0),'"',/extract)
atmlblvalues=strtrim(string(atmlblvalues),2)
atmlblvalues=strmid(atmlblvalues,0,strlen(atmlblvalues)-6)
atmlblvalues=(file_search(crism_ref_path+slash+'WA'+slash+atmlblvalues+'*.IMG'))[0]
atmlblvalues=strcompress(atmlblvalues(0),/remove_all)

close,2
wvlc_at=fltarr(size_x,size_l)
openr,2,atmlblvalues
readu,2,wvlc_at
CLOSE,2
wvlc_at=swap_endian(temporary(wvlc_at),/swap_if_big_endian)
wvlc_at=wvlc_at*0.001
wvlc_at(*,0)=4.0
temp=where(wvlc_at eq 65.5350,count)
if count gt 0 then wvlc_at(temp)=0.
wvlc_at=reverse(wvlc_at,2)
atm=fltarr(size_x,size_l)
CLOSE,1
OPENR,1,atm_file
readu,1,atm
CLOSE,1
atm=reverse(atm,2)
retbin=0b & retwvf=0b

endif
; -----------------------------------
; FIND GOOD DATA
; -----------------------------------

;if want to remove CRISM data > 2.8 µm (faster):then ending wavelength is No. 265 given that it's a targed image with 438 bands
if rm_tir eq 1 and (obs_type eq 'FRT' or obs_type eq 'HRL') then endl=265
if rm_tir eq 0 then endl=size_l-1

;Find CRISM no data values on the edge of file.
for i=0,size_x/4,1 do begin
  check_min=where(finite(radat(i,size_l/2,*)) eq 0 or radat(i,size_l/2,*) le 0. or radat(i,size_l/2,*) gt 2.,count_min)
  if count_min lt size_y/4 then break
endfor
min_i=i
for i=size_x-1,3*size_x/4,-1 do begin
  check_max=where(finite(radat(i,size_l/2,*)) eq 0 or radat(i,size_l/2,*) le 0. or radat(i,size_l/2,*) gt 2.,count_max)
  if count_max lt size_y/4 then break
endfor
max_i=i
check_min=0b & check_max=0b & count_min=0b &  count_max=0b

;Make the ignore values into NAN for later calculations.
;Mask out the original bad bands.

for i=0,size_y-1 do begin
  for j=0,size_x-1 do begin
  check_nan = where(finite(radat(j,*,i)) eq 0 or radat(j,*,i) eq 65535.0)
  radat(j,check_nan,i) = !VALUES.F_NAN
  endfor
endfor

; -----------------------------------
; RADIANCE TO I/F CALCULATION [OPTIONAL]
; -----------------------------------
if ra_corr eq 1 then begin
  print,'<> Radiance to I/F calculation'
  ;Find solar spectrum from auxillary files. 
  ; Find the best solar spectrum file

  get_sf_file=file_search(crism_ref_path+slash+'SF'+slash+'CDR4*_SF'+'*'+binmode+'*'+wvlfilter+'*'+channel+'_*.LBL',count=count)
  if count eq 0 then begin
    print,'<!> Error : Solar flux spetrum file not found'
    continue
  endif
  pos=strpos(get_sf_file(0),'_SF')
  retbin=strmid(get_sf_file,pos+4,1)
  w=where(retbin eq binmode)
  get_sf_file=get_sf_file(w)
  retwvf=strmid(get_sf_file,pos+8,1)
  w=where(retwvf eq wvlfilter)
  get_sf_file=get_sf_file(w)
  
  if n_elements(get_sf_file) eq 1 then begin
    sf=fltarr(size_x,size_l)
    sf_len=strlen(get_sf_file)
    sf_file=strmid(get_sf_file,0,atm_len-4)+'.IMG'
    CLOSE,1
    OPENR,1,sf_file
    readu,1,sf
  endif
  sf=reverse(sf,2)
  ifdat = ra2if(radat,sf,dmars)
endif

if ra_corr ne 1 then begin
ifdat = radat
endif
; -----------------------------------
; MAKE BAD SPECTEL LIST
; -----------------------------------
if list_bad_spec_only eq 1 and bad_spectels_corr eq 1 then begin
  print,'<> Locating bad spectels'
  if n_elements(bad_spectel) le 1 then bad_spectel=-1
  add_bad=where(wvlc(size_x/2,*) lt 0.4 or wvlc(size_x/2,*) gt 5.,count_bad)
  if count_bad gt 0 then bad_spectel=[bad_spectel,add_bad]
  x_min=fix(max([size_x/2.-8.,0.]))
  x_max=fix(min([size_x/2.+8.,size_x-1.]))
  y_min=fix(max([size_y/2.-8.,0.]))
  y_max=fix(min([size_y/2.+8.,size_y-1.]))
  slice=ifdat(x_min:x_max,*,y_min:y_max)
  slice_size=float(x_max-x_min+1.)*float(y_max-y_min+1.)
  for l=0,endl+1-1 do begin
    tmp=where(slice(*,l,*) le 0.01 or slice(*,l,*) gt 50.,count)
    if count gt fix(slice_size/2.) then bad_spectel=[bad_spectel,l]
  endfor
  if n_elements(bad_spectel) gt 1 then begin
    if bad_spectel(0) eq -1 then bad_spectel=bad_spectel(1:*)
    if bad_spectel(0) eq 0 and n_elements(bad_spectel) gt 1 then bad_spectel=bad_spectel(1:*)
  endif
  tmp = 0& slice=0 & slice_size=0
  print,'For image:'+ID+', bad channels are: ', bad_spectel
  if list_bad_spec_only ne 1 then begin
    print,'The above channels are marked as NAN.'
    radat(*,bad_spectel,*) = !VALUES.F_NAN
  endif
endif


; -----------------------------------
; PHOTOMETRIC CORRECTION [SKIP IF ALREADY CORRECTED USING CAT]
; -----------------------------------
if  photo_corr eq 1 then begin
  print,'<> Photometric correction'
  incidence=reform(geocube(*,*,0))
  incidence=1./cos(!dtor*incidence)
  incidence=smooth(incidence,3)
  incidence=reform(incidence,size_x,1,size_y)
;  gdat=ifdat
  for l=0,endl do ifdat(*,l,*) *= incidence(*,0,*)
  check_ifdat=where(finite(ifdat) eq 0 or ifdat lt 0. or ifdat gt 10.,count)
  if count gt 0 then ifdat(check_ifdat)=!VALUES.F_NAN
  check_ifdat=0b & incidence=0b & count=0 & inci=0b &
endif


; -----------------------------------
; ATMOSPHERIC CORRECTION [SKIP IF ALREADY CORRECTED USING CAT]
; -----------------------------------
if  atp_corr eq 1 then begin
    print,'<> Atmospheric correction'
    ;McGuire 2 wavelengths method
    ;I/F(lambda) = AL(lambda)* [T(lambda)]^beta
    temp_wvlc=wvlc(*,0:endl)
    temp_wvlc=reform(temp_wvlc,size_x,endl+1,1)
    temp_wvlc=reform(temp_wvlc(*,*,0))
    beta=fltarr(size_x,size_y,/nozero)
    beta=reform(beta,size_x,1,size_y)

    temp_atm=atm(*,0:endl)
    temp_atm=reform(temp_atm,size_x,endl+1,1)
    for i=0,size_x-1 do begin
      temp=min(abs(temp_wvlc(i,*)-1.980),r1980index)
      temp=min(abs(wvlc_at(i,0:endl)-1.980),r1980index_at)
      temp=min(abs(temp_wvlc(i,*,0)-2.007),r2007index)
      temp=min(abs(wvlc_at(i,0:endl)-2.007),r2007index_at)
            temp=min(abs(temp_wvlc(i,*)-1.899),r1899index)
            temp=min(abs(temp_wvlc(i,*,0)-2.011),r2011index)
            temp=min(abs(wvlc_at(i,0:endl)-2.011),r2011index_at)
            temp=min(abs(wvlc_at(i,0:endl)-1.899),r1899index_at)
      beta(i,0,indgen(size_y))=alog(reform(ifdat(i,r2011index,indgen(size_y)))/reform(ifdat(i,r1899index,indgen(size_y))))/alog(temp_atm(i,r2011index_at,indgen(size_y)/99999)/temp_atm(i,r1899index_at,indgen(size_y)/99999))
    endfor

;      temp=min(abs(temp_wvlc(i,*)-1.299),r1299index)
;      temp=min(abs(temp_wvlc(i,*)-2.527),r2527index)
;      temp=min(abs(temp_wvlc(i,*)-1.850),r1850index) 
    temp_wvlc=0b
    ref_pt=0b
    tmp=temporary(temp_atm)
    temp_atm=tmp(*,indgen(endl+1),indgen(size_y)/99999)^beta(*,indgen(endl+1)/99999,indgen(size_y))
    beta=0b
      ifdat_corr=fltarr(size_x,size_l,size_y,/nozero)
      for l=0,endl do  ifdat_corr(*,l,*)=ifdat(*,l,*)/temp_atm(*,l,*)
    beta=0B & temp_atm=0b & temp_fit=0b & wvl_fit=0b & temp_wvlc=0b & check_data=0b & temp=0 & pente=0b & offset=0b & tmp=0b
endif

if photo_corr eq 0 and atp_corr eq 0 then begin
  print,"Batch corrected file: skipping atmospheric correction...."
  ifdat_corr = ifdat
  ifdat = 0b
 endif
;ENVI_WRITE_ENVI_FILE, tmpdat, out_name=ID+'_ratio_despike.img',DEF_BANDS=[232,76,12],interleave=1,Wavelength_units=0L, WL=meanwvl,zplot_titles='CRISM Spectral Plot'
;envi_write_envi_file,ifdat,out_name='if.img',def_bands=[232,76,12],interleave=1,wavelength_units=0l, wl=meanwvl
;envi_write_envi_file,ifdat_corr,out_name='_pelkey_atm_corr.img',def_bands=[232,76,12],interleave=1,wavelength_units=0l, wl=meanwvl

; -----------------------------------
; DESPIKE
; -----------------------------------
if rm_spikes eq 1 then begin
  print,'<> Basic spike correction'
  tmp=0b
  threshold=0.015
  tmp=slicedespike(ifdat_corr,threshold,1,0.001,bad_spectel,0)
  ifdat_corr_dsp=temporary(tmp)
endif
if rm_spikes eq 0 then begin
  print,'<> Skipping basic spike correction'
  tmp=ifdat_corr
  ifdat_corr_dsp=temporary(tmp)
endif
;ENVI_WRITE_ENVI_FILE, ifdat_corr_dsp, out_name=ID+'_despiked.img',DEF_BANDS=[232,76,12],interleave=1,Wavelength_units=0L, WL=meanwvl,zplot_titles='CRISM Spectral Plot'
;continue
;start_l=12
;if rm_spikes eq 1 and lpfilter eq 1 then begin
;  print,'<> Low pass filter noise reduction'
;  tmp = radat
;  for i= 0,size_y-1 do begin
;    for j=min_i,max_i-1 do begin
;      tmp(j,start_l:end_l-12,i) = BANDPASS_FILTER(radat(j,start_l:end_l-12,i), 0, 0.45, $
;      BUTTERWORTH=20)
;  endfor
;  endfor
;  tmpdat=temporary(tmp)
;endif
;ENVI_WRITE_ENVI_FILE, tmpdat, out_name=ID+'_lowpassfiltered.img',DEF_BANDS=[232,76,12],interleave=1,Wavelength_units=0L, WL=meanwvl,zplot_titles='CRISM Spectral Plot'

; -----------------------------------
; LINEAR CONTINUUM REMOVAL
; -----------------------------------
; -----------------------------------
; BORING CUBE RATIOING
; -----------------------------------
if rm_cont_bdt eq 1 then begin
      print,'<> Removing continuum (avg method with band threshold)'
      tmp=0b
      FLATTEN,wvlc,ifdat_corr_dsp,tmpdatflat,/BANDTHRES ; flatten ver >= v3.1
      ifdat_corr_dsp=temporary(tmpdatflat)
      ;ENVI_WRITE_ENVI_FILE, tmpdat, out_name=ID+'_bdt2.img',DEF_BANDS=[12,76,232],interleave=1,Wavelength_units=0L, WL=meanwvl,zplot_titles='CRISM Spectral Plot'
      ;ENVI_SETUP_HEAD, fname = ID+'_bdt2.img',interleave=1,wavelength_units=0l,wl=meanwvl,data_ignore_value=65535, offset=0, /write, /open
endif
    
; -----------------------------------
; From now on we start to make efforts to make better maps
; -----------------------------------
;if rm_spikes eq 1 then begin
;  print,'<> Basic spike correction'
;  tmp=0b
;  tmp=slicedespike(ifdat_corr_dsp,0.01,1,0.001,bad_spectel,1)
;  ifdat_corr_dsp=temporary(tmp)
;endif
;ENVI_WRITE_ENVI_FILE, tmpdat, out_name=ID+'_ratio_despike.img',DEF_BANDS=[232,76,12],interleave=1,Wavelength_units=0L, WL=meanwvl,zplot_titles='CRISM Spectral Plot'

;if rm_spikes eq 1 and lpfilter eq 1 then begin
;  print,'<> Low pass filter noise reduction'
;  tmp = tmpdat
;  for i= 0,size_y-1 do begin
;    for j=min_i,max_i-1 do begin
;      tmp(j,start_l:end_l-12,i) = BANDPASS_FILTER(tmpdat(j,start_l:end_l-12,i), 0, 0.45, $
;      BUTTERWORTH=20)
;  endfor
;  endfor
;  tmpdat=temporary(tmp)
;endif
;ENVI_WRITE_ENVI_FILE, tmpdat, out_name=ID+'_ratio_despikelowpassfiltered.img',DEF_BANDS=[232,76,12],interleave=1,Wavelength_units=0L, WL=meanwvl,zplot_titles='CRISM Spectral Plot'
;return
; -----------------------------------
; DESTRIPE
; -----------------------------------

if rm_stripes eq 1 then begin
  print,'<> Stripe correction'

  window_size=13
  wk=findgen(window_size)-(window_size-1)/2.
  hwidth=3
  kernel=(-1./!Pi)*hwidth/((wk-0.)^2+hwidth^2)
  kernel=kernel/(min(kernel)) ; lorentz

  med_image=fltarr(size_x,endl+1,/nozero)
  med_col1=MEDIAN(ifdat_corr_dsp(*,0:endl,10:size_y/3.),dimension=3)
  med_col2=MEDIAN(ifdat_corr_dsp(*,0:endl,size_y/3.+1:2.*size_y/3.),dimension=3)
  med_col3=MEDIAN(ifdat_corr_dsp(*,0:endl,2.*size_y/3.+1:size_y-11),dimension=3)

  med_col=(med_col1+med_col2+med_col3)/3.
  med_col(indgen(min_i+1),*)=med_col(indgen(min_i+1)*0+min_i+1,*)
  med_col(indgen(size_x-max_i)+max_i,*)=med_col(indgen(size_x-max_i)*0+max_i-1,*)
  for l=0,endl do begin
    convol_in=reform(med_col(*,l))
    med_image(*,l)=CONVOL(convol_in,kernel,total(kernel),/NAN,/CENTER,/EDGE_TRUNCATE)
  endfor
  med_col=reform(med_col,size_x,endl+1,1)
  med_image=reform(med_image,size_x,endl+1,1)
  tmp=temporary(ifdat_corr_dsp)
  ifdat_corr_dsp=fltarr(size_x,size_l,size_y,/nozero)
  ifdat_corr_dsp(0:min_i,0:endl,*)=tmp(0:min_i,0:endl,*)
  ifdat_corr_dsp(max_i:*,0:endl,*)=tmp(max_i:*,0:endl,*)
  ifdat_corr_dsp(min_i+1:max_i-1,indgen(endl+1),indgen(size_y))=tmp(min_i+1:max_i-1,indgen(endl+1),indgen(size_y))/med_col(min_i+1:max_i-1,indgen(endl+1),indgen(size_y)/99999)*med_image(min_i+1:max_i-1,indgen(endl+1),indgen(size_y)/99999)
  tmp=0b & med_col=0b & med_image=0b  & convol_in=0b &  med_col1=0b & med_col2=0b & med_col3=0b
endif
;stripe_profile = tmpdat/gdat
;showimg,tmpdat,143
;showimg,stripe_profile,143
;plotspectra,tmpdat,size_x/3,size_y*2/3,wvlc
;ENVI_WRITE_ENVI_FILE, tmpdat, out_name=ID+'_tmpdat_goodpicture2.img',DEF_BANDS=[12,76,232],interleave=1,Wavelength_units=0L, WL=meanwvl,zplot_titles='CRISM Spectral Plot'
;ENVI_SETUP_HEAD, fname = ID+'_tmpdat_goodpicture2.img',ns=size_x,nl=size_y,nb=size_l,DEF_BANDS=[12,76,232],interleave=1,wavelength_units=0l,wl=meanwvl,data_ignore_value=65535,offset=0, /write, /open

; -----------------------------------
; MAKE BAND MAPS!
; -----------------------------------

if make_bands eq 1 then begin
  ;if make_bands eq 1 and rm_atm eq 1 then begin
  print,'<> Running spectral criteria'
  ifcorr_bmap = ifdat_corr_dsp
  ; DEAL WITH MAFIC : NO CONTINUUM REMOVAL, NO FLATTENING
  if n_elements(ifcorr_bmap) gt 1 then CRITERIA,wvlc,ifcorr_bmap,crismcube,namecube,bad_spectel,/CRISM,/MAFIC
  if n_elements(ifcorr_bmap) le 1 then CRITERIA,wvlc,ifcorr_bmap,crismcube,namecube,bad_spectel,/CRISM,/MAFIC
  OLIVINE=crismcube(*,*,9)
  PYROXENE=crismcube(*,*,10)
  PLAGIOCLASE=crismcube(*,*,11)

  CRITERIA,wvlc,ifcorr_bmap,crismcube,namecube,bad_spectel,/CRISM
  MHSULFATE=crismcube(*,*,7)
  PHSULFATE=crismcube(*,*,5)
  CHLORITES=crismcube(*,*,4)


  FLATTEN,wvlc,ifcorr_bmap,tmpdat2,/MLINEAR ; flatten ver >= v3.0
;  ENVI_WRITE_ENVI_FILE, tmpdat2, out_name=ID+'_mlinear.img',DEF_BANDS=[12,76,232],interleave=1,Wavelength_units=0L, WL=meanwvl,zplot_titles='CRISM Spectral Plot'
;  ENVI_SETUP_HEAD, fname = ID+'_mlinear.img',interleave=1,wavelength_units=0l,wl=meanwvl,data_ignore_value=65535, offset=0, /write, /open

  keepdat=temporary(ifcorr_bmap)
  ifcorr_bmap=temporary(tmpdat2)

  CRITERIA,wvlc,ifcorr_bmap,crismcube,namecube,bad_spectel,/CRISM
  crismcube(*,*,7)=MHSULFATE
  crismcube(*,*,5)=PHSULFATE
  crismcube(*,*,4)=CHLORITES

  crismcube(*,*,9)=OLIVINE
  crismcube(*,*,10)=PYROXENE


  ifcorr_bmap=temporary(keepdat)
  ;ENVI_WRITE_ENVI_FILE, crismcube, out_name=ID+'_flattened_bandmap2.img',BNAMES=bandname,interleave=0

endif


; -----------------------------------
; GENERATE INFOCUBE
; -----------------------------------
infocube=fltarr(size_x,size_y,9,/nozero)
infocube(*,*,0)=geocube(*,*,4)
infocube(*,*,1)=geocube(*,*,3)
infocube(*,*,2)=geocube(*,*,9)
infocube(*,*,3)=geocube(*,*,0)
infocube(*,*,4)=geocube(*,*,1)
infocube(*,*,5)=geocube(*,*,2)
infocube(*,*,6)=0.
infocube_header=['Longitude E', 'Latitude N','MOLA altimetry (meters)', 'Solar incidence (Deg)', 'Solar Emergence (Deg)', 'Solar phase (Deg)', '-Null-','1. 25µm Albedo', 'Bolometric albedo']
check=where(finite(infocube) eq 0,count)
if count gt 0 then infocube(check)=0.
count = 0b  & check=0b

; -----------------------------------
; GENERATE LOG INFORMATION
; -----------------------------------
conv_min_lon=min(infocube(*,*,0))
conv_max_lon=max(infocube(*,*,0))
if conv_min_lon lt 0 then conv_min_lon=360.+conv_min_lon
if conv_max_lon lt 0 then conv_max_lon=360.+conv_max_lon 
log=strarr(6)
log(0)=strcompress('FILE_NAME '+FILE_NAME)
log(1)=strcompress('OBSERVATION '+OBS_NAME)
log(2)=strcompress('BUILD_DATE '+SYSTIME())
log(3)=strcompress('DATA_SIZE '+string(size_x)+' '+string(size_l)+' '+string(size_y))
log(4)=strcompress('MAP_LON/LAT '+'[ '+ $
                   string(conv_min_lon)+' , ' + $
                   string(conv_max_lon)+' ] [ '+ $
                   string(min(infocube(*,*,1)))+' , '+ $
                   string(max(infocube(*,*,1)))+' ]')
log(5)=            'INFO '+strcompress('Solar Incidence (deg):'+string(mean(geocube(*,*,0)))+' Solar Longitude (deg):'+string(ls)+' Mars distance (UA):'+string(dmars)+' Local time (h):'+string(mean(geocube(*,*,12))) )



file_name=(strsplit(file_name,'_',/extract))[0]


;tmp=min(abs(wvlc(size_x/2,*)-1.25),wpos1)

;if n_elements(hdat) gt 1 and save_mem ne 2 then infocube(*,*,7)=reform(hdat(*,wpos1,*))

;tmp=min(abs(wvlc(size_x/2,*)-1.99),wpos1)
;tmp=min(abs(wvlc(size_x/2,*)-2.65),wpos2)
;if n_elements(hdat) gt 1 and save_mem ne 2 then infocube(*,*,8)=median(hdat(*,wpos1:wpos2,*),dimension=2)


print,'<> Saving despiked and ratioed cubes, bandmaps and related files to '+ID+'.sav'
 save,infocube_header,infocube,ifdat_corr,ifdat_corr_dsp,NAMECUBE,CRISMCUBE,WVLC,meanwvl,BAD_SPECTEL,file=strcompress(crism_sav_path+ID+'.sav',/remove_all)
 print,'<> CRISM data reduction for '+ID+': Finished'
 
radat=0b & tmpdat=0b & namecube=0b & crismcube=0b & wvlc=0b & bad_spectel=0b
print,'***************************************************************'
print,''
print,''
print,''
endfor
  finish:

END
 
