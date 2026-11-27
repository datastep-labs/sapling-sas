/*******************************************************************************
| Macro Name    : _spl_folder.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.10.0
| Created By    : Sapling
| Date          : 16NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : Make the folder of a file the macro writes, and each folder
|                 above it that is missing, with a NOTE that names the folder
|                 made. A path that starts with ~ is in the home folder. Nothing
|                 is made when the folder is there or the file has no folder.
| Used By       : %print, %ard, %csv, %_spl_figure_open, the one-call tables
|                 (inner part)
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| _macro      The name of the calling macro                       Required
| _file       The file the macro writes: a path                   Required
|-------------------------------------------------------------------------------
|
| Output        : LOG: NOTE: [print] made the folder ~/study/out/tlf. for a
|                 folder it made; a WARNING when the folder cannot be made.
|
| Example:
|
 %_spl_folder(print, %SUPERQ(file).rtf)
|
|-------------------------------------------------------------------------------
| Change Log :
| Date        Programmer   Description
|-------------------------------------------------------------------------------
| 16-NOV-2026 Sapling      1.9.0: initial version: the macros make their
|                          output folders.
|
*******************************************************************************/
%MACRO _spl_folder(
     _macro     /* The name of the calling macro */
   , _file      /* The file the macro writes */
) / DES = 'Make the folder of a file and the folders above it that are missing';
  %LOCAL _dir _full _sep _n _i _part _parent _next _rc _bad;
  %LET _dir = %SUPERQ(_file);

  /* the folder: the path without its last part */
  %LET _n = %SYSFUNC(MAX(%SYSFUNC(FIND(&_dir., /, -32767)), %SYSFUNC(FIND(&_dir., \, -32767))));
  %IF &_n. <= 1 %THEN %RETURN;
  %LET _dir  = %QSUBSTR(&_dir., 1, %EVAL(&_n. - 1));
  %LET _full = &_dir.;  /* the folder with ~ as the home folder */
  %IF %QSUBSTR(&_dir., 1, 1) = %STR(~) and %SYSFUNC(SYSEXIST(HOME)) %THEN %DO;
    %IF %LENGTH(&_dir.) = 1 %THEN %LET _full = %SYSGET(HOME);
    %ELSE %LET _full = %SYSGET(HOME)%QSUBSTR(&_dir., 2);
  %END;
  %IF %SYSFUNC(FILEEXIST(&_full.)) %THEN %RETURN;

  /* each part of the path in turn: a part that is missing is made */
  %LET _sep = %STR(/);
  %IF %INDEX(&_full., \) %THEN %LET _sep = \;
  %LET _parent = .;
  %IF %QSUBSTR(&_full., 1, 1) = %STR(/) %THEN %LET _parent = %STR(/);
  %LET _bad = 0;
  %DO _i = 1 %TO %SYSFUNC(COUNTW(&_full., /\));
    %LET _part = %QSCAN(&_full., &_i., /\);
    %IF &_i. = 1 and %INDEX(&_part., :) %THEN %LET _next = &_part.&_sep.;
    %ELSE %IF %QSUBSTR(&_parent., %LENGTH(&_parent.), 1) = &_sep. %THEN
      %LET _next = &_parent.&_part.;
    %ELSE %LET _next = &_parent.&_sep.&_part.;
    %IF not &_bad. and not %SYSFUNC(FILEEXIST(&_next.)) %THEN %DO;
      %LET _rc = %SYSFUNC(DCREATE(&_part., &_parent.));
      %IF %LENGTH(&_rc.) = 0 %THEN %LET _bad = 1;
    %END;
    %LET _parent = &_next.;
  %END;
  %IF &_bad. %THEN %DO;
    %PUT %STR(WAR)NING: [&_macro.] file= is in the folder &_dir., which could not be made.;
    %PUT %STR(WAR)NING: [&_macro.]   fix: give file= a folder you may write in.;
  %END;
  %ELSE %PUT NOTE: [&_macro.] made the folder &_dir..;
%MEND _spl_folder;
