/*******************************************************************************
| Macro Name    : interaction_glm.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.9.1
| Created By    : Sapling
| Date          : 16NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : The test of the interaction of the treatment and a factor in a
|                 linear model, one record per subject (PROC GLM): the variable
|                 on the groups, the covariates, the class factors, the factor
|                 and the treatment-by-factor terms; the Type III F test of the
|                 treatment-by-factor terms (pval). For the term of the highest
|                 order this is the F test of the model with the factor against
|                 the same model with the terms.
| Procedure     : PROC GLM
| Proven        : the known answer of the method interaction-lm (src/methods.ts,
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
| by          The groups of the model: a character variable       Required
| factor      The factor of the subgroups: a variable whose       Required
|             values are its levels
| covars      The covariates                                      Optional
| class       The class factors                                   Optional
| stats       The statistic and its pattern (default              pval="X.XXX"
|             pval="X.XXX")
| label       The label of the block in a table, in quotes        Optional
| out         The result                                          Required
| debug       yes: keep the work data sets of the macro           no
|             (_interaction_glm_*)
|-------------------------------------------------------------------------------
|
| Output        : OUT: one row, of all groups and levels together (GROUPS is blank).
|
| Example:
|
 %interaction_glm(
     data   = adqsadas
   , where  = (paramcd = 'ACTOT' AND avisit = 'Week 24')
   , var    = chg
   , by     = trtp
   , factor = sex
   , covars = base
   , class  = sitegr1
   , label  = "Sex"
   , out    = sex_int
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
