; NAME:     READ_CRISM_LBL
;
; PURPOSE:
;     The READ_LBL procedure reads CRISM LBL files in PDS format.
;     Parameters are retrieved by specifying the related keywords.
;
; CALLING SEQUENCE:
;     read_crism_lbl, filename,keywords, values
;
; INPUTS:
;    filename: data file name (with path)
;    keywords: string array containing the list of keyword
;
; OUTPUTS:
;    values: string array with same dimensions as the keywords argument;  
;            holds output values as strings.
;            Returns empty string element ('') if file or requested keyword
;            is not found.
;
; NOTES: 
; --program first checks for label file, if not found, '-1' is returned
;
; CREATED: March 2006
;      BY: S. Pelkey
;
; MODIFICATION HISTORY:
; 07-MAR-2006, SMP: Adapted from OMEGA read_geolbl written by N.Manaud.
; 20-JUN-2006, SMP: Modified to handle multi-line "BAND_NAME" in 
;                   *DDR*LBL files
; 25-JUL-2006, SMP: Added ability for user to point to LBL file if not
;                   automatically found.
; 08-AUG-2006, SMP: Made compatible with Windows platform
; 31-OCT-2006, SMP: Added more refined check of platform.
; 20-MAR-2007, SMP: Modified to handle multi-line "BAND_NAME" for any
;                   standard CRISM product that would have them (I think!)
;                   

PRO read_crism_lbl, lblfile,keywords, values

nitems = n_elements(keywords)
values = strarr(nitems)

; Test for file:
test=file_search(lblfile)

; If not found then return:
if (test[0] eq '') or (lblfile eq '') then return

; If LBL file present, parse to get info...

; Check if need to deal with band names:
pos=strpos(lblfile,'DDR') > strpos(lblfile,'SU') > strpos(lblfile,'MRRDE') > strpos(lblfile,'MRRSP') 
if (pos ne -1) then pdsbands=1 else pdsbands=0

; Open file:
openr, unit, lblfile, /GET_LUN

line    = ''

WHILE (STRTRIM(line,2) NE 'END') DO BEGIN
  ;Read the header one line at a time
  readf, unit, line
  len=strlen(line)
  i = strpos(line,' = ')
  if ( i ne -1 ) then begin
    keyword = strtrim(strmid(line,0,i),2) ;all to the left of =
    value   = strmid(line,i+3,len-i-2)    ;all to the right of =
    for j=0,nitems-1 do begin
      if ( keywords(j) eq keyword ) then begin
        if (keyword eq 'BAND_NAME') and (pdsbands eq 1) then begin
          bands=value
          while (strpos(line,')') eq -1) do begin
            readf, unit, line
            bands=bands+strtrim(line,2)
          endwhile
          values(j)=bands  
        endif else values(j) = value
      endif
    endfor
 endif
ENDWHILE

close,    unit
free_lun, unit


END
