/*******************************************************************************
| Macro Name    : flag_first.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.9.1
| Created By    : Sapling
| Date          : 27NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : Flags the first or last record of each group, among the
|                 records that meet a condition, with Y. Use %pick to copy the
|                 value of such a record to a subject. Use %flag_if_any to flag
|                 the subjects that have any record that meets a condition. The
|                 records of a group are sorted by order=. A missing sort key
|                 sorts last. Records with equal keys keep their order. The
|                 other records get a blank flag. The rows of data= keep their
|                 order.
| Procedure     : PROC SORT, MERGE
| Proven        : the fixtures of the step kind flag.extreme (src/adam_steps.ts;
|                 node tools/adam_steps_sas.ts); ran on SAS 9.4 M9, 2026-11-12
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| data        The data set to change in place, such as advs       Required
| where       The records that can be flagged: a condition in     Optional
|             parentheses, such as where = (anl01fl = 'Y'). When
|             not given, all records can be flagged.
| by          The groups: variables separated by blanks (by =     Required
|             usubjid paramcd)
| order       The sort keys within a group: variables separated   Required
|             by blanks; write descending before a key as in a
|             BY statement (order = descending adt)
| which       first or last: the record of the group that gets    first
|             the flag
| new         The name of the flag variable to make               Required
| debug       yes: keep the work data sets _flag_first_*          no
|-------------------------------------------------------------------------------
|
| Output        : DATA: data=, changed in place: the character variable new=
|                 ($1), Y on the first (or last) record of each group among the
|                 records that meet where=, blank on the other records.
|
| Example:
|
 DATA vs;
   SET advs;
   WHERE paramcd = 'SYSBP';
 RUN;
 %flag_first(
     data  = vs
   , where = (NOT MISSING(avisitn) AND NOT MISSING(aval))
   , by    = usubjid paramcd avisitn
   , order = ady atptn vsseq
   , new   = anl02fl
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
| 27-NOV-2026 Sapling      1.9.1: the example runs on the example data
|                          (sas/examples). The text of the header for the
|                          manual: the summary, the form of each parameter. No
|                          number changes.
| 27-NOV-2026 Sapling      1.9.1: The example first copies its records into a
|                          data set of its own, so that it changes no data set of
|                          setup.sas for a later example. No number changes.
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
