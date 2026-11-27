/*******************************************************************************
| Macro Name    : import_xpt.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.9.1
| Created By    : Sapling
| Date          : 16NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : Read SAS transport files (XPORT version 5) into SAS data sets.
| Procedure     : LIBNAME XPORT, PROC COPY
| Proven        : the ADaM and SDTM transport files (sapling sas run, sapling
|                 sas adam run) of the dummy study SYNHTN01 (sapling sas run:
|                 SAS RUN PASS; sapling sas check: SAS CHECK PASS, 570 of 570
|                 numbers of R the same in SAS); ran on SAS 9.4 M9, 2026-11-12
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| dir         The folder of the transport files (<member>.xpt)    Required
| members     The names of the data sets, separated by blanks:    Required
|             the file <member>.xpt, else in lower case (VTXC
|             reads vtxc.xpt)
| out         The folder the data sets are written to             Required
|-------------------------------------------------------------------------------
|
| Output        : FILE: the data sets <out>/<member>.sas7bdat. The macro stands alone:
|                 a program includes it without the library (00_import.sas), so
|                 it calls no other macro of the library and writes no begin and
|                 end lines.
|
| Example:
|
 %import_xpt(
     dir     = /DATA/htn3/xpt
   , members = adsl adae advs
   , out     = /DATA/htn3/adam
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
