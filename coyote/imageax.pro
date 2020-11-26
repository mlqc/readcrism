PRO ImageAx, image, Position=position

IF N_PARAMS() EQ 0 THEN Message, 'Must pass image argument.'
IF N_ELEMENTS(position) EQ 0 THEN $
position = [0.2, 0.2, 0.8, 0.8]

   ; Get the size of the image in pixel units.

s = SIZE(image)
imgXsize = s(1)
imgYsize = s(2)

   ; Calculate the size and starting locations in pixels.

xsize = (position(2) - position(0)) * !D.X_VSize
ysize = (position(3) - position(1)) * !D.Y_VSize
xstart = position(0) * !D.X_VSize
ystart = position(1) * !D.Y_VSize

   ; Size the image differently in PostScript.

IF !D.NAME EQ 'PS' THEN $
   TV, image, xstart, ystart, XSize=xsize, YSize=ysize ELSE $
TV, Congrid(image, xsize, ysize, /Interp), xstart, ystart

   ; Draw the axes around the image.

Plot, FIndGen(100), /NoData, /NoErase, Position=position
END
