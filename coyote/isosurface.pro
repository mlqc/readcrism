
Plot, Histogram(head), Max_Value=5000
Empty
Shade_Volume, head, 50, vertices, polygons, /Low
Scale3, XRange=[0,xs], YRange=[0,ys], ZRange=[0,zs]
isosurface = PolyShade(vertices, polygons, /T3D)
LoadCT, 0, NColors=topColor+1
TV, isosurface
Shade_Volume, head(*,*,0:zpt), 50, vertices, polygons, /Low
isosurface = PolyShade(vertices, polygons, /T3D)
isosurface(Where(isosurface EQ 0)) = topColor+1
TvLCT, 70, 70, 70, topColor+1
Set_Plot, 'Z', /Copy
TV, isosurface
Scale3, XRange=[0,xs], YRange=[0,ys], ZRange=[0,zs]
Polyfill, zplane, /T3D, Pattern=zimage, /Image_Interp, $
   Image_Coord=[ [0,0], [xs, 0], [xs, ys], [0, ys] ], $
   Transparent=25
picture = TVRD()
Set_Plot, thisDevice
TV, picture
