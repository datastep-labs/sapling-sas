/*******************************************************************************
| Macro Name    : lsmeans.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.10.0
| Created By    : Sapling
| Date          : 27NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : The ANCOVA of the groups: returns the differences of the LS
|                 means of pairs of groups in a linear model, with confidence
|                 limits and p-values. Use %ancova for the test of one numeric
|                 term (a dose response), and %mmrm for repeated visits of a
|                 subject. The model is PROC MIXED without a random effect
|                 (least squares): the covariates, the class factors and the
|                 groups, one record per subject (the first with a value; when
|                 where= leaves a second record of a subject, the log has a NOTE
|                 with their number). Give a where= that leaves one record per
|                 subject, such as one parameter at one visit with anl01fl =
|                 'Y'; otherwise each subject has the first of its records in
|                 the order of data=, whichever it is. The LS mean of each group
|                 comes when stats= asks for it. The macro writes a result: a
|                 data set with one row per number (the result shape, see
|                 %stack).
| Procedure     : PROC MIXED (LSMEANS)
| Proven        : Checked against its known answer (on a small data set, the
|                 numbers worked out independently in R); ran on SAS 9.4 M9,
|                 2026-11-12
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| data        The input data set, with USUBJID                    Required
| where       The records to use: a condition in parentheses,     Optional
|             such as where = (paramcd = 'SYSBP' AND avisit =
|             'Week 12')
| var         The response: one numeric variable                  Required
| by          The groups of the model: one character variable     Required
| within      One model in each group of these variables,         Optional
|             separated by blanks (within = paramcd)
| covars      The covariates: numeric variables separated by      Optional
|             blanks (covars = base)
| class       The class factors besides the groups: variables     Optional
|             separated by blanks (class = sex)
| pairs       The pairs of groups to compare. all: each later     all
|             group against each earlier one, in the order of
|             order= (or of the values). Or the pairs separated
|             by #, each the group first and then the group it
|             is compared with, a value with a blank or a hyphen
|             in quotes: pairs = "Drug" "Placebo" # "High"
|             "Low"
| order       The order of the groups: one numeric variable with  Optional
|             one value per group (order = trt01pn)
| level       The confidence level of the limits: a number        0.95
|             between 0 and 1
| stats       The statistics, in the order of the rows: each      diff="XX.X"
|             name with the pattern of its printed number,        diff_se="XX.XX" lcl="XX.X"
|             separated by blanks. The names are diff, diff_se,   ucl="XX.X" pval="X.XXX"
|             lcl, ucl, pval, lsmean, lsmean_se, lsmean_lcl and
|             lsmean_ucl. A name without a pattern takes its
|             default pattern: see the table of default patterns
|             (How a number is kept and printed).
| label       The label of the block in the table: a text in      Optional
|             quotes. A block is the rows of one call in the
|             table.
| out         The name of the result data set                     Required
| debug       yes: keep the work data sets _lsmeans_*             no
|-------------------------------------------------------------------------------
|
| Output        : OUT: the result shape (see %stack). A row of a difference has
|                 the group in the by= variable and the group it is compared
|                 with in VERSUS: diff is the LS mean of the group minus the LS
|                 mean of VERSUS (a negative diff: a smaller LS mean in the
|                 group), diff_se its standard error, lcl and ucl its confidence
|                 limits, pval the p-value of the test that it is 0. With
|                 pairs=all the group is the later one in the order of order=. A
|                 row of an LS mean has VERSUS blank. GROUPS is the by=
|                 variable, VERSUS and the within= variables.
|
| Example:
|
 * Gives the difference of the LS means of every pair at Week 12, adjusted for baseline and sex.;
 %lsmeans(
     data   = advs
   , where  = (paramcd = 'SYSBP' AND avisit = 'Week 12' AND anl01fl = 'Y')
   , var    = chg
   , by     = trt01p
   , covars = base
   , class  = sex
   , pairs  = all
   , order  = trt01pn
   , out    = sbp_ls
 )
 * Compares two pairs against Placebo at a 90 percent level and keeps the statistics of stats=.;
 %lsmeans(
     data   = advs
   , where  = (paramcd = 'SYSBP' AND avisit = 'Week 12' AND anl01fl = 'Y')
   , var    = chg
   , by     = trt01p
   , covars = base
   , pairs  = "Xanomeline High Dose" "Placebo"
            # "Xanomeline Low Dose"  "Placebo"
   , order  = trt01pn
   , level  = 0.90
   , stats  = lsmean lsmean_se diff lcl ucl pval
   , out    = sbp_ls90
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
| 12-NOV-2026 Sapling      1.1.0: pairs= takes the pairs separated by #, one
|                          pair per line; the form "A"-"B" is still read.
| 12-NOV-2026 Sapling      1.1.0: the label is written into the code
|                          (%_spl_quote), not read by SYMGET when the step
|                          runs: the flat program has it. No number changes.
| 16-NOV-2026 Sapling      1.9.0: the license line; the example in the house
|                          case (names in lower case). No number changes.
| 16-NOV-2026 Sapling      1.9.1: covars= and class= are checked (DEV-036). No
|                          number changes.
| 27-NOV-2026 Sapling      1.10.0: lsmean_lcl and lsmean_ucl, the confidence
|                          limits of each LS mean (PROC MIXED, LSMEANS / CL).
|                          No number changes.
| 27-NOV-2026 Sapling      1.10.0: the example runs on the example data
|                          (sas/examples). The text of the header for the
|                          manual: the summary, the form of each parameter. No
|                          number changes.
| 27-NOV-2026 Sapling      1.10.0: a NOTE when where= leaves a second record of
|                          a subject (the first is used, as before). No number
|                          changes.
| 27-NOV-2026 Sapling      1.10.0: The example analyses the records of anl01fl =
|                          'Y' (one record per subject). The text of stats=: a
|                          name without a pattern takes its default pattern. No
|                          number changes.
| 27-NOV-2026 Sapling      1.10.0: an example with pairs=, level= and stats= with
|                          the LS means; the text says to give a where= that
|                          leaves one record per subject. No number changes.
| 27-NOV-2026 Sapling      1.10.0: a caption for each call of the example (a
|                          comment line before it). No number changes.
| 27-NOV-2026 Sapling      1.10.0: The first sentence says that the macro is the
|                          ANCOVA of the groups; the Output says the direction
|                          of diff (the group minus VERSUS); the caption of the
|                          first example says what it gives (the differences,
|                          not the LS means); Proven in plain words, for the
|                          published manual. stats= points to the table of
|                          default patterns of the manual. No number changes.
|
*******************************************************************************/
%MACRO lsmeans(
     data   =       /* The records */
   , where  =       /* The records to use: a condition in parentheses */
   , var    =       /* The response */
   , by     =       /* The groups of the model: a character variable */
   , within =       /* One model in each group of these variables */
   , covars =       /* The covariates */
   , class  =       /* The class factors */
   , pairs  = all   /* all, or the pairs: each group, then its comparator */
   , order  =       /* A numeric variable: the order of the groups */
   , level  = 0.95  /* The confidence level */
   , stats  = diff="XX.X" diff_se="XX.XX" lcl="XX.X" ucl="XX.X" pval="X.XXX"
                    /* The statistics, each with its pattern */
   , label  =       /* The label of the block, in quotes */
   , out    =       /* The result */
   , debug  = no    /* yes: keep the work data sets _lsmeans_* */
) / DES = 'The differences of the LS means of pairs of groups in a linear model (PROC MIXED)';
  %LOCAL t0 i item cond chars mstats dstats rows ndup;
  %LET t0 = %_spl_begin(lsmeans);

  /* Step 1: the parameters; the statistics of the LS means and those of the differences */
  %IF not %_spl_need(lsmeans, data var by out) %THEN %RETURN;
  %IF not %_spl_vars(lsmeans, data, var by within covars class) %THEN %RETURN;
  %IF not %_spl_oneof(lsmeans, debug, yes no) %THEN %RETURN;

  %LET by     = %UPCASE(&by.);  /* the groups, in upper case */
  %LET within = %UPCASE(&within.);  /* the subgroups, in upper case */
  %LET chars  = %_spl_chars(&data., &by. &within.);  /* the character variables */
  %LET cond   = not missing(&var.);  /* the records that count */
  %IF %LENGTH(%SUPERQ(where)) %THEN %LET cond = &cond. and &where.;  /* plus where= */
  %DO i = 1 %TO %SYSFUNC(COUNTW(%SUPERQ(stats), %STR( ), q));
    %LET item = %QSCAN(%SUPERQ(stats), &i., %STR( ), q);
    %IF %INDEX(%LOWCASE(&item.), lsmean) = 1 %THEN %LET mstats = &mstats. &item.;
    %ELSE %LET dstats = &dstats. &item.;
  %END;

  /* Step 2: one record per subject with a value */
  DATA _lsmeans_records;
    %IF %LENGTH(&chars.) %THEN %DO;
      LENGTH &chars. $200;
    %END;
    SET &data.;
    WHERE &cond.;
    IF CMISS(OF &within. &by.) = 0;
  RUN;
  PROC SORT DATA=_lsmeans_records NODUPKEY DUPOUT=_lsmeans_dups; BY &within. usubjid; RUN;
  %LET ndup = %_spl_nobs(_lsmeans_dups);  /* the second records of a subject, dropped */
  %IF &ndup. > 0 %THEN %DO;
    %PUT NOTE: [lsmeans] &ndup. record(s) of where= are a second record of a subject:;
    %PUT NOTE: [lsmeans]   the first record of each subject is used.;
  %END;

  /* Step 3: no record qualified: the result without a row */
  %IF %_spl_nobs(_lsmeans_records) = 0 %THEN %DO;
    %_spl_empty(macro=lsmeans, out=&out., like=_lsmeans_records, keep=&by. &within., add=versus)
    %GOTO finish;
  %END;

  /* Step 4: the model, its LS means and their differences */
  ODS EXCLUDE ALL;
  ODS OUTPUT LSMeans=_lsmeans_means Diffs=_lsmeans_diffs;
  PROC MIXED DATA=_lsmeans_records;
    %IF %LENGTH(&within.) %THEN %DO;
      BY &within.;
    %END;
    CLASS &class. &by.;
    MODEL &var. = &covars. &class. &by.;
    LSMEANS &by. / DIFF CL ALPHA=%SYSEVALF(1 - &level.);
  RUN;
  ODS EXCLUDE NONE;
  %_spl_pairs(
      diffs   = _lsmeans_diffs
    , by      = &by.
    , within  = &within.
    , records = _lsmeans_records
    , pairs   = &pairs.
    , order   = &order.
    , out     = _lsmeans_pairs
  )

  /* Step 5: one row per group or pair and statistic: the result */
  %IF %LENGTH(&mstats.) %THEN %DO;
    DATA _lsmeans_mrows;
      SET _lsmeans_means(RENAME=(estimate = lsmean stderr = lsmean_se lower = lsmean_lcl
                                 upper = lsmean_ucl));
      %_spl_rows(stats=&mstats.)
    RUN;
  %END;
  DATA _lsmeans_drows;
    SET _lsmeans_pairs;
    %_spl_rows(stats=&dstats.)
  RUN;
  %LET rows = _lsmeans_drows;
  %IF %LENGTH(&mstats.) %THEN %LET rows = _lsmeans_mrows _lsmeans_drows;
  DATA &out.;
    LENGTH &by. versus groups block $200;
    SET &rows.;
    groups = "&by. VERSUS &within.";
    block  = DEQUOTE(%_spl_quote(label));
    KEEP &by. versus &within. groups block stat value text;
  RUN;

  /* Step 6: the work data sets are deleted (kept with debug=yes) */
  %finish:
  %IF %UPCASE(&debug.) ne YES %THEN %DO;
    PROC DATASETS LIBRARY=work NOLIST NOWARN;
      DELETE _lsmeans_:;
    QUIT;
  %END;
  %_spl_end(lsmeans, &t0., &debug.)
%MEND lsmeans;
