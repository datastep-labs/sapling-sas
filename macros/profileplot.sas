/*******************************************************************************
| Macro Name    : profileplot.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.9.1
| Created By    : Sapling
| Date          : 27NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : Draws one line per subject through its values by visit as PNG
|                 and RTF files and returns the numbers drawn. Use %meanplot for
|                 the mean of each group alone, with error bars. Each line is
|                 thin, in the colour and line pattern of the group of the
|                 subject. With mean=yes, the mean of each group at each visit
|                 is also drawn, as a thick line with markers. A record with a
|                 missing visit, value, group or panel is not used. To draw the
|                 figure again without computing, give plot= the out= and par=
|                 the outpar= of an earlier call.
| Procedure     : PROC MEANS, PROC SGPANEL
| Proven        : its known answer in tools/figures_sas.ts (the values and the
|                 means worked out by hand); not yet run on a SAS server
| Note          : Draw again: plot= takes the out= of an earlier %profileplot
|                 call, changed or not, and draws it as it is, with no statistic
|                 computed. par= takes the outpar= of that call and gives the
|                 drawing parameters: columns, subject, by, panel, mean (no: the
|                 rows of KIND mean are not drawn), xformat, xlabel, ylabel,
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
| plot        Draw again: the out= of an earlier %profileplot     Optional
|             call, changed or not. It is drawn as it is, and no
|             statistic is computed. Give it instead of data=.
| par         The drawing parameters of an earlier %profileplot   Optional
|             call: its outpar=. A drawing parameter given in
|             the call wins over its row of par=.
| columns     The data set of %columns: it gives the order of     Optional
|             the groups and their colours. When not given, the
|             groups come in the order of the data.
| where       The records to use: a condition in parentheses,     Optional
|             such as where = (anl01fl = 'Y')
| x           The visit: one numeric variable (x = avisitn or x   Required
|             = ady)
| y           The value: one numeric variable (y = aval)          Required
| subject     The subject: one variable, one line per subject     USUBJID
| by          The groups: one variable, one colour per group      Required
| panel       A variable: one panel per value, one under the      Optional
|             other, each with its own y axis (panel = paramcd)
| mean        yes: also draw the mean of each group as a thick    no
|             line
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
| debug       yes: keep the work data sets _profileplot_*         no
|-------------------------------------------------------------------------------
|
| Output        : OUT: one row per point: the variables of panel=, by= and
|                 subject=, KIND, X, Y and N. KIND is subject for a value of a
|                 subject, or mean for the mean of a group (the subject is then
|                 blank); N is the number of values of a mean. OUTPAR: one row
|                 per drawing parameter, in the order of the table: PARAMETER
|                 ($32), its name, and VALUE ($500), its value as drawn (a label
|                 in quotes). FILE: <file>.png and <file>.rtf.
|
| Example:
|
 %profileplot(
     data    = adlb
   , columns = t14_2_1_cols
   , where   = (paramcd = 'ALT' AND anl01fl = 'Y' AND MISSING(dtype))
   , x       = ady
   , y       = aval
   , by      = trt01a
   , mean    = no
   , file    = &spl_out./figures/f_alt_prof
   , out     = f_alt_prof
 )
|
|-------------------------------------------------------------------------------
| Change Log :
| Date        Programmer   Description
|-------------------------------------------------------------------------------
| 12-NOV-2026 Sapling      1.3.0: initial version.
| 12-NOV-2026 Sapling      1.4.0: the line of a subject in the line pattern of
|                          its group, so that the groups differ in black and
|                          white. No number changes.
| 13-NOV-2026 Sapling      1.6.0: outpar=, plot= and par=: draw again from a
|                          changed out= and outpar=. The defaults of the
|                          drawing parameters and of the computation are set in
|                          the macro (%_spl_figure_par). No number changes.
| 13-NOV-2026 Sapling      1.7.1: mean=no draws no empty series (the legend from
|                          a subject line); the ticks are the visits.
| 16-NOV-2026 Sapling      1.9.0: the license line; the example in the house
|                          case (names in lower case). No number changes.
| 27-NOV-2026 Sapling      1.9.1: the example runs on the example data
|                          (sas/examples). The text of the header for the
|                          manual: the summary, the form of each parameter. No
|                          number changes.
|
*******************************************************************************/
%MACRO profileplot(
     data    =      /* The records */
   , plot    =      /* Draw again: an out= of %profileplot */
   , par     =      /* The drawing parameters: an outpar= of %profileplot */
   , columns =      /* The columns of %columns: order and colours */
   , where   =      /* The records to use: a condition in parentheses */
   , x       =      /* The visit: a numeric variable */
   , y       =      /* The variable */
   , subject =      /* The subject: one line each (USUBJID) */
   , by      =      /* The groups: one colour each */
   , panel   =      /* One panel per value of this variable */
   , mean    =      /* yes: the mean of each group as a thick line (default no) */
   , xformat =      /* The format of the ticks of x */
   , xlabel  =      /* The label of the x axis */
   , ylabel  =      /* The label of the y axis */
   , ref     =      /* Reference lines on the y axis */
   , file    =      /* The output without its extension */
   , width   =      /* The width of the figure (6.5in) */
   , height  =      /* The height of the figure (4.5in) */
   , out     =      /* The numbers drawn */
   , outpar  =      /* The drawing parameters: one row each */
   , debug   = no   /* yes: keep the work data sets _profileplot_* */
) / DES = 'One line per subject by visit, coloured by group (PROC MEANS, PROC SGPANEL)';
  %LOCAL t0 i cond chars pby listing dsid rc xnum xtype ticks ok drawn src xvar yvar;
  %LET t0 = %_spl_begin(profileplot);

  /* Step 1: the parameters */
  %_spl_figure_par(
      macro   = profileplot
    , draw    = columns subject=USUBJID by panel mean=no xformat xlabel ylabel ref file width=6.5in
                height=4.5in
    , compute = where x y
    , shape   = kind x y n
    , names   = drawn
    , state   = ok
  )
  %IF not &ok. %THEN %RETURN;
  %IF %LENGTH(&plot.) = 0 %THEN %DO;
    %IF not %_spl_need(profileplot, data x y subject by file) %THEN %RETURN;
    %IF not %_spl_vars(profileplot, data, x y subject by panel) %THEN %RETURN;
    %LET dsid  = %SYSFUNC(OPEN(&data.));
    %LET xnum  = %SYSFUNC(VARNUM(&dsid., &x.));
    %LET xtype = %SYSFUNC(VARTYPE(&dsid., &xnum.));
    /* the format of the ticks, when xformat= is not given */
    %IF %LENGTH(&xformat.) = 0 %THEN %LET xformat = %SYSFUNC(VARFMT(&dsid., &xnum.));
    %LET rc = %SYSFUNC(CLOSE(&dsid.));
    %IF &xtype. = C %THEN %DO;
      %PUT %STR(ERR)OR: [profileplot] x=&x. is a character variable;
      %PUT %STR(ERR)OR: [profileplot]   fix: give x= a numeric visit (AVISITN, ADY).;
      %RETURN;
    %END;
  %END;
  %ELSE %DO;
    %IF not %_spl_need(profileplot, subject by file) %THEN %RETURN;
    %IF not %_spl_vars(profileplot, plot, subject by panel) %THEN %RETURN;
  %END;
  %IF not %_spl_oneof(profileplot, mean, yes no) %THEN %RETURN;
  %IF not %_spl_oneof(profileplot, debug, yes no) %THEN %RETURN;
  %IF %LENGTH(&columns.) %THEN %DO;
    %IF not %_spl_need(profileplot, columns) %THEN %RETURN;
  %END;

  %LET by      = %UPCASE(&by.);                                /* the groups, in upper case */
  %LET panel   = %UPCASE(&panel.);                             /* the panels, in upper case */
  %LET subject = %UPCASE(&subject.);                           /* the subject, in upper case */
  %LET src     = &data.&plot.;                                 /* the data set read */
  %LET xvar    = &x.;                                          /* the variable of the x axis */
  %LET yvar    = &y.;                                          /* the variable of the y axis */
  %IF %LENGTH(&plot.) %THEN %LET xvar = x;                     /* with plot=: its X */
  %IF %LENGTH(&plot.) %THEN %LET yvar = y;                     /* with plot=: its Y */
  %LET chars  = %_spl_chars(&src., &by. &panel. &subject.);   /* the character variables */
  %LET xlabel = %_spl_figure_label(&src., &xvar., %SUPERQ(xlabel));  /* the x axis */
  %LET ylabel = %_spl_figure_label(&src., &yvar., %SUPERQ(ylabel));  /* the y axis */
  %LET pby    = _panel;                                       /* the PANELBY variable */
  %IF %LENGTH(&panel.) %THEN %LET pby = &panel.;  /* with panel=: the panel variable */
  %IF %LENGTH(&out.) = 0 %THEN %LET out = _profileplot_out;    /* out= not asked: not kept */
  /* the records that count */
  %LET cond = not missing(&x.) and not missing(&y.) and not missing(&by.);
  %IF %LENGTH(&panel.) %THEN %LET cond = &cond. and not missing(&panel.);  /* with a panel */
  %IF %LENGTH(%SUPERQ(where)) %THEN %LET cond = &cond. and &where.;        /* plus where= */

  /* Step 2: the drawing parameters: outpar= */
  %_spl_figure_outpar(names=&drawn., out=&outpar.)

  /* Step 3: with plot= its points are drawn again */
  %IF %LENGTH(&plot.) %THEN %DO;
    DATA &out.;
      SET &plot.;
      KEEP &panel. &by. &subject. kind x y n;
    RUN;
    %GOTO draw;
  %END;

  /* Step 4: the records */
  DATA _profileplot_records;
    %IF %LENGTH(&chars.) %THEN %DO;
      LENGTH &chars. $200;
    %END;
    SET &data.;
    WHERE &cond.;
    KEEP &panel. &by. &subject. &x. &y.;
  RUN;

  /* Step 5: no record qualified: the figure that says so and out= without a row */
  %IF %_spl_nobs(_profileplot_records) = 0 %THEN %DO;
    %_spl_figure_nodata(
        keep   = &panel. &by. &subject.
      , macro  = profileplot
      , like   = _profileplot_records
      , chars  = kind
      , nums   = x y n
      , file   = &file.
      , width  = &width.
      , height = &height.
      , out    = &out.
    )
    %GOTO finish;
  %END;

  /* Step 6: the mean of each group at each visit */
  %IF &mean. = yes %THEN %DO;
    PROC MEANS DATA=_profileplot_records NOPRINT NWAY;
      CLASS &panel. &by. &x.;
      VAR &y.;
      OUTPUT OUT=_profileplot_means(DROP=_TYPE_ _FREQ_) N=n MEAN=y;
    RUN;
  %END;

  /* Step 7: the numbers drawn: out= */
  DATA &out.;
    LENGTH kind $8;
    SET _profileplot_records(IN=insubj)
    %IF &mean. = yes %THEN %DO;
      _PROFILEPLOT_MEANS
    %END;
    ;
    x = &x.;
    IF insubj THEN DO;
      kind = 'subject';
      y    = &y.;
      n    = .;
    END;
    ELSE kind = 'mean';
    KEEP &panel. &by. &subject. kind x y n;
  RUN;
  PROC SORT DATA=&out.; BY &panel. &by. kind &subject. x; RUN;

  /* Step 8: the rows of the figure: each subject in the look of its group */
  %draw:
  DATA _profileplot_plot;
    SET &out.;
    %IF &mean. = no %THEN %DO;
      IF kind = 'mean' THEN DELETE;
    %END;
    _panel = 1;
    _my    = .;
    _mby   = &by.;
    IF kind = 'mean' THEN DO;
      _my = y;
      y   = .;
    END;
  RUN;
  %_spl_figure_attrs(data=_profileplot_plot, columns=&columns., var=&by., out=_profileplot_attrs)
  PROC SORT DATA=_profileplot_plot; BY &pby. _order &subject. x; RUN;
  %IF &mean. = no %THEN %DO;
    /* without means the legend takes the line of the first subject of each group */
    DATA _profileplot_plot;
      SET _profileplot_plot;
      BY &pby. _order &subject.;
      RETAIN _rep;
           IF FIRST._order    THEN _rep = 1;
      ELSE IF first.&subject. THEN _rep = 0;
      IF _rep THEN _my = y;
      DROP _rep;
    RUN;
  %END;
  /* the ticks are the values of x (the visits) when they are 12 or fewer */
  PROC SORT DATA=_profileplot_plot(KEEP=x) OUT=_profileplot_ticks NODUPKEY; BY x; RUN;
  DATA _NULL_;
    LENGTH _list $2000;
    SET _profileplot_ticks END=last NOBS=_nx;
    RETAIN _list;
    _list = CATX(' ', _list, x);
    IF last AND (_nx <= 12 OR %LENGTH(&xformat.) > 0) THEN CALL SYMPUTX('ticks', _list, 'L');
  RUN;
  /* the line of each subject: the colour and the line pattern of its group, thin */
  PROC SORT DATA=_profileplot_plot(KEEP=&subject. _order WHERE=(NOT MISSING(&subject.)))
            OUT=_profileplot_subjects NODUPKEY;
    BY &subject.;
  RUN;
  DATA _profileplot_subjattrs;
    LENGTH id $8 value $200 linecolor $8 linepattern $24;
    IF _N_ = 1 THEN DO;
      DECLARE HASH _h(DATASET: "_profileplot_attrs(WHERE=(id = 'grp'))");
      _h.DEFINEKEY('_order');
      _h.DEFINEDATA('linecolor', 'linepattern');
      _h.DEFINEDONE();
    END;
    SET _profileplot_subjects;
    id    = 'subj';
    value = STRIP(VVALUE(&subject.));
    IF _h.FIND() NE 0 THEN DO;
      linecolor   = 'CX777777';
      linepattern = 'Solid';
    END;
    KEEP id value linecolor linepattern;
  RUN;
  DATA _profileplot_attrs;
    SET _profileplot_attrs _profileplot_subjattrs;
  RUN;
  PROC SORT DATA=_profileplot_attrs; BY id; RUN;

  /* Step 9: the figure */
  %_spl_figure_open(file=&file., width=&width., height=&height., state=listing)
  PROC SGPANEL DATA=_profileplot_plot DATTRMAP=_profileplot_attrs NOAUTOLEGEND;
    %IF %LENGTH(&panel.) %THEN %DO;
      PANELBY &pby. / NOVARNAME SPACING=10 COLUMNS=1 UNISCALE=column;
    %END;
    %ELSE %DO;
      PANELBY &pby. / NOHEADER NOVARNAME;
    %END;
    SERIES X=x Y=y / GROUP=&subject. ATTRID=subj LINEATTRS=(thickness = 1) TRANSPARENCY=0.3;
    %IF &mean. = yes %THEN %DO;
      SERIES X=x Y=_my / GROUP=_mby ATTRID=grp NAME='group' MARKERS LINEATTRS=(thickness = 3)
                         MARKERATTRS=(size = 8);
    %END;
    %ELSE %DO;
      SERIES X=x Y=_my / GROUP=_mby ATTRID=grp NAME='group' LINEATTRS=(thickness = 1);
    %END;
    %DO i = 1 %TO %SYSFUNC(COUNTW(&ref.%STR( ), %STR( )));
      REFLINE %SCAN(&ref., &i., %STR( )) / AXIS=y LINEATTRS=(pattern = dash color = gray);
    %END;
    %IF %LENGTH(&xformat.) %THEN %DO;
      FORMAT x &xformat.;
    %END;
    ROWAXIS LABEL=&ylabel. grid;
    %IF %LENGTH(&ticks.) %THEN %DO;
      COLAXIS LABEL=&xlabel. VALUES=(&ticks.);
    %END;
    %ELSE %DO;
      COLAXIS LABEL=&xlabel.;
    %END;
    KEYLEGEND 'group' / TITLE=' ';
  RUN;
  %_spl_figure_close(listing=&listing.)

  /* Step 10: the work data sets are deleted (kept with debug=yes) */
  %finish:
  %IF %UPCASE(&debug.) ne YES %THEN %DO;
    PROC DATASETS LIBRARY=work NOLIST NOWARN;
      DELETE _profileplot_:;
    QUIT;
  %END;
  %_spl_end(profileplot, &t0., &debug.)
%MEND profileplot;
