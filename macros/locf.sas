/*******************************************************************************
| Macro Name    : locf.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.10.0
| Created By    : Sapling
| Date          : 27NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : Adds last-observation-carried-forward records (DTYPE = 'LOCF')
|                 to the analysis windows in which a group has no analysed
|                 record. Use %windows first: it gives each record the AVISITN
|                 of its window. The rule:
|                 - An analysed record has flag= equal to 'Y' and a window after
|                   baseline.
|                 - For each window, from the second window after baseline on,
|                   that has no analysed record of the group, the macro copies
|                   the last analysed record before it and moves the copy to
|                   that window.
|                 - Baseline is not carried forward, and the first window after
|                   baseline is not filled.
|                 The new records get the window variables of their window and
|                 DTYPE = 'LOCF'; the other records get a blank DTYPE.
| Procedure     : PROC SORT, a DATA step (SET POINT=)
| Proven        : Checked on its test cases of the value carried into a visit
|                 without one (small made-up records): every value the same as
|                 that of the expected records; ran on SAS 9.4 M9, 2026-11-12
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| data        The data set to change in place, such as advs: the  Required
|             new records are added to it
| windows     The windows, in the form of windows= of %windows:   Required
|             baseline first, then one window or more after it
| where       The records to carry forward: a condition in        Optional
|             parentheses, such as where = (paramcd = 'SYSBP').
|             When not given, all analysed records count.
| by          The groups, each carried forward by itself:         USUBJID PARAMCD
|             variables separated by blanks
| flag        The flag of the analysed records: a character       ANL01FL
|             variable that is 'Y' on them
| day         The numeric variable of the study day: it gives     ADY
|             AWTDIFF of a new record
| length      The length of DTYPE, such as $8                     $8
| debug       yes: keep the work data sets _locf_*                no
|-------------------------------------------------------------------------------
|
| Output        : DATA: data=, changed in place: the new records are added, and
|                 all records are sorted by the groups, AVISITN and DTYPE.
|
| Example:
|
 * Copies the systolic records of the analysis visits.;
 DATA vs;
   SET advs;
   WHERE paramcd = 'SYSBP' AND avisitn IN (0 4 12 24);
 RUN;
 * Carries the last value forward into a visit without a value: DTYPE is LOCF on the new records.;
 %locf(
     data    = vs
   , windows = 0  "Baseline" .   1   1   "<=1"
             # 4  "Week 4"   2   42  28  "2-42"
             # 12 "Week 12"  43  126 84  "43-126"
             # 24 "Week 24"  127 210 168 "127-210"
   , where   = (paramcd = 'SYSBP')
   , length  = $7
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
| 13-NOV-2026 Sapling      1.7.0: windows= takes the rows in the call, as
|                          %windows. No number changes.
| 13-NOV-2026 Sapling      1.7.1: the header: baseline and one or more windows
|                          after it.
| 16-NOV-2026 Sapling      1.9.0: the license line; the example in the house
|                          case (names in lower case). No number changes.
| 16-NOV-2026 Sapling      1.9.1: the header names no variable _ROW (DEV-024).
|                          No change of the code.
| 27-NOV-2026 Sapling      1.10.0: the example runs on the example data
|                          (sas/examples). No number changes.
| 27-NOV-2026 Sapling      1.10.0: DTYPE gets its length before the records are
|                          read: data= with DTYPE of another length gave a
|                          WARNING. The text of the header for the manual: the
|                          summary, the form of each parameter. No number
|                          changes.
| 27-NOV-2026 Sapling      1.10.0: The example first copies its records into a
|                          data set of its own, so that it changes no data set of
|                          setup.sas for a later example. No number changes.
| 27-NOV-2026 Sapling      1.10.0: a caption for each call of the example (a
|                          comment line before it). No number changes.
| 27-NOV-2026 Sapling      1.10.0: Proven in plain words, for the published
|                          manual. No number changes.
|
*******************************************************************************/
%MACRO locf(
     data    =                  /* The working data set (records are added) */
   , windows =                  /* The windows, as for %windows */
   , where   =                  /* The records LOCF is for, in parentheses */
   , by      = USUBJID PARAMCD  /* The groups */
   , flag    = ANL01FL          /* The flag of the analysed records */
   , day     = ADY              /* The study day */
   , length  = $8               /* The length of DTYPE */
   , debug   = no               /* yes: keep the work data sets _locf_* */
) / DES = 'Last observation carried forward into the analysis windows, as new records (PROC SORT)';
  %LOCAL t0 lastby baseline rowsok;
  %LET t0 = %_spl_begin(locf);

  /* Step 1: the parameters; the baseline window (the first) */
  %IF not %_spl_need(locf, data windows by flag) %THEN %RETURN;
  %IF not %_spl_vars(locf, data, by flag) %THEN %RETURN;
  %IF not %_spl_oneof(locf, debug, yes no) %THEN %RETURN;

  %LET lastby   = %SCAN(&by., -1, %STR( ));  /* the last variable of by= */
  %LET baseline = 0;                         /* the visit of the baseline, set below */
  %_spl_windows(locf, windows, day, _locf_rows)
  %IF &rowsok. = 0 %THEN %RETURN;
  DATA _NULL_;
    SET _locf_rows(OBS=1);
    CALL SYMPUTX('baseline', avisitn, 'L');
  RUN;

  /* Step 2: the analysed records after baseline, the latest first */
  /* The record after each one is then known. */
  PROC SORT DATA=&data. OUT=_locf_records;
    WHERE
    %IF %LENGTH(%SUPERQ(where)) %THEN %DO;
      &where. AND
    %END;
    &flag. = 'Y' AND avisitn > &baseline.;
    BY &by. DESCENDING avisitn;
  RUN;

  /* Step 3: a copy of the record before each empty window, moved to that window */
  DATA _locf_new;
    LENGTH dtype &length.;
    SET _locf_records;
    BY &by. DESCENDING avisitn;
    RETAIN _later;
    _this = avisitn;
    IF first.&lastby. THEN _later = CONSTANT('big');   /* no analysed record after this one */
    DO _w = 3 TO _nwindows;
      SET _locf_rows(RENAME=(avisitn = _wn avisit = _wname awlo = _wlo awhi = _whi
                            awtarget = _wtarget awrange = _wrange))
          POINT=_w NOBS=_nwindows;
      IF _this < _wn AND _wn < _later THEN DO;
        avisitn  = _wn;
        avisit   = _wname;
        awlo     = _wlo;
        awhi     = _whi;
        awtarget = _wtarget;
        awrange  = _wrange;
        IF NMISS(&day., _wtarget) = 0 THEN awtdiff = ABS(&day. - _wtarget);
        ELSE                               awtdiff = .;
        dtype = 'LOCF';
        OUTPUT;
      END;
    END;
    _later = _this;   /* for the record before: the window of the next analysed record */
    DROP _this _later _wn _wname _wlo _whi _wtarget _wrange;
  RUN;

  /* Step 4: the new records after those of DATA, sorted by the groups, AVISITN and DTYPE */
  DATA &data.;
    LENGTH dtype &length.;
    SET &data. _locf_new;
  RUN;
  PROC SORT DATA=&data.; BY &by. avisitn dtype; RUN;

  /* Step 5: the work data sets are deleted (kept with debug=yes) */
  %IF %UPCASE(&debug.) ne YES %THEN %DO;
    PROC DATASETS LIBRARY=work NOLIST NOWARN;
      DELETE _locf_:;
    QUIT;
  %END;
  %_spl_end(locf, &t0., &debug.)
%MEND locf;
