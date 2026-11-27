/*******************************************************************************
| Macro Name    : lineplot.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.9.1
| Created By    : Sapling
| Date          : 27NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : Draws lines through given values, one line per group, as PNG
|                 and RTF files and returns the numbers drawn. It computes
|                 nothing: use it for values computed before (the LS means of
|                 %lsmeans or %mmrm by visit, a rate by month), and %meanplot to
|                 compute the mean of the records. The interval of lower= and
|                 upper= is drawn as error bars, with the groups a little apart
|                 on the x axis, or as a band. A row with a missing x, group or
|                 panel is not used. To draw the figure again without computing,
|                 give plot= the out= and par= the outpar= of an earlier call.
| Procedure     : PROC SGPANEL
| Proven        : its known answer in tools/figures_sas.ts (the values given);
|                 not yet run on a SAS server
| Note          : Draw again: plot= takes the out= of an earlier %lineplot call,
|                 changed or not, and draws it as it is, with no statistic
|                 computed (an interval where LOWER has a value). par= takes the
|                 outpar= of that call and gives the drawing parameters:
|                 columns, by, panel, band, xformat, xlabel, ylabel, ref, file,
|                 width, height. These change the picture, not the numbers. The
|                 other parameters choose the values; with plot= the log has a
|                 NOTE for each one given, as it is not used. A drawing
|                 parameter given in the call wins over its row of par=, and the
|                 row wins over the default of the table.
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| data        The input data set: one row per group and x         Required
| plot        Draw again: the out= of an earlier %lineplot call,  Optional
|             changed or not. It is drawn as it is, and no
|             statistic is computed. Give it instead of data=.
| par         The drawing parameters of an earlier %lineplot      Optional
|             call: its outpar=. A drawing parameter given in
|             the call wins over its row of par=.
| columns     The data set of %columns: it gives the order of     Optional
|             the groups and their colours. When not given, the
|             groups come in the order of the data.
| where       The rows to use: a condition in parentheses, such   Optional
|             as where = (paramcd = 'SYSBP')
| x           The x: one numeric variable (x = avisitn)           Required
| y           The value: one numeric variable (y = estimate)      Required
| by          The groups: one variable, one line per group        Required
| panel       A variable: one panel per value, one under the      Optional
|             other, each with its own y axis (panel = paramcd)
| lower       The lower end of the interval: one numeric          Optional
|             variable. Give upper= with it.
| upper       The upper end of the interval: one numeric          Optional
|             variable. Give lower= with it.
| band        yes: draw the interval as a band; no: as error      no
|             bars
| xformat     The format of the ticks of x, as in a FORMAT        Optional
|             statement (xformat = visfmt.). When not given, the
|             format of x.
| xlabel      The label of the x axis: a text in quotes. When     Optional
|             not given, the label of x= (or its name).
| ylabel      The label of the y axis: a text in quotes. When     Optional
|             not given, the label of y= (or its name).
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
| debug       yes: keep the work data sets _lineplot_*            no
|-------------------------------------------------------------------------------
|
| Output        : OUT: one row per panel, group and x: the variables of panel=
|                 and by=, KIND (line), X, Y, LOWER and UPPER. OUTPAR: one row
|                 per drawing parameter, in the order of the table: PARAMETER
|                 ($32), its name, and VALUE ($500), its value as drawn (a label
|                 in quotes). FILE: <file>.png and <file>.rtf.
|
| Example:
|
 * Draws the means that meanplot kept as lines, with a band between the limits.;
 %lineplot(
     data    = f_bp_mean
   , columns = t14_2_1_cols
   , x       = x
   , y       = y
   , by      = trt01a
   , panel   = param
   , lower   = lower
   , upper   = upper
   , band    = yes
   , xformat = VISIT.
   , ylabel  = "Mean change from baseline (SE)"
   , ref     = 0
   , file    = &spl_out./figures/f_bp_line
   , out     = f_bp_line
 )
|
|-------------------------------------------------------------------------------
| Change Log :
| Date        Programmer   Description
|-------------------------------------------------------------------------------
| 12-NOV-2026 Sapling      1.3.0: initial version.
| 13-NOV-2026 Sapling      1.6.0: outpar=, plot= and par=: draw again from a
|                          changed out= and outpar=. The defaults of the
|                          drawing parameters and of the computation are set in
|                          the macro (%_spl_figure_par). No number changes.
| 16-NOV-2026 Sapling      1.9.0: the x axis has room at its ends for the groups
|                          set apart (OFFSETMIN=, OFFSETMAX=): the outer groups
|                          were cut. The license line; the example in the house
|                          case. No number changes.
| 27-NOV-2026 Sapling      1.9.1: the example runs on the example data
|                          (sas/examples). The text of the header for the
|                          manual: the summary, the form of each parameter. No
|                          number changes.
| 27-NOV-2026 Sapling      1.9.1: a caption for each call of the example (a
|                          comment line before it). No number changes.
|
*******************************************************************************/
%MACRO lineplot(
     data    =      /* The values: one row per group and x */
   , plot    =      /* Draw again: an out= of %lineplot */
   , par     =      /* The drawing parameters: an outpar= of %lineplot */
   , columns =      /* The columns of %columns: order and colours */
   , where   =      /* The rows to use: a condition in parentheses */
   , x       =      /* The x: a numeric variable */
   , y       =      /* The value */
   , by      =      /* The groups: one line each */
   , panel   =      /* One panel per value of this variable */
   , lower   =      /* The lower end of the interval */
   , upper   =      /* The upper end of the interval */
   , band    =      /* yes: the interval as a band (default no) */
   , xformat =      /* The format of the ticks of x */
   , xlabel  =      /* The label of the x axis */
   , ylabel  =      /* The label of the y axis */
   , ref     =      /* Reference lines on the y axis */
   , file    =      /* The output without its extension */
   , width   =      /* The width of the figure (6.5in) */
   , height  =      /* The height of the figure (4.5in) */
   , out     =      /* The numbers drawn */
   , outpar  =      /* The drawing parameters: one row each */
   , debug   = no   /* yes: keep the work data sets _lineplot_* */
) / DES = 'Lines through values given, with their interval (PROC SGPANEL)';
  %LOCAL t0 i cond chars pby listing ticks dsid rc xnum xtype ok drawn src xvar yvar bars xoff;
  %LET t0 = %_spl_begin(lineplot);

  /* Step 1: the parameters */
  %_spl_figure_par(
      macro   = lineplot
    , draw    = columns by panel band=no xformat xlabel ylabel ref file width=6.5in height=4.5in
    , compute = where x y lower upper
    , shape   = kind x y lower upper
    , names   = drawn
    , state   = ok
  )
  %IF not &ok. %THEN %RETURN;
  %IF %LENGTH(&plot.) = 0 %THEN %DO;
    %IF not %_spl_need(lineplot, data x y by file) %THEN %RETURN;
    %IF not %_spl_vars(lineplot, data, x y by panel lower upper) %THEN %RETURN;
    %IF (%LENGTH(&lower.) = 0) ne (%LENGTH(&upper.) = 0) %THEN %DO;
      %PUT %STR(ERR)OR: [lineplot] lower= and upper= come together;
      %PUT %STR(ERR)OR: [lineplot]   fix: give both ends of the interval, or neither.;
      %RETURN;
    %END;
    %LET dsid  = %SYSFUNC(OPEN(&data.));
    %LET xnum  = %SYSFUNC(VARNUM(&dsid., &x.));
    %LET xtype = %SYSFUNC(VARTYPE(&dsid., &xnum.));
    /* the format of the ticks, when xformat= is not given */
    %IF %LENGTH(&xformat.) = 0 %THEN %LET xformat = %SYSFUNC(VARFMT(&dsid., &xnum.));
    %LET rc = %SYSFUNC(CLOSE(&dsid.));
    %IF &xtype. = C %THEN %DO;
      %PUT %STR(ERR)OR: [lineplot] x=&x. is a character variable;
      %PUT %STR(ERR)OR: [lineplot]   fix: give x= a numeric variable (AVISITN), xformat= labels.;
      %RETURN;
    %END;
  %END;
  %ELSE %DO;
    %IF not %_spl_need(lineplot, by file) %THEN %RETURN;
    %IF not %_spl_vars(lineplot, plot, by panel) %THEN %RETURN;
  %END;
  %IF %LENGTH(&columns.) %THEN %DO;
    %IF not %_spl_need(lineplot, columns) %THEN %RETURN;
  %END;
  %IF not %_spl_oneof(lineplot, band, yes no) %THEN %RETURN;
  %IF not %_spl_oneof(lineplot, debug, yes no) %THEN %RETURN;

  %LET by    = %UPCASE(&by.);                            /* the groups, in upper case */
  %LET panel = %UPCASE(&panel.);                         /* the panels, in upper case */
  %LET src   = &data.&plot.;                             /* the data set read */
  %LET xvar  = &x.;                                      /* the variable of the x axis */
  %LET yvar  = &y.;                                      /* the variable of the y axis */
  %IF %LENGTH(&plot.) %THEN %LET xvar = x;                /* with plot=: its X */
  %IF %LENGTH(&plot.) %THEN %LET yvar = y;                /* with plot=: its Y */
  %LET bars = no;                                       /* an interval */
  %IF %LENGTH(&lower.) %THEN %LET bars = yes;             /* lower= and upper= given */
  %LET chars  = %_spl_chars(&src., &by. &panel.);         /* the character variables */
  %LET xlabel = %_spl_figure_label(&src., &xvar., %SUPERQ(xlabel));  /* the x axis */
  %LET ylabel = %_spl_figure_label(&src., &yvar., %SUPERQ(ylabel));  /* the y axis */
  %LET pby    = _panel;                                   /* the PANELBY variable */
  %IF %LENGTH(&panel.) %THEN %LET pby = &panel.;  /* with panel=: the panel variable */
  %IF %LENGTH(&out.) = 0 %THEN %LET out = _lineplot_out;  /* out= not asked: not kept */
  %LET cond = not missing(&x.) and not missing(&by.);  /* the records that count */
  %IF %LENGTH(&panel.) %THEN %LET cond = &cond. and not missing(&panel.);  /* with a panel */
  %IF %LENGTH(%SUPERQ(where)) %THEN %LET cond = &cond. and &where.;        /* plus where= */

  /* Step 2: the drawing parameters: outpar= */
  %_spl_figure_outpar(names=&drawn., out=&outpar.)

  /* Step 3: with plot= its values are drawn again: an interval where LOWER has a value */
  %IF %LENGTH(&plot.) %THEN %DO;
    DATA &out.;
      SET &plot.;
      KEEP &panel. &by. kind x y lower upper;
    RUN;
    %LET bars = no;
    %IF %_spl_nobs(&out.(WHERE=(NOT MISSING(lower)))) %THEN %LET bars = yes;
    %GOTO draw;
  %END;

  /* Step 4: the values */
  DATA _lineplot_values;
    %IF %LENGTH(&chars.) %THEN %DO;
      LENGTH &chars. $200;
    %END;
    SET &data.;
    WHERE &cond.;
    _panel = 1;
    KEEP &panel. &by. &x. &y. &lower. &upper. _panel;
  RUN;

  /* Step 5: no row qualified: the figure that says so and out= without a row */
  %IF %_spl_nobs(_lineplot_values) = 0 %THEN %DO;
    %_spl_figure_nodata(
        keep   = &panel. &by.
      , macro  = lineplot
      , like   = _lineplot_values
      , chars  = kind
      , nums   = x y lower upper
      , file   = &file.
      , width  = &width.
      , height = &height.
      , out    = &out.
    )
    %GOTO finish;
  %END;

  /* Step 6: the numbers drawn: out= */
  DATA &out.;
    LENGTH kind $8;
    SET _lineplot_values;
    kind = 'line';
    x    = &x.;
    y    = &y.;
    %IF %LENGTH(&lower.) %THEN %DO;
      lower = &lower.;
      upper = &upper.;
    %END;
    %ELSE %DO;
      CALL MISSING(lower, upper);
    %END;
    KEEP &panel. &by. kind x y lower upper;
  RUN;
  PROC SORT DATA=&out.; BY &panel. &by. x; RUN;

  /* Step 7: the rows of the figure: with error bars the groups a little apart */
  %draw:
  DATA _lineplot_plot;
    SET &out.;
    _panel = 1;
    _bar   = &by.;
  RUN;
  %_spl_figure_attrs(data=_lineplot_plot, columns=&columns., var=&by., out=_lineplot_attrs)
  %IF &bars. = yes and &band. = no %THEN %DO;
    %_spl_figure_dodge(data=_lineplot_plot, x=x, offset=xoff)
  %END;
  %ELSE %DO;
    DATA _lineplot_plot;
      SET _lineplot_plot;
      _xplot = x;
    RUN;
  %END;
  PROC SORT DATA=_lineplot_plot; BY &pby. _order x; RUN;
  PROC SORT DATA=_lineplot_plot(KEEP=x) OUT=_lineplot_ticks NODUPKEY; BY x; RUN;
  DATA _NULL_;
    LENGTH _list $2000;
    SET _lineplot_ticks END=last;
    RETAIN _list;
    _list = CATX(' ', _list, x);
    IF last THEN CALL SYMPUTX('ticks', _list, 'L');
  RUN;

  /* Step 8: the figure */
  %_spl_figure_open(file=&file., width=&width., height=&height., state=listing)
  PROC SGPANEL DATA=_lineplot_plot DATTRMAP=_lineplot_attrs NOAUTOLEGEND;
    %IF %LENGTH(&panel.) %THEN %DO;
      PANELBY &pby. / NOVARNAME SPACING=10 COLUMNS=1 UNISCALE=column;
    %END;
    %ELSE %DO;
      PANELBY &pby. / NOHEADER NOVARNAME;
    %END;
    %IF &bars. = yes and &band. = yes %THEN %DO;
      BAND X=_xplot LOWER=lower UPPER=upper / GROUP=_bar ATTRID=grpcol TRANSPARENCY=0.8;
    %END;
    %ELSE %IF &bars. = yes %THEN %DO;
      HIGHLOW X=_xplot LOW=lower HIGH=upper / GROUP=_bar ATTRID=grpcol LOWCAP=serif
                                              HIGHCAP=serif;
    %END;
    SERIES X=_xplot Y=y / GROUP=&by. ATTRID=grp MARKERS NAME='line' LINEATTRS=(thickness = 1.5)
                          MARKERATTRS=(size = 8);
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
    KEYLEGEND 'line' / TITLE=' ';
  RUN;
  %_spl_figure_close(listing=&listing.)

  /* Step 9: the work data sets are deleted (kept with debug=yes) */
  %finish:
  %IF %UPCASE(&debug.) ne YES %THEN %DO;
    PROC DATASETS LIBRARY=work NOLIST NOWARN;
      DELETE _lineplot_:;
    QUIT;
  %END;
  %_spl_end(lineplot, &t0., &debug.)
%MEND lineplot;
