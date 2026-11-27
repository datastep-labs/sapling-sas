/*******************************************************************************
| Macro Name    : rate.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.9.1
| Created By    : Sapling
| Date          : 16NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : The exposure-adjusted incidence rate of each group: the
|                 subjects with a record (n; PROC FREQ), the sum of the exposure
|                 of the subjects of the group (exposure; PROC MEANS), the rate
|                 n / exposure times per= (rate) and its exact Poisson limits
|                 (lcl, ucl: the chi-square quantiles of 2n and 2(n + 1) degrees
|                 of freedom, halved, divided by the exposure; CINV).
| Procedure     : PROC FREQ, PROC MEANS, CINV
| Proven        : the known answer of the methods eair, eventrate
|                 (src/methods.ts, worked out by tools/method_answers.R; node
|                 tools/methods_sas.ts); ran on SAS 9.4 M9, 2026-11-12
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| data        The records (the events)                            Required
| denom       The subjects of the groups with their exposure:     Required
|             one row per subject
| where       The records to use, a condition in parentheses      Optional
| by          The groups: one variable, in data= and in denom=    Required
| exposure    The exposure of a subject: a variable of denom=,    Required
|             or an expression of it (TRTDUR / 365.25: in
|             years)
| count       subjects (default): the subjects with a record      subjects
|             (n); events: every record (events), the rate and
|             its limits of the number of events
| per         The rate per this many units of exposure (default   100
|             100: per 100 patient-years)
|             (the line of %layout reads "Rate per 100
|             patient-years": with another per=, change LABEL in
|             the display data set)
| level       The confidence level (default 0.95)                 0.95
| stats       The statistics, each with its pattern (default      Optional
|             n="XX" exposure="XX.X" rate="XX.XX" lcl="XX.XX"
|             ucl="XX.XX")
| label       The label of the block in a table, in quotes        Optional
| out         The result                                          Required
| debug       yes: keep the work data sets of the macro           no
|             (_rate_*)
|-------------------------------------------------------------------------------
|
| Output        : OUT: one row per group and statistic; GROUPS is BY.
|
| Example:
|
 %rate(
     data     = adae
   , denom    = adsl
   , where    = (trtemfl = 'Y')
   , by       = trt01a
   , exposure = trtdur / 365.25
   , out      = ae_rate
 )
 %rate(
     data     = adae
   , denom    = adsl
   , where    = (trtemfl = 'Y')
   , by       = trt01a
   , exposure = trtdur / 365.25
   , count    = events
   , out      = ae_events
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
| 12-NOV-2026 Sapling      1.1.0: the label is written into the code
|                          (%_spl_quote), not read by SYMGET when the step
|                          runs: the flat program has it. No number changes.
| 13-NOV-2026 Sapling      1.7.1: exposure= that is one name must be a variable
|                          of denom=.
| 16-NOV-2026 Sapling      1.9.0: the license line; the example in the house
|                          case (names in lower case). No number changes.
|
*******************************************************************************/
%MACRO rate(
     data     =           /* The records (the events) */
   , denom    =           /* The subjects with their exposure, one row each */
   , where    =           /* The records to use: a condition in parentheses */
   , by       =           /* The groups: one variable, in data= and denom= */
   , exposure =           /* The exposure: a variable of denom= or an expression */
   , count    = subjects  /* subjects (with a record) or events (every record) */
   , per      = 100       /* The rate per this many units of exposure */
   , level    = 0.95      /* The confidence level */
   , stats    =           /* The statistics, each with its pattern */
   , label    =           /* The label of the block, in quotes */
   , out      =           /* The result */
   , debug    = no        /* yes: keep the work data sets _rate_* */
) / DES = 'The exposure-adjusted incidence rate of each group, exact Poisson limits (PROC FREQ)';
  %LOCAL t0 chars;
  %LET t0 = %_spl_begin(rate);

  /* Step 1: the parameters; the default rows start with the count of the rate */
  %IF not %_spl_need(rate, data by denom exposure out) %THEN %RETURN;
  %IF not %_spl_vars(rate, data, by) %THEN %RETURN;
  %IF not %_spl_vars(rate, denom, by) %THEN %RETURN;
  /* exposure= may be an expression; one name is a variable of denom= */
  %IF %SYSFUNC(PRXMATCH(/^[A-Za-z_]\w*$/, %BQUOTE(&exposure.))) %THEN %DO;
    %IF not %_spl_vars(rate, denom, exposure) %THEN %RETURN;
  %END;
  %IF not %_spl_oneof(rate, count, subjects events) %THEN %RETURN;
  %IF not %_spl_oneof(rate, debug, yes no) %THEN %RETURN;

  %IF %LENGTH(%SUPERQ(stats)) = 0 %THEN %DO;
    %IF %UPCASE(&count.) = EVENTS %THEN
      %LET stats = events="XX" exposure="XX.X" rate="XX.XX" lcl="XX.XX" ucl="XX.XX";
    %ELSE %LET stats = n="XX" exposure="XX.X" rate="XX.XX" lcl="XX.XX" ucl="XX.XX";
  %END;
  %LET by    = %UPCASE(&by.);               /* the groups, in upper case */
  %LET chars = %_spl_chars(&denom., &by.);  /* the character variables */

  /* Step 2: the subjects with a record, each once in each group */
  DATA _rate_records;
    %IF %LENGTH(&chars.) %THEN %DO;
      LENGTH &chars. $200;
    %END;
    SET &data.;
    %IF %LENGTH(%SUPERQ(where)) %THEN %DO;
      WHERE &where.;
    %END;
    IF NOT MISSING(&by.);
    KEEP usubjid &by.;
  RUN;

  /* Step 3: the records of each group (count=events), and the subjects with a record, each once */
  PROC FREQ DATA=_rate_records NOPRINT;
    TABLES &by. / OUT=_rate_e(KEEP=&by. count RENAME=(count = events));
  RUN;
  PROC SORT DATA=_rate_records NODUPKEY; BY &by. usubjid; RUN;
  PROC FREQ DATA=_rate_records NOPRINT;
    TABLES &by. / OUT=_rate_n(KEEP=&by. count RENAME=(count = n));
  RUN;

  /* Step 4: the exposure of each group: the sum over its subjects */
  DATA _rate_denom;
    %IF %LENGTH(&chars.) %THEN %DO;
      LENGTH &chars. $200;
    %END;
    SET &denom.;
    IF NOT MISSING(&by.);
    _exposure = &exposure.;
  RUN;
  PROC SORT DATA=_rate_denom NODUPKEY; BY &by. usubjid; RUN;
  PROC MEANS DATA=_rate_denom NOPRINT;
    BY &by.;
    VAR _exposure;
    OUTPUT OUT=_rate_py(KEEP=&by. exposure) SUM=exposure;
  RUN;

  /* Step 5: one row per group and statistic: the rate and its exact limits, the result */
  DATA &out.;
    LENGTH groups block $200;
    MERGE _rate_py(IN=planned) _rate_n _rate_e;
    BY &by.;
    IF planned;
    IF MISSING(n) THEN n = 0;
    IF MISSING(events) THEN events = 0;
    /* the count of the rate: the subjects (n), or every record (events) */
    _count = n;
    %IF %UPCASE(&count.) = EVENTS %THEN %DO;
      _count = events;
    %END;
    rate = &per. * _count / exposure;
    lcl  = 0;
    IF _count > 0 THEN lcl = &per. * CINV((1 - &level.) / 2, 2 * _count) / 2 / exposure;
    ucl    = &per. * CINV(1 - (1 - &level.) / 2, 2 * (_count + 1)) / 2 / exposure;
    groups = "&by.";
    block  = DEQUOTE(%_spl_quote(label));
    %_spl_rows(stats=&stats.)
    KEEP &by. groups block stat value text;
  RUN;

  /* Step 6: the work data sets are deleted (kept with debug=yes) */
  %IF %UPCASE(&debug.) ne YES %THEN %DO;
    PROC DATASETS LIBRARY=work NOLIST NOWARN;
      DELETE _rate_:;
    QUIT;
  %END;
  %_spl_end(rate, &t0., &debug.)
%MEND rate;
