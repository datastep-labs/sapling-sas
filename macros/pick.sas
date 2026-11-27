/*******************************************************************************
| Macro Name    : pick.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.10.0
| Created By    : Sapling
| Date          : 27NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : Gives each subject the value of its first or last record in
|                 another data set, as a new variable. Use %merge_subject when
|                 the other data set has one row per subject. Use %flag_first to
|                 flag a record instead of copying a value. The records of a
|                 subject are sorted by order=, and which= takes the first or
|                 the last one. A missing sort key sorts last. The rows of data=
|                 keep their order. A subject with no record in from= gets a
|                 missing value. When data= has the variable new= already, the
|                 new values replace it and the log says so.
| Procedure     : PROC SORT, MERGE
| Proven        : Checked on its test cases of a value from one record, from the
|                 first or the last record, and from an intercurrent event
|                 (small made-up records): every value the same as that of the
|                 expected records; ran on SAS 9.4 M9, 2026-11-12
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| data        The data set to change in place, such as adsl       Required
| from        The data set of the records, with USUBJID. When     Required
|             the value or a sort key is not a variable yet (a
|             date from a text, a difference), make it first in
|             a DATA step.
| value       The variable of from= that gives the value          Required
| order       The sort keys within a subject: variables           Optional
|             separated by blanks; write descending before a key
|             as in a BY statement (order = descending astdt).
|             When not given, the records keep the order they
|             have in from=.
| which       first or last: the record of the subject that       first
|             gives the value
| length      The length of the new variable when it is a text,   Optional
|             such as $40
| format      The format of the new variable, such as date9       Optional
| unique      yes: each subject must have at most one record in   no
|             from=, so that no order is needed. Two records of
|             a subject give an ERROR line that names the
|             subject.
| new         The name of the new variable                        Required
| debug       yes: keep the work data sets _pick_*                no
|-------------------------------------------------------------------------------
|
| Output        : DATA: data=, changed in place: the variable new= on every row
|                 of a subject, with the value of its first (or last) record in
|                 from=. A subject with no record gets a missing value. With
|                 unique=yes, a subject with two records gets an ERROR line that
|                 names it.
|
| Example:
|
 * Copies the subjects with USUBJID and TRTSDT only.;
 DATA sl;
   SET adsl;
   KEEP usubjid trtsdt;
 RUN;
 * Takes the date of the first exposure record of each subject, as a text of 10.;
 %pick(
     data   = sl
   , from   = sdtm.ex
   , value  = exstdtc
   , order  = exstdtc exseq
   , which  = first
   , length = $10
   , new    = exfstdtc
 )
 * Takes the dose of the last exposure record of each subject.;
 %pick(
     data  = sl
   , from  = sdtm.ex
   , value = exdose
   , order = exstdtc exseq
   , which = last
   , new   = exldose
 )
 * Keeps the disposition event of each subject: one record per subject.;
 DATA ds_eos;
   SET sdtm.ds;
   WHERE dscat = 'DISPOSITION EVENT';
 RUN;
 * Takes the disposition term: unique=yes checks one record per subject, so no order is needed.;
 %pick(
     data   = sl
   , from   = work.ds_eos
   , value  = dsdecod
   , unique = yes
   , new    = dcdecod
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
| 27-NOV-2026 Sapling      1.10.0: the example runs on the example data
|                          (sas/examples). The text of the header for the
|                          manual: the summary, the form of each parameter. No
|                          number changes.
| 27-NOV-2026 Sapling      1.10.0: The example first copies its records into a
|                          data set of its own, so that it changes no data set of
|                          setup.sas for a later example. No number changes.
| 27-NOV-2026 Sapling      1.10.0: the message of two records of a subject with
|                          unique=yes names the parameters of the macro (unique=,
|                          order=, which=); the text of unique=. No number
|                          changes.
| 27-NOV-2026 Sapling      1.10.0: a caption for each call of the example (a
|                          comment line before it). No number changes.
| 27-NOV-2026 Sapling      1.10.0: Proven in plain words, for the published
|                          manual. An example with unique=yes. No number
|                          changes.
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
        PUT "ERR" "OR: [pick]   fix: give unique=no with order= and which= (the record "
            "to keep), or remove the duplicate records: " usubjid=;
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
