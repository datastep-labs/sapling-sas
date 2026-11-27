/*******************************************************************************
| Macro Name    : _spl_vars.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.9.1
| Created By    : Sapling
| Date          : 16NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : Check that the variables of some parameters are variables of a
|                 data set. For each one that is not it writes one line that names
|                 the parameter and the fix:
|                   ERROR: [describe] var=AGEX is not a variable of adsl: give ...
|                 It gives 1 when all are there, 0 when one is not: the caller
|                 then stops (%RETURN). A data set that cannot be opened is the
|                 business of %_spl_need. With _also (the subjects adsl= of a
|                 one-call table, whose variables go to the records) a variable
|                 of either data set is there.
| Used By       : the macros a person calls (inner part)
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| _macro      The name of the calling macro (for the message)     Required
| _data       The parameter that names the data set (data,        Required
|             denom)
| _params     The parameters whose values are variables of it     Required
| _also       The parameter that names a second data set where    Optional
|             the variables may be (adsl)
|-------------------------------------------------------------------------------
|
| Output        : TEXT: 1 or 0, as text.
|
| Example:
|
 %IF not %_spl_vars(describe, data, var by) %THEN %RETURN;
 %IF not %_spl_vars(table_ae, data, var by, adsl) %THEN %RETURN;
|
|-------------------------------------------------------------------------------
| Change Log :
| Date        Programmer   Description
|-------------------------------------------------------------------------------
| 12-NOV-2026 Sapling      1.1.0: initial version.
| 16-NOV-2026 Sapling      1.9.0: the license line; the example in the house
|                          case (names in lower case). No number changes.
| 16-NOV-2026 Sapling      1.9.1: _also: a variable of a second data set (adsl=
|                          of a one-call table) is there too (DEV-031). No
|                          number changes.
|
*******************************************************************************/
%MACRO _spl_vars(
     _macro     /* The name of the calling macro */
   , _data      /* The parameter that names the data set */
   , _params    /* The parameters whose values are its variables */
   , _also      /* A second data set where they may be (adsl) */
) / DES = 'Check that variables are in a data set';
  %LOCAL _ok _ds _dsid _i _j _p _list _v _rc _ds2 _dsid2 _in;
  %LET _ok    = 1;
  %LET _ds    = %SCAN(%SUPERQ(&_data.), 1, %STR(%());
  %LET _dsid  = %SYSFUNC(OPEN(&_ds.));
  %LET _dsid2 = 0;
  %IF %LENGTH(&_also.) %THEN %DO;
    %LET _ds2 = %SCAN(%SUPERQ(&_also.), 1, %STR(%());
    %IF %LENGTH(&_ds2.) %THEN %LET _dsid2 = %SYSFUNC(OPEN(&_ds2.));
  %END;
  %LET _in = &_ds.;  /* the data sets named in the message */
  %IF &_dsid2. %THEN %LET _in = &_ds. or &_ds2.;
  %IF &_dsid. %THEN %DO;
    %DO _i = 1 %TO %SYSFUNC(COUNTW(&_params., %STR( )));
      %LET _p    = %SCAN(&_params., &_i., %STR( ));
      %LET _list = %SUPERQ(&_p.);
      %DO _j = 1 %TO %SYSFUNC(COUNTW(&_list.%STR( ), %STR( )));
        %LET _v = %SCAN(&_list., &_j., %STR( ));
        %IF %SYSFUNC(VARNUM(&_dsid., &_v.)) = 0 %THEN %DO;
          %IF &_dsid2. = 0 %THEN %DO;
            %PUT %STR(ERR)OR: [&_macro.] &_p.=&_v. is not a variable of &_in.;
            %PUT %STR(ERR)OR: [&_macro.]   fix: give &_p.= a variable of &_data.=.;
            %LET _ok = 0;
          %END;
          %ELSE %IF %SYSFUNC(VARNUM(&_dsid2., &_v.)) = 0 %THEN %DO;
            %PUT %STR(ERR)OR: [&_macro.] &_p.=&_v. is not a variable of &_in.;
            %PUT %STR(ERR)OR: [&_macro.]   fix: give &_p.= a variable of &_data.= or &_also.=.;
            %LET _ok = 0;
          %END;
        %END;
      %END;
    %END;
    %LET _rc = %SYSFUNC(CLOSE(&_dsid.));
  %END;
  %IF &_dsid2. %THEN %LET _rc = %SYSFUNC(CLOSE(&_dsid2.));
  &_ok.
%MEND _spl_vars;
