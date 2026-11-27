/*******************************************************************************
| Macro Name    : stack.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.10.0
| Created By    : Sapling
| Date          : 27NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : Stacks results one under another into one table, a block per
|                 result, in the order given. Call it before %columns, %ard and
|                 %layout, which read the stacked table. A result is the data
|                 set that a statistics macro writes (%describe, %freq, a test
|                 or a model): one row per number. Every result has the same
|                 variables, the result shape:
|                 - the group variables, as in the data (TRT01A, AEDECOD, AVISIT
|                   ...); VERSUS: the group that a difference is made with
|                 - GROUPS: the names of the group variables, in their order
|                 - BLOCK: the label of the block
|                 - STAT: the name of the statistic (n, pct, mean, pval ...)
|                 - VALUE: the number
|                 - TEXT: the number as printed
|                 A block is the rows of one call in the table: the rows of one
|                 result, under its label. A DATA step of your own can write a
|                 result in the same shape. Each variable gets the longest
|                 length it has in the results, so that no text is cut.
| Procedure     : a DATA step (SET INDSNAME=)
| Proven        : The tables of a made-up study: every program ran with a clean
|                 log, and 570 of 570 numbers the same as those of a second
|                 program in R; ran on SAS 9.4 M9, 2026-11-12
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| results     The results to stack: data set names separated by   Required
|             blanks, in the order of the blocks. Give them
|             first, without a keyword (%stack(a b, out=t)), or
|             as results= (%stack(results=a b, out=t)); a
|             message names them results=.
| out         The name of the stacked table                       Required
|-------------------------------------------------------------------------------
|
| Output        : OUT: all rows of the results in the result shape, with two
|                 more variables: RESULT, the name of the result that the row
|                 comes from, and ORD, the place of that result in the list (1,
|                 2, ...). A result with no row keeps its number. A result named
|                 twice has the place of its first name. %layout lays out the
|                 blocks in the order of ORD.
|
| Example:
|
 * Stacks four results in the order of the table: RESULT and ORD tell where each row came from.;
 %stack(age_describe age_anova sex_freq sex_chisq, out=t14_2_1)
 * Stacks the hazard ratios by sex and by age group, for one forest plot.;
 %stack(hr_sex hr_age, out=hr_sub)
 * Stacks age and the age groups by sex: the results of a table with a page per sex.;
 %stack(age_sex agegr_sex, out=t14_1_1)
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
| 27-NOV-2026 Sapling      1.10.0: the example runs on the example data
|                          (sas/examples). The text of the header for the
|                          manual: the summary, the form of each parameter. No
|                          number changes.
| 27-NOV-2026 Sapling      1.10.0: The example names the results of the examples
|                          of %describe, %anova, %freq and %chisq. The header
|                          names no internal tool. No number changes.
| 27-NOV-2026 Sapling      1.10.0: the message of a result that does not exist is
|                          two lines, the fault and its fix. No number changes.
| 27-NOV-2026 Sapling      1.10.0: a caption for each call of the example; a
|                          third call, the results of a table with a page per
|                          sex. No number changes.
| 27-NOV-2026 Sapling      1.10.0: results= may be given without a keyword or as
|                          results=; Proven in plain words, for the published
|                          manual. No number changes.
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
      %PUT %STR(ERR)OR: [stack] results=&ds. does not exist;
      %PUT %STR(ERR)OR: [stack]   fix: give results= results that exist (make them first).;
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
