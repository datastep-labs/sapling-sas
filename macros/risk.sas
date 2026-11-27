/*******************************************************************************
| Macro Name    : risk.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.9.1
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
| Proven        : the known answer of the methods riskdiff, riskratio,
|                 oddsratio, perterm (src/methods.ts, worked out by
|                 tools/method_answers.R; node tools/methods_sas.ts); ran on SAS
|                 9.4 M9, 2026-11-12
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
|             "Low". The old form "A"-"B" is still read.
| order       The order of the groups: one numeric variable with  Optional
|             one value per group (order = trt01an)
| measure     The estimate: rd (risk difference), rr (relative    rd
|             risk) or or (odds ratio)
| ci          The interval of a risk difference: wald, newcombe,  wald
|             miettinen-nurminen (CL=MN) or agresti-caffo
|             (CL=AC). With strata= the interval is always mh.
| level       The confidence level of the interval: a number      0.95
|             between 0 and 1
| stats       The statistics, in the order of the rows: each      Optional
|             name with the pattern of its printed number,
|             separated by blanks. When not given: rd="X.XXX"
|             lcl="X.XXX" ucl="X.XXX" pval="X.XXX"; for
|             measure=rr or or, rr="XX.XX" or or="XX.XX" with
|             lcl="XX.XX" ucl="XX.XX" pval="X.XXX". A name
|             without a pattern takes its default pattern
|             (n="XX", mean="XX.X", pval="X.XXX" ...; see
|             %describe).
| label       The label of the block in the table: a text in      Optional
|             quotes. A block is the rows of one call in the
|             table.
| out         The name of the result data set                     Required
| debug       yes: keep the work data sets _risk_*                no
|-------------------------------------------------------------------------------
|
| Output        : OUT: the result shape (see %stack), one row per pair and
|                 statistic: the group in the by= variable, the group it is
|                 compared with in VERSUS, and the variables of within=. GROUPS
|                 is the by= variable, VERSUS and the within= variables.
|
| Example:
|
 %risk(
     data  = adsl
   , var   = eosstt
   , event = "DISCONTINUED"
   , by    = trt01a
   , order = trt01an
   , ci    = newcombe
   , out   = eos_rd
 )
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
 %risk(
     data    = adsl
   , var     = eosstt
   , event   = "DISCONTINUED"
   , by      = trt01a
   , order   = trt01an
   , measure = rr
   , out     = eos_rr
 )
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
| 27-NOV-2026 Sapling      1.9.1: the example runs on the example data
|                          (sas/examples). The text of the header for the
|                          manual: the summary, the form of each parameter. No
|                          number changes.
| 27-NOV-2026 Sapling      1.9.1: The text of stats=: a name without a pattern
|                          takes its default pattern. No number changes.
| 27-NOV-2026 Sapling      1.9.1: examples with measure=rr and with strata=. No
|                          number changes.
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
