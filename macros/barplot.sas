/*******************************************************************************
| Macro Name    : barplot.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.9.1
| Created By    : Sapling
| Date          : 16NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : Bars of the categories of a variable in each group: the percent
|                 of the subjects of the group (denom=: the subjects of the
|                 population; a subject counts once in a category) or of its
|                 records, or the count; the groups side by side or stacked,
|                 the value on each bar. One panel per value of panel=.
| Procedure     : PROC FREQ, PROC SGPANEL
| Proven        : its known answer in tools/figures_sas.ts (counts and percents
|                 worked out by hand); not yet run on a SAS server
| Note          : Draw again: plot= (an out= of %barplot, changed or not) is
|                 drawn as it is, the categories in the order of their first
|                 row, a value on a bar with one decimal unless every Y is its N
|                 (a count); par= (an outpar= of %barplot) gives the drawing
|                 parameters: columns, by, panel, stacked, labels, xlabel,
|                 ylabel, ref, file, width, height. They change the picture, not
|                 the numbers; the others compute, and with plot= a NOTE says
|                 each one given is not used. A drawing parameter given in the
|                 call wins over its row of par=, the row over the default of
|                 the table.
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| data        The records                                         Required
| plot        Draw again: an out= of %barplot (not with data=)    Optional
| par         The drawing parameters: an outpar= of %barplot      Optional
| columns     The columns of %columns: the order of the groups    Optional
|             and their colours (default: the order of the data)
| denom       The population: one row per subject (USUBJID) with  Optional
|             by=; its subjects of a group are the N of the
|             percent (default: the records of the group)
| where       The records to use, a condition in parentheses      Optional
| var         The category                                        Required
| by          The groups: one colour each                         Required
| panel       One panel per value of this variable                Optional
| stat        percent or count                                    percent
| stacked     yes: the groups stacked in one bar                  no
| labels      yes: the value on each bar                          yes
| xlabel      The label of the x axis (default: the label of      Optional
|             var=)
| ylabel      The label of the y axis (default: Subjects (%),     Optional
|             Records (%), Subjects or Records)
| ref         Reference lines on the y axis: values               Optional
| file        The output without its extension: <file>.png (300   Required
|             dpi) and <file>.rtf
| width       The width of the figure                             6.5in
| height      The height of the figure                            4.5in
| out         The numbers drawn                                   Optional
| outpar      The drawing parameters: one row each                Optional
| debug       yes: keep the work data sets _barplot_*             no
|-------------------------------------------------------------------------------
|
| Output        : OUT: one row per bar: PANEL and BY, KIND bar, X (the category
|                 as printed), Y (the percent or the count), N (the subjects or
|                 records of the bar), DENOM (the N of the percent). A category
|                 without a record in a group has no bar. OUTPAR: one row per
|                 drawing parameter in the order of the table: PARAMETER ($32)
|                 its name, VALUE ($500) its value as drawn (a label in quotes).
|                 FILE: <file>.png and <file>.rtf.
|
| Example:
|
 %barplot(
     data    = adae
   , columns = t14_5_1_cols
   , denom   = adsl
   , where   = (trtemfl = 'Y')
   , var     = aesev
   , by      = trta
   , file    = &spl_out./figures/f14_5_2
   , out     = f14_5_2
 )
|
|-------------------------------------------------------------------------------
| Change Log :
| Date        Programmer   Description
|-------------------------------------------------------------------------------
| 12-NOV-2026 Sapling      1.3.0: initial version: replaces %plot(type=bar).
| 13-NOV-2026 Sapling      1.6.0: outpar=, plot= and par=: draw again from a
|                          changed out= and outpar=. The defaults of the
|                          drawing parameters and of the computation are set in
|                          the macro (%_spl_figure_par). No number changes.
| 16-NOV-2026 Sapling      1.9.0: the license line; the example in the house
|                          case (names in lower case). No number changes.
|
*******************************************************************************/
%MACRO barplot(
     data    =      /* The records */
   , plot    =      /* Draw again: an out= of %barplot */
   , par     =      /* The drawing parameters: an outpar= of %barplot */
   , columns =      /* The columns of %columns: order and colours */
   , denom   =      /* The population: the N of the percent */
   , where   =      /* The records to use: a condition in parentheses */
   , var     =      /* The category */
   , by      =      /* The groups: one colour each */
   , panel   =      /* One panel per value of this variable */
   , stat    =      /* percent (default) or count */
   , stacked =      /* yes: the groups stacked in one bar (default no) */
   , labels  =      /* yes (default): the value on each bar */
   , xlabel  =      /* The label of the x axis */
   , ylabel  =      /* The label of the y axis */
   , ref     =      /* Reference lines on the y axis */
   , file    =      /* The output without its extension */
   , width   =      /* The width of the figure (6.5in) */
   , height  =      /* The height of the figure (4.5in) */
   , out     =      /* The numbers drawn */
   , outpar  =      /* The drawing parameters: one row each */
   , debug   = no   /* yes: keep the work data sets _barplot_* */
) / DES = 'Bars of the categories of a variable in each group (PROC FREQ, PROC SGPANEL)';
  %LOCAL t0 i cond chars pby listing tables nkeys who ok drawn src xvar xorder;
  %LET t0 = %_spl_begin(barplot);

  /* Step 1: the parameters */
  %_spl_figure_par(
      macro   = barplot
    , draw    = columns by panel stacked=no labels=yes xlabel ylabel ref file width=6.5in
                height=4.5in
    , compute = denom where var stat=percent
    , shape   = kind x y n denom
    , names   = drawn
    , state   = ok
  )
  %IF not &ok. %THEN %RETURN;
  %IF %LENGTH(&plot.) = 0 %THEN %DO;
    %IF not %_spl_need(barplot, data var by file) %THEN %RETURN;
    %IF not %_spl_vars(barplot, data, var by panel) %THEN %RETURN;
    %IF not %_spl_oneof(barplot, stat, percent count) %THEN %RETURN;
    %IF %LENGTH(&denom.) %THEN %DO;
      %IF not %_spl_need(barplot, denom) %THEN %RETURN;
      %IF not %_spl_vars(barplot, denom, by) %THEN %RETURN;
    %END;
  %END;
  %ELSE %DO;
    %IF not %_spl_need(barplot, by file) %THEN %RETURN;
    %IF not %_spl_vars(barplot, plot, by panel) %THEN %RETURN;
  %END;
  %IF not %_spl_oneof(barplot, stacked, yes no) %THEN %RETURN;
  %IF not %_spl_oneof(barplot, labels, yes no) %THEN %RETURN;
  %IF not %_spl_oneof(barplot, debug, yes no) %THEN %RETURN;
  %IF %LENGTH(&columns.) %THEN %DO;
    %IF not %_spl_need(barplot, columns) %THEN %RETURN;
  %END;

  %LET stat   = %LOWCASE(&stat.);                         /* the statistic */
  %LET by     = %UPCASE(&by.);                            /* the groups, in upper case */
  %LET panel  = %UPCASE(&panel.);                         /* the panels, in upper case */
  %LET src    = &data.&plot.;                             /* the data set read */
  %LET xvar   = &var.;                                    /* the variable of the x axis */
  %LET xorder = &var.;                                    /* the order of the categories */
  %IF %LENGTH(&plot.) %THEN %LET xvar = x;                /* with plot=: its X */
  %IF %LENGTH(&plot.) %THEN %LET xorder = _xorder;        /* with plot=: its first rows */
  %LET chars  = %_spl_chars(&src., &by. &panel.);         /* the character variables */
  %LET nkeys  = %SYSFUNC(COMPBL(&panel. &by.));           /* the keys of the N */
  %LET tables = %SYSFUNC(TRANWRD(%SYSFUNC(COMPBL(&panel. &by. &var.)), %STR( ), *));  /* TABLES */
  %LET who    = Records;                                  /* what a bar counts */
  %IF %LENGTH(&denom.) %THEN %LET who = Subjects;  /* with denom=: the subjects */
  %LET xlabel = %_spl_figure_label(&src., &xvar., %SUPERQ(xlabel));  /* the x axis */
  /* the default: a percent */
  %IF %LENGTH(%SUPERQ(ylabel)) = 0 and &stat. = percent %THEN %LET ylabel = "&who. (%)";
  %IF %LENGTH(%SUPERQ(ylabel)) = 0 %THEN %LET ylabel = "&who.";  /* the default: a count */
  %LET ylabel = %_spl_figure_label(&src., , %SUPERQ(ylabel));  /* the y axis */
  %LET pby    = _panel;                                   /* the PANELBY variable */
  %IF %LENGTH(&panel.) %THEN %LET pby = &panel.;  /* with panel=: the panel variable */
  %IF %LENGTH(&out.) = 0 %THEN %LET out = _barplot_out;   /* out= not asked: not kept */
  %LET cond = not missing(&var.) and not missing(&by.);  /* the records that count */
  %IF %LENGTH(&panel.) %THEN %LET cond = &cond. and not missing(&panel.);  /* with a panel */
  %IF %LENGTH(%SUPERQ(where)) %THEN %LET cond = &cond. and &where.;        /* plus where= */

  /* Step 2: the drawing parameters: outpar= */
  %_spl_figure_outpar(names=&drawn., out=&outpar.)

  /* Step 3: with plot= its bars are drawn again, the categories in the order of their first row */
  %IF %LENGTH(&plot.) %THEN %DO;
    DATA &out.;
      IF _N_ = 1 THEN DO;
        LENGTH _xorder 8;
        DECLARE HASH _h();
        _h.DEFINEKEY('x');
        _h.DEFINEDATA('_xorder');
        _h.DEFINEDONE();
      END;
      SET &plot.;
      IF _h.FIND() NE 0 THEN DO;
        _seen + 1;
        _xorder = _seen;
        _h.ADD();
      END;
      KEEP &panel. &by. kind x y n denom _xorder;
    RUN;
    /* a count when every Y is its N */
    %LET stat = count;
    %IF %_spl_nobs(&out.(WHERE=(y NE n))) %THEN %LET stat = percent;
    %GOTO draw;
  %END;

  /* Step 4: the records; with denom= each subject once in a category */
  DATA _barplot_records;
    %IF %LENGTH(&chars.) %THEN %DO;
      LENGTH &chars. $200;
    %END;
    SET &data.;
    WHERE &cond.;
    KEEP &panel. &by. &var.
    %IF %LENGTH(&denom.) %THEN %DO;
      USUBJID
    %END;
    ;
  RUN;
  %IF %LENGTH(&denom.) %THEN %DO;
    PROC SORT DATA=_barplot_records NODUPKEY; BY &panel. &by. &var. usubjid; RUN;
  %END;

  /* Step 5: no record qualified: the figure that says so and out= without a row */
  %IF %_spl_nobs(_barplot_records) = 0 %THEN %DO;
    %_spl_figure_nodata(
        keep   = &panel. &by.
      , macro  = barplot
      , like   = _barplot_records
      , chars  = kind x
      , nums   = y n denom
      , file   = &file.
      , width  = &width.
      , height = &height.
      , out    = &out.
    )
    %GOTO finish;
  %END;

  /* Step 6: the count of each bar, and the N of each group (of denom=, or the records) */
  PROC FREQ DATA=_barplot_records NOPRINT;
    TABLES &tables. / OUT=_barplot_counts(DROP=percent);
  RUN;
  %IF %LENGTH(&denom.) %THEN %DO;
    PROC SORT DATA=&denom.(KEEP=usubjid &by. WHERE=(NOT MISSING(&by.))) OUT=_barplot_subjects
              NODUPKEY;
      BY usubjid;
    RUN;
    PROC FREQ DATA=_barplot_subjects NOPRINT;
      TABLES &by. / OUT=_barplot_n(DROP=percent RENAME=(count = denom));
    RUN;
    %LET nkeys = &by.;
  %END;
  %ELSE %DO;
    PROC FREQ DATA=_barplot_records NOPRINT;
      TABLES %SYSFUNC(TRANWRD(&nkeys., %STR( ), *)) / OUT=_barplot_n(DROP=percent
                                                         RENAME=(count = denom));
    RUN;
  %END;

  /* Step 7: the numbers drawn: out= */
  PROC SORT DATA=_barplot_counts; BY &nkeys.; RUN;
  PROC SORT DATA=_barplot_n; BY &nkeys.; RUN;
  DATA &out.;
    LENGTH kind $8 x $200;
    MERGE _barplot_counts(IN=inbar) _barplot_n;
    BY &nkeys.;
    IF inbar;
    kind = 'bar';
    x    = STRIP(VVALUE(&var.));
    n    = count;
    %IF &stat. = percent %THEN %DO;
      y = 100 * count / denom;
    %END;
    %ELSE %DO;
      y = count;
    %END;
    KEEP &panel. &by. kind x y n denom &var.;
  RUN;
  PROC SORT DATA=&out.; BY &panel. &var. &by.; RUN;

  /* Step 8: the rows of the figure: the categories in the order of var=, the groups in theirs */
  %draw:
  DATA _barplot_plot;
    SET &out.;
    _panel = 1;
    %IF &stat. = percent %THEN %DO;
      _label = PUT(y, 5.1);
    %END;
    %ELSE %DO;
      _label = PUT(y, 8.);
    %END;
  RUN;
  %_spl_figure_attrs(data=_barplot_plot, columns=&columns., var=&by., out=_barplot_attrs)
  PROC SORT DATA=_barplot_plot; BY &pby. &xorder. _order; RUN;
  DATA &out.;
    SET &out.(DROP=&xorder.);
  RUN;

  /* Step 9: the figure */
  %_spl_figure_open(file=&file., width=&width., height=&height., state=listing)
  PROC SGPANEL DATA=_barplot_plot DATTRMAP=_barplot_attrs NOAUTOLEGEND;
    %IF %LENGTH(&panel.) %THEN %DO;
      PANELBY &pby. / NOVARNAME SPACING=10;
    %END;
    %ELSE %DO;
      PANELBY &pby. / NOHEADER NOVARNAME;
    %END;
    %IF &stacked. = yes %THEN %DO;
      VBAR x / RESPONSE=y GROUP=&by. ATTRID=grp GROUPDISPLAY=stack GROUPORDER=data NAME='bar'
      %IF &labels. = yes %THEN SEGLABEL;
      ;
    %END;
    %ELSE %DO;
      VBAR x / RESPONSE=y GROUP=&by. ATTRID=grp GROUPDISPLAY=cluster GROUPORDER=data NAME='bar'
      %IF &labels. = yes %THEN DATALABEL=_label DATALABELATTRS=(SIZE=8pt);
      ;
    %END;
    %DO i = 1 %TO %SYSFUNC(COUNTW(&ref.%STR( ), %STR( )));
      REFLINE %SCAN(&ref., &i., %STR( )) / AXIS=y LINEATTRS=(pattern = dash color = gray);
    %END;
    ROWAXIS LABEL=&ylabel. grid;
    COLAXIS LABEL=&xlabel. DISCRETEORDER=data;
    KEYLEGEND 'bar' / TITLE=' ';
  RUN;
  %_spl_figure_close(listing=&listing.)

  /* Step 10: the work data sets are deleted (kept with debug=yes) */
  %finish:
  %IF %UPCASE(&debug.) ne YES %THEN %DO;
    PROC DATASETS LIBRARY=work NOLIST NOWARN;
      DELETE _barplot_:;
    QUIT;
  %END;
  %_spl_end(barplot, &t0., &debug.)
%MEND barplot;
