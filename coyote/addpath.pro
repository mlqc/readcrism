PRO ADDPATH

   ; This program adds the current directory to
   ; the IDL !Path system variable.

CD, Current=thisDir

   ; Get the correct directory separator.

CASE !version.os OF        ; Have to worry about directory separators.
   'Win32'  : sep = ';'    ; PCs running IDL 4.0 for Windows or NT
   'windows'   : sep = ';' ; PCs
   'MacOS'  : sep = ','    ; Macintoshes
   'vms'    : sep = ','    ; VMS machines
ELSE        : sep = ':'    ; Unix machines
ENDCASE

!Path = thisDir + sep + !Path
END
