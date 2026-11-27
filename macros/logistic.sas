/*******************************************************************************
| Macro Name    : logistic.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.9.1
| Created By    : Sapling
| Date          : 16NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : A logistic regression of a response with two values, one
|                 record per subject (PROC LOGISTIC): the probability of the
|                 event (event=) on the groups, the covariates and the class
|                 factors. The odds ratio of pairs of groups from one fit (or),
|                 its Wald confidence limits (lcl, ucl) and the Wald p-value of
|                 the pair (pval).
| Procedure     : PROC LOGISTIC (LSMEANS)
| Proven        : the known answer of the method logistic (src/methods.ts,
|                 worked out by tools/method_answers.R; node
|                 tools/methods_sas.ts); ran on SAS 9.4 M9, 2026-11-12
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| data        The records                                         Required
| where       The records to use, a condition in parentheses      Optional
| var         The response: two values                            Required
| event       The value that is the event, in quotes (default     "Y"
|             "Y"; a number: "1"). PROC LOGISTIC alone models
|             the first value in sort order.
| by          The groups of the model: a character variable       Required
| within      One model in each group of these variables (the     Optional
|             levels of a subgroup)
| covars      The covariates                                      Optional
| class       The class factors                                   Optional
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
| stats       The statistics, each with its pattern (default      or="XX.XX" lcl="XX.XX"
|             or="XX.XX" lcl="XX.XX" ucl="XX.XX" pval="X.XXX")    ucl="XX.XX" pval="X.XXX"
| label       The label of the block in a table, in quotes        Optional
| out         The result                                          Required
| debug       yes: keep the work data sets of the macro           no
|             (_logistic_*)
|-------------------------------------------------------------------------------
|
| Output        : OUT: one row per pair and statistic (BY: the group, VERSUS: the
|                 group it is compared with); GROUPS is BY VERSUS (and WITHIN).
| Note          : The iterations go on until no parameter changes by more than
|                 1E-10 (XCONV=; PROC LOGISTIC alone stops at a relative
|                 gradient of 1E-8), so that the estimate is the maximum to the
|                 digits R gives (the odds ratio 7 of a 2 x 2 table: 7, where
|                 GCONV=1E-10 gave 6.9999907).
|
| Example:
|
 %logistic(
     data   = adrs
   , where  = (paramcd = 'BOR')
   , var    = crit1fl
   , event  = "Y"
   , by     = trt01p
   , covars = age
   , class  = sex
   , order  = trt01pn
   , out    = resp_or
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
| 16-NOV-2026 Sapling      1.9.1: XCONV=1E-10 in place of GCONV=1E-10: the
|                          maximum to the last digits (the odds ratio 7 of a 2 x
|                          2 table, not 6.9999907; DEV-041). The numbers change
|                          after the sixth digit.
|
*******************************************************************************/
%MACRO logistic(
     data   =         /* The records */
   , where  =         /* The records to use: a condition in parentheses */
   , var    =         /* The response: two values */
   , event  = "Y"     /* The value that is the event, in quotes */
   , by     =         /* The groups of the model: a character variable */
   , within =         /* One model in each group of these variables */
   , covars =         /* The covariates */
   , class  =         /* The class factors */
   , pairs  = all     /* all, or the pairs: each group, then its comparator */
   , order  =         /* A numeric variable: the order of the groups */
   , level  = 0.95    /* The confidence level */
   , stats  = or="XX.XX" lcl="XX.XX" ucl="XX.XX" pval="X.XXX"
                      /* The statistics, each with its pattern */
   , label  =         /* The label of the block, in quotes */
   , out    =         /* The result */
   , debug  = no      /* yes: keep the work data sets _logistic_* */
) / DES = 'The odds ratio of pairs of groups from a logistic regression (PROC LOGISTIC)';
  %LOCAL t0 cond chars;
  %LET t0 = %_spl_begin(logistic);

  /* Step 1: the parameters */
  %IF not %_spl_need(logistic, data var by out) %THEN %RETURN;
  %IF not %_spl_vars(logistic, data, var by within covars class) %THEN %RETURN;
  %IF not %_spl_oneof(logistic, debug, yes no) %THEN %RETURN;

  %LET by     = %UPCASE(&by.);  /* the groups, in upper case */
  %LET within = %UPCASE(&within.);  /* the subgroups, in upper case */
  %LET chars  = %_spl_chars(&data., &by. &within.);  /* the character variables */
  %LET cond   = not missing(&var.) and not missing(&by.);  /* the records that count */
  %IF %LENGTH(%SUPERQ(where)) %THEN %LET cond = &cond. and &where.;  /* plus where= */

  /* Step 2: one record per subject with a response */
  DATA _logistic_records;
    %IF %LENGTH(&chars.) %THEN %DO;
      LENGTH &chars. $200;
    %END;
    SET &data.;
    WHERE &cond.;
    %IF %LENGTH(&within.) %THEN %DO;
      IF CMISS(OF &within.) = 0;
    %END;
  RUN;
  PROC SORT DATA=_logistic_records NODUPKEY; BY &within. usubjid; RUN;

  /* Step 3: no record qualified: the result without a row */
  %IF %_spl_nobs(_logistic_records) = 0 %THEN %DO;
    %_spl_empty(macro=logistic, out=&out., like=_logistic_records, keep=&by. &within., add=versus)
    %GOTO finish;
  %END;

  /* Step 4: the model, and the differences of the groups on the scale of the log odds */
  ODS EXCLUDE ALL;
  ODS OUTPUT Diffs=_logistic_diffs;
  PROC LOGISTIC DATA=_logistic_records;
    %IF %LENGTH(&within.) %THEN %DO;
      BY &within.;
    %END;
    CLASS &class. &by. / PARAM=GLM;
    MODEL &var.(event = &event.) = &by. &class. &covars. / xconv = 1E-10;
    LSMEANS &by. / DIFF CL ALPHA=%SYSEVALF(1 - &level.);
  RUN;
  ODS EXCLUDE NONE;
  DATA _logistic_diffs;
    SET _logistic_diffs;
    probt = probz;
  RUN;
  %_spl_pairs(
      diffs   = _logistic_diffs
    , by      = &by.
    , within  = &within.
    , records = _logistic_records
    , pairs   = &pairs.
    , order   = &order.
    , out     = _logistic_pairs
  )

  /* Step 5: one row per pair and statistic: the odds ratio and its limits, the result */
  DATA &out.;
    LENGTH groups block $200;
    SET _logistic_pairs;
    or     = EXP(diff);
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
      DELETE _logistic_:;
    QUIT;
  %END;
  %_spl_end(logistic, &t0., &debug.)
%MEND logistic;
