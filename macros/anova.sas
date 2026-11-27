/*******************************************************************************
| Macro Name    : anova.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.9.1
| Created By    : Sapling
| Date          : 16NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : The one-way analysis of variance of a variable between groups
|                 (PROC GLM): the F test of the model (pval).
| Procedure     : PROC GLM
| Proven        : the known answer of the method anova (src/methods.ts, worked
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
| by          The groups to compare: one variable                 Required
| stats       The statistic and its pattern (default              pval="X.XXX"
|             pval="X.XXX")
| label       The label of the block in a table, in quotes        Optional
| out         The result                                          Required
| debug       yes: keep the work data set of the macro            no
|             (_anova_overall)
|-------------------------------------------------------------------------------
|
| Output        : OUT: one row, of all groups together (GROUPS is blank).
|
| Example:
|
 %anova(
     data  = adsl
   , var   = age
   , by    = trt01a
   , label = "Age (years)"
   , out   = age_test
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
