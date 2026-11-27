/*******************************************************************************
| Macro Name    : stack.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.9.1
| Created By    : Sapling
| Date          : 16NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : Put results one under another: the blocks of a table, in the
|                 order given.
| Procedure     : a DATA step (SET INDSNAME=)
| Proven        : the tables of the dummy study SYNHTN01 (sapling sas run: SAS
|                 RUN PASS; sapling sas check: SAS CHECK PASS, 570 of 570
|                 numbers of R the same in SAS); ran on SAS 9.4 M9, 2026-11-12
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| results     The results (of %describe, %freq, a test or a       Required
|             model, or a DATA step of your own in the same
|             shape), separated by blanks
| out         The table                                           Required
|-------------------------------------------------------------------------------
|
| Output        : OUT: all rows, with RESULT (the name of the result each row comes
|                 from) and ORD (its place in the list: 1, 2, ...; a result
|                 without a row keeps its number, and a result named twice has
|                 the place of its first name). %layout lays the blocks out in
|                 this order. Each variable has the
|                 longest length it has in the results: no text is cut.
| Note          : The result shape (every statistics macro writes it): the group
|                 variables as in the data (TRT01A, AEDECOD, AVISIT ...; VERSUS:
|                 the group a difference is made with), GROUPS (their names, in
|                 order), BLOCK (the label of the block), STAT (n, pct, mean,
|                 pval ...), VALUE (the number), TEXT (the number as printed).
|
| Example:
|
 %stack(
     age sex race
   , out = t14_2_01
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
| 12-NOV-2026 Sapling      1.5.0: each variable the longest length of the
|                          results (the CDISC pilot: PARAM of ADLBH was cut
|                          to the 40 characters of ADLBC's). No number
|                          changes.
| 16-NOV-2026 Sapling      1.9.0: the license line; the example in the house
|                          case (names in lower case). No number changes.
| 16-NOV-2026 Sapling      1.9.1: a result that does not exist stops with the
|                          ERROR of the macro (DEV-005); ORD is the place of the
|                          result in the list (DEV-006). No number changes.
|
*******************************************************************************/
%MACRO stack(
     results     /* The results, separated by blanks */
   , out =       /* The table */
) / DES = 'Put results one under another: the blocks of a table (a DATA step)';
  %LOCAL t0 i j k m n dsid name len dollar names lengths ds places;
  %LET t0 = %_spl_begin(stack);

  /* Step 1: the parameters; each result exists */
  %IF not %_spl_need(stack, results out) %THEN %RETURN;
  %DO i = 1 %TO %SYSFUNC(COUNTW(&results., %STR( )));
    %LET ds = %SCAN(%SCAN(&results., &i., %STR( )), 1, %STR(%());
    %IF not %SYSFUNC(EXIST(&ds.)) and not %SYSFUNC(EXIST(&ds., VIEW)) %THEN %DO;
      %PUT %STR(ERR)OR: [stack] results=&ds. does not exist: give results= results that exist.;
      %RETURN;
    %END;
    /* the full name of each result, as INDSNAME gives it: its place in the list */
    %IF %INDEX(&ds., .) = 0 %THEN %LET ds = WORK.&ds.;
    %IF %LENGTH(%SUPERQ(places)) %THEN %LET places = &places.%STR(, );
    %LET places = &places."%UPCASE(&ds.)";
  %END;

  /* Step 2: the length of each variable */

  /* the length of each variable: the longest in the results, so that no text is cut
     (PARAM of ADLBC and of ADLBH); the variables in the order they first appear */
  %LET n = 0;
  %DO i = 1 %TO %SYSFUNC(COUNTW(&results., %STR( )));
    %LET dsid = %SYSFUNC(OPEN(%SCAN(%SCAN(&results., &i., %STR( )), 1, %STR(%())));
    %IF &dsid. %THEN %DO;
      %DO j = 1 %TO %SYSFUNC(ATTRN(&dsid., NVARS));
        %LET name = %UPCASE(%SYSFUNC(VARNAME(&dsid., &j.)));
        %LET len  = %SYSFUNC(VARLEN(&dsid., &j.));
        %LET k    = 0;
        %DO m = 1 %TO &n.;
          %IF %SCAN(&names., &m., %STR( )) = &name. %THEN %LET k = &m.;
        %END;
        %IF &name. = RESULT or &name. = _SOURCE %THEN %LET k = -1;
        %IF &k. = 0 %THEN %DO;
          %LET n = %EVAL(&n. + 1);
          %LOCAL _len&n. _type&n.;
          %LET names = &names. &name.;
          %LET _len&n. = &len.;
          %LET _type&n. = %SYSFUNC(VARTYPE(&dsid., &j.));
        %END;
        %ELSE %IF &k. > 0 %THEN %DO;
          %IF &len. > &&_len&k. %THEN %LET _len&k. = &len.;
        %END;
      %END;
      %LET dsid = %SYSFUNC(CLOSE(&dsid.));
    %END;
  %END;
  %DO k = 1 %TO &n.;
    %LET dollar = ;
    %IF &&_type&k. = C %THEN %LET dollar = $;
    %LET lengths = &lengths. %SCAN(&names., &k., %STR( )) &dollar.&&_len&k.;
  %END;

  /* Step 3: the results one under another: RESULT and ORD of each row */
  DATA &out.;
    LENGTH result $32 _source $41 &lengths.;
    SET &results. INDSNAME=_source;
    result = UPCASE(SCAN(_source, 2, '.'));
    /* the place of the result in the list: an empty result keeps its number */
    ord = WHICHC(UPCASE(_source), &places.);
  RUN;
  %_spl_end(stack, &t0.)
%MEND stack;
