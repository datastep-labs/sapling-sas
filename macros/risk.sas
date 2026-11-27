/*******************************************************************************
| Macro Name    : risk.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.9.1
| Created By    : Sapling
| Date          : 16NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : The comparison of two proportions of each pair of groups, one
|                 record per subject (PROC FREQ): the 2 x 2 table of the two
|                 groups (the group first) and the event (event=) against the
|                 rest. measure=rd: the risk difference (rd) with the interval
|                 of ci=; measure=rr: the relative risk (rr), measure=or: the
|                 odds ratio (or), each with the Wald interval of its logarithm;
|                 the p-value of Pearson's chi-square test without continuity
|                 correction (pval). With strata= the Mantel-Haenszel risk
|                 difference (COMMONRISKDIFF, CL=MH) and the CMH test.
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
| data        The records                                         Required
| where       The records to use, a condition in parentheses      Optional
| var         The response: two values                            Required
| event       The value that is the event, in quotes (default     "Y"
|             "Y")
| by          The groups: a character variable                    Required
| within      One comparison in each group of these variables     Optional
|             (each term of an adverse event table: the flags of
|             %termflags)
| strata      The strata variables of the Mantel-Haenszel risk    Optional
|             difference
| pairs       all: each later group against each earlier one, in  all
|             the order of ORDER; or the pairs separated by #,
|             one pair per line, the group first, then the group
|             it is compared with (a value with a blank or a
|             hyphen in quotes): "Drug" "Placebo" # "High"
|             "Low". The form "A"-"B" of version 1.0 is still
|             read.
| order       A numeric variable with one value per group: the    Optional
|             order of the groups
| measure     rd (default), rr or or                              rd
| ci          The interval of a risk difference: wald (default),  wald
|             newcombe, miettinen-nurminen (CL=MN),
|             agresti-caffo (CL=AC); with strata: mh
| level       The confidence level (default 0.95)                 0.95
| stats       The statistics, each with its pattern (default      Optional
|             rd="X.XXX" lcl="X.XXX" ucl="X.XXX" pval="X.XXX";
|             with measure=rr or or: rr= or or= "XX.XX")
| label       The label of the block in a table, in quotes        Optional
| out         The result                                          Required
| debug       yes: keep the work data sets of the macro           no
|             (_risk_*)
|-------------------------------------------------------------------------------
|
| Output        : OUT: one row per pair and statistic (BY: the group, VERSUS: the
|                 group it is compared with, and WITHIN); GROUPS is BY VERSUS
|                 WITHIN.
|
| Example:
|
 %risk(
     data  = adrs
   , where = (paramcd = 'BOR')
   , var   = crit1fl
   , event = "Y"
   , by    = trt01p
   , order = trt01pn
   , ci    = newcombe
   , out   = resp_rd
 )
 %risk(
     data   = adae
   , var    = aoccfl
   , event  = "Y"
   , by     = trt01a
   , within = aebodsys aedecod
   , pairs  = "Drug" "Placebo"
   , ci     = newcombe
   , out    = ae_rd
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
