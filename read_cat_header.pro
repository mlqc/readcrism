;******************************************************************************
;
; function read_cat_header
;
; Read CAT custom parameters from an open CAT/ENVI header. 
; Keyword values transfered via output keywords.
;
; INPUT PARAMETERS:
;	fid        ENVI file ID for an open file associated with the header to be read.
;
; OUTPUT: No parameters
;
; RETURN VALUE: int status...
;	 0   success
;	-1   File not open
;
; KEYWORDS:
;	Operational keywords:
;		BATCH               No interactive dialog
;	Parameter keywords:
;		CAT_START_TIME            string   Obs start date 'yyyy-mm-ddThh:mm:ss.fff'
;		CAT_SCLK_START            string   Obs start SCLK 'p/tttttttttt'
;		CAT_CRISM_OBSID           string   CRISM observation ID string
;		CAT_OBS_TYPE              string   CRISM obs type (FRT, MSP, etc)
;		CAT_PRODUCT_VERSION       string   Cal version; from PDS PRODUCT_VERSION_ID
;		CAT_CRISM_DETECTOR_ID     string   CRISM detector ('L', 'S', 'J')
;		CAT_BIN_MODE              int      Detector bin mode (numeric code from PDS label)
;		CAT_WAVELENGTH_FILTER     int      Wavelength filter (numeric code from PDS label)
;		CAT_CRISM_DETECTOR_TEMP   float    CRISM detector temperature (C)
;		CAT_CRISM_BENCH_TEMP      float    CRISM optical bench temperature (C)
;		CAT_CRISM_HOUSING_TEMP    float    CRISM spectrometer housing temperature (C)
;		CAT_SOLAR_LONGITUDE       float    Observation solar longitude (L_S; degrees)
;		CAT_PDS_LABEL_FILE        str[arr] Label file of initial PDS file, with path
;		                                   (could be multiple files after merging)
;		CAT_SPECTRUM_RESAMPLED    int      Flag whether data are resampled (1) or not (0)
;		CAT_TILE_WAVE_FILE        string   For tiles - wavelength file
;		CAT_SWEETSPOT_WAVE_FILE   string   For non-tiles - sweetspot wavelength file
;		CAT_WA_WAVE_FILE          string   For non-tiles - WA wavelength file (full array)
;		CAT_IR_WAVES_REVERSED     string   'YES', IR wavelength array reversed so low 
;		                                   wavelengths first; 'NO', not reversed.
;		CAT_HISTORY               string   CAT processing steps
;		CAT_INPUT_FILES           strarr   containing input files for each CAT 
;	 	                                   processing step
;
; NOTES:
;	CAT parameter keywords are returned as strings with the following exceptions: 
;	      Keyword                Type     Value if Invalid
;	   CAT_BIN_MODE               int           -1
;	   CAT_WAVELENGTH_FILTER      int           -1
;	   CAT_CRISM_DETECTOR_TEMP   float        65535.0
;	   CAT_CRISM_BENCH_TEMP      float        65535.0
;	   CAT_CRISM_HOUSING_TEMP    float        65535.0
;	   CAT_SOLAR_LONGITUDE       float        65535.0
;	   CAT_SPECTRUM_RESAMPLED     int           -1
;
;	When other parameters are not present, the returned value is an int = -1.
;	(ENVI default behavior.) (Including keywords returned as strings when present.)
;
; TYPICAL CALL:
;
; USES:
;
; HISTORY:
;	2009 Nov 06 F. Morgan: First version written.
;	2009 Nov 10 F. Morgan: More keywords.
;	2010 Nov 17 F. Morgan: add CAT_PRODUCT_VERSION keyword
;	2010 Nov 18 F. Morgan: New parameters: cat_start_time, cat_sclk_start, 
;	            cat_crism_obsid, cat_obs_type
;
;******************************************************************************

function read_cat_header, fid, $
	CAT_START_TIME          = cat_start_time, $
	CAT_SCLK_START          = cat_sclk_start, $
	CAT_CRISM_OBSID         = cat_crism_obsid, $
	CAT_OBS_TYPE            = cat_obs_type, $
	CAT_PRODUCT_VERSION     = cat_product_version, $
	CAT_CRISM_DETECTOR_ID   = cat_crism_detector_id, $
	CAT_BIN_MODE            = cat_bin_mode, $
	CAT_WAVELENGTH_FILTER   = cat_wavelength_filter, $
	CAT_CRISM_DETECTOR_TEMP = cat_crism_detector_temp, $
	CAT_CRISM_BENCH_TEMP    = cat_crism_bench_temp, $
	CAT_CRISM_HOUSING_TEMP  = cat_crism_housing_temp, $
	CAT_SOLAR_LONGITUDE     = cat_solar_longitude, $
	CAT_PDS_LABEL_FILE      = cat_pds_label_file, $
	CAT_SPECTRUM_RESAMPLED  = cat_spectrum_resampled, $
	CAT_TILE_WAVE_FILE      = cat_tile_wave_file, $
	CAT_SWEETSPOT_WAVE_FILE = cat_sweetspot_wave_file, $
	CAT_WA_WAVE_FILE        = cat_wa_wave_file,  $
	CAT_IR_WAVES_REVERSED   = cat_ir_waves_reversed, $
	CAT_HISTORY             = cat_history, $
	CAT_INPUT_FILES         = cat_input_files, $
	BATCH=batch


; Set everything invalid in case of failure:
cat_start_time = -1
cat_sclk_start = -1
cat_crism_obsid = -1
cat_obs_type = -1
cat_product_version = -1
cat_crism_detector_id = -1
cat_bin_mode = -1
cat_wavelength_filter = -1
cat_crism_detector_temp = 65535.0
cat_crism_bench_temp = 65535.0
cat_crism_housing_temp = 65535.0
cat_solar_longitude = 65535.0
cat_pds_label_file = -1
cat_spectrum_resampled = -1
cat_tile_wave_file = -1
cat_sweetspot_wave_file = -1
cat_wa_wave_file = -1
cat_ir_waves_reversed = -1
cat_history = -1
cat_input_files = -1


; Check fid, if not open, alert and return -1
fid_open = 1
if (n_elements(fid) eq 0) then begin
	fid_open = 0
endif else begin
	all_open = envi_get_file_ids()
	k = where((fid eq all_open),nk)
	if (nk eq 0) then fid_open=0
endelse
if (~fid_open) then begin
	if (~keyword_set(batch)) then begin
		msg = 'CAT attempting to read unopen header.' 
		ok = dialog_message(msg, title='CRISM Header fail')
	endif
	return,-1
endif

; Read parameters:
cat_start_time = envi_get_header_value(fid, 'cat start time')
cat_sclk_start = envi_get_header_value(fid, 'cat sclk start')
cat_crism_obsid = envi_get_header_value(fid, 'cat crism obsid')
cat_obs_type = envi_get_header_value(fid, 'cat obs type')
cat_product_version = envi_get_header_value(fid, 'cat product version')
cat_crism_detector_id = envi_get_header_value(fid, 'cat crism detector id')
cat_bin_mode = envi_get_header_value(fid, 'cat bin mode',/fix)
cat_wavelength_filter = envi_get_header_value(fid, 'cat wavelength filter',/fix)
cat_crism_detector_temp = envi_get_header_value(fid, 'cat crism detector temp', $
	undefined=udf, /float)
if (udf) then cat_crism_detector_temp=65535.0
cat_crism_bench_temp = envi_get_header_value(fid, 'cat crism bench temp', $
	undefined=udf, /float)
if (udf) then cat_crism_bench_temp=65535.0
cat_crism_housing_temp = envi_get_header_value(fid, 'cat crism housing temp', $
	undefined=udf, /float)
if (udf) then cat_crism_housing_temp=65535.0
cat_solar_longitude = envi_get_header_value(fid, 'cat solar longitude',	$
	undefined=udf, /float)
if (udf) then cat_solar_longitude=65535.0
cat_pds_label_file = envi_get_header_value(fid, 'cat pds label file')
cat_spectrum_resampled = envi_get_header_value(fid, 'cat spectrum resampled',/fix)
cat_tile_wave_file = envi_get_header_value(fid, 'cat tile wave file')
cat_sweetspot_wave_file = envi_get_header_value(fid, 'cat sweetspot wave file')
cat_wa_wave_file = envi_get_header_value(fid, 'cat wa wave file')
cat_ir_waves_reversed = envi_get_header_value(fid, 'cat ir waves reversed')
cat_history = envi_get_header_value(fid, 'cat history')
cat_input_files = envi_get_header_value(fid, 'cat input files')

return, 0
end
