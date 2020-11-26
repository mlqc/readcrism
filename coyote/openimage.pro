Pro OpenImage_Events, event

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

   'Cancel' : Widget_Control, event.top, /Destroy

   'Accept' : BEGIN

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

         ; If it checks out, set the pointer information.

      (*info.ptr).filename = filename
      (*info.ptr).xsize = xsize
      (*info.ptr).ysize = ysize
      (*info.ptr).cancel = 0

         ; Destroy the widget program

      Widget_Control, event.top, /Destroy
      END

ENDCASE

END ;---------------------------------------------------------------------------



Function OpenImage, $
   Filename=filename, $              ; Initial name of file to open.
   Group_Leader=group_leader, $      ; Group leader of this program.
   XSize=xsize, $                    ; Initial X size of file to open.
   YSize=ysize, $                    ; Initial Y size of file to open.
   Cancel=cancel                     ; An output cancel flag.


   ; This is a pop-up dialog widget to collect the filename and
   ; file sizes from the user. The widget is a modal or blocking
   ; widget. The function result is the image that is read from
   ; the file.
   ;
   ; The Cancel field indicates whether the user clicked the CANCEL
   ; button (result.cancel=1) or the ACCEPT button (result.cancel=0).

 On_Error, 2 ; Return to caller.

   ; Check parameters and keywords.

IF N_Elements(filename) EQ 0 THEN $
   filename=Filepath(SubDirectory=['examples','data'],'ctscan.dat')
IF N_Elements(xsize) EQ 0 THEN xsize = 256
IF N_Elements(ysize) EQ 0 THEN ysize = 256

   ; Create a top-level base. Must have a Group Leader defined
   ; for Modal operation. If this widget is NOT modal, then it
   ; should only be called from the IDL command line as a blocking
   ; widget.

IF N_Elements(group_leader) NE 0 THEN $
   tlb = Widget_Base(Column=1, Title='Enter File Information...', /Modal, $
      Group_Leader=group_leader, /Floating, /Base_Align_Center) ELSE $
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

   ; Make a button base with frame to hold CANCEL and ACCEPT buttons.

butbase = Widget_Base(tlb, Row=1)
cancel = Widget_Button(butbase, Value='Cancel')
accept = Widget_Button(butbase, Value='Accept')

   ; Center the program on the display

screenSize = Get_Screen_Size()
geom = Widget_Info(tlb, /Geometry)
Widget_Control, tlb, $
   XOffset = (screenSize[0] / 2) - (geom.scr_xsize / 2), $
   YOffset = (screenSize[1] / 2) - (geom.scr_ysize / 2)

   ; Realize top-level base and all of its children.

Widget_Control, tlb, /Realize

   ; Create a pointer. This will point to the location where the
   ; information collected from the user will be stored. You must
   ; store it external to the widget program, since the program
   ; will be destroyed no matter which button is selected. Fill the
   ; pointer with NULL values.

ptr = Ptr_New({Filename:'', Cancel:1, XSize:0, YSize:0})

   ; Create info structure to hold information needed in event handler.

info = { fileID:fileID, $     ; Identifier of widget holding filename.
         xsizeID:xsizeID, $   ; Identifier of widget holding xsize.
         ysizeID:ysizeID, $   ; Identifier of widget holding ysize.
         ptr:ptr }            ; Pointer to file information storage location.

   ; Store the info structure in the top-level base

Widget_Control, tlb, Set_UValue=info, /No_Copy

   ; Register the program, set up event loop. Make this program a
   ; blocking widget. This will allow the program to also be called
   ; from IDL command line without a GROUP_LEADER parameter. The program
   ; blocks here until the entire program is destroyed.

XManager, 'openimage', tlb, Event_Handler='OpenImage_Events'

  ; OK, widget is destroyed. Go get the file information in the pointer
  ; location, free up pointer memory, and return the file information.

fileInfo = *ptr
Ptr_Free, ptr

   ; Set the Cancel flag.

cancel = fileInfo.cancel

   ; Return the file information.

RETURN, fileInfo

END ;---------------------------------------------------------------------------
