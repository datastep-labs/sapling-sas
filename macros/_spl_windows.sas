/*******************************************************************************
| Macro Name    : _spl_windows.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.10.0
| Created By    : Sapling
| Date          : 16NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : The rows of windows= (or visits=) of a call as a data set: one
|                 row per window, the rows of the call separated by #, the
|                 values of a row by blanks, a text in quotes, a missing number
|                 as a period.
| Used By       : %windows, %visits, %locf (inner part)
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| _macro      The macro that calls                                Required
| _name       The name of its parameter with the rows             Required
| _kind       day: AVISITN AVISIT AWLO AWHI AWTARGET AWRANGE;     Required
|             visit: VISIT AVISITN AVISIT
| _out        The data set of the rows                            Required
|-------------------------------------------------------------------------------
|
| Output        : DATA: _out, one row per window in the order of the call. The
|                 macro variable ROWSOK of the caller: 1, or 0 when a row has
|                 not its number of values (an error in the log).
|
| Example:
|
 %_spl_windows(windows, windows, day, _windows_rows)
|
|-------------------------------------------------------------------------------
| Change Log :
| Date        Programmer   Description
|-------------------------------------------------------------------------------
| 13-NOV-2026 Sapling      1.7.0: initial version.
| 16-NOV-2026 Sapling      1.9.0: the license line; the example in the house
|                          case (names in lower case). No number changes.
|
*******************************************************************************/
%MACRO _spl_windows(
     _macro     /* The macro that calls */
   , _name      /* The name of its parameter with the rows */
   , _kind      /* day or visit: the values of a row */
   , _out       /* The data set of the rows */
) / DES = 'The rows of windows= or visits= of a call as a data set';
  %LOCAL nval form bad;
  %IF &_kind. = day %THEN %DO;
    %LET nval = 6;
    %LET form = AVISITN "AVISIT" AWLO AWHI AWTARGET "AWRANGE";
  %END;
  %ELSE %DO;
    %LET nval = 3;
    %LET form = "VISIT" AVISITN "AVISIT";
  %END;

  DATA &_out.;
    %IF &_kind. = day %THEN %DO;
      LENGTH _text $32767 _row $2000 avisit awrange $200;
    %END;
    %ELSE %DO;
      LENGTH _text $32767 _row $2000 visit avisit $200;
    %END;
    _text = %_spl_quote(&_name.);
    _bad  = 0;
    DO _r = 1 TO COUNTW(_text, '#', 'q');
      _row = SCAN(_text, _r, '#', 'q');
      IF COUNTW(_row, ' ', 'q') NE &nval. THEN _bad = _r;
      %IF &_kind. = day %THEN %DO;
        avisitn  = INPUT(SCAN(_row, 1, ' ', 'q'), ?? BEST32.);
        avisit   = DEQUOTE(SCAN(_row, 2, ' ', 'q'));
        awlo     = INPUT(SCAN(_row, 3, ' ', 'q'), ?? BEST32.);
        awhi     = INPUT(SCAN(_row, 4, ' ', 'q'), ?? BEST32.);
        awtarget = INPUT(SCAN(_row, 5, ' ', 'q'), ?? BEST32.);
        awrange  = DEQUOTE(SCAN(_row, 6, ' ', 'q'));
      %END;
      %ELSE %DO;
        visit   = DEQUOTE(SCAN(_row, 1, ' ', 'q'));
        avisitn = INPUT(SCAN(_row, 2, ' ', 'q'), ?? BEST32.);
        avisit  = DEQUOTE(SCAN(_row, 3, ' ', 'q'));
      %END;
      OUTPUT;
    END;
    CALL SYMPUTX('rowsok', (_bad = 0));
    CALL SYMPUTX('bad', _bad, 'L');
    STOP;
    %IF &_kind. = day %THEN %DO;
      KEEP avisitn avisit awlo awhi awtarget awrange;
    %END;
    %ELSE %DO;
      KEEP visit avisitn avisit;
    %END;
  RUN;
  %IF &rowsok. = 0 %THEN %DO;
    %PUT %STR(ERR)OR: [&_macro.] row &bad. of &_name.= has not &nval. values.;
    %PUT %STR(ERR)OR: [&_macro.]   fix: write a row as &form., # between the rows.;
  %END;
%MEND _spl_windows;
