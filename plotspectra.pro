pro plotspectra,img,line,sample,wvlc,name

sizeofscene = size(img);
x=sizeofscene(1);
l=sizeofscene(2);
y=sizeofscene(3);
endl = 256;
spec = img(line,10:endl,sample)
wvl = wvlc(line,10:endl)
;PLOT(spec,'g2',/FILL_BACKGROUND,FILL_LEVEL=0,FILL_COLOR='white',YRANGE=[0.1,0.2])
; Create the plot
plot = PLOT(wvl,spec, "k", TITLE="Spectral plot")

; Set some properties
;plot.SYM_INCREMENT = 10
;plot.SYM_COLOR = "blue"
;plot.SYM_FILLED = 1
;plot.SYM_FILL_COLOR = 0
;plot.FILL_COLOR = 'white'
plot.XRANGE=[1,2.6]
plot.YRANGE=[median(spec)-0.05,median(spec)+0.05]
;PLOT.YRANGE = [0,600]
ax = plot.AXES
ax[0].TITLE = 'Wavelength (micron)'
ax[1].TITLE = 'CRISM I/F'
;PLOT(wvl,spec,'g2',/FILL_BACKGROUND,FILL_LEVEL=0,FILL_COLOR='white',XRANGE=[wvlc(122,10),wvlc(122,240)],YRANGE=[0.1,0.2])
plot.Save, name+".eps", BORDER=5, $
  RESOLUTION=300, /TRANSPARENT
end