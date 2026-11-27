/*******************************************************************************
| Macro Name    : logrank.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.9.1
| Created By    : Sapling
| Date          : 16NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : The log-rank test of a time between groups (PROC LIFETEST,
|                 STRATA), one record per subject: pval. With strata= the
|                 stratified log-rank test (STRATA strata / GROUP=by): each
|                 combination of the values of the strata variables one stratum.
|                 With one group there is no test: the value is missing.
| Procedure     : PROC LIFETEST (STRATA)
| Proven        : the known answer of the method logrank (src/methods.ts, worked
|                 out by tools/method_answers.R; node tools/methods_sas.ts); ran
|                 on SAS 9.4 M9, 2026-11-12
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| data        The records                                         Required
| where       The records to use, a condition in parentheses      Optional
| var         The time                                            Required
| by          The groups to compare: one variable                 Required
| cnsr        The censoring variable: 1 = censored (default       CNSR
|             CNSR)
| strata      The strata variables of a stratified test,          Optional
|             separated by blanks
| stats       The statistic and its pattern (default              pval="X.XXX"
|             pval="X.XXX")
| label       The label of the block in a table, in quotes        Optional
| out         The result                                          Required
| debug       yes: keep the work data sets of the macro           no
|             (_logrank_*)
|-------------------------------------------------------------------------------
|
| Output        : OUT: one row, of all groups together (GROUPS is blank).
|
| Example:
|
 %logrank(
     data   = adtte
   , where  = (paramcd = 'TTDE')
   , var    = aval
   , by     = trt01a
   , strata = strat1 strat2
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
|
*******************************************************************************/
%MACRO logrank(
     data   =                /* The records */
   , where  =                /* The records to use: a condition in parentheses */
   , var    =                /* The time */
   , by     =                /* The groups to compare: one variable */
   , cnsr   = CNSR           /* The censoring variable: 1 = censored */
   , strata =                /* The strata variables of a stratified test */
   , stats  = pval="X.XXX"   /* The statistic and its pattern */
   , label  =                /* The label of the block, in quotes */
   , out    =                /* The result */
   , debug  = no             /* yes: keep the work data sets _logrank_* */
) / DES = 'The log-rank test of a time between groups (PROC LIFETEST)';
  %LOCAL t0 cond plots ngroup;
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
      TIME &var. * &cnsr.(1);
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
  %IF %UPCASE(&debug.) ne YES %THEN %DO;
    PROC DATASETS LIBRARY=work NOLIST NOWARN;
      DELETE _logrank_:;
    QUIT;
  %END;
  %_spl_end(logrank, &t0., &debug.)
%MEND logrank;
