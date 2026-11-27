/*******************************************************************************
| Macro Name    : pick.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.9.1
| Created By    : Sapling
| Date          : 16NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : Give each subject the value of its first (or last) record in
|                 another data set.
| Procedure     : PROC SORT, MERGE
| Proven        : the fixtures of the step kinds derive.from.one,
|                 derive.from.extreme, ice (src/adam_steps.ts; node
|                 tools/adam_steps_sas.ts); ran on SAS 9.4 M9, 2026-11-12
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| data        The working data set (changed in place)             Required
| from        The data set of the records. Prepare it with a      Required
|             DATA step when the value or a sort key is not a
|             variable yet (a date of a text, a difference).
| value       The variable of FROM that gives the value           Required
| order       The sort keys within a subject; "descending"        Optional
|             before a key as in a BY statement. A missing key
|             sorts last. Without order: the first record as the
|             data are.
| which       first (default) or last                             first
| length      The length of a text variable, e.g. $40             Optional
| format      The format, e.g. date9                              Optional
| unique      yes: each subject has at most one record in FROM    no
|             (the plan names one record and no order); two
|             records are an ERROR. Default no.
| new         The variable to make                                Required
| debug       yes: keep the work data sets _pick_*                no
|-------------------------------------------------------------------------------
|
| Output        : DATA: NEW on every row of a subject: the value of its
|                 first (or last) record in FROM; missing for a subject without
|                 a record. With unique=yes two records of a subject are an
|                 ERROR that names the subject.
|
| Example:
|
 %pick(
     data   = adsl
   , from   = ex
   , value  = exstdt
   , order  = exstdt exseq
   , which  = first
   , format = date9.
   , new    = trtsdt
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
| 13-NOV-2026 Sapling      1.7.1: the error of unique=yes names the subject in
|                          its line, the fix on the next line.
| 16-NOV-2026 Sapling      1.9.0: a variable new= that data= has already is
|                          replaced, with a NOTE (a subject without a value kept
|                          its old value). The license line; the example in the
|                          house case.
|
*******************************************************************************/
%MACRO pick(
     data   =         /* The working data set (changed in place) */
   , from   =         /* The data set of the records */
   , value  =         /* The variable of FROM that gives the value */
   , order  =         /* The sort keys within a subject */
   , which  = first   /* first or last */
   , length =         /* The length of a text variable, e.g. $40 */
   , format =         /* The format, e.g. date9. */
   , unique = no      /* yes: each subject has at most one record */
   , new    =         /* The variable to make */
   , debug  = no      /* yes: keep the work data sets _pick_* */
) / DES = 'The value of the first or last record of each subject in another data set (PROC SORT)';
  %LOCAL t0 i token bykeys n desc dsid had rc;
  %LET t0 = %_spl_begin(pick);

  /* Step 1: the parameters */
  %IF not %_spl_need(pick, data from new value) %THEN %RETURN;
  %IF not %_spl_vars(pick, from, value) %THEN %RETURN;
  %IF not %_spl_oneof(pick, which, first last) %THEN %RETURN;
  %IF not %_spl_oneof(pick, debug, yes no) %THEN %RETURN;

  /* Step 2: the sort keys: each one after a key that puts its missing values last */
  DATA _pick_records;
    SET &from.;
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
  PROC SORT DATA=_pick_records; BY usubjid &bykeys.; RUN;

  /* Step 3: with unique=yes, one record of each subject; two are an error */
  %IF %UPCASE(%SUBSTR(&unique., 1, 1)) = Y %THEN %DO;
    DATA _NULL_;
      SET _pick_records;
      BY usubjid;
      IF FIRST.usubjid AND NOT LAST.usubjid THEN DO;
        PUT "ERR" "OR: [pick] more than one record in from=&from. of " usubjid=;
        PUT "ERR" "OR: [pick]   fix: write first= or last= in the SAP (order=, which=): " usubjid=;
      END;
    RUN;
  %END;

  /* Step 4: the value of the first (last) record of each subject */
  DATA _pick_value(KEEP=usubjid &new.);
    SET _pick_records;
    BY usubjid;
    IF &which..usubjid;
    %IF %LENGTH(&length.) %THEN %DO;
      LENGTH &new. &length.;
    %END;
    %IF %LENGTH(&format.) %THEN %DO;
      FORMAT &new. &format.;
    %END;
    &new. = &value.;
  RUN;

  /* Step 5: the rows keep their order: their number now; the value of their subject */
  /* a variable new= that data= has already is replaced, also for a subject without a value */
  %LET dsid = %SYSFUNC(OPEN(&data.));
  %LET had  = %SYSFUNC(VARNUM(&dsid., &new.));
  %LET rc   = %SYSFUNC(CLOSE(&dsid.));
  %IF &had. %THEN %PUT NOTE: [pick] data=&data. has &new. already: new=&new. replaces it.;
  DATA &data.;
    SET &data.;
    _pick_row = _N_;
  RUN;
  PROC SORT DATA=&data.; BY usubjid; RUN;
  DATA &data.;
    %IF &had. %THEN %DO;
      MERGE &data.(IN=_inrows DROP=&new.) _pick_value;
    %END;
    %ELSE %DO;
      MERGE &data.(IN=_inrows) _pick_value;
    %END;
    BY usubjid;
    IF _inrows;
  RUN;
  PROC SORT DATA=&data. OUT=&data.(DROP=_pick_row); BY _pick_row; RUN;

  /* Step 6: the work data sets are deleted (kept with debug=yes) */
  %IF %UPCASE(&debug.) ne YES %THEN %DO;
    PROC DATASETS LIBRARY=work NOLIST NOWARN;
      DELETE _pick_:;
    QUIT;
  %END;
  %_spl_end(pick, &t0., &debug.)
%MEND pick;
