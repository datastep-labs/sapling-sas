/*******************************************************************************
| Macro Name    : flag_first.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.9.1
| Created By    : Sapling
| Date          : 16NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : Flag one record of each group: the first (or last) one, among
|                 the records that meet a condition. The other records keep a
|                 blank flag.
| Procedure     : PROC SORT, MERGE
| Proven        : the fixtures of the step kind flag.extreme (src/adam_steps.ts;
|                 node tools/adam_steps_sas.ts); ran on SAS 9.4 M9, 2026-11-12
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| data        The working data set (changed in place)             Required
| where       The records that can be chosen, a condition in      Optional
|             parentheses
| by          The groups                                          Required
| order       The sort keys within a group; "descending" before   Required
|             a key as in a BY statement. A missing key sorts
|             last; records with equal keys keep their order.
| which       first (default) or last                             first
| new         The flag to make (Y on the chosen record)           Required
| debug       yes: keep the work data sets _flag_first_*          no
|-------------------------------------------------------------------------------
|
| Output        : DATA: NEW: Y on the first (last) record of each group
|                 among the records that meet where=; the others keep a blank
|                 NEW. The rows keep their order.
|
| Example:
|
 %flag_first(
     data  = advs
   , where = (NOT MISSING(avisitn) AND NOT MISSING(aval))
   , by    = usubjid paramcd avisitn
   , order = awtdiff ady vsseq
   , new   = anl01fl
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
| 13-NOV-2026 Sapling      1.7.1: order= is checked as required.
| 16-NOV-2026 Sapling      1.9.0: the license line; the example in the house
|                          case (names in lower case). No number changes.
|
*******************************************************************************/
%MACRO flag_first(
     data  =         /* The working data set (changed in place) */
   , where =         /* The records that can be chosen, in parentheses */
   , by    =         /* The groups */
   , order =         /* The sort keys within a group */
   , which = first   /* first or last */
   , new   =         /* The flag to make (Y on the chosen record) */
   , debug = no      /* yes: keep the work data sets _flag_first_* */
) / DES = 'Flag the first or last record of each group that meets a condition (PROC SORT, MERGE)';
  %LOCAL t0 i token bykeys n desc lastby;
  %LET t0 = %_spl_begin(flag_first);

  /* Step 1: the parameters */
  %IF not %_spl_need(flag_first, data new by order) %THEN %RETURN;
  %IF not %_spl_vars(flag_first, data, by) %THEN %RETURN;
  %IF not %_spl_oneof(flag_first, which, first last) %THEN %RETURN;
  %IF not %_spl_oneof(flag_first, debug, yes no) %THEN %RETURN;

  %LET lastby = %SCAN(&by., -1, %STR( ));  /* the last variable of by= */

  /* Step 2: the rows keep their order: their number now */
  DATA &data.;
    SET &data.;
    _flag_first_row = _N_;
  RUN;

  /* Step 3: the records that can be chosen, with their sort keys (a missing key last) */
  DATA _flag_first_records;
    SET &data.;
    %IF %LENGTH(%SUPERQ(where)) %THEN %DO;
      IF &where.;
    %END;
    %LET n    = 0;
    %LET desc = ;
    %DO i = 1 %TO %SYSFUNC(COUNTW(&order., %STR( )));
      %LET token = %SCAN(&order., &i., %STR( ));
      %IF %UPCASE(&token.) = DESCENDING %THEN %LET desc = descending;
      %ELSE %DO;
        %LET n = %EVAL(&n. + 1);
        _MISSING&n. = MISSING(&token.);
        %LET bykeys = &bykeys. _missing&n. &desc. &token.;
        %LET desc   = ;
      %END;
    %END;
  RUN;
  PROC SORT DATA=_flag_first_records; BY &by. &bykeys. _flag_first_row; RUN;

  /* Step 4: the first (last) record of each group, flagged on its row */
  DATA _flag_first_chosen(KEEP=_flag_first_row);
    SET _flag_first_records;
    BY &by.;
    IF &which..&lastby.;
  RUN;
  PROC SORT DATA=_flag_first_chosen; BY _flag_first_row; RUN;
  DATA &data.;
    MERGE &data.(IN=_inrows) _flag_first_chosen(IN=_picked);
    BY _flag_first_row;
    IF _inrows;
    LENGTH &new. $1;
    IF _picked THEN &new. = 'Y';
    DROP _flag_first_row;
  RUN;

  /* Step 5: the work data sets are deleted (kept with debug=yes) */
  %IF %UPCASE(&debug.) ne YES %THEN %DO;
    PROC DATASETS LIBRARY=work NOLIST NOWARN;
      DELETE _flag_first_:;
    QUIT;
  %END;
  %_spl_end(flag_first, &t0., &debug.)
%MEND flag_first;
