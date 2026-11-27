/*******************************************************************************
| Macro Name    : _spl_figure_outpar.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.9.1
| Created By    : Sapling
| Date          : 16NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : The drawing parameters of a figure macro as a data set (its
|                 outpar=): one row per parameter in the order of the
|                 signature, PARAMETER its name in lower case and VALUE its
|                 value as the macro draws it (given, from par=, the default,
|                 or made by the macro: the label of an axis, the format of
|                 the ticks). par= of a later call reads it back.
| Used By       : the figure macros (%kmplot, %forestplot, %meanplot ...)
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| names       The drawing parameters of the caller, in their      Required
|             order (names= of %_spl_figure_par)
| out         The data set to write; blank: none                  Optional
|-------------------------------------------------------------------------------
|
| Output        : DATA: out= with PARAMETER ($32) and VALUE ($500).
|
| Example:
|
 %_spl_figure_outpar(names=&drawn., out=&outpar.)
|
|-------------------------------------------------------------------------------
| Change Log :
| Date        Programmer   Description
|-------------------------------------------------------------------------------
| 13-NOV-2026 Sapling      1.6.0: initial version (plot=, par= and outpar= of
|                          the figure macros).
| 16-NOV-2026 Sapling      1.9.0: the license line; the example in the house
|                          case (names in lower case). No number changes.
|
*******************************************************************************/
%MACRO _spl_figure_outpar(
     names =   /* The drawing parameters of the caller, in their order */
   , out   =   /* The data set to write; blank: none */
) / DES = 'Write the drawing parameters of a figure macro as a data set';
  %LOCAL _i _name;
  %IF %LENGTH(&out.) = 0 %THEN %RETURN;
  DATA &out.;
    LENGTH parameter $32 value $500;
    %DO _i = 1 %TO %SYSFUNC(COUNTW(&names., %STR( )));
      %LET _name = %SCAN(&names., &_i., %STR( ));
      parameter = "&_name.";
      value     = %_spl_quote(&_name.);
      OUTPUT;
    %END;
  RUN;
%MEND _spl_figure_outpar;
