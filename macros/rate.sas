/*******************************************************************************
| Macro Name    : rate.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.9.1
| Created By    : Sapling
| Date          : 27NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : Returns the exposure-adjusted incidence rate of each group,
|                 with its exact Poisson confidence limits. Use %freq for the
|                 percent of subjects with an event, and %rateratio to compare
|                 the rates of two groups. The macro writes a result: a data set
|                 with one row per number (the result shape, see %stack). The
|                 statistics:
|                 - n: the subjects with a record (PROC FREQ); events: every
|                   record
|                 - exposure: the sum of the exposure of the subjects of the
|                   group in denom= (PROC MEANS)
|                 - rate: n (or events with count=events) divided by the
|                   exposure, times per=
|                 - lcl, ucl: the exact Poisson limits, the chi-square quantiles
|                   (CINV) of 2n and 2(n + 1) degrees of freedom, halved,
|                   divided by the exposure, times per=
| Procedure     : PROC FREQ, PROC MEANS, CINV
| Proven        : the known answer of the methods eair, eventrate
|                 (src/methods.ts, worked out by tools/method_answers.R; node
|                 tools/methods_sas.ts); ran on SAS 9.4 M9, 2026-11-12
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| data        The input data set: the records of the events,      Required
|             with USUBJID
| denom       The subjects of the groups with their exposure: a   Required
|             data set with one row per subject, USUBJID and the
|             variable of by=
| where       The records to use: a condition in parentheses,     Optional
|             such as where = (trtemfl = 'Y')
| by          The groups: one variable, in data= and in denom=    Required
| exposure    The exposure of a subject: a numeric variable of    Required
|             denom=, or an expression of its variables
|             (exposure = trtdur / 365.25 gives years)
| count       What the rate counts: subjects (the subjects with   subjects
|             a record, each once) or events (every record)
| per         The units of exposure of the rate: a number (per =  100
|             1000 gives the rate per 1000 patient-years). The
|             row label of %layout reads "Rate per 100
|             patient-years"; with another per=, change LABEL in
|             the display data set.
| level       The confidence level: a number between 0 and 1      0.95
|             (level = 0.90)
| stats       The statistics, in the order of the rows: each      Optional
|             name with its pattern of the printed number,
|             separated by blanks. The names are n, events,
|             exposure, rate, lcl and ucl. When not given: n
|             (events with count=events), exposure, rate, lcl
|             and ucl. A name without a pattern takes its
|             default pattern (n="XX", mean="XX.X", pval="X.XXX"
|             ...; see %describe).
| label       The label of the block in the table: a text in      Optional
|             quotes. A block is the rows of one call in the
|             table.
| out         The name of the result data set                     Required
| debug       yes: keep the work data sets _rate_*                no
|-------------------------------------------------------------------------------
|
| Output        : OUT: the result shape (see %stack), one row per group and
|                 statistic: the variable of by=, GROUPS (by=), BLOCK, STAT,
|                 VALUE and TEXT. Every group of denom= has its rows: n = 0 when
|                 no subject of it has a record.
|
| Example:
|
 * Gives the subjects with an event per 100 patient years, with the exposure and the limits.;
 %rate(
     data     = adae
   , denom    = adsl(WHERE=(trtdurd > 0))
   , where    = (trtemfl = 'Y')
   , by       = trt01a
   , exposure = trtdurd / 365.25
   , out      = ae_rate
 )
 * Counts the events, not the subjects, with count=events: a subject adds each of its events.;
 %rate(
     data     = adae
   , denom    = adsl(WHERE=(trtdurd > 0))
   , where    = (trtemfl = 'Y')
   , by       = trt01a
   , exposure = trtdurd / 365.25
   , count    = events
   , out      = ae_events
 )
 * Gives the rate of severe events per 1000 patient years with per=1000.;
 %rate(
     data     = adae
   , denom    = adsl(WHERE=(trtdurd > 0))
   , where    = (trtemfl = 'Y' AND aesev = 'SEVERE')
   , by       = trt01a
   , exposure = trtdurd / 365.25
   , per      = 1000
   , out      = ae_rate1000
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
| 27-NOV-2026 Sapling      1.9.1: the example runs on the example data
|                          (sas/examples). The text of the header for the
|                          manual: the summary, the form of each parameter. No
|                          number changes.
| 27-NOV-2026 Sapling      1.9.1: The text of stats=: a name without a pattern
|                          takes its default pattern. No number changes.
| 27-NOV-2026 Sapling      1.9.1: an example with per=. No number changes.
| 27-NOV-2026 Sapling      1.9.1: a caption for each call of the example (a
|                          comment line before it). No number changes.
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
