/*******************************************************************************
| Macro Name    : logistic.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.10.0
| Created By    : Sapling
| Date          : 27NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : Returns the odds ratios of pairs of groups from a logistic
|                 regression, with their Wald confidence limits and p-values.
|                 Use %risk for a risk difference, relative risk or odds ratio
|                 from the 2 x 2 table of a pair, without a model. The model is
|                 PROC LOGISTIC of a response with two values: the probability
|                 of the event of event= on the groups, the class factors and
|                 the covariates, one record per subject (the first with a
|                 response). All pairs come from one fit. The macro writes a
|                 result: a data set with one row per number (the result shape,
|                 see %stack).
| Procedure     : PROC LOGISTIC (LSMEANS)
| Proven        : Checked against its known answer (on a small data set, the
|                 numbers worked out independently in R); ran on SAS 9.4 M9,
|                 2026-11-12
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| data        The input data set, with USUBJID                    Required
| where       The records to use: a condition in parentheses,     Optional
|             such as where = (paramcd = 'RESP')
| var         The response: one variable with two values,         Required
|             numeric or character
| event       The value of var= that is the event, in quotes;     "Y"
|             for a number also in quotes (event = "1"). PROC
|             LOGISTIC alone models the first value in sort
|             order.
| by          The groups of the model: one character variable     Required
| within      One model in each group of these variables,         Optional
|             separated by blanks, such as the levels of a
|             subgroup (within = sex)
| covars      The covariates: numeric variables separated by      Optional
|             blanks (covars = age)
| class       The class factors besides the groups: variables     Optional
|             separated by blanks (class = sex)
| pairs       The pairs of groups to compare. all: each later     all
|             group against each earlier one, in the order of
|             order= (or of the values). Or the pairs separated
|             by #, each the group first and then the group it
|             is compared with, a value with a blank or a hyphen
|             in quotes: pairs = "Drug" "Placebo" # "High"
|             "Low"
| order       The order of the groups: one numeric variable with  Optional
|             one value per group (order = trt01pn)
| level       The confidence level of the limits: a number        0.95
|             between 0 and 1
| stats       The statistics, in the order of the rows: each      or="XX.XX" lcl="XX.XX"
|             name with the pattern of its printed number,        ucl="XX.XX" pval="X.XXX"
|             separated by blanks. The names are or, lcl, ucl
|             and pval. A name without a pattern takes its
|             default pattern (n="XX", mean="XX.X", pval="X.XXX"
|             ...; see %describe).
| label       The label of the block in the table: a text in      Optional
|             quotes. A block is the rows of one call in the
|             table.
| out         The name of the result data set                     Required
| debug       yes: keep the work data sets _logistic_*            no
|-------------------------------------------------------------------------------
|
| Output        : OUT: the result shape (see %stack), one row per pair and
|                 statistic: the group in the by= variable, the group it is
|                 compared with in VERSUS, and the variables of within=. or is
|                 the odds of the event of event= in the group over the odds in
|                 VERSUS, adjusted for the covariates and the class factors (an
|                 odds ratio above 1: the event is more likely in the group),
|                 lcl and ucl its Wald confidence limits, pval its p-value. With
|                 pairs=all the group is the later one in the order of order=.
|                 GROUPS is the by= variable, VERSUS and the within= variables.
| Note          : The iterations go on until no parameter changes by more than
|                 1E-10 (XCONV=). PROC LOGISTIC alone stops at a relative
|                 gradient of 1E-8. So the estimate is the maximum to the digits
|                 R gives: the odds ratio 7 of a 2 x 2 table is 7, where
|                 GCONV=1E-10 gave 6.9999907.
|
| Example:
|
 * Gives the odds ratio of discontinuation for each pair, adjusted for age and sex.;
 %logistic(
     data   = adsl
   , var    = eosstt
   , event  = "DISCONTINUED"
   , by     = trt01a
   , covars = age
   , class  = sex
   , order  = trt01an
   , out    = eos_or
 )
 * Gives the odds ratio against Placebo for each sex: the rows carry SEX.;
 %logistic(
     data   = adsl
   , var    = eosstt
   , event  = "DISCONTINUED"
   , by     = trt01a
   , within = sex
   , pairs  = "Xanomeline High Dose" "Placebo"
            # "Xanomeline Low Dose"  "Placebo"
   , out    = eos_or_sex
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
| 27-NOV-2026 Sapling      1.10.0: the example runs on the example data
|                          (sas/examples). The text of the header for the
|                          manual: the summary, the form of each parameter. No
|                          number changes.
| 27-NOV-2026 Sapling      1.10.0: The text of stats=: a name without a pattern
|                          takes its default pattern. No number changes.
| 27-NOV-2026 Sapling      1.10.0: an example with within= and pairs=. No number
|                          changes.
| 27-NOV-2026 Sapling      1.10.0: a caption for each call of the example (a
|                          comment line before it). No number changes.
| 27-NOV-2026 Sapling      1.10.0: The Output says the direction of or (the odds
|                          of the group over the odds of VERSUS); Proven in
|                          plain words, for the published manual. No number
|                          changes.
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
