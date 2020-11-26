This directory contains the files required to work with the
IDL Programming Techniques book, 2nd Edition, by David Fanning, 
first published by Fanning Software Consulting in October 2000. 
If you are using the first edition of the book, you will find the 
correct files in:

   ftp://ftp.dfanning.com/pub/dfanning/outgoing/coyote

Description of Files:

   Files ending in "pro": IDL program files.
   Files ending in "txt": Information-only text files.

Copying the Data Files:

   Use the COPYDATA program file that is among the IDL program 
   files you can downloaded to copy the IDL example data file to
   your working directory. For example, like this: 

   1. Create a directory where you want the data files to be stored
      on your machine. For example:

      %mkdir /usr/local/rsi/idl53/coyote

   2. Download the copydata.pro program file to this directory.

   3. Enter IDL and change to this directory. For example:

      %IDL
      IDL> CD, '/usr/local/rsi/idl53/coyote'

   4. Run the COPYDATA program.

      IDL> COPYDATA

   5. If you have problems, please read pages 5-6 in the book. If
      you still have problems, contact Fanning Software Consulting
      via e-mail at problems@dfanning.com.

Downloading the IDL Program Files:

   You can either download the 62 IDL program files individually, as you
   need them, or all at once in compressed format. Individual files should
   be downloaded in ASCII mode. All compressed format files should be
   downloaded in BINARY mode. I recommend you download all the files at 
   once.

   coyote2ndfiles.zip (210K)  ZIP file archive for Windows and UNIX computers

Problems with the Files:

   If you have any problems with the files, or if--heaven forbid--you find
   bugs in them, please contact me immediately. 

   Phone:  970-221-0438
   Fax:    970-221-4762
   E-Mail: problems@dfanning.com

   These files have been tested in version 5.3.1 of IDL.