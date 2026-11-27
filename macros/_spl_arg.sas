/*******************************************************************************
| Macro Name    : _spl_arg.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.10.0
| Created By    : Sapling
| Date          : 16NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : One parameter of a call that a one-call table writes into its long
|                 program: its name and its value. A parameter without a value is
|                 left out.
| Used By       : the one-call tables %table_* (inner part)
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| _name       The name of the parameter in the call; without      Required
|             _value also the parameter of the calling macro
|             whose value is written
| _value      A DATA step expression with the value (a text)      Optional
|-------------------------------------------------------------------------------
|
| Output        : CODE: DATA step statements that add the parameter to the arrays
|                 PN and PV of %_spl_program(begin).
|
| Example:
|
 %_spl_arg(data, "&rec.")
 %_spl_arg(where)
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
%MACRO _spl_arg(
     _name      /* The name of the parameter in the call */
   , _value     /* A DATA step expression with its value */
) / DES = 'One parameter of a call in the long program of a one-call table (DATA step statements)';
  %IF %LENGTH(%SUPERQ(_value)) %THEN %DO;
    part = &_value.;
  %END;
  %ELSE %DO;
    part = %_spl_quote(&_name.);
  %END;
  IF part NE ' ' THEN DO;
    n     = n + 1;
    pn{n} = "&_name.";
    pv{n} = part;
  END;
%MEND _spl_arg;
