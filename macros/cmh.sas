/*******************************************************************************
| Macro Name    : cmh.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.9.1
| Created By    : Sapling
| Date          : 27NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : Returns the p-value of the Cochran-Mantel-Haenszel test of the
|                 groups against the categories of a response, within strata.
|                 Use %chisq for the same test without strata. Each subject
|                 counts once in each group, category and stratum. A record with
|                 a missing group, category or value of within= is not used.
|                 statistic= chooses the test:
|                 - general: the test of general association
|                 - rowmean: the test that the mean scores of the groups differ;
|                   the scores are the values of the numeric response
|                   (SCORES=TABLE)
|                 The macro writes a result: a data set with one row per number
|                 (the result shape, see %stack).
| Procedure     : PROC FREQ (CMH)
| Proven        : the known answer of the method cmh (src/methods.ts, worked out
|                 by tools/method_answers.R; node tools/methods_sas.ts); ran on
|                 SAS 9.4 M9, 2026-11-12
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| data        The input data set: the records, with USUBJID       Required
| where       The records to use: a condition in parentheses,     Optional
|             such as where = (avisit = 'Week 24')
| var         The categories of the response: one variable;       Required
|             numeric for statistic=rowmean
| by          The groups to compare: one variable                 Required
| strata      The stratification variables, separated by blanks   Optional
|             (strata = sitegr1). When not given, the test has
|             one stratum.
| within      One test in each group of these variables,          Optional
|             separated by blanks, such as a parameter and a
|             visit (within = paramcd avisit)
| statistic   The test: general (general association) or rowmean  general
|             (the mean scores of the groups differ)
| stats       The statistic pval and the pattern of its printed   pval="X.XXX"
|             number, such as stats = pval="X.XXXX"
| label       The label of the block in the table: a text in      Optional
|             quotes. A block is the rows of one call in the
|             table.
| out         The name of the result data set                     Required
| debug       yes: keep the work data sets _cmh_*                 no
|-------------------------------------------------------------------------------
|
| Output        : OUT: the result shape (see %stack): one row with STAT pval, or
|                 one row per group of within= with the variables of within=.
|                 GROUPS has the names of the within= variables. VALUE is
|                 missing where PROC FREQ makes no test.
|
| Example:
|
 %cmh(
     data   = adsl
   , var    = eosstt
   , by     = trt01a
   , strata = sex
   , label  = "Discontinued the study"
   , out    = eos_cmh
 )
 %cmh(
     data      = adsl
   , var       = agegr1
   , by        = trt01a
   , statistic = rowmean
   , label     = "Age group"
   , out       = agegr_cmh
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
| 27-NOV-2026 Sapling      1.9.1: the example runs on the example data
|                          (sas/examples). The text of the header for the
|                          manual: the summary, the form of each parameter. No
|                          number changes.
| 27-NOV-2026 Sapling      1.9.1: an example with statistic=rowmean. No number
|                          changes.
|
*******************************************************************************/
%MACRO cmh(
     data      =                /* The records */
   , where     =                /* The records to use: a condition in parentheses */
   , var       =                /* The categories (the response): one variable */
   , by        =                /* The groups to compare: one variable */
   , strata    =                /* The stratification variables */
   , within    =                /* One test in each group of these variables */
   , statistic = general        /* general or rowmean (row mean scores differ) */
   , stats     = pval="X.XXX"   /* The statistic and its pattern */
   , label     =                /* The label of the block, in quotes */
   , out       =                /* The result */
   , debug     = no             /* yes: keep the work data sets _cmh_* */
) / DES = 'The Cochran-Mantel-Haenszel test of groups against categories in strata (PROC FREQ)';
  %LOCAL t0 chars tables hypothesis;
  %LET t0 = %_spl_begin(cmh);

  /* Step 1: the parameters */
  %IF not %_spl_need(cmh, data var by out) %THEN %RETURN;
  %IF not %_spl_vars(cmh, data, var by strata within) %THEN %RETURN;
  %IF not %_spl_oneof(cmh, statistic, general rowmean) %THEN %RETURN;
  %IF not %_spl_oneof(cmh, debug, yes no) %THEN %RETURN;

  %LET within     = %UPCASE(&within.);  /* the subgroups, in upper case */
  %LET chars      = %_spl_chars(&data., &within.);  /* the character variables */
  %LET hypothesis = General Association;  /* the name of the test in the output */
  /* the name of the row mean test */
  %IF %UPCASE(&statistic.) = ROWMEAN %THEN %LET hypothesis = Row Mean Scores Differ;
  %LET tables = &by. * &var.;  /* the cells of the TABLES statement */
  /* strata first */
  %IF %LENGTH(&strata.) %THEN
    %LET tables = %SYSFUNC(TRANSLATE(%SYSFUNC(COMPBL(&strata.)), *, %STR( ))) * &tables.;

  /* Step 2: each subject once in each group, category and stratum */
  DATA _cmh_records;
    %IF %LENGTH(&chars.) %THEN %DO;
      LENGTH &chars. $200;
    %END;
    SET &data.;
    %IF %LENGTH(%SUPERQ(where)) %THEN %DO;
      WHERE &where.;
    %END;
    IF CMISS(OF &within. &by. &var.) = 0;
    KEEP usubjid &within. &by. &var. &strata.;
  RUN;
  PROC SORT DATA=_cmh_records NODUPKEY; BY &within. usubjid &by. &var. &strata.; RUN;

  /* Step 3: the test: &hypothesis. */
  PROC DATASETS LIBRARY=work NOLIST NOWARN;
    DELETE _cmh_test;
  QUIT;
  ODS EXCLUDE ALL;
  ODS OUTPUT CMH=_cmh_test(WHERE=(althypothesis = "&hypothesis.") RENAME=(prob = pval));
  PROC FREQ DATA=_cmh_records;
    %IF %LENGTH(&within.) %THEN %DO;
      BY &within.;
    %END;
    TABLES &tables. / CMH SCORES=TABLE NOPRINT;
  RUN;
  ODS EXCLUDE NONE;
  %IF not %SYSFUNC(EXIST(_cmh_test)) %THEN %DO;
    /* no table could be tested */
    DATA _cmh_test;
      SET _cmh_records(OBS=0);
      pval = .;
    RUN;
  %END;

  /* Step 4: one row per group of WITHIN (a missing value where no test was made): the result */
  %IF %LENGTH(&within.) %THEN %DO;
    PROC SORT DATA=_cmh_records(KEEP=&within.) OUT=_cmh_groups NODUPKEY; BY &within.; RUN;
  %END;
  DATA &out.;
    LENGTH groups block $200;
    %IF %LENGTH(&within.) %THEN %DO;
      MERGE _cmh_groups(IN=planned) _cmh_test(KEEP=&within. pval);
      BY &within.;
      IF planned;
    %END;
    %ELSE %DO;
      IF _ntest THEN SET _cmh_test(keep = pval) nobs = _ntest;
    %END;
    groups = "&within.";
    block  = DEQUOTE(%_spl_quote(label));
    %_spl_rows(stats=&stats.)
    KEEP &within. groups block stat value text;
    %IF %LENGTH(&within.) = 0 %THEN %DO;
      STOP;
    %END;
  RUN;

  /* Step 5: the work data sets are deleted (kept with debug=yes) */
  %IF %UPCASE(&debug.) ne YES %THEN %DO;
    PROC DATASETS LIBRARY=work NOLIST NOWARN;
      DELETE _cmh_:;
    QUIT;
  %END;
  %_spl_end(cmh, &t0., &debug.)
%MEND cmh;
