/*******************************************************************************
| Macro Name    : rateratio.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.9.1
| Created By    : Sapling
| Date          : 16NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : A count model of a count with its exposure, one record per
|                 subject (PROC GENMOD, the logarithm of the exposure the
|                 offset): Poisson or negative binomial (the dispersion k by
|                 maximum likelihood), on the groups, the covariates and the
|                 class factors. The rate ratio of pairs of groups from one fit
|                 (irr), its Wald confidence limits (lcl, ucl) and the Wald
|                 p-value of the pair (pval).
| Procedure     : PROC GENMOD (LSMEANS)
| Proven        : the known answer of the methods poisson, negbin
|                 (src/methods.ts, worked out by tools/method_answers.R; node
|                 tools/methods_sas.ts); ran on SAS 9.4 M9, 2026-11-12
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| data        The records                                         Required
| where       The records to use, a condition in parentheses      Optional
| var         The count                                           Required
| by          The groups of the model: a character variable       Required
| exposure    The exposure of each subject: a variable, or an     Required
|             expression of it (TRTDUR / 365.25: in years).
|             Above 0.
| within      One model in each group of these variables (the     Optional
|             levels of a subgroup)
| covars      The covariates                                      Optional
| class       The class factors                                   Optional
| dist        poisson (default) or negbin                         poisson
| pairs       all: each later group against each earlier one, in  all
|             the order of ORDER; or the pairs separated by #,
|             one pair per line, the group first, then the group
|             it is compared with (a value with a blank or a
|             hyphen in quotes): "Drug" "Placebo" # "High"
|             "Low". The form "A"-"B" of version 1.0 is still
|             read.
| order       A numeric variable with one value per group: the    Optional
|             order of the groups
| level       The confidence level (default 0.95)                 0.95
| stats       The statistics, each with its pattern (default      irr="XX.XX" lcl="XX.XX"
|             irr="XX.XX" lcl="XX.XX" ucl="XX.XX" pval="X.XXX")   ucl="XX.XX" pval="X.XXX"
| label       The label of the block in a table, in quotes        Optional
| out         The result                                          Required
| debug       yes: keep the work data sets of the macro           no
|             (_rateratio_*)
|-------------------------------------------------------------------------------
|
| Output        : OUT: one row per pair and statistic (BY: the group, VERSUS: the
|                 group it is compared with); GROUPS is BY VERSUS (and WITHIN).
| Note          : The standard errors of a negative binomial model are those of
|                 PROC GENMOD (the observed information of the coefficients and
|                 the dispersion together); R's engine computes the same.
|
| Example:
|
 %rateratio(
     data     = adexac
   , var      = aval
   , by       = trt01p
   , exposure = trtdur / 365.25
   , covars   = base
   , dist     = negbin
   , order    = trt01pn
   , out      = exac_rr
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
  %LOCAL t0 cond chars family badexp;
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
    %PUT %STR(ERR)OR: [rateratio] exposure=%SUPERQ(exposure) has &badexp., not a variable of &data.;
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
