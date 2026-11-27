/*******************************************************************************
| Macro Name    : _spl_call.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.10.0
| Created By    : Sapling
| Date          : 16NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : One call of a macro in the long program of a one-call table: the
|                 parameters given by %_spl_arg since the last call, one per line, the
|                 equal signs under each other.
| Used By       : the one-call tables %table_* (inner part)
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| _macro      The name of the macro called, without the percent   Required
|             sign
|-------------------------------------------------------------------------------
|
| Output        : CODE: DATA step statements that write the call to the file of the
|                 long program and start the next list of parameters.
|
| Example:
|
 %_spl_call(freq)
|
|-------------------------------------------------------------------------------
| Change Log :
| Date        Programmer   Description
|-------------------------------------------------------------------------------
| 13-NOV-2026 Sapling      1.8.0: initial version.
| 16-NOV-2026 Sapling      1.9.0: the license line; the example in the house
|                          case (names in lower case). No number changes.
|
*******************************************************************************/
%MACRO _spl_call(
     _macro     /* The name of the macro called */
) / DES = 'One call of a macro in the long program of a one-call table (DATA step statements)';
  macro = '%' || "&_macro.";
  LINK call;
  n = 0;
%MEND _spl_call;
