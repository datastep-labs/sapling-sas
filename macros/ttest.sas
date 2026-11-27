/*******************************************************************************
| Macro Name    : ttest.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.10.0
| Created By    : Sapling
| Date          : 27NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : Returns the difference of the means of each pair of groups,
|                 with its confidence limits and the t-test p-value. Use
|                 %wilcoxon when the values are not normal, %anova for one test
|                 of all the groups, and %lsmeans for a model with covariates.
|                 The macro writes a result: a data set with one row per number
|                 (the result shape, see %stack). The test is the two-sample
|                 t-test of PROC TTEST, run BY each pair, the group first. The
|                 statistics:
|                 - diff: the mean of the group minus the mean of the group it
|                   is compared with
|                 - diff_se: the standard error of diff
|                 - lcl, ucl: the confidence limits of diff
|                 - pval: the two-sided p-value, of Student's test with the
|                   pooled variance (variances=equal) or of Welch's test with
|                   Satterthwaite's degrees of freedom (variances=unequal)
|                 The macro uses one record per subject: when a subject has
|                 several records, the first one.
| Procedure     : PROC TTEST
| Proven        : Checked against its known answer (on a small data set, the
|                 numbers worked out independently in R); ran on SAS 9.4 M9,
|                 2026-11-12
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| data        The input data set: one record per subject, with    Required
|             USUBJID
| where       The records to use: a condition in parentheses,     Optional
|             such as where = (avisit = 'Week 24')
| var         The variable to compare: one numeric variable       Required
| by          The groups: one character variable (trt01a, not     Required
|             trt01an)
| pairs       Which groups to compare. all: each later group      all
|             against each earlier one, in the order of order=
|             (else of the values). Or the pairs, separated by
|             #: in each pair the group first, then the group it
|             is compared with, each value in quotes (pairs =
|             "Drug" "Placebo" # "High" "Low")
| order       The order of the groups: one numeric variable with  Optional
|             one value per group (order = trt01an)
| variances   equal (Student's test, the Pooled row of PROC       equal
|             TTEST) or unequal (Welch's test, the Satterthwaite
|             row)
| level       The confidence level: a number between 0 and 1      0.95
|             (level = 0.90)
| stats       The statistics, in the order of the rows: each      diff="XX.X"
|             name with its pattern of the printed number,        diff_se="XX.XX" lcl="XX.X"
|             separated by blanks. The names are diff, diff_se,   ucl="XX.X" pval="X.XXX"
|             lcl, ucl and pval. A name without a pattern takes
|             its default pattern: see the table of default
|             patterns (How a number is kept and printed).
| label       The label of the block in the table: a text in      Optional
|             quotes. A block is the rows of one call in the
|             table.
| out         The name of the result data set                     Required
| debug       yes: keep the work data sets _ttest_*               no
|-------------------------------------------------------------------------------
|
| Output        : OUT: the result shape (see %stack), one row per pair and
|                 statistic: the variable of by= (the group), VERSUS (the group
|                 it is compared with), GROUPS (by= and VERSUS), BLOCK, STAT,
|                 VALUE and TEXT. When no record qualifies, the result has no
|                 row.
|
| Example:
|
 * Compares each pair of groups with the pooled t test: the difference, its SE, limits and p value.;
 %ttest(
     data  = advs
   , where = (paramcd = 'SYSBP' AND avisit = 'Week 12' AND anl01fl = 'Y')
   , var   = chg
   , by    = trt01p
   , order = trt01pn
   , out   = sbp_t
 )
 * Uses the Welch test of unequal variances on two pairs: the SE, limits and p value change.;
 %ttest(
     data      = advs
   , where     = (paramcd = 'SYSBP' AND avisit = 'Week 12' AND anl01fl = 'Y')
   , var       = chg
   , by        = trt01p
   , pairs     = "Xanomeline High Dose" "Placebo"
               # "Xanomeline Low Dose"  "Placebo"
   , variances = unequal
   , out       = sbp_welch
 )
|
|-------------------------------------------------------------------------------
| Change Log :
| Date        Programmer   Description
|-------------------------------------------------------------------------------
| 12-NOV-2026 Sapling      1.0.0: initial version.
| 12-NOV-2026 Sapling      1.0.0: ran on SAS 9.4 M9.
| 12-NOV-2026 Sapling      1.1.0: the house standard (docs/sas-style.md). No
|                          number changes.
| 12-NOV-2026 Sapling      1.1.0: pairs= takes the pairs separated by #, one
|                          pair per line; the form "A"-"B" is still read.
| 12-NOV-2026 Sapling      1.1.0: the label is written into the code
|                          (%_spl_quote), not read by SYMGET when the step
|                          runs: the flat program has it. No number changes.
| 13-NOV-2026 Sapling      1.7.1: a pair of pairs= that names a group no record
|                          has is an error with its fix.
| 16-NOV-2026 Sapling      1.9.0: the license line; the example in the house
|                          case (names in lower case). No number changes.
| 16-NOV-2026 Sapling      1.9.1: a numeric by= stops with the ERROR of the
|                          macro (DEV-048). No number changes.
| 27-NOV-2026 Sapling      1.10.0: the text of the header for the manual: the
|                          summary, the form of each parameter. No number
|                          changes.
| 27-NOV-2026 Sapling      1.10.0: The example analyses the records of anl01fl =
|                          'Y' (one record per subject). The text of stats=: a
|                          name without a pattern takes its default pattern. No
|                          number changes.
| 27-NOV-2026 Sapling      1.10.0: an example with pairs= and variances=unequal.
|                          No number changes.
| 27-NOV-2026 Sapling      1.10.0: a caption for each call of the example (a
|                          comment line before it). No number changes.
| 27-NOV-2026 Sapling      1.10.0: Proven in plain words, for the published
|                          manual. stats= points to the table of default
|                          patterns of the manual. No number changes.
|
*******************************************************************************/
%MACRO ttest(
     data      =        /* The records */
   , where     =        /* The records to use: a condition in parentheses */
   , var       =        /* The variable */
   , by        =        /* The groups: a character variable */
   , pairs     = all    /* all, or the pairs: each group, then its comparator */
   , order     =        /* A numeric variable: the order of the groups */
   , variances = equal  /* equal (pooled) or unequal (Satterthwaite) */
   , level     = 0.95   /* The confidence level */
   , stats     = diff="XX.X" diff_se="XX.XX" lcl="XX.X" ucl="XX.X" pval="X.XXX"
                        /* The statistics, each with its pattern */
   , label     =        /* The label of the block, in quotes */
   , out       =        /* The result */
   , debug     = no     /* yes: keep the work data sets _ttest_* */
) / DES = 'The two-sample t-test of each pair of groups (PROC TTEST)';
  %LOCAL t0 cond chars method pairsok;
  %LET t0 = %_spl_begin(ttest);

  /* Step 1: the parameters */
  %IF not %_spl_need(ttest, data var by out) %THEN %RETURN;
  %IF not %_spl_vars(ttest, data, var by) %THEN %RETURN;
  %IF not %_spl_oneof(ttest, variances, equal unequal) %THEN %RETURN;
  %IF not %_spl_oneof(ttest, debug, yes no) %THEN %RETURN;

  %LET by    = %UPCASE(&by.);  /* the groups, in upper case */
  %LET chars = %_spl_chars(&data., &by.);  /* the character variables */
  %IF %LENGTH(&chars.) = 0 %THEN %DO;
    %PUT %STR(ERR)OR: [ttest] by=&by. is numeric;
    %PUT %STR(ERR)OR: [ttest]   fix: give by= a character group (TRT01A, not TRT01AN).;
    %RETURN;
  %END;
  %LET cond = not missing(&var.) and not missing(&by.);  /* the records that count */
  %IF %LENGTH(%SUPERQ(where)) %THEN %LET cond = &cond. and &where.;  /* plus where= */
  %IF %UPCASE(&variances.) = EQUAL %THEN %LET method = Pooled;  /* the row of the table */
  %ELSE %LET method = Satterthwaite;  /* the row of the table */

  /* Step 2: one record per subject with a value */
  DATA _ttest_records;
    %IF %LENGTH(&chars.) %THEN %DO;
      LENGTH &chars. $200;
    %END;
    SET &data.;
    WHERE &cond.;
  RUN;
  PROC SORT DATA=_ttest_records NODUPKEY; BY usubjid; RUN;

  /* Step 3: no record qualified: the result without a row */
  %IF %_spl_nobs(_ttest_records) = 0 %THEN %DO;
    %_spl_empty(macro=ttest, out=&out., like=_ttest_records, keep=&by., add=versus)
    %GOTO finish;
  %END;

  /* Step 4: the records of each pair */
  %_spl_stackpairs(
      macro   = ttest
    , records = _ttest_records
    , by      = &by.
    , pairs   = &pairs.
    , order   = &order.
    , out     = _ttest_pairs
  )
  %IF &pairsok. = 0 %THEN %GOTO finish;

  /* Step 5: the t test of each pair: the side 1 minus the side 2 */
  ODS EXCLUDE ALL;
  ODS OUTPUT ConfLimits=_ttest_cl TTests=_ttest_t Statistics=_ttest_st;
  PROC TTEST DATA=_ttest_pairs ALPHA=%SYSEVALF(1 - &level.);
    BY _pair _a _b;
    CLASS _side;
    VAR &var.;
  RUN;
  ODS EXCLUDE NONE;

  /* Step 6: one row per pair and statistic: the result */
  DATA &out.;
    LENGTH &by. versus groups block $200;
    MERGE _ttest_cl(WHERE=(method = "&method." AND class =: 'Diff')
                    KEEP=_pair _a _b method class mean lowerclmean upperclmean
                    RENAME=(mean = diff lowerclmean = lcl upperclmean = ucl))
          _ttest_st(WHERE=(method = "&method." AND class =: 'Diff')
                    KEEP=_pair _a _b method class stderr
                    RENAME=(stderr = diff_se))
          _ttest_t(WHERE=(method = "&method.") KEEP=_pair _a _b method probt RENAME=(probt = pval));
    BY _pair _a _b;
    &by. = _a;
    versus = _b;
    groups = "&by. VERSUS";
    block  = DEQUOTE(%_spl_quote(label));
    %_spl_rows(stats=&stats.)
    KEEP &by. versus groups block stat value text;
  RUN;

  /* Step 7: the work data sets are deleted (kept with debug=yes) */
  %finish:
  %IF %UPCASE(&debug.) ne YES %THEN %DO;
    PROC DATASETS LIBRARY=work NOLIST NOWARN;
      DELETE _ttest_:;
    QUIT;
  %END;
  %_spl_end(ttest, &t0., &debug.)
%MEND ttest;
