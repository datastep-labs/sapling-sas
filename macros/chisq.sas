/*******************************************************************************
| Macro Name    : chisq.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.9.1
| Created By    : Sapling
| Date          : 27NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : Returns the p-value of the Pearson chi-square test of the
|                 groups against the categories of a response. Use %fisher for
|                 subjects with a record against subjects without (an adverse
|                 event), and %cmh for a test within strata. The test has no
|                 continuity correction. Each subject counts once in each group
|                 and category. A record with a missing group, category or value
|                 of within= is not used. With exact=yes the macro gives
|                 Fisher's exact test of the same table. The macro writes a
|                 result: a data set with one row per number (the result shape,
|                 see %stack).
| Procedure     : PROC FREQ (CHISQ, FISHER)
| Proven        : the known answer of the methods chisq, fisher (src/methods.ts,
|                 worked out by tools/method_answers.R; node
|                 tools/methods_sas.ts); ran on SAS 9.4 M9, 2026-11-12
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| data        The input data set: the records, with USUBJID       Required
| where       The records to use: a condition in parentheses,     Optional
|             such as where = (avisit = 'Week 24')
| var         The categories of the response: one variable,       Required
|             numeric or character
| by          The groups to compare: one variable                 Required
| within      One test in each group of these variables,          Optional
|             separated by blanks, such as a parameter and a
|             visit (within = paramcd avisit)
| exact       yes: Fisher's exact test of the same table instead  no
|             of the chi-square test
| stats       The statistic pval and the pattern of its printed   pval="X.XXX"
|             number, such as stats = pval="X.XXXX"
| label       The label of the block in the table: a text in      Optional
|             quotes. A block is the rows of one call in the
|             table.
| out         The name of the result data set                     Required
| debug       yes: keep the work data sets _chisq_*               no
|-------------------------------------------------------------------------------
|
| Output        : OUT: the result shape (see %stack): one row with STAT pval, or
|                 one row per group of within= with the variables of within=.
|                 GROUPS has the names of the within= variables. VALUE is
|                 missing where PROC FREQ makes no test (a table with one row or
|                 one column).
|
| Example:
|
 %chisq(
     data  = adsl
   , var   = sex
   , by    = trt01a
   , label = "Sex"
   , out   = sex_chisq
 )
 %chisq(
     data   = adlb
   , where  = (avisit = 'Week 24')
   , var    = anrind
   , by     = trt01a
   , within = paramcd
   , exact  = yes
   , out    = nr_test
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
| 27-NOV-2026 Sapling      1.9.1: The example result is sex_chisq, the name
|                          %stack reads. No number changes.
|
*******************************************************************************/
%MACRO chisq(
     data   =                /* The records */
   , where  =                /* The records to use: a condition in parentheses */
   , var    =                /* The categories (the response): one variable */
   , by     =                /* The groups to compare: one variable */
   , within =                /* One test in each group of these variables */
   , exact  = no             /* yes: Fisher exact test of the same table */
   , stats  = pval="X.XXX"   /* The statistic and its pattern */
   , label  =                /* The label of the block, in quotes */
   , out    =                /* The result */
   , debug  = no             /* yes: keep the work data sets _chisq_* */
) / DES = 'The Pearson chi-square test of groups against categories (PROC FREQ)';
  %LOCAL t0 chars test;
  %LET t0 = %_spl_begin(chisq);

  /* Step 1: the parameters */
  %IF not %_spl_need(chisq, data var by out) %THEN %RETURN;
  %IF not %_spl_vars(chisq, data, var by within) %THEN %RETURN;
  %IF not %_spl_oneof(chisq, exact, yes no) %THEN %RETURN;
  %IF not %_spl_oneof(chisq, debug, yes no) %THEN %RETURN;

  %LET chars = %_spl_chars(&data., &within.);           /* the character variables */
  %LET test  = CHISQ;                                   /* the test the macro runs */
  %IF %UPCASE(&exact.) = YES %THEN %LET test = FISHER;  /* exact= changes the test */

  /* Step 2: each subject once in each group and category */
  DATA _chisq_records;
    %IF %LENGTH(&chars.) %THEN %DO;
      LENGTH &chars. $200;
    %END;
    SET &data.;
    %IF %LENGTH(%SUPERQ(where)) %THEN %DO;
      WHERE &where.;
    %END;
    IF CMISS(OF &within. &by. &var.) = 0;
    KEEP usubjid &within. &by. &var.;
  RUN;
  PROC SORT DATA=_chisq_records NODUPKEY; BY &within. &by. &var. usubjid; RUN;

  /* Step 3: the test of the table of groups by categories */
  PROC DATASETS LIBRARY=work NOLIST NOWARN;
    DELETE _chisq_test;
  QUIT;
  ODS EXCLUDE ALL;
  %IF &test. = FISHER %THEN %DO;
    ODS OUTPUT FishersExact=_chisq_test(WHERE=(name1 = 'XP2_FISH') RENAME=(nvalue1 = pval));
  %END;
  %ELSE %DO;
    ODS OUTPUT ChiSq=_chisq_test(WHERE=(statistic = 'Chi-Square') RENAME=(prob = pval));
  %END;
  PROC FREQ DATA=_chisq_records;
    %IF %LENGTH(&within.) %THEN %DO;
      BY &within.;
    %END;
    TABLES &by. * &var. / &test.;
  RUN;
  ODS EXCLUDE NONE;
  %IF not %SYSFUNC(EXIST(_chisq_test)) %THEN %DO;
    /* no table could be tested */
    DATA _chisq_test;
      SET _chisq_records(OBS=0);
      pval = .;
    RUN;
  %END;

  /* Step 4: one row per group of WITHIN (a missing value where no test was made): the result */
  %IF %LENGTH(&within.) %THEN %DO;
    PROC SORT DATA=_chisq_records(KEEP=&within.) OUT=_chisq_groups NODUPKEY; BY &within.; RUN;
    DATA &out.;
      LENGTH groups block $200;
      MERGE _chisq_groups(IN=planned) _chisq_test(KEEP=&within. pval);
      BY &within.;
      IF planned;
      groups = "%UPCASE(&within.)";
      block  = DEQUOTE(%_spl_quote(label));
      %_spl_rows(stats=&stats.)
      KEEP &within. groups block stat value text;
    RUN;
  %END;
  %ELSE %DO;
    DATA &out.;
      LENGTH groups block $200;
      IF _ntest THEN SET _chisq_test(keep = pval) nobs = _ntest;
      groups = ' ';
      block  = DEQUOTE(%_spl_quote(label));
      %_spl_rows(stats=&stats.)
      KEEP groups block stat value text;
      STOP;
    RUN;
  %END;

  /* Step 5: the work data sets are deleted (kept with debug=yes) */
  %IF %UPCASE(&debug.) ne YES %THEN %DO;
    PROC DATASETS LIBRARY=work NOLIST NOWARN;
      DELETE _chisq_:;
    QUIT;
  %END;
  %_spl_end(chisq, &t0., &debug.)
%MEND chisq;
