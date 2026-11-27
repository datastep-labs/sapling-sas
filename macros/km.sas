/*******************************************************************************
| Macro Name    : km.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.9.1
| Created By    : Sapling
| Date          : 27NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : Returns the Kaplan-Meier summary of a time in each group:
|                 subjects, events, the median time and its confidence limits.
|                 Use %kmplot to draw the curve, and %table_tte for the whole
|                 table of a time to event in one call. The macro writes a
|                 result: a data set with one row per number (the result shape,
|                 see %stack). The statistics are n (the subjects), events,
|                 median, lcl and ucl. The limits of the median are those of
|                 Brookmeyer and Crowley, from PROC LIFETEST. A median or a
|                 limit that the curve does not reach has a missing VALUE and
|                 the TEXT NE (not estimable). Without time=, lcl and ucl are
|                 the limits of the median. With time=, surv is the survival at
|                 that time in percent, and lcl and ucl are the limits of that
|                 survival, in percent, not of the median; the default stats=
|                 has no surv, so give stats= with surv to show it. A record
|                 with a missing time or a missing group is not used. CNSR 0 is
|                 an event and any positive value is a censoring, as in ADaM,
|                 where the value names the reason of the censoring: a CNSR of 2
|                 is censored as 1 is. A record used with a missing or negative
|                 CNSR stops the macro with an ERROR.
| Procedure     : PROC LIFETEST
| Proven        : the known answer of the methods km, kmrate (src/methods.ts,
|                 worked out by tools/method_answers.R; node
|                 tools/methods_sas.ts); ran on SAS 9.4 M9, 2026-11-12
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| data        The input data set: one record per subject, with    Required
|             the time and the censoring variable
| where       The records to use: a condition in parentheses,     Optional
|             such as where = (paramcd = 'TTDE')
| var         The time: one numeric variable, such as aval        Required
| by          The groups: one variable                            Required
| cnsr        The censoring variable: one numeric variable, 0     CNSR
|             for an event and a positive value for a censoring
|             (the ADaM CNSR: 1, 2 ... name the reason). A
|             missing or negative value on a record used stops
|             the macro with an ERROR.
| time        One time at which to give the survival: a number,   Optional
|             such as time = 180. When not given, the result has
|             no survival.
| conftype    The transformation of the confidence interval:      linear
|             linear, log or loglog, as CONFTYPE= of PROC
|             LIFETEST (the default of PROC LIFETEST itself is
|             loglog)
| level       The confidence level: a number between 0 and 1      0.95
| stats       The statistics, in the order of the rows: each      n="XX" events="XX"
|             name with its pattern of the printed number,        median="XX.X" lcl="XX.X"
|             separated by blanks. The names are n, events,       ucl="XX.X"
|             median, lcl, ucl and, with time=, surv. A name
|             without a pattern takes its default pattern
|             (n="XX", mean="XX.X", pval="X.XXX" ...; see
|             %describe).
| label       The label of the block in the table: a text in      Optional
|             quotes. A block is the rows of one call in the
|             table.
| out         The name of the result data set                     Required
| debug       yes: keep the work data sets _km_*                  no
|-------------------------------------------------------------------------------
|
| Output        : OUT: the result shape (see %stack), one row per group and
|                 statistic: the BY variable, GROUPS, BLOCK, STAT, VALUE and
|                 TEXT. When no record qualifies, the result has no row and the
|                 log has the NOTE "No data qualified".
| Note          : The macro does not give the number at risk at given times:
|                 %kmplot draws it and keeps it in its out= data set.
|
| Example:
|
 * Gives n, events, the median and its limits of each group: NE is a median not reached.;
 %km(
     data  = adttde
   , var   = aval
   , by    = trt01a
   , label = "Time to the first skin event (days)"
   , out   = ttde_km
 )
 * Gives the percent of subjects alive at day 182 and its limits, with the patterns of stats=.;
 %km(
     data  = adtte
   , where = (paramcd = 'OS')
   , var   = aval
   , by    = trt01p
   , time  = 182
   , stats = n="XX" events="XX" surv="XX.X" lcl="XX.X" ucl="XX.X"
   , out   = os_km
 )
 * Uses conftype=loglog and a 90 percent level: the median stays, its limits change.;
 %km(
     data     = adttde
   , var      = aval
   , by       = trt01a
   , conftype = loglog
   , level    = 0.90
   , out      = ttde_km90
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
| 27-NOV-2026 Sapling      1.9.1: the example runs on the example data
|                          (sas/examples). The text of the header for the
|                          manual: the summary, the form of each parameter. No
|                          number changes.
| 27-NOV-2026 Sapling      1.9.1: The example with time= shows the survival
|                          (stats= with surv); the text says which limits lcl and
|                          ucl are. The text of stats=: a name without a pattern
|                          takes its default pattern. No number changes.
| 27-NOV-2026 Sapling      1.9.1: CNSR as in ADaM: 0 is an event and any positive
|                          value a censoring (before, only 1 was a censoring and
|                          2 an event); a missing or negative CNSR on a record
|                          used stops the macro with an ERROR. No number changes
|                          on data with CNSR 0 and 1.
| 27-NOV-2026 Sapling      1.9.1: an example with conftype= and level=. No number
|                          changes.
| 27-NOV-2026 Sapling      1.9.1: a caption for each call of the example (a
|                          comment line before it). No number changes.
|
*******************************************************************************/
%MACRO km(
     data     =         /* The records */
   , where    =         /* The records to use: a condition in parentheses */
   , var      =         /* The time */
   , by       =         /* The groups: one variable */
   , cnsr     = CNSR    /* The censoring variable: 0 = event, > 0 censored */
   , time     =         /* A time: the survival at it and its limits */
   , conftype = linear  /* The interval of the survival: linear, log, loglog */
   , level    = 0.95    /* The confidence level */
   , stats    = n="XX" events="XX" median="XX.X" lcl="XX.X" ucl="XX.X"
                        /* The statistics, each with its pattern */
   , label    =         /* The label of the block, in quotes */
   , out      =         /* The result */
   , debug    = no      /* yes: keep the work data sets _km_* */
) / DES = 'The Kaplan-Meier summary of a time in each group (PROC LIFETEST)';
  %LOCAL t0 cond chars plots nbad;
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
    /* CNSR 0 is an event; a positive value is a censoring, with its reason */
    IF &cnsr. > 0 THEN _cens = 1;
    ELSE               _cens = 0;
  RUN;
  PROC SORT DATA=_km_records; BY &by.; RUN;
  /* a missing or negative CNSR is neither an event nor a censoring */
  %LET nbad = %_spl_nobs(_km_records(WHERE=(MISSING(&cnsr.) OR &cnsr. < 0)));
  %IF &nbad. > 0 %THEN %DO;
    %PUT %STR(ERR)OR: [km] cnsr=&cnsr. is missing or negative on &nbad. record(s) used;
    %PUT %STR(ERR)OR: [km]   fix: give each record CNSR 0 (an event) or more (a censoring).;
    %GOTO finish;
  %END;

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
    TIME &var. * _cens(1);
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
