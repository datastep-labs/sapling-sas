/*******************************************************************************
| Macro Name    : _spl_total.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.9.1
| Created By    : Sapling
| Date          : 16NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : The name of the group of all groups together, from total=:
|                 nothing for no, Total for yes, else the text in quotes.
| Used By       : %describe, %freq, %columns (inner part)
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| total       The value of total= (no, yes, or a name in          Required
|             quotes)
|-------------------------------------------------------------------------------
|
| Output        : TEXT: nothing for no (or empty), Total for yes, else the text of the
|                 quotes.
|
| Example:
|
 %LET totlab = %_spl_total(%SUPERQ(total));
|
|-------------------------------------------------------------------------------
| Change Log :
| Date        Programmer   Description
|-------------------------------------------------------------------------------
| 12-NOV-2026 Sapling      1.0.0: initial version.
| 12-NOV-2026 Sapling      1.1.0: the house standard (docs/sas-style.md). No
|                          number changes.
| 16-NOV-2026 Sapling      1.9.0: the license line; the example in the house
|                          case (names in lower case). No number changes.
|
*******************************************************************************/
%MACRO _spl_total(
     total   /* The value of total=: no, yes, or a name in quotes */
) / DES = 'The name of the group of all groups together, from total=';
  %IF %LENGTH(%SUPERQ(total)) = 0 %THEN %RETURN;
  %IF %QUPCASE(%SUPERQ(total)) = YES %THEN Total;
  %ELSE %IF %QUPCASE(%SUPERQ(total)) ne NO %THEN %SYSFUNC(DEQUOTE(%SUPERQ(total)));
%MEND _spl_total;
