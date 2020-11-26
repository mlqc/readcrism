PRO Histo_GUI_Image_Colors, event

; This event handler changes the image colors of the graphic display.

Widget_Control, event.top, Get_UValue=info, /No_Copy

   ; What kind of event is this: button or color table loading?

thisEvent = Tag_Names(event, /Structure_Name)
CASE thisEvent OF

   'WIDGET_BUTTON': BEGIN

         ; Load the current color vectors.

      TVLCT, info.r, info.g, info.b

         ; Create an unique title for the XColors program. Assign
         ; it to the top-level base widget.

      colorTitle = info.title + " (" + StrTrim(info.wid,2) + ")"
      Widget_Control, event.top, TLB_Set_Title = colorTitle

         ; Call XColors with NOTIFYID to alert widgets when colors change.

      XColors, NColors=info.imagecolors, Group_Leader=event.top, $
         NotifyID=[event.id, event.top], Title=colortitle + ' Colors'

      END

   'XCOLORS_LOAD': BEGIN

         ; Update the color vectors with new values.

      info.r = event.r
      info.g = event.g
      info.b = event.b

         ; Redisplay the graphic if necessary.

      Device, Get_Visual_Depth=theDepth
      IF theDepth GT 8 THEN BEGIN

            ; Make the draw widget window the current graphics window.

         WSet, info.wid

            ; Draw the graphics.

         HistoImage, *info.process, $
            AxisColorName=info.axisColorName, $
            BackColorName=info.backcolorName, $
            Binsize=info.binsize, $
            DataColorName=info.datacolorName, $
            _Extra=*info.extra, $
            Max_Value=info.max_value, $
            NoLoadCT=1, $
            XScale=info.xscale, $
            YScale=info.yscale

      ENDIF
      END
ENDCASE

Widget_Control, event.top, Set_UValue=info, /No_Copy
END ;---------------------------------------------------------------------------



PRO Histo_GUI_Drawing_Colors, event

; This event handler changes the drawing colors of the graphic display.

Widget_Control, event.top, Get_UValue=info, /No_Copy

   ; Which color are we changing? The button UVALUE will tell us.

Widget_Control, event.id, Get_UValue=buttonUValue

   ; Change it by calling the modal dialog PickColorName.

CASE buttonUValue OF
   'ANNOTATION': BEGIN
      colorname = PickColorName(info.axisColorName, $
      Cancel=cancelled, Group_Leader=event.top, $
         Title='Select Annotation Color', $
         Index=!D.Table_Size-2, Bottom=!D.Table_Size-21)
      IF NOT cancelled THEN info.axisColorName = colorname
      END
   'DATA': BEGIN
      colorname = PickColorName(info.dataColorName, $
      Cancel=cancelled, Group_Leader=event.top, $
         Title='Select Data Color', $
         Index=!D.Table_Size-3, Bottom=!D.Table_Size-21)
      IF NOT cancelled THEN info.dataColorName = colorname
      END
   'BACKGROUND': BEGIN
      colorname = PickColorName(info.backColorName, $
      Cancel=cancelled, Group_Leader=event.top, $
         Title='Select Background Color', $
         Index=!D.Table_Size-4, Bottom=!D.Table_Size-21)
      IF NOT cancelled THEN info.backColorName = colorname
      END
ENDCASE

   ; Retrieve the new color table. The keyboard focus events will redraw the
   ; graphics display.

TVLCT, r, g, b, /Get
info.r = r
info.g = g
info.b = b

Widget_Control, event.top, Set_UValue=info, /No_Copy
END ;---------------------------------------------------------------------------



PRO Histo_GUI_Undo, event

Widget_Control, event.top, Get_UValue=info, /No_Copy

   ; Switch the process and undo images.

temp = *info.process
*info.process = *info.undo
*info.undo = temp

   ; Switch the UNDO/REDO button values.

Widget_Control, event.id, Get_Value=theValue, Get_UValue=theUValue
Widget_Control, event.id, Set_Value=theUValue, Set_UValue=theValue

   ; Make the draw widget window the current graphics window.

WSet, info.wid

   ; Draw the graphics.

HistoImage, *info.process, $
   AxisColorName=info.axisColorName, $
   BackColorName=info.backcolorName, $
   Binsize=info.binsize, $
   DataColorName=info.datacolorName, $
   _Extra=*info.extra, $
   Max_Value=info.max_value, $
   NoLoadCT=1, $
   XScale=info.xscale, $                 .
   YScale=info.yscale

Widget_Control, event.top, Set_UValue=info, /No_Copy
END ;---------------------------------------------------------------------------



PRO Histo_GUI_Processing, event

Widget_Control, event.top, Get_UValue=info, /No_Copy

   ; Set the undo image to be the current process image.

*info.undo = *info.process

   ; Set the undo button to UNDO and make it sensitive.

Widget_Control, info.undoID, Set_Value='Undo', Set_UValue='Redo', Sensitive=1

   ; What kind of processing do you need?

Widget_Control, event.id, Get_Value=buttonValue
CASE StrUpCase(buttonValue) OF
   'MEDIAN SMOOTH': *info.process = Median(*info.process, 5)
   'BOXCAR SMOOTH': *info.process = Smooth(*info.process, 7, /Edge_Truncate)
   'SOBEL': *info.process = Sobel(*info.process)
   'UNSHARP MASKING': *info.process = Smooth(*info.process, 7) - *info.process
   'ORIGINAL IMAGE':  *info.process = *info.image
ENDCASE

   ; Display the new image and its histogram.

WSet, info.wid

      ; Draw the graphics.

HistoImage, *info.process, $
   AxisColorName=info.axisColorName, $
   BackColorName=info.backcolorName, $
   Binsize=info.binsize, $
   DataColorName=info.datacolorName, $
   _Extra=*info.extra, $
   Max_Value=info.max_value, $
   NoLoadCT=1, $
   XScale=info.xscale, $                 .
   YScale=info.yscale

Widget_Control, event.top, Set_UValue=info, /No_Copy
END ;---------------------------------------------------------------------------



PRO Histo_GUI_Quit, event
Widget_Control, event.top, /Destroy
END ;---------------------------------------------------------------------------



PRO Histo_GUI_TLB_Events, event

thisEvent = Tag_Names(event, /Structure_Name)

IF thisEvent EQ 'WIDGET_BASE' THEN BEGIN

      ; Get the info structure and copy it here.

   Widget_Control, event.top, Get_UValue=info, /No_Copy

      ; Resize the draw widget.

   Widget_Control, info.drawID, Draw_XSize=event.x, Draw_YSize=event.y

      ; Make the draw widget window the current graphics window.

   WSet, info.wid

      ; Draw the graphics.

   HistoImage, *info.process, $
      AxisColorName=info.axisColorName, $
      BackColorName=info.backcolorName, $
      Binsize=info.binsize, $
      DataColorName=info.datacolorName, $
      _Extra=*info.extra, $
      Max_Value=info.max_value, $
      NoLoadCT=1, $
      XScale=info.xscale, $                 .
      YScale=info.yscale

   ; Put the info structure back in its storage location.

   Widget_Control, event.top, Set_UValue=info, /No_Copy
ENDIF

IF thisEvent EQ 'WIDGET_KBRD_FOCUS' THEN BEGIN

      ; If losing keyboard focus, do nothing and RETURN.

   IF event.enter EQ 0 THEN RETURN

      ; Get the info structure and copy it here.

   Widget_Control, event.top, Get_UValue=info, /No_Copy

      ; Load the program's colors.

   TVLCT, info.r, info.g, info.b

      ; If this is other than 8-bit display, redraw graphic.

   Device, Get_Visual_Depth=theDepth
   IF theDepth GT 8 THEN BEGIN
   WSet, info.wid
   HistoImage, *info.process, $
      AxisColorName=info.axisColorName, $
      BackColorName=info.backcolorName, $
      Binsize=info.binsize, $
      DataColorName=info.datacolorName, $
      _Extra=*info.extra, $
      Max_Value=info.max_value, $
      NoLoadCT=1, $
      XScale=info.xscale, $                 .
      YScale=info.yscale
   ENDIF

      ; Put the info structure back in its storage location.

   Widget_Control, event.top, Set_UValue=info, /No_Copy
ENDIF

END ;---------------------------------------------------------------------------


PRO Histo_GUI_Cleanup, tlb

; The purpose of this procedure is to clean up pointers,
; objects, pixmaps, and other things in our program that
; use memory. This procedure is called when the top-level
; base widget is destroyed.

Widget_Control, tlb, Get_UValue=info, /No_Copy
IF N_Elements(info) EQ 0 THEN RETURN

   ; Free the pointers.

Ptr_Free, info.image
Ptr_Free, info.extra
Ptr_Free, info.process
Ptr_Free, info.undo

END ;---------------------------------------------------------------------------



PRO Histo_GUI, $                    ; The program name.
   image, $                         ; The image data.
   AxisColorName=axisColorName, $   ; The axis color.
   BackColorName=backcolorName, $   ; The background color.
   Binsize=binsize, $               ; The histogram bin size.
   ColorTable=colortable, $         ; The colortable index to load.
   DataColorName=datacolorName, $   ; The data color.
   _Extra=extra, $                  ; For passing extra keywords.
   Group_Leader=group_leader, $     ; The group leader for the TLB.
   Max_Value=max_value, $           ; The maximum value of the histogram plot.
   Title=title, $                   ; The program window title.
   XScale=xscale, $                 ; The scale for the X axis of the image.
   YScale=yscale                    ; The scale for the Y axis of the image.

   ; Catch any error in the Histo_GUI program.

Catch, theError
IF theError NE 0 THEN BEGIN
   Catch, /Cancel
   ok = Error_Message(Traceback=1)
   RETURN
ENDIF

   ; Check for positional parameter. Define if necessary.
   ; Make sure it is correct size.

IF N_Elements(image) EQ 0 THEN image = LoadData(7)
ndim = Size(image, /N_Dimensions)
IF ndim NE 2 THEN Message, '2D Image Variable Required.', /NoName

   ; Check for histogram keywords.

IF N_Elements(binsize) EQ 0 THEN BEGIN
   range = Max(image) - Min(image)
   binsize = 2.0 > (range / 128.0)
ENDIF

IF N_Elements(max_value) EQ 0 THEN max_value = 5000.0
IF N_Elements(title) EQ 0 THEN title = 'Histo_GUI Program'

   ; Check for image scale parameters.

s = Size(image, /Dimensions)
IF N_Elements(xscale) EQ 0 THEN xscale = [0, s[0]]
IF N_Elements(xscale) NE 2 THEN Message, 'XSCALE must be 2-element array', /NoName
IF N_Elements(yscale) EQ 0 THEN yscale = [0, s[1]]
IF N_Elements(yscale) NE 2 THEN Message, 'YSCALE must be 2-element array', /NoName

   ; Check for color keywords.

IF N_Elements(dataColorName) EQ 0 THEN dataColorName = "Red"
IF N_Elements(axisColorName) EQ 0 THEN axisColorName = "Navy"
IF N_Elements(backcolorName) EQ 0 THEN backcolorName = "White"
IF N_Elements(colortable) EQ 0 THEN colortable = 4
colortable = 0 > colortable < 40
imagecolors = !D.Table_Size-4

   ; Define the TLB. The TLB should be resizeable and it should have a menu bar.

tlb = Widget_Base(Column=1, /TLB_Size_Events, Title=title, MBar=menubarID)

   ; Define the File pull-down menu.

fileID = Widget_Button(menubarID, Value='File')
quitID = Widget_Button(fileID, Value='Quit', Event_Pro='Histo_GUI_Quit')

   ; Define the Processing pull-down menu.

processID = Widget_Button(menubarID, Value='Processing', Event_Pro='Histo_GUI_Processing', /Menu)
smoothID = Widget_Button(processID, Value='Smoothing', /Menu)
button = Widget_Button(smoothID, Value='Median Smooth')
button = Widget_Button(smoothID, Value='Boxcar Smooth')
edgeID = Widget_Button(processID, Value='Edge Enhance', /Menu)
button = Widget_Button(edgeID, Value='Sobel')
button = Widget_Button(edgeID, Value='Unsharp Masking')
button = Widget_Button(processID, Value='Original Image')
undoID = Widget_Button(processID, Value='Undo', UValue='Redo', $
   Event_Pro='Histo_GUI_Undo', Sensitive=0, /Separator)

   ; Define the Colors pull-down menu.

colorsID = Widget_Button(menubarID, Value='Colors')
button = Widget_Button(colorsID, Value='Image Colors', Event_Pro='Histo_GUI_Image_Colors')
drawColorsID = Widget_Button(colorsID, Value='Drawing Colors', Event_Pro='Histo_GUI_Drawing_Colors', /Menu)
button = Widget_Button(drawColorsID, Value='Data Color', UValue='DATA')
button = Widget_Button(drawColorsID, Value='Background Color', UValue='BACKGROUND')
button = Widget_Button(drawColorsID, Value='Annotation Color', UValue='ANNOTATION')

   ; Define the draw widget.

drawID = Widget_Draw(tlb, XSize=400, YSize=400)

   ; Realize the widget hierarchy.

Widget_Control, tlb, /Realize

   ; Get the window index number of the draw widget window. Make it active.

Widget_Control, drawID, Get_Value=wid
WSet, wid

   ; Draw the graphic display.

HistoImage, image, $
   AxisColorName=axisColorName, $
   BackColorName=backcolorName, $
   Binsize=binsize, $
   ColorTable=colortable, $
   DataColorName=datacolorName, $
   _Extra=extra, $
   ImageColors=imagecolors, $
   Max_Value=max_value, $
   XScale=xscale, $                 .
   YScale=yscale

   ; Obtain the current RGB color vectors.

TVLCT, r, g, b, /Get

   ; Create the info structure with the information
   ; required to run the program.

info = { image:Ptr_New(image), $          ; A pointer to the image data.
         process:Ptr_New(image), $        ; A pointer to the process image.
         undo:Ptr_New(image), $           ; A pointer to the last processed image.
         undoID:undoID, $                 ; The identifier of the UNDO button.
         axisColorName:axisColorName, $   ; The name of the axis color.
         backColorName:backcolorName, $   ; The name of the background color.
         binsize:binsize, $               ; The histogram bin size.
         dataColorName:datacolorName, $   ; The name of the data color.
         imageColors:imagecolors, $       ; The number of colors used to display the image.
         max_value:max_value, $           ; The maximum value of the histogram plot.
         xscale:xscale, $                 ; The X scale of the image axis.
         yscale:yscale, $                 ; The Y scale of the image axis.
         title:title, $                   ; The window title.
         extra:Ptr_New(extra), $          ; A pointer to "extra" keywords.
         r:r, $                           ; The R color vector.
         g:g, $                           ; The G color vector.
         b:b, $                           ; The B color vector.
         drawID:drawID, $                 ; The identifier of the draw widget.
         wid:wid $                        ; The window index number of the graphics window.
       }

   ; Store the info structure in the user value of the TLB. Turn keyboard
   ; focus events on.

Widget_Control, tlb, Set_UValue=info, /No_Copy, /KBRD_Focus_Events

   ; Set up the event loop. Register the program with the window manager.

XManager, 'histo_gui', tlb, Event_Handler='Histo_GUI_TLB_Events', $
   /No_Block, Cleanup='Histo_GUI_Cleanup', Group_Leader=group_leader
END ;---------------------------------------------------------------------------