/*******************************************************************************
| Macro Name    : logrank.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.9.1
| Created By    : Sapling
| Date          : 27NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : Returns the p-value of the log-rank test that compares the
|                 time to an event between the groups. Use %km for the medians
|                 of the groups, and %cox for a hazard ratio with its confidence
|                 interval. The macro writes a result: a data set with one row
|                 per number (the result shape, see %stack). The test uses one
|                 record per subject: when a subject has several records, the
|                 first one in the order of USUBJID is used, so where= must
|                 select one parameter. With strata=, the test is the stratified
|                 log-rank test: each combination of the values of the strata
|                 variables is one stratum (STRATA strata / GROUP=by of PROC
|                 LIFETEST). With only one group there is no test, and the
|                 p-value is missing. CNSR 0 is an event and any positive value
|                 is a censoring, as in ADaM, where the value names the reason
|                 of the censoring: a CNSR of 2 is censored as 1 is. A record
|                 used with a missing or negative CNSR stops the macro with an
|                 ERROR.
| Procedure     : PROC LIFETEST (STRATA)
| Proven        : the known answer of the method logrank (src/methods.ts, worked
|                 out by tools/method_answers.R; node tools/methods_sas.ts); ran
|                 on SAS 9.4 M9, 2026-11-12
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| data        The input data set: one record per subject, with    Required
|             USUBJID, the time and the censoring variable
| where       The records to use: a condition in parentheses,     Optional
|             such as where = (paramcd = 'TTDE')
| var         The time: one numeric variable, such as aval        Required
| by          The groups to compare: one variable                 Required
| cnsr        The censoring variable: one numeric variable, 0     CNSR
|             for an event and a positive value for a censoring
|             (the ADaM CNSR: 1, 2 ... name the reason). A
|             missing or negative value on a record used stops
|             the macro with an ERROR.
| strata      The strata of a stratified test: one variable or    Optional
|             several, separated by blanks (strata = sitegr1).
|             When not given, the test is not stratified.
| stats       The statistic with its pattern of the printed       pval="X.XXX"
|             number: pval
| label       The label of the block in the table: a text in      Optional
|             quotes. A block is the rows of one call in the
|             table.
| out         The name of the result data set                     Required
| debug       yes: keep the work data sets _logrank_*             no
|-------------------------------------------------------------------------------
|
| Output        : OUT: the result shape (see %stack), one row for all groups
|                 together: GROUPS (blank), BLOCK, STAT (pval), VALUE and TEXT.
|
| Example:
|
 %logrank(
     data   = adttde
   , var    = aval
   , by     = trt01a
   , strata = sex
   , out    = ttde_test
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
| 12-NOV-2026 Sapling      1.1.0: the label is written into the code
|                          (%_spl_quote), not read by SYMGET when the step
|                          runs: the flat program has it. No number changes.
| 16-NOV-2026 Sapling      1.9.0: the license line; the example in the house
|                          case (names in lower case). No number changes.
| 16-NOV-2026 Sapling      1.9.1: one group is not tested: the value missing, no
|                          WARNING (DEV-050); PLOTS=NONE only with ODS graphics
|                          on (DEV-051). No number changes.
| 27-NOV-2026 Sapling      1.9.1: the example runs on the example data
|                          (sas/examples). The text of the header for the
|                          manual: the summary, the form of each parameter. No
|                          number changes.
| 27-NOV-2026 Sapling      1.9.1: CNSR as in ADaM: 0 is an event and any positive
|                          value a censoring (before, only 1 was a censoring and
|                          2 an event); a missing or negative CNSR on a record
|                          used stops the macro with an ERROR. No number changes
|                          on data with CNSR 0 and 1.
|
*******************************************************************************/
%MACRO logrank(
     data   =                /* The records */
   , where  =                /* The records to use: a condition in parentheses */
   , var    =                /* The time */
   , by     =                /* The groups to compare: one variable */
   , cnsr   = CNSR           /* The censoring variable: 0 = event, > 0 censored */
   , strata =                /* The strata variables of a stratified test */
   , stats  = pval="X.XXX"   /* The statistic and its pattern */
   , label  =                /* The label of the block, in quotes */
   , out    =                /* The result */
   , debug  = no             /* yes: keep the work data sets _logrank_* */
) / DES = 'The log-rank test of a time between groups (PROC LIFETEST)';
  %LOCAL t0 cond plots ngroup nbad;
  %LET t0 = %_spl_begin(logrank);

  /* Step 1: the parameters */
  %IF not %_spl_need(logrank, data var by out) %THEN %RETURN;
  %IF not %_spl_vars(logrank, data, var by cnsr strata) %THEN %RETURN;
  %IF not %_spl_oneof(logrank, debug, yes no) %THEN %RETURN;

  %LET cond = not missing(&var.) and not missing(&by.);  /* the records that count */
  %IF %LENGTH(%SUPERQ(where)) %THEN %LET cond = &cond. and &where.;  /* plus where= */

  /* Step 2: one record per subject with a time */
  PROC SORT DATA=&data. OUT=_logrank_subjects NODUPKEY;
    WHERE &cond.;
    BY usubjid;
  RUN;
  DATA _logrank_subjects;
    SET _logrank_subjects;
    /* CNSR 0 is an event; a positive value is a censoring, with its reason */
    IF &cnsr. > 0 THEN _cens = 1;
    ELSE               _cens = 0;
  RUN;
  /* a missing or negative CNSR is neither an event nor a censoring */
  %LET nbad = %_spl_nobs(_logrank_subjects(WHERE=(MISSING(&cnsr.) OR &cnsr. < 0)));
  %IF &nbad. > 0 %THEN %DO;
    %PUT %STR(ERR)OR: [logrank] cnsr=&cnsr. is missing or negative on &nbad. record(s) used;
    %PUT %STR(ERR)OR: [logrank]   fix: give each record CNSR 0 (an event) or more (a censoring).;
    %GOTO finish;
  %END;

  /* Step 3: the test of the groups */
  PROC DATASETS LIBRARY=work NOLIST NOWARN;
    DELETE _logrank_tests;
  QUIT;
  /* one group has no test (and its ODS OUTPUT would write a WARNING) */
  PROC SORT DATA=_logrank_subjects(KEEP=&by.) OUT=_logrank_groups NODUPKEY; BY &by.; RUN;
  %LET ngroup = %_spl_nobs(_logrank_groups);  /* the number of groups */
  /* PLOTS=NONE only with ODS graphics on: with them off the option writes a WARNING */
  %LET plots = ;
  %IF not %SYMEXIST(sysodsgraphics) %THEN %LET plots = PLOTS=NONE;
  %ELSE %IF &sysodsgraphics. %THEN %LET plots = PLOTS=NONE;
  %IF &ngroup. > 1 %THEN %DO;
    ODS EXCLUDE ALL;
    ODS OUTPUT HomTests=_logrank_tests(WHERE=(test = 'Log-Rank') RENAME=(probchisq = pval));
    PROC LIFETEST DATA=_logrank_subjects &plots.;
      TIME &var. * _cens(1);
      %IF %LENGTH(&strata.) %THEN %DO;
        STRATA &strata. / GROUP=&by.;
      %END;
      %ELSE %DO;
        STRATA &by.;
      %END;
    RUN;
    ODS EXCLUDE NONE;
  %END;

  /* Step 4: the p value (missing when PROC LIFETEST made no test): the result */
  DATA &out.;
    LENGTH groups block $200;
    pval = .;
    %IF %SYSFUNC(EXIST(_logrank_tests)) %THEN %DO;
      IF _ntest THEN SET _logrank_tests(keep = pval) nobs = _ntest;
    %END;
    groups = ' ';
    block  = DEQUOTE(%_spl_quote(label));
    %_spl_rows(stats=&stats.)
    KEEP groups block stat value text;
    STOP;
  RUN;

  /* Step 5: the work data sets are deleted (kept with debug=yes) */
  %finish:
  %IF %UPCASE(&debug.) ne YES %THEN %DO;
    PROC DATASETS LIBRARY=work NOLIST NOWARN;
      DELETE _logrank_:;
    QUIT;
  %END;
  %_spl_end(logrank, &t0., &debug.)
%MEND logrank;
