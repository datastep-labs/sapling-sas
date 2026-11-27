/*******************************************************************************
| Macro Name    : _spl_figure_close.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.10.0
| Created By    : Sapling
| Date          : 16NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : Close the destinations of a figure (%_spl_figure_open) and set
|                 back what it changed: the RTF file closed, LISTING closed and
|                 opened again (its style LISTING) when it was open before, the
|                 options of ODS GRAPHICS reset.
| Used By       : the figure macros (%kmplot, %forestplot, %meanplot ...)
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| listing     yes: LISTING was open before the figure             no
|-------------------------------------------------------------------------------
|
| Output        : CODE: the ODS statements that close the destinations.
|
| Example:
|
 %_spl_figure_close(listing=&listing.)
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
%MACRO _spl_figure_close(
     listing = no   /* yes: LISTING was open before the figure */
) / DES = 'Close the destinations of a figure and set back what it changed';
  ODS RTF CLOSE;
  ODS LISTING CLOSE;
  ODS GRAPHICS / RESET=all;
  %IF &listing. = yes %THEN %DO;
    ODS LISTING STYLE=listing;
  %END;
%MEND _spl_figure_close;
