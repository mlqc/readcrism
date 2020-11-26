topColor = !D.Table_Size-1
LoadCT, 3, NColors=!D.Table_Size-1
TvLCT, 255, 255, 0, topColor
TV, BytScl(image, Top=!D.Table_Size-2)
!Mouse.Button = 1
REPEAT BEGIN
   Cursor, col, row, /Down, /Device
   Print, 'Pixel Value: ', image[col, row]
ENDREP UNTIL !Mouse.Button NE 1
END