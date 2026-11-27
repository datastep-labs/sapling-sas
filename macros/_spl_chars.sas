/*******************************************************************************
| Macro Name    : _spl_chars.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.10.0
| Created By    : Sapling
| Date          : 16NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : The character variables among some variables of a data set
|                 (their names, separated by blanks). The statistics macros give
|                 them one length ($200) in their results, so that results stack
|                 without a cut value.
| Used By       : the statistics macros (inner part)
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| data        The data set (data set options after it are         Required
|             ignored)
| vars        The variables                                       Required
|-------------------------------------------------------------------------------
|
| Output        : TEXT: the names of the character variables among VARS, separated by
|                 blanks (a variable not in DATA is left out).
|
| Example:
|
 %LET chars = %_spl_chars(adae, TRT01A AEBODSYS AEDECOD AVISITN);
|
|-------------------------------------------------------------------------------
| Change Log :
| Date        Programmer   Description
|-------------------------------------------------------------------------------
| 11-NOV-2026 Sapling      1.0.0: initial version.
| 12-NOV-2026 Sapling      1.1.0: the house standard (docs/sas-style.md). No
|                          number changes.
| 16-NOV-2026 Sapling      1.9.0: the license line; the example in the house
|                          case (names in lower case). No number changes.
|
*******************************************************************************/
%MACRO _spl_chars(
     data   /* The data set (its options are ignored) */
   , vars   /* The variables */
) / DES = 'The character variables among some variables of a data set';
  %LOCAL _dsid _i _v _num _list;
  %LET _dsid = %SYSFUNC(OPEN(%SCAN(&data., 1, %STR(%())));
  %IF &_dsid. %THEN %DO;
    %DO _i = 1 %TO %SYSFUNC(COUNTW(&vars., %STR( )));
      %LET _v   = %SCAN(&vars., &_i., %STR( ));
      %LET _num = %SYSFUNC(VARNUM(&_dsid., &_v.));
      %IF &_num. > 0 %THEN %DO;
        %IF %SYSFUNC(VARTYPE(&_dsid., &_num.)) = C %THEN %LET _list = &_list. &_v.;
      %END;
    %END;
    %LET _dsid = %SYSFUNC(CLOSE(&_dsid.));
  %END;
  &_list.
%MEND _spl_chars;
