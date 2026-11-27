/*******************************************************************************
| Macro Name    : _spl_figure_label.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.9.1
| Created By    : Sapling
| Date          : 16NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : The label of an axis, as a text in quotes: the text given (in
|                 quotes, or put in quotes), else the label of the variable,
|                 else its name.
| Used By       : the figure macros (%kmplot, %meanplot, %boxplot ...)
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| _data       The data set                                        Required
| _var        The variable of the axis                            Optional
| _text       The text given, or nothing                          Optional
|-------------------------------------------------------------------------------
|
| Output        : TEXT: the label in double quotes.
|
| Example:
|
 %LET xlabel = %_spl_figure_label(&data., &time., %SUPERQ(xlabel));
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
%MACRO _spl_figure_label(
     _data   /* The data set */
   , _var    /* The variable of the axis */
   , _text   /* The text given, or nothing */
) / DES = 'The label of an axis, in quotes';
  %LOCAL dsid num lab rc first;
  %LET lab = %SUPERQ(_text);
  %IF %LENGTH(&lab.) %THEN %DO;
    %LET first = %QSUBSTR(&lab., 1, 1);
    %IF %SUPERQ(first) = %STR(%") or %SUPERQ(first) = %STR(%') %THEN
      %LET lab = %QSYSFUNC(DEQUOTE(&lab.));
  %END;
  %ELSE %IF %LENGTH(&_var.) %THEN %DO;
    %LET dsid = %SYSFUNC(OPEN(%SCAN(&_data., 1, %STR(%())));
    %IF &dsid. %THEN %DO;
      %LET num = %SYSFUNC(VARNUM(&dsid., &_var.));
      %IF &num. %THEN %LET lab = %QSYSFUNC(VARLABEL(&dsid., &num.));
      %LET rc = %SYSFUNC(CLOSE(&dsid.));
    %END;
    %IF %LENGTH(&lab.) = 0 %THEN %LET lab = %UPCASE(&_var.);
  %END;
  %UNQUOTE(%QSYSFUNC(QUOTE(&lab.)))
%MEND _spl_figure_label;
