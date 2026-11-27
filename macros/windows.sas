/*******************************************************************************
| Macro Name    : windows.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.10.0
| Created By    : Sapling
| Date          : 27NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : Puts each record into its analysis window by its study day,
|                 and gives it AVISIT, AVISITN and the window variables. Use
|                 %visits when the analysis visit comes from the visit name of
|                 the record, not from its study day. The macro writes these
|                 variables:
|                 - AVISIT and AVISITN: the analysis visit of the window
|                 - AWLO, AWHI and AWTARGET: the first day, the last day and the
|                   target day of the window
|                 - AWRANGE: the window as a text; AWU: DAYS
|                 - AWTDIFF: the distance of the study day to the target day
|                 A record takes the first window, in the order of windows=,
|                 that holds its day. A record with no window, or a missing day,
|                 gets missing values only when data= does not have these
|                 variables yet. When data= has them already (an AVISIT from an
|                 earlier step), a record in no window keeps its old AVISIT,
|                 AVISITN and window values: drop them before the call when such
|                 a record must have none.
| Procedure     : DATA steps (SET POINT=)
| Proven        : Checked on its test cases of the analysis visit of each study
|                 day (small made-up records): every value the same as that of
|                 the expected records; ran on SAS 9.4 M9, 2026-11-12
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| data        The data set to change in place, such as advs       Required
| windows     The windows in the order of AVISITN, separated by   Required
|             #. Each window is AVISITN "AVISIT" AWLO AWHI
|             AWTARGET "AWRANGE"; a period for AWLO or AWHI is a
|             limit that is open (# 4 "Week 4" 2 42 28 "2-42").
| day         The numeric variable of the study day               ADY
|-------------------------------------------------------------------------------
|
| Output        : DATA: data=, changed in place: AVISIT, AVISITN, AWLO, AWHI,
|                 AWTARGET, AWRANGE, AWU and AWTDIFF on each record in a window,
|                 missing on a record in no window.
|
| Example:
|
 * Copies the systolic records with only the variables the windows need: no old AVISIT or AVISITN.;
 DATA vs;
   SET advs;
   WHERE paramcd = 'SYSBP';
   KEEP usubjid paramcd param adt ady aval vsseq;
 RUN;
 * Puts each record in the window of its study day, with the limits, the target and the distance.;
 %windows(
     data    = vs
   , windows = 0  "Baseline" .   1   1   "<=1"
             # 4  "Week 4"   2   42  28  "2-42"
             # 12 "Week 12"  43  126 84  "43-126"
             # 24 "Week 24"  127 210 168 "127-210"
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
| 27-NOV-2026 Sapling      1.10.0: the example runs on the example data
|                          (sas/examples). The text of the header for the
|                          manual: the summary, the form of each parameter. No
|                          number changes.
| 27-NOV-2026 Sapling      1.10.0: The example first copies its records into a
|                          data set of its own, so that it changes no data set of
|                          setup.sas for a later example. No number changes.
| 27-NOV-2026 Sapling      1.10.0: the text says that a record in no window keeps
|                          an AVISIT that data= has already. No number changes.
| 27-NOV-2026 Sapling      1.10.0: a caption for each call of the example; the
|                          example starts from a copy that keeps only the
|                          variables it needs (no AVISIT, AVISITN of ADVS). No
|                          number changes.
| 27-NOV-2026 Sapling      1.10.0: Proven in plain words, for the published
|                          manual. No number changes.
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
