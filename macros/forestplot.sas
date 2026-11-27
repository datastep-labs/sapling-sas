/*******************************************************************************
| Macro Name    : forestplot.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.9.1
| Created By    : Sapling
| Date          : 16NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : The forest plot of results in the levels of subgroups: one row
|                 per level under a heading row of its factor, the estimate as a
|                 marker with its interval as a bar, a line at no difference, a
|                 log axis for a ratio, and the estimate (lower, upper) as text
|                 at the right. It draws results (of %cox, %logistic,
|                 %rateratio, %lsmeans or %risk with within=), so that the
|                 figure and the table of the same results cannot differ.
| Procedure     : PROC SUMMARY, PROC SGPLOT
| Proven        : its known answer in tools/figures_sas.ts (made-up results,
|                 arranged by hand); not yet run on a SAS server
| Note          : Draw again: plot= (an out= of %forestplot, changed or not) is
|                 drawn as it is, the factors, levels and pairs in the order of
|                 its rows, each factor under the heading of its name; par= (an
|                 outpar= of %forestplot) gives the drawing parameters: columns,
|                 estimate (with plot= only the name over the text column),
|                 scale, text, xlabel, ref, file, width, height. They change the
|                 picture, not the numbers; the others compute, and with plot= a
|                 NOTE says each one given is not used. A drawing parameter
|                 given in the call wins over its row of par=, the row over the
|                 default of the table.
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| data        The results: rows of STAT and VALUE (the result     Required
|             shape), with the variables of within=
| plot        Draw again: an out= of %forestplot (not with data=) Optional
| par         The drawing parameters: an outpar= of %forestplot   Optional
| columns     The columns of %columns: the order and colours of   Optional
|             the groups of by=
| where       The results to use, a condition in parentheses      Optional
| estimate    The statistic of the estimate (hr, or, irr, rr, rd, Required
|             diff)
| lower       The statistic of the lower limit                    lcl
| upper       The statistic of the upper limit                    ucl
| within      The variables of the levels, one per factor, in the Required
|             order of the rows; a row is the level of the first
|             of them that has a value
| group       A variable with the heading of each factor          Optional
|             (default: the label of the variable of within=)
| by          The group of a pair (the results with VERSUS: the   Optional
|             pair is by= vs VERSUS); one colour per pair
| scale       log (a ratio) or linear (a difference)              log
| text        yes: the estimate (lower, upper) as text at the     yes
|             right under the name of the statistic (HR (CI)),
|             and the n when the results have a statistic n
| xlabel      The label of the x axis                             "Estimate
|                                                                 (95% CI)"
| ref         The line of no difference: 1 for a ratio, 0 for a   1
|             difference
| file        The output without its extension: <file>.png (300   Required
|             dpi) and <file>.rtf
| width       The width of the figure                             6.5in
| height      The height of the figure                            4.5in
| out         The numbers drawn                                   Optional
| outpar      The drawing parameters: one row each                Optional
| debug       yes: keep the work data sets _forestplot_*          no
|-------------------------------------------------------------------------------
|
| Output        : OUT: one row per level and pair: FACTOR (the variable of
|                 within=), LEVEL (its value as printed), PAIR (by= vs VERSUS;
|                 blank without by=), KIND estimate, X (the estimate), LOWER,
|                 UPPER, N (missing unless the results have n). OUTPAR: one row
|                 per drawing parameter in the order of the table: PARAMETER
|                 ($32) its name, VALUE ($500) its value as drawn (a label in
|                 quotes). FILE: <file>.png and <file>.rtf.
|
| Example:
|
 %forestplot(
     data     = t14_2_sg
   , estimate = hr
   , within   = sex agegr1 race
   , by       = trta
   , scale    = log
   , ref      = 1
   , file     = &spl_out./figures/f14_2_sg
   , out      = f14_2_sg
 )
|
|-------------------------------------------------------------------------------
| Change Log :
| Date        Programmer   Description
|-------------------------------------------------------------------------------
| 12-NOV-2026 Sapling      1.3.0: initial version: replaces %plot(type=forest).
| 12-NOV-2026 Sapling      1.4.0: the pairs of a level 0.35 of a row apart
|                          (0.22 before), so that their two texts do not touch;
|                          a level of more pairs is higher. No number changes.
| 13-NOV-2026 Sapling      1.6.0: outpar=, plot= and par=: draw again from a
|                          changed out= and outpar=. The defaults of the
|                          drawing parameters and of the computation are set in
|                          the macro (%_spl_figure_par). No number changes.
| 13-NOV-2026 Sapling      1.7.1: estimate= that is not a statistic of the
|                          results is an error with its fix.
| 16-NOV-2026 Sapling      1.9.0: the license line; the example in the house
|                          case (names in lower case). No number changes.
|
*******************************************************************************/
%MACRO forestplot(
     data     =      /* The results */
   , plot     =      /* Draw again: an out= of %forestplot */
   , par      =      /* The drawing parameters: an outpar= of %forestplot */
   , columns  =      /* The columns of %columns: order and colours */
   , where    =      /* The results to use: a condition in parentheses */
   , estimate =      /* The statistic of the estimate */
   , lower    =      /* The statistic of the lower limit (lcl) */
   , upper    =      /* The statistic of the upper limit (ucl) */
   , within   =      /* The variables of the levels, one per factor */
   , group    =      /* A variable with the heading of each factor */
   , by       =      /* The group of a pair: by= vs VERSUS */
   , scale    =      /* log (default: a ratio) or linear (a difference) */
   , text     =      /* yes (default): the estimate and its limits as text */
   , xlabel   =      /* The label of the x axis ("Estimate (95% CI)") */
   , ref      =      /* The line of no difference (1) */
   , file     =      /* The output without its extension */
   , width    =      /* The width of the figure (6.5in) */
   , height   =      /* The height of the figure (4.5in) */
   , out      =      /* The numbers drawn */
   , outpar   =      /* The drawing parameters: one row each */
   , debug    = no   /* yes: keep the work data sets _forestplot_* */
) / DES = 'Forest plot of results in the levels of subgroups (PROC SGPLOT)';
  %LOCAL t0 i nw dsid rc stat result versus listing hasn npair bottom ticks ok drawn hasest;
  %LET t0 = %_spl_begin(forestplot);

  /* Step 1: the parameters */
  %_spl_figure_par(
      macro   = forestplot
    , draw    = columns estimate scale=log text=yes xlabel="Estimate (95% CI)" ref=1 file
                width=6.5in height=4.5in
    , compute = where lower=lcl upper=ucl within group by
    , shape   = factor level pair kind x lower upper n
    , names   = drawn
    , state   = ok
  )
  %IF not &ok. %THEN %RETURN;
  %IF %LENGTH(&plot.) = 0 %THEN %DO;
    %IF not %_spl_need(forestplot, data estimate lower upper within file) %THEN %RETURN;
    %IF not %_spl_vars(forestplot, data, within group by) %THEN %RETURN;
    %LET dsid   = %SYSFUNC(OPEN(&data.));
    %LET stat   = %SYSFUNC(VARNUM(&dsid., stat));
    %LET result = %SYSFUNC(MIN(&stat., %SYSFUNC(VARNUM(&dsid., value))));
    %LET versus = %SYSFUNC(VARNUM(&dsid., versus));
    %LET rc     = %SYSFUNC(CLOSE(&dsid.));
    %IF &result. = 0 %THEN %DO;
      %PUT %STR(ERR)OR: [forestplot] data=&data. has no STAT and VALUE: it is not a result;
      %PUT %STR(ERR)OR: [forestplot]   fix: give data= the out= of a comparison with within=.;
      %RETURN;
    %END;
  %END;
  %ELSE %DO;
    %IF not %_spl_need(forestplot, file) %THEN %RETURN;
  %END;
  %IF %LENGTH(&columns.) %THEN %DO;
    %IF not %_spl_need(forestplot, columns) %THEN %RETURN;
  %END;
  %IF not %_spl_oneof(forestplot, scale, log linear) %THEN %RETURN;
  %IF not %_spl_oneof(forestplot, text, yes no) %THEN %RETURN;
  %IF not %_spl_oneof(forestplot, debug, yes no) %THEN %RETURN;

  %LET within   = %UPCASE(%SYSFUNC(COMPBL(&within.%STR( ))));  /* the factors, in upper case */
  %LET nw       = %SYSFUNC(COUNTW(&within.%STR( ), %STR( )));  /* the number of factors */
  %LET estimate = %LOWCASE(&estimate.);                      /* the statistics, as STAT has them */
  %LET lower    = %LOWCASE(&lower.);                       /* the lower limit */
  %LET upper    = %LOWCASE(&upper.);                       /* the upper limit */
  %LET xlabel   = %_spl_figure_label(&data.&plot., , %SUPERQ(xlabel));  /* the x axis */
  %IF %LENGTH(&out.) = 0 %THEN %LET out = _forestplot_out;   /* out= not asked: not kept */

  /* Step 2: the drawing parameters: outpar= */
  %_spl_figure_outpar(names=&drawn., out=&outpar.)

  /* Step 3: with plot= its rows are drawn again, each factor under its name */
  %IF %LENGTH(&plot.) %THEN %DO;
    DATA _forestplot_rows;
      LENGTH _head $256;
      SET &plot.;
      _first = _N_;
      _head  = factor;
      KEEP factor level pair kind x lower upper n _first _head;
    RUN;
    PROC SUMMARY DATA=_forestplot_rows NWAY;
      CLASS factor;
      VAR _first;
      OUTPUT OUT=_forestplot_fseq(DROP=_TYPE_ _FREQ_) MIN=_f;
    RUN;
    PROC SORT DATA=_forestplot_rows; BY factor; RUN;
    DATA _forestplot_rows;
      MERGE _forestplot_rows _forestplot_fseq;
      BY factor;
    RUN;
    %GOTO order;
  %END;

  /* Step 4: the rows of the statistics: the factor, the level and the pair of each */
  %LET hasest = 0;
  DATA _NULL_;
    SET &data.(WHERE=(LOWCASE(stat) = "&estimate."));
    CALL SYMPUTX('hasest', 1, 'L');
    STOP;
  RUN;
  %IF &hasest. = 0 %THEN %DO;
    %PUT %STR(ERR)OR: [forestplot] estimate=&estimate. is not a statistic (STAT) of data=&data..;
    %PUT %STR(ERR)OR: [forestplot]   fix: give estimate= a statistic of the results (hr, or, rd).;
    %GOTO finish;
  %END;
  DATA _forestplot_r;
    LENGTH factor level pair $200 _head $256;
    SET &data.;
    WHERE LOWCASE(stat) IN ("&estimate." "&lower." "&upper." 'n')
    %IF %LENGTH(%SUPERQ(where)) %THEN %DO;
      AND &where.
    %END;
    ;
    _row = _N_;
    _f   = 0;
    %DO i = 1 %TO &nw.;
      IF _f = 0 AND NOT MISSING(%SCAN(&within., &i., %STR( ))) THEN DO;
        _f     = &i.;
        factor = "%SCAN(&within., &i., %STR( ))";
        level  = STRIP(VVALUE(%SCAN(&within., &i., %STR( ))));
        _head  = VLABEL(%SCAN(&within., &i., %STR( )));
      END;
    %END;
    IF _f = 0 THEN DELETE;
    %IF %LENGTH(&group.) %THEN %DO;
      IF NOT MISSING(&group.) THEN _head = &group.;
    %END;
    %IF %LENGTH(&by.) and &versus. > 0 %THEN %DO;
      pair = CATX(' vs ', VVALUE(&by.), versus);
    %END;
    %ELSE %IF %LENGTH(&by.) %THEN %DO;
      pair = VVALUE(&by.);
    %END;
    %ELSE %DO;
      pair = ' ';
    %END;
    stat = LOWCASE(stat);
    KEEP factor level pair _head _f _row stat value;
  RUN;

  /* Step 5: no result qualified: the figure that says so and out= without a row */
  %IF %_spl_nobs(_forestplot_r) = 0 %THEN %DO;
    %_spl_figure_nodata(
        macro  = forestplot
      , like   = _forestplot_r
      , chars  = factor level pair kind
      , nums   = x lower upper n
      , file   = &file.
      , width  = &width.
      , height = &height.
      , out    = &out.
    )
    %GOTO finish;
  %END;

  /* Step 6: one row per level and pair: the estimate, its limits and the n */
  PROC SORT DATA=_forestplot_r; BY _f level pair _row; RUN;
  DATA _forestplot_rows;
    LENGTH kind $8;
    SET _forestplot_r;
    BY _f level pair;
    RETAIN x lower upper n _first;
    IF FIRST.pair THEN DO;
      CALL MISSING(x, lower, upper, n);
      _first = _row;
    END;
    IF stat = "&estimate." THEN x = value;
    IF stat = "&lower." THEN lower = value;
    IF stat = "&upper." THEN upper = value;
    IF stat = 'n' THEN n = value;
    IF LAST.pair;
    kind = 'estimate';
    DROP stat value _row;
  RUN;

  /* Step 7: the order: the factors as in within=, the levels and the pairs as in the data */
  %order:
  PROC SUMMARY DATA=_forestplot_rows NWAY;
    CLASS _f level;
    VAR _first;
    OUTPUT OUT=_forestplot_lseq(DROP=_TYPE_ _FREQ_) MIN=_lseq;
  RUN;
  PROC SUMMARY DATA=_forestplot_rows NWAY;
    CLASS pair;
    VAR _first;
    OUTPUT OUT=_forestplot_pseq(DROP=_TYPE_ _FREQ_) MIN=_pseq;
  RUN;
  PROC SORT DATA=_forestplot_rows; BY _f level; RUN;
  DATA _forestplot_rows;
    MERGE _forestplot_rows _forestplot_lseq;
    BY _f level;
  RUN;
  PROC SORT DATA=_forestplot_rows; BY pair; RUN;
  DATA _forestplot_rows;
    MERGE _forestplot_rows _forestplot_pseq;
    BY pair;
  RUN;
  PROC SORT DATA=_forestplot_rows; BY _f _lseq _pseq; RUN;

  /* Step 8: the numbers drawn: out= */
  DATA &out.;
    SET _forestplot_rows;
    KEEP factor level pair kind x lower upper n;
  RUN;

  /* Step 9: the rows of the figure: a heading row per factor, then its levels, the pairs apart */
  %_spl_figure_attrs(data=_forestplot_rows, columns=, var=pair, out=_forestplot_attrs)
  %LET npair = %_spl_nobs(_forestplot_attrs(WHERE=(id = 'grp')));
  %LET hasn  = %_spl_nobs(_forestplot_rows(WHERE=(NOT MISSING(n))));
  DATA _forestplot_plot;
    LENGTH _label _etext _ntext $200 _kind $8;
    SET _forestplot_rows;
    BY _f _lseq;
    RETAIN _line 0;
    IF FIRST._f THEN DO;
      _line   = _line + 1;
      _label  = _head;
      _kind   = 'heading';
      _indent = 0;
      _ly     = _line;
      CALL MISSING(_y, _etext, _ntext);
      OUTPUT;
    END;
    /* a level as high as its pairs need: 0.35 of a row each, so that their texts stand apart */
    IF FIRST._lseq THEN _line = _line + MAX(1, 0.35 * &npair. + 0.3);
    _label  = level;
    _kind   = 'level';
    _indent = 1;
    _ly     = IFN(FIRST._lseq, _line, .);
    _y      = _line + (_order - (&npair. + 1) / 2) * 0.35;
    IF NOT FIRST._lseq THEN _label = ' ';
    _etext = CATX(' ', IFC(MISSING(x), 'NE', STRIP(PUT(x, 8.2))),
                   CATS('(', IFC(MISSING(lower), 'NE', STRIP(PUT(lower, 8.2))), ','),
                   CATS(IFC(MISSING(upper), 'NE', STRIP(PUT(upper, 8.2))), ')'));
    _ntext = IFC(MISSING(n), ' ', STRIP(PUT(n, BEST8.)));
    OUTPUT;
  RUN;
  DATA _NULL_;
    SET _forestplot_plot END=last;
    RETAIN _most 0;
    _most = MAX(_most, _ly);
    IF last THEN CALL SYMPUTX('bottom', _most + MAX(0.5, 0.175 * &npair. + 0.15), 'L');
  RUN;
  DATA _forestplot_txt;
    LENGTH id $8 value $200 textweight $8;
    id         = 'txt';
    value      = 'heading';
    textweight = 'bold';
    OUTPUT;
    value      = 'level';
    textweight = 'normal';
    OUTPUT;
  RUN;
  DATA _forestplot_attrs;
    SET _forestplot_attrs _forestplot_txt;
  RUN;
  PROC SORT DATA=_forestplot_attrs; BY id; RUN;

  /* Step 10: the ticks of a log axis: 1, 2 and 5 times a power of 10 in the range of the limits */
  %IF &scale. = log %THEN %DO;
    PROC SUMMARY DATA=_forestplot_rows;
      VAR lower upper x;
      OUTPUT OUT=_forestplot_range MIN(lower x)=_lo _lo2 MAX(upper x)=_hi _hi2;
    RUN;
    DATA _NULL_;
      LENGTH _list $1000;
      SET _forestplot_range;
      _lo = MIN(_lo, _lo2, &ref.);
      _hi = MAX(_hi, _hi2, &ref.);
      DO _p = -4 TO 4;
        DO _m = 1, 2, 5;
          _t = _m * 10 ** _p;
          IF _t >= _lo / 1.5 AND _t <= _hi * 1.5 THEN _list = CATX(' ', _list, _t);
        END;
      END;
      CALL SYMPUTX('ticks', _list, 'L');
    RUN;
  %END;

  /* Step 11: the figure */
  %_spl_figure_open(file=&file., width=&width., height=&height., state=listing)
  PROC SGPLOT DATA=_forestplot_plot DATTRMAP=_forestplot_attrs NOAUTOLEGEND;
    REFLINE &ref. / AXIS=x LINEATTRS=(pattern = dash color = gray);
    HIGHLOW Y=_y LOW=lower HIGH=upper / GROUP=pair ATTRID=grp LINEATTRS=(thickness = 1.5)
                                       LOWCAP=serif HIGHCAP=serif;
    SCATTER Y=_y X=x / GROUP=pair ATTRID=grp NAME='est' MARKERATTRS=(size = 9);
    YAXISTABLE _label / Y=_ly LOCATION=inside POSITION=left INDENTWEIGHT=_indent
                        TEXTGROUP=_kind TEXTGROUPID=txt LABEL=' ' VALUEATTRS=(size = 9pt);
    %IF &text. = yes %THEN %DO;
      YAXISTABLE _etext / Y=_y LOCATION=inside POSITION=right LABEL="%UPCASE(&estimate.) (CI)"
                          LABELATTRS=(size = 8pt) VALUEATTRS=(size = 8pt);
      %IF &hasn. %THEN %DO;
        YAXISTABLE _ntext / Y=_y LOCATION=inside POSITION=right LABEL='n'
                            LABELATTRS=(size = 8pt) VALUEATTRS=(size = 8pt);
      %END;
    %END;
    %IF &scale. = log %THEN %DO;
      XAXIS TYPE=log LOGBASE=10 LOGSTYLE=linear VALUES=(&ticks.) LABEL=&xlabel.;
    %END;
    %ELSE %DO;
      XAXIS LABEL=&xlabel.;
    %END;
    YAXIS reverse DISPLAY=none MIN=0.5 MAX=&bottom.;
    %IF &npair. > 1 %THEN %DO;
      KEYLEGEND 'est' / TITLE=' ';
    %END;
  RUN;
  %_spl_figure_close(listing=&listing.)

  /* Step 12: the work data sets are deleted (kept with debug=yes) */
  %finish:
  %IF %UPCASE(&debug.) ne YES %THEN %DO;
    PROC DATASETS LIBRARY=work NOLIST NOWARN;
      DELETE _forestplot_:;
    QUIT;
  %END;
  %_spl_end(forestplot, &t0., &debug.)
%MEND forestplot;
