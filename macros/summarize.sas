/*******************************************************************************
| Macro Name    : summarize.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.9.1
| Created By    : Sapling
| Date          : 16NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : Give each subject a summary of its records in another data
|                 set: the sum or the mean of a variable. A subject without a
|                 record gets a missing value; a sum of only missing values is
|                 missing.
| Procedure     : PROC SUMMARY, MERGE
| Proven        : the fixtures of the step kind derive.from.summary
|                 (src/adam_steps.ts; node tools/adam_steps_sas.ts); ran on SAS
|                 9.4 M9, 2026-11-12
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| data        The working data set (changed in place)             Required
| from        The data set of the records (prepare the value      Required
|             with a DATA step)
| value       The variable of FROM to summarize. To count         Required
|             records, give a 0/1 variable and stat=sum; for
|             "some record meets it" stat=max, for "every record
|             meets it" stat=min.
| stat        sum (default), mean, max or min                     sum
| new         The variable to make                                Required
| debug       yes: keep the work data sets _summarize_*           no
|-------------------------------------------------------------------------------
|
| Output        : DATA: NEW on every row of a subject: the sum, mean,
|                 maximum or minimum of VALUE over its records in FROM; missing
|                 for a subject without a record.
|
| Example:
|
 %summarize(
     data  = adsl
   , from  = ex
   , value = dose_days
   , stat  = sum
   , new   = cumdose
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
|
*******************************************************************************/
%MACRO summarize(
     data  =      /* The working data set (changed in place) */
   , from  =      /* The data set of the records */
   , value =      /* The variable of FROM to summarize */
   , stat  = sum  /* sum, mean, max or min */
   , new   =      /* The variable to make */
   , debug = no   /* yes: keep the work data sets _summarize_* */
) / DES = 'The sum or mean of the records of each subject in another data set (PROC SUMMARY)';
  %LOCAL t0;
  %LET t0 = %_spl_begin(summarize);

  /* Step 1: the parameters */
  %IF not %_spl_need(summarize, data from new value) %THEN %RETURN;
  %IF not %_spl_vars(summarize, from, value) %THEN %RETURN;
  %IF not %_spl_oneof(summarize, stat, sum mean max min) %THEN %RETURN;
  %IF not %_spl_oneof(summarize, debug, yes no) %THEN %RETURN;

  /* Step 2: the summary of the records of each subject */
  PROC SUMMARY DATA=&from. NWAY;
    CLASS usubjid;
    VAR &value.;
    OUTPUT OUT=_summarize_value(KEEP=usubjid &new.) &stat.=&new.;
  RUN;

  /* Step 3: the rows keep their order: their number now; the summary of their subject */
  DATA &data.;
    SET &data.;
    _summarize_row = _N_;
  RUN;
  PROC SORT DATA=&data.; BY usubjid; RUN;
  DATA &data.;
    MERGE &data.(IN=_inrows) _summarize_value;
    BY usubjid;
    IF _inrows;
  RUN;
  PROC SORT DATA=&data. OUT=&data.(DROP=_summarize_row); BY _summarize_row; RUN;

  /* Step 4: the work data sets are deleted (kept with debug=yes) */
  %IF %UPCASE(&debug.) ne YES %THEN %DO;
    PROC DATASETS LIBRARY=work NOLIST NOWARN;
      DELETE _summarize_:;
    QUIT;
  %END;
  %_spl_end(summarize, &t0., &debug.)
%MEND summarize;
