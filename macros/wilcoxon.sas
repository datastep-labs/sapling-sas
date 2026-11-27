/*******************************************************************************
| Macro Name    : wilcoxon.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.9.1
| Created By    : Sapling
| Date          : 16NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : The Wilcoxon rank-sum test of each pair of groups, one record
|                 per subject (PROC NPAR1WAY, BY each pair, the group first):
|                 the two-sided p-value of the normal approximation with the
|                 continuity correction (pval; CORRECT=), the Hodges-Lehmann
|                 estimate of the shift (estimate: the group minus the group it
|                 is compared with) and its asymptotic (Moses) confidence limits
|                 (lcl, ucl; HL).
| Procedure     : PROC NPAR1WAY (WILCOXON, HL)
| Proven        : the known answer of the method wilcoxon (src/methods.ts,
|                 worked out by tools/method_answers.R; node
|                 tools/methods_sas.ts); ran on SAS 9.4 M9, 2026-11-12
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
| correction  yes (default): the continuity correction of the     yes
|             test; no
| level       The confidence level (default 0.95)                 0.95
| stats       The statistics, each with its pattern (default      estimate="XX.XX"
|             estimate="XX.XX" lcl="XX.XX" ucl="XX.XX"            lcl="XX.XX" ucl="XX.XX"
|             pval="X.XXX")                                       pval="X.XXX"
| label       The label of the block in a table, in quotes        Optional
| out         The result                                          Required
| debug       yes: keep the work data sets of the macro           no
|             (_wilcoxon_*)
|-------------------------------------------------------------------------------
|
| Output        : OUT: one row per pair and statistic (BY: the group, VERSUS: the
|                 group it is compared with); GROUPS is BY VERSUS.
|
| Example:
|
 %wilcoxon(
     data  = adqs
   , where = (paramcd = 'PAIN' AND avisit = 'Week 12')
   , var   = chg
   , by    = trt01p
   , order = trt01pn
   , out   = pain_w
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
