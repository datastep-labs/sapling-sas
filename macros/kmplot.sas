/*******************************************************************************
| Macro Name    : kmplot.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.10.0
| Created By    : Sapling
| Date          : 27NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : Draws the Kaplan-Meier curve of each group as PNG and RTF
|                 files and returns the numbers drawn. Use %km for the
|                 Kaplan-Meier estimates in a table; %kmplot computes its own
|                 curve with PROC LIFETEST. The survival is in percent, drawn as
|                 steps, with a mark at each censored time. Under the axis is
|                 the number at risk at each tick: the subjects whose time is
|                 that tick or later. With median=yes, the plot also shows the
|                 median time of each group and its confidence interval (NE: not
|                 reached). A record with a missing time, group or panel is not
|                 used. CNSR 0 is an event and any positive value is a
|                 censoring, as in ADaM, where the value names the reason of the
|                 censoring: a CNSR of 2 is censored as 1 is. A record used with
|                 a missing or negative CNSR stops the macro with an ERROR. To
|                 draw the figure again without computing, give plot= the out=
|                 and par= the outpar= of an earlier call.
| Procedure     : PROC LIFETEST, PROC SUMMARY, PROC SGPANEL
| Proven        : Its known answer: the survival and the number at risk, worked
|                 out by hand; ran on SAS 9.4 M9, 2026-11-27 (the cases of the 9
|                 figure macros: 103 of 103 the same)
| Note          : Draw again: plot= takes the out= of an earlier %kmplot call,
|                 changed or not, and draws it as it is, with no statistic
|                 computed. par= takes the outpar= of that call and gives the
|                 drawing parameters: columns, by, panel, atrisk, median, level
|                 (with plot= only for the heading of the medians), xlabel,
|                 ylabel, ref, file, width, height. These change the picture,
|                 not the numbers. The other parameters compute; with plot= the
|                 log has a NOTE for each one given, as it is not used. A
|                 drawing parameter given in the call wins over its row of par=,
|                 and the row wins over the default of the table. With plot=,
|                 the ticks are the X of the rows of KIND atrisk.
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| data        The input data set: one record per subject, such    Required
|             as a time-to-event data set. Required unless plot=
|             is given.
| plot        Draw again: the out= of an earlier %kmplot call,    Optional
|             changed or not. It is drawn as it is, and no
|             statistic is computed. Give it instead of data=.
| par         The drawing parameters of an earlier %kmplot call:  Optional
|             its outpar=. A drawing parameter given in the call
|             wins over its row of par=.
| columns     The data set of %columns: it gives the order of     Optional
|             the groups and their colours. When not given, the
|             groups come in the order of the data.
| where       The records to use: a condition in parentheses,     Optional
|             such as where = (anl01fl = 'Y')
| time        The time variable: one numeric variable (time =     Required
|             aval). Required unless plot= is given.
| cnsr        The censoring variable: one numeric variable, 0     CNSR
|             for an event and a positive value for a censoring
|             (the ADaM CNSR: 1, 2 ... name the reason). A
|             missing or negative value on a record used stops
|             the macro with an ERROR.
| by          The groups: one variable, one curve per group.      Required
|             Required unless par= gives it.
| panel       A variable: one panel per value (panel = sex)       Optional
| atrisk      yes: show the number at risk under the axis         yes
| times       The ticks of the x axis and the times of the        Optional
|             number at risk: numbers separated by blanks (times
|             = 0 30 60 90). When not given, the ticks go from 0
|             by a round step (1, 2, 2.5 or 5 times a power of
|             10) to the first tick at or after the longest
|             time.
| median      yes: show the median time of each group and its     no
|             confidence interval as text in the plot
| conftype    The type of the confidence interval of the median,  linear
|             as CONFTYPE= of PROC LIFETEST: linear, log,
|             loglog, asinsqrt or logit
| level       The confidence level of the interval of the         0.95
|             median: a number between 0 and 1
| xlabel      The label of the x axis: a text in quotes. When     Optional
|             not given, the label of time= (or its name).
| ylabel      The label of the y axis: a text in quotes           "Survival (%)"
| ref         Reference lines on the y axis: one value or         Optional
|             several, separated by blanks (ref = 0 50)
| file        The output file without its extension: the macro    Required
|             writes <file>.png (300 dpi) and <file>.rtf.
|             Required unless par= gives it.
| width       The width of the figure: a length with its unit     6.5in
|             (width = 9in)
| height      The height of the figure: a length with its unit    4.5in
|             (height = 6in)
| out         The name of the data set of the numbers drawn.      Optional
|             When not given, they are not kept.
| outpar      The name of the data set of the drawing             Optional
|             parameters, one row each. Give it to par= of a
|             later call to draw the figure again.
| debug       yes: keep the work data sets _kmplot_*              no
|-------------------------------------------------------------------------------
|
| Output        : OUT: one row per number drawn, with the variables of panel=
|                 and by=, KIND, X, Y, LOWER, UPPER, N and CENSORED. In a row of
|                 KIND curve, X is a time (0 and each time with an event or a
|                 censoring), Y the survival in percent after it, and CENSORED
|                 is 1 when a subject is censored at it. In a row of KIND
|                 atrisk, X is a tick and N the number at risk. In a row of KIND
|                 median, X is the median and LOWER and UPPER its limits
|                 (missing: not reached). OUTPAR: one row per drawing parameter,
|                 in the order of the table: PARAMETER ($32), its name, and
|                 VALUE ($500), its value as drawn (a label in quotes). FILE:
|                 <file>.png and <file>.rtf.
|
| Example:
|
 * Draws the curves with the number at risk and the median of each group, and keeps the numbers.;
 %kmplot(
     data    = adttde
   , columns = t14_2_1_cols
   , time    = aval
   , by      = trt01a
   , median  = yes
   , xlabel  = "Days to the first skin event"
   , file    = &spl_out./figures/f_ttde
   , out     = f_ttde
   , outpar  = f_ttde_par
 )
 * Draws the figure again from out= and outpar= of the call before: no median, another label.;
 %kmplot(
     plot   = f_ttde
   , par    = f_ttde_par
   , by     = trt01a
   , median = no
   , ylabel = "Subjects without a skin event (%)"
   , file   = &spl_out./figures/f_ttde_again
 )
|
|-------------------------------------------------------------------------------
| Change Log :
| Date        Programmer   Description
|-------------------------------------------------------------------------------
| 12-NOV-2026 Sapling      1.3.0: initial version: replaces %plot(type=km).
| 13-NOV-2026 Sapling      1.6.0: outpar=, plot= and par=: draw again from a
|                          changed out= and outpar=. The defaults of the
|                          drawing parameters and of the computation are set in
|                          the macro (%_spl_figure_par). No number changes.
| 13-NOV-2026 Sapling      1.7.0: the ticks reach the first tick at or after the
|                          last time (the end of a curve was cut before).
| 16-NOV-2026 Sapling      1.9.0: the default of conftype= is linear, as %km and
|                          the stated default of Sapling (it was loglog): the
|                          interval of the median is the same in the figure as
|                          in the table. The limits of the median change where
|                          conftype= is not given. The license line; the example
|                          in the house case.
| 16-NOV-2026 Sapling      1.9.1: PLOTS=NONE only with ODS graphics on: no
|                          WARNING when they are off (DEV-051). No number
|                          changes.
| 27-NOV-2026 Sapling      1.10.0: the example runs on the example data
|                          (sas/examples). The text of the header for the
|                          manual: the summary, the form of each parameter. No
|                          number changes.
| 27-NOV-2026 Sapling      1.10.0: The text of data= and time= (required unless
|                          plot= is given) and of conftype= (the values it
|                          accepts). No number changes.
| 27-NOV-2026 Sapling      1.10.0: CNSR as in ADaM: 0 is an event and any positive
|                          value a censoring (before, only 1 was a censoring and
|                          2 an event); a missing or negative CNSR on a record
|                          used stops the macro with an ERROR. No number changes
|                          on data with CNSR 0 and 1.
| 27-NOV-2026 Sapling      1.10.0: a caption for each call of the example; the
|                          first call keeps its drawing parameters (outpar=), a
|                          second call draws the figure again from them (plot=,
|                          par=). No number changes.
| 27-NOV-2026 Sapling      1.10.0: Proven in plain words, for the published
|                          manual. by= and file= are required unless par= gives
|                          them, as the code checks. No number changes.
|
*******************************************************************************/
%MACRO kmplot(
     data     =      /* The records: one per subject */
   , plot     =      /* Draw again: an out= of %kmplot */
   , par      =      /* The drawing parameters: an outpar= of %kmplot */
   , columns  =      /* The columns of %columns: order and colours */
   , where    =      /* The records to use: a condition in parentheses */
   , time     =      /* The time */
   , cnsr     =      /* The censoring variable: 0 = event (CNSR) */
   , by       =      /* The groups: one curve each */
   , panel    =      /* One panel per value of this variable */
   , atrisk   =      /* yes (default): the number at risk under the axis */
   , times    =      /* The ticks and the times of the number at risk */
   , median   =      /* yes: the median of each group as text (default no) */
   , conftype =      /* The interval of the median (linear, as %km) */
   , level    =      /* The confidence level (0.95) */
   , xlabel   =      /* The label of the x axis */
   , ylabel   =      /* The label of the y axis ("Survival (%)") */
   , ref      =      /* Reference lines on the y axis */
   , file     =      /* The output without its extension */
   , width    =      /* The width of the figure (6.5in) */
   , height   =      /* The height of the figure (4.5in) */
   , out      =      /* The numbers drawn */
   , outpar   =      /* The drawing parameters: one row each */
   , debug    = no   /* yes: keep the work data sets _kmplot_* */
) / DES = 'Kaplan-Meier curves with the number at risk (PROC LIFETEST, PROC SGPANEL)';
  %LOCAL t0 i cond chars pby listing tcomma ngroup ok drawn src xvar plots nbad;
  %LET t0 = %_spl_begin(kmplot);

  /* Step 1: the parameters */
  %_spl_figure_par(
      macro   = kmplot
    , draw    = columns by panel atrisk=yes median=no level=0.95 xlabel ylabel="Survival (%)"
                ref file width=6.5in height=4.5in
    , compute = where time cnsr=CNSR times conftype=linear
    , shape   = kind x y lower upper n censored
    , names   = drawn
    , state   = ok
  )
  %IF not &ok. %THEN %RETURN;
  %IF %LENGTH(&plot.) = 0 %THEN %DO;
    %IF not %_spl_need(kmplot, data time by file) %THEN %RETURN;
    %IF not %_spl_vars(kmplot, data, time cnsr by panel) %THEN %RETURN;
    %IF not %_spl_oneof(kmplot, conftype, linear log loglog asinsqrt logit) %THEN %RETURN;
  %END;
  %ELSE %DO;
    %IF not %_spl_need(kmplot, by file) %THEN %RETURN;
    %IF not %_spl_vars(kmplot, plot, by panel) %THEN %RETURN;
  %END;
  %IF %LENGTH(&columns.) %THEN %DO;
    %IF not %_spl_need(kmplot, columns) %THEN %RETURN;
  %END;
  %IF not %_spl_oneof(kmplot, atrisk, yes no) %THEN %RETURN;
  %IF not %_spl_oneof(kmplot, median, yes no) %THEN %RETURN;
  %IF not %_spl_oneof(kmplot, debug, yes no) %THEN %RETURN;
  %IF %LENGTH(&times.) and %LENGTH(&plot.) = 0 %THEN %DO;
    %IF not %SYSFUNC(PRXMATCH(/^[0-9. ]+$/, &times.)) %THEN %DO;
      %PUT %STR(ERR)OR: [kmplot] times=&times. is not a list of numbers;
      %PUT %STR(ERR)OR: [kmplot]   fix: give times= the ticks separated by blanks: 0 30 60 90.;
      %RETURN;
    %END;
  %END;

  %LET by    = %UPCASE(&by.);                                 /* the groups, in upper case */
  %LET panel = %UPCASE(&panel.);                              /* the panels, in upper case */
  %LET src   = &data.&plot.;                                  /* the data set read */
  %LET xvar  = &time.;                                        /* the variable of the x axis */
  %IF %LENGTH(&plot.) %THEN %LET xvar = x;                     /* with plot=: its X */
  %LET chars  = %_spl_chars(&src., &by. &panel.);              /* the character variables */
  %LET xlabel = %_spl_figure_label(&src., &xvar., %SUPERQ(xlabel));  /* the x axis */
  %LET ylabel = %_spl_figure_label(&src., , %SUPERQ(ylabel));        /* the y axis */
  %LET pby    = _panel;                                        /* the PANELBY variable */
  %IF %LENGTH(&panel.) %THEN %LET pby = &panel.;  /* with panel=: the panel variable */
  %IF %LENGTH(&out.) = 0 %THEN %LET out = _kmplot_out;         /* out= not asked: not kept */
  /* the records that count */
  %LET cond = not missing(&time.) and not missing(&by.);
  %IF %LENGTH(&panel.) %THEN %LET cond = &cond. and not missing(&panel.);  /* with a panel */
  %IF %LENGTH(%SUPERQ(where)) %THEN %LET cond = &cond. and &where.;        /* plus where= */

  /* Step 2: the drawing parameters: outpar= */
  %_spl_figure_outpar(names=&drawn., out=&outpar.)

  /* Step 3: with plot= its numbers are drawn again, the ticks the x of the number at risk */
  %IF %LENGTH(&plot.) %THEN %DO;
    DATA &out.;
      SET &plot.;
      KEEP &panel. &by. kind x y lower upper n censored;
    RUN;
    PROC SORT DATA=&out.(KEEP=kind x WHERE=(kind = 'atrisk')) OUT=_kmplot_ticks NODUPKEY; BY x; RUN;
    %LET times = ;
    DATA _NULL_;
      LENGTH _list $1000;
      SET _kmplot_ticks END=last;
      RETAIN _list;
      _list = CATX(' ', _list, x);
      IF last THEN CALL SYMPUTX('times', _list, 'L');
    RUN;
    %IF %LENGTH(&times.) = 0 %THEN %DO;
      %PUT %STR(ERR)OR: [kmplot] plot=&plot. has no row of KIND atrisk: its X are the ticks;
      %PUT %STR(ERR)OR: [kmplot]   fix: give plot= its rows of KIND atrisk (atrisk=no hides them).;
      %GOTO finish;
    %END;
    %GOTO draw;
  %END;

  /* Step 4: the records */
  DATA _kmplot_records;
    %IF %LENGTH(&chars.) %THEN %DO;
      LENGTH &chars. $200;
    %END;
    SET &data.;
    WHERE &cond.;
    _panel = 1;
    /* CNSR 0 is an event; a positive value is a censoring, with its reason */
    IF &cnsr. > 0 THEN _cens = 1;
    ELSE               _cens = 0;
    KEEP &panel. &by. &time. &cnsr. _cens _panel;
  RUN;
  /* a missing or negative CNSR is neither an event nor a censoring */
  %LET nbad = %_spl_nobs(_kmplot_records(WHERE=(MISSING(&cnsr.) OR &cnsr. < 0)));
  %IF &nbad. > 0 %THEN %DO;
    %PUT %STR(ERR)OR: [kmplot] cnsr=&cnsr. is missing or negative on &nbad. record(s) used;
    %PUT %STR(ERR)OR: [kmplot]   fix: give each record CNSR 0 (an event) or more (a censoring).;
    %GOTO finish;
  %END;

  /* Step 5: no record qualified: the figure that says so and out= without a row */
  %IF %_spl_nobs(_kmplot_records) = 0 %THEN %DO;
    %_spl_figure_nodata(
        keep   = &panel. &by.
      , macro  = kmplot
      , like   = _kmplot_records
      , chars  = kind
      , nums   = x y lower upper n censored
      , file   = &file.
      , width  = &width.
      , height = &height.
      , out    = &out.
    )
    %GOTO finish;
  %END;

  /* Step 6: the ticks: from 0 by a round step to the first tick at or after the last time */
  %IF %LENGTH(&times.) = 0 %THEN %DO;
    PROC SUMMARY DATA=_kmplot_records;
      VAR &time.;
      OUTPUT OUT=_kmplot_max MAX=_max;
    RUN;
    DATA _NULL_;
      LENGTH _list $1000;
      SET _kmplot_max;
      IF _max <= 0 THEN _max = 1;
      _raw = _max / 6;
      _mag = 10 ** FLOOR(LOG10(_raw));
      DO _m = 1, 2, 2.5, 5, 10;
        IF MISSING(_step) AND _m * _mag >= _raw * (1 - 1E-9) THEN _step = _m * _mag;
      END;
      DO _k = 0 TO CEIL(_max / _step - 1E-9);
        _list = CATX(' ', _list, ROUND(_k * _step, 1E-9));
      END;
      CALL SYMPUTX('times', _list, 'L');
    RUN;
  %END;
  %LET tcomma = %SYSFUNC(TRANWRD(%SYSFUNC(COMPBL(&times.)), %STR( ), %STR(,)));  /* DO list */

  /* Step 7: the Kaplan Meier estimate of each group; the quartiles for the median */
  PROC SORT DATA=_kmplot_records; BY &panel. &by.; RUN;
  ODS EXCLUDE ALL;
  %IF &median. = yes %THEN %DO;
    ODS OUTPUT Quartiles=_kmplot_quartiles;
  %END;
  /* PLOTS=NONE only with ODS graphics on: with them off the option writes a WARNING */
  %LET plots = ;
  %IF not %SYMEXIST(sysodsgraphics) %THEN %LET plots = PLOTS=NONE;
  %ELSE %IF &sysodsgraphics. %THEN %LET plots = PLOTS=NONE;
  PROC LIFETEST DATA=_kmplot_records OUTSURV=_kmplot_surv CONFTYPE=&conftype.
                ALPHA=%SYSEVALF(1 - &level.) &plots.;
    BY &panel. &by.;
    TIME &time. * _cens(1);
  RUN;
  ODS EXCLUDE NONE;

  /* Step 8: the curve: one row per time, the survival after it, a mark when censored */
  DATA _kmplot_curve;
    LENGTH kind $8;
    SET _kmplot_surv;
    BY &panel. &by. &time.;
    RETAIN y censored _prev;
    IF first.&by. THEN _prev = 100;
    IF first.&time. THEN DO;
      y        = .;
      censored = 0;
    END;
    IF NOT MISSING(survival) THEN y = MIN(y, 100 * survival);
    IF _censor_ = 1 THEN censored = 1;
    IF last.&time.;
    IF MISSING(y) THEN y = _prev;
    _prev = y;
    kind  = 'curve';
    x     = &time.;
    CALL MISSING(lower, upper, n);
    KEEP &panel. &by. kind x y lower upper n censored;
  RUN;

  /* Step 9: the number at risk at each tick: the subjects whose time is the tick or later */
  DATA _kmplot_ticks;
    SET _kmplot_records;
    DO x = &tcomma.;
      n = IFN(&time. >= x - 1E-9, 1, 0);
      OUTPUT;
    END;
    KEEP &panel. &by. x n;
  RUN;
  PROC SUMMARY DATA=_kmplot_ticks NWAY;
    CLASS &panel. &by. x;
    VAR n;
    OUTPUT OUT=_kmplot_risk(DROP=_TYPE_ _FREQ_) SUM=n;
  RUN;
  DATA _kmplot_risk;
    LENGTH kind $8;
    SET _kmplot_risk;
    kind = 'atrisk';
    CALL MISSING(y, lower, upper, censored);
  RUN;

  /* Step 10: the median of each group and its limits */
  %IF &median. = yes %THEN %DO;
    DATA _kmplot_median;
      LENGTH kind $8;
      SET _kmplot_quartiles(WHERE=(percent = 50));
      kind  = 'median';
      x     = estimate;
      lower = lowerlimit;
      upper = upperlimit;
      CALL MISSING(y, n, censored);
      KEEP &panel. &by. kind x y lower upper n censored;
    RUN;
  %END;

  /* Step 11: the numbers drawn: out= */
  DATA &out.;
    SET _kmplot_curve _kmplot_risk
    %IF &median. = yes %THEN %DO;
      _KMPLOT_MEDIAN
    %END;
    ;
    KEEP &panel. &by. kind x y lower upper n censored;
  RUN;
  PROC SORT DATA=&out.; BY &panel. &by. kind x; RUN;

  /* Step 12: the rows of the figure: the curve, the marks, the table and the text */
  %draw:
  DATA _kmplot_plot;
    LENGTH _mtext $200;
    SET &out.;
    _panel = 1;
    _mark  = &by.;
    _cy    = .;
    _tx    = .;
    _n     = .;
    _mtext = ' ';
    IF kind = 'curve' AND censored = 1 THEN _cy = y;
    IF kind = 'atrisk' THEN DO;
      _tx = x;
      _n  = n;
      x   = .;
    END;
    IF kind = 'median' THEN DO;
      /* the median (lower, upper); NE: not reached */
      _mtext = CATX(' ', CATS(VVALUE(&by.), ':'), IFC(MISSING(x), 'NE', STRIP(PUT(x, BEST8.))),
                    CATS('(', IFC(MISSING(lower), 'NE', STRIP(PUT(lower, BEST8.))), ','),
                    CATS(IFC(MISSING(upper), 'NE', STRIP(PUT(upper, BEST8.))), ')'));
      x = .;
    END;
  RUN;
  %_spl_figure_attrs(data=_kmplot_plot, columns=&columns., var=&by., out=_kmplot_attrs)
  %IF &median. = yes %THEN %DO;
    /* the text of the medians at the lower left, the groups in their order under a heading */
    %LET ngroup = %_spl_nobs(_kmplot_attrs(WHERE=(id = 'grp')));
    DATA _kmplot_plot;
      SET _kmplot_plot;
      BY &pby. NOTSORTED;
      IF kind = 'median' THEN DO;
        _mx = %SCAN(&times., 1, %STR( ));
        _my = 4 + 7 * (&ngroup. - _order);
      END;
      OUTPUT;
      IF last.&pby. THEN DO;
        kind   = 'heading';
        _mx    = %SCAN(&times., 1, %STR( ));
        _my    = 4 + 7 * &ngroup.;
        _mtext = "Median (%SYSEVALF(100 * &level.)% CI)";
        CALL MISSING(x, y, _cy, _tx, _n);
        OUTPUT;
      END;
    RUN;
  %END;
  PROC SORT DATA=_kmplot_plot; BY &pby. _order kind x _tx; RUN;

  /* Step 13: the figure */
  %_spl_figure_open(file=&file., width=&width., height=&height., state=listing)
  PROC SGPANEL DATA=_kmplot_plot DATTRMAP=_kmplot_attrs NOAUTOLEGEND;
    %IF %LENGTH(&panel.) %THEN %DO;
      PANELBY &pby. / NOVARNAME SPACING=10;
    %END;
    %ELSE %DO;
      PANELBY &pby. / NOHEADER NOVARNAME;
    %END;
    STEP X=x Y=y / GROUP=&by. ATTRID=grp NAME='curve' LINEATTRS=(thickness = 2);
    SCATTER X=x Y=_cy / GROUP=_mark ATTRID=grpcol MARKERATTRS=(symbol = plus size = 9);
    %IF &atrisk. = yes %THEN %DO;
      COLAXISTABLE _n / X=_tx CLASS=&by. COLORGROUP=&by. ATTRID=grp CLASSORDER=data
                        TITLE='Number at risk' TITLEATTRS=(size = 8pt) VALUEATTRS=(size = 8pt);
    %END;
    %IF &median. = yes %THEN %DO;
      TEXT X=_mx Y=_my TEXT=_mtext / POSITION=right TEXTATTRS=(size = 8pt)
                                    CONTRIBUTEOFFSETS=none;
    %END;
    %DO i = 1 %TO %SYSFUNC(COUNTW(&ref.%STR( ), %STR( )));
      REFLINE %SCAN(&ref., &i., %STR( )) / AXIS=y LINEATTRS=(pattern = dash color = gray);
    %END;
    LEGENDITEM TYPE=marker NAME='cens' / LABEL='Censored'
                                         MARKERATTRS=(symbol = plus size = 9 color = black);
    ROWAXIS LABEL=&ylabel. VALUES=(0 TO 100 BY 20) grid;
    COLAXIS LABEL=&xlabel. VALUES=(&times.) OFFSETMAX=0.02;
    KEYLEGEND 'curve' 'cens' / TITLE=' ';
  RUN;
  %_spl_figure_close(listing=&listing.)

  /* Step 14: the work data sets are deleted (kept with debug=yes) */
  %finish:
  %IF %UPCASE(&debug.) ne YES %THEN %DO;
    PROC DATASETS LIBRARY=work NOLIST NOWARN;
      DELETE _kmplot_:;
    QUIT;
  %END;
  %_spl_end(kmplot, &t0., &debug.)
%MEND kmplot;
