# readcrism
IDL script to pre-process CRISM images, including denoising and calculating ratioed image and spectral parameters.

main script*: readcrism.pro

To run the main script, the path file named "mypaths.def" needs to be updated and saved. 

>> @mypaths.def
>> save,filename = 'mypaths.sav'

The CRISM image IDs should be listed in a text file (See the sample file list). 
Then the script would run automatically:
>> readcrism,file.list

readcrism.pro includes these main procedures:

1. Read CRISM image file and label file (Run atmosphere and geometric correction if not already done)
2. Despike CRISM I/F image (despike.pro)
3. Run spectral parameter on the despiked image cube (criteria.pro)
4. Calculate image ratio using the boring pixels
5. Remove stripes for the ratioed image
6. Calculate spectral parameters on the ratioed cube
7. Save three image files and relevant label information including:
  a) Despiked I/F image
  b) Ratioed CRISM image 
  c) New CRISM spectral parameters


important subroutines:
despike.pro remove spikes in spectral domain
destripe.pro remove stripes in spatial domain
criteria.pro calculate spectral parameters with three different continuum removing methods


*These routines depend on astron and coyote IDL packages

The script runs on IDL with the input of CRISM target file and data labels.
The results are output to a .sav file
This .sav file can be read into an ENVI format via crism2envi.pro (which requires ENVI software)

The output files from crism2envi.pro are in the format of ENVI image format. (.img) with associated CAT (CRISM Analysis Toolkit) label, which is compatible for additional processing using the CAT toolkit. 


Reference:
Carter et al., 2012;
Pan et al., 2017

CAT (CRISM Analysis Toolkit) is a freely available IDL-based software developed by the CRISM team (JHUAPL) which can be integrated with ENVI software. The newest version is available on the PDS geoscience node website (https://pds-geosciences.wustl.edu/missions/mro/crism.htm).
