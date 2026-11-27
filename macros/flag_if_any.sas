/*******************************************************************************
| Macro Name    : flag_if_any.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.9.1
| Created By    : Sapling
| Date          : 16NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : Flag the subjects that have a record in another data set that
|                 meets a condition.
| Procedure     : PROC SORT, MERGE
| Proven        : the fixtures of the step kinds flag.condition, flag.any
|                 (src/adam_steps.ts; node tools/adam_steps_sas.ts); ran on SAS
|                 9.4 M9, 2026-11-12
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| data        The working data set (changed in place)             Required
| from        The data set of the records                         Required
| where       The condition on FROM, in parentheses               Required
| else        The value of the other subjects: N (default) or     N
|             blank
| new         The flag to make: Y for a subject with such a       Required
|             record
| debug       yes: keep the work data sets _flag_if_any_*         no
|-------------------------------------------------------------------------------
|
| Output        : DATA: NEW: Y on every row of a subject that has such a
|                 record in FROM, else N (or blank with else=blank), in the
|                 order of its rows.
|
| Example:
|
 %flag_if_any(
     data  = adsl
   , from  = sdtm.ds
   , where = (dsdecod = 'COMPLETED')
   , new   = complfl
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
| 16-NOV-2026 Sapling      1.9.0: the license line; the example in the house
|                          case (names in lower case). No number changes.
|
*******************************************************************************/
%MACRO flag_if_any(
     data  =     /* The working data set (changed in place) */
   , from  =     /* The data set of the records */
   , where =     /* The condition on FROM, in parentheses */
   , else  = N   /* The value of the other subjects: N or blank */
   , new   =     /* The flag to make: Y for a subject with a record */
   , debug = no  /* yes: keep the work data sets _flag_if_any_* */
) / DES = 'Flag the subjects with a record in another data set that meets a condition (PROC SORT)';
  %LOCAL t0;
  %LET t0 = %_spl_begin(flag_if_any);

  /* Step 1: the parameters */
  %IF not %_spl_need(flag_if_any, data from where new) %THEN %RETURN;
  %IF not %_spl_oneof(flag_if_any, debug, yes no) %THEN %RETURN;

  /* Step 2: the subjects with such a record */
  PROC SORT DATA=&from. OUT=_flag_if_any_hit(KEEP=usubjid) NODUPKEY;
    WHERE &where.;
    BY usubjid;
  RUN;

  /* Step 3: the rows keep their order: their number now; the flag of their subject */
  DATA &data.;
    SET &data.;
    _flag_if_any_row = _N_;
  RUN;
  PROC SORT DATA=&data.; BY usubjid; RUN;
  DATA &data.;
    MERGE &data.(IN=_inrows) _flag_if_any_hit(IN=_hit);
    BY usubjid;
    IF _inrows;
    LENGTH &new. $1;
    IF _hit THEN &new. = 'Y';
    %IF %UPCASE(&else.) = N %THEN %DO;
      ELSE &new. = 'N';
    %END;
  RUN;
  PROC SORT DATA=&data. OUT=&data.(DROP=_flag_if_any_row); BY _flag_if_any_row; RUN;

  /* Step 4: the work data sets are deleted (kept with debug=yes) */
  %IF %UPCASE(&debug.) ne YES %THEN %DO;
    PROC DATASETS LIBRARY=work NOLIST NOWARN;
      DELETE _flag_if_any_:;
    QUIT;
  %END;
  %_spl_end(flag_if_any, &t0., &debug.)
%MEND flag_if_any;
