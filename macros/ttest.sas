/*******************************************************************************
| Macro Name    : ttest.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.9.1
| Created By    : Sapling
| Date          : 16NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : The two-sample t-test of each pair of groups, one record per
|                 subject (PROC TTEST, BY each pair, the group first): the
|                 difference of the means (diff: the group minus the group it is
|                 compared with), its standard error (diff_se), its confidence
|                 limits (lcl, ucl) and the two-sided p-value (pval): Student's
|                 with the pooled variance (variances=equal) or Welch's with
|                 Satterthwaite's df (variances=unequal).
| Procedure     : PROC TTEST
| Proven        : the known answer of the method ttest (src/methods.ts, worked
|                 out by tools/method_answers.R; node tools/methods_sas.ts); ran
|                 on SAS 9.4 M9, 2026-11-12
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| data        The records                                         Required
| where       The records to use, a condition in parentheses      Optional
| var         The variable                                        Required
| by          The groups: a character variable                    Required
| pairs       all: each later group against each earlier one, in  all
|             the order of ORDER; or the pairs separated by #,
|             one pair per line, the group first, then the group
|             it is compared with (a value with a blank or a
|             hyphen in quotes): "Drug" "Placebo" # "High"
|             "Low". The form "A"-"B" of version 1.0 is still
|             read.
| order       A numeric variable with one value per group: the    Optional
|             order of the groups
| variances   equal (default: the Pooled row) or unequal (the     equal
|             Satterthwaite row)
| level       The confidence level (default 0.95)                 0.95
| stats       The statistics, each with its pattern (default      diff="XX.X"
|             diff="XX.X" diff_se="XX.XX" lcl="XX.X" ucl="XX.X"   diff_se="XX.XX" lcl="XX.X"
|             pval="X.XXX")                                       ucl="XX.X" pval="X.XXX"
| label       The label of the block in a table, in quotes        Optional
| out         The result                                          Required
| debug       yes: keep the work data sets of the macro           no
|             (_ttest_*)
|-------------------------------------------------------------------------------
|
| Output        : OUT: one row per pair and statistic (BY: the group, VERSUS: the
|                 group it is compared with); GROUPS is BY VERSUS.
|
| Example:
|
 %ttest(
     data  = advs
   , where = (paramcd = 'SYSBP' AND avisit = 'Week 12')
   , var   = chg
   , by    = trt01p
   , order = trt01pn
   , out   = sbp_t
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
