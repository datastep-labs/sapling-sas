/*******************************************************************************
| Macro Name    : boxplot.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.10.0
| Created By    : Sapling
| Date          : 27NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : Draws box plots of a variable in each group as PNG and RTF
|                 files and returns the numbers drawn. Use %meanplot for the
|                 mean and its error bars only. With x=, there is one box per
|                 group at each visit. The box goes from Q1 to Q3, with a line
|                 at the median and a marker at the mean. The whiskers go to the
|                 most extreme values within 1.5 times the interquartile range
|                 of the box; the values beyond them are outliers. The quantiles
|                 are those of PROC MEANS with QNTLDEF=5 and of VBOX (its
|                 default PERCENTILE=5; R quantile type 2). A record with a
|                 missing value, category, group or panel is not used. To draw
|                 the figure again without computing, give plot= the out= and
|                 par= the outpar= of an earlier call.
| Procedure     : PROC MEANS, PROC SGPANEL
| Proven        : Its known answer: the quartiles and the whiskers, worked out
|                 by hand; ran on SAS 9.4 M9, 2026-11-27 (the cases of the 9
|                 figure macros: 103 of 103 the same)
| Note          : Draw again: plot= takes the out= of an earlier %boxplot call,
|                 changed or not, and draws it as it is, with no statistic
|                 computed, each box from its statistics: the whiskers from WLOW
|                 to WHIGH, the box from Q1 to Q3 with the line of the MEDIAN,
|                 the MEAN, and as outliers only MIN and MAX when they are
|                 beyond a whisker (out= has no other value; from data= every
|                 outlier is drawn). par= takes the outpar= of that call and
|                 gives the drawing parameters: columns, by, panel, outliers,
|                 mean, xformat, xlabel, ylabel, ref, file, width, height. These
|                 change the picture, not the numbers. The other parameters
|                 compute; with plot= the log has a NOTE for each one given, as
|                 it is not used. A drawing parameter given in the call wins
|                 over its row of par=, and the row wins over the default of the
|                 table.
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| data        The input data set: one record per value            Required
| plot        Draw again: the out= of an earlier %boxplot call,   Optional
|             changed or not. It is drawn as it is, and no
|             statistic is computed. Give it instead of data=.
| par         The drawing parameters of an earlier %boxplot       Optional
|             call: its outpar=. A drawing parameter given in
|             the call wins over its row of par=.
| columns     The data set of %columns: it gives the order of     Optional
|             the groups and their colours. When not given, the
|             groups come in the order of the data.
| where       The records to use: a condition in parentheses,     Optional
|             such as where = (anl01fl = 'Y')
| y           The variable of the boxes: one numeric variable (y  Required
|             = aval)
| x           The category of the x axis: one variable, such as   Optional
|             the visit (x = avisitn). When not given, there is
|             one box per group.
| by          The groups: one variable, one box per group         Required
| panel       A variable: one panel per value, one under the      Optional
|             other, each with its own y axis (panel = paramcd)
| outliers    yes: show the values beyond the whiskers as         yes
|             markers
| mean        yes: show the mean as a marker in the box           yes
| xformat     The format of the categories of x, as in a FORMAT   Optional
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
| debug       yes: keep the work data sets _boxplot_*             no
|-------------------------------------------------------------------------------
|
| Output        : OUT: one row per box: the variables of panel= and by=, KIND
|                 (box), X (the category; missing without x=), N, MEAN, MEDIAN,
|                 Q1, Q3, MIN, MAX, WLOW and WHIGH. WLOW and WHIGH are the ends
|                 of the whiskers: the smallest and the largest value within
|                 Q1 - 1.5 IQR and Q3 + 1.5 IQR. OUTPAR: one row per drawing
|                 parameter, in the order of the table: PARAMETER ($32), its
|                 name, and VALUE ($500), its value as drawn (a label in
|                 quotes). FILE: <file>.png and <file>.rtf.
|
| Example:
|
 * Draws a box of the change of the systolic blood pressure at each visit for each group.;
 %boxplot(
     data    = advs
   , columns = t14_2_1_cols
   , where   = (paramcd = 'SYSBP' AND anl01fl = 'Y' AND avisitn IN (4 12 24))
   , y       = chg
   , x       = avisitn
   , by      = trt01a
   , xformat = VISIT.
   , ref     = 0
   , file    = &spl_out./figures/f_sbp_box
   , out     = f_sbp_box
 )
|
|-------------------------------------------------------------------------------
| Change Log :
| Date        Programmer   Description
|-------------------------------------------------------------------------------
| 12-NOV-2026 Sapling      1.3.0: initial version: replaces %plot(type=box).
| 13-NOV-2026 Sapling      1.6.0: outpar=, plot= and par=: draw again from a
|                          changed out= and outpar=. The defaults of the
|                          drawing parameters and of the computation are set in
|                          the macro (%_spl_figure_par). No number changes.
| 16-NOV-2026 Sapling      1.9.0: the license line; the example in the house
|                          case (names in lower case). No number changes.
| 27-NOV-2026 Sapling      1.10.0: the example runs on the example data
|                          (sas/examples). The text of the header for the
|                          manual: the summary, the form of each parameter. No
|                          number changes.
| 27-NOV-2026 Sapling      1.10.0: a caption for each call of the example (a
|                          comment line before it). No number changes.
| 27-NOV-2026 Sapling      1.10.0: Proven in plain words, for the published
|                          manual. No number changes.
|
*******************************************************************************/
%MACRO boxplot(
     data     =      /* The records */
   , plot     =      /* Draw again: an out= of %boxplot */
   , par      =      /* The drawing parameters: an outpar= of %boxplot */
   , columns  =      /* The columns of %columns: order and colours */
   , where    =      /* The records to use: a condition in parentheses */
   , y        =      /* The variable */
   , x        =      /* The category of the x axis (the visit) */
   , by       =      /* The groups: one box each */
   , panel    =      /* One panel per value of this variable */
   , outliers =      /* yes (default): the values beyond the whiskers as markers */
   , mean     =      /* yes (default): the mean as a marker */
   , xformat  =      /* The format of the categories of x */
   , xlabel   =      /* The label of the x axis */
   , ylabel   =      /* The label of the y axis */
   , ref      =      /* Reference lines on the y axis */
   , file     =      /* The output without its extension */
   , width    =      /* The width of the figure (6.5in) */
   , height   =      /* The height of the figure (4.5in) */
   , out      =      /* The numbers drawn */
   , outpar   =      /* The drawing parameters: one row each */
   , debug    = no   /* yes: keep the work data sets _boxplot_* */
) / DES = 'Box plots by group and visit (PROC MEANS, PROC SGPANEL)';
  %LOCAL t0 i cond chars pby listing cat dsid rc ok drawn src xvar yvar rows;
  %LET t0 = %_spl_begin(boxplot);

  /* Step 1: the parameters */
  %_spl_figure_par(
      macro   = boxplot
    , draw    = columns by panel outliers=yes mean=yes xformat xlabel ylabel ref file width=6.5in
                height=4.5in
    , compute = where y x
    , shape   = kind x n mean median q1 q3 min max wlow whigh
    , names   = drawn
    , state   = ok
  )
  %IF not &ok. %THEN %RETURN;
  %IF %LENGTH(&plot.) = 0 %THEN %DO;
    %IF not %_spl_need(boxplot, data y by file) %THEN %RETURN;
    %IF not %_spl_vars(boxplot, data, y x by panel) %THEN %RETURN;
    %IF %LENGTH(&x.) and %LENGTH(&xformat.) = 0 %THEN %DO;
      /* the format of the categories, when xformat= is not given */
      %LET dsid    = %SYSFUNC(OPEN(&data.));
      %LET xformat = %SYSFUNC(VARFMT(&dsid., %SYSFUNC(VARNUM(&dsid., &x.))));
      %LET rc      = %SYSFUNC(CLOSE(&dsid.));
    %END;
  %END;
  %ELSE %DO;
    %IF not %_spl_need(boxplot, by file) %THEN %RETURN;
    %IF not %_spl_vars(boxplot, plot, by panel) %THEN %RETURN;
  %END;
  %IF %LENGTH(&columns.) %THEN %DO;
    %IF not %_spl_need(boxplot, columns) %THEN %RETURN;
  %END;
  %IF not %_spl_oneof(boxplot, outliers, yes no) %THEN %RETURN;
  %IF not %_spl_oneof(boxplot, mean, yes no) %THEN %RETURN;
  %IF not %_spl_oneof(boxplot, debug, yes no) %THEN %RETURN;

  %LET by    = %UPCASE(&by.);                            /* the groups, in upper case */
  %LET panel = %UPCASE(&panel.);                         /* the panels, in upper case */
  %LET src   = &data.&plot.;                             /* the data set read */
  %LET xvar  = &x.;                                      /* the category of a box */
  %LET yvar  = &y.;                                      /* the variable of the y axis */
  %LET rows  = _boxplot_records;                         /* the rows of the figure */
  %IF %LENGTH(&plot.) %THEN %LET yvar = median;           /* with plot=: a statistic */
  %IF %LENGTH(&plot.) %THEN %LET rows = _boxplot_boxes;   /* with plot=: the boxes */
  %IF %LENGTH(&plot.) %THEN %LET xvar = x;               /* with plot=: its X */
  /* with plot=: no category when X has no value */
  %IF %LENGTH(&plot.) %THEN %IF %_spl_nobs(&plot.(WHERE=(NOT MISSING(x)))) = 0 %THEN %LET xvar = ;
  %LET chars  = %_spl_chars(&src., &by. &panel. &xvar.);  /* the character variables */
  %LET xlabel = %_spl_figure_label(&src., &xvar., %SUPERQ(xlabel));  /* the x axis */
  %LET ylabel = %_spl_figure_label(&src., &yvar., %SUPERQ(ylabel));  /* the y axis */
  %LET pby    = _panel;                                   /* the PANELBY variable */
  %IF %LENGTH(&panel.) %THEN %LET pby = &panel.;  /* with panel=: the panel variable */
  %LET cat = &xvar.;                                   /* the category of a box */
  %IF %LENGTH(&xvar.) = 0 %THEN %LET cat = &by.;  /* without x=: the groups */
  %IF %LENGTH(&out.) = 0 %THEN %LET out = _boxplot_out;   /* out= not asked: not kept */
  %LET cond = not missing(&y.) and not missing(&by.);  /* the records that count */
  %IF %LENGTH(&x.) %THEN %LET cond = &cond. and not missing(&x.);          /* with a category */
  %IF %LENGTH(&panel.) %THEN %LET cond = &cond. and not missing(&panel.);  /* with a panel */
  %IF %LENGTH(%SUPERQ(where)) %THEN %LET cond = &cond. and &where.;        /* plus where= */

  /* Step 2: the drawing parameters: outpar= */
  %_spl_figure_outpar(names=&drawn., out=&outpar.)

  /* Step 3: with plot= its boxes are drawn again; the outliers MIN and MAX beyond a whisker */
  %IF %LENGTH(&plot.) %THEN %DO;
    DATA &out.;
      SET &plot.;
      KEEP &panel. &by. kind x n mean median q1 q3 min max wlow whigh;
    RUN;
    DATA _boxplot_boxes;
      SET &out.;
      _panel = 1;
      _lo    = IFN(min < wlow, min, .);
      _hi    = IFN(max > whigh, max, .);
    RUN;
    %GOTO draw;
  %END;

  /* Step 4: the records */
  DATA _boxplot_records;
    %IF %LENGTH(&chars.) %THEN %DO;
      LENGTH &chars. $200;
    %END;
    SET &data.;
    WHERE &cond.;
    _panel = 1;
    KEEP &panel. &by. &x. &y. _panel;
  RUN;

  /* Step 5: no record qualified: the figure that says so and out= without a row */
  %IF %_spl_nobs(_boxplot_records) = 0 %THEN %DO;
    %_spl_figure_nodata(
        keep   = &panel. &by.
      , macro  = boxplot
      , like   = _boxplot_records
      , chars  = kind
      , nums   = x n mean median q1 q3 min max wlow whigh
      , file   = &file.
      , width  = &width.
      , height = &height.
      , out    = &out.
    )
    %GOTO finish;
  %END;

  /* Step 6: the statistics of each box */
  PROC MEANS DATA=_boxplot_records NOPRINT NWAY QNTLDEF=5;
    CLASS &panel. &x. &by.;
    VAR &y.;
    OUTPUT OUT=_boxplot_stats(DROP=_TYPE_ _FREQ_) N=n MEAN=mean MEDIAN=median Q1=q1 Q3=q3
           MIN=min MAX=max;
  RUN;

  /* Step 7: the ends of the whiskers: the values within 1.5 IQR of the box */
  PROC SORT DATA=_boxplot_records; BY &panel. &x. &by.; RUN;
  DATA _boxplot_inner;
    MERGE _boxplot_records _boxplot_stats(KEEP=&panel. &x. &by. q1 q3);
    BY &panel. &x. &by.;
    IF q1 - 1.5 * (q3 - q1) - 1E-9 <= &y. <= q3 + 1.5 * (q3 - q1) + 1E-9;
  RUN;
  PROC MEANS DATA=_boxplot_inner NOPRINT NWAY;
    CLASS &panel. &x. &by.;
    VAR &y.;
    OUTPUT OUT=_boxplot_whisk(DROP=_TYPE_ _FREQ_) MIN=wlow MAX=whigh;
  RUN;

  /* Step 8: the numbers drawn: out= */
  DATA &out.;
    LENGTH kind $8;
    MERGE _boxplot_stats _boxplot_whisk;
    BY &panel. &x. &by.;
    kind = 'box';
    %IF %LENGTH(&x.) %THEN %DO;
      x = &x.;
    %END;
    %ELSE %DO;
      x = .;
    %END;
    KEEP &panel. &by. kind x n mean median q1 q3 min max wlow whigh;
  RUN;

  /* Step 9: the rows of the figure: the records (with plot= the boxes), the groups in order */
  %draw:
  %_spl_figure_attrs(data=&rows., columns=&columns., var=&by., out=_boxplot_attrs)
  PROC SORT DATA=&rows.; BY &pby. _order &xvar.; RUN;

  /* Step 10: the figure */
  %_spl_figure_open(file=&file., width=&width., height=&height., state=listing)
  PROC SGPANEL DATA=&rows. DATTRMAP=_boxplot_attrs NOAUTOLEGEND;
    %IF %LENGTH(&panel.) %THEN %DO;
      PANELBY &pby. / NOVARNAME SPACING=10 COLUMNS=1 UNISCALE=column;
    %END;
    %ELSE %DO;
      PANELBY &pby. / NOHEADER NOVARNAME;
    %END;
    %IF %LENGTH(&plot.) = 0 %THEN %DO;
      VBOX &y. / CATEGORY=&cat. GROUP=&by. ATTRID=grpcol GROUPDISPLAY=cluster GROUPORDER=data
                 NAME='box'
                 FILLATTRS=(transparency = 0.6) MEDIANATTRS=(thickness = 2)
                 MEANATTRS=(symbol = diamondfilled size = 9)
                 OUTLIERATTRS=(symbol = circle size = 7)
      %IF &outliers. = no %THEN NOOUTLIERS;
      %IF &mean. = no %THEN NOMEAN;
      ;
    %END;
    %ELSE %DO;
      /* the box of plot=: the two whiskers, the box Q1 to Q3, the line of the median */
      HIGHLOW X=&cat. LOW=wlow HIGH=q1 / GROUP=&by. ATTRID=grpcol GROUPDISPLAY=cluster
                                         GROUPORDER=data CLUSTERWIDTH=0.7 LOWCAP=serif;
      HIGHLOW X=&cat. LOW=q3 HIGH=whigh / GROUP=&by. ATTRID=grpcol GROUPDISPLAY=cluster
                                          GROUPORDER=data CLUSTERWIDTH=0.7 HIGHCAP=serif;
      HIGHLOW X=&cat. LOW=q1 HIGH=q3 / TYPE=bar GROUP=&by. ATTRID=grpcol NAME='box'
                                       GROUPDISPLAY=cluster GROUPORDER=data CLUSTERWIDTH=0.7
                                       BARWIDTH=0.6 FILLATTRS=(transparency = 0.6);
      HIGHLOW X=&cat. LOW=median HIGH=median / TYPE=bar GROUP=&by. ATTRID=grpcol NOFILL
                                               GROUPDISPLAY=cluster GROUPORDER=data
                                               CLUSTERWIDTH=0.7 BARWIDTH=0.6
                                               LINEATTRS=(thickness = 2);
      %IF &mean. = yes %THEN %DO;
        SCATTER X=&cat. Y=mean / GROUP=&by. ATTRID=grpcol GROUPDISPLAY=cluster GROUPORDER=data
                                 CLUSTERWIDTH=0.7 MARKERATTRS=(symbol = diamondfilled size = 9);
      %END;
      %IF &outliers. = yes and %_spl_nobs(&rows.(WHERE=(NOT MISSING(_lo)))) %THEN %DO;
        SCATTER X=&cat. Y=_lo / GROUP=&by. ATTRID=grpcol GROUPDISPLAY=cluster GROUPORDER=data
                                CLUSTERWIDTH=0.7 MARKERATTRS=(symbol = circle size = 7);
      %END;
      %IF &outliers. = yes and %_spl_nobs(&rows.(WHERE=(NOT MISSING(_hi)))) %THEN %DO;
        SCATTER X=&cat. Y=_hi / GROUP=&by. ATTRID=grpcol GROUPDISPLAY=cluster GROUPORDER=data
                                CLUSTERWIDTH=0.7 MARKERATTRS=(symbol = circle size = 7);
      %END;
    %END;
    %DO i = 1 %TO %SYSFUNC(COUNTW(&ref.%STR( ), %STR( )));
      REFLINE %SCAN(&ref., &i., %STR( )) / AXIS=y LINEATTRS=(pattern = dash color = gray);
    %END;
    %IF %LENGTH(&xformat.) %THEN %DO;
      FORMAT &xvar. &xformat.;
    %END;
    ROWAXIS LABEL=&ylabel. grid;
    %IF %LENGTH(&xvar.) %THEN %DO;
      COLAXIS TYPE=discrete LABEL=&xlabel.;
    %END;
    %ELSE %DO;
      COLAXIS TYPE=discrete DISPLAY=(nolabel) DISCRETEORDER=data;
    %END;
    KEYLEGEND 'box' / TITLE=' ';
  RUN;
  %_spl_figure_close(listing=&listing.)

  /* Step 11: the work data sets are deleted (kept with debug=yes) */
  %finish:
  %IF %UPCASE(&debug.) ne YES %THEN %DO;
    PROC DATASETS LIBRARY=work NOLIST NOWARN;
      DELETE _boxplot_:;
    QUIT;
  %END;
  %_spl_end(boxplot, &t0., &debug.)
%MEND boxplot;
