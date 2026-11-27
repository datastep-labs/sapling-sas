/*******************************************************************************
| Macro Name    : rateratio.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.9.1
| Created By    : Sapling
| Date          : 27NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : Returns the rate ratios of pairs of groups from a Poisson or
|                 negative binomial model, with confidence limits and p-values.
|                 Use %rate for the rate of each group without a model. The
|                 model is PROC GENMOD of a count with the logarithm of the
|                 exposure as the offset, on the groups, the covariates and the
|                 class factors, one record per subject (the first with a
|                 count). The dispersion k of a negative binomial model is
|                 estimated by maximum likelihood. All pairs come from one fit.
|                 The macro writes a result: a data set with one row per number
|                 (the result shape, see %stack).
| Procedure     : PROC GENMOD (LSMEANS)
| Proven        : the known answer of the methods poisson, negbin
|                 (src/methods.ts, worked out by tools/method_answers.R; node
|                 tools/methods_sas.ts); ran on SAS 9.4 M9, 2026-11-12
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| data        The input data set, with USUBJID: one record per    Required
|             subject
| where       The records to use: a condition in parentheses,     Optional
|             such as where = (trtdurd > 0)
| var         The count: one numeric variable (var = teaecnt)     Required
| by          The groups of the model: one character variable     Required
| exposure    The exposure of each subject: a numeric variable,   Required
|             or an expression of variables of data=, such as
|             exposure = trtdurd / 365.25 for years. A subject
|             with an exposure of 0 or less is not used in the
|             model.
| within      One model in each group of these variables,         Optional
|             separated by blanks, such as the levels of a
|             subgroup (within = sex)
| covars      The covariates: numeric variables separated by      Optional
|             blanks (covars = age)
| class       The class factors besides the groups: variables     Optional
|             separated by blanks (class = sex)
| dist        The distribution of the count: poisson, or negbin   poisson
|             (also nb) for the negative binomial
| pairs       The pairs of groups to compare. all: each later     all
|             group against each earlier one, in the order of
|             order= (or of the values). Or the pairs separated
|             by #, each the group first and then the group it
|             is compared with, a value with a blank or a hyphen
|             in quotes: pairs = "Drug" "Placebo" # "High"
|             "Low". The old form "A"-"B" is still read.
| order       The order of the groups: one numeric variable with  Optional
|             one value per group (order = trt01an)
| level       The confidence level of the limits: a number        0.95
|             between 0 and 1
| stats       The statistics, in the order of the rows: each      irr="XX.XX" lcl="XX.XX"
|             name with the pattern of its printed number,        ucl="XX.XX" pval="X.XXX"
|             separated by blanks. The names are irr, lcl, ucl
|             and pval. A name without a pattern takes its
|             default pattern (n="XX", mean="XX.X", pval="X.XXX"
|             ...; see %describe).
| label       The label of the block in the table: a text in      Optional
|             quotes. A block is the rows of one call in the
|             table.
| out         The name of the result data set                     Required
| debug       yes: keep the work data sets _rateratio_*           no
|-------------------------------------------------------------------------------
|
| Output        : OUT: the result shape (see %stack), one row per pair and
|                 statistic: the group in the by= variable, the group it is
|                 compared with in VERSUS, and the variables of within=. GROUPS
|                 is the by= variable, VERSUS and the within= variables.
| Note          : The standard errors of a negative binomial model are those of
|                 PROC GENMOD: the observed information of the coefficients and
|                 the dispersion together. The function rateratio() of the R
|                 package sapling computes the same.
|
| Example:
|
 %rateratio(
     data     = adsl
   , where    = (trtdurd > 0)
   , var      = teaecnt
   , by       = trt01a
   , exposure = trtdurd / 365.25
   , dist     = negbin
   , order    = trt01an
   , out      = ae_rr
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
| 12-NOV-2026 Sapling      1.1.0: pairs= takes the pairs separated by #, one
|                          pair per line; the form "A"-"B" is still read.
| 12-NOV-2026 Sapling      1.1.0: the label is written into the code
|                          (%_spl_quote), not read by SYMGET when the step
|                          runs: the flat program has it. No number changes.
| 16-NOV-2026 Sapling      1.9.0: the license line; the example in the house
|                          case (names in lower case). No number changes.
| 16-NOV-2026 Sapling      1.9.1: covars=, class= and the variables of exposure=
|                          are checked (DEV-036). No number changes.
| 27-NOV-2026 Sapling      1.9.1: the example runs on the example data
|                          (sas/examples). The text of the header for the
|                          manual: the summary, the form of each parameter. No
|                          number changes.
| 27-NOV-2026 Sapling      1.9.1: The text of stats=: a name without a pattern
|                          takes its default pattern. No number changes.
| 27-NOV-2026 Sapling      1.9.1: the message of exposure= prints a macro
|                          variable, not a macro expression; the Note names the R
|                          package. No number changes.
|
*******************************************************************************/
%MACRO rateratio(
     data     =          /* The records */
   , where    =          /* The records to use: a condition in parentheses */
   , var      =          /* The count */
   , by       =          /* The groups of the model: a character variable */
   , exposure =          /* The exposure: a variable or an expression of it */
   , within   =          /* One model in each group of these variables */
   , covars   =          /* The covariates */
   , class    =          /* The class factors */
   , dist     = poisson  /* poisson or negbin */
   , pairs    = all      /* all, or the pairs: each group, then its comparator */
   , order    =          /* A numeric variable: the order of the groups */
   , level    = 0.95     /* The confidence level */
   , stats    = irr="XX.XX" lcl="XX.XX" ucl="XX.XX" pval="X.XXX"
                         /* The statistics, each with its pattern */
   , label    =          /* The label of the block, in quotes */
   , out      =          /* The result */
   , debug    = no       /* yes: keep the work data sets _rateratio_* */
) / DES = 'The rate ratio of pairs of groups, Poisson or negative binomial model (PROC GENMOD)';
  %LOCAL t0 cond chars family badexp exptext;
  %LET t0 = %_spl_begin(rateratio);

  /* Step 1: the parameters */
  %IF not %_spl_need(rateratio, data var by exposure out) %THEN %RETURN;
  %IF not %_spl_vars(rateratio, data, var by within covars class) %THEN %RETURN;
  %IF not %_spl_oneof(rateratio, dist, poisson negbin nb) %THEN %RETURN;
  %IF not %_spl_oneof(rateratio, debug, yes no) %THEN %RETURN;
  /* the names of exposure= that are not functions are variables of data= */
  %LET badexp = ;
  DATA _NULL_;
    LENGTH text $2000 word $32 bad $2000;
    text  = %_spl_quote(exposure);
    dsid  = OPEN("%SCAN(&data., 1, %STR(%())");
    rx    = PRXPARSE('/\b[A-Za-z_]\w*\b(?!\s*\()/');
    start = 1;
    stop  = LENGTH(text);
    CALL PRXNEXT(rx, start, stop, text, pos, len);
    DO WHILE (pos > 0);
      word = SUBSTR(text, pos, len);
      IF VARNUM(dsid, word) = 0 THEN bad = CATX(' ', bad, word);
      CALL PRXNEXT(rx, start, stop, text, pos, len);
    END;
    rc = CLOSE(dsid);
    CALL SYMPUTX('badexp', bad);
  RUN;
  %IF %LENGTH(&badexp.) %THEN %DO;
    %LET exptext = %SUPERQ(exposure);  /* the expression as written */
    %PUT %STR(ERR)OR: [rateratio] exposure=&exptext. has &badexp., not a variable of &data.;
    %PUT %STR(ERR)OR: [rateratio]   fix: give exposure= variables of data=, or an expression.;
    %RETURN;
  %END;

  %LET by     = %UPCASE(&by.);  /* the groups, in upper case */
  %LET within = %UPCASE(&within.);  /* the subgroups, in upper case */
  %LET chars  = %_spl_chars(&data., &by. &within.);  /* the character variables */
  %LET cond   = not missing(&var.) and not missing(&by.);  /* the records that count */
  %IF %LENGTH(%SUPERQ(where)) %THEN %LET cond = &cond. and &where.;  /* plus where= */
  %LET family = %UPCASE(&dist.);  /* the family of the model, in upper case */
  %IF &family. = NEGBIN %THEN %LET family = NB;  /* NB is the SAS name of the negative binomial */

  /* Step 2: one record per subject with a count, and the logarithm of its exposure */
  DATA _rateratio_records;
    %IF %LENGTH(&chars.) %THEN %DO;
      LENGTH &chars. $200;
    %END;
    SET &data.;
    WHERE &cond.;
    %IF %LENGTH(&within.) %THEN %DO;
      IF CMISS(OF &within.) = 0;
    %END;
    IF &exposure. > 0 THEN _logexp = LOG(&exposure.);
  RUN;
  PROC SORT DATA=_rateratio_records NODUPKEY; BY &within. usubjid; RUN;

  /* Step 3: no record qualified: the result without a row */
  %IF %_spl_nobs(_rateratio_records) = 0 %THEN %DO;
    %_spl_empty(macro=rateratio, out=&out., like=_rateratio_records, keep=&by. &within., add=versus)
    %GOTO finish;
  %END;

  /* Step 4: the model, and the differences of the groups on the scale of the log rate */
  ODS EXCLUDE ALL;
  ODS OUTPUT Diffs=_rateratio_diffs;
  PROC GENMOD DATA=_rateratio_records;
    %IF %LENGTH(&within.) %THEN %DO;
      BY &within.;
    %END;
    CLASS &class. &by.;
    MODEL &var. = &by. &class. &covars.
          / dist = &family. link = log offset = _logexp converge = 1E-12;
    LSMEANS &by. / DIFF CL ALPHA=%SYSEVALF(1 - &level.);
  RUN;
  ODS EXCLUDE NONE;
  DATA _rateratio_diffs;
    SET _rateratio_diffs;
    probt = probz;
  RUN;
  %_spl_pairs(
      diffs   = _rateratio_diffs
    , by      = &by.
    , within  = &within.
    , records = _rateratio_records
    , pairs   = &pairs.
    , order   = &order.
    , out     = _rateratio_pairs
  )

  /* Step 5: one row per pair and statistic: the rate ratio and its limits, the result */
  DATA &out.;
    LENGTH groups block $200;
    SET _rateratio_pairs;
    irr    = EXP(diff);
    lcl    = EXP(lcl);
    ucl    = EXP(ucl);
    groups = "&by. VERSUS &within.";
    block  = DEQUOTE(%_spl_quote(label));
    %_spl_rows(stats=&stats.)
    KEEP &by. versus &within. groups block stat value text;
  RUN;

  /* Step 6: the work data sets are deleted (kept with debug=yes) */
  %finish:
  %IF %UPCASE(&debug.) ne YES %THEN %DO;
    PROC DATASETS LIBRARY=work NOLIST NOWARN;
      DELETE _rateratio_:;
    QUIT;
  %END;
  %_spl_end(rateratio, &t0., &debug.)
%MEND rateratio;
