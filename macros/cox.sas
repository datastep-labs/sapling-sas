/*******************************************************************************
| Macro Name    : cox.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.9.1
| Created By    : Sapling
| Date          : 16NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : A Cox proportional hazards model of a time, one record per
|                 subject (PROC PHREG): the groups, the covariates and the class
|                 factors, stratified by the strata (each combination of their
|                 values a stratum with its own baseline hazard). The hazard
|                 ratio of pairs of groups from one fit (hr), its Wald
|                 confidence limits (lcl, ucl) and the Wald p-value of the pair
|                 (pval). With pvalue=logrank the p-value is the log-rank test
|                 of the two groups of the pair, stratified by the same strata
|                 (PROC LIFETEST); the hazard ratio and its limits stay those of
|                 the model.
| Procedure     : PROC PHREG (LSMEANS); PROC LIFETEST for pvalue=logrank
| Proven        : the known answer of the method cox (src/methods.ts, worked out
|                 by tools/method_answers.R; node tools/methods_sas.ts); ran on
|                 SAS 9.4 M9, 2026-11-12
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| data        The records                                         Required
| where       The records to use, a condition in parentheses      Optional
| var         The time                                            Required
| by          The groups of the model: a character variable       Required
| cnsr        The censoring variable: 1 = censored (default       CNSR
|             CNSR)
| within      One model in each group of these variables (the     Optional
|             levels of a subgroup)
| covars      The covariates                                      Optional
| class       The class factors                                   Optional
| strata      The strata variables, separated by blanks           Optional
| pairs       all: each later group against each earlier one, in  all
|             the order of ORDER; or the pairs separated by #,
|             one pair per line, the group first, then the group
|             it is compared with (a value with a blank or a
|             hyphen in quotes): "Drug" "Placebo" # "High"
|             "Low". The form "A"-"B" of version 1.0 is still
|             read.
| order       A numeric variable with one value per group: the    Optional
|             order of the groups
| ties        The likelihood of tied times: efron (default),      efron
|             breslow, or exact (the discrete likelihood,
|             TIES=DISCRETE; R coxph calls it exact)
| pvalue      wald (default): the Wald test of the pair in the    wald
|             model; logrank: the log-rank test of the two
|             groups of the pair, in the strata
| level       The confidence level (default 0.95)                 0.95
| stats       The statistics, each with its pattern (default      hr="XX.XX" lcl="XX.XX"
|             hr="XX.XX" lcl="XX.XX" ucl="XX.XX" pval="X.XXX")    ucl="XX.XX" pval="X.XXX"
| label       The label of the block in a table, in quotes        Optional
| out         The result                                          Required
| debug       yes: keep the work data sets of the macro           no
|             (_cox_*)
|-------------------------------------------------------------------------------
|
| Output        : OUT: one row per pair and statistic (BY: the group, VERSUS: the
|                 group it is compared with); GROUPS is BY VERSUS (and WITHIN).
| Note          : Sapling's default ties are Efron's (R coxph's default); PROC
|                 PHREG alone uses Breslow's.
|
| Example:
|
 %cox(
     data   = adtte
   , where  = (paramcd = 'PFS')
   , var    = aval
   , by     = trt01p
   , strata = strat1 strat2
   , order  = trt01pn
   , out    = pfs_hr
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
| 12-NOV-2026 Sapling      1.1.0: the fit iterates until the estimates change by
|                          less than 1E-12 (XCONV=1E-12 GCONV=0): with the
|                          default GCONV=1E-8 PHREG stopped a step early (a
|                          hazard ratio 2E-5 from the maximum on the dummy
|                          study; R's coxph had it). The estimates move to the
|                          maximum of the partial likelihood.
| 16-NOV-2026 Sapling      1.9.0: the license line; the example in the house
|                          case (names in lower case). No number changes.
| 16-NOV-2026 Sapling      1.9.1: PLOTS=NONE only with ODS graphics on: no
|                          WARNING when they are off (DEV-051). No number
|                          changes.
|
*******************************************************************************/
%MACRO cox(
     data   =        /* The records */
   , where  =        /* The records to use: a condition in parentheses */
   , var    =        /* The time */
   , by     =        /* The groups of the model: a character variable */
   , cnsr   = CNSR   /* The censoring variable: 1 = censored */
   , within =        /* One model in each group of these variables */
   , covars =        /* The covariates */
   , class  =        /* The class factors */
   , strata =        /* The strata variables */
   , pairs  = all    /* all, or the pairs: each group, then its comparator */
   , order  =        /* A numeric variable: the order of the groups */
   , ties   = efron  /* efron, breslow or exact */
   , pvalue = wald   /* wald (the model) or logrank (the pair) */
   , level  = 0.95   /* The confidence level */
   , stats  = hr="XX.XX" lcl="XX.XX" ucl="XX.XX" pval="X.XXX"
                     /* The statistics, each with its pattern */
   , label  =        /* The label of the block, in quotes */
   , out    =        /* The result */
   , debug  = no     /* yes: keep the work data sets _cox_* */
) / DES = 'The hazard ratio of pairs of groups from a Cox model (PROC PHREG)';
  %LOCAL t0 cond chars method plots;
  %LET t0 = %_spl_begin(cox);

  /* Step 1: the parameters */
  %IF not %_spl_need(cox, data var by out) %THEN %RETURN;
  %IF not %_spl_vars(cox, data, var by cnsr within strata) %THEN %RETURN;
  %IF not %_spl_oneof(cox, ties, efron breslow exact discrete) %THEN %RETURN;
  %IF not %_spl_oneof(cox, pvalue, wald logrank) %THEN %RETURN;
  %IF not %_spl_oneof(cox, debug, yes no) %THEN %RETURN;

  %LET by     = %UPCASE(&by.);  /* the groups, in upper case */
  %LET within = %UPCASE(&within.);  /* the subgroups, in upper case */
  %LET chars  = %_spl_chars(&data., &by. &within.);  /* the character variables */
  %LET cond   = not missing(&var.) and not missing(&by.);  /* the records that count */
  %IF %LENGTH(%SUPERQ(where)) %THEN %LET cond = &cond. and &where.;  /* plus where= */
  %LET method = %UPCASE(&ties.);  /* the method of ties, in upper case */
  %IF &method. = EXACT %THEN %LET method = DISCRETE;  /* DISCRETE is the SAS name of exact ties */
  %IF %LENGTH(&within.) and %UPCASE(&pvalue.) = LOGRANK %THEN %DO;
    %PUT %STR(ERR)OR: [cox] pvalue=logrank is not made within groups (within=&within.);
    %PUT %STR(ERR)OR: [cox]   fix: write pvalue=wald.;
    %RETURN;
  %END;

  /* Step 2: one record per subject with a time */
  DATA _cox_records;
    %IF %LENGTH(&chars.) %THEN %DO;
      LENGTH &chars. $200;
    %END;
    SET &data.;
    WHERE &cond.;
    %IF %LENGTH(&within.) %THEN %DO;
      IF CMISS(OF &within.) = 0;
    %END;
  RUN;
  PROC SORT DATA=_cox_records NODUPKEY; BY &within. usubjid; RUN;

  /* Step 3: no record qualified: the result without a row */
  %IF %_spl_nobs(_cox_records) = 0 %THEN %DO;
    %_spl_empty(macro=cox, out=&out., like=_cox_records, keep=&by. &within., add=versus)
    %GOTO finish;
  %END;

  /* Step 4: the model, and the differences of the groups on the scale of the log hazard */
  ODS EXCLUDE ALL;
  ODS OUTPUT Diffs=_cox_diffs;
  PROC PHREG DATA=_cox_records;
    %IF %LENGTH(&within.) %THEN %DO;
      BY &within.;
    %END;
    CLASS &class. &by. / PARAM=GLM;
    MODEL &var. * &cnsr.(1) = &by. &class. &covars. / ties = &method. xconv = 1E-12 gconv = 0;
    %IF %LENGTH(&strata.) %THEN %DO;
      STRATA &strata.;
    %END;
    LSMEANS &by. / DIFF CL ALPHA=%SYSEVALF(1 - &level.);
  RUN;
  ODS EXCLUDE NONE;
  DATA _cox_diffs;
    SET _cox_diffs;
    probt = probz;
  RUN;
  %_spl_pairs(
      diffs   = _cox_diffs
    , by      = &by.
    , within  = &within.
    , records = _cox_records
    , pairs   = &pairs.
    , order   = &order.
    , out     = _cox_pairs
  )

  /* Step 5: pvalue=logrank: the log rank test of the two groups of each pair, in the strata */
  %IF %UPCASE(&pvalue.) = LOGRANK %THEN %DO;
    DATA _cox_pairdata;
      LENGTH _a _b $200;
      SET _cox_pairs(KEEP=&by. versus);
      _pair = _N_;
      _a    = &by.;
      _b    = versus;
      DO _i = 1 TO _nrec;
        SET _cox_records POINT=_i NOBS=_nrec;
        IF &by. = _a OR &by. = _b THEN OUTPUT;
      END;
      DROP versus;
    RUN;
    PROC SORT DATA=_cox_pairdata; BY _pair _a _b; RUN;
    /* PLOTS=NONE only with ODS graphics on: with them off the option writes a WARNING */
    %LET plots = ;
    %IF not %SYMEXIST(sysodsgraphics) %THEN %LET plots = PLOTS=NONE;
    %ELSE %IF &sysodsgraphics. %THEN %LET plots = PLOTS=NONE;
    ODS EXCLUDE ALL;
    ODS OUTPUT HomTests=_cox_logrank(WHERE=(test = 'Log-Rank') KEEP=_a _b test probchisq);
    PROC LIFETEST DATA=_cox_pairdata &plots.;
      BY _pair _a _b;
      TIME &var. * &cnsr.(1);
      %IF %LENGTH(&strata.) %THEN %DO;
        STRATA &strata. / GROUP=&by.;
      %END;
      %ELSE %DO;
        STRATA &by.;
      %END;
    RUN;
    ODS EXCLUDE NONE;
    PROC SORT DATA=_cox_logrank; BY _a _b; RUN;
    PROC SORT DATA=_cox_pairs; BY &by. versus; RUN;
    DATA _cox_pairs;
      MERGE _cox_pairs _cox_logrank(RENAME=(_a = &by. _b = versus probchisq = _lrp));
      BY &by. versus;
      pval = _lrp;
      DROP test _lrp;
    RUN;
  %END;

  /* Step 6: one row per pair and statistic: the hazard ratio and its limits, the result */
  DATA &out.;
    LENGTH groups block $200;
    SET _cox_pairs;
    hr     = EXP(diff);
    lcl    = EXP(lcl);
    ucl    = EXP(ucl);
    groups = "&by. VERSUS &within.";
    block  = DEQUOTE(%_spl_quote(label));
    %_spl_rows(stats=&stats.)
    KEEP &by. versus &within. groups block stat value text;
  RUN;

  /* Step 7: the work data sets are deleted (kept with debug=yes) */
  %finish:
  %IF %UPCASE(&debug.) ne YES %THEN %DO;
    PROC DATASETS LIBRARY=work NOLIST NOWARN;
      DELETE _cox_:;
    QUIT;
  %END;
  %_spl_end(cox, &t0., &debug.)
%MEND cox;
