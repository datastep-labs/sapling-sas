/*******************************************************************************
| Macro Name    : lsmeans.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.9.1
| Created By    : Sapling
| Date          : 27NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : A linear model of a variable, one record per subject (PROC
|                 MIXED without a random effect: least squares): covariates,
|                 class factors and the groups. The differences of the LS means
|                 of pairs of groups (diff, diff_se, lcl, ucl, pval) and, when
|                 stats= asks for them, the LS mean of each group (lsmean,
|                 lsmean_se) and its confidence limits (lsmean_lcl,
|                 lsmean_ucl).
| Procedure     : PROC MIXED (LSMEANS)
| Proven        : the known answer of the method lsmeans (src/methods.ts, worked
|                 out by tools/method_answers.R; node tools/methods_sas.ts); ran
|                 on SAS 9.4 M9, 2026-11-12
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| data        The records                                         Required
| where       The records to use, a condition in parentheses      Optional
| var         The response                                        Required
| by          The groups of the model: a character variable       Required
| within      One model in each group of these variables          Optional
| covars      The covariates                                      Optional
| class       The class factors                                   Optional
| pairs       all: each later group against each earlier one, in  all
|             the order of ORDER; or the pairs separated by #,
|             one pair per line, the group first, then the group
|             it is compared with (a value with a blank or a
|             hyphen in quotes): "Drug" "Placebo" # "High"
|             "Low". The form "A"-"B" of version 1.0 is still
|             read.
| order       A numeric variable with one value per group: the    Optional
|             order of the groups
| level       The confidence level (default 0.95)                 0.95
| stats       The statistics, each with its pattern (default      diff="XX.X"
|             diff="XX.X" diff_se="XX.XX" lcl="XX.X" ucl="XX.X"   diff_se="XX.XX" lcl="XX.X"
|             pval="X.XXX"); also lsmean, lsmean_se, lsmean_lcl   ucl="XX.X" pval="X.XXX"
|             and lsmean_ucl
| label       The label of the block in a table, in quotes        Optional
| out         The result                                          Required
| debug       yes: keep the work data sets of the macro           no
|             (_lsmeans_*)
|-------------------------------------------------------------------------------
|
| Output        : OUT: the rows of the differences (BY: the group, VERSUS: the group
|                 it is compared with) and of the LS means (VERSUS blank);
|                 GROUPS is BY VERSUS WITHIN.
|
| Example:
|
 %lsmeans(
     data   = adqsadas
   , where  = (paramcd = 'ACTOT' AND avisit = 'Week 24')
   , var    = chg
   , by     = trt01p
   , covars = base
   , class  = sitegr1
   , pairs  = all
   , order  = trt01pn
   , out    = pairs
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
| 27-NOV-2026 Sapling      1.9.1: lsmean_lcl and lsmean_ucl, the confidence
|                          limits of each LS mean (PROC MIXED, LSMEANS / CL).
|                          No number changes.
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
  %LOCAL t0 i item cond chars mstats dstats rows;
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
  PROC SORT DATA=_lsmeans_records NODUPKEY; BY &within. usubjid; RUN;

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
