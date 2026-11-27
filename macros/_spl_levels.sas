/*******************************************************************************
| Macro Name    : _spl_levels.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.9.1
| Created By    : Sapling
| Date          : 16NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : The planned categories of some variables as rows: every
|                 combination of their values, by DO loops. A character variable
|                 gets the length $200.
| Used By       : %freq, %proportion (inner part)
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| data        The data set of the variables (it tells which ones  Required
|             are character)
| levels      Each variable followed by its values: a text in     Required
|             quotes, a number without
| order       A prefix: the place of each value in its list as    Optional
|             the variables <prefix>1, <prefix>2 ... (one for
|             each variable, in the order of levels=)
|-------------------------------------------------------------------------------
|
| Output        : CODE: DATA step statements: LENGTH of the character variables
|                 ($200), then DO loops that output every combination of the
|                 planned values (DO BNRIND = ...; DO ANRIND = ...; OUTPUT; END;
|                 END;); with order= also the place of each value in its list.
|
| Example:
|
 DATA levels;
   %_spl_levels(levels=bnrind 'LOW' 'NORMAL' 'HIGH' anrind 'LOW' 'NORMAL' 'HIGH', data=adlbc)
 RUN;
|
|-------------------------------------------------------------------------------
| Change Log :
| Date        Programmer   Description
|-------------------------------------------------------------------------------
| 11-NOV-2026 Sapling      1.0.0: initial version.
| 12-NOV-2026 Sapling      1.1.0: the house standard (docs/sas-style.md). No
|                          number changes.
| 16-NOV-2026 Sapling      1.9.0: order=: the place of each value in its list.
|                          The license line; the example in the house case.
|
*******************************************************************************/
%MACRO _spl_levels(
     data   =   /* The data set of the variables */
   , levels =   /* Each variable followed by its values */
   , order  =   /* A prefix: the place of each value as <prefix>1 ... */
) / DES = 'The planned categories of some variables as rows (DATA step statements)';
  %LOCAL _i _w _nvar _k _names _chars;
  %LET _nvar = 0;
  %DO _i = 1 %TO %SYSFUNC(COUNTW(%SUPERQ(levels), %STR( ), q));
    %LET _w = %QSCAN(%SUPERQ(levels), &_i., %STR( ), q);
    %IF %SYSFUNC(NVALID(&_w., v7)) %THEN %DO;
      /* a variable: its values follow */
      %LET _nvar = %EVAL(&_nvar. + 1);
      %LOCAL _var&_nvar. _vals&_nvar.;
      %LET _var&_nvar. = %UPCASE(&_w.);
      %LET _names = &_names. %UPCASE(&_w.);
    %END;
    %ELSE %IF %LENGTH(%SUPERQ(_vals&_nvar.)) %THEN %LET _vals&_nvar. = &&_vals&_nvar., &_w.;
    %ELSE %LET _vals&_nvar. = &_w.;
  %END;
  %LET _chars = %_spl_chars(&data., &_names.);
  %IF %LENGTH(&_chars.) %THEN %DO;
    LENGTH &_chars. $200;
  %END;
  %DO _k = 1 %TO &_nvar.;
    %IF %LENGTH(&order.) %THEN %DO;
      &order.&_k. = 0;
    %END;
    DO &&_var&_k. = %UNQUOTE(&&_vals&_k.);
      %IF %LENGTH(&order.) %THEN %DO;
        &order.&_k. = &order.&_k. + 1;
      %END;
  %END;
  OUTPUT;
  %DO _k = 1 %TO &_nvar.;
    END;
  %END;
%MEND _spl_levels;
