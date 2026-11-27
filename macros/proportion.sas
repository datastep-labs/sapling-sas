/*******************************************************************************
| Macro Name    : proportion.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.9.1
| Created By    : Sapling
| Date          : 27NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : Returns the percent of subjects in each category and group,
|                 with its confidence interval by a method you name. Use %freq
|                 for counts and percents without an interval. The macro writes
|                 a result: a data set with one row per number (the result
|                 shape, see %stack). The statistics are n, pct, and lcl and
|                 ucl: the limits of the interval, in percent like pct. A
|                 subject is counted once in each category. The percent is of
|                 the subjects of the group in denom=. The interval comes from
|                 the BINOMIAL option of PROC FREQ.
| Procedure     : PROC FREQ (BINOMIAL)
| Proven        : the known answer of the method propci (src/methods.ts, worked
|                 out by tools/method_answers.R; node tools/methods_sas.ts); ran
|                 on SAS 9.4 M9, 2026-11-12
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| data        The input data set: the records, with USUBJID       Required
| denom       The subjects of the percent: a data set with one    Optional
|             row per subject and the variable of by=. When not
|             given, the subjects of data= (without where=).
| where       The records to use: a condition in parentheses,     Optional
|             such as where = (avisit = 'Week 24')
| var         The category: one variable                          Required
| by          The groups: one variable, the columns of the table  Required
| levels      The planned categories: the variable, then its      Optional
|             values in quotes (levels = avalc 'CR' 'PR'). A
|             planned category without a subject shows with n =
|             0.
| ci          The method of the interval: clopper-pearson (the    clopper-pearson
|             exact interval, CL=EXACT; exact is another name
|             for it), wilson (the score interval, CL=WILSON),
|             wald (CL=WALD) or agresti-coull (CL=AGRESTICOULL)
| level       The confidence level: a number between 0 and 1      0.95
|             (level = 0.90)
| stats       The statistics, in the order of the rows: each      n="XX" pct="(XX.X%)"
|             name with its pattern of the printed number,        lcl="XX.X" ucl="XX.X"
|             separated by blanks. The names are n, pct, lcl and
|             ucl. A name without a pattern takes its default
|             pattern (n="XX", mean="XX.X", pval="X.XXX" ...;
|             see %describe).
| label       The label of the block in the table: a text in      Optional
|             quotes. A block is the rows of one call in the
|             table.
| out         The name of the result data set                     Required
| debug       yes: keep the work data sets _proportion_*          no
|-------------------------------------------------------------------------------
|
| Output        : OUT: the result shape (see %stack), one row per group,
|                 category and statistic: the variables of by= and var=, GROUPS
|                 (by= and var=), BLOCK, STAT, VALUE and TEXT. When no record
|                 qualifies and levels= is not given, the result has no row.
|
| Example:
|
 * Gives the percent that completed and that discontinued, each with its Clopper Pearson limits.;
 %proportion(
     data   = adsl
   , var    = eosstt
   , by     = trt01a
   , levels = eosstt 'COMPLETED' 'DISCONTINUED'
   , ci     = clopper-pearson
   , out    = eos_ci
 )
 * Gives the percent of the best responses CR and PR of the N of denom=, with Wilson limits.;
 %proportion(
     data   = adrs
   , denom  = adsl
   , where  = (paramcd = 'BOR')
   , var    = avalc
   , by     = trt01a
   , levels = avalc 'CR' 'PR'
   , ci     = wilson
   , out    = bor_ci
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
| 12-NOV-2026 Sapling      1.1.0: the label is written into the code
|                          (%_spl_quote), not read by SYMGET when the step
|                          runs: the flat program has it. No number changes.
| 16-NOV-2026 Sapling      1.9.0: the license line; the example in the house
|                          case (names in lower case). No number changes.
| 16-NOV-2026 Sapling      1.9.1: no record: the result without a row and the
|                          NOTE No data qualified, not ERRORs of PROC FREQ
|                          (DEV-035); the header names exact as another name of
|                          clopper-pearson (DEV-042). No number changes.
| 27-NOV-2026 Sapling      1.9.1: the example runs on the example data
|                          (sas/examples). The text of the header for the
|                          manual: the summary, the form of each parameter. No
|                          number changes.
| 27-NOV-2026 Sapling      1.9.1: The text of stats=: a name without a pattern
|                          takes its default pattern. No number changes.
| 27-NOV-2026 Sapling      1.9.1: a caption for each call of the example (a
|                          comment line before it). No number changes.
|
*******************************************************************************/
%MACRO proportion(
     data   =                  /* The records */
   , denom  =                  /* The subjects of the percent (default: data=) */
   , where  =                  /* The records to use: a condition in parentheses */
   , var    =                  /* The category */
   , by     =                  /* The groups: one variable */
   , levels =                  /* The planned categories: the variable, values */
   , ci     = clopper-pearson  /* clopper pearson, wilson, wald, agresti coull */
   , level  = 0.95             /* The confidence level */
   , stats  = n="XX" pct="(XX.X%)" lcl="XX.X" ucl="XX.X"
                               /* The statistics, each with its pattern */
   , label  =                  /* The label of the block, in quotes */
   , out    =                  /* The result */
   , debug  = no               /* yes: keep the work data sets _proportion_* */
) / DES = 'The percent of subjects in each category and group with its interval (PROC FREQ)';
  %LOCAL t0 chars cl;
  %LET t0 = %_spl_begin(proportion);

  /* Step 1: the parameters */
  %IF not %_spl_need(proportion, data var by out) %THEN %RETURN;
  %IF not %_spl_vars(proportion, data, var by) %THEN %RETURN;
  %IF not %_spl_oneof(proportion, debug, yes no) %THEN %RETURN;

  %LET by    = %UPCASE(&by.);  /* the groups, in upper case */
  %LET var   = %UPCASE(&var.);  /* the variable, in upper case */
  %LET chars = %_spl_chars(&data., &by. &var.);  /* the character variables */
  %LET cl    = %SYSFUNC(COMPRESS(%UPCASE(&ci.), -));  /* the interval, no hyphens */
  %IF &cl. = CLOPPERPEARSON %THEN %LET cl = EXACT;  /* EXACT is the SAS name of Clopper Pearson */
  %IF not %SYSFUNC(INDEXW(EXACT WILSON WALD AGRESTICOULL, &cl.)) %THEN %DO;
    %PUT %STR(ERR)OR: [proportion] ci=&ci. is not one of: clopper-pearson wilson wald agresti-coull;
    %PUT %STR(ERR)OR: [proportion]   fix: give ci= one of them.;
    %RETURN;
  %END;
  %IF not %LENGTH(&denom.) %THEN %LET denom = &data.;  /* the default: the records of data= */

  /* Step 2: each subject once in each group and category */
  DATA _proportion_records;
    %IF %LENGTH(&chars.) %THEN %DO;
      LENGTH &chars. $200;
    %END;
    SET &data.;
    %IF %LENGTH(%SUPERQ(where)) %THEN %DO;
      WHERE &where.;
    %END;
    IF CMISS(&by., &var.) = 0;
    KEEP usubjid &by. &var.;
  RUN;
  /* no record qualified and no category planned: the result without a row */
  %IF %_spl_nobs(_proportion_records) = 0 and %LENGTH(&levels.) = 0 %THEN %DO;
    %_spl_empty(macro=proportion, out=&out., like=_proportion_records, keep=&by. &var.)
    %GOTO finish;
  %END;
  PROC SORT DATA=_proportion_records NODUPKEY; BY &by. &var. usubjid; RUN;

  /* Step 3: the subjects of each group (the denominator) and of each group and category */
  DATA _proportion_denom;
    %IF %SYSFUNC(INDEXW(%STR( )&chars., &by.)) %THEN %DO;
      LENGTH &by. $200;
    %END;
    SET &denom.(KEEP=usubjid &by.);
    IF NOT MISSING(&by.);
  RUN;
  PROC SORT DATA=_proportion_denom NODUPKEY; BY &by. usubjid; RUN;
  PROC FREQ DATA=_proportion_denom NOPRINT;
    TABLES &by. / OUT=_proportion_bign(KEEP=&by. count RENAME=(count = _bign));
  RUN;
  PROC FREQ DATA=_proportion_records NOPRINT;
    TABLES &by. * &var. / OUT=_proportion_n(KEEP=&by. &var. count RENAME=(count = n)) SPARSE;
  RUN;
  %IF %LENGTH(&levels.) %THEN %DO;

    /* Step 4: the categories of the plan in every group (n = 0 where nobody is in one) */
    DATA _proportion_lv;
      %_spl_levels(levels=&levels., data=&data.)
    RUN;
    DATA _proportion_grid;
      SET _proportion_bign(KEEP=&by.);
      DO _i = 1 TO _nlv;
        SET _proportion_lv POINT=_i NOBS=_nlv;
        OUTPUT;
      END;
      DROP _i;
    RUN;
    PROC SORT DATA=_proportion_grid; BY &by. &var.; RUN;
    PROC SORT DATA=_proportion_n; BY &by. &var.; RUN;
    DATA _proportion_n;
      MERGE _proportion_grid(IN=planned) _proportion_n;
      BY &by. &var.;
      IF planned;
      IF MISSING(n) THEN n = 0;
    RUN;
  %END;

  /* Step 5: each group and category: the subjects in it (_hit = 1), the others (_hit = 2) */
  PROC SORT DATA=_proportion_n; BY &by.; RUN;
  DATA _proportion_w;
    MERGE _proportion_n(IN=inn) _proportion_bign;
    BY &by.;
    IF inn;
    IF MISSING(n) THEN n = 0;
    _hit   = 1;
    _count = n;
    OUTPUT;
    _hit   = 2;
    _count = _bign - n;
    OUTPUT;
  RUN;
  PROC SORT DATA=_proportion_w; BY &by. &var. _hit; RUN;

  /* Step 6: the proportion of each group and category and its interval */
  ODS EXCLUDE ALL;
  ODS OUTPUT BinomialCLs=_proportion_cls;
  PROC FREQ DATA=_proportion_w;
    BY &by. &var.;
    WEIGHT _count / ZEROS;
    TABLES _hit / BINOMIAL(level = '1' cl = &cl.) ALPHA=%SYSEVALF(1 - &level.);
  RUN;
  ODS EXCLUDE NONE;

  /* Step 7: one row per group, category and statistic: the result */
  DATA &out.;
    LENGTH groups block $200;
    MERGE _proportion_w(WHERE=(_hit = 1) KEEP=&by. &var. _hit n _bign)
          _proportion_cls(KEEP=&by. &var. lowercl uppercl);
    BY &by. &var.;
    pct    = 100 * n / _bign;
    lcl    = 100 * lowercl;
    ucl    = 100 * uppercl;
    groups = "&by. &var.";
    block  = DEQUOTE(%_spl_quote(label));
    %_spl_rows(stats=&stats.)
    KEEP &by. &var. groups block stat value text;
  RUN;

  /* Step 8: the work data sets are deleted (kept with debug=yes) */
  %finish:
  %IF %UPCASE(&debug.) ne YES %THEN %DO;
    PROC DATASETS LIBRARY=work NOLIST NOWARN;
      DELETE _proportion_:;
    QUIT;
  %END;
  %_spl_end(proportion, &t0., &debug.)
%MEND proportion;
