topColor = !D.Table_Size-1
LoadCT, 3, NColors=!D.Table_Size-1
TvLCT, 255, 255, 0, topColor
TV, BytScl(image, Top=!D.Table_Size-2)
!Mouse.Button = 1

   ; Go into XOR mode.

Device, Set_Graphics_Function=6

   ; Get initial cursor location. Draw cross-hair.

Cursor, col, row, /Device, /Down
PlotS, [col,col], [0,360], /Device, Color=topColor
PlotS, [0,360], [row,row], /Device, Color=topColor
Print, 'Pixel Value: ', image[col, row]

   ; Loop.

REPEAT BEGIN

      ; Get new cursor location.

   Cursor, colnew, rownew, /Down, /Device

      ; Erase old cross-hair.

   PlotS, [col,col], [0,360], /Device, Color=topColor
   PlotS, [0,360], [row,row], /Device, Color=topColor
   Print, 'Pixel Value: ', image(colnew, rownew)

      ; Draw new cross-hair.

   PlotS, [colnew,colnew], [0,360], /Device, Color=topColor
   PlotS, [0,360], [rownew,rownew], /Device, Color=topColor

      ; Update coordinates.

   col = colnew
   row = rownew
ENDREP UNTIL !Mouse.Button NE 1

   ;Erase the final cross-hair.

PlotS, [col,col], [0,360], /Device, Color=topColor
PlotS, [0,360], [row,row], /Device, Color=topColor

   ; Restore normal graphics function.

Device, Set_Graphics_Function=3
END
