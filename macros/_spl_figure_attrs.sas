/*******************************************************************************
| Macro Name    : _spl_figure_attrs.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.10.0
| Created By    : Sapling
| Date          : 16NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : The look of the groups of a figure: an attribute map (DATTRMAP=)
|                 that gives each value of the group variable a colour, a marker
|                 and a line pattern, in the order of the columns of %columns
|                 (columns=; a value not in it after them), else in the order
|                 the values come in the data. Eight colours safe for colour
|                 blindness (Okabe and Ito, without the yellow, and a grey),
|                 each with another marker and line pattern, so that groups
|                 differ in black and white too; a ninth group starts the list
|                 again. ID grp has all attributes; ID grpcol the colours only,
|                 solid lines (an error bar; a marker of its own, such as the
|                 censoring mark: give it to a copy of the group variable, as
|                 SGPLOT takes one ID per variable). The data get _ORDER, the
|                 place of their group.
| Used By       : the figure macros (%kmplot, %meanplot, %boxplot ...)
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| data        The rows of the figure: they get _ORDER             Required
| columns     The columns of %columns (COL, COLVALUE)             Optional
| var         The group variable                                  Required
| out         The attribute map                                   Required
|-------------------------------------------------------------------------------
|
| Output        : OUT: the attribute map: ID, VALUE, _ORDER and the attributes;
|                 DATA: data= with _ORDER.
|
| Example:
|
 %_spl_figure_attrs(data=_kmplot_plot, columns=&columns., var=&by., out=_kmplot_attrs)
|
|-------------------------------------------------------------------------------
| Change Log :
| Date        Programmer   Description
|-------------------------------------------------------------------------------
| 12-NOV-2026 Sapling      1.3.0: initial version (the figure macros).
| 16-NOV-2026 Sapling      1.9.0: the license line; the example in the house
|                          case (names in lower case). No number changes.
|
*******************************************************************************/
%MACRO _spl_figure_attrs(
     data    =   /* The rows of the figure: they get _ORDER */
   , columns =   /* The columns of %columns */
   , var     =   /* The group variable */
   , out     =   /* The attribute map */
) / DES = 'The colours, markers and line patterns of the groups of a figure';

  /* Step 1: each value of the group once, at its first row */
  DATA _figure_attrs_values;
    LENGTH value $200;
    SET &data.(KEEP=&var.);
    value = STRIP(VVALUE(&var.));
    _seen = _N_;
    KEEP value _seen;
  RUN;
  PROC SORT DATA=_figure_attrs_values NODUPKEY; BY value; RUN;

  /* Step 2: the order: the column of %columns, else the first row */
  %IF %LENGTH(&columns.) %THEN %DO;
    DATA _figure_attrs_cols;
      LENGTH value $200;
      SET &columns.(KEEP=col colvalue);
      value = colvalue;
      KEEP value col;
    RUN;
    PROC SORT DATA=_figure_attrs_cols NODUPKEY; BY value; RUN;
    DATA _figure_attrs_values;
      MERGE _figure_attrs_values(IN=indata) _figure_attrs_cols;
      BY value;
      IF indata;
    RUN;
  %END;
  %ELSE %DO;
    DATA _figure_attrs_values;
      SET _figure_attrs_values;
      col = .;
    RUN;
  %END;
  PROC SORT DATA=_figure_attrs_values; BY col _seen; RUN;

  /* Step 3: the attributes of the place of each group */
  DATA &out.;
    LENGTH id $8 value $200 markercolor linecolor fillcolor textcolor $8 markersymbol $16
           linepattern $24;
    SET _figure_attrs_values;
    _order = _N_;
    _k     = MOD(_order - 1, 8) + 1;
    markercolor = CHOOSEC(_k, 'CX0072B2', 'CXD55E00', 'CX009E73', 'CXCC79A7', 'CXE69F00',
                           'CX56B4E9', 'CX000000', 'CX777777');
    linecolor = markercolor;
    fillcolor = markercolor;
    textcolor = markercolor;
    linepattern = CHOOSEC(_k, 'Solid', 'ShortDash', 'LongDash', 'MediumDashShortDash', 'Dot',
                           'DashDashDot', 'LongDashShortDash', 'MediumDash');
    markersymbol = CHOOSEC(_k, 'CircleFilled', 'TriangleFilled', 'SquareFilled', 'DiamondFilled',
                           'Circle', 'Triangle', 'Square', 'Diamond');
    id = 'grp';
    OUTPUT;
    markersymbol = ' ';
    linepattern  = 'Solid';
    id           = 'grpcol';
    OUTPUT;
    KEEP id value _order markercolor linecolor fillcolor textcolor markersymbol linepattern;
  RUN;
  /* the rows of one ID together, as SGPLOT reads them */
  PROC SORT DATA=&out.; BY id _order; RUN;

  /* Step 4: the place of the group of each row of the data */
  DATA &data.;
    IF _N_ = 1 THEN DO;
      LENGTH value $200;
      _order = .;
      DECLARE HASH _h(DATASET: "&out.(WHERE=(id = 'grp'))");
      _h.DEFINEKEY('value');
      _h.DEFINEDATA('_order');
      _h.DEFINEDONE();
    END;
    SET &data.;
    value = STRIP(VVALUE(&var.));
    IF _h.FIND() NE 0 THEN _order = .;
    DROP value;
  RUN;

  /* Step 5: the work data sets are deleted */
  PROC DATASETS LIBRARY=work NOLIST NOWARN;
    DELETE _figure_attrs_:;
  QUIT;
%MEND _spl_figure_attrs;
