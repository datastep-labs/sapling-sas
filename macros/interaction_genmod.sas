/*******************************************************************************
| Macro Name    : interaction_genmod.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.10.0
| Created By    : Sapling
| Date          : 27NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : Returns the p-value of the treatment-by-subgroup interaction
|                 in a Poisson or negative binomial model of a count. Use
|                 %interaction_glm for a continuous variable,
|                 %interaction_logistic for a response, and %interaction_phreg
|                 for a time to an event. The macro writes a result: a data set
|                 with one row per number (the result shape, see %stack). The
|                 macro fits two models with PROC GENMOD, with the logarithm of
|                 the exposure as the offset: the groups, the covariates, the
|                 class factors and the factor; and the same model with the
|                 treatment-by-factor terms. In a negative binomial model, each
|                 fit estimates its own dispersion k. pval is the
|                 likelihood-ratio test: twice the difference of the full log
|                 likelihoods of the two fits, with the difference of the
|                 numbers of their estimated coefficients. The models use one
|                 record per subject: a record with a missing count, group or
|                 level is not used.
| Procedure     : PROC GENMOD
| Proven        : Checked against its known answers: a Poisson and a negative
|                 binomial model (on a small data set, the numbers worked out
|                 independently in R); ran on SAS 9.4 M9, 2026-11-12
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| data        The input data set: one record per subject, with    Required
|             USUBJID
| where       The records to use: a condition in parentheses,     Optional
|             such as where = (ittfl = 'Y')
| var         The count: one numeric variable, such as the        Required
|             number of events of each subject
| by          The groups of the model, the treatment: one         Required
|             variable
| factor      The factor of the subgroups: one variable whose     Required
|             values are its levels (factor = sex)
| exposure    The exposure of each subject: a numeric variable,   Required
|             or an expression of it (exposure = trtdurd /
|             365.25). It must be above 0, because the offset is
|             its logarithm.
| covars      The numeric covariates of the model, separated by   Optional
|             blanks (covars = base)
| class       The other class factors of the model, separated by  Optional
|             blanks (class = sitegr1)
| dist        The distribution of the count: poisson or negbin    poisson
|             (nb is accepted as another name of negbin)
| stats       The statistic with its pattern of the printed       pval="X.XXX"
|             number: pval
| label       The label of the block in the table: a text in      Optional
|             quotes. A block is the rows of one call in the
|             table.
| out         The name of the result data set                     Required
| debug       yes: keep the work data sets _interaction_genmod_*  no
|-------------------------------------------------------------------------------
|
| Output        : OUT: the result shape (see %stack), one row for all groups and
|                 levels together: GROUPS (blank), BLOCK, STAT (pval), VALUE and
|                 TEXT.
|
| Example:
|
 * Tests the treatment by sex interaction of the event counts in a negative binomial model.;
 %interaction_genmod(
     data     = adsl
   , where    = (trtdurd > 0)
   , var      = teaecnt
   , by       = trt01a
   , factor   = sex
   , exposure = trtdurd / 365.25
   , dist     = negbin
   , label    = "Sex"
   , out      = ae_int
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
