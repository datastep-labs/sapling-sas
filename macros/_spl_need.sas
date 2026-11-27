/*******************************************************************************
| Macro Name    : _spl_need.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.10.0
| Created By    : Sapling
| Date          : 16NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : Check the parameters a macro needs: each must have a value, and
|                 a data set of data=, denom=, columns= or from= must exist. For
|                 each one that does not it writes one line that names the
|                 parameter and the fix:
|                   ERROR: [describe] data= is required: give data=<value> ...
|                   ERROR: [describe] data=adsx does not exist: give data= ...
|                 It gives 1 when all are there, 0 when one is not: the caller
|                 then stops (%RETURN).
| Used By       : every macro a person calls (inner part)
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| _macro      The name of the calling macro (for the message)     Required
| _params     The names of its parameters that must have a        Required
|             value
|-------------------------------------------------------------------------------
|
| Output        : TEXT: 1 or 0, as text.
|
| Example:
|
 %IF not %_spl_need(describe, data var by out) %THEN %RETURN;
|
|-------------------------------------------------------------------------------
| Change Log :
| Date        Programmer   Description
|-------------------------------------------------------------------------------
| 11-NOV-2026 Sapling      1.0.0: initial version.
| 12-NOV-2026 Sapling      1.1.0: the house standard; the data sets of from=,
|                          windows= and visits= are checked too; each message
|                          names the fix.
| 12-NOV-2026 Sapling      1.3.0: columns= is a data set that must exist (the
|                          figure macros).
| 13-NOV-2026 Sapling      1.7.0: windows= and visits= are the rows of a call,
|                          no data sets.
| 16-NOV-2026 Sapling      1.9.0: the license line; the example in the house
|                          case (names in lower case). No number changes.
|
*******************************************************************************/
%MACRO _spl_need(
     _macro     /* The name of the calling macro */
   , _params    /* Its parameters that must have a value */
) / DES = 'Check the parameters a macro needs';
  %LOCAL _i _p _ds _ok;
  %LET _ok = 1;
  %DO _i = 1 %TO %SYSFUNC(COUNTW(&_params., %STR( )));
    %LET _p = %SCAN(&_params., &_i., %STR( ));
    %IF %LENGTH(%SUPERQ(&_p.)) = 0 %THEN %DO;
      %PUT %STR(ERR)OR: [&_macro.] &_p.= is required;
      %PUT %STR(ERR)OR: [&_macro.]   fix: give &_p.=<value> (see &_macro..sas).;
      %LET _ok = 0;
    %END;
    %ELSE %IF %SYSFUNC(INDEXW(data denom columns from, &_p.)) %THEN %DO;
      %LET _ds = %SCAN(%SUPERQ(&_p.), 1, %STR(%());
      %IF not %SYSFUNC(EXIST(&_ds.)) %THEN %DO;
        %PUT %STR(ERR)OR: [&_macro.] &_p.=&_ds. does not exist;
        %PUT %STR(ERR)OR: [&_macro.]   fix: give &_p.= a data set that exists (make it first).;
        %LET _ok = 0;
      %END;
    %END;
  %END;
  &_ok.
%MEND _spl_need;
