/*******************************************************************************
| Macro Name    : boxplot.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.9.1
| Created By    : Sapling
| Date          : 16NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : Box plots of a variable in each group (and at each visit of
|                 x=): the box from Q1 to Q3 with the median, the whiskers to the
|                 most extreme values within 1.5 times the interquartile range
|                 of the box, the values beyond as outliers, the mean as a
|                 marker. The quantiles are those of PROC MEANS QNTLDEF=5 and of
|                 VBOX (its default PERCENTILE=5; R quantile type 2). One panel
|                 per value of panel=.
| Procedure     : PROC MEANS, PROC SGPANEL
| Proven        : its known answer in tools/figures_sas.ts (quartiles and
|                 whiskers worked out by hand); not yet run on a SAS server
| Note          : Draw again: plot= (an out= of %boxplot, changed or not) is
|                 drawn as it is, each box from its statistics: the whiskers
|                 WLOW to WHIGH, the box Q1 to Q3 with the line of the MEDIAN,
|                 the MEAN, and as outliers only MIN and MAX when beyond a
|                 whisker (out= has no other value; from data= every outlier is
|                 drawn). par= (an outpar= of %boxplot) gives the drawing
|                 parameters: columns, by, panel, outliers, mean, xformat,
|                 xlabel, ylabel, ref, file, width, height. They change the
|                 picture, not the numbers; the others compute, and with plot= a
|                 NOTE says each one given is not used. A drawing parameter
|                 given in the call wins over its row of par=, the row over the
|                 default of the table.
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| data        The records                                         Required
| plot        Draw again: an out= of %boxplot (not with data=)    Optional
| par         The drawing parameters: an outpar= of %boxplot      Optional
| columns     The columns of %columns: the order of the groups    Optional
|             and their colours (default: the order of the data)
| where       The records to use, a condition in parentheses      Optional
| y           The variable                                        Required
| x           The category of the x axis (the visit, AVISITN)     Optional
|             (default: one box per group)
| by          The groups: one box each                            Required
| panel       One panel per value of this variable,               Optional
|             one under the other, each with its own y axis
| outliers    yes: the values beyond the whiskers as markers      yes
| mean        yes: the mean as a marker in the box                yes
| xformat     The format of the categories of x (default: the     Optional
|             format of x)
| xlabel      The label of the x axis (default: the label of x)   Optional
| ylabel      The label of the y axis (default: the label of y)   Optional
| ref         Reference lines on the y axis: values               Optional
| file        The output without its extension: <file>.png (300   Required
|             dpi) and <file>.rtf
| width       The width of the figure                             6.5in
| height      The height of the figure                            4.5in
| out         The numbers drawn                                   Optional
| outpar      The drawing parameters: one row each                Optional
| debug       yes: keep the work data sets _boxplot_*             no
|-------------------------------------------------------------------------------
|
| Output        : OUT: one row per box: PANEL, BY, KIND box, X (the category;
|                 missing without x=), N, MEAN, MEDIAN, Q1, Q3, MIN, MAX, WLOW
|                 and WHIGH (the ends of the whiskers: the smallest and the
|                 largest value within Q1 - 1.5 IQR and Q3 + 1.5 IQR). OUTPAR:
|                 one row per drawing parameter in the order of the table:
|                 PARAMETER ($32) its name, VALUE ($500) its value as drawn (a
|                 label in quotes). FILE: <file>.png and <file>.rtf.
|
| Example:
|
 %boxplot(
     data    = advs
   , columns = t14_3_1_cols
   , where   = (paramcd = 'SYSBP' AND anl01fl = 'Y')
   , y       = chg
   , x       = avisitn
   , by      = trta
   , xformat = VISIT.
   , ref     = 0
   , file    = &spl_out./figures/f14_3_1
   , out     = f14_3_1
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
