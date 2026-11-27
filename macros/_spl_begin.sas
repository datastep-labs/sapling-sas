/*******************************************************************************
| Macro Name    : _spl_begin.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.9.1
| Created By    : Sapling
| Date          : 16NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : The begin line of a macro in the log, with the version of the
|                 macro library; it gives the time it began, for the end line
|                 (%_spl_end). The version below is the one place of the version
|                 of the library: every header says the same.
| Used By       : every macro a person calls (inner part)
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| _macro      The name of the calling macro                       Required
|-------------------------------------------------------------------------------
|
| Output        : TEXT: the text of the time it began (seconds); the line
|                 NOTE: [describe] begins (Sapling macro library 1.1.0).
|                 in the log, unless SPL_QUIET is yes (a global macro variable:
|                 %LET spl_quiet = yes; before the calls keeps the log short).
|
| Example:
|
 %LET t0 = %_spl_begin(describe);
|
|-------------------------------------------------------------------------------
| Change Log :
| Date        Programmer   Description
|-------------------------------------------------------------------------------
| 12-NOV-2026 Sapling      1.1.0: initial version.
| 12-NOV-2026 Sapling      1.3.0: the version of the library with the figure
|                          macros.
| 12-NOV-2026 Sapling      1.4.0: the version of the library with %table and
|                          setup= of %layout.
| 12-NOV-2026 Sapling      1.5.0: the version of the library that ran the
|                          CDISC pilot (%freq, %stack).
| 13-NOV-2026 Sapling      1.6.0: the version of the library with plot=, par=
|                          and outpar= of the figure macros.
| 16-NOV-2026 Sapling      1.9.0: version 1.9.0; under OPTIONS NONOTES the begin
|                          line is written without NOTE: (a NOTE was not written
|                          at all). The license line.
|
*******************************************************************************/
%MACRO _spl_begin(
     _macro     /* The name of the calling macro */
) / DES = 'The begin line of a macro in the log';
  %LOCAL version quiet;
  %LET version = 1.9.1;
  %LET quiet   = NO;
  %IF %SYMEXIST(spl_quiet) %THEN %DO;
    %IF %LENGTH(%SUPERQ(spl_quiet)) %THEN %LET quiet = %QUPCASE(%SUPERQ(spl_quiet));
  %END;
  /* under OPTIONS NONOTES a NOTE is not written: the line then goes without NOTE: */
  %IF &quiet. ne YES %THEN %DO;
    %IF %SYSFUNC(GETOPTION(NOTES)) = NOTES %THEN
      %PUT NOTE: [&_macro.] begins (Sapling macro library &version.).;
    %ELSE %PUT [&_macro.] begins (Sapling macro library &version.).;
  %END;
  %SYSFUNC(DATETIME(), 18.3)
%MEND _spl_begin;
