/*******************************************************************************
| Macro Name    : windows.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.9.1
| Created By    : Sapling
| Date          : 16NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : Put each record in its analysis window by its study day:
|                 AVISIT, AVISITN, AWLO, AWHI, AWTARGET, AWRANGE, AWU (DAYS) and
|                 AWTDIFF (the distance to the target day). A record in no
|                 window keeps them missing. The first window (in the order of
|                 AVISITN) that holds the day is taken.
| Procedure     : DATA steps (SET POINT=)
| Proven        : the fixtures of the step kind windows.day (src/adam_steps.ts;
|                 node tools/adam_steps_sas.ts); ran on SAS 9.4 M9, 2026-11-12
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| data        The working data set (changed in place)             Required
| windows     The windows in the order of AVISITN, # between      Required
|             them; a window is AVISITN "AVISIT" AWLO AWHI
|             AWTARGET "AWRANGE" (a period: a limit that is open)
| day         The study day (default ADY)                         ADY
|-------------------------------------------------------------------------------
|
| Output        : DATA: AVISIT, AVISITN, AWLO, AWHI, AWTARGET, AWRANGE, AWU
|                 and AWTDIFF on each record in a window; missing on a record in
|                 no window.
|
| Example:
|
 %windows(
     data    = advs
   , windows = 0 "Baseline" .  1  1  "<=1"
             # 4 "Week 4"   2  42 28 "2-42"
             # 8 "Week 8"   43 70 56 "43-70"
   , day     = ady
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
| 13-NOV-2026 Sapling      1.7.0: windows= takes the rows in the call (# between
|                          rows), no data set of them. No number changes.
| 16-NOV-2026 Sapling      1.9.0: the license line; the example in the house
|                          case (names in lower case). No number changes.
|
*******************************************************************************/
%MACRO windows(
     data    =       /* The working data set (changed in place) */
   , windows =       /* The windows: AVISITN "AVISIT" AWLO AWHI AWTARGET "AWRANGE" # ... */
   , day     = ADY   /* The study day */
) / DES = 'Put each record in its analysis window by its study day (a DATA step)';
  %LOCAL t0 rowsok;
  %LET t0 = %_spl_begin(windows);
  %IF not %_spl_need(windows, data windows) %THEN %RETURN;

  /* the windows of the call as a data set, one row per window */
  %_spl_windows(windows, windows, day, _windows_rows)
  %IF &rowsok. = 0 %THEN %RETURN;

  /* the first window (in the order of AVISITN) that holds the day of each record */
  DATA &data.;
    SET &data.;
    _found = 0;
    IF NOT MISSING(&day.) THEN DO _w = 1 TO _nwindows WHILE (NOT _found);
      SET _windows_rows(RENAME=(avisitn = _wn avisit = _wname awlo = _wlo awhi = _whi
                            awtarget = _wtarget awrange = _wrange))
          POINT=_w NOBS=_nwindows;
      IF (MISSING(_wlo) OR &day. >= _wlo) AND (MISSING(_whi) OR &day. <= _whi) THEN DO;
        _found   = 1;
        avisit   = _wname;
        avisitn  = _wn;
        awlo     = _wlo;
        awhi     = _whi;
        awtarget = _wtarget;
        awrange  = _wrange;
        awu      = 'DAYS';
        IF NOT MISSING(_wtarget) THEN awtdiff = ABS(&day. - _wtarget);
      END;
    END;
    DROP _found _wn _wname _wlo _whi _wtarget _wrange;
  RUN;
  PROC DATASETS LIBRARY=work NOLIST NOWARN;
    DELETE _windows_:;
  QUIT;
  %_spl_end(windows, &t0.)
%MEND windows;
