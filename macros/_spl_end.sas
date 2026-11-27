/*******************************************************************************
| Macro Name    : _spl_end.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.9.1
| Created By    : Sapling
| Date          : 16NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : The end line of a macro in the log: its run time since its begin
|                 line (%_spl_begin), and with debug=yes that its work data sets
|                 are kept.
| Used By       : every macro a person calls (inner part)
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| _macro      The name of the calling macro                       Required
| _start      The time it began (%_spl_begin)                     Required
| _debug      The debug= of the calling macro                     Optional
|-------------------------------------------------------------------------------
|
| Output        : LOG: NOTE: [describe] ends after 0.42 seconds. in the log,
|                 unless SPL_QUIET is yes; with debug=yes always the line that
|                 names the kept work data sets.
|
| Example:
|
 %_spl_end(describe, &t0., &debug.)
|
|-------------------------------------------------------------------------------
| Change Log :
| Date        Programmer   Description
|-------------------------------------------------------------------------------
| 12-NOV-2026 Sapling      1.1.0: initial version.
| 16-NOV-2026 Sapling      1.9.0: under OPTIONS NONOTES the end lines are
|                          written without NOTE: (a NOTE was not written at
|                          all). The license line.
|
*******************************************************************************/
%MACRO _spl_end(
     _macro     /* The name of the calling macro */
   , _start     /* The time it began */
   , _debug     /* The debug= of the calling macro */
) / DES = 'The end line of a macro in the log';
  %LOCAL quiet seconds notes;
  %LET quiet = NO;
  %IF %SYMEXIST(spl_quiet) %THEN %DO;
    %IF %LENGTH(%SUPERQ(spl_quiet)) %THEN %LET quiet = %QUPCASE(%SUPERQ(spl_quiet));
  %END;
  /* under OPTIONS NONOTES a NOTE is not written: the lines then go without NOTE: */
  %LET notes = %SYSFUNC(GETOPTION(NOTES));  /* NOTES or NONOTES */
  %IF %QUPCASE(%SUPERQ(_debug)) = YES %THEN %DO;
    %IF &notes. = NOTES %THEN
      %PUT NOTE: [&_macro.] debug=yes: the work data sets _&_macro._* are kept.;
    %ELSE %PUT [&_macro.] debug=yes: the work data sets _&_macro._* are kept.;
  %END;
  %IF &quiet. ne YES %THEN %DO;
    %LET seconds = %SYSFUNC(ROUND(%SYSEVALF(%SYSFUNC(DATETIME(), 18.3) - &_start.), 0.01), 12.2);
    %IF &notes. = NOTES %THEN %PUT NOTE: [&_macro.] ends after &seconds. seconds.;
    %ELSE %PUT [&_macro.] ends after &seconds. seconds.;
  %END;
%MEND _spl_end;
