/*******************************************************************************
| Macro Name    : merge_subject.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.9.1
| Created By    : Sapling
| Date          : 16NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : Copy variables from another data set by subject (USUBJID). The
|                 other data set has one row per subject; the rows of DATA stay
|                 as they are, in their order.
| Procedure     : PROC SORT, MERGE
| Proven        : the fixtures of the step kinds copy, period
|                 (src/adam_steps.ts; node tools/adam_steps_sas.ts); ran on SAS
|                 9.4 M9, 2026-11-12
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| data        The working data set (changed in place)             Required
| from        The data set to copy from                           Required
| vars        The variables, separated by blanks; NEW=OLD copies  Required
|             under another name
| debug       yes: keep the work data sets _merge_subject_*       no
|-------------------------------------------------------------------------------
|
| Output        : DATA: the variables of FROM of its subject on every row,
|                 in the order of its rows; a subject not in FROM gets missing
|                 values.
|
| Example:
|
 %merge_subject(
     data = advs
   , from = adam.adsl
   , vars = age sex trtp=trt01p trtpn=trt01pn
 )
|
|-------------------------------------------------------------------------------
| Change Log :
| Date        Programmer   Description
|-------------------------------------------------------------------------------
| 11-NOV-2026 Sapling      1.0.0: initial version.
| 12-NOV-2026 Sapling      1.0.0: ran on SAS 9.4 M9.
| 12-NOV-2026 Sapling      1.1.0: the house standard (docs/sas-style.md). No
|                          number changes.
| 13-NOV-2026 Sapling      1.7.1: from= with more than one row of a subject is
|                          an error; data= is not changed.
| 16-NOV-2026 Sapling      1.9.0: the license line; the example in the house
|                          case (names in lower case). No number changes.
| 16-NOV-2026 Sapling      1.9.1: vars= is checked against from= (DEV-026). No
|                          number changes.
|
*******************************************************************************/
%MACRO merge_subject(
     data  =     /* The working data set (changed in place) */
   , from  =     /* The data set to copy from, one row per subject */
   , vars  =     /* The variables; NEW=OLD copies under another name */
   , debug = no  /* yes: keep the work data sets _merge_subject_* */
) / DES = 'Copy variables from another data set by subject (PROC SORT, MERGE)';
  %LOCAL t0 i item new old keep rename twice dsid bad;
  %LET t0 = %_spl_begin(merge_subject);

  /* Step 1: the parameters; the variables to keep and to rename */
  %IF not %_spl_need(merge_subject, data from vars) %THEN %RETURN;
  %IF not %_spl_oneof(merge_subject, debug, yes no) %THEN %RETURN;

  %DO i = 1 %TO %SYSFUNC(COUNTW(&vars., %STR( )));
    %LET item = %SCAN(&vars., &i., %STR( ));
    %LET new  = %SCAN(&item., 1, =);
    %LET old  = %SCAN(&item., 2, =);
    %IF %LENGTH(&old.) = 0 %THEN %LET old = &new.;
    %LET keep = &keep. &old.;
    %IF %UPCASE(&new.) ne %UPCASE(&old.) %THEN %LET rename = &rename. &old.=&new.;
  %END;
  /* the variables of vars= (the old names of new=old) are in from= */
  %LET dsid = %SYSFUNC(OPEN(%SCAN(&from., 1, %STR(%())));
  %IF &dsid. %THEN %DO;
    %DO i = 1 %TO %SYSFUNC(COUNTW(&keep., %STR( )));
      %LET old = %SCAN(&keep., &i., %STR( ));
      %IF %SYSFUNC(VARNUM(&dsid., &old.)) = 0 %THEN %LET bad = &bad. &old.;
    %END;
    %LET dsid = %SYSFUNC(CLOSE(&dsid.));
  %END;
  %IF %LENGTH(&bad.) %THEN %DO;
    %PUT %STR(ERR)OR: [merge_subject] vars=&bad. is not a variable of %SCAN(&from., 1, %STR(%());
    %PUT %STR(ERR)OR: [merge_subject]   fix: give vars= variables of from= (new=old to rename one).;
    %RETURN;
  %END;

  /* Step 2: the variables of each subject in FROM */
  PROC SORT DATA=&from.(KEEP=usubjid &keep.) OUT=_merge_subject_vars
    %IF %LENGTH(&rename.) %THEN %DO;
      (rename=(&rename.))
    %END;
    ;
    BY usubjid;
  RUN;
  DATA _NULL_;
    SET _merge_subject_vars;
    BY usubjid;
    IF NOT (FIRST.usubjid AND LAST.usubjid) THEN CALL SYMPUTX('twice', usubjid, 'L');
  RUN;
  %IF %LENGTH(&twice.) %THEN %DO;
    %PUT %STR(ERR)OR: [merge_subject] from=&from. has more than one row of a subject (&twice.).;
    %PUT %STR(ERR)OR: [merge_subject]   fix: give from= one row per subject, or use pick.sas.;
    %GOTO finish;
  %END;

  /* Step 3: the rows keep their order: their number now; the variables of their subject */
  DATA &data.;
    SET &data.;
    _merge_subject_row = _N_;
  RUN;
  PROC SORT DATA=&data.; BY usubjid; RUN;
  DATA &data.;
    MERGE &data.(IN=_inrows) _merge_subject_vars;
    BY usubjid;
    IF _inrows;
  RUN;
  PROC SORT DATA=&data. OUT=&data.(DROP=_merge_subject_row); BY _merge_subject_row; RUN;

  /* Step 4: the work data sets are deleted (kept with debug=yes) */
  %finish:
  %IF %UPCASE(&debug.) ne YES %THEN %DO;
    PROC DATASETS LIBRARY=work NOLIST NOWARN;
      DELETE _merge_subject_:;
    QUIT;
  %END;
  %_spl_end(merge_subject, &t0., &debug.)
%MEND merge_subject;
