pro pause,up=up,xcrs=xcrs,ycrs=ycrs,on_screen=on_screen
  ;+
  ; routine:        pause
  ;
  ; useage:         pause
  ;                 pause,up=up,xcrs=xcrs,ycrs=ycrs,on_screen=on_screen
  ;
  ; input:          none
  ;
  ; keyword input:
  ;   up
  ;     if set, don't return until a upward button transition is
  ;     detected.  This is useful when pause is used between plots which
  ;     draw quickly.  Setting this keyword ensures that no plots are
  ;     skipped but also requires that each new plot be accompanied by a
  ;     downward and upward button transition.  The default is to skip
  ;     to the next plot as long a mouse button is pressed down.
  ;
  ;
  ; xcrs,ycrs
  ;     pixel location to put cursor while waiting
  ;
  ; on_screen
  ;     if set, don't pause if cursor not in plot window
  ;
  ; output:         none
  ;
  ; PURPOSE:
  ;     Momentarily stop execution until a mouse key is pressed.  While
  ;     in the paused state the cursor is changed to what looks like an
  ;     arrow pointing down on a button.  When any of the mouse buttons
  ;     are pressed the cursor returns to its original form and
  ;     execution continues.
  ;
  ;     PAUSE will only interrupt execution if the output device is 'X'
  ;     and plot system variable !p.multi(0) eq 0.  The first condition
  ;     disables PAUSE when output is directed to a postscript file.
  ;     The second condition ensures that pauses occur only just before
  ;     the screen is erased for a new plot.
  ;
  ;     NOTE: After PAUSE returns to the calling program different
  ;     actions can be performed depending on whether the left, middle
  ;     or right mouse button was pressed.  Just test on the !err system
  ;     variable: !err=1 => left !err=2 => middle !err=4 => right.
  ;
  ; COMMON BLOCKS: pause_blk
  ;
  ; EXAMPLE:
  ;
  ;x=findgen(201)/10.-10.
  ;for a=-2.,2.,.1 do begin & plot,x,1/(x^2*10.^a+1),tit=string(a) & pause & end
  ;
  ;for a=-2.,2.,.1 do begin & plot,x,1/(x^2*10.^a+1),tit=string(a) &$
  ;   pause,/u & end
  ;
  ;  author:  Paul Ricchiazzi                            22sep92
  ;           Institute for Computational Earth System Science
  ;           University of California, Santa Barbara
  ;-


  if !d.name eq 'X' and !p.multi(0) eq 0 then begin
    cursor,xw,yw,/nowait,/device

    if xw eq -1 then begin
      if keyword_set(on_screen) then return
      if n_elements(xcrs) eq 0 then xcrs=.9*!d.x_vsize
      if n_elements(ycrs) eq 0 then ycrs=.9*!d.y_vsize
      tvcrs,xcrs,ycrs
    endif
    device,cursor_standard=16
    cursor,xdum,ydum,/wait,/device
    if keyword_set(up) then cursor,xdum,ydum,/up,/device
    device,cursor_standard=30
  endif
end