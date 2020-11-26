Set_Plot, 'Z'
Erase, Color=topColor + 1
Polyfill, xplane, /T3D, Pattern=ximage, /Image_Interp, $
   Image_Coord=[ [0,0], [0, zs], [ys, zs], [ys, 0] ], $
   Transparent=25
Polyfill, yplane, /T3D, Pattern=yimage, /Image_Interp, $
   Image_Coord=[ [0,0], [0, zs], [xs, zs], [xs, 0] ], $
   Transparent=25
Polyfill, zplane, /T3D, Pattern=zimage, /Image_Interp, $
   Image_Coord=[ [0,0], [xs, 0], [xs, ys], [0, ys] ], $
   Transparent=25
picture = TVRD()
Set_Plot, thisDevice
Window, /Free, XSize=400, YSize=400
Erase, Color=topColor + 1
TV, picture
