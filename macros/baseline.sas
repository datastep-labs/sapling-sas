/*******************************************************************************
| Macro Name    : baseline.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.10.0
| Created By    : Sapling
| Date          : 27NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : Gives every record of a group the value of the group's
|                 baseline record, as a new variable such as BASE. The macro
|                 does not make the change from baseline: CHG = AVAL - BASE is a
|                 DATA step after %baseline (the how-to guide "Derive analysis
|                 visits, the baseline and the change from baseline" shows all
|                 the steps). The baseline record is the one whose flag=
|                 variable is 'Y'. A group with no baseline record gets a
|                 missing value. The rows of data= keep their order. When a
|                 group has two baseline records, the log has an ERROR line that
|                 names the group, and data= is not changed.
| Procedure     : PROC SORT, MERGE
| Proven        : Checked on its test cases of the baseline value (small made-up
|                 records): every value the same as that of the expected
|                 records; ran on SAS 9.4 M9, 2026-11-12
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| data        The data set to change in place, such as advs       Required
| value       The variable whose baseline value is taken, such    Required
|             as aval
| by          The groups, each with one baseline record:          Required
|             variables separated by blanks (by = usubjid
|             paramcd)
| flag        The baseline flag: a character variable that is     ABLFL
|             'Y' on the baseline record
| replace     yes: data= has the variable new= already; the       no
|             macro drops it and makes it again, with the type
|             and length of value=. With no, the values are
|             written into the variable new= of data= when it
|             has one (its type, length and label stay).
| new         The name of the new variable, such as base          Required
| debug       yes: keep the work data sets _baseline_*            no
|-------------------------------------------------------------------------------
|
| Output        : DATA: data=, changed in place: the variable new= on every
|                 record, with the value of value= on the baseline record of its
|                 group. A group with no baseline record gets a missing value.
|
| Example:
|
 * Copies the systolic records.;
 DATA vs;
   SET advs;
   WHERE paramcd = 'SYSBP';
 RUN;
 * Copies the value of the baseline record to BASE on each record of its subject and parameter.;
 %baseline(
     data    = vs
   , value   = aval
   , by      = usubjid paramcd
   , replace = yes
   , new     = base
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
| 27-NOV-2026 Sapling      1.10.0: the example runs on the example data
|                          (sas/examples). The text of the header for the
|                          manual: the summary, the form of each parameter. No
|                          number changes.
| 27-NOV-2026 Sapling      1.10.0: The text says that CHG is a DATA step after
|                          %baseline. The example first copies its records into a
|                          data set of its own, so that it changes no data set of
|                          setup.sas for a later example. No number changes.
| 27-NOV-2026 Sapling      1.10.0: a caption for each call of the example (a
|                          comment line before it). No number changes.
| 27-NOV-2026 Sapling      1.10.0: Proven in plain words, for the published
|                          manual. The title of the how-to guide in quotes;
|                          replace= says what no does. No number changes.
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
