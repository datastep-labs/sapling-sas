/*******************************************************************************
| Macro Name    : baseline.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.9.1
| Created By    : Sapling
| Date          : 16NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : Give every record of a group the value of the group's baseline
|                 record (the one with the baseline flag).
| Procedure     : PROC SORT, MERGE
| Proven        : the fixtures of the step kind baseline (src/adam_steps.ts;
|                 node tools/adam_steps_sas.ts); ran on SAS 9.4 M9, 2026-11-12
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| data        The working data set (changed in place)             Required
| value       The variable whose baseline value is taken (AVAL)   Required
| by          The groups (one baseline record in each)            Required
| flag        The baseline flag (default ABLFL = 'Y')             ABLFL
| replace     yes: NEW is in the data already and is made again   no
|             (default no)
| new         The variable to make (BASE)                         Required
| debug       yes: keep the work data sets _baseline_*            no
|-------------------------------------------------------------------------------
|
| Output        : DATA: NEW on every record: the VALUE of the baseline
|                 record of its group (missing for a group without one); two
|                 baseline records in a group are an ERROR that names the group.
|                 The rows keep their order.
|
| Example:
|
 %baseline(
     data  = advs
   , value = aval
   , by    = usubjid paramcd
   , new   = base
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
| 16-NOV-2026 Sapling      1.9.1: two baseline records in a group: the ERROR,
|                          then data= is not changed (DEV-025).
|
*******************************************************************************/
%MACRO baseline(
     data    =         /* The working data set (changed in place) */
   , value   =         /* The variable whose baseline value is taken */
   , by      =         /* The groups (one baseline record in each) */
   , flag    = ABLFL   /* The baseline flag (Y on the baseline record) */
   , replace = no      /* yes: NEW is in the data already and is made again */
   , new     =         /* The variable to make (BASE) */
   , debug   = no      /* yes: keep the work data sets _baseline_* */
) / DES = 'Give every record of a group the value of its baseline record (PROC SORT, MERGE)';
  %LOCAL t0 opts lastby ndup;
  %LET t0 = %_spl_begin(baseline);

  /* Step 1: the parameters */
  %IF not %_spl_need(baseline, data new value by) %THEN %RETURN;
  %IF not %_spl_vars(baseline, data, value by flag) %THEN %RETURN;
  %IF not %_spl_oneof(baseline, debug, yes no) %THEN %RETURN;

  /* Step 2: the value of the baseline record of each group */
  PROC SORT DATA=&data. OUT=_baseline_value(KEEP=&by. &value. RENAME=(&value. = _base));
    WHERE &flag. = 'Y';
    BY &by.;
  RUN;

  /* Step 3: one baseline record in each group: two are an error of the data or of the flag */
  %LET lastby = %SCAN(&by., -1, %STR( ));
  %LET ndup   = 0;
  DATA _NULL_;
    SET _baseline_value END=_last;
    BY &by.;
    IF first.&lastby. AND NOT last.&lastby. THEN DO;
      PUT "ERR" "OR: [baseline] a group of by=&by. has more than one baseline record "
          "(flag=&flag.): give flag= one record in each group " (&by.) (=);
      _ndup + 1;
    END;
    IF _last THEN CALL SYMPUTX('ndup', SUM(_ndup, 0));
  RUN;
  /* two baseline records in a group: data= is not changed */
  %IF &ndup. > 0 %THEN %GOTO finish;

  /* Step 4: the rows keep their order: their number now; the baseline value of their group */
  DATA &data.;
    SET &data.;
    _baseline_row = _N_;
  RUN;
  PROC SORT DATA=&data.; BY &by. _baseline_row; RUN;
  %LET opts = IN=_inrows;
  %IF %UPCASE(%SUBSTR(&replace., 1, 1)) = Y %THEN %LET opts = &opts. DROP=&new.;
  DATA &data.;
    MERGE &data.(&opts.) _baseline_value;
    BY &by.;
    IF _inrows;
    &new. = _base;
    DROP _base;
  RUN;
  PROC SORT DATA=&data. OUT=&data.(DROP=_baseline_row); BY _baseline_row; RUN;

  /* Step 5: the work data sets are deleted (kept with debug=yes) */
  %finish:
  %IF %UPCASE(&debug.) ne YES %THEN %DO;
    PROC DATASETS LIBRARY=work NOLIST NOWARN;
      DELETE _baseline_:;
    QUIT;
  %END;
  %_spl_end(baseline, &t0., &debug.)
%MEND baseline;
