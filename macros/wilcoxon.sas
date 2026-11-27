/*******************************************************************************
| Macro Name    : wilcoxon.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.9.1
| Created By    : Sapling
| Date          : 27NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : Returns the p-value of the Wilcoxon rank-sum test of each pair
|                 of groups, with the Hodges-Lehmann shift and its limits. Use
|                 %ttest when the values are normal and the difference of the
|                 means is wanted. The macro writes a result: a data set with
|                 one row per number (the result shape, see %stack). The test
|                 runs in PROC NPAR1WAY, BY each pair, the group first. The
|                 statistics:
|                 - pval: the two-sided p-value of the normal approximation,
|                   with the continuity correction when correction=yes
|                   (CORRECT=)
|                 - estimate: the Hodges-Lehmann estimate of the shift, the
|                   group minus the group it is compared with (HL)
|                 - lcl, ucl: the asymptotic (Moses) confidence limits of the
|                   shift
|                 The macro uses one record per subject: when a subject has
|                 several records, the first one.
| Procedure     : PROC NPAR1WAY (WILCOXON, HL)
| Proven        : the known answer of the method wilcoxon (src/methods.ts,
|                 worked out by tools/method_answers.R; node
|                 tools/methods_sas.ts); ran on SAS 9.4 M9, 2026-11-12
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
| correction  yes: the continuity correction of the normal        yes
|             approximation; no: none
| level       The confidence level: a number between 0 and 1      0.95
|             (level = 0.90)
| stats       The statistics, in the order of the rows: each      estimate="XX.XX"
|             name with its pattern of the printed number,        lcl="XX.XX" ucl="XX.XX"
|             separated by blanks. The names are estimate, lcl,   pval="X.XXX"
|             ucl and pval. A name without a pattern takes its
|             default pattern (n="XX", mean="XX.X", pval="X.XXX"
|             ...; see %describe).
| label       The label of the block in the table: a text in      Optional
|             quotes. A block is the rows of one call in the
|             table.
| out         The name of the result data set                     Required
| debug       yes: keep the work data sets _wilcoxon_*            no
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
 * Compares each pair with the Wilcoxon rank sum test and the Hodges Lehmann estimate.;
 %wilcoxon(
     data  = advs
   , where = (paramcd = 'DIABP' AND avisit = 'Week 12' AND anl01fl = 'Y')
   , var   = chg
   , by    = trt01p
   , order = trt01pn
   , out   = dbp_w
 )
 * Leaves out the continuity correction for one pair: only the p value changes.;
 %wilcoxon(
     data       = advs
   , where      = (paramcd = 'DIABP' AND avisit = 'Week 12' AND anl01fl = 'Y')
   , var        = chg
   , by         = trt01p
   , pairs      = "Xanomeline High Dose" "Placebo"
   , correction = no
   , out        = dbp_w_nocc
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
| 27-NOV-2026 Sapling      1.9.1: the example runs on the example data
|                          (sas/examples). The text of the header for the
|                          manual: the summary, the form of each parameter. No
|                          number changes.
| 27-NOV-2026 Sapling      1.9.1: The example analyses the records of anl01fl =
|                          'Y' (one record per subject). The text of stats=: a
|                          name without a pattern takes its default pattern. No
|                          number changes.
| 27-NOV-2026 Sapling      1.9.1: an example with one pair and correction=no. No
|                          number changes.
| 27-NOV-2026 Sapling      1.9.1: a caption for each call of the example (a
|                          comment line before it). No number changes.
|
*******************************************************************************/
%MACRO wilcoxon(
     data       =       /* The records */
   , where      =       /* The records to use: a condition in parentheses */
   , var        =       /* The variable */
   , by         =       /* The groups: a character variable */
   , pairs      = all   /* all, or the pairs: each group, then its comparator */
   , order      =       /* A numeric variable: the order of the groups */
   , correction = yes   /* yes: the continuity correction of the test; no */
   , level      = 0.95  /* The confidence level */
   , stats      = estimate="XX.XX" lcl="XX.XX" ucl="XX.XX" pval="X.XXX"
                        /* The statistics, each with its pattern */
   , label      =       /* The label of the block, in quotes */
   , out        =       /* The result */
   , debug      = no    /* yes: keep the work data sets _wilcoxon_* */
) / DES = 'The Wilcoxon rank-sum test and Hodges-Lehmann shift of pairs (PROC NPAR1WAY)';
  %LOCAL t0 cond chars pairsok;
  %LET t0 = %_spl_begin(wilcoxon);

  /* Step 1: the parameters */
  %IF not %_spl_need(wilcoxon, data var by out) %THEN %RETURN;
  %IF not %_spl_vars(wilcoxon, data, var by) %THEN %RETURN;
  %IF not %_spl_oneof(wilcoxon, correction, yes no) %THEN %RETURN;
  %IF not %_spl_oneof(wilcoxon, debug, yes no) %THEN %RETURN;

  %LET by    = %UPCASE(&by.);  /* the groups, in upper case */
  %LET chars = %_spl_chars(&data., &by.);  /* the character variables */
  %LET cond  = not missing(&var.) and not missing(&by.);  /* the records that count */
  %IF %LENGTH(%SUPERQ(where)) %THEN %LET cond = &cond. and &where.;  /* plus where= */

  /* Step 2: one record per subject with a value */
  DATA _wilcoxon_records;
    %IF %LENGTH(&chars.) %THEN %DO;
      LENGTH &chars. $200;
    %END;
    SET &data.;
    WHERE &cond.;
  RUN;
  PROC SORT DATA=_wilcoxon_records NODUPKEY; BY usubjid; RUN;

  /* Step 3: no record qualified: the result without a row */
  %IF %_spl_nobs(_wilcoxon_records) = 0 %THEN %DO;
    %_spl_empty(macro=wilcoxon, out=&out., like=_wilcoxon_records, keep=&by., add=versus)
    %GOTO finish;
  %END;

  /* Step 4: the records of each pair */
  %_spl_stackpairs(
      macro   = wilcoxon
    , records = _wilcoxon_records
    , by      = &by.
    , pairs   = &pairs.
    , order   = &order.
    , out     = _wilcoxon_pairs
  )
  %IF &pairsok. = 0 %THEN %GOTO finish;

  /* Step 5: the test and the shift of each pair: the side 1 against the side 2 */
  ODS EXCLUDE ALL;
  ODS OUTPUT WilcoxonTest=_wilcoxon_test HodgesLehmann=_wilcoxon_hl;
  PROC NPAR1WAY DATA=_wilcoxon_pairs WILCOXON HL(refclass = '2') CORRECT=%UPCASE(&correction.)
    ALPHA=%SYSEVALF(1 - &level.);
    BY _pair _a _b;
    CLASS _side;
    VAR &var.;
  RUN;
  ODS EXCLUDE NONE;

  /* Step 6: one row per pair and statistic: the result */
  DATA &out.;
    LENGTH &by. versus groups block $200;
    MERGE _wilcoxon_hl(KEEP=_pair _a _b shift lowercl uppercl RENAME=(shift = estimate lowercl = lcl
                       uppercl = ucl))
          _wilcoxon_test(KEEP=_pair _a _b prob2 RENAME=(prob2 = pval));
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
      DELETE _wilcoxon_:;
    QUIT;
  %END;
  %_spl_end(wilcoxon, &t0., &debug.)
%MEND wilcoxon;
