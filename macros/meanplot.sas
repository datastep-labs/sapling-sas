/*******************************************************************************
| Macro Name    : meanplot.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.9.1
| Created By    : Sapling
| Date          : 27NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : Draws the mean or median of each group by visit as PNG and RTF
|                 files and returns the numbers drawn. It computes the statistic
|                 from the records; use %lineplot for values computed before
|                 (the LS means of %mmrm by visit) and %profileplot for the line
|                 of each subject. The error bars are the SE, the SD or the
|                 confidence interval of the mean, or Q1 and Q3 of the median.
|                 The points of a group are joined by a line, and the groups
|                 stand a little apart on the x axis so that their bars do not
|                 overlap. With ntable=yes, the n of each visit and group is
|                 shown under the axis. The quantiles are those of PROC MEANS
|                 with QNTLDEF=5 (R quantile type 2). A record with a missing
|                 value, visit, group or panel is not used. To draw the figure
|                 again without computing, give plot= the out= and par= the
|                 outpar= of an earlier call.
| Procedure     : PROC MEANS, PROC SGPANEL
| Proven        : its known answer in tools/figures_sas.ts (means, SE, SD,
|                 limits worked out by hand); not yet run on a SAS server
| Note          : Draw again: plot= takes the out= of an earlier %meanplot call,
|                 changed or not, and draws it as it is, with no statistic
|                 computed (error bars where LOWER has a value). par= takes the
|                 outpar= of that call and gives the drawing parameters:
|                 columns, by, panel, connect, ntable, xformat, xlabel, ylabel,
|                 ref, file, width, height. These change the picture, not the
|                 numbers. The other parameters compute; with plot= the log has
|                 a NOTE for each one given, as it is not used. A drawing
|                 parameter given in the call wins over its row of par=, and the
|                 row wins over the default of the table.
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| data        The input data set: one record per subject and      Required
|             visit
| plot        Draw again: the out= of an earlier %meanplot call,  Optional
|             changed or not. It is drawn as it is, and no
|             statistic is computed. Give it instead of data=.
| par         The drawing parameters of an earlier %meanplot      Optional
|             call: its outpar=. A drawing parameter given in
|             the call wins over its row of par=.
| columns     The data set of %columns: it gives the order of     Optional
|             the groups and their colours. When not given, the
|             groups come in the order of the data.
| where       The records to use: a condition in parentheses,     Optional
|             such as where = (anl01fl = 'Y')
| y           The variable to summarize: one numeric variable (y  Required
|             = aval)
| x           The visit: one numeric variable (x = avisitn). Its  Required
|             values are the ticks, printed with xformat=.
| by          The groups: one variable, one line per group        Required
| panel       A variable: one panel per value, one under the      Optional
|             other, each with its own y axis (panel = paramcd)
| stat        The statistic: mean or median                       mean
| error       The error bars: se, sd or ci for the mean; iqr (Q1  se
|             and Q3) for the median; or none
| level       The confidence level of error=ci: a number between  0.95
|             0 and 1
| connect     yes: join the points of a group by a line           yes
| ntable      yes: show the n of each visit and group under the   no
|             axis
| xformat     The format of the ticks of x, as in a FORMAT        Optional
|             statement (xformat = visfmt.). When not given, the
|             format of x.
| xlabel      The label of the x axis: a text in quotes. When     Optional
|             not given, the label of x= (or its name).
| ylabel      The label of the y axis: a text in quotes. When     Optional
|             not given, the statistic, the error bars and the
|             label of y=.
| ref         Reference lines on the y axis: one value or         Optional
|             several, separated by blanks (ref = 0 50)
| file        The output file without its extension: the macro    Required
|             writes <file>.png (300 dpi) and <file>.rtf
| width       The width of the figure: a length with its unit     6.5in
|             (width = 9in)
| height      The height of the figure: a length with its unit    4.5in
|             (height = 6in)
| out         The name of the data set of the numbers drawn.      Optional
|             When not given, they are not kept.
| outpar      The name of the data set of the drawing             Optional
|             parameters, one row each. Give it to par= of a
|             later call to draw the figure again.
| debug       yes: keep the work data sets _meanplot_*            no
|-------------------------------------------------------------------------------
|
| Output        : OUT: one row per panel, group and visit: the variables of
|                 panel= and by=, KIND (mean or median), X (the visit), Y (the
|                 statistic), LOWER and UPPER (the ends of the error bar;
|                 missing for se, sd and ci when there is one value) and N.
|                 OUTPAR: one row per drawing parameter, in the order of the
|                 table: PARAMETER ($32), its name, and VALUE ($500), its value
|                 as drawn (a label in quotes). FILE: <file>.png and <file>.rtf.
|
| Example:
|
 * Draws the mean change and its SE at each visit, a panel per parameter, with the n of each point.;
 %meanplot(
     data    = advs
   , columns = t14_2_1_cols
   , where   = (paramcd IN ('SYSBP' 'DIABP') AND anl01fl = 'Y' AND avisitn < 99)
   , y       = chg
   , x       = avisitn
   , by      = trt01a
   , panel   = param
   , ntable  = yes
   , xformat = VISIT.
   , ref     = 0
   , file    = &spl_out./figures/f_bp_mean
   , out     = f_bp_mean
 )
|
|-------------------------------------------------------------------------------
| Change Log :
| Date        Programmer   Description
|-------------------------------------------------------------------------------
| 12-NOV-2026 Sapling      1.3.0: initial version: replaces %plot(type=means).
| 13-NOV-2026 Sapling      1.6.0: outpar=, plot= and par=: draw again from a
|                          changed out= and outpar=. The defaults of the
|                          drawing parameters and of the computation are set in
|                          the macro (%_spl_figure_par). No number changes.
| 16-NOV-2026 Sapling      1.9.0: the x axis has room at its ends for the groups
|                          set apart (OFFSETMIN=, OFFSETMAX=): the outer groups
|                          were cut. The license line; the example in the house
|                          case. No number changes.
| 16-NOV-2026 Sapling      1.9.1: a visit with one value has no bar and no note
|                          of missing values (DEV-019). No number changes.
| 27-NOV-2026 Sapling      1.9.1: the example runs on the example data
|                          (sas/examples). The text of the header for the
|                          manual: the summary, the form of each parameter. No
|                          number changes.
| 27-NOV-2026 Sapling      1.9.1: a caption for each call of the example (a
|                          comment line before it). No number changes.
|
*******************************************************************************/
%MACRO meanplot(
     data    =      /* The records */
   , plot    =      /* Draw again: an out= of %meanplot */
   , par     =      /* The drawing parameters: an outpar= of %meanplot */
   , columns =      /* The columns of %columns: order and colours */
   , where   =      /* The records to use: a condition in parentheses */
   , y       =      /* The variable */
   , x       =      /* The visit: a numeric variable */
   , by      =      /* The groups: one line each */
   , panel   =      /* One panel per value of this variable */
   , stat    =      /* mean (default) or median */
   , error   =      /* se (default), sd, ci, iqr or none */
   , level   =      /* The confidence level of error=ci (0.95) */
   , connect =      /* yes (default): the points of a group joined by a line */
   , ntable  =      /* yes: the n of each visit and group under the axis (no) */
   , xformat =      /* The format of the ticks of x */
   , xlabel  =      /* The label of the x axis */
   , ylabel  =      /* The label of the y axis */
   , ref     =      /* Reference lines on the y axis */
   , file    =      /* The output without its extension */
   , width   =      /* The width of the figure (6.5in) */
   , height  =      /* The height of the figure (4.5in) */
   , out     =      /* The numbers drawn */
   , outpar  =      /* The drawing parameters: one row each */
   , debug   = no   /* yes: keep the work data sets _meanplot_* */
) / DES = 'Mean or median by visit with error bars (PROC MEANS, PROC SGPANEL)';
  %LOCAL t0 i cond chars pby listing ticks dsid rc xnum xtype words ok drawn src xvar xoff;
  %LET t0 = %_spl_begin(meanplot);

  /* Step 1: the parameters */
  %_spl_figure_par(
      macro   = meanplot
    , draw    = columns by panel connect=yes ntable=no xformat xlabel ylabel ref file width=6.5in
                height=4.5in
    , compute = where y x stat=mean error=se level=0.95
    , shape   = kind x y lower upper n
    , names   = drawn
    , state   = ok
  )
  %IF not &ok. %THEN %RETURN;
  %IF %LENGTH(&plot.) = 0 %THEN %DO;
    %IF not %_spl_need(meanplot, data y x by file) %THEN %RETURN;
    %IF not %_spl_vars(meanplot, data, y x by panel) %THEN %RETURN;
    %IF not %_spl_oneof(meanplot, stat, mean median) %THEN %RETURN;
    %IF not %_spl_oneof(meanplot, error, se sd ci iqr none) %THEN %RETURN;
    %IF (%LOWCASE(&stat.) = mean and %LOWCASE(&error.) = iqr)
     or (%LOWCASE(&stat.) = median and %SYSFUNC(INDEXW(se sd ci, %LOWCASE(&error.)))) %THEN %DO;
      %PUT %STR(ERR)OR: [meanplot] error=&error. does not go with stat=&stat.;
      %PUT %STR(ERR)OR: [meanplot]   fix: give the mean error=se, sd or ci, the median iqr or none.;
      %RETURN;
    %END;
    %LET dsid  = %SYSFUNC(OPEN(&data.));
    %LET xnum  = %SYSFUNC(VARNUM(&dsid., &x.));
    %LET xtype = %SYSFUNC(VARTYPE(&dsid., &xnum.));
    /* the format of the ticks, when xformat= is not given */
    %IF %LENGTH(&xformat.) = 0 %THEN %LET xformat = %SYSFUNC(VARFMT(&dsid., &xnum.));
    %LET rc = %SYSFUNC(CLOSE(&dsid.));
    %IF &xtype. = C %THEN %DO;
      %PUT %STR(ERR)OR: [meanplot] x=&x. is a character variable;
      %PUT %STR(ERR)OR: [meanplot]   fix: give x= the numeric visit (AVISITN), xformat= its labels.;
      %RETURN;
    %END;
  %END;
  %ELSE %DO;
    %IF not %_spl_need(meanplot, by file) %THEN %RETURN;
    %IF not %_spl_vars(meanplot, plot, by panel) %THEN %RETURN;
  %END;
  %IF %LENGTH(&columns.) %THEN %DO;
    %IF not %_spl_need(meanplot, columns) %THEN %RETURN;
  %END;
  %IF not %_spl_oneof(meanplot, connect, yes no) %THEN %RETURN;
  %IF not %_spl_oneof(meanplot, ntable, yes no) %THEN %RETURN;
  %IF not %_spl_oneof(meanplot, debug, yes no) %THEN %RETURN;

  %LET stat  = %LOWCASE(&stat.);                         /* the statistic */
  %LET error = %LOWCASE(&error.);                        /* the error bars */
  %LET by    = %UPCASE(&by.);                            /* the groups, in upper case */
  %LET panel = %UPCASE(&panel.);                         /* the panels, in upper case */
  %LET src   = &data.&plot.;                             /* the data set read */
  %LET xvar  = &x.;                                      /* the variable of the x axis */
  %IF %LENGTH(&plot.) %THEN %LET xvar = x;                /* with plot=: its X */
  %LET chars  = %_spl_chars(&src., &by. &panel.);         /* the character variables */
  %LET xlabel = %_spl_figure_label(&src., &xvar., %SUPERQ(xlabel));  /* the x axis */
  %LET words  = %SYSFUNC(PROPCASE(&stat.));               /* the words of the default y label */
  %IF &error. = se %THEN %LET words = &words. (+/- SE);  /* the words of the default y label */
  %IF &error. = sd %THEN %LET words = &words. (+/- SD);  /* the words of the default y label */
  /* the words of the default y label */
  %IF &error. = ci %THEN %LET words = &words. (%SYSEVALF(100 * &level.)% CI);
  /* the words of the default y label */
  %IF &error. = iqr %THEN %LET words = &words. (Q1%STR(,) Q3);
  %IF %LENGTH(%SUPERQ(ylabel)) = 0 and %LENGTH(&plot.) = 0 %THEN
    /* the default y label */
    %LET ylabel = "&words. of %SYSFUNC(DEQUOTE(%_spl_figure_label(&data., &y.)))";
  %LET ylabel = %_spl_figure_label(&src., y, %SUPERQ(ylabel));  /* the y axis */
  %LET pby    = _panel;                                   /* the PANELBY variable */
  %IF %LENGTH(&panel.) %THEN %LET pby = &panel.;  /* with panel=: the panel variable */
  %IF %LENGTH(&out.) = 0 %THEN %LET out = _meanplot_out;  /* out= not asked: not kept */
  /* the records that count */
  %LET cond = not missing(&y.) and not missing(&x.) and not missing(&by.);
  %IF %LENGTH(&panel.) %THEN %LET cond = &cond. and not missing(&panel.);  /* with a panel */
  %IF %LENGTH(%SUPERQ(where)) %THEN %LET cond = &cond. and &where.;        /* plus where= */

  /* Step 2: the drawing parameters: outpar= */
  %_spl_figure_outpar(names=&drawn., out=&outpar.)

  /* Step 3: with plot= its numbers are drawn again: error bars where LOWER has a value */
  %IF %LENGTH(&plot.) %THEN %DO;
    DATA &out.;
      SET &plot.;
      KEEP &panel. &by. kind x y lower upper n;
    RUN;
    %IF %_spl_nobs(&out.(WHERE=(NOT MISSING(lower)))) = 0 %THEN %LET error = none;
    %GOTO draw;
  %END;

  /* Step 4: the records */
  DATA _meanplot_records;
    %IF %LENGTH(&chars.) %THEN %DO;
      LENGTH &chars. $200;
    %END;
    SET &data.;
    WHERE &cond.;
    _panel = 1;
    KEEP &panel. &by. &x. &y. _panel;
  RUN;

  /* Step 5: no record qualified: the figure that says so and out= without a row */
  %IF %_spl_nobs(_meanplot_records) = 0 %THEN %DO;
    %_spl_figure_nodata(
        keep   = &panel. &by.
      , macro  = meanplot
      , like   = _meanplot_records
      , chars  = kind
      , nums   = x y lower upper n
      , file   = &file.
      , width  = &width.
      , height = &height.
      , out    = &out.
    )
    %GOTO finish;
  %END;

  /* Step 6: the statistics of each panel, group and visit */
  PROC MEANS DATA=_meanplot_records NOPRINT NWAY QNTLDEF=5 ALPHA=%SYSEVALF(1 - &level.);
    CLASS &panel. &by. &x.;
    VAR &y.;
    OUTPUT OUT=_meanplot_stats N=n MEAN=mean STD=sd STDERR=se MEDIAN=median Q1=q1 Q3=q3
           LCLM=lclm UCLM=uclm;
  RUN;

  /* Step 7: the numbers drawn: out= */
  DATA &out.;
    LENGTH kind $8;
    SET _meanplot_stats;
    kind = "&stat.";
    x    = &x.;
    y    = &stat.;
    /* a visit with one value has no SE and no SD: no bar, and no note of missing values */
    CALL MISSING(lower, upper);
    %IF &error. = se %THEN %DO;
      IF NOT MISSING(se) THEN DO;
        lower = mean - se;
        upper = mean + se;
      END;
    %END;
    %ELSE %IF &error. = sd %THEN %DO;
      IF NOT MISSING(sd) THEN DO;
        lower = mean - sd;
        upper = mean + sd;
      END;
    %END;
    %ELSE %IF &error. = ci %THEN %DO;
      lower = lclm;
      upper = uclm;
    %END;
    %ELSE %IF &error. = iqr %THEN %DO;
      lower = q1;
      upper = q3;
    %END;
    %ELSE %DO;
      CALL MISSING(lower, upper);
    %END;
    KEEP &panel. &by. kind x y lower upper n;
  RUN;

  /* Step 8: the rows of the figure: the groups a little apart, the ticks at the visits */
  %draw:
  DATA _meanplot_plot;
    SET &out.;
    _panel = 1;
    _bar   = &by.;
  RUN;
  %_spl_figure_attrs(data=_meanplot_plot, columns=&columns., var=&by., out=_meanplot_attrs)
  %_spl_figure_dodge(data=_meanplot_plot, x=x, offset=xoff)
  PROC SORT DATA=_meanplot_plot; BY &pby. _order x; RUN;
  PROC SORT DATA=_meanplot_plot(KEEP=x) OUT=_meanplot_ticks NODUPKEY; BY x; RUN;
  DATA _NULL_;
    LENGTH _list $2000;
    SET _meanplot_ticks END=last;
    RETAIN _list;
    _list = CATX(' ', _list, x);
    IF last THEN CALL SYMPUTX('ticks', _list, 'L');
  RUN;

  /* Step 9: the figure */
  %_spl_figure_open(file=&file., width=&width., height=&height., state=listing)
  PROC SGPANEL DATA=_meanplot_plot DATTRMAP=_meanplot_attrs NOAUTOLEGEND;
    %IF %LENGTH(&panel.) %THEN %DO;
      PANELBY &pby. / NOVARNAME SPACING=10 COLUMNS=1 UNISCALE=column;
    %END;
    %ELSE %DO;
      PANELBY &pby. / NOHEADER NOVARNAME;
    %END;
    %IF &error. ne none %THEN %DO;
      HIGHLOW X=_xplot LOW=lower HIGH=upper / GROUP=_bar ATTRID=grpcol LOWCAP=serif
                                              HIGHCAP=serif;
    %END;
    %IF &connect. = yes %THEN %DO;
      SERIES X=_xplot Y=y / GROUP=&by. ATTRID=grp MARKERS NAME='stat'
                            LINEATTRS=(thickness = 1.5) MARKERATTRS=(size = 8);
    %END;
    %ELSE %DO;
      SCATTER X=_xplot Y=y / GROUP=&by. ATTRID=grp NAME='stat' MARKERATTRS=(size = 8);
    %END;
    %IF &ntable. = yes %THEN %DO;
      COLAXISTABLE n / X=x CLASS=&by. COLORGROUP=&by. ATTRID=grp CLASSORDER=data
                       TITLE='n' TITLEATTRS=(size = 8pt) VALUEATTRS=(size = 8pt);
    %END;
    %DO i = 1 %TO %SYSFUNC(COUNTW(&ref.%STR( ), %STR( )));
      REFLINE %SCAN(&ref., &i., %STR( )) / AXIS=y LINEATTRS=(pattern = dash color = gray);
    %END;
    %IF %LENGTH(&xformat.) %THEN %DO;
      FORMAT x _xplot &xformat.;
    %END;
    ROWAXIS LABEL=&ylabel. grid;
    %IF %LENGTH(&xoff.) %THEN %DO;
      COLAXIS LABEL=&xlabel. VALUES=(&ticks.) OFFSETMIN=&xoff. OFFSETMAX=&xoff.;
    %END;
    %ELSE %DO;
      COLAXIS LABEL=&xlabel. VALUES=(&ticks.);
    %END;
    KEYLEGEND 'stat' / TITLE=' ';
  RUN;
  %_spl_figure_close(listing=&listing.)

  /* Step 10: the work data sets are deleted (kept with debug=yes) */
  %finish:
  %IF %UPCASE(&debug.) ne YES %THEN %DO;
    PROC DATASETS LIBRARY=work NOLIST NOWARN;
      DELETE _meanplot_:;
    QUIT;
  %END;
  %_spl_end(meanplot, &t0., &debug.)
%MEND meanplot;
