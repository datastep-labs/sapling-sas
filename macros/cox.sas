/*******************************************************************************
| Macro Name    : cox.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.10.0
| Created By    : Sapling
| Date          : 27NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : Returns the hazard ratio of pairs of groups from a Cox
|                 proportional hazards model, with its confidence limits and
|                 p-value. Use %logrank for the test of all groups together
|                 without a model, and %interaction_phreg for the test of a
|                 treatment-by-subgroup interaction. The macro writes a result:
|                 a data set with one row per number (the result shape, see
|                 %stack). The model has the groups, the covariates and the
|                 class factors. With strata=, each combination of the values of
|                 the strata variables is a stratum with its own baseline
|                 hazard. All pairs come from one fit: hr is the hazard ratio,
|                 lcl and ucl are its Wald confidence limits, and pval is the
|                 Wald p-value of the pair. With pvalue=logrank, pval is the
|                 log-rank test of the two groups of the pair, in the same
|                 strata (PROC LIFETEST); the hazard ratio and its limits stay
|                 those of the model. The model uses one record per subject (in
|                 each group of within=). CNSR 0 is an event and any positive
|                 value is a censoring, as in ADaM, where the value names the
|                 reason of the censoring: a CNSR of 2 is censored as 1 is. A
|                 record used with a missing or negative CNSR stops the macro
|                 with an ERROR.
| Procedure     : PROC PHREG (LSMEANS); PROC LIFETEST for pvalue=logrank
| Proven        : Checked against its known answer (on a small data set, the
|                 numbers worked out independently in R); ran on SAS 9.4 M9,
|                 2026-11-12
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| data        The input data set: one record per subject, with    Required
|             USUBJID, the time and the censoring variable
| where       The records to use: a condition in parentheses,     Optional
|             such as where = (paramcd = 'TTDE')
| var         The time: one numeric variable, such as aval        Required
| by          The groups of the model: one character variable     Required
| cnsr        The censoring variable: one numeric variable, 0     CNSR
|             for an event and a positive value for a censoring
|             (the ADaM CNSR: 1, 2 ... name the reason). A
|             missing or negative value on a record used stops
|             the macro with an ERROR.
| within      One model in each group of these variables,         Optional
|             separated by blanks (within = sex for the levels
|             of a subgroup). A record with a missing value of
|             one of them is not used.
| covars      The numeric covariates of the model, separated by   Optional
|             blanks (covars = age)
| class       The class factors of the model, separated by        Optional
|             blanks (class = sitegr1)
| strata      The strata of the model, separated by blanks        Optional
|             (strata = sitegr1). When not given, the model has
|             no strata.
| pairs       The pairs of groups to compare. all: each later     all
|             group against each earlier one, in the order of
|             order= (or of the values). Or a list of pairs
|             separated by #: the group first, then the group it
|             is compared with, each value in quotes ("Drug"
|             "Placebo" # "High" "Low")
| order       The order of the groups: one numeric variable with  Optional
|             one value per group (order = trt01pn)
| ties        The method for tied times: efron, breslow, or       efron
|             exact (TIES=DISCRETE of PROC PHREG, which coxph of
|             R calls exact). discrete is accepted as another
|             name of exact
| pvalue      The p-value of each pair: wald (the Wald test of    wald
|             the pair in the model) or logrank (the log-rank
|             test of the two groups of the pair, in the
|             strata). logrank is not possible with within=
| level       The confidence level: a number between 0 and 1      0.95
| stats       The statistics, in the order of the rows: each      hr="XX.XX" lcl="XX.XX"
|             name with its pattern of the printed number,        ucl="XX.XX" pval="X.XXX"
|             separated by blanks. The names are hr, lcl, ucl
|             and pval. A name without a pattern takes its
|             default pattern: see the table of default patterns
|             (How a number is kept and printed).
| label       The label of the block in the table: a text in      Optional
|             quotes. A block is the rows of one call in the
|             table.
| out         The name of the result data set                     Required
| debug       yes: keep the work data sets _cox_*                 no
|-------------------------------------------------------------------------------
|
| Output        : OUT: the result shape (see %stack), one row per pair and
|                 statistic: the BY variable (the group), VERSUS (the group it
|                 is compared with), the variables of within=, GROUPS, BLOCK,
|                 STAT, VALUE and TEXT. hr is the hazard of the group over the
|                 hazard of VERSUS (a hazard ratio below 1: fewer events in the
|                 group, as its hazard is lower), lcl and ucl its confidence
|                 limits, pval its p-value. With pairs=all the group is the
|                 later one in the order of order=. GROUPS is the name of the BY
|                 variable, VERSUS and the names of within=.
| Note          : The ties of the library are Efron's, as in coxph of R; PROC
|                 PHREG by itself uses Breslow's.
|
| Example:
|
 * Gives the hazard ratio of each pair, stratified by sex, with its limits and p value.;
 %cox(
     data   = adttde
   , var    = aval
   , by     = trt01a
   , strata = sex
   , order  = trt01an
   , out    = ttde_hr
 )
 * Gives the hazard ratio against Placebo for each sex: the rows carry SEX, for a forest plot.;
 %cox(
     data   = adttde
   , var    = aval
   , by     = trt01a
   , within = sex
   , pairs  = "Xanomeline High Dose" "Placebo"
            # "Xanomeline Low Dose"  "Placebo"
   , out    = hr_sex
 )
 * Gives the hazard ratio against Placebo for each age group.;
 %cox(
     data   = adttde
   , var    = aval
   , by     = trt01a
   , within = agegr1
   , pairs  = "Xanomeline High Dose" "Placebo"
            # "Xanomeline Low Dose"  "Placebo"
   , out    = hr_age
 )
 * Uses the Breslow ties, and as p value the log rank test of the two groups of each pair.;
 %cox(
     data   = adttde
   , var    = aval
   , by     = trt01a
   , pairs  = "Xanomeline High Dose" "Placebo"
            # "Xanomeline Low Dose"  "Placebo"
   , ties   = breslow
   , pvalue = logrank
   , out    = ttde_hr_lr
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
| 27-NOV-2026 Sapling      1.10.0: the example runs on the example data
|                          (sas/examples). The text of the header for the
|                          manual: the summary, the form of each parameter. No
|                          number changes.
| 27-NOV-2026 Sapling      1.10.0: The text of stats=: a name without a pattern
|                          takes its default pattern. No number changes.
| 27-NOV-2026 Sapling      1.10.0: CNSR as in ADaM: 0 is an event and any positive
|                          value a censoring (before, only 1 was a censoring and
|                          2 an event); a missing or negative CNSR on a record
|                          used stops the macro with an ERROR. No number changes
|                          on data with CNSR 0 and 1.
| 27-NOV-2026 Sapling      1.10.0: an example with ties= and pvalue=logrank. No
|                          number changes.
| 27-NOV-2026 Sapling      1.10.0: a caption for each call of the example (a
|                          comment line before it). No number changes.
| 27-NOV-2026 Sapling      1.10.0: The Output says the direction of hr (the
|                          hazard of the group over that of VERSUS); the caption
|                          of the fourth example names the log rank test of the
|                          two groups of each pair (PROC LIFETEST); Proven in
|                          plain words, for the published manual. stats= points
|                          to the table of default patterns of the manual. No
|                          number changes.
|
*******************************************************************************/
%MACRO cox(
     data   =        /* The records */
   , where  =        /* The records to use: a condition in parentheses */
   , var    =        /* The time */
   , by     =        /* The groups of the model: a character variable */
   , cnsr   = CNSR   /* The censoring variable: 0 = event, > 0 censored */
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
  %LOCAL t0 cond chars method plots nbad;
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
    /* CNSR 0 is an event; a positive value is a censoring, with its reason */
    IF &cnsr. > 0 THEN _cens = 1;
    ELSE               _cens = 0;
  RUN;
  PROC SORT DATA=_cox_records NODUPKEY; BY &within. usubjid; RUN;
  /* a missing or negative CNSR is neither an event nor a censoring */
  %LET nbad = %_spl_nobs(_cox_records(WHERE=(MISSING(&cnsr.) OR &cnsr. < 0)));
  %IF &nbad. > 0 %THEN %DO;
    %PUT %STR(ERR)OR: [cox] cnsr=&cnsr. is missing or negative on &nbad. record(s) used;
    %PUT %STR(ERR)OR: [cox]   fix: give each record CNSR 0 (an event) or more (a censoring).;
    %GOTO finish;
  %END;

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
    MODEL &var. * _cens(1) = &by. &class. &covars. / ties = &method. xconv = 1E-12 gconv = 0;
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
      TIME &var. * _cens(1);
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
