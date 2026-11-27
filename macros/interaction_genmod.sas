/*******************************************************************************
| Macro Name    : interaction_genmod.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.9.1
| Created By    : Sapling
| Date          : 16NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : The test of the interaction of the treatment and a factor in a
|                 count model with its exposure, one record per subject (PROC
|                 GENMOD, the logarithm of the exposure the offset): Poisson or
|                 negative binomial (the dispersion k estimated in each model),
|                 the model of the groups, the covariates, the class factors and
|                 the factor, against the same with the treatment-by-factor
|                 terms. The likelihood-ratio test (pval): twice the difference
|                 of the full log likelihoods of the two fits, with the
|                 difference of the numbers of their estimated coefficients.
| Procedure     : PROC GENMOD
| Proven        : the known answer of the methods interaction-poisson,
|                 interaction-negbin (src/methods.ts, worked out by
|                 tools/method_answers.R; node tools/methods_sas.ts); ran on SAS
|                 9.4 M9, 2026-11-12
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| data        The records                                         Required
| where       The records to use, a condition in parentheses      Optional
| var         The count                                           Required
| by          The groups of the model: a character variable       Required
| factor      The factor of the subgroups: a variable whose       Required
|             values are its levels
| exposure    The exposure of each subject: a variable, or an     Required
|             expression of it. Above 0.
| covars      The covariates                                      Optional
| class       The class factors                                   Optional
| dist        poisson (default) or negbin                         poisson
| stats       The statistic and its pattern (default              pval="X.XXX"
|             pval="X.XXX")
| label       The label of the block in a table, in quotes        Optional
| out         The result                                          Required
| debug       yes: keep the work data sets of the macro           no
|             (_interaction_genmod_*)
|-------------------------------------------------------------------------------
|
| Output        : OUT: one row, of all groups and levels together (GROUPS is blank).
|
| Example:
|
 %interaction_genmod(
     data     = adsl
   , var      = exacnt
   , by       = trt01p
   , factor   = sex
   , exposure = trtdur / 365.25
   , dist     = negbin
   , label    = "Sex"
   , out      = sex_int
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
%MACRO interaction_genmod(
     data     =                /* The records */
   , where    =                /* The records to use: a condition in parentheses */
   , var      =                /* The count */
   , by       =                /* The groups of the model: a character variable */
   , factor   =                /* The factor of the subgroups */
   , exposure =                /* The exposure: a variable or an expression of it */
   , covars   =                /* The covariates */
   , class    =                /* The class factors */
   , dist     = poisson        /* poisson or negbin */
   , stats    = pval="X.XXX"   /* The statistic and its pattern */
   , label    =                /* The label of the block, in quotes */
   , out      =                /* The result */
   , debug    = no             /* yes: keep the work data sets _interaction_genmod_* */
) / DES = 'The likelihood-ratio test of the treatment-by-factor interaction, counts (PROC GENMOD)';
  %LOCAL t0 cond family k _ig_n0 _ig_n1;
  %LET t0 = %_spl_begin(interaction_genmod);

  /* Step 1: the parameters */
  %IF not %_spl_need(interaction_genmod, data var by factor exposure out) %THEN %RETURN;
  %IF not %_spl_vars(interaction_genmod, data, var by factor) %THEN %RETURN;
  %IF not %_spl_oneof(interaction_genmod, dist, poisson negbin nb) %THEN %RETURN;
  %IF not %_spl_oneof(interaction_genmod, debug, yes no) %THEN %RETURN;

  %LET family = %UPCASE(&dist.);  /* the family of the model, in upper case */
  %IF &family. = NEGBIN %THEN %LET family = NB;  /* NB is the SAS name of the negative binomial */
  /* the records that count */
  %LET cond = not missing(&var.) and not missing(&by.) and not missing(&factor.);
  %IF %LENGTH(%SUPERQ(where)) %THEN %LET cond = &cond. and &where.;  /* plus where= */

  /* Step 2: one record per subject with a count, a group, a level and its exposure */
  DATA _interaction_genmod_records;
    SET &data.;
    WHERE &cond.;
    _offset = LOG(&exposure.);
  RUN;
  PROC SORT DATA=_interaction_genmod_records NODUPKEY; BY usubjid; RUN;

  /* Step 3: no record qualified: the result without a row */
  %IF %_spl_nobs(_interaction_genmod_records) = 0 %THEN %DO;
    %_spl_empty(macro=interaction_genmod, out=&out., like=_interaction_genmod_records)
    %GOTO finish;
  %END;

  /* Step 4: the two models: 0 with the factor, 1 with the treatment by factor terms too */
  %DO k = 0 %TO 1;
    ODS EXCLUDE ALL;
    ODS OUTPUT ModelFit=_interaction_genmod_fit&k.(where = (criterion = 'Full Log Likelihood'))
               ParameterEstimates=_interaction_genmod_par&k.;
    PROC GENMOD DATA=_interaction_genmod_records;
      CLASS &class. &by. &factor.;
      MODEL &var. = &by. &covars. &class. &factor.
      %IF &k. = 1 %THEN &by.*&factor.; / DIST=&family. LINK=LOG OFFSET=_offset CONVERGE=1E-12;
    RUN;
    ODS EXCLUDE NONE;
  %END;

  /* Step 5: the number of estimated coefficients of each model */
  /* Not those set to 0, not the dispersion. */
  %DO k = 0 %TO 1;
    DATA _NULL_;
      SET _interaction_genmod_par&k.(WHERE=(df > 0 AND
                                            UPCASE(parameter) NOT IN ('DISPERSION' 'SCALE')))
          END=last;
      IF last THEN CALL SYMPUTX("_ig_n&k.", _N_);
    RUN;
  %END;

  /* Step 6: the likelihood ratio test of the treatment by factor terms: the result */
  DATA &out.;
    LENGTH groups block $200;
    MERGE _interaction_genmod_fit0(KEEP=value RENAME=(value = ll0))
          _interaction_genmod_fit1(KEEP=value RENAME=(value = ll1));
    pval   = 1 - PROBCHI(MAX(0, 2 * (ll1 - ll0)), &_ig_n1. - &_ig_n0.);
    groups = ' ';
    block  = DEQUOTE(%_spl_quote(label));
    %_spl_rows(stats=&stats.)
    KEEP groups block stat value text;
  RUN;

  /* Step 7: the work data sets are deleted (kept with debug=yes) */
  %finish:
  %IF %UPCASE(&debug.) ne YES %THEN %DO;
    PROC DATASETS LIBRARY=work NOLIST NOWARN;
      DELETE _interaction_genmod_:;
    QUIT;
  %END;
  %_spl_end(interaction_genmod, &t0., &debug.)
%MEND interaction_genmod;
