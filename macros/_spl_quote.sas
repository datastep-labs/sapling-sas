/*******************************************************************************
| Macro Name    : _spl_quote.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.10.0
| Created By    : Sapling
| Date          : 27NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : The value of a parameter as a text in single quotes, for a
|                 DATA step: each single quote in it doubled, nothing in it
|                 resolved. The code the macro writes holds the value itself
|                 (SYMGET would read it when the step runs), so that the flat
|                 program (the code the macros wrote, without a macro) has it
|                 too. An empty value gives a blank text.
| Used By       : %_spl_pairlist, the label= of the macros a
|                 person calls (inner part)
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| _param      The name of the parameter (label, pairs)            Required
|-------------------------------------------------------------------------------
|
| Output        : TEXT: a text in single quotes: 'Age (years)', '"A" "B" # "C" "B"'.
|
| Example:
|
 block = DEQUOTE(%_spl_quote(label));
|
|-------------------------------------------------------------------------------
| Change Log :
| Date        Programmer   Description
|-------------------------------------------------------------------------------
| 12-NOV-2026 Sapling      1.1.0: initial version (the flat programs had no
|                          pairs and no labels: SYMGET read them at run time).
| 16-NOV-2026 Sapling      1.9.0: the license line; the example in the house
|                          case (names in lower case). No number changes.
| 27-NOV-2026 Sapling      1.10.0: The header names no internal tool. No number
|                          changes.
|
*******************************************************************************/
%MACRO _spl_quote(
     _param     /* The name of the parameter */
) / DES = 'The value of a parameter as a text in single quotes (DATA step code)';
  %IF %LENGTH(%SUPERQ(&_param.)) = 0 %THEN %DO;
    ' '
  %END;
  %ELSE %DO;
    %UNQUOTE(%STR(%')%QSYSFUNC(TRANWRD(%SUPERQ(&_param.), %STR(%'), %STR(%'%')))%STR(%'))
  %END;
%MEND _spl_quote;
