/*******************************************************************************
| Macro Name    : interaction_glm.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.10.0
| Created By    : Sapling
| Date          : 27NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : Returns the p-value of the treatment-by-subgroup interaction
|                 in a linear model of a continuous variable. Use
|                 %interaction_logistic for a response, %interaction_genmod for
|                 a count with its exposure, and %interaction_phreg for a time
|                 to an event. The macro writes a result: a data set with one
|                 row per number (the result shape, see %stack). The model has
|                 the groups, the covariates, the class factors, the factor and
|                 the treatment-by-factor terms. pval is the Type III F test of
|                 the treatment-by-factor terms (PROC GLM). For this term of the
|                 highest order, the test is the same as the F test of the model
|                 with the terms against the model without them. The model uses
|                 one record per subject: a record with a missing value, group
|                 or level is not used.
| Procedure     : PROC GLM
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
|             such as where = (ittfl = 'Y')
| var         The variable of the model: one numeric variable,    Required
|             such as chg
| by          The groups of the model, the treatment: one         Required
|             variable
| factor      The factor of the subgroups: one variable whose     Required
|             values are its levels (factor = sex)
| covars      The numeric covariates of the model, separated by   Optional
|             blanks (covars = base)
| class       The other class factors of the model, separated by  Optional
|             blanks (class = sitegr1)
| stats       The statistic with its pattern of the printed       pval="X.XXX"
|             number: pval
| label       The label of the block in the table: a text in      Optional
|             quotes. A block is the rows of one call in the
|             table.
| out         The name of the result data set                     Required
| debug       yes: keep the work data sets _interaction_glm_*     no
|-------------------------------------------------------------------------------
|
| Output        : OUT: the result shape (see %stack), one row for all groups and
|                 levels together: GROUPS (blank), BLOCK, STAT (pval), VALUE and
|                 TEXT.
|
| Example:
|
 * Tests the treatment by sex interaction of the change at Week 12, adjusted for baseline.;
 %interaction_glm(
     data   = advs
   , where  = (paramcd = 'SYSBP' AND avisit = 'Week 12' AND anl01fl = 'Y')
   , var    = chg
   , by     = trt01p
   , factor = sex
   , covars = base
   , label  = "Sex"
   , out    = sbp_int
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
| 27-NOV-2026 Sapling      1.10.0: the example runs on the example data
|                          (sas/examples). The text of the header for the
|                          manual: the summary, the form of each parameter. No
|                          number changes.
| 27-NOV-2026 Sapling      1.10.0: The example analyses the records of anl01fl =
|                          'Y' (one record per subject). No number changes.
| 27-NOV-2026 Sapling      1.10.0: a caption for each call of the example (a
|                          comment line before it). No number changes.
| 27-NOV-2026 Sapling      1.10.0: Proven in plain words, for the published
|                          manual. No number changes.
|
*******************************************************************************/
%MACRO interaction_glm(
     data   =                /* The records */
   , where  =                /* The records to use: a condition in parentheses */
   , var    =                /* The variable */
   , by     =                /* The groups of the model: a character variable */
   , factor =                /* The factor of the subgroups */
   , covars =                /* The covariates */
   , class  =                /* The class factors */
   , stats  = pval="X.XXX"   /* The statistic and its pattern */
   , label  =                /* The label of the block, in quotes */
   , out    =                /* The result */
   , debug  = no             /* yes: keep the work data sets _interaction_glm_* */
) / DES = 'The F test of the treatment-by-factor interaction in a linear model (PROC GLM)';
  %LOCAL t0 cond;
  %LET t0 = %_spl_begin(interaction_glm);

  /* Step 1: the parameters */
  %IF not %_spl_need(interaction_glm, data var by factor out) %THEN %RETURN;
  %IF not %_spl_vars(interaction_glm, data, var by factor) %THEN %RETURN;
  %IF not %_spl_oneof(interaction_glm, debug, yes no) %THEN %RETURN;

  /* the records that count */
  %LET cond = not missing(&var.) and not missing(&by.) and not missing(&factor.);
  %IF %LENGTH(%SUPERQ(where)) %THEN %LET cond = &cond. and &where.;  /* plus where= */

  /* Step 2: one record per subject with a value, a group and a level */
  DATA _interaction_glm_records;
    SET &data.;
    WHERE &cond.;
  RUN;
  PROC SORT DATA=_interaction_glm_records NODUPKEY; BY usubjid; RUN;

  /* Step 3: no record qualified: the result without a row */
  %IF %_spl_nobs(_interaction_glm_records) = 0 %THEN %DO;
    %_spl_empty(macro=interaction_glm, out=&out., like=_interaction_glm_records)
    %GOTO finish;
  %END;

  /* Step 4: the model with the factor and the treatment by factor terms: their Type III F test */
  ODS EXCLUDE ALL;
  ODS OUTPUT ModelANOVA=_interaction_glm_anova;
  PROC GLM DATA=_interaction_glm_records;
    CLASS &class. &by. &factor.;
    MODEL &var. = &by. &covars. &class. &factor. &by.*&factor. / ss3;
  RUN;
  QUIT;
  ODS EXCLUDE NONE;

  /* Step 5: the F test of the treatment by factor terms: the result */
  DATA &out.;
    LENGTH groups block $200;
    SET _interaction_glm_anova(WHERE=(UPCASE(source) = UPCASE("&by.*&factor."))
                               RENAME=(probf = pval));
    groups = ' ';
    block  = DEQUOTE(%_spl_quote(label));
    %_spl_rows(stats=&stats.)
    KEEP groups block stat value text;
  RUN;

  /* Step 6: the work data sets are deleted (kept with debug=yes) */
  %finish:
  %IF %UPCASE(&debug.) ne YES %THEN %DO;
    PROC DATASETS LIBRARY=work NOLIST NOWARN;
      DELETE _interaction_glm_:;
    QUIT;
  %END;
  %_spl_end(interaction_glm, &t0., &debug.)
%MEND interaction_glm;
