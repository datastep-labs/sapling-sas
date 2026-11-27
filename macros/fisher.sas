/*******************************************************************************
| Macro Name    : fisher.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.10.0
| Created By    : Sapling
| Date          : 27NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : Returns the p-value of Fisher's exact test of the subjects
|                 with a record against the subjects without, between groups.
|                 Use it for an adverse event between treatments; use %chisq for
|                 the categories of a response, and %cmh for a test within
|                 strata. Every subject of denom= counts, with a record in data=
|                 or without. A subject with a missing group in denom= is not
|                 used. With exact=no the macro gives the Pearson chi-square
|                 test of the same table. The macro writes a result: a data set
|                 with one row per number (the result shape, see %stack).
| Procedure     : PROC FREQ (FISHER, CHISQ)
| Proven        : Checked against its known answer (on a small data set, the
|                 numbers worked out independently in R); ran on SAS 9.4 M9,
|                 2026-11-12
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| data        The input data set: the records (adverse events),   Required
|             with USUBJID
| denom       The subjects, one row each, with USUBJID and the    Required
|             variable of by=: a data set, with data set options
|             if needed, such as denom = adsl(where = (saffl =
|             'Y'))
| where       The records to use: a condition in parentheses,     Optional
|             such as where = (trtemfl = 'Y')
| by          The groups to compare: one variable of denom=       Required
| within      One test in each group of these variables of        Optional
|             data=, separated by blanks, such as each preferred
|             term (within = aedecod)
| exact       no: the Pearson chi-square test of the same table   yes
|             instead of Fisher's exact test
| stats       The statistic pval and the pattern of its printed   pval="X.XXX"
|             number, such as stats = pval="X.XXXX"
| label       The label of the block in the table: a text in      Optional
|             quotes. A block is the rows of one call in the
|             table.
| out         The name of the result data set                     Required
| debug       yes: keep the work data sets _fisher_*              no
|-------------------------------------------------------------------------------
|
| Output        : OUT: the result shape (see %stack): one row with STAT pval, or
|                 one row per group of within= with the variables of within=.
|                 GROUPS has the names of the within= variables. VALUE is
|                 missing where no test can be made (one group, or all subjects
|                 with a record, or none).
|
| Example:
|
 * Tests the subjects with an event against those without in each class: one p value per class.;
 %fisher(
     data   = adae
   , denom  = adsl
   , where  = (trtemfl = 'Y')
   , by     = trt01a
   , within = aebodsys
   , out    = soc_test
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
| 16-NOV-2026 Sapling      1.9.1: a table of one group or one column is not
|                          tested: the value missing, no WARNING of ODS OUTPUT
|                          (DEV-049). No number changes.
| 27-NOV-2026 Sapling      1.10.0: the example runs on the example data
|                          (sas/examples). The text of the header for the
|                          manual: the summary, the form of each parameter. No
|                          number changes.
| 27-NOV-2026 Sapling      1.10.0: a caption for each call of the example (a
|                          comment line before it). No number changes.
| 27-NOV-2026 Sapling      1.10.0: Proven in plain words, for the published
|                          manual. No number changes.
|
*******************************************************************************/
%MACRO fisher(
     data   =                /* The records */
   , denom  =                /* The subjects, one row each, with BY */
   , where  =                /* The records to use: a condition in parentheses */
   , by     =                /* The groups to compare: a variable of denom= */
   , within =                /* One test in each group of these variables */
   , exact  = yes            /* no: the chi square test of the same table */
   , stats  = pval="X.XXX"   /* The statistic and its pattern */
   , label  =                /* The label of the block, in quotes */
   , out    =                /* The result */
   , debug  = no             /* yes: keep the work data sets _fisher_* */
) / DES = 'Fisher exact test of subjects with a record against those without (PROC FREQ)';
  %LOCAL t0 chars bychar test testable;
  %LET t0 = %_spl_begin(fisher);

  /* Step 1: the parameters */
  %IF not %_spl_need(fisher, data by denom out) %THEN %RETURN;
  %IF not %_spl_vars(fisher, data, within) %THEN %RETURN;
  %IF not %_spl_vars(fisher, denom, by) %THEN %RETURN;
  %IF not %_spl_oneof(fisher, exact, yes no) %THEN %RETURN;
  %IF not %_spl_oneof(fisher, debug, yes no) %THEN %RETURN;

  %LET by     = %UPCASE(&by.);  /* the groups, in upper case */
  %LET within = %UPCASE(&within.);  /* the subgroups, in upper case */
  %LET chars  = %_spl_chars(&data., &within.);  /* the character variables */
  %LET bychar = %_spl_chars(&denom., &by.);  /* the character variables */
  %LET test   = FISHER;  /* the test the macro runs */
  %IF %UPCASE(&exact.) = NO %THEN %LET test = CHISQ;  /* exact= changes the test */

  /* Step 2: the subjects, each with its group (of DENOM) */
  DATA _fisher_subjects;
    %IF %LENGTH(&bychar.) %THEN %DO;
      LENGTH &by. $200;
    %END;
    SET &denom.;
    IF NOT MISSING(&by.);
    KEEP usubjid &by.;
  RUN;
  PROC SORT DATA=_fisher_subjects NODUPKEY; BY usubjid &by.; RUN;

  /* Step 3: the subjects with a record, in each group of WITHIN */
  DATA _fisher_records;
    %IF %LENGTH(&chars.) %THEN %DO;
      LENGTH &chars. $200;
    %END;
    SET &data.;
    %IF %LENGTH(%SUPERQ(where)) %THEN %DO;
      WHERE &where.;
    %END;
    %IF %LENGTH(&within.) %THEN %DO;
      IF CMISS(OF &within.) = 0;
    %END;
    KEEP usubjid &within.;
  RUN;
  PROC SORT DATA=_fisher_records NODUPKEY; BY &within. usubjid; RUN;

  /* Step 4: each group of WITHIN with every subject: with a record (EVENT = 1) or without (0) */
  %IF %LENGTH(&within.) %THEN %DO;
    PROC SORT DATA=_fisher_records(KEEP=&within.) OUT=_fisher_groups NODUPKEY; BY &within.; RUN;
    DATA _fisher_table;
      SET _fisher_groups;
      DO _k = 1 TO _nsubj;
        SET _fisher_subjects POINT=_k NOBS=_nsubj;
        OUTPUT;
      END;
    RUN;
  %END;
  %ELSE %DO;
    DATA _fisher_table;
      SET _fisher_subjects;
    RUN;
  %END;
  DATA _fisher_table;
    MERGE _fisher_table(IN=subject) _fisher_records(IN=record);
    BY &within. usubjid;
    IF subject;
    event = record;
  RUN;

  /* Step 5: the test of the table of groups by EVENT */
  PROC DATASETS LIBRARY=work NOLIST NOWARN;
    DELETE _fisher_test;
  QUIT;
  /* a table of one group or of one column has no test (and its ODS OUTPUT would write a WARNING) */
  %LET testable = 0;
  DATA _NULL_;
    LENGTH _first $200;
    RETAIN _first ' ' _e0 _e1 _g2 0;
    SET _fisher_table END=_last;
         IF _N_ = 1                THEN _first = VVALUE(&by.);
    ELSE IF VVALUE(&by.) NE _first THEN _g2 = 1;
    IF event = 1 THEN _e1 = 1;
    ELSE              _e0 = 1;
    IF _last THEN CALL SYMPUTX('testable', _e0 * _e1 * _g2);
  RUN;
  %IF &testable. %THEN %DO;
    ODS EXCLUDE ALL;
    %IF &test. = FISHER %THEN %DO;
      ODS OUTPUT FishersExact=_fisher_test(WHERE=(name1 = 'XP2_FISH') RENAME=(nvalue1 = pval));
    %END;
    %ELSE %DO;
      ODS OUTPUT ChiSq=_fisher_test(WHERE=(statistic = 'Chi-Square') RENAME=(prob = pval));
    %END;
    PROC FREQ DATA=_fisher_table;
      %IF %LENGTH(&within.) %THEN %DO;
        BY &within.;
      %END;
      TABLES &by. * event / &test.;
    RUN;
    ODS EXCLUDE NONE;
  %END;
  %IF not %SYSFUNC(EXIST(_fisher_test)) %THEN %DO;
    /* no table could be tested */
    DATA _fisher_test;
      SET _fisher_table(OBS=0);
      pval = .;
    RUN;
  %END;

  /* Step 6: one row per group of WITHIN (a missing value where no test was made): the result */
  DATA &out.;
    LENGTH groups block $200;
    %IF %LENGTH(&within.) %THEN %DO;
      MERGE _fisher_groups(IN=planned) _fisher_test(KEEP=&within. pval);
      BY &within.;
      IF planned;
    %END;
    %ELSE %DO;
      IF _ntest THEN SET _fisher_test(keep = pval) nobs = _ntest;
    %END;
    groups = "%UPCASE(&within.)";
    block  = DEQUOTE(%_spl_quote(label));
    %_spl_rows(stats=&stats.)
    KEEP &within. groups block stat value text;
    %IF %LENGTH(&within.) = 0 %THEN %DO;
      STOP;
    %END;
  RUN;

  /* Step 7: the work data sets are deleted (kept with debug=yes) */
  %IF %UPCASE(&debug.) ne YES %THEN %DO;
    PROC DATASETS LIBRARY=work NOLIST NOWARN;
      DELETE _fisher_:;
    QUIT;
  %END;
  %_spl_end(fisher, &t0., &debug.)
%MEND fisher;
