topColor = !D.Table_Size-1
LoadCT, 3, NColors=!D.Table_Size-1
TvLCT, 255, 255, 0, topColor
TV, BytScl(image, Top=!D.Table_Size-2)
!Mouse.Button = 1

   ; Create a pixmap window and display image in it.

Window, 1, /Pixmap, XSize=360, YSize=360
TV, BytScl(image, Top=!D.Table_Size-2)

   ;Make the display window the current graphics window.

WSet, 0

   ; Get initial cursor location (static corner of box).

Cursor, sx, sy, /Device, /Down

   ; Loop.

REPEAT BEGIN

      ; Get new cursor location (dynamic corner of box).

   Cursor, dx, dy, /Wait, /Device

      ; Erase the old box.

   Device, Copy=[0, 0, 360, 360, 0, 0, 1]

      ; Draw the new box.

   PlotS, [sx,sx,dx,dx,sx], [sy,dy,dy,sy,sy], /Device, $
      Color=topColor


ENDREP UNTIL !Mouse.Button NE 1

   ;Erase the final box.

Device, Copy=[0, 0, 360, 360, 0, 0, 1]
END
