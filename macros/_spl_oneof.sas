/*******************************************************************************
| Macro Name    : _spl_oneof.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.10.0
| Created By    : Sapling
| Date          : 16NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : Check that the value of a parameter is one of a list (in any
|                 case). When it is not it writes one line that names the
|                 parameter and the fix:
|                   ERROR: [cox] ties=fast is not one of efron breslow exact ...
|                 It gives 1 or 0: the caller then stops (%RETURN).
| Used By       : the macros a person calls (inner part)
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| _macro      The name of the calling macro (for the message)     Required
| _param      The parameter                                       Required
| _list       Its values, separated by blanks                     Required
|-------------------------------------------------------------------------------
|
| Output        : TEXT: 1 or 0, as text.
|
| Example:
|
 %IF not %_spl_oneof(cox, ties, efron breslow exact discrete) %THEN %RETURN;
|
|-------------------------------------------------------------------------------
| Change Log :
| Date        Programmer   Description
|-------------------------------------------------------------------------------
| 12-NOV-2026 Sapling      1.1.0: initial version.
| 16-NOV-2026 Sapling      1.9.0: the license line; the example in the house
|                          case (names in lower case). No number changes.
|
*******************************************************************************/
%MACRO _spl_oneof(
     _macro     /* The name of the calling macro */
   , _param     /* The parameter */
   , _list      /* Its values, separated by blanks */
) / DES = 'Check that a parameter is one of a list';
  %LOCAL _ok _v;
  %LET _ok = 0;
  %LET _v  = %QUPCASE(%SUPERQ(&_param.));
  %IF %LENGTH(&_v.) %THEN %DO;
    %IF %SYSFUNC(INDEXW(%UPCASE(&_list.), &_v.)) %THEN %LET _ok = 1;
  %END;
  %IF not &_ok. %THEN %DO;
    %PUT %STR(ERR)OR: [&_macro.] &_param.=&_v. is not one of: &_list.;
    %PUT %STR(ERR)OR: [&_macro.]   fix: give &_param.= one of them.;
  %END;
  &_ok.
%MEND _spl_oneof;
