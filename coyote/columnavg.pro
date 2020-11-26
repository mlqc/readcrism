PRO ColumnAvg, image

On_Error, 2

   ; Make  sure an image is available.

IF N_Elements(image) EQ 0 THEN image = LoadData(7)

   ; Find the size of the image.

ndims = Size(image, /N_Dimensions)
IF ndims NE 2 THEN Message, 'Image parameter must be 2D. Returning...'
s = Size(image, /Dimensions)
xsize = s[0]
ysize = s[1]

   ; Load colors for graphic.

backColor = GetColor('gray', !D.Table_Size-2)
axisColor = GetColor('navy', !D.Table_Size-3)
dataColor = GetColor('green', !D.Table_Size-4)
LoadCT, 33, NColors=!D.Table_Size-4

   ; Save system variables.

theFont = !P.Font
thePlots = !P.Multi

   ; Set system variables and create the data.

!P.Font = 0
!P.Multi=[0,1,2]
columnData = Total(image,2)/ysize

   ; Draw the plots.

Plot, columnData, /NoData, Color=axisColor, $
   Background=backColor, XStyle=1, XRange=[0,xsize-1], $
   Title='Column Average Value', XTitle='Column Number'
OPlot, columnData, Color=dataColor
TVImage, BytScl(image, Top=!D.Table_Size-5)

   ; Restore  system variables.

!P.Multi = thePlots
!P.Font = theFont
END