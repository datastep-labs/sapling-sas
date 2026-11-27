/*******************************************************************************
| Macro Name    : locf.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.9.1
| Created By    : Sapling
| Date          : 16NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : Last observation carried forward into the analysis windows, as
|                 new records (ADaM: DTYPE = 'LOCF'). For each window after the
|                 first one after baseline in which a group has no analysed
|                 record: a copy of the last analysed record before it, moved to
|                 that window. Baseline is not carried.
| Procedure     : PROC SORT, a DATA step (SET POINT=)
| Proven        : the fixtures of the step kind impute (src/adam_steps.ts; node
|                 tools/adam_steps_sas.ts); ran on SAS 9.4 M9, 2026-11-12
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| data        The working data set (changed in place; the new     Required
|             records are added)
| windows     The windows, as windows= of %windows (baseline and  Required
|             one or more after it)
| where       The records LOCF is for, a condition in             Optional
|             parentheses
| by          The groups (default USUBJID PARAMCD)                USUBJID PARAMCD
| flag        The flag of the analysed records (default ANL01FL   ANL01FL
|             = 'Y')
| day         The study day (default ADY)                         ADY
| length      The length of DTYPE (default $8)                    $8
| debug       yes: keep the work data sets _locf_*                no
|-------------------------------------------------------------------------------
|
| Output        : DATA: sorted by the groups, AVISITN and DTYPE (the new order of
|                 the records).
|
| Example:
|
 %locf(
     data    = adqs
   , windows = &advs_windows.
   , where   = (paramcd = 'ACTOT')
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
    SET _locf_records;
    BY &by. DESCENDING avisitn;
    LENGTH dtype &length.;
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
