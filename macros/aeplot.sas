/*******************************************************************************
| Macro Name    : aeplot.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.9.1
| Created By    : Sapling
| Date          : 16NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : The adverse events of the subjects as two panels side by side
|                 that share the axis of the terms: at the left the percent of
|                 the subjects of each group with the term (dots), at the right
|                 the risk difference of each group against the reference
|                 group with its interval and a line at 0. The flags are those
|                 of %termflags, the risk differences those of %risk (ci=,
|                 level=), so that the figure and a table made with them cannot
|                 differ. The terms: those of threshold=, sorted by sort=, at
|                 most max= of them.
| Procedure     : PROC SUMMARY, PROC SGPANEL (and PROC FREQ in %risk)
| Proven        : its known answer in tools/figures_sas.ts (percents and Wald
|                 intervals worked out by hand); not yet run on a SAS server
| Note          : Draw again: plot= (an out= of %aeplot, changed or not) is
|                 drawn as it is, the terms from the top in the order of their
|                 first row (to drop or move a term, change its rows); par= (an
|                 outpar= of %aeplot) gives the drawing parameters: columns,
|                 term, by, xlabel, file, width, height. They change the
|                 picture, not the numbers; the others compute (sort= and max=
|                 choose the rows of out= and their order), and with plot= a
|                 NOTE says each one given is not used. A drawing parameter
|                 given in the call wins over its row of par=, the row over the
|                 default of the table.
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| data        The adverse event records                           Required
| plot        Draw again: an out= of %aeplot (not with data=)     Optional
| par         The drawing parameters: an outpar= of %aeplot       Optional
| columns     The columns of %columns: the order of the groups    Optional
|             and their colours (default: the order of denom=)
| denom       The population: one row per subject with by=        Required
| where       The records to use, a condition in parentheses      Optional
|             (TRTEMFL = 'Y')
| term        The term of a row                                   AEDECOD
| by          The groups: a character variable of denom=          Required
| reference   The reference group: a value of by=, in quotes      Required
| threshold   A percent: only the terms with this percent of the  Optional
|             subjects of a group or more, in at least one group
| sort        The order of the terms from the top: difference     difference
|             (the risk difference of the first group that is not
|             the reference, largest first), frequency (the
|             percent of all subjects, largest first) or
|             alphabetical
| ci          The interval of the risk difference: ci= of %risk   wald
| level       The confidence level                                0.95
| max         The most terms shown (the first in sort=)           30
| xlabel      The heading of the right panel (default: Risk       Optional
|             difference (%) with 95% CI, the level of level=)
| file        The output without its extension: <file>.png (300   Required
|             dpi) and <file>.rtf
| width       The width of the figure                             6.5in
| height      The height of the figure                            4.5in
| out         The numbers drawn                                   Optional
| outpar      The drawing parameters: one row each                Optional
| debug       yes: keep the work data sets _aeplot_*              no
|-------------------------------------------------------------------------------
|
| Output        : OUT: TERM and BY, KIND, X, LOWER, UPPER, N. KIND percent: one
|                 row per term and group, X the percent of its subjects, N the
|                 subjects with the term. KIND difference: one row per term and
|                 group that is not the reference, X the risk difference in
|                 percent (100 x RD of %risk), LOWER and UPPER its limits in
|                 percent. OUTPAR: one row per drawing parameter in the order of
|                 the table: PARAMETER ($32) its name, VALUE ($500) its value as
|                 drawn (a label in quotes). FILE: <file>.png and <file>.rtf.
|
| Example:
|
 %aeplot(
     data      = adae
   , columns   = t14_5_1_cols
   , denom     = adsl
   , where     = (trtemfl = 'Y')
   , term      = aedecod
   , by        = trta
   , reference = "Placebo"
   , threshold = 5
   , file      = &spl_out./figures/f14_5_3
   , out       = f14_5_3
 )
|
|-------------------------------------------------------------------------------
| Change Log :
| Date        Programmer   Description
|-------------------------------------------------------------------------------
| 12-NOV-2026 Sapling      1.3.0: initial version.
| 12-NOV-2026 Sapling      1.4.0: the percents on the line of their term (no
|                          dodge: the symbols of equal percents overlap); the
|                          line at 0 in the right panel only. No number
|                          changes.
| 13-NOV-2026 Sapling      1.6.0: outpar=, plot= and par=: draw again from a
|                          changed out= and outpar=. The defaults of the
|                          drawing parameters and of the computation are set in
|                          the macro (%_spl_figure_par). No number changes.
| 16-NOV-2026 Sapling      1.9.0: the license line; the example in the house
|                          case (names in lower case). No number changes.
|
*******************************************************************************/
%MACRO aeplot(
     data      =      /* The adverse event records */
   , plot      =      /* Draw again: an out= of %aeplot */
   , par       =      /* The drawing parameters: an outpar= of %aeplot */
   , columns   =      /* The columns of %columns: order and colours */
   , denom     =      /* The population: one row per subject */
   , where     =      /* The records to use: a condition in parentheses */
   , term      =      /* The term of a row (AEDECOD) */
   , by        =      /* The groups: a character variable of denom= */
   , reference =      /* The reference group, in quotes */
   , threshold =      /* A percent: only the terms that reach it */
   , sort      =      /* difference (default), frequency or alphabetical */
   , ci        =      /* The interval of the risk difference (wald) */
   , level     =      /* The confidence level (0.95) */
   , max       =      /* The most terms shown (30) */
   , xlabel    =      /* The heading of the right panel */
   , file      =      /* The output without its extension */
   , width     =      /* The width of the figure (6.5in) */
   , height    =      /* The height of the figure (4.5in) */
   , out       =      /* The numbers drawn */
   , outpar    =      /* The drawing parameters: one row each */
   , debug     = no   /* yes: keep the work data sets _aeplot_* */
) / DES = 'Adverse events: percent by group and risk difference (PROC SUMMARY, PROC SGPANEL)';
  %LOCAL t0 ref nref pairs first listing left right ok drawn;
  %LET t0 = %_spl_begin(aeplot);

  /* Step 1: the parameters */
  %_spl_figure_par(
      macro   = aeplot
    , draw    = columns term=AEDECOD by xlabel file width=6.5in height=4.5in
    , compute = denom where reference threshold sort=difference ci=wald level=0.95 max=30
    , shape   = kind x lower upper n
    , names   = drawn
    , state   = ok
  )
  %IF not &ok. %THEN %RETURN;
  %IF %LENGTH(&plot.) = 0 %THEN %DO;
    %IF not %_spl_need(aeplot, data denom term by reference file) %THEN %RETURN;
    %IF not %_spl_vars(aeplot, data, term) %THEN %RETURN;
    %IF not %_spl_vars(aeplot, denom, by) %THEN %RETURN;
    %IF not %_spl_oneof(aeplot, sort, difference frequency alphabetical) %THEN %RETURN;
    %IF not %SYSFUNC(PRXMATCH(/^[1-9][0-9]*$/, &max.)) %THEN %DO;
      %PUT %STR(ERR)OR: [aeplot] max=&max. is not a positive whole number;
      %PUT %STR(ERR)OR: [aeplot]   fix: give max= the most terms to show, such as 30.;
      %RETURN;
    %END;
  %END;
  %ELSE %DO;
    %IF not %_spl_need(aeplot, term by file) %THEN %RETURN;
    %IF not %_spl_vars(aeplot, plot, term by) %THEN %RETURN;
  %END;
  %IF not %_spl_oneof(aeplot, debug, yes no) %THEN %RETURN;
  %IF %LENGTH(&columns.) %THEN %DO;
    %IF not %_spl_need(aeplot, columns) %THEN %RETURN;
  %END;

  %LET term = %UPCASE(&term.);                       /* the term, in upper case */
  %LET by   = %UPCASE(&by.);                         /* the groups, in upper case */
  %LET sort = %LOWCASE(&sort.);                      /* the order of the terms */
  /* the reference group, without quotes */
  %IF %LENGTH(%SUPERQ(reference)) %THEN %LET ref = %SYSFUNC(DEQUOTE(%SUPERQ(reference)));
  %LET left  = Percent of subjects;                   /* the heading of the left panel */
  %LET right = Risk difference (%) with %SYSEVALF(100 * &level.)% CI;  /* of the right panel */
  /* xlabel= is the heading */
  %IF %LENGTH(%SUPERQ(xlabel)) %THEN %LET right = %SYSFUNC(DEQUOTE(%SUPERQ(xlabel)));
  %LET xlabel = %_spl_figure_label(, , %SUPERQ(right));  /* the heading as drawn, in quotes */
  %IF %LENGTH(&out.) = 0 %THEN %LET out = _aeplot_out;  /* out= not asked: not kept */

  /* Step 2: the drawing parameters: outpar= */
  %_spl_figure_outpar(names=&drawn., out=&outpar.)

  /* Step 3: with plot= its rows are drawn again, the terms in the order of their first row */
  %IF %LENGTH(&plot.) %THEN %DO;
    DATA &out.;
      IF _N_ = 1 THEN DO;
        LENGTH _rank 8;
        DECLARE HASH _h();
        _h.DEFINEKEY("&term.");
        _h.DEFINEDATA('_rank');
        _h.DEFINEDONE();
      END;
      SET &plot.;
      IF _h.FIND() NE 0 THEN DO;
        _seen + 1;
        _rank = _seen;
        _h.ADD();
      END;
      KEEP &term. &by. kind x lower upper n _rank;
    RUN;
    %GOTO draw;
  %END;

  /* Step 4: the groups of the population; the reference must be one of them */
  PROC SORT DATA=&denom.(KEEP=&by. WHERE=(NOT MISSING(&by.))) OUT=_aeplot_groups NODUPKEY; BY &by.; RUN;
  %LET nref = %_spl_nobs(_aeplot_groups(WHERE=(&by. = "&ref.")));
  %IF &nref. = 0 %THEN %DO;
    %PUT %STR(ERR)OR: [aeplot] reference=&reference. is not a group of by=&by. in denom=&denom.;
    %PUT %STR(ERR)OR: [aeplot]   fix: give reference= a value of &by. in quotes.;
    %GOTO finish;
  %END;
  /* each group that is not the reference against it: the pairs of %risk */
  DATA _NULL_;
    LENGTH _pairs $32767;
    SET _aeplot_groups END=last;
    RETAIN _pairs;
    IF &by. NE "&ref." THEN
      _pairs = CATX(' # ', _pairs, CATX(' ', QUOTE(STRIP(&by.)), QUOTE("&ref.")));
    IF last THEN CALL SYMPUTX('pairs', _pairs, 'L');
  RUN;
  /* the first group that is not the reference, in the order of columns= (else of the values) */
  DATA _aeplot_order;
    LENGTH _v $200;
    %IF %LENGTH(&columns.) %THEN %DO;
      IF _N_ = 1 THEN DO;
        _c = .;
        DECLARE HASH _h(DATASET: "&columns.(RENAME=(colvalue = _v col = _c))");
        _h.DEFINEKEY('_v');
        _h.DEFINEDATA('_c');
        _h.DEFINEDONE();
      END;
    %END;
    SET _aeplot_groups;
    _v = STRIP(&by.);
    %IF %LENGTH(&columns.) %THEN %DO;
      IF _h.FIND() NE 0 THEN _c = 1E9;
    %END;
    %ELSE %DO;
      _c = 1;
    %END;
    IF &by. NE "&ref.";
  RUN;
  PROC SORT DATA=_aeplot_order; BY _c &by.; RUN;
  DATA _NULL_;
    SET _aeplot_order(OBS=1);
    CALL SYMPUTX('first', &by., 'L');
  RUN;

  /* Step 5: the flag of each term for every subject (%termflags) */
  %termflags(
      data      = &data.
    , denom     = &denom.
    , where     = &where.
    , terms     = &term.
    , by        = &by.
    , threshold = &threshold.
    , out       = _aeplot_flags
  )

  /* Step 6: no term qualified: the figure that says so and out= without a row */
  %IF %_spl_nobs(_aeplot_flags) = 0 %THEN %DO;
    %_spl_figure_nodata(
        keep   = &by.
      , macro  = aeplot
      , like   = _aeplot_groups
      , chars  = &term. kind
      , nums   = x lower upper n
      , file   = &file.
      , width  = &width.
      , height = &height.
      , out    = &out.
    )
    %GOTO finish;
  %END;

  /* Step 7: the percent of the subjects of each group with each term */
  DATA _aeplot_flags;
    LENGTH &term. &by. $200;
    SET _aeplot_flags;
    _y = IFN(flag = 'Y', 1, 0);
  RUN;
  PROC SUMMARY DATA=_aeplot_flags NWAY;
    CLASS &term. &by.;
    VAR _y;
    OUTPUT OUT=_aeplot_pct(DROP=_TYPE_ _FREQ_) SUM=n MEAN=_p;
  RUN;
  PROC SUMMARY DATA=_aeplot_flags NWAY;
    CLASS &term.;
    VAR _y;
    OUTPUT OUT=_aeplot_all(DROP=_TYPE_ _FREQ_) MEAN=_all;
  RUN;

  /* Step 8: the risk difference of each group against the reference (%risk) */
  %risk(
      data    = _aeplot_flags
    , var     = flag
    , event   = "Y"
    , by      = &by.
    , within  = &term.
    , pairs   = &pairs.
    , measure = rd
    , ci      = &ci.
    , level   = &level.
    , out     = _aeplot_rd
  )
  PROC SORT DATA=_aeplot_rd(WHERE=(stat IN ('rd' 'lcl' 'ucl'))) OUT=_aeplot_rd; BY &term. &by.; RUN;
  PROC TRANSPOSE DATA=_aeplot_rd OUT=_aeplot_diff(DROP=_NAME_);
    BY &term. &by.;
    ID stat;
    VAR value;
  RUN;

  /* Step 9: the terms in their order (sort=), at most max= of them */
  DATA _aeplot_rank;
    MERGE _aeplot_all
    %IF &sort. = difference %THEN %DO;
      _aeplot_diff(keep = &term. &by. rd where = (&by. = "&first."))
    %END;
    ;
    BY &term.;
  RUN;
  %IF &sort. = difference %THEN %DO;
    PROC SORT DATA=_aeplot_rank; BY DESCENDING rd DESCENDING _all &term.; RUN;
  %END;
  %ELSE %IF &sort. = frequency %THEN %DO;
    PROC SORT DATA=_aeplot_rank; BY DESCENDING _all &term.; RUN;
  %END;
  %ELSE %DO;
    PROC SORT DATA=_aeplot_rank; BY &term.; RUN;
  %END;
  DATA _aeplot_rank;
    SET _aeplot_rank;
    _rank = _N_;
    IF _rank <= &max.;
    KEEP &term. _rank;
  RUN;
  %IF %_spl_nobs(_aeplot_all) > &max. %THEN
    %PUT NOTE: [aeplot] %_spl_nobs(_aeplot_all) terms qualified: the first &max. are shown.;

  /* Step 10: the numbers drawn: out= */
  PROC SORT DATA=_aeplot_rank; BY &term.; RUN;
  DATA _aeplot_both;
    MERGE _aeplot_pct _aeplot_diff(IN=indiff);
    BY &term. &by.;
    _diff = IFN(indiff, 1, 0);
  RUN;
  DATA &out.;
    LENGTH kind $12;
    MERGE _aeplot_both _aeplot_rank(IN=inrank);
    BY &term.;
    IF inrank;
    kind  = 'percent';
    x     = 100 * _p;
    lower = .;
    upper = .;
    OUTPUT;
    IF _diff = 1 THEN DO;
      kind  = 'difference';
      x     = 100 * rd;
      lower = 100 * lcl;
      upper = 100 * ucl;
      n     = .;
      OUTPUT;
    END;
    KEEP &term. &by. kind x lower upper n _rank;
  RUN;
  PROC SORT DATA=&out.; BY _rank kind &by.; RUN;

  /* Step 11: the rows of the figure: the left panel the percents, the right the differences */
  %draw:
  DATA _aeplot_plot;
    LENGTH _panel $80;
    SET &out.;
    IF kind = 'percent' THEN _panel = "1 &left.";
    ELSE                     _panel = "2 &right.";
    _bar = &by.;
    /* the percents on the line of their term, the differences side by side, the line at 0 right */
    _xp  = IFN(kind = 'percent', x, .);
    _xd  = IFN(kind = 'difference', x, .);
    _ref = IFN(kind = 'difference', 0, .);
  RUN;
  DATA &out.;
    SET &out.(DROP=_rank);
  RUN;
  %_spl_figure_attrs(data=_aeplot_plot, columns=&columns., var=&by., out=_aeplot_attrs)
  PROC SORT DATA=_aeplot_plot; BY _rank _panel _order; RUN;
  DATA _aeplot_plot;
    SET _aeplot_plot;
    _panel = SUBSTR(_panel, 3);
  RUN;

  /* Step 12: the figure */
  %_spl_figure_open(file=&file., width=&width., height=&height., state=listing)
  PROC SGPANEL DATA=_aeplot_plot DATTRMAP=_aeplot_attrs NOAUTOLEGEND;
    PANELBY _panel / LAYOUT=columnlattice UNISCALE=row NOVARNAME ONEPANEL SORT=data SPACING=10;
    REFLINE _ref / AXIS=x LINEATTRS=(pattern = dash color = gray);
    HIGHLOW Y=&term. LOW=lower HIGH=upper / GROUP=_bar ATTRID=grpcol GROUPDISPLAY=cluster
                                            GROUPORDER=data
                                            CLUSTERWIDTH=0.3;
    SCATTER Y=&term. X=_xp / GROUP=&by. ATTRID=grp NAME='dot' GROUPORDER=data
                             MARKERATTRS=(size = 7);
    SCATTER Y=&term. X=_xd / GROUP=&by. ATTRID=grp GROUPDISPLAY=cluster GROUPORDER=data
                             CLUSTERWIDTH=0.3 MARKERATTRS=(size = 7);
    ROWAXIS DISPLAY=(nolabel) DISCRETEORDER=data reverse VALUEATTRS=(size = 8pt) grid;
    COLAXIS DISPLAY=(nolabel) grid;
    KEYLEGEND 'dot' / TITLE=' ';
  RUN;
  %_spl_figure_close(listing=&listing.)

  /* Step 13: the work data sets are deleted (kept with debug=yes) */
  %finish:
  %IF %UPCASE(&debug.) ne YES %THEN %DO;
    PROC DATASETS LIBRARY=work NOLIST NOWARN;
      DELETE _aeplot_:;
    QUIT;
  %END;
  %_spl_end(aeplot, &t0., &debug.)
%MEND aeplot;
