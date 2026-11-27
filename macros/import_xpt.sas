/*******************************************************************************
| Macro Name    : import_xpt.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.10.0
| Created By    : Sapling
| Date          : 27NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : Copies SAS transport files (XPORT version 5, .xpt) into SAS
|                 data sets in a folder. The macro stands alone: a program can
|                 include it without the library (00_import.sas). So it calls no
|                 other macro of the library and writes no begin and end lines
|                 in the log. A member is read from <dir>/<member>.xpt; when
|                 that file does not exist, from the same name in lower case.
| Procedure     : LIBNAME XPORT, PROC COPY
| Proven        : The ADaM and SDTM transport files of a made-up study: every
|                 program ran with a clean log, and 570 of 570 numbers the same
|                 as those of a second program in R; ran on SAS 9.4 M9,
|                 2026-11-12
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| dir         The folder of the transport files: a path without   Required
|             quotes
| members     The names of the data sets to read: one name or     Required
|             several, separated by blanks (members = dm ae vs).
|             The file of VTXC is VTXC.xpt or, when that does
|             not exist, vtxc.xpt.
| out         The folder that gets the data sets: a path without  Required
|             quotes. The folder must exist.
|-------------------------------------------------------------------------------
|
| Output        : FILE: one data set <out>/<member>.sas7bdat for each name of
|                 members=.
|
| Example:
|
 * Copies the six ADaM transport files of the example data into SAS data sets of one folder.;
 %import_xpt(
     dir     = &spl_root./examples/data
   , members = adsl adae advs adlb adtte adrs
   , out     = &spl_root./examples/adam
 )
|
|-------------------------------------------------------------------------------
| Change Log :
| Date        Programmer   Description
|-------------------------------------------------------------------------------
| 11-NOV-2026 Sapling      1.0.0: initial version.
| 12-NOV-2026 Sapling      1.0.0: ran on SAS 9.4 M9.
| 12-NOV-2026 Sapling      1.1.0: the house standard (docs/sas-style.md). No
|                          number changes.
| 16-NOV-2026 Sapling      1.9.0: the license line; the example in the house
|                          case (names in lower case). No number changes.
| 16-NOV-2026 Sapling      1.9.1: one ERROR and its fix for each missing
|                          parameter (DEV-011); members= finds <member>.xpt also
|                          in lower case (DEV-010). No number changes.
| 27-NOV-2026 Sapling      1.10.0: the example runs on the example data
|                          (sas/examples). The text of the header for the
|                          manual: the summary, the form of each parameter. No
|                          number changes.
| 27-NOV-2026 Sapling      1.10.0: The header names no internal tool. No number
|                          changes.
| 27-NOV-2026 Sapling      1.10.0: a caption for each call of the example (a
|                          comment line before it). No number changes.
| 27-NOV-2026 Sapling      1.10.0: Proven in plain words, for the published
|                          manual. No number changes.
|
*******************************************************************************/
%MACRO import_xpt(
     dir     =   /* The folder of the transport files (<member>.xpt) */
   , members =   /* The names of the data sets, separated by blanks */
   , out     =   /* The folder the data sets are written to */
) / DES = 'Read SAS transport files (XPORT version 5) into SAS data sets (PROC COPY)';
  %LOCAL i p ok member file;
  /* the checks of %_spl_need, written here: the macro stands alone */
  %LET ok = 1;
  %DO i = 1 %TO 3;
    %LET p = %SCAN(dir members out, &i., %STR( ));
    %IF %LENGTH(%SUPERQ(&p.)) = 0 %THEN %DO;
      %PUT %STR(ERR)OR: [import_xpt] &p.= is required;
      %PUT %STR(ERR)OR: [import_xpt]   fix: give &p.=<value> (see import_xpt.sas).;
      %LET ok = 0;
    %END;
  %END;
  %IF not &ok. %THEN %RETURN;

  /* each transport file into the folder of OUT */
  LIBNAME _splout "&out.";
  %DO i = 1 %TO %SYSFUNC(COUNTW(&members., %STR( )));
    %LET member = %SCAN(&members., &i., %STR( ));
    /* the file as members= names it, else in lower case (vtxc.xpt for VTXC) */
    %LET file = &dir./&member..xpt;
    %IF not %SYSFUNC(FILEEXIST(&file.)) %THEN %LET file = &dir./%LOWCASE(&member.).xpt;
    LIBNAME _splx XPORT "&file." ACCESS=readonly;
    PROC COPY IN=_splx OUT=_splout MEMTYPE=data;
    RUN;
    LIBNAME _splx CLEAR;
  %END;
  LIBNAME _splout CLEAR;
%MEND import_xpt;
