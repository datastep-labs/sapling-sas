/*******************************************************************************
| Macro Name    : interaction_phreg.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.9.1
| Created By    : Sapling
| Date          : 27NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : Returns the p-value of the treatment-by-subgroup interaction
|                 in a Cox model of a time to an event. Use %interaction_glm for
|                 a continuous variable, %interaction_logistic for a response,
|                 and %interaction_genmod for a count with its exposure. The
|                 macro writes a result: a data set with one row per number (the
|                 result shape, see %stack). The macro fits two models with PROC
|                 PHREG, in the strata of strata=: the groups, the covariates,
|                 the class factors and the factor; and the same model with the
|                 treatment-by-factor terms. pval is the likelihood-ratio test:
|                 the difference of the likelihood-ratio chi-squares of the two
|                 fits (twice the difference of the log partial likelihoods),
|                 with the difference of their degrees of freedom. The models
|                 use one record per subject: a record with a missing time,
|                 group or level is not used. CNSR 0 is an event and any
|                 positive value is a censoring, as in ADaM, where the value
|                 names the reason of the censoring: a CNSR of 2 is censored as
|                 1 is. A record used with a missing or negative CNSR stops the
|                 macro with an ERROR.
| Procedure     : PROC PHREG
| Proven        : the known answer of the method interaction-cox
|                 (src/methods.ts, worked out by tools/method_answers.R; node
|                 tools/methods_sas.ts); ran on SAS 9.4 M9, 2026-11-12
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| data        The input data set: one record per subject, with    Required
|             USUBJID, the time and the censoring variable
| where       The records to use: a condition in parentheses,     Optional
|             such as where = (ittfl = 'Y')
| var         The time: one numeric variable, such as aval        Required
| by          The groups of the model, the treatment: one         Required
|             variable
| factor      The factor of the subgroups: one variable whose     Required
|             values are its levels (factor = sex)
| cnsr        The censoring variable: one numeric variable, 0     CNSR
|             for an event and a positive value for a censoring
|             (the ADaM CNSR: 1, 2 ... name the reason). A
|             missing or negative value on a record used stops
|             the macro with an ERROR.
| covars      The numeric covariates of the model, separated by   Optional
|             blanks (covars = base)
| class       The other class factors of the model, separated by  Optional
|             blanks (class = sitegr1)
| strata      The strata of the models, separated by blanks       Optional
|             (strata = sitegr1). When not given, the models
|             have no strata.
| ties        The method for tied times: efron, breslow, or       efron
|             exact (TIES=DISCRETE of PROC PHREG). discrete is
|             accepted as another name of exact
| stats       The statistic with its pattern of the printed       pval="X.XXX"
|             number: pval
| label       The label of the block in the table: a text in      Optional
|             quotes. A block is the rows of one call in the
|             table.
| out         The name of the result data set                     Required
| debug       yes: keep the work data sets _interaction_phreg_*   no
|-------------------------------------------------------------------------------
|
| Output        : OUT: the result shape (see %stack), one row for all groups and
|                 levels together: GROUPS (blank), BLOCK, STAT (pval), VALUE and
|                 TEXT.
|
| Example:
|
 * Tests the treatment by sex interaction of the time to the event in a Cox model.;
 %interaction_phreg(
     data   = adttde
   , var    = aval
   , by     = trt01a
   , factor = sex
   , label  = "Sex"
   , out    = ttde_int
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
| 27-NOV-2026 Sapling      1.9.1: the example runs on the example data
|                          (sas/examples). The text of the header for the
|                          manual: the summary, the form of each parameter. No
|                          number changes.
| 27-NOV-2026 Sapling      1.9.1: CNSR as in ADaM: 0 is an event and any positive
|                          value a censoring (before, only 1 was a censoring and
|                          2 an event); a missing or negative CNSR on a record
|                          used stops the macro with an ERROR. No number changes
|                          on data with CNSR 0 and 1.
| 27-NOV-2026 Sapling      1.9.1: a caption for each call of the example (a
|                          comment line before it). No number changes.
|
*******************************************************************************/
%MACRO interaction_phreg(
     data   =                /* The records */
   , where  =                /* The records to use: a condition in parentheses */
   , var    =                /* The time */
   , by     =                /* The groups of the model: a character variable */
   , factor =                /* The factor of the subgroups */
   , cnsr   = CNSR           /* The censoring variable: 0 = event, > 0 censored */
   , covars =                /* The covariates */
   , class  =                /* The class factors */
   , strata =                /* The strata variables */
   , ties   = efron          /* efron, breslow or exact */
   , stats  = pval="X.XXX"   /* The statistic and its pattern */
   , label  =                /* The label of the block, in quotes */
   , out    =                /* The result */
   , debug  = no             /* yes: keep the work data sets _interaction_phreg_* */
) / DES = 'The likelihood-ratio test of the treatment-by-factor interaction (PROC PHREG)';
  %LOCAL t0 cond method k nbad;
  %LET t0 = %_spl_begin(interaction_phreg);

  /* Step 1: the parameters */
  %IF not %_spl_need(interaction_phreg, data var by factor out) %THEN %RETURN;
  %IF not %_spl_vars(interaction_phreg, data, var by factor cnsr strata) %THEN %RETURN;
  %IF not %_spl_oneof(interaction_phreg, ties, efron breslow exact discrete) %THEN %RETURN;
  %IF not %_spl_oneof(interaction_phreg, debug, yes no) %THEN %RETURN;

  /* the records that count */
  %LET cond = not missing(&var.) and not missing(&by.) and not missing(&factor.);
  %IF %LENGTH(%SUPERQ(where)) %THEN %LET cond = &cond. and &where.;  /* plus where= */
  %LET method = %UPCASE(&ties.);  /* the method of ties, in upper case */
  %IF &method. = EXACT %THEN %LET method = DISCRETE;  /* DISCRETE is the SAS name of exact ties */

  /* Step 2: one record per subject with a time, a group and a level */
  DATA _interaction_phreg_records;
    SET &data.;
    WHERE &cond.;
    /* CNSR 0 is an event; a positive value is a censoring, with its reason */
    IF &cnsr. > 0 THEN _cens = 1;
    ELSE               _cens = 0;
  RUN;
  PROC SORT DATA=_interaction_phreg_records NODUPKEY; BY usubjid; RUN;
  /* a missing or negative CNSR is neither an event nor a censoring */
  %LET nbad = %_spl_nobs(_interaction_phreg_records(WHERE=(MISSING(&cnsr.) OR &cnsr. < 0)));
  %IF &nbad. > 0 %THEN %DO;
    %PUT %STR(ERR)OR: [interaction_phreg] cnsr=&cnsr. is missing or negative on &nbad. record(s);
    %PUT %STR(ERR)OR: [interaction_phreg]   fix: give each record CNSR 0 (event) or more (censor).;
    %GOTO finish;
  %END;

  /* Step 3: no record qualified: the result without a row */
  %IF %_spl_nobs(_interaction_phreg_records) = 0 %THEN %DO;
    %_spl_empty(macro=interaction_phreg, out=&out., like=_interaction_phreg_records)
    %GOTO finish;
  %END;

  /* Step 4: the two models: 0 with the factor, 1 with the treatment by factor terms too */
  %DO k = 0 %TO 1;
    ODS EXCLUDE ALL;
    ODS OUTPUT GlobalTests=_interaction_phreg_g&k.(where = (test = 'Likelihood Ratio'));
    PROC PHREG DATA=_interaction_phreg_records;
      CLASS &class. &by. &factor. / PARAM=GLM;
      MODEL &var. * _cens(1) = &by. &class. &covars. &factor.
      %IF &k. = 1 %THEN &by.*&factor.; / TIES=&method.;
      %IF %LENGTH(&strata.) %THEN %DO;
        STRATA &strata.;
      %END;
    RUN;
    ODS EXCLUDE NONE;
  %END;

  /* Step 5: the likelihood ratio test of the treatment by factor terms: the result */
  DATA &out.;
    LENGTH groups block $200;
    MERGE _interaction_phreg_g0(RENAME=(chisq = chisq0 df = df0))
          _interaction_phreg_g1(RENAME=(chisq = chisq1 df = df1));
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
      DELETE _interaction_phreg_:;
    QUIT;
  %END;
  %_spl_end(interaction_phreg, &t0., &debug.)
%MEND interaction_phreg;
