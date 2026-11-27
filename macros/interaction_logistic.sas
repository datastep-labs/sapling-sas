/*******************************************************************************
| Macro Name    : interaction_logistic.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.10.0
| Created By    : Sapling
| Date          : 27NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : Returns the p-value of the treatment-by-subgroup interaction
|                 in a logistic regression of a response. Use %interaction_glm
|                 for a continuous variable, %interaction_genmod for a count
|                 with its exposure, and %interaction_phreg for a time to an
|                 event. The macro writes a result: a data set with one row per
|                 number (the result shape, see %stack). The macro fits two
|                 models with PROC LOGISTIC: the groups, the covariates, the
|                 class factors and the factor; and the same model with the
|                 treatment-by-factor terms. pval is the likelihood-ratio test:
|                 the difference of the likelihood-ratio chi-squares of the two
|                 fits, with the difference of their degrees of freedom. The
|                 models use one record per subject: a record with a missing
|                 response, group or level is not used.
| Procedure     : PROC LOGISTIC
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
| var         The response: one variable, such as avalc           Required
| event       The value of the response that is the event: a      "Y"
|             text in quotes ("Y")
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
| debug       yes: keep the work data sets                        no
|             _interaction_logistic_*
|-------------------------------------------------------------------------------
|
| Output        : OUT: the result shape (see %stack), one row for all groups and
|                 levels together: GROUPS (blank), BLOCK, STAT (pval), VALUE and
|                 TEXT.
|
| Example:
|
 * Tests the treatment by sex interaction of discontinuation in a logistic model with age.;
 %interaction_logistic(
     data   = adsl
   , var    = eosstt
   , event  = "DISCONTINUED"
   , by     = trt01a
   , factor = sex
   , covars = age
   , label  = "Sex"
   , out    = eos_int
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
| 27-NOV-2026 Sapling      1.10.0: a caption for each call of the example (a
|                          comment line before it). No number changes.
| 27-NOV-2026 Sapling      1.10.0: Proven in plain words, for the published
|                          manual. No number changes.
|
*******************************************************************************/
%MACRO interaction_logistic(
     data   =                /* The records */
   , where  =                /* The records to use: a condition in parentheses */
   , var    =                /* The response */
   , event  = "Y"            /* The value that is the event, in quotes */
   , by     =                /* The groups of the model: a character variable */
   , factor =                /* The factor of the subgroups */
   , covars =                /* The covariates */
   , class  =                /* The class factors */
   , stats  = pval="X.XXX"   /* The statistic and its pattern */
   , label  =                /* The label of the block, in quotes */
   , out    =                /* The result */
   , debug  = no             /* yes: keep the work data sets _interaction_logistic_* */
) / DES = 'The likelihood-ratio test of the treatment-by-factor interaction (PROC LOGISTIC)';
  %LOCAL t0 cond k;
  %LET t0 = %_spl_begin(interaction_logistic);

  /* Step 1: the parameters */
  %IF not %_spl_need(interaction_logistic, data var by factor out) %THEN %RETURN;
  %IF not %_spl_vars(interaction_logistic, data, var by factor) %THEN %RETURN;
  %IF not %_spl_oneof(interaction_logistic, debug, yes no) %THEN %RETURN;

  /* the records that count */
  %LET cond = not missing(&var.) and not missing(&by.) and not missing(&factor.);
  %IF %LENGTH(%SUPERQ(where)) %THEN %LET cond = &cond. and &where.;  /* plus where= */

  /* Step 2: one record per subject with a response, a group and a level */
  DATA _interaction_logistic_records;
    SET &data.;
    WHERE &cond.;
  RUN;
  PROC SORT DATA=_interaction_logistic_records NODUPKEY; BY usubjid; RUN;

  /* Step 3: no record qualified: the result without a row */
  %IF %_spl_nobs(_interaction_logistic_records) = 0 %THEN %DO;
    %_spl_empty(macro=interaction_logistic, out=&out., like=_interaction_logistic_records)
    %GOTO finish;
  %END;

  /* Step 4: the two models: 0 with the factor, 1 with the treatment by factor terms too */
  %DO k = 0 %TO 1;
    ODS EXCLUDE ALL;
    ODS OUTPUT GlobalTests=_interaction_logistic_g&k.(where = (test = 'Likelihood Ratio'));
    PROC LOGISTIC DATA=_interaction_logistic_records;
      CLASS &class. &by. &factor. / PARAM=GLM;
      MODEL &var.(event = &event.) = &by. &covars. &class. &factor.
      %IF &k. = 1 %THEN &by.*&factor.; / GCONV = 1E-10;
    RUN;
    ODS EXCLUDE NONE;
  %END;

  /* Step 5: the likelihood ratio test of the treatment by factor terms: the result */
  DATA &out.;
    LENGTH groups block $200;
    MERGE _interaction_logistic_g0(RENAME=(chisq = chisq0 df = df0))
          _interaction_logistic_g1(RENAME=(chisq = chisq1 df = df1));
    pval   = 1 - PROBCHI(MAX(0, chisq1 - chisq0), df1 - df0);
    groups = ' ';
    block  = DEQUOTE(%_spl_quote(label));
    %_spl_rows(stats=&stats.)
    KEEP groups block stat value text;
  RUN;

  /* Step 6: the work data sets are deleted (kept with debug=yes) */
  %finish:
  %IF %UPCASE(&debug.) ne YES %THEN %DO;
    PROC DATASETS LIBRARY=work NOLIST NOWARN;
      DELETE _interaction_logistic_:;
    QUIT;
  %END;
  %_spl_end(interaction_logistic, &t0., &debug.)
%MEND interaction_logistic;
