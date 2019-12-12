# readcrism
IDL script to pre-process CRISM images, including denoising and calculating ratioed image and spectral parameters.

main script*: readcrism.pro

subroutines:
despike.pro remove spikes in spectral domain
destripe.pro remove stripes in spatial domain
criteria.pro calculate spectral parameters with three different continuum removing methods


*These routines depend on astron and coyote IDL packages

The script runs on IDL with the input of CRISM target file and data labels.
The results are output to a .sav file

This .save file can be read into an ENVI format via crism2envi.pro (which requires ENVI+CAT software)



Reference:
Carter et al., 2012
Pan et al., 2017

