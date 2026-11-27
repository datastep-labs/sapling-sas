/*******************************************************************************
| Macro Name    : _spl_figure_dodge.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.10.0
| Created By    : Sapling
| Date          : 16NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : Move the groups a little apart on a numeric x axis, so that
|                 their error bars do not overlap: _XPLOT = x + (_ORDER - (G +
|                 1) / 2) * STEP, G the number of groups, STEP the smaller of
|                 half the smallest distance of two x values divided by G - 1
|                 and 3% of the range of x. The x of the data stays as it is.
|                 With offset= the room the axis needs at each end, so that the
|                 outer groups are not cut at the edge of the plot.
| Used By       : %meanplot, %lineplot (inner part)
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| data        The rows of the figure, with _ORDER                 Required
|             (%_spl_figure_attrs)
| x           The numeric x variable                              Required
| offset      A macro variable of the caller: it gets the offset  Optional
|             of each end of the axis (OFFSETMIN=, OFFSETMAX= of
|             COLAXIS), a fraction of its length
|-------------------------------------------------------------------------------
|
| Output        : DATA: data= with _XPLOT; with offset= that macro variable.
|
| Example:
|
 %_spl_figure_dodge(data=_meanplot_plot, x=x, offset=xoff)
|
|-------------------------------------------------------------------------------
| Change Log :
| Date        Programmer   Description
|-------------------------------------------------------------------------------
| 12-NOV-2026 Sapling      1.3.0: initial version (the figure macros).
| 16-NOV-2026 Sapling      1.9.0: offset=: the room the axis needs at each end,
|                          so that the outer groups are not cut. The license
|                          line.
|
*******************************************************************************/
%MACRO _spl_figure_dodge(
     data   =   /* The rows of the figure, with _ORDER */
   , x      =   /* The numeric x variable */
   , offset =   /* A macro variable that gets the offset of the axis ends */
) / DES = 'Move the groups of a figure a little apart on the x axis';
  %LOCAL step groups;
  %LET step   = 0;
  %LET groups = 1;

  /* Step 1: the smallest distance of two x values, the range and the number of groups */
  PROC SORT DATA=&data.(KEEP=&x. _order) OUT=_figure_dodge_x; BY &x.; RUN;
  DATA _NULL_;
    SET _figure_dodge_x END=last;
    WHERE NOT MISSING(&x.);
    RETAIN _gap _first _last _g;
    IF _N_ = 1 THEN _first = &x.;
    IF &x. > _last AND NOT MISSING(_last) THEN _gap = MIN(_gap, &x. - _last);
    _last = &x.;
    _g    = MAX(_g, _order);
    IF last THEN DO;
      _range = _last - _first;
      IF _range <= 0 THEN _range = 1;
      IF MISSING(_gap) THEN _gap = _range;
      _step = 0;
      IF _g > 1 THEN _step = MIN(0.5 * _gap / (_g - 1), 0.03 * _range);
      CALL SYMPUTX('step', _step);
      CALL SYMPUTX('groups', MAX(_g, 1));
      %IF %LENGTH(&offset.) %THEN %DO;
        /* half the width of the groups at an x, and a little room for the markers */
        CALL SYMPUTX("&offset.", ROUND(MIN(0.2, (_g - 1) / 2 * _step / _range + 0.03), 0.001));
      %END;
    END;
  RUN;

  /* Step 2: the x of the drawing */
  DATA &data.;
    SET &data.;
    _xplot = &x. + (_order - (&groups. + 1) / 2) * &step.;
  RUN;

  /* Step 3: the work data sets are deleted */
  PROC DATASETS LIBRARY=work NOLIST NOWARN;
    DELETE _figure_dodge_:;
  QUIT;
%MEND _spl_figure_dodge;
