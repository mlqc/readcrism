PRO BoxImage::BackgroundColor, Draw=draw, _Extra=extra

; This method changes the background color.

thisColorName = PickColorName(self.backcolor, Cancel=cancelled, $
   _Extra=extra, Title='Background Color')
IF cancelled THEN RETURN

self.backcolor = thisColorName

   ; Redraw the image if needed.

IF Keyword_Set(draw) THEN self->Draw

END ;--------------------------------------------------------------------



PRO BoxImage::AnnotateColor, Draw=draw, _Extra=extra

; This method changes the annotation color.

thisColorName = PickColorName(self.annotatecolor, Cancel=cancelled, $
   _Extra=extra, Title='Annotation Color')
IF cancelled THEN RETURN

self.annotatecolor = thisColorName

   ; Redraw the image if needed.

IF Keyword_Set(draw) THEN self->Draw

END ;--------------------------------------------------------------------



PRO BoxImage::LoadColorVectors, _Extra=extra

   ; Get the current color vectors.

TVLCT, r, g, b, /Get

   ; Pull out the image colors.

*self.r = r[0:self.ncolors-1]
*self.g = g[0:self.ncolors-1]
*self.b = b[0:self.ncolors-1]

   ; Redraw the image.

self->Draw

END ;--------------------------------------------------------------------



PRO BoxImage::XColors, _Extra=extra

   ; Load the current image colors.

TVLCT, *self.r, *self.g, *self.b

   ; Call XCOLORS and notify this object if colors change.

struct = { XCOLORS_NOTIFYOBJ, $
   object:self, $                 ; The object reference.
   method:'LoadColorVectors' }    ; The object method to call.

XColors, NotifyObj=struct, NColors=self.ncolors, _Extra=extra, $
   Title='Modify BoxImage Image Colors'

END ;--------------------------------------------------------------------



PRO BoxImage::GetProperty, $
   Image = image, $
   BackColor=backcolor, $
   AnnotateColor=annotatecolor, $
   ColorTable=colortable, $
   NColors=ncolors, $
   Position=position, $
   Vertical=vertical, $
   XScale=xscale, $
   XTitle=xtitle, $
   YScale=yscale, $
   YTitle=ytitle

; This method gets the properties of the object.

   ; Error handling.

Catch, theError
IF theError NE 0 THEN BEGIN
   Catch, /Cancel
   ok = Error_Message(!Error_State.Msg + ' Returning...', $
      Traceback=1, /Error)
   RETURN
ENDIF

   ; Set properties if keyword is present.

IF Arg_Present(colortable) THEN colortable = self.colortable
IF Arg_Present(backcolor) THEN backcolor = self.backcolor
IF Arg_Present(annotatecolor) THEN annotatecolor = self.annotatecolor
IF Arg_Present(ncolors) THEN ncolors = self.ncolors
IF Arg_Present(vertical) THEN vertical = self.vertical
IF Arg_Present(xtitle) THEN xtitle = self.xtitle
IF Arg_Present(ytitle) THEN ytitle = self.ytitle
IF Arg_Present(xscale) THEN xscale = self.xscale
IF Arg_Present(yscale) THEN yscale = self.yscale
IF Arg_Present(image) THEN image = *self.image

END ;--------------------------------------------------------------------



FUNCTION BoxImage::GetAnnotationColor

; This method returns the annotation color.

RETURN, self.annotatecolor

END ;--------------------------------------------------------------------



PRO BoxImage::SetProperty, $
   Image = image, $
   AnnotateColor=annotatecolor, $
   BackColor=backcolor, $
   ColorTable=colortable, $
   Draw=draw, $
   NColors=ncolors, $
   Position=position, $
   Vertical=vertical, $
   XScale=xscale, $
   XTitle=xtitle, $
   YScale=yscale, $
   YTitle=ytitle, $
   _Extra=extra

; This method sets the properties of the object.

   ; Error handling.

Catch, theError
IF theError NE 0 THEN BEGIN
   Catch, /Cancel
   ok = Error_Message(!Error_State.Msg + ' Returning...', $
      Traceback=1, /Error)
   RETURN
ENDIF

   ; Set properties if keyword is present.

IF N_Elements(backcolor) NE 0 THEN self.backcolor = backcolor
IF N_Elements(annotatecolor) NE 0 THEN self.annotatecolor = annotatecolor
IF N_Elements(ncolors) NE 0 THEN self.ncolors = ncolors
IF N_Elements(position) NE 0 THEN self.position = position
IF N_Elements(vertical) NE 0 THEN self.vertical = vertical
IF N_Elements(xtitle) NE 0 THEN self.xtitle = xtitle
IF N_Elements(ytitle) NE 0 THEN self.ytitle = ytitle
IF N_Elements(xscale) NE 0 THEN self.xscale = xscale
IF N_Elements(yscale) NE 0 THEN self.yscale = yscale
IF N_Elements(extra) NE 0 THEN *self.extra = extra
IF N_Elements(image) NE 0 THEN BEGIN
   *self.image = image
   *self.process = image
   *self.undo = image
ENDIF
IF N_Elements(colortable) NE 0 THEN BEGIN
   colors = Obj_New("IDLgrPalette")
   colors->LoadCT, 0 > colortable < 40
   colors->GetProperty, Red=r, Green=g, Blue=b
   Obj_Destroy, colors
   *self.r = Congrid(r, self.ncolors)
   *self.g = Congrid(g, self.ncolors)
   *self.b = Congrid(b, self.ncolors)
ENDIF

IF Keyword_Set(draw) THEN self->Draw

END ;--------------------------------------------------------------------



PRO BoxImage::LoadCT, colortable, Draw=draw

; This method loads a different color table for the image.

IF N_Elements(colortable) EQ 0 THEN BEGIN
   colors = Obj_New("IDLgrPalette")
   colors->LoadCT, 0
   colors->GetProperty, Red=r, Green=g, Blue=b
   Obj_Destroy, colors
ENDIF ELSE BEGIN
   colors = Obj_New("IDLgrPalette")
   colors->LoadCT, 0 > colortable < 40
   colors->GetProperty, Red=r, Green=g, Blue=b
   Obj_Destroy, colors
ENDELSE

*self.r = Congrid(r, self.ncolors)
*self.g = Congrid(g, self.ncolors)
*self.b = Congrid(b, self.ncolors)

   ; Redraw the image if needed.

IF Keyword_Set(draw) THEN self->Draw

END ;--------------------------------------------------------------------



PRO BoxImage::Draw, Font=font

; This method draws the graphics display.

   ; Error handling.

Catch, theError
IF theError NE 0 THEN BEGIN
   Catch, /Cancel
   ok = Error_Message(!Error_State.Msg + ' Returning...', $
      Traceback=1, /Error)
   RETURN
ENDIF

   ; Check keywords.

IF N_Elements(font) EQ 0 THEN font = !P.Font

   ; Obtain the annotate color.

annotateColor = GetColor(self.annotatecolor, !D.Table_Size-2)
backColor = GetColor(self.backColor, !D.Table_Size-3)

   ; Load the image colors.

TVLCT, *self.r, *self.g, *self.b

   ; Calculate the position of the image and color bar
   ; in the window.

IF self.vertical THEN BEGIN
   p = self.position
   length = p[2] - p[0]
   imgpos = [p[0], p[1], (p[2]-(0.20*length)), p[3]]
   cbpos =  [(p[0]+(0.93*length)), p[1], p[2], p[3]]
ENDIF ELSE BEGIN
   p = self.position
   length = p[3] - p[1]
   imgpos = [p[0], p[1], p[2], (p[3]-(0.20*length))]
   cbpos =  [p[0], (p[1]+(0.93*length)), p[2], p[3]]
ENDELSE

   ; Need to erase display? Only on displays with windows.

IF (!D.Flags AND 256) NE 0 THEN Erase, Color=backColor

   ; Calculate appropriate character size for plots.

thisCharsize = Str_Size('A Sample String', 0.25)

   ; Draw the graphics.

TVImage, BytScl(*self.process, Top=self.ncolors-1), $
   Position=imgpos, _Extra=*self.extra
Plot, self.xscale, self.yscale, XStyle=1, YStyle=1, $
   XTitle=self.xtitle, YTitle=self.ytitle, Color=annotateColor, $
   Position=imgpos, /NoErase, /NoData, Ticklen=-0.025, _Extra=*self.extra, $
   CharSize=thisCharSize, Font=font
Colorbar, Range=[Min(*self.process), Max(*self.process)], Divisions=8, $
   _Extra=*self.extra, Color=annotateColor, Position=cbpos, Ticklen=-0.2, $
   Vertical=self.vertical, NColors=self.ncolors, CharSize=thisCharSize, Font=font

END ;--------------------------------------------------------------------


Function BoxImage::Init, $        ; The name of the method.
   image, $                       ; The image data.
   AnnotateColor=annotatecolor, $ ; The annotation color.
   BackColor=backcolor, $         ; The background color.
   ColorTable=colortable, $       ; The colortable index.
   NColors=ncolors, $             ; Number of image colors.
   Position=position, $           ; Position in window.
   Vertical=vertical, $           ; Vertical colorbar flag.
   XScale=xscale, $               ; The scale on X axis.
   XTitle=xtitle, $               ; The title on X axis.
   YScale=yscale, $               ; The scale on Y axis.
   YTitle=ytitle, $               ; The title on Y axis.
   _Extra=extra                   ; Holds extra keywords.

; The initialization routine for the object. Create the
; particular instance of the object class.

   ; Error handling.

Catch, theError
IF theError NE 0 THEN BEGIN
   Catch, /Cancel
   ok = Error_Message(!Error_State.Msg + ' Returning...', $
      Traceback=1, /Error)
   RETURN, 0
ENDIF

   ; Check for positional parameter. Define if necessary.

IF N_Elements(image) EQ 0 THEN image = LoadData(7)
ndims = Size(image, /N_Dimensions)
IF ndims NE 2 THEN Message, 'Image must be 2D array.', /NoName

   ; Check for keyword parameters.

IF N_Elements(annotatecolor) EQ 0 THEN annotatecolor = "NAVY"
IF N_Elements(backcolor) EQ 0 THEN backcolor = "WHITE"
IF N_Elements(ncolors) EQ 0 THEN ncolors = !D.Table_Size - 3
IF N_Elements(position) EQ 0 THEN position = [0.15, 0.15, 0.9, 0.9]
vertical = Keyword_Set(vertical)
IF N_Elements(xtitle) EQ 0 THEN xtitle = ""
IF N_Elements(ytitle) EQ 0 THEN ytitle = ""

s = Size(image, /Dimensions)
IF N_Elements(xscale) EQ 0 THEN xscale = [0,s[0]]
IF N_Elements(yscale) EQ 0 THEN yscale = [0,s[1]]

IF N_Elements(colortable) EQ 0 THEN BEGIN
   colors = Obj_New("IDLgrPalette")
   colors->LoadCT, 0
   colors->GetProperty, Red=r, Green=g, Blue=b
   Obj_Destroy, colors
ENDIF ELSE BEGIN
   colors = Obj_New("IDLgrPalette")
   colors->LoadCT, 0 > colortable < 40
   colors->GetProperty, Red=r, Green=g, Blue=b
   Obj_Destroy, colors
ENDELSE

r = Congrid(r, ncolors)
g = Congrid(g, ncolors)
b = Congrid(b, ncolors)

   ; Populate the object.

self.image = Ptr_New(image)
self.process = Ptr_New(image)
self.undo = Ptr_New(image)
self.position = position
self.ncolors = ncolors
self.annotatecolor = annotatecolor
self.backcolor = backcolor
self.r = Ptr_New(r)
self.g = Ptr_New(g)
self.b = Ptr_New(b)
self.vertical = vertical
self.xscale = xscale
self.yscale = yscale
self.xtitle = xtitle
self.ytitle = ytitle
self.extra = Ptr_New(extra)

   ; Indicate successful initialization.

RETURN, 1

END ;--------------------------------------------------------------------



PRO BoxImage::Cleanup

; The clean-up routine for the object. Free all
; pointers.

Ptr_Free, self.image
Ptr_Free, self.process
Ptr_Free, self.undo
Ptr_Free, self.r
Ptr_Free, self.g
Ptr_Free, self.b
Ptr_Free, self.extra

END ;--------------------------------------------------------------------



PRO BoxImage__Define

; The definition of the BOXIMAGE object class.

struct = { BOXIMAGE, $              ; The BOXIMAGE object class.
           image: Ptr_New(), $      ; The original image data.
           process: Ptr_New(), $    ; The processed image data.
           undo: Ptr_New(), $       ; The previous processed image data.
           position: FltArr(4), $   ; The position of the graphics output in window.
           r: Ptr_New(), $          ; The red color vector associated with image colors.
           g: Ptr_New(), $          ; The green color vector associated with image colors.
           b: Ptr_New(), $          ; The blue color vector associated with image colors.
           ncolors: 0L, $           ; The number of image colors.
           annotatecolor: "", $     ; The name of the annotation color.
           backcolor:"", $          ; The name of the background color.
           xscale: FltArr(2), $     ; The scale for the X axis of the image plot.
           yscale: FltArr(2), $     ; The scale for the Y axis of the image plot.
           xtitle: "", $            ; The title of the X axis.
           ytitle: "", $            ; The title of the Y axis.
           vertical: 0L, $          ; A flag to indicate a vertical color bar.
           extra: Ptr_New() $       ; A placeholder for extra keywords.
          }
END ;--------------------------------------------------------------------