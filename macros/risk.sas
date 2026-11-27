/*******************************************************************************
| Macro Name    : risk.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.10.0
| Created By    : Sapling
| Date          : 27NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : Returns the risk difference, relative risk or odds ratio of
|                 pairs of groups, with its confidence interval and p-value. Use
|                 %logistic for an odds ratio adjusted for covariates in a
|                 model, and %fisher for only the p-value of an adverse event.
|                 For each pair the macro makes the 2 x 2 table of the two
|                 groups (the group first) by the event of event= against the
|                 rest, one record per subject, with PROC FREQ. measure= gives
|                 the estimate:
|                 - rd: the risk difference, with the interval of ci=
|                 - rr: the relative risk, with the Wald interval of its
|                   logarithm
|                 - or: the odds ratio, with the Wald interval of its logarithm
|                 The p-value is that of Pearson's chi-square test without
|                 continuity correction. With strata= the macro gives the
|                 Mantel-Haenszel risk difference (COMMONRISKDIFF, CL=MH) and
|                 the p-value of the CMH test. The macro writes a result: a data
|                 set with one row per number (the result shape, see %stack).
| Procedure     : PROC FREQ (RISKDIFF, RELRISK, CHISQ; COMMONRISKDIFF, CMH)
| Proven        : Checked against its known answers: the risk difference, the
|                 relative risk, the odds ratio, and the risk difference of each
|                 term of an adverse event table (on a small data set, the
|                 numbers worked out independently in R); ran on SAS 9.4 M9,
|                 2026-11-12
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| data        The input data set, with USUBJID: one record per    Required
|             subject, or per subject and term with within=
| where       The records to use: a condition in parentheses,     Optional
|             such as where = (saffl = 'Y')
| var         The response: one variable with two values,         Required
|             numeric or character
| event       The value of var= that is the event, in quotes      "Y"
|             (event = "DISCONTINUED")
| by          The groups: one character variable                  Required
| within      One comparison in each group of these variables,    Optional
|             separated by blanks, such as each term of an
|             adverse event table with the flags of %termflags
|             (within = aebodsys aedecod)
| strata      The strata of the Mantel-Haenszel risk difference:  Optional
|             variables separated by blanks. Only with
|             measure=rd.
| pairs       The pairs of groups to compare. all: each later     all
|             group against each earlier one, in the order of
|             order= (or of the values). Or the pairs separated
|             by #, each the group first and then the group it
|             is compared with, a value with a blank or a hyphen
|             in quotes: pairs = "Drug" "Placebo" # "High"
|             "Low"
| order       The order of the groups: one numeric variable with  Optional
|             one value per group (order = trt01an)
| measure     The estimate of the group against the group it is   rd
|             compared with: rd, the risk difference, a
|             difference of two proportions between -1 and 1
|             (0.25 is 25 percentage points), not of percents;
|             rr, the relative risk, the ratio of the two risks;
|             or or, the odds ratio, the ratio of the two odds.
|             A ratio has no unit.
| ci          The interval of a risk difference: wald, the Wald   wald
|             interval (CL=WALD); newcombe, the hybrid score
|             interval of Newcombe, from the Wilson interval of
|             each risk (CL=NEWCOMBE); mn or miettinen-nurminen,
|             the score interval of Miettinen and Nurminen
|             (CL=MN); ac or agresti-caffo, the interval of
|             Agresti and Caffo, a Wald interval with one event
|             and one non-event added to each group (CL=AC); or
|             mh, the interval of Mantel and Haenszel, which
|             needs strata=. With strata= the interval is always
|             mh, whatever ci= says.
| level       The confidence level of the interval: a number      0.95
|             between 0 and 1
| stats       The statistics, in the order of the rows: each      Optional
|             name with the pattern of its printed number,
|             separated by blanks. When not given: rd="X.XXX"
|             lcl="X.XXX" ucl="X.XXX" pval="X.XXX"; for
|             measure=rr or or, rr="XX.XX" or or="XX.XX" with
|             lcl="XX.XX" ucl="XX.XX" pval="X.XXX". A name
|             without a pattern takes its default pattern: see
|             the table of default patterns (How a number is
|             kept and printed).
| label       The label of the block in the table: a text in      Optional
|             quotes. A block is the rows of one call in the
|             table.
| out         The name of the result data set                     Required
| debug       yes: keep the work data sets _risk_*                no
|-------------------------------------------------------------------------------
|
| Output        : OUT: the result shape (see %stack), one row per pair and
|                 statistic: the group in the by= variable, the group it is
|                 compared with in VERSUS, and the variables of within=. The
|                 risk of a group is its subjects with the event of event= over
|                 its subjects in the records used. With measure=rd, rd is the
|                 risk of the group minus the risk of VERSUS, a difference of
|                 two proportions (0.25: 25 percentage points more in the
|                 group); with strata=, the Mantel-Haenszel estimate of that
|                 difference. With measure=rr, rr is the risk of the group over
|                 the risk of VERSUS; with measure=or, or is the odds of the
|                 event in the group over the odds in VERSUS. lcl and ucl are
|                 the limits of the estimate, pval its p-value. With pairs=all
|                 the group is the later one in the order of order=. GROUPS is
|                 the by= variable, VERSUS and the within= variables.
|
| Example:
|
 * Gives the risk difference of discontinuation of each pair, its Newcombe limits and p value.;
 %risk(
     data  = adsl
   , var   = eosstt
   , event = "DISCONTINUED"
   , by    = trt01a
   , order = trt01an
   , ci    = newcombe
   , out   = eos_rd
 )
 * Gives the risk difference of each flagged term against Placebo, within its class and term.;
 %risk(
     data   = work.ae_flags
   , var    = flag
   , event  = "Y"
   , by     = trt01a
   , within = aebodsys aedecod
   , pairs  = "Xanomeline High Dose" "Placebo"
            # "Xanomeline Low Dose"  "Placebo"
   , ci     = newcombe
   , out    = ae_rd
 )
 * Asks for the relative risk with measure=rr: the rows of STAT rr hold the ratio of the two risks.;
 %risk(
     data    = adsl
   , var     = eosstt
   , event   = "DISCONTINUED"
   , by      = trt01a
   , order   = trt01an
   , measure = rr
   , out     = eos_rr
 )
 * Stratifies by sex: the risk difference is the Mantel Haenszel estimate over the strata.;
 %risk(
     data   = adsl
   , var    = eosstt
   , event  = "DISCONTINUED"
   , by     = trt01a
   , strata = sex
   , order  = trt01an
   , out    = eos_rd_mh
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
| 12-NOV-2026 Sapling      1.2.0: the event (_EV) by IF and ELSE, not a Boolean
|                          value (the owner's rule 10). No number changes.
| 13-NOV-2026 Sapling      1.7.1: a pair of pairs= that names a group no record
|                          has is an error with its fix.
| 16-NOV-2026 Sapling      1.9.0: the license line; the example in the house
|                          case (names in lower case). No number changes.
| 27-NOV-2026 Sapling      1.10.0: the example runs on the example data
|                          (sas/examples). The text of the header for the
|                          manual: the summary, the form of each parameter. No
|                          number changes.
| 27-NOV-2026 Sapling      1.10.0: The text of stats=: a name without a pattern
|                          takes its default pattern. No number changes.
| 27-NOV-2026 Sapling      1.10.0: examples with measure=rr and with strata=. No
|                          number changes.
| 27-NOV-2026 Sapling      1.10.0: a caption for each call of the example (a
|                          comment line before it). No number changes.
| 27-NOV-2026 Sapling      1.10.0: The Output says the direction of rd, rr and
|                          or (the group against VERSUS); Proven in plain words,
|                          for the published manual. stats= points to the table
|                          of default patterns of the manual. ci= lists mh;
|                          ci=mh without strata= stops with the ERROR of the
|                          macro (PROC FREQ has no RISKDIFF(CL=MH), so the step
|                          stopped with a syntax error before). No number
|                          changes. ci= names each interval it takes, also the
|                          short names mn and ac. No number changes.
|
*******************************************************************************/
%MACRO risk(
     data    =       /* The records */
   , where   =       /* The records to use: a condition in parentheses */
   , var     =       /* The response: two values */
   , event   = "Y"   /* The value that is the event, in quotes */
   , by      =       /* The groups: a character variable */
   , within  =       /* One comparison in each group of these variables */
   , strata  =       /* The strata of the Mantel Haenszel risk difference */
   , pairs   = all   /* all, or the pairs: each group, then its comparator */
   , order   =       /* A numeric variable: the order of the groups */
   , measure = rd    /* rd, rr or or */
   , ci      = wald  /* The interval of a risk difference */
   , level   = 0.95  /* The confidence level */
   , stats   =       /* The statistics, each with its pattern */
   , label   =       /* The label of the block, in quotes */
   , out     =       /* The result */
   , debug   = no    /* yes: keep the work data sets _risk_* */
) / DES = 'The risk difference, relative risk or odds ratio of pairs of groups (PROC FREQ)';
  %LOCAL t0 cond chars cl tables pairsok;
  %LET t0 = %_spl_begin(risk);

  /* Step 1: the parameters */
  %IF not %_spl_need(risk, data var by out) %THEN %RETURN;
  %IF not %_spl_vars(risk, data, var by within strata) %THEN %RETURN;
  %IF not %_spl_oneof(risk, measure, rd rr or) %THEN %RETURN;
  %IF not %_spl_oneof(risk, debug, yes no) %THEN %RETURN;

  %LET by      = %UPCASE(&by.);  /* the groups, in upper case */
  %LET within  = %UPCASE(&within.);  /* the subgroups, in upper case */
  %LET measure = %LOWCASE(&measure.);  /* the measure, in lower case */
  %LET chars   = %_spl_chars(&data., &by. &within.);  /* the character variables */
  %LET cond    = not missing(&var.) and not missing(&by.);  /* the records that count */
  %IF %LENGTH(%SUPERQ(where)) %THEN %LET cond = &cond. and &where.;  /* plus where= */
  %LET cl = %SYSFUNC(COMPRESS(%UPCASE(&ci.), -));  /* the interval, no hyphens */
  %IF &cl. = MIETTINENNURMINEN %THEN %LET cl = MN;  /* the short name of the interval */
  %IF &cl. = AGRESTICAFFO %THEN %LET cl = AC;  /* the short name of the interval */
  %IF not %SYSFUNC(INDEXW(WALD NEWCOMBE MN AC MH, &cl.)) %THEN %DO;
    %PUT %STR(ERR)OR: [risk] ci=&ci. is not an interval here;
    %PUT %STR(ERR)OR: [risk]   fix: give ci= wald, newcombe, miettinen-nurminen, agresti-caffo, mh.;
    %RETURN;
  %END;
  %IF &cl. = MH and %LENGTH(&strata.) = 0 %THEN %DO;
    %PUT %STR(ERR)OR: [risk] ci=mh is the interval of strata= (Mantel and Haenszel);
    %PUT %STR(ERR)OR: [risk]   fix: give strata=, or give ci= wald, newcombe, mn or ac.;
    %RETURN;
  %END;
  %IF %LENGTH(&strata.) and %SUPERQ(measure) ne rd %THEN %DO;
    %PUT %STR(ERR)OR: [risk] strata=&strata. is taken by the risk difference only;
    %PUT %STR(ERR)OR: [risk]   fix: give measure=rd, or no strata=.;
    %RETURN;
  %END;
  %IF not %LENGTH(%SUPERQ(stats)) %THEN %DO;
    %IF %SUPERQ(measure) = rd %THEN %LET stats = rd="X.XXX" lcl="X.XXX" ucl="X.XXX" pval="X.XXX";
    %ELSE %LET stats = &measure.="XX.XX" lcl="XX.XX" ucl="XX.XX" pval="X.XXX";
  %END;
  %LET tables = _side * _ev;  /* the cells of the TABLES statement */
  /* strata first */
  %IF %LENGTH(&strata.) %THEN
    %LET tables = %SYSFUNC(TRANSLATE(%SYSFUNC(COMPBL(&strata.)), *, %STR( ))) * &tables.;

  /* Step 2: one record per subject with a response: the event (_ev = 1) or not (_ev = 2) */
  DATA _risk_records;
    %IF %LENGTH(&chars.) %THEN %DO;
      LENGTH &chars. $200;
    %END;
    SET &data.;
    WHERE &cond.;
    %IF %LENGTH(&within.) %THEN %DO;
      IF CMISS(OF &within.) = 0;
    %END;
    IF &var. = &event. THEN _ev = 1;
    ELSE                    _ev = 2;
  RUN;
  PROC SORT DATA=_risk_records NODUPKEY; BY &within. usubjid; RUN;

  /* Step 3: no record qualified: the result without a row */
  %IF %_spl_nobs(_risk_records) = 0 %THEN %DO;
    %_spl_empty(macro=risk, out=&out., like=_risk_records, keep=&by. &within., add=versus)
    %GOTO finish;
  %END;

  /* Step 4: the records of each pair, the group (_side = 1) and the other group (_side = 2) */
  %_spl_stackpairs(
      macro   = risk
    , records = _risk_records
    , by      = &by.
    , pairs   = &pairs.
    , order   = &order.
    , out     = _risk_pairs
  )
  %IF &pairsok. = 0 %THEN %GOTO finish;
  %IF %LENGTH(&within.) %THEN %DO;
    PROC SORT DATA=_risk_pairs; BY _pair _a _b &within. _side; RUN;
  %END;

  /* Step 5: the 2 x 2 table of each pair: the measure, its interval, the test */
  PROC DATASETS LIBRARY=work NOLIST NOWARN;
    DELETE _risk_cls _risk_rr _risk_chisq _risk_cmh _risk_common;
  QUIT;
  ODS EXCLUDE ALL;
  %IF %LENGTH(&strata.) %THEN %DO;
    ODS OUTPUT CommonPdiff=_risk_common CMH=_risk_cmh;
  %END;
  %ELSE %IF %SUPERQ(measure) = rd %THEN %DO;
    ODS OUTPUT PdiffCLs=_risk_cls ChiSq=_risk_chisq;
  %END;
  %ELSE %DO;
    ODS OUTPUT RelativeRisks=_risk_rr ChiSq=_risk_chisq;
  %END;
  PROC FREQ DATA=_risk_pairs;
    BY _pair _a _b &within.;
    %IF %LENGTH(&strata.) %THEN %DO;
      TABLES &tables. / CMH COMMONRISKDIFF(cl = mh) ALPHA=%SYSEVALF(1 - &level.);
    %END;
    %ELSE %IF %SUPERQ(measure) = rd %THEN %DO;
      TABLES &tables. / CHISQ RISKDIFF(cl = &cl.) ALPHA=%SYSEVALF(1 - &level.);
    %END;
    %ELSE %DO;
      TABLES &tables. / CHISQ RELRISK ALPHA=%SYSEVALF(1 - &level.);
    %END;
  RUN;
  ODS EXCLUDE NONE;

  /* Step 6: the estimate, its limits and the p value of each pair */
  DATA _risk_est;
    LENGTH _a _b $200;
    %IF %LENGTH(&strata.) %THEN %DO;
      SET _risk_common(WHERE=(UPCASE(method) =: 'MANTEL'));
      rd  = value;
      lcl = lowercl;
      ucl = uppercl;
    %END;
    %ELSE %IF %SUPERQ(measure) = rd %THEN %DO;
      SET _risk_cls;
      rd  = riskdifference;
      lcl = lowercl;
      ucl = uppercl;
    %END;
    %ELSE %IF %SUPERQ(measure) = rr %THEN %DO;
      SET _risk_rr(WHERE=(statistic =: 'Relative Risk (Column 1)'));
      rr  = value;
      lcl = lowercl;
      ucl = uppercl;
    %END;
    %ELSE %DO;
      SET _risk_rr(WHERE=(statistic =: 'Odds Ratio'));
      or  = value;
      lcl = lowercl;
      ucl = uppercl;
    %END;
    KEEP _pair _a _b &within. &measure. lcl ucl;
  RUN;
  DATA _risk_test;
    LENGTH _a _b $200;
    %IF %LENGTH(&strata.) %THEN %DO;
      SET _risk_cmh(WHERE=(althypothesis = 'General Association'));
    %END;
    %ELSE %DO;
      SET _risk_chisq(WHERE=(statistic = 'Chi-Square'));
    %END;
    pval = prob;
    KEEP _pair _a _b &within. pval;
  RUN;

  /* Step 7: one row per pair and statistic: the result */
  DATA &out.;
    LENGTH &by. versus groups block $200;
    MERGE _risk_est _risk_test;
    BY _pair _a _b &within.;
    &by. = _a;
    versus = _b;
    groups = "&by. VERSUS &within.";
    block  = DEQUOTE(%_spl_quote(label));
    %_spl_rows(stats=&stats.)
    KEEP &by. versus &within. groups block stat value text;
  RUN;

  /* Step 8: the work data sets are deleted (kept with debug=yes) */
  %finish:
  %IF %UPCASE(&debug.) ne YES %THEN %DO;
    PROC DATASETS LIBRARY=work NOLIST NOWARN;
      DELETE _risk_:;
    QUIT;
  %END;
  %_spl_end(risk, &t0., &debug.)
%MEND risk;
