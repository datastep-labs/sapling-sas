/*******************************************************************************
| Macro Name    : lineplot.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.9.1
| Created By    : Sapling
| Date          : 16NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : Lines through values given (the LS means of %lsmeans or %mmrm
|                 by visit, a rate by month): one line per group, with the
|                 interval of lower= and upper= as error bars (the groups a
|                 little apart on the x axis) or as a band. Nothing is computed:
|                 the figure draws the values of data=. One panel per value of
|                 panel=.
| Procedure     : PROC SGPANEL
| Proven        : its known answer in tools/figures_sas.ts (the values given);
|                 not yet run on a SAS server
| Note          : Draw again: plot= (an out= of %lineplot, changed or not) is
|                 drawn as it is (an interval where LOWER has a value), and par=
|                 (an outpar= of %lineplot) gives the drawing parameters:
|                 columns, by, panel, band, xformat, xlabel, ylabel, ref, file,
|                 width, height. They change the picture, not the numbers; the
|                 others choose the values, and with plot= a NOTE says each one
|                 given is not used. A drawing parameter given in the call wins
|                 over its row of par=, the row over the default of the table.
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| data        The values: one row per group and x                 Required
| plot        Draw again: an out= of %lineplot (not with data=)   Optional
| par         The drawing parameters: an outpar= of %lineplot     Optional
| columns     The columns of %columns: the order of the groups    Optional
|             and their colours (default: the order of the data)
| where       The rows to use, a condition in parentheses         Optional
| x           The x: a numeric variable (AVISITN)                 Required
| y           The value                                           Required
| by          The groups: one line each                           Required
| panel       One panel per value of this variable,               Optional
|             one under the other, each with its own y axis
| lower       The lower end of the interval: a variable           Optional
| upper       The upper end of the interval: a variable           Optional
| band        yes: the interval as a band; no: as error bars      no
| xformat     The format of the ticks of x (default: the format   Optional
|             of x)
| xlabel      The label of the x axis (default: the label of x)   Optional
| ylabel      The label of the y axis (default: the label of y)   Optional
| ref         Reference lines on the y axis: values               Optional
| file        The output without its extension: <file>.png (300   Required
|             dpi) and <file>.rtf
| width       The width of the figure                             6.5in
| height      The height of the figure                            4.5in
| out         The numbers drawn                                   Optional
| outpar      The drawing parameters: one row each                Optional
| debug       yes: keep the work data sets _lineplot_*            no
|-------------------------------------------------------------------------------
|
| Output        : OUT: one row per panel, group and x: PANEL and BY, KIND line,
|                 X, Y, LOWER, UPPER. OUTPAR: one row per drawing parameter in
|                 the order of the table: PARAMETER ($32) its name, VALUE ($500)
|                 its value as drawn (a label in quotes). FILE: <file>.png and
|                 <file>.rtf.
|
| Example:
|
 %lineplot(
     data    = lsm_chg
   , columns = t14_3_1_cols
   , x       = avisitn
   , y       = estimate
   , by      = trtp
   , lower   = lcl
   , upper   = ucl
   , xformat = VISIT.
   , ylabel  = "LS mean change from baseline (95% CI)"
   , ref     = 0
   , file    = &spl_out./figures/f14_3_2
   , out     = f14_3_2
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
