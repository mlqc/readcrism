Pro ReadImage_Events, event

   ; Error handling.

Catch, theError
IF theError NE 0 THEN BEGIN
   Catch, /Cancel
   IF !Error_State.Code EQ -167 THEN BEGIN
      ok = Error_Message('A required value is undefined.')
   ENDIF ELSE BEGIN
      ok= Error_Message()
   ENDELSE
   IF N_Elements(info) NE 0 THEN $
      Widget_Control, event.top, Set_UValue=info, /No_Copy
   RETURN
ENDIF

   ; What kind of event is this? We only want to handle button events
   ; from our ACCEPT or CANCEL buttons. Other events fall through.

eventName = Tag_Names(event, /Structure_Name)

IF eventName NE 'WIDGET_BUTTON' THEN RETURN

      ; Get the info structure out of the top-level base

Widget_Control, event.top, Get_UValue=info, /No_Copy

   ; Which button was selected?

Widget_Control, event.id, Get_Value=buttonValue
CASE buttonValue OF

   'Dismiss' : Widget_Control, event.top, /Destroy

   'Apply' : BEGIN

         ; Fill out the file data structure with information
         ; collected from the form. Be sure to get just the
         ; *first* filename, since values from text widgets are
         ; always string arrays. Set the CANCEL flag correctly.

      filename = info.fileID->Get_Value()
      filename = filename[0]
      xsize = info.xsizeID->Get_Value()
      ysize = info.ysizeID->Get_Value()

         ; Preliminary checks of the fileInfo information.
         ; Does the file really exist?

      dummy = Findfile(filename, Count=theCount)
      IF theCount EQ 0 THEN $
         Message, 'Requested file cannot be found. Check spelling.', /NoName

         ; Are the file sizes positive?

      IF xsize LE 0 OR ysize LE 0 THEN $
         Message, 'File sizes must be positive numbers.', /NoName

         ; If it checks out, send an event.

              ; Notify the widgets about this event.

      s = Size(info.notifyIDs)
      IF s[0] EQ 1 THEN count = 0 ELSE count = s[2] - 1
      FOR j=0,count DO BEGIN

            ; Create a fileInfo event.

          fileInfo = { READIMAGE_EVENT, $
                       ID:info.notifyIDs[0,j], $
                       Top:info.notifyIDs[1,j], $
                       Handler:0L, $
                       Filename:filename, $
                       XSize:xsize, $
                       YSize:ysize }

          IF Widget_Info(info.notifyIDs[0,j], /Valid_ID) THEN $
             Widget_Control, info.notifyIDs[0,j], Send_Event=fileInfo
       ENDFOR

      Widget_Control, event.top, Set_UValue=info, /No_Copy
      END

ENDCASE

END ;---------------------------------------------------------------------------



PRO ReadImage, $
   notifyIDs, $                  ; A vector of widgets and their TLBs to notify.
   Filename=filename, $          ; Initial name of file to open.
   Group_Leader=group_leader, $  ; Group leader of this program.
   XSize=xsize, $                ; Initial X size of file to open.
   YSize=ysize                   ; Initial Y size of file to open.

   ; This is a pop-up dialog widget to collect the filename and
   ; file sizes from the user. The widget is non-modal.

   ; Only one READIMAGE program at a time.

IF XRegistered('readimage') NE 0 THEN RETURN

 On_Error, 2 ; Return to caller.

   ; Check parameters and keywords.

IF N_Elements(notifyIDs) EQ 0 THEN Message, 'Notification IDs are a required parameter.'
IF N_Elements(filename) EQ 0 THEN $
   filename=Filepath(SubDirectory=['examples','data'],'ctscan.dat')
IF N_Elements(xsize) EQ 0 THEN xsize = 256
IF N_Elements(ysize) EQ 0 THEN ysize = 256

   ; Create a top-level base.

tlb = Widget_Base(Column=1, Title='Enter File Information...', /Base_Align_Center)

   ; Make a sub-base for the filename and size widgets.

subbase = Widget_Base(tlb, Column=1, Frame=1)

   ; Create widgets for filename. Set text widget size appropriately.

filesize = StrLen(filename) * 1.25
fileID = FSC_InputField(subbase, Title='Filename:', Value=filename, $
   XSize=filesize, LabelSize=50, /StringValue)
xsizeID = FSC_InputField(subbase, Title='X Size:', $
   Value=xsize, /IntegerValue, LabelSize=50, Digits=4)
ysizeID = FSC_InputField(subbase, Title='Y Size:', $
   Value=ysize, /IntegerValue, LabelSize=50, Digits=4)

   ; Set up Tabing between fields.

fileID->SetTabNext, xsizeID->GetTextID()
xsizeID->SetTabNext, ysizeID->GetTextID()
ysizeID->SetTabNext, fileID->GetTextID()

   ; Make a button base with frame to hold DISMISS and APPLY buttons.

butbase = Widget_Base(tlb, Row=1)
dismissID = Widget_Button(butbase, Value='Dismiss')
applyID = Widget_Button(butbase, Value='Apply')

   ; Center the program on the display

screenSize = Get_Screen_Size()
geom = Widget_Info(tlb, /Geometry)
Widget_Control, tlb, $
   XOffset = (screenSize[0] / 2) - (geom.scr_xsize / 2), $
   YOffset = (screenSize[1] / 2) - (geom.scr_ysize / 2)

   ; Realize top-level base and all of its children.

Widget_Control, tlb, /Realize

   ; Create info structure to hold information needed in event handler.

info = { notifyIDs:notifyIDs, $ ; The list of widgets to notify.
         fileID:fileID, $       ; Identifier of widget holding filename.
         xsizeID:xsizeID, $     ; Identifier of widget holding xsize.
         ysizeID:ysizeID $      ; Identifier of widget holding ysize.
       }

   ; Store the info structure in the top-level base

Widget_Control, tlb, Set_UValue=info, /No_Copy

   ; Register the program, set up event loop. Make this program a
   ; non-blocking widget.

XManager, 'readimage', tlb, Event_Handler='ReadImage_Events', $
   /No_Block, Group_Leader=group_leader

END ;---------------------------------------------------------------------------
