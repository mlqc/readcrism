head = LoadData(8)
s = Size(head)
xs = s(1) - 1
ys = s(2) - 1
zs = s(3) - 1
xpt = 40
ypt = 50
zpt = 27
xplane = [ [xpt, 0, 0], [xpt, 0, zs], [xpt, ys, zs], [xpt, ys, 0] ]
yplane = [ [0, ypt, 0], [0, ypt, zs], [xs, ypt, zs], [xs, ypt, 0] ]
zplane = [ [ 0, 0, zpt],[xs, 0, zpt], [xs, ys, zpt], [0, ys, zpt] ]
ximage = head(xpt, *, *)
yimage = head(*, ypt, *)
zimage = head(*, *, zpt)
ximage = Reform(ximage)
yimage = Reform(yimage)
zimage = Reform(zimage)
minData = Min(head, Max=maxData)
topColor = !D.N_Colors-2
LoadCT, 5, NColors=!D.N_Colors-1
TvLCT, 255, 255, 255, topColor+1
ximage = BytScl(ximage, Top=topColor, Max=maxData, Min=minData)
yimage = BytScl(yimage, Top=topColor, Max=maxData, Min=minData)
zimage = BytScl(zimage, Top=topColor, Max=maxData, Min=minData)
thisDevice = !D.Name
Set_Plot, 'Z'
Device, Set_Colors=topColor, Set_Resolution=[400,400]
Erase, Color=topColor + 1
Scale3, XRange=[0,xs], YRange=[0,ys], ZRange=[0,zs]
Polyfill, xplane, /T3D, Pattern=ximage, /Image_Interp, $
   Image_Coord=[ [0,0], [0, zs], [ys, zs], [ys, 0] ]
Polyfill, yplane, /T3D, Pattern=yimage, /Image_Interp, $
   Image_Coord=[ [0,0], [0, zs], [xs, zs], [xs, 0] ]
Polyfill, zplane, /T3D, Pattern=zimage, /Image_Interp, $
   Image_Coord=[ [0,0], [xs, 0], [xs, ys], [0, ys] ]
picture = TVRD()
Set_Plot, thisDevice
Window, XSize=400, YSize=400
TV, picture