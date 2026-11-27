/*******************************************************************************
| Macro Name    : km.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.9.1
| Created By    : Sapling
| Date          : 16NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : The Kaplan-Meier summary of a time in each group (PROC
|                 LIFETEST): the subjects (n), the events (events), the median
|                 time (median) and its confidence limits (lcl, ucl; the limits
|                 of Brookmeyer and Crowley). A median the curve does not reach
|                 is missing. With time= the survival at that time in percent
|                 (surv; TIMELIST=, OUTSURV=) and its limits (lcl, ucl: then of
|                 the survival, not of the median).
| Procedure     : PROC LIFETEST
| Proven        : the known answer of the methods km, kmrate (src/methods.ts,
|                 worked out by tools/method_answers.R; node
|                 tools/methods_sas.ts); ran on SAS 9.4 M9, 2026-11-12
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| data        The records                                         Required
| where       The records to use, a condition in parentheses      Optional
| var         The time                                            Required
| by          The groups: one variable                            Required
| cnsr        The censoring variable: 1 = censored (default       CNSR
|             CNSR)
| time        A time: the survival at it (surv) and its limits    Optional
| conftype    The interval of the survival function: CONFTYPE=    linear
|             of PROC LIFETEST, linear (default: Sapling's
|             stated default plain; PROC LIFETEST alone uses
|             loglog), log, loglog
| level       The confidence level (default 0.95)                 0.95
| stats       The statistics, each with its pattern (default      n="XX" events="XX"
|             n="XX" events="XX" median="XX.X" lcl="XX.X"         median="XX.X" lcl="XX.X"
|             ucl="XX.X")                                         ucl="XX.X"
| label       The label of the block in a table, in quotes        Optional
| out         The result                                          Required
| debug       yes: keep the work data sets of the macro (_km_*)   no
|-------------------------------------------------------------------------------
|
| Output        : OUT: one row per group and statistic.
| Note          : The number at risk at given times is not made by this macro.
|
| Example:
|
 %km(
     data  = adtte
   , where = (paramcd = 'TTDE')
   , var   = aval
   , by    = trt01a
   , out   = ttde
 )
|
|-------------------------------------------------------------------------------
| Change Log :
| Date        Programmer   Description
|-------------------------------------------------------------------------------
| 11-NOV-2026 Sapling      1.0.0: initial version.
| 12-NOV-2026 Sapling      1.0.0: ran on SAS 9.4 M9.
| 12-NOV-2026 Sapling      1.1.0: the house standard (docs/sas-style.md). No
|                          number changes.
| 12-NOV-2026 Sapling      1.1.0: the label is written into the code
|                          (%_spl_quote), not read by SYMGET when the step
|                          runs: the flat program has it. No number changes.
| 13-NOV-2026 Sapling      1.7.1: a median or a limit the curve does not reach
|                          has the text NE.
| 16-NOV-2026 Sapling      1.9.0: the license line; the example in the house
|                          case (names in lower case). No number changes.
| 16-NOV-2026 Sapling      1.9.1: conftype= is checked (DEV-047); PLOTS=NONE
|                          only with ODS graphics on (DEV-051). No number
|                          changes.
|
*******************************************************************************/
%MACRO km(
     data     =         /* The records */
   , where    =         /* The records to use: a condition in parentheses */
   , var      =         /* The time */
   , by       =         /* The groups: one variable */
   , cnsr     = CNSR    /* The censoring variable: 1 = censored */
   , time     =         /* A time: the survival at it and its limits */
   , conftype = linear  /* The interval of the survival: linear, log, loglog */
   , level    = 0.95    /* The confidence level */
   , stats    = n="XX" events="XX" median="XX.X" lcl="XX.X" ucl="XX.X"
                        /* The statistics, each with its pattern */
   , label    =         /* The label of the block, in quotes */
   , out      =         /* The result */
   , debug    = no      /* yes: keep the work data sets _km_* */
) / DES = 'The Kaplan-Meier summary of a time in each group (PROC LIFETEST)';
  %LOCAL t0 cond chars plots;
  %LET t0 = %_spl_begin(km);

  /* Step 1: the parameters */
  %IF not %_spl_need(km, data var by out) %THEN %RETURN;
  %IF not %_spl_vars(km, data, var by cnsr) %THEN %RETURN;
  %IF not %_spl_oneof(km, conftype, linear log loglog) %THEN %RETURN;
  %IF not %_spl_oneof(km, debug, yes no) %THEN %RETURN;

  %LET by    = %UPCASE(&by.);  /* the groups, in upper case */
  %LET chars = %_spl_chars(&data., &by.);  /* the character variables */
  %LET cond  = not missing(&var.) and not missing(&by.);  /* the records that count */
  %IF %LENGTH(%SUPERQ(where)) %THEN %LET cond = &cond. and &where.;  /* plus where= */

  /* Step 2: the records of each group */
  DATA _km_records;
    %IF %LENGTH(&chars.) %THEN %DO;
      LENGTH &chars. $200;
    %END;
    SET &data.;
    WHERE &cond.;
  RUN;
  PROC SORT DATA=_km_records; BY &by.; RUN;

  /* Step 3: no record qualified: the result without a row */
  %IF %_spl_nobs(_km_records) = 0 %THEN %DO;
    %_spl_empty(macro=km, out=&out., like=_km_records, keep=&by.)
    %GOTO finish;
  %END;

  /* Step 4: the Kaplan Meier estimate of each group: its quartiles and its events */
  /* PLOTS=NONE only with ODS graphics on: with them off the option writes a WARNING */
  %LET plots = ;
  %IF not %SYMEXIST(sysodsgraphics) %THEN %LET plots = PLOTS=NONE;
  %ELSE %IF &sysodsgraphics. %THEN %LET plots = PLOTS=NONE;
  ODS EXCLUDE ALL;
  ODS OUTPUT Quartiles=_km_quartiles CensoredSummary=_km_events;
  PROC LIFETEST DATA=_km_records CONFTYPE=&conftype. ALPHA=%SYSEVALF(1 - &level.) &plots.
    %IF %LENGTH(&time.) %THEN %DO;
      timelist = &time. reduceout outsurv = _km_at
    %END;
    ;
    BY &by.;
    TIME &var. * &cnsr.(1);
  RUN;
  ODS EXCLUDE NONE;

  /* Step 5: one row per group and statistic: the result */
  DATA &out.;
    LENGTH groups block $200;
    MERGE _km_events(KEEP=&by. total failed RENAME=(total = n failed = events))
          _km_quartiles(KEEP=&by. percent estimate lowerlimit upperlimit WHERE=(percent = 50)
                        RENAME=(estimate = median lowerlimit = lcl upperlimit = ucl))
    %IF %LENGTH(&time.) %THEN %DO;
      _km_at(keep = &by. survival sdf_lcl sdf_ucl)
    %END;
    ;
    BY &by.;
    %IF %LENGTH(&time.) %THEN %DO;
      /* the survival at the time, in percent, and its limits */
      surv = 100 * survival;
      lcl  = 100 * sdf_lcl;
      ucl  = 100 * sdf_ucl;
    %END;
    groups = "&by.";
    block  = DEQUOTE(%_spl_quote(label));
    /* a median or a limit the curve does not reach: NE (not estimable) */
    %_spl_rows(stats=&stats., missing=NE)
    KEEP &by. groups block stat value text;
  RUN;

  /* Step 6: the work data sets are deleted (kept with debug=yes) */
  %finish:
  %IF %UPCASE(&debug.) ne YES %THEN %DO;
    PROC DATASETS LIBRARY=work NOLIST NOWARN;
      DELETE _km_:;
    QUIT;
  %END;
  %_spl_end(km, &t0., &debug.)
%MEND km;
