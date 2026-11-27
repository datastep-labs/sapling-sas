/*******************************************************************************
| Macro Name    : summarize.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.9.1
| Created By    : Sapling
| Date          : 27NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : Gives each subject the sum, mean, largest or smallest value of
|                 a variable over its records in another data set. Use
|                 %summarize_groups for one record per group instead of a new
|                 variable on each subject. A subject with no record gets a
|                 missing value. A sum of only missing values is missing. The
|                 rows of data= keep their order.
| Procedure     : PROC SUMMARY, MERGE
| Proven        : the fixtures of the step kind derive.from.summary
|                 (src/adam_steps.ts; node tools/adam_steps_sas.ts); ran on SAS
|                 9.4 M9, 2026-11-12
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| data        The data set to change in place, such as adsl       Required
| from        The data set of the records, with USUBJID. When     Required
|             the value is not a variable yet, make it first in
|             a DATA step.
| value       The numeric variable of from= to summarize. To      Required
|             count records, give a 0/1 variable and stat=sum;
|             for "some record meets it" use stat=max, for
|             "every record meets it" stat=min.
| stat        The statistic: sum, mean, max or min                sum
| new         The name of the new variable                        Required
| debug       yes: keep the work data sets _summarize_*           no
|-------------------------------------------------------------------------------
|
| Output        : DATA: data=, changed in place: the variable new= on every row
|                 of a subject, with the sum, mean, maximum or minimum of value=
|                 over its records in from=. A subject with no record gets a
|                 missing value.
|
| Example:
|
 DATA sl;
   SET adsl;
   KEEP usubjid trtdurd;
 RUN;
 %summarize(
     data  = sl
   , from  = sdtm.ex
   , value = exendy
   , stat  = max
   , new   = exlstdy
 )
 %summarize(
     data  = sl
   , from  = sdtm.ex
   , value = exdose
   , stat  = mean
   , new   = exmdose
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
| 27-NOV-2026 Sapling      1.9.1: the example runs on the example data
|                          (sas/examples). The text of the header for the
|                          manual: the summary, the form of each parameter. No
|                          number changes.
| 27-NOV-2026 Sapling      1.9.1: The example first copies its records into a
|                          data set of its own, so that it changes no data set of
|                          setup.sas for a later example. No number changes.
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
