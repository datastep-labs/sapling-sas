/*******************************************************************************
| Macro Name    : scatterplot.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.9.1
| Created By    : Sapling
| Date          : 16NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : The values of two variables against each other (a shift plot of
|                 baseline and post baseline values, two measures of a subject),
|                 one colour and marker per group; with fit=linear the least
|                 squares line of each group (its slope, intercept and R-square
|                 in out=), with fit=loess the loess curve of SGPLOT (its
|                 smoothing chosen by SGPLOT, not in out=); identity=yes the
|                 line y = x. One panel per value of panel=.
| Procedure     : PROC REG, PROC SGPANEL
| Proven        : its known answer in tools/figures_sas.ts (the points, and the
|                 slope, intercept and R-square worked out by hand); not yet run
|                 on a SAS server
| Note          : Draw again: plot= (an out= of %scatterplot, changed or not) is
|                 drawn as it is: its points, and the line of each row of KIND
|                 fit over the X of the points of its group (a loess curve is
|                 not in out= and is not drawn again); par= (an outpar= of
|                 %scatterplot) gives the drawing parameters: columns, by,
|                 panel, identity, xlabel, ylabel, ref, file, width, height.
|                 They change the picture, not the numbers; the others compute,
|                 and with plot= a NOTE says each one given is not used. A
|                 drawing parameter given in the call wins over its row of par=,
|                 the row over the default of the table.
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| data        The records                                         Required
| plot        Draw again: an out= of %scatterplot, not with       Optional
|             data=
| par         The drawing parameters: an outpar= of %scatterplot  Optional
| columns     The columns of %columns: the order of the groups    Optional
|             and their colours (default: the order of the data)
| where       The records to use, a condition in parentheses      Optional
| x           The variable of the x axis (BASE)                   Required
| y           The variable of the y axis (AVAL)                   Required
| by          The groups: one colour and marker each              Required
| panel       One panel per value of this variable                Optional
| fit         none, linear (a line per group) or loess            none
| identity    yes: the line y = x                                 no
| xlabel      The label of the x axis (default: the label of x)   Optional
| ylabel      The label of the y axis (default: the label of y)   Optional
| ref         Reference lines on the y axis: values               Optional
| file        The output without its extension: <file>.png (300   Required
|             dpi) and <file>.rtf
| width       The width of the figure                             6.5in
| height      The height of the figure                            4.5in
| out         The numbers drawn                                   Optional
| outpar      The drawing parameters: one row each                Optional
| debug       yes: keep the work data sets _scatterplot_*         no
|-------------------------------------------------------------------------------
|
| Output        : OUT: PANEL and BY, KIND, X, Y; KIND point: one row per value;
|                 with fit=linear KIND fit: one row per group with SLOPE,
|                 INTERCEPT, RSQUARE and N (X and Y missing). OUTPAR: one row
|                 per drawing parameter in the order of the table: PARAMETER
|                 ($32) its name, VALUE ($500) its value as drawn (a label in
|                 quotes). FILE: <file>.png and <file>.rtf.
|
| Example:
|
 %scatterplot(
     data     = adlbc
   , columns  = t14_6_cols
   , where    = (paramcd = 'ALT' AND avisitn = 24)
   , x        = base
   , y        = aval
   , by       = trta
   , identity = yes
   , file     = &spl_out./figures/f14_6_2
   , out      = f14_6_2
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
| 13-NOV-2026 Sapling      1.7.1: the line of identity=yes does not stretch the
|                          axes (CLIP).
| 16-NOV-2026 Sapling      1.9.0: fit=none or loess: no NOTE that the variable
|                          _EDF_ is uninitialized (it was read without a fitted
|                          line). The license line; the example in the house
|                          case. No number changes.
| 16-NOV-2026 Sapling      1.9.1: one PROC REG for each group, without BY: no
|                          note Interactivity disabled (DEV-020). No number
|                          changes.
|
*******************************************************************************/
%MACRO scatterplot(
     data     =      /* The records */
   , plot     =      /* Draw again: an out= of %scatterplot */
   , par      =      /* The drawing parameters: an outpar= of %scatterplot */
   , columns  =      /* The columns of %columns: order and colours */
   , where    =      /* The records to use: a condition in parentheses */
   , x        =      /* The variable of the x axis */
   , y        =      /* The variable of the y axis */
   , by       =      /* The groups: one colour and marker each */
   , panel    =      /* One panel per value of this variable */
   , fit      =      /* none (default), linear or loess */
   , identity =      /* yes: the line y = x (default no) */
   , xlabel   =      /* The label of the x axis */
   , ylabel   =      /* The label of the y axis */
   , ref      =      /* Reference lines on the y axis */
   , file     =      /* The output without its extension */
   , width    =      /* The width of the figure (6.5in) */
   , height   =      /* The height of the figure (4.5in) */
   , out      =      /* The numbers drawn */
   , outpar   =      /* The drawing parameters: one row each */
   , debug    = no   /* yes: keep the work data sets _scatterplot_* */
) / DES = 'Two variables against each other by group (PROC REG, PROC SGPANEL)';
  %LOCAL t0 i cond chars pby listing ok drawn src xvar yvar ngrp lastby;
  %LET t0 = %_spl_begin(scatterplot);

  /* Step 1: the parameters */
  %_spl_figure_par(
      macro   = scatterplot
    , draw    = columns by panel identity=no xlabel ylabel ref file width=6.5in height=4.5in
    , compute = where x y fit=none
    , shape   = kind x y slope intercept rsquare n
    , names   = drawn
    , state   = ok
  )
  %IF not &ok. %THEN %RETURN;
  %IF %LENGTH(&plot.) = 0 %THEN %DO;
    %IF not %_spl_need(scatterplot, data x y by file) %THEN %RETURN;
    %IF not %_spl_vars(scatterplot, data, x y by panel) %THEN %RETURN;
    %IF not %_spl_oneof(scatterplot, fit, none linear loess) %THEN %RETURN;
  %END;
  %ELSE %DO;
    %IF not %_spl_need(scatterplot, by file) %THEN %RETURN;
    %IF not %_spl_vars(scatterplot, plot, by panel) %THEN %RETURN;
  %END;
  %IF not %_spl_oneof(scatterplot, identity, yes no) %THEN %RETURN;
  %IF not %_spl_oneof(scatterplot, debug, yes no) %THEN %RETURN;
  %IF %LENGTH(&columns.) %THEN %DO;
    %IF not %_spl_need(scatterplot, columns) %THEN %RETURN;
  %END;

  %LET fit   = %LOWCASE(&fit.);                          /* the fit */
  %LET by    = %UPCASE(&by.);                            /* the groups, in upper case */
  %LET panel = %UPCASE(&panel.);                         /* the panels, in upper case */
  %LET src   = &data.&plot.;                             /* the data set read */
  %LET xvar  = &x.;                                      /* the variable of the x axis */
  %LET yvar  = &y.;                                      /* the variable of the y axis */
  %IF %LENGTH(&plot.) %THEN %LET xvar = x;                /* with plot=: its X */
  %IF %LENGTH(&plot.) %THEN %LET yvar = y;                /* with plot=: its Y */
  %LET chars  = %_spl_chars(&src., &by. &panel.);         /* the character variables */
  %LET xlabel = %_spl_figure_label(&src., &xvar., %SUPERQ(xlabel));  /* the x axis */
  %LET ylabel = %_spl_figure_label(&src., &yvar., %SUPERQ(ylabel));  /* the y axis */
  %LET pby    = _panel;                                   /* the PANELBY variable */
  %IF %LENGTH(&panel.) %THEN %LET pby = &panel.;  /* with panel=: the panel variable */
  %IF %LENGTH(&out.) = 0 %THEN %LET out = _scatterplot_out;  /* out= not asked: not kept */
  /* the records that count */
  %LET cond = not missing(&x.) and not missing(&y.) and not missing(&by.);
  %IF %LENGTH(&panel.) %THEN %LET cond = &cond. and not missing(&panel.);  /* with a panel */
  %IF %LENGTH(%SUPERQ(where)) %THEN %LET cond = &cond. and &where.;        /* plus where= */

  /* Step 2: the drawing parameters: outpar= */
  %_spl_figure_outpar(names=&drawn., out=&outpar.)

  /* Step 3: with plot= its points are drawn again, a line for each row of KIND fit */
  %IF %LENGTH(&plot.) %THEN %DO;
    DATA &out.;
      SET &plot.;
      KEEP &panel. &by. kind x y slope intercept rsquare n;
    RUN;
    PROC SORT DATA=&out.; BY &panel. &by. kind x y; RUN;
    %LET fit = none;
    %IF %_spl_nobs(&out.(WHERE=(kind = 'fit'))) %THEN %LET fit = linear;
    %GOTO draw;
  %END;

  /* Step 4: the records */
  DATA _scatterplot_records;
    %IF %LENGTH(&chars.) %THEN %DO;
      LENGTH &chars. $200;
    %END;
    SET &data.;
    WHERE &cond.;
    KEEP &panel. &by. &x. &y.;
  RUN;

  /* Step 5: no record qualified: the figure that says so and out= without a row */
  %IF %_spl_nobs(_scatterplot_records) = 0 %THEN %DO;
    %_spl_figure_nodata(
        keep   = &panel. &by.
      , macro  = scatterplot
      , like   = _scatterplot_records
      , chars  = kind
      , nums   = x y slope intercept rsquare n
      , file   = &file.
      , width  = &width.
      , height = &height.
      , out    = &out.
    )
    %GOTO finish;
  %END;

  /* Step 6: the least squares line of each group */
  PROC SORT DATA=_scatterplot_records; BY &panel. &by.; RUN;
  %IF &fit. = linear %THEN %DO;
    /* one fit per group, without BY: PROC REG with BY writes the note Interactivity disabled */
    %LET lastby = %SCAN(&panel. &by., -1, %STR( ));  /* the last variable of the groups */
    DATA _scatterplot_groups;
      SET _scatterplot_records(KEEP=&panel. &by.);
      BY &panel. &by.;
      IF first.&lastby.;
    RUN;
    %LET ngrp = %_spl_nobs(_scatterplot_groups);  /* the number of groups */
    DATA _scatterplot_records;
      SET _scatterplot_records;
      BY &panel. &by.;
      IF first.&lastby. THEN _g + 1;
    RUN;
    %DO i = 1 %TO &ngrp.;
      PROC REG DATA=_scatterplot_records(WHERE=(_g = &i.)) OUTEST=_scatterplot_e&i. RSQUARE EDF
               NOPRINT;
        MODEL &y. = &x.;
      RUN;
      QUIT;
    %END;
    /* the fits in the order of the groups, each beside its group */
    DATA _scatterplot_est;
      SET _scatterplot_e1-_scatterplot_e&ngrp.;
    RUN;
    DATA _scatterplot_est;
      MERGE _scatterplot_groups _scatterplot_est;
    RUN;
  %END;

  /* Step 7: the numbers drawn: out= */
  DATA &out.;
    LENGTH kind $8;
    SET _scatterplot_records(IN=inpoint)
    %IF &fit. = linear %THEN %DO;
      _scatterplot_est(keep = &panel. &by. intercept &x. _rsq_ _edf_
                       rename = (&x. = slope _rsq_ = rsquare))
    %END;
    ;
    IF inpoint THEN DO;
      kind = 'point';
      x    = &x.;
      y    = &y.;
      CALL MISSING(slope, intercept, rsquare, n);
    END;
    %IF &fit. = linear %THEN %DO;
      ELSE DO;
        kind = 'fit';
        n    = _edf_ + 2;
        CALL MISSING(x, y);
      END;
    %END;
    KEEP &panel. &by. kind x y slope intercept rsquare n;
  RUN;
  PROC SORT DATA=&out.; BY &panel. &by. kind x y; RUN;

  /* Step 8: the rows of the figure: the points, and the line of each group over its x */
  %draw:
  DATA _scatterplot_plot;
    SET &out.;
    _panel = 1;
    _fby   = &by.;
    CALL MISSING(_fx, _fy);
  RUN;
  %IF &fit. = linear %THEN %DO;
    PROC MEANS DATA=&out.(WHERE=(kind = 'point')) NOPRINT NWAY;
      CLASS &panel. &by.;
      VAR x;
      OUTPUT OUT=_scatterplot_range(DROP=_TYPE_ _FREQ_) MIN=_xmin MAX=_xmax;
    RUN;
    DATA _scatterplot_plot;
      MERGE _scatterplot_plot _scatterplot_range;
      BY &panel. &by.;
      IF kind = 'fit' THEN DO;
        _fx = _xmin;
        _fy = intercept + slope * _fx;
        OUTPUT;
        _fx = _xmax;
        _fy = intercept + slope * _fx;
      END;
      OUTPUT;
      DROP _xmin _xmax;
    RUN;
  %END;
  %_spl_figure_attrs(data=_scatterplot_plot, columns=&columns., var=&by., out=_scatterplot_attrs)
  PROC SORT DATA=_scatterplot_plot; BY &pby. _order kind _fx; RUN;

  /* Step 9: the figure */
  %_spl_figure_open(file=&file., width=&width., height=&height., state=listing)
  PROC SGPANEL DATA=_scatterplot_plot DATTRMAP=_scatterplot_attrs NOAUTOLEGEND;
    %IF %LENGTH(&panel.) %THEN %DO;
      PANELBY &pby. / NOVARNAME SPACING=10;
    %END;
    %ELSE %DO;
      PANELBY &pby. / NOHEADER NOVARNAME;
    %END;
    %IF &identity. = yes %THEN %DO;
      LINEPARM X=0 Y=0 SLOPE=1 / CLIP LINEATTRS=(pattern = solid color = lightgray thickness = 2);
    %END;
    SCATTER X=x Y=y / GROUP=&by. ATTRID=grp NAME='point' MARKERATTRS=(size = 8);
    %IF &fit. = linear %THEN %DO;
      SERIES X=_fx Y=_fy / GROUP=_fby ATTRID=grp LINEATTRS=(thickness = 1.5);
    %END;
    %ELSE %IF &fit. = loess %THEN %DO;
      LOESS X=x Y=y / GROUP=_fby ATTRID=grp NOMARKERS LINEATTRS=(thickness = 1.5);
    %END;
    %DO i = 1 %TO %SYSFUNC(COUNTW(&ref.%STR( ), %STR( )));
      REFLINE %SCAN(&ref., &i., %STR( )) / AXIS=y LINEATTRS=(pattern = dash color = gray);
    %END;
    ROWAXIS LABEL=&ylabel. grid;
    COLAXIS LABEL=&xlabel. grid;
    KEYLEGEND 'point' / TITLE=' ';
  RUN;
  %_spl_figure_close(listing=&listing.)

  /* Step 10: the work data sets are deleted (kept with debug=yes) */
  %finish:
  %IF %UPCASE(&debug.) ne YES %THEN %DO;
    PROC DATASETS LIBRARY=work NOLIST NOWARN;
      DELETE _scatterplot_:;
    QUIT;
  %END;
  %_spl_end(scatterplot, &t0., &debug.)
%MEND scatterplot;
