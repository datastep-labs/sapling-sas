/*******************************************************************************
| Macro Name    : anova.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.10.0
| Created By    : Sapling
| Date          : 27NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : Returns the p-value of the F test of a one-way analysis of
|                 variance of a variable between the groups. Use %ttest or
|                 %wilcoxon to compare pairs of groups, and %ancova when the
|                 model has covariates. The macro writes a result: a data set
|                 with one row per number (the result shape, see %stack). The
|                 model is var= by by= (PROC GLM). The p-value is that of the
|                 model, one test of all the groups together. A record with a
|                 missing value or a missing group is not used.
| Procedure     : PROC GLM
| Proven        : Checked against its known answer (on a small data set, the
|                 numbers worked out independently in R); ran on SAS 9.4 M9,
|                 2026-11-12
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| data        The input data set                                  Required
| where       The records to use: a condition in parentheses,     Optional
|             such as where = (anl01fl = 'Y')
| var         The variable to analyse: one numeric variable       Required
| by          The groups to compare: one variable                 Required
| stats       The statistic with its pattern of the printed       pval="X.XXX"
|             number: pval
| label       The label of the block in the table: a text in      Optional
|             quotes. A block is the rows of one call in the
|             table.
| out         The name of the result data set                     Required
| debug       yes: keep the work data sets _anova_*               no
|-------------------------------------------------------------------------------
|
| Output        : OUT: the result shape (see %stack), one row: STAT pval, with
|                 GROUPS blank (all the groups together), BLOCK, VALUE and TEXT.
|                 When no record qualifies, the result has no row.
|
| Example:
|
 * Tests age across the three groups: one row, the p value of the F test.;
 %anova(
     data  = adsl
   , var   = age
   , by    = trt01a
   , label = "Age (years)"
   , out   = age_anova
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
| 27-NOV-2026 Sapling      1.10.0: the text of the header for the manual: the
|                          summary, the form of each parameter. No number
|                          changes.
| 27-NOV-2026 Sapling      1.10.0: The example result is age_anova, the name
|                          %stack reads. No number changes.
| 27-NOV-2026 Sapling      1.10.0: a caption for each call of the example (a
|                          comment line before it). No number changes.
| 27-NOV-2026 Sapling      1.10.0: Proven in plain words, for the published
|                          manual. No number changes.
|
*******************************************************************************/
%MACRO anova(
     data  =                /* The records */
   , where =                /* The records to use: a condition in parentheses */
   , var   =                /* The variable */
   , by    =                /* The groups to compare: one variable */
   , stats = pval="X.XXX"   /* The statistic and its pattern */
   , label =                /* The label of the block, in quotes */
   , out   =                /* The result */
   , debug = no             /* yes: keep the work data sets _anova_* */
) / DES = 'The F test of a one-way analysis of variance (PROC GLM)';
  %LOCAL t0 cond;
  %LET t0 = %_spl_begin(anova);

  /* Step 1: the parameters */
  %IF not %_spl_need(anova, data var by out) %THEN %RETURN;
  %IF not %_spl_vars(anova, data, var by) %THEN %RETURN;
  %IF not %_spl_oneof(anova, debug, yes no) %THEN %RETURN;

  %LET cond = not missing(&var.) and not missing(&by.);  /* the records that count */
  %IF %LENGTH(%SUPERQ(where)) %THEN %LET cond = &cond. and &where.;  /* plus where= */

  /* Step 2: the records of the test, counted (the model reads them from data= as before) */
  DATA _anova_records;
    SET &data.;
    WHERE &cond.;
  RUN;

  /* Step 3: no record qualified: the result without a row */
  %IF %_spl_nobs(_anova_records) = 0 %THEN %DO;
    %_spl_empty(macro=anova, out=&out., like=_anova_records)
    %GOTO finish;
  %END;

  /* Step 4: the model: the variable by the groups */
  ODS EXCLUDE ALL;
  ODS OUTPUT OverallANOVA=_anova_overall;
  PROC GLM DATA=&data.;
    WHERE &cond.;
    CLASS &by.;
    MODEL &var. = &by.;
  RUN;
  QUIT;
  ODS EXCLUDE NONE;

  /* Step 5: the F test of the model: the result */
  DATA &out.;
    LENGTH groups block $200;
    SET _anova_overall(WHERE=(source = 'Model') RENAME=(probf = pval));
    groups = ' ';
    block  = DEQUOTE(%_spl_quote(label));
    %_spl_rows(stats=&stats.)
    KEEP groups block stat value text;
  RUN;

  /* Step 6: the work data sets are deleted (kept with debug=yes) */
  %finish:
  %IF %UPCASE(&debug.) ne YES %THEN %DO;
    PROC DATASETS LIBRARY=work NOLIST NOWARN;
      DELETE _anova_:;
    QUIT;
  %END;
  %_spl_end(anova, &t0., &debug.)
%MEND anova;
