; -------------------------------------------------------------
; NAME:
; -------------------------------------------------------------
;       CRITERIA 
;
;       ver 2.2 - released july 2010    
;       author: John Carter (IAS)
;       contributors: F. Poulet (IAS)
;         
; -------------------------------------------------------------
; PURPOSE:
; -------------------------------------------------------------
;       Compute spectral criteria maps from processed OMEGA or
;       CRISM surface reflectance data
;
; -------------------------------------------------------------
; VERSION HISTORY:
; -------------------------------------------------------------
;       Ver 2.2 - july 2010
;         - Updated spectral criteria
;         - Added MAFIC keyword
;         - Removed spectral continuum handling
;
;       Ver 2.1 - march 2010
;         - Continuum removal, despiking and destriping applets
;           removed from program. Applets are run prior to exec
;         - Added 'continuum' input for processing continuum
;           removed data
;         - Added mono-hydrated sulfate spectral criterion
;
;       Ver 2.0 - feb 2010
;         - Improved time efficiency +220%
;         - Improved continuum removal 
;         - Removed non-browse product map computation
;         - Added destriping option
;
;       Ver 1.x - 2008-2009
;         - Revamped
;
;       Original version - may 2008
;
; -------------------------------------------------------------
; CALLING SEQUENCE:
; -------------------------------------------------------------
;       IDL>criteria, wvlarr,hdat, bandcube, namecube, 
;                     bad_spectel, continuum [,/CRISM ,/MAFIC]
;  
; -------------------------------------------------------------
; INPUTS:
; -------------------------------------------------------------
;       wvlarr      : the OMEGA 1D or CRISM 2D wavelength arrays
;       hdat        : the OMEGA or CRISM processed albedo cube
;       bandcube    : the output spectral criteria map cube
;       namecube    : data description for output_cube
;       bad_spectel : 1D list of bad spectels for observation
;       
; -------------------------------------------------------------
; OPTIONAL KEYWORDS:
; -------------------------------------------------------------
;       /CRISM   : required when processing CRISM data
;                  do not set when using OMEGA data
;       /MAFIC   : only compute mafic bands (very fast)           
; -------------------------------------------------------------;   


PRO CRITERIA,wvlarr,hdat,bandcube,namecube,bad_spectel,CRISM=CRISM,MAFIC=MAFIC,SILENT=SILENT,NOBS=NOBS


; ---------------------------------------
; Check data consistency
; ---------------------------------------
if n_elements(wvlarr) lt 1 or n_elements(hdat) lt 1  then begin
    print,'<!> Error : No data'
    goto,finish
endif

hdat=reform(hdat)
wvlarr=reform(wvlarr)
data_size=size(hdat,/dimensions)

if n_elements(data_size) eq 2 or n_elements(data_size) gt 3 then begin
print,'<!> Bad data'
goto,finish
endif

if n_elements(data_size) eq 3 then begin
    size_x=data_size(0)
    size_y=data_size(2)
    size_l=data_size(1)
endif
if n_elements(data_size) eq 1 then begin
    size_x=1
    size_y=1
    size_l=data_size(0)
    temp=fltarr(1,size_l,2)
    temp=fltarr(1,size_l,1)
    temp=reform(temp,1,size_l,1)
    temp(0,*,0)=hdat(*)
    hdat=temp
    temp=0b
endif

if keyword_set(CRISM) then begin
    check_wave=size(wvlarr,/dimensions)
    if (check_wave(0) ne size_x or check_wave(1) ne size_l) and size_x ne 1 then begin
        print,'<!> Error : Wrong CRISM wavelength array'
        goto,finish
    endif
endif
if not keyword_set(CRISM) then wvlarr=wvlarr(0:size_l-1)


; ---------------------------------------
; DEAL WITH BAD SPECTELS
; ---------------------------------------

if n_elements(bad_spectel) le 1 then bad_spectel=-1
if not keyword_set(NOBS) then begin
    if keyword_set(CRISM) then add_bad=where(wvlarr(size_x/2,*) lt 0.4 or wvlarr(size_x/2,*) gt 5.,count_bad)
    if not keyword_set(CRISM) then add_bad=where(wvlarr(*) lt 0.4 or wvlarr(*) gt 5.,count_bad)
    if count_bad gt 0 then bad_spectel=[bad_spectel,add_bad]
    
    x_min=fix(max([size_x/2.-8.,0.]))
    x_max=fix(min([size_x/2.+8.,size_x-1.]))
    y_min=fix(max([size_y/2.-8.,0.]))
    y_max=fix(min([size_y/2.+8.,size_y-1.]))
    slice=hdat(x_min:x_max,*,y_min:y_max)
    slice_size=float(x_max-x_min+1.)*float(y_max-y_min+1.)
    for l=0,size_l-1 do begin
        tmp=where(slice(*,l,*) le 0.01 or slice(*,l,*) gt 2.,count)
        if count gt fix(slice_size/2.) then bad_spectel=[bad_spectel,l]
    endfor
    
    if n_elements(bad_spectel) gt 1 then begin
        bad_spectel=bad_spectel(sort(bad_spectel))
        bad_spectel=bad_spectel(uniq(bad_spectel))
        bad_spectel=bad_spectel(sort(bad_spectel))
        if n_elements(bad_spectel) gt 1 then begin
            if bad_spectel(0) eq -1 then bad_spectel=bad_spectel(1:*)
            check_bad_spectel=where(bad_spectel ge size_l,countchk)
            if countchk gt 0 then bad_spectel=bad_spectel(0:min(check_bad_spectel)-1)
            if bad_spectel(0) eq 0 and n_elements(bad_spectel) gt 1 then bad_spectel=bad_spectel(1:*)
            tmp_wv=indgen(size_l)
            tmp_wv(bad_spectel)=-9999
            if n_elements(bad_spectel) le 0.75*size_l then begin
                for b=0,n_elements(bad_spectel)-1 do begin
                    tmp=sort(abs(tmp_wv-bad_spectel(b)))
                    hdat(*,bad_spectel(b),*)=0.5*hdat(*,tmp(0),*)+0.5*hdat(*,tmp(1),*)
                endfor
            endif
            if n_elements(bad_spectel) gt 0.75*size_l then bad_spectel=-1
        endif
    endif
    
    tmp=0 & tmp_wv=0 & slice=0 & slice_size=0
endif


; ---------------------------------------
; BEGIN LOOP FOR BAND MAP COMPUTATION
; ---------------------------------------
namecube = ['BD(1.9um)','BD(Kaolinite)','BD(Al)','BD(Fe)', 'BD(Mg-Chl)', 'BD(PHSulfates)', 'BD(Prehnite)', 'BD(MHSulfates)','BD(Opaline)','Olivine', 'Pyroxene', 'Plagioclase', 'BD(epidote)', 'BD(carbonates)','BD148']


data2=temporary(hdat)
;if keyword_set(CRISM) then data2=hdat
;if not keyword_set(CRISM) then data2=hdat



bandcube=fltarr(size_x,size_y,15)
tab=fltarr(400)
count_nomaf=0
count_maf=0
find_maf=-1
no_maf=-1
if not keyword_set(CRISM) then begin
    wv=wvlarr
    for t=0,399 do begin
        temp=min(abs(wv(*)-t*0.01),pos) 
        tab(t)=pos
    endfor
endif


; ---------------------------------------
; COMPUTE MAFIC BANDS 
; ---------------------------------------
if keyword_set(CRISM) then begin
    tmp=min(abs(wvlarr(size_x/2,*)-1.03),w103)
    tmp=min(abs(wvlarr(size_x/2,*)-1.10),w110)
    tmp=min(abs(wvlarr(size_x/2,*)-1.21),w121)
    tmp=min(abs(wvlarr(size_x/2,*)-1.26),w126)
    tmp=min(abs(wvlarr(size_x/2,*)-1.33),w133)
    tmp=min(abs(wvlarr(size_x/2,*)-1.35),w135)
    tmp=min(abs(wvlarr(size_x/2,*)-1.40),w140)
    tmp=min(abs(wvlarr(size_x/2,*)-1.46),w146)
    tmp=min(abs(wvlarr(size_x/2,*)-1.43),w143)
    tmp=min(abs(wvlarr(size_x/2,*)-1.48),w148)
    tmp=min(abs(wvlarr(size_x/2,*)-1.53),w153)
    tmp=min(abs(wvlarr(size_x/2,*)-1.55),w155)
    tmp=min(abs(wvlarr(size_x/2,*)-1.70),w170)
    tmp=min(abs(wvlarr(size_x/2,*)-1.75),w175)
    tmp=min(abs(wvlarr(size_x/2,*)-1.81),w181)
    tmp=min(abs(wvlarr(size_x/2,*)-1.85),w185)
    tmp=min(abs(wvlarr(size_x/2,*)-2.15),w215)
    tmp=min(abs(wvlarr(size_x/2,*)-2.08),w208)
    tmp=min(abs(wvlarr(size_x/2,*)-1.54),w154)
    tmp=min(abs(wvlarr(size_x/2,*)-2.48),w248)
    tmp=min(abs(wvlarr(size_x/2,*)-2.58),w258)
endif

if not keyword_set(CRISM) then begin
    tmp=min(abs(wvlarr(*)-1.03),w103)
    tmp=min(abs(wvlarr(*)-1.10),w110)
    tmp=min(abs(wvlarr(*)-1.21),w121)
    tmp=min(abs(wvlarr(*)-1.26),w126)
    tmp=min(abs(wvlarr(*)-1.33),w133)
    tmp=min(abs(wvlarr(*)-1.35),w135)
    tmp=min(abs(wvlarr(*)-1.40),w140)
    tmp=min(abs(wvlarr(*)-1.46),w146)
    tmp=min(abs(wvlarr(*)-1.55),w155)
    tmp=min(abs(wvlarr(*)-1.70),w170)
    tmp=min(abs(wvlarr(*)-1.75),w175)
    tmp=min(abs(wvlarr(*)-1.81),w181)
    tmp=min(abs(wvlarr(*)-1.85),w185)
    tmp=min(abs(wvlarr(*)-2.15),w215)
    tmp=min(abs(wvlarr(*)-2.08),w208)
    tmp=min(abs(wvlarr(*)-1.54),w154)
    tmp=min(abs(wvlarr(*)-2.48),w248)
    tmp=min(abs(wvlarr(*)-2.58),w258)
endif


dat103=0.25*data2(*,w103,*)+0.25*data2(*,max([w103-1,0]),*)+0.25*data2(*,w103+1,*)+0.25*data2(*,w103+2,*)
dat110=0.25*data2(*,w110,*)+0.25*data2(*,w110-1,*)+0.25*data2(*,w110+1,*)+0.25*data2(*,w110+2,*)
dat121=0.25*data2(*,w121,*)+0.25*data2(*,w121-1,*)+0.25*data2(*,w121+1,*)+0.25*data2(*,w121+2,*)
dat126=0.25*data2(*,w126,*)+0.25*data2(*,w126-1,*)+0.25*data2(*,w126+1,*)+0.25*data2(*,w126+2,*)
dat135=0.25*data2(*,w135,*)+0.25*data2(*,w135-1,*)+0.25*data2(*,w135+1,*)+0.25*data2(*,w135+2,*)
dat140=0.25*data2(*,w140,*)+0.25*data2(*,w140-1,*)+0.25*data2(*,w140+1,*)+0.25*data2(*,w140+2,*)
dat143=0.25*data2(*,w143,*)+0.25*data2(*,w143-1,*)+0.25*data2(*,w143+1,*)+0.25*data2(*,w143+2,*)
dat148=0.25*data2(*,w148,*)+0.25*data2(*,w148-1,*)+0.25*data2(*,w148+1,*)+0.25*data2(*,w148+2,*)
dat153=0.25*data2(*,w153,*)+0.25*data2(*,w153-1,*)+0.25*data2(*,w153+1,*)+0.25*data2(*,w153+2,*)
dat154=0.25*data2(*,w154,*)+0.25*data2(*,w154-1,*)+0.25*data2(*,w154+1,*)+0.25*data2(*,w154+2,*)
dat170=0.25*data2(*,w170,*)+0.25*data2(*,w170-1,*)+0.25*data2(*,w170+1,*)+0.25*data2(*,w170+2,*)
dat181=0.25*data2(*,w181,*)+0.25*data2(*,w181-1,*)+0.25*data2(*,w181+1,*)+0.25*data2(*,w181+2,*)
dat185=0.25*data2(*,w185,*)+0.25*data2(*,w185-1,*)+0.25*data2(*,w185+1,*)+0.25*data2(*,w185+2,*)
dat208=0.25*data2(*,w208,*)+0.25*data2(*,w208-1,*)+0.25*data2(*,w208+1,*)+0.25*data2(*,w208+2,*)
dat215=0.25*data2(*,w215,*)+0.25*data2(*,w215-1,*)+0.25*data2(*,w215+1,*)+0.25*data2(*,w215+2,*)
dat248=0.25*data2(*,w248,*)+0.25*data2(*,w248-1,*)+0.25*data2(*,w248+1,*)+0.25*data2(*,w248+2,*)
dat258=0.25*data2(*,w258,*)+0.25*data2(*,w258-1,*);+0.25*data2(*,w258+1,*)+0.25*data2(*,w258+2,*)
dat258=dat258*2.

; pyroxene
pyroxene=reform(1.-(0.3333*dat185+0.3333*dat215+0.3333*dat208)/(0.25*dat154+0.25*dat248+0.25*dat258+0.25*dat135))

; olivine
olivine=reform(1.-(0.5*dat135+0.5*dat140)/(0.5*dat170+0.5*dat181))

; plagioclase, 
plagioclase=reform(1.-(0.2*dat121+0.8*dat126)/(0.25*dat154+0.75*dat110))


bandcube(*,*,9)=OLIVINE
bandcube(*,*,10)=PYROXENE
bandcube(*,*,11)=PLAGIOCLASE


if not keyword_set(MAFIC) then begin

for i=0,size_x-1 do begin

if keyword_set(CRISM) then begin
    wv=reform(wvlarr(i,*))
    for t=0,399 do begin
        temp=min(abs(wv(*)-t*0.01),pos) 
        tab(t)=pos
    endfor
    check_wv=where(tab(100:*) ge 437. or tab(100:*) le 0.,count_bad_wv)
    if count_bad_wv gt size_l/2. then continue
endif

; ---------------------------------------
; COMPUTE HYDROUS MINERAL BAND MAPS
; ---------------------------------------

; fe phyllosilicate
band=median(data2(i,tab(228):tab(231),*),dimension=2)
cont=0.5*median(data2(i,tab(217):tab(224),*),dimension=2)+0.5*median(data2(i,tab(235):tab(235)+4,*),dimension=2)
bdfe=reform(1.-band/cont)

; mg phyllosilicate, chlorite, prehnite
band=median(data2(i,tab(230):tab(233),*),dimension=2)
cont=median(data2(i,tab(210):tab(223),*),dimension=2)
bdmg2=reform(1.-band/cont)


; mg phyllosilicate, chlorite, prehnite
band=median(data2(i,tab(229):tab(233),*),dimension=2)
cont=median(data2(i,tab(208):tab(218),*),dimension=2)
bdmg=reform(1.-band/cont)

; prehnite with 1.48
band=median(data2(i,tab(146):tab(149),*),dimension=2)
cont=0.5*median(data2(i,tab(142):tab(143),*),dimension=2)+0.5*median(data2(i,tab(151)-1:tab(153),*),dimension=2)
bd148=reform(1.-band/cont)

; al phyllosilicate - 'kaolinite'
band=median(data2(i,tab(216):tab(219),*),dimension=2)
cont=0.5*median(data2(i,tab(205):tab(215),*),dimension=2)+0.5*median(data2(i,tab(223)-1:tab(228),*),dimension=2)
bdkao=reform(1.-band/cont)

; al phyllosilicate - 'montmorillonite' + prehnite/chlorite
band=median(data2(i,tab(220):tab(225),*),dimension=2)
cont=0.5*median(data2(i,tab(213):tab(217),*),dimension=2)+0.5*median(data2(i,tab(225):tab(229),*),dimension=2)
bdal=reform(1.-band/cont)

; al opaline silica
band=median(data2(i,tab(220):tab(230),*),dimension=2)
cont=0.4*median(data2(i,tab(205):tab(215),*),dimension=2)+0.6*median(data2(i,tab(235):tab(240),*),dimension=2)
bdop=reform(1.-band/cont)


; common hydrous minerals (1.9µm band)
band=median(data2(i,tab(191):tab(194)+1,*),dimension=2)
cont=0.5*median(data2(i,tab(173):tab(185),*),dimension=2)+0.5*median(data2(i,tab(210):tab(216),*),dimension=2)
bd19=reform(1.-band/cont)

; sulfates and phyllosilicates (2.4 µm drop)
band=median(data2(i,tab(242):tab(255),*),dimension=2)
cont=median(data2(i,tab(215):tab(230),*),dimension=2)
bdall=reform(1.-band/cont)

; prehnite (2.35 µm band)
band=median(data2(i,tab(234):tab(237),*),dimension=2)
cont=0.5*median(data2(i,tab(226):tab(231),*),dimension=2)+0.5*median(data2(i,tab(244):tab(248),*),dimension=2)
bdpre=reform(1.-band/cont)

; epidote band (2.33 µm band)
band=median(data2(i,tab(232):tab(237),*),dimension=2)
cont=0.25*median(data2(i,tab(224):tab(228),*),dimension=2)+0.75*median(data2(i,tab(239):tab(243),*),dimension=2)
bdepi=reform(1.-band/cont)

; carbonate band (2.5 µm band)
band=median(data2(i,tab(247):tab(253),*),dimension=2)
cont=0.5*median(data2(i,tab(237):tab(242),*),dimension=2)+0.5*median(data2(i,tab(258):tab(263),*),dimension=2)
bdcarb=reform(1.-band/cont)

; poly hydrated sulfates
band=median(data2(i,tab(243):tab(250),*),dimension=2)
cont=median(data2(i,tab(228):tab(235),*),dimension=2)
bdpsul=reform(1.-band/cont)


; mono hydrated sulfates (2.1 µm broad band)
band=median(data2(i,tab(209):tab(216),*),dimension=2)
cont=0.5*median(data2(i,tab(185):tab(195),*),dimension=2)+0.5*median(data2(i,tab(220):tab(224),*),dimension=2)
bdmsul=reform(1.-band/cont)



; ---------------------------------------
; BUILD BAND MAP CUBE
; ---------------------------------------
bandcube(i,*,0)=BD19
bandcube(i,*,1)=BDKAO
bandcube(i,*,2)=BDAL
bandcube(i,*,3)=BDFE
bandcube(i,*,4)=BDMG
bandcube(i,*,5)=BDPSUL
bandcube(i,*,6)=BDPRE;BDALL
bandcube(i,*,7)=BDMSUL
bandcube(i,*,8)=BDOP
bandcube(i,*,12)=BDEPI
bandcube(i,*,13)=BDCARB
bandcube(i,*,14)=BD148
if not keyword_set(SILENT) then begin
if i eq fix(size_x/10.) then print,'   10 %'
if i eq 2*fix(size_x/10.) then print,'   20 %'
if i eq 3*fix(size_x/10.) then print,'   30 %'
if i eq 4*fix(size_x/10.) then print,'   40 %'
if i eq 5*fix(size_x/10.) then print,'   50 %'
if i eq 6*fix(size_x/10.) then print,'   60 %'
if i eq 7*fix(size_x/10.) then print,'   70 %'
if i eq 8*fix(size_x/10.) then print,'   80 %'
if i eq 9*fix(size_x/10.) then print,'   90 %'
if i eq 10*fix(size_x/10.) then print,'   100 %'
endif
Endfor
endif




hdat=temporary(data2)


finish:
END
