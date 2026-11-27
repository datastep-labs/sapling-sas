/*******************************************************************************
| Macro Name    : interaction_phreg.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.9.1
| Created By    : Sapling
| Date          : 16NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : The test of the interaction of the treatment and a factor in a
|                 Cox model, one record per subject (PROC PHREG): the model of
|                 the groups, the covariates, the class factors and the factor,
|                 stratified by the strata, against the same with the
|                 treatment-by-factor terms. The likelihood-ratio test (pval):
|                 the difference of the likelihood-ratio chi-squares of the two
|                 fits (twice the difference of the log partial likelihoods),
|                 with the difference of their degrees of freedom.
| Procedure     : PROC PHREG
| Proven        : the known answer of the method interaction-cox
|                 (src/methods.ts, worked out by tools/method_answers.R; node
|                 tools/methods_sas.ts); ran on SAS 9.4 M9, 2026-11-12
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| data        The records                                         Required
| where       The records to use, a condition in parentheses      Optional
| var         The time                                            Required
| by          The groups of the model: a character variable       Required
| factor      The factor of the subgroups: a variable whose       Required
|             values are its levels
| cnsr        The censoring variable: 1 = censored (default       CNSR
|             CNSR)
| covars      The covariates                                      Optional
| class       The class factors                                   Optional
| strata      The strata variables, separated by blanks           Optional
| ties        efron (default), breslow, or exact                  efron
|             (TIES=DISCRETE)
| stats       The statistic and its pattern (default              pval="X.XXX"
|             pval="X.XXX")
| label       The label of the block in a table, in quotes        Optional
| out         The result                                          Required
| debug       yes: keep the work data sets of the macro           no
|             (_interaction_phreg_*)
|-------------------------------------------------------------------------------
|
| Output        : OUT: one row, of all groups and levels together (GROUPS is blank).
|
| Example:
|
 %interaction_phreg(
     data   = adtte
   , where  = (paramcd = 'PFS')
   , var    = aval
   , by     = trt01p
   , factor = sex
   , strata = strat1
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
%MACRO interaction_phreg(
     data   =                /* The records */
   , where  =                /* The records to use: a condition in parentheses */
   , var    =                /* The time */
   , by     =                /* The groups of the model: a character variable */
   , factor =                /* The factor of the subgroups */
   , cnsr   = CNSR           /* The censoring variable: 1 = censored */
   , covars =                /* The covariates */
   , class  =                /* The class factors */
   , strata =                /* The strata variables */
   , ties   = efron          /* efron, breslow or exact */
   , stats  = pval="X.XXX"   /* The statistic and its pattern */
   , label  =                /* The label of the block, in quotes */
   , out    =                /* The result */
   , debug  = no             /* yes: keep the work data sets _interaction_phreg_* */
) / DES = 'The likelihood-ratio test of the treatment-by-factor interaction (PROC PHREG)';
  %LOCAL t0 cond method k;
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
  RUN;
  PROC SORT DATA=_interaction_phreg_records NODUPKEY; BY usubjid; RUN;

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
      MODEL &var. * &cnsr.(1) = &by. &class. &covars. &factor.
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
