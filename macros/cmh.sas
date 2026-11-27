/*******************************************************************************
| Macro Name    : cmh.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.9.1
| Created By    : Sapling
| Date          : 16NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : The Cochran-Mantel-Haenszel test of groups against categories
|                 in strata (PROC FREQ), each subject once in each group,
|                 category and stratum: pval. The test of general association,
|                 or (statistic=rowmean) the test that the mean scores of the
|                 groups differ, the scores being the values of the numeric
|                 response.
| Procedure     : PROC FREQ (CMH)
| Proven        : the known answer of the method cmh (src/methods.ts, worked out
|                 by tools/method_answers.R; node tools/methods_sas.ts); ran on
|                 SAS 9.4 M9, 2026-11-12
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| data        The records                                         Required
| where       The records to use, a condition in parentheses      Optional
| var         The categories (the response): one variable         Required
| by          The groups to compare: one variable                 Required
| strata      The stratification variables, separated by blanks   Optional
| within      One test in each group of these variables (a        Optional
|             parameter, a visit)
| statistic   general (default): general association; rowmean:    general
|             row mean scores differ
| stats       The statistic and its pattern (default              pval="X.XXX"
|             pval="X.XXX")
| label       The label of the block in a table, in quotes        Optional
| out         The result                                          Required
| debug       yes: keep the work data sets of the macro           no
|             (_cmh_*)
|-------------------------------------------------------------------------------
|
| Output        : OUT: one row, or one per group of WITHIN (GROUPS: their names).
|                 Where PROC FREQ makes no test the value is missing.
|
| Example:
|
 %cmh(
     data      = adqscibc
   , var       = aval
   , by        = trt01p
   , strata    = sitegr1
   , within    = avisit
   , statistic = rowmean
   , out       = cibic_test
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
