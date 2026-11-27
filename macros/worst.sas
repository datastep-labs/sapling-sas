/*******************************************************************************
| Macro Name    : worst.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.9.1
| Created By    : Sapling
| Date          : 16NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : The records of each subject at its worst level (the maximum
|                 severity or toxicity grade): for each subject and each value
|                 of BY (a term, or nothing: all its records), only the records
|                 whose VAR is the highest of LEVELS, in their order from the
|                 least to the most severe. A record whose VAR is not one of
|                 LEVELS (a missing grade) is never the worst and is left out.
|                 It computes no statistic: %freq then counts each subject once
|                 in each row, at its worst level.
| Procedure     : PROC SORT, a DATA step (BY, FIRST.)
| Proven        : the known answer of the method catsumm with worst=
|                 (src/methods.ts, counted by hand; R ars_worst gives the same,
|                 test/safety-r.test.ts; node tools/methods_sas.ts); ran on SAS
|                 9.4 M9, 2026-11-12
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| data        The records                                         Required
| where       The records to use, a condition in parentheses      Optional
| var         The graded variable                                 Required
| by          The variables of a row (the worst of each subject   Optional
|             in each row); default: none (the worst of all the
|             records of the subject)
| levels      Its values from the least to the most severe        Required
|             (texts in quotes, numbers without)
| out         The records kept (all the variables of DATA)        Required
| debug       yes: keep the work data sets of the macro           no
|             (_worst_*)
|-------------------------------------------------------------------------------
|
| Output        : OUT: the records of DATA at the worst level of each subject and
|                 row.
|
| Example:
|
 %worst(
     data   = adae
   , where  = (trtemfl = 'Y')
   , var    = aesev
   , by     = aebodsys aedecod
   , levels = 'MILD' 'MODERATE' 'SEVERE'
   , out    = ae_worst
 )
|
|-------------------------------------------------------------------------------
| Change Log :
| Date        Programmer   Description
|-------------------------------------------------------------------------------
| 12-NOV-2026 Sapling      1.0.0: initial version.
| 12-NOV-2026 Sapling      1.1.0: the house standard (docs/sas-style.md). No
|                          number changes.
| 12-NOV-2026 Sapling      1.1.0: a level is unquoted before the comparison
|                          (%QSCAN kept its macro quoting: SAS read the text
|                          in quotes as a symbol of its own); ran on SAS 9.4 M9
|                          on the known answer of catsumm with worst=.
| 16-NOV-2026 Sapling      1.9.0: the license line; the example in the house
|                          case (names in lower case). No number changes.
|
*******************************************************************************/
%MACRO worst(
     data   =     /* The records */
   , where  =     /* The records to use: a condition in parentheses */
   , var    =     /* The graded variable */
   , by     =     /* The variables of a row (default: none) */
   , levels =     /* Its values from the least to the most severe */
   , out    =     /* The records kept */
   , debug  = no  /* yes: keep the work data sets _worst_* */
) / DES = 'The records of each subject at its worst level (PROC SORT, a DATA step)';
  %LOCAL t0 i last;
  %LET t0 = %_spl_begin(worst);

  /* Step 1: the parameters */
  %IF not %_spl_need(worst, data var levels out) %THEN %RETURN;
  %IF not %_spl_vars(worst, data, var by) %THEN %RETURN;
  %IF not %_spl_oneof(worst, debug, yes no) %THEN %RETURN;

  %LET var = %UPCASE(&var.);  /* the variable, in upper case */
  /* the groups, in upper case */
  %IF %LENGTH(&by.) %THEN %LET by = %UPCASE(%SYSFUNC(COMPBL(&by.)));
  %LET last = %SCAN(usubjid &by., -1, %STR( ));  /* the last variable of the groups */

  /* Step 2: the level of each record: the place of its value in LEVELS (0: none of them) */
  DATA _worst_ranked;
    SET &data.;
    %IF %LENGTH(%SUPERQ(where)) %THEN %DO;
      WHERE &where.;
    %END;
    _worst_rank = 0;
    %DO i = 1 %TO %SYSFUNC(COUNTW(%SUPERQ(levels), %STR( ), q));
      IF &var. = %UNQUOTE(%QSCAN(%SUPERQ(levels), &i., %STR( ), q)) THEN _worst_rank = &i.;
    %END;
    IF _worst_rank > 0;
  RUN;

  /* Step 3: the highest level of each subject and row first; its records kept */
  PROC SORT DATA=_worst_ranked; BY usubjid &by. DESCENDING _worst_rank; RUN;
  DATA &out.;
    SET _worst_ranked;
    BY usubjid &by.;
    RETAIN _worst_top;
    IF first.&last. THEN _worst_top = _worst_rank;
    IF _worst_rank = _worst_top;
    DROP _worst_rank _worst_top;
  RUN;

  /* Step 4: the work data sets are deleted (kept with debug=yes) */
  %IF %UPCASE(&debug.) ne YES %THEN %DO;
    PROC DATASETS LIBRARY=work NOLIST NOWARN;
      DELETE _worst_:;
    QUIT;
  %END;
  %_spl_end(worst, &t0., &debug.)
%MEND worst;
