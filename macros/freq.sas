/*******************************************************************************
| Macro Name    : freq.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.9.1
| Created By    : Sapling
| Date          : 27NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : Frequencies of subjects (PROC FREQ): the subjects of each
|                 category in each group (n), their percent of the subjects of
|                 the group (pct), and the records (events) when stats= asks for
|                 them. A subject is counted once in each cell. Without var= the
|                 cell is "a record at all".
| Procedure     : PROC FREQ
| Proven        : the known answer of the methods count, catsumm
|                 (src/methods.ts, worked out by tools/method_answers.R; node
|                 tools/methods_sas.ts); ran on SAS 9.4 M9, 2026-11-12
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| data        The records                                         Required
| denom       The subjects of each group: the N of the percent    Optional
|             and the columns (default: DATA without WHERE). A
|             data set, with options if needed:
|             adsl(where=(...)).
| where       The records to count, a condition in parentheses    Optional
| var         The categories: variables, nested in their order    Optional
|             (a term within its class)
| by          The groups: variables. The first gives the columns  Required
|             of a table, the others its rows or its pages (sex
|             for page= of %layout)
| keep        Variables to keep with the categories for their     Optional
|             names and order: PARAM and PARAMN go with PARAMCD,
|             AVISITN with AVISIT (a twin <V>N with V); the
|             value of the first record of the category
| levels      The planned categories of some variables of var=:   Optional
|             each variable and its values. They show also
|             without a subject; a record of another category is
|             not counted. The categories of the other variables
|             come from the records counted: a record of another
|             category of a planned variable brings none. The
|             rows of a planned variable V in the order given:
|             its twin VN (1, 2 ...) in out=, unless keep= has
|             VN.
| total       yes: also all groups of the first BY variable         no
|             together, as the group "Total" (a text in quotes is
|             another name for it); that variable a character
|             variable. Default no.
| threshold   A percent: only the categories with this percent    Optional
|             of the subjects of a group or more, in at least
|             one group (the percent itself, not its rounded
|             text)
| order       frequency: the rows of the variable ORDEROF in the  Optional
|             order of their subjects, the most first (equal
|             counts by their value), as its twin <V>N (%print
|             orders the rows by it); default: the order of the
|             values
| orderof     The variable of VAR whose rows are ordered          Optional
|             (default: the last of VAR; the term above a graded
|             variable of %worst)
| orderby     The group of BY whose subjects order the rows, in   Optional
|             quotes (default: all the groups)
| stats       The statistics, each with its pattern (default      n="XX" pct="(XX.X%)"
|             n="XX" pct="(XX.X%)"); also events
| label       The label of the block in a table, in quotes        Optional
| out         The result                                          Required
| debug       yes: keep the work data sets of the macro           no
|             (_freq_*)
|-------------------------------------------------------------------------------
|
| Output        : OUT: one row per group, category and statistic: BY and VAR (and
|                 KEEP), GROUPS (their names), BLOCK, STAT, VALUE, TEXT. Every
|                 group of DENOM has every category: n = 0 when no subject has
|                 it. With levels= the twin <V>N of each planned variable (its
|                 place in levels=); with order=frequency the twin of ORDEROF.
|
| Example:
|
 %freq(
     data  = adsl
   , var   = sex
   , by    = trt01a
   , total = yes
   , label = "Sex"
   , out   = sex
 )
 %freq(
     data  = adae
   , denom = adsl
   , where = (trtemfl = 'Y')
   , var   = aebodsys aedecod
   , by    = trt01a
   , stats = n pct events
   , out   = teae
 )
 %freq(
     data   = adlbc
   , denom  = adsl
   , var    = paramcd bnrind anrind
   , by     = trt01a
   , levels = bnrind 'LOW' 'NORMAL' 'HIGH' anrind 'LOW' 'NORMAL' 'HIGH'
   , out    = shift
 )
 %freq(
     data      = adae
   , denom     = adsl
   , where     = (trtemfl = 'Y')
   , var       = aedecod
   , by        = trt01a
   , threshold = 5
   , order     = frequency
   , out       = common
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
| 12-NOV-2026 Sapling      1.1.0: the label is written into the code
|                          (%_spl_quote), not read by SYMGET when the step
|                          runs: the flat program has it. No number changes.
| 12-NOV-2026 Sapling      1.5.0: the categories of the variables without
|                          levels= come from the records counted, not from
|                          a record of another category (the CDISC pilot:
|                          MICROCY without a normal range has no rows).
| 13-NOV-2026 Sapling      1.7.1: a variable of levels= that var= does not have
|                          is an error with its fix.
| 16-NOV-2026 Sapling      1.9.0: levels= orders the rows: the twin <V>N of each
|                          planned variable is its place in levels= (unless
|                          keep= has <V>N or order=frequency makes it); total=
|                          with a numeric by= stops with one ERROR (it wrote
|                          Invalid numeric data). The license line; the example
|                          in the house case. No number changes.
| 16-NOV-2026 Sapling      1.9.1: denom= that does not exist stops with the
|                          ERROR of the macro (DEV-004); no record: the NOTE No
|                          data qualified (DEV-003). No number changes.
| 27-NOV-2026 Sapling      1.9.1: by= takes more variables, as in %describe:
|                          the first gives the columns and the Total, the
|                          others the rows or the pages (by=trt01a sex). One
|                          variable: no number changes.
|
*******************************************************************************/
%MACRO freq(
     data      =     /* The records */
   , denom     =     /* The subjects of each group (default: data=) */
   , where     =     /* The records to count: a condition in parentheses */
   , var       =     /* The categories: variables, nested in order */
   , by        =     /* The groups: one variable, the columns */
   , keep      =     /* Variables kept for the names and order of rows */
   , levels    =     /* The planned categories: a variable, its values */
   , total     = no  /* yes: also all groups together, as Total */
   , threshold =     /* A percent: only the categories that reach it */
   , order     =     /* frequency: the rows by their subjects */
   , orderof   =     /* The variable of var= whose rows are ordered */
   , orderby   =     /* The group whose subjects order the rows */
   , stats     = n="XX" pct="(XX.X%)"
                     /* The statistics, each with its pattern */
   , label     =     /* The label of the block, in quotes */
   , out       =     /* The result */
   , debug     = no  /* yes: keep the work data sets _freq_* */
) / DES = 'Frequencies of subjects in each group and category (PROC FREQ)';
  %LOCAL t0 i w owner listed free chars totlab table above twin stop lvtwin keepit first bytable
         bychars;
  %LET t0 = %_spl_begin(freq);

  /* Step 1: the parameters; levels= plans the categories of some variables */
  %IF not %_spl_need(freq, data by out) %THEN %RETURN;
  %IF not %_spl_vars(freq, data, var by) %THEN %RETURN;
  %IF not %_spl_oneof(freq, debug, yes no) %THEN %RETURN;
  %IF %LENGTH(%SUPERQ(denom)) %THEN %DO;
    %IF not %_spl_need(freq, denom) %THEN %RETURN;
  %END;

  /* the default: the records of data= */
  %IF %LENGTH(%SUPERQ(denom)) = 0 %THEN %LET denom = &data.;
  %IF not %_spl_vars(freq, denom, by) %THEN %RETURN;
  %LET by      = %UPCASE(&by.);                                /* the groups, in upper case */
  %LET first   = %SCAN(&by., 1, %STR( ));                      /* the variable of the columns */
  %LET bytable = %SYSFUNC(TRANSLATE(%SYSFUNC(STRIP(&by.)), *, %STR( )));  /* the groups crossed */
  /* the variables, in upper case */
  %IF %LENGTH(&var.) %THEN %LET var = %UPCASE(%SYSFUNC(COMPBL(&var.)));
  /* the TABLES list: groups * variables */
  %LET table  = %SYSFUNC(TRANSLATE(%SYSFUNC(STRIP(&by. &var.)), *, %STR( )));
  %LET chars  = %_spl_chars(&data., &by. &var.);  /* the character variables */
  %LET totlab = %_spl_total(%SUPERQ(total));  /* the label of the total group */
  %IF %LENGTH(&totlab.) and not %SYSFUNC(INDEXW(%STR( )&chars., &first.)) %THEN %DO;
    %PUT %STR(ERR)OR: [freq] total= needs a character group first in by= (&first. is numeric);
    %PUT %STR(ERR)OR: [freq]   fix: give by= a character group first (TRT01A), or total=no.;
    %RETURN;
  %END;
  %DO i = 1 %TO %SYSFUNC(COUNTW(%SUPERQ(levels), %STR( ), q));
    %LET w = %QSCAN(%SUPERQ(levels), &i., %STR( ), q);
    %IF %SYSFUNC(NVALID(&w., v7)) %THEN %DO;
      %LET listed = &listed. %UPCASE(&w.);
      %IF not %SYSFUNC(INDEXW(%STR( )&var., %UPCASE(&w.))) %THEN %DO;
        %PUT %STR(ERR)OR: [freq] levels= names the variable &w., and var=&var. does not have it.;
        %PUT %STR(ERR)OR: [freq]   fix: give levels= variables of var= only, or add &w. to var=.;
        %RETURN;
      %END;
    %END;
  %END;
  %DO i = 1 %TO %SYSFUNC(COUNTW(&var.%STR( ), %STR( )));
    %LET w = %SCAN(&var., &i., %STR( ));
    %IF not %SYSFUNC(INDEXW(%STR( )&listed., &w.)) %THEN %LET free = &free. &w.;
  %END;
  /* the order of levels= as the twin <V>N of each planned variable, unless keep= has it or
     order=frequency makes it */
  %LET lvtwin = ;  /* the twins of levels=, as <V>N:<the place of V> */
  %DO i = 1 %TO %SYSFUNC(COUNTW(&listed.%STR( ), %STR( )));
    %LET w      = %SCAN(&listed., &i., %STR( ));
    %LET keepit = 1;
    %IF %LENGTH(&w.) > 31 %THEN %LET keepit = 0;
    %ELSE %IF %SYSFUNC(INDEXW(%STR( )%UPCASE(&keep.), &w.N)) %THEN %LET keepit = 0;
    %ELSE %IF %UPCASE(&order.) = FREQUENCY %THEN %DO;
      %IF %UPCASE(&orderof.) = &w. %THEN %LET keepit = 0;
      %ELSE %IF %LENGTH(&orderof.) = 0 and %SCAN(&var., -1, %STR( )) = &w. %THEN %LET keepit = 0;
    %END;
    %IF &keepit. %THEN %LET lvtwin = &lvtwin. &w.N:&i.;
  %END;

  /* Step 2: the records counted, each with its group and its categories */
  /* A record without a group or a category is not counted; with a total, each record
     once more in the group &totlab. */
  DATA _freq_records;
    %IF %LENGTH(&chars.) %THEN %DO;
      LENGTH &chars. $200;
    %END;
    SET &data.;
    %IF %LENGTH(%SUPERQ(where)) %THEN %DO;
      WHERE &where.;
    %END;
    IF CMISS(OF &by. &var.) = 0;
    OUTPUT;
    %IF %LENGTH(&totlab.) %THEN %DO;
      &first. = "&totlab.";
      OUTPUT;
    %END;
    KEEP usubjid &by. &var. &keep.;
  RUN;
  %IF %_spl_nobs(_freq_records) = 0 %THEN %DO;
    %PUT NOTE: [freq] No data qualified: no record meets where= and the conditions of the macro.;
  %END;

  /* Step 3: the categories: the planned ones, and those of the records counted */
  %IF %LENGTH(&listed.) %THEN %DO;
    /* a record of another category of a planned variable brings no category */
    DATA _freq_levels;
      %_spl_levels(levels=&levels., data=&data., order=_freq_lv)
    RUN;
    PROC SORT DATA=_freq_levels; BY &listed.; RUN;
    PROC SORT DATA=_freq_records; BY &listed.; RUN;
    DATA _freq_records;
      MERGE _freq_records(IN=inrec) _freq_levels(IN=planned);
      BY &listed.;
      IF inrec AND planned;
    RUN;
  %END;
  %IF %LENGTH(&free.) %THEN %DO;
    PROC SORT DATA=_freq_records(KEEP=&free.) OUT=_freq_categories NODUPKEY; BY &free.; RUN;
  %END;
  %IF %LENGTH(&listed.) %THEN %DO;
    %IF %LENGTH(&free.) %THEN %DO;
      DATA _freq_categories;
        SET _freq_categories;
        DO _k = 1 TO _nlev;
          SET _freq_levels POINT=_k NOBS=_nlev;
          OUTPUT;
        END;
      RUN;
    %END;
    %ELSE %DO;
      DATA _freq_categories;
        SET _freq_levels;
      RUN;
    %END;
  %END;

  /* Step 4: the groups: the subjects of each group in DENOM, the N of the percent */
  %DO i = 1 %TO %SYSFUNC(COUNTW(&by., %STR( )));
    %IF %SYSFUNC(INDEXW(%STR( )&chars., %SCAN(&by., &i., %STR( )))) %THEN
      %LET bychars = &bychars. %SCAN(&by., &i., %STR( ));
  %END;
  DATA _freq_subjects;
    %IF %LENGTH(&bychars.) %THEN %DO;
      LENGTH &bychars. $200;
    %END;
    SET &denom.;
    IF CMISS(OF &by.) = 0;
    OUTPUT;
    %IF %LENGTH(&totlab.) %THEN %DO;
      &first. = "&totlab.";
      OUTPUT;
    %END;
    KEEP usubjid &by.;
  RUN;
  PROC SORT DATA=_freq_subjects NODUPKEY; BY &by. usubjid; RUN;
  PROC FREQ DATA=_freq_subjects NOPRINT;
    TABLES &bytable. / OUT=_freq_groups(KEEP=&by. count RENAME=(count = bign));
  RUN;

  /* Step 5: every group with every category: a cell without a subject has n = 0 */
  DATA _freq_cells;
    SET _freq_groups;
    %IF %LENGTH(&var.) %THEN %DO;
      DO _k = 1 TO _ncat;
        SET _freq_categories POINT=_k NOBS=_ncat;
        OUTPUT;
      END;
    %END;
  RUN;
  %IF %LENGTH(&var.) %THEN %DO i = 1 %TO %SYSFUNC(COUNTW(&keep.%STR( ), %STR( )));
    /* Each variable of KEEP goes with the category it names or orders (PARAM and PARAMN: PARAMCD;
       AVISITN: AVISIT; else all of VAR): the value of its first record. */
    %LET w     = %UPCASE(%SCAN(&keep., &i., %STR( )));
    %LET owner = &var.;
    %IF &w. = PARAM or &w. = PARAMN %THEN %LET owner = PARAMCD;
    %ELSE %IF %LENGTH(&w.) > 1 %THEN %LET owner = %SUBSTR(&w., 1, %LENGTH(&w.) - 1);
    %IF not %SYSFUNC(INDEXW(&var., &owner.)) %THEN %LET owner = &var.;
    PROC SORT DATA=_freq_records(KEEP=&owner. &w.) OUT=_freq_keep NODUPKEY; BY &owner.; RUN;
    PROC SORT DATA=_freq_cells; BY &owner.; RUN;
    DATA _freq_cells;
      MERGE _freq_cells(IN=cell) _freq_keep;
      BY &owner.;
      IF cell;
    RUN;
  %END;
  PROC SORT DATA=_freq_cells; BY &by. &var.; RUN;

  /* Step 6: the subjects of each cell (each subject once) and its records */
  PROC SORT DATA=_freq_records OUT=_freq_once NODUPKEY; BY &by. &var. usubjid; RUN;
  PROC FREQ DATA=_freq_once NOPRINT;
    TABLES &table. / OUT=_freq_n(KEEP=&by. &var. count RENAME=(count = n));
  RUN;
  PROC FREQ DATA=_freq_records NOPRINT;
    TABLES &table. / OUT=_freq_events(KEEP=&by. &var. count RENAME=(count = events));
  RUN;
  %IF not %SYSFUNC(EXIST(_freq_n)) %THEN %DO;
    /* no record to count: every cell has n = 0 */
    DATA _freq_n _freq_events;
      SET _freq_records(OBS=0 KEEP=&by. &var.);
      n      = 0;
      events = 0;
    RUN;
  %END;

  %IF %LENGTH(&threshold.) %THEN %DO;

    /* Step 7: the categories that reach threshold= in at least one group */
    DATA _freq_pct;
      MERGE _freq_cells(IN=planned) _freq_n;
      BY &by. &var.;
      IF planned;
      pct = 0;
      IF bign > 0 THEN pct = 100 * COALESCE(n, 0) / bign;
      KEEP &var. pct;
    RUN;
    PROC SUMMARY DATA=_freq_pct NWAY;
      CLASS &var.;
      VAR pct;
      OUTPUT OUT=_freq_top(KEEP=&var. top) MAX=top;
    RUN;
    PROC SORT DATA=_freq_cells; BY &var.; RUN;
    DATA _freq_cells;
      MERGE _freq_cells(IN=cell) _freq_top;
      BY &var.;
      IF cell AND top >= &threshold. - 1E-9;
      DROP top;
    RUN;
    PROC SORT DATA=_freq_cells; BY &by. &var.; RUN;
  %END;

  %IF %UPCASE(&order.) = FREQUENCY %THEN %DO;

    /* Step 8: the rank of each row of ORDEROF by its subjects (order=frequency) */
    /* The rank is by the subjects of the group ORDERBY (else of all the groups), summed over the
       variables after it, the most first; the twin <V>N orders the rows of %print. */
    %IF %LENGTH(&orderof.) = 0 %THEN %LET orderof = %SCAN(&var., -1, %STR( ));
    %LET orderof = %UPCASE(&orderof.);
    %LET twin    = &orderof.N;
    %LET above   = ;
    %LET stop    = 0;
    %DO i = 1 %TO %SYSFUNC(COUNTW(&var., %STR( )));
      %IF %SCAN(&var., &i., %STR( )) = &orderof. %THEN %LET stop = 1;
      %IF not &stop. %THEN %LET above = &above. %SCAN(&var., &i., %STR( ));
    %END;
    PROC SUMMARY DATA=_freq_n NWAY;
      %IF %LENGTH(%SUPERQ(orderby)) %THEN %DO;
        WHERE &first. = &orderby.;
      %END;
      %ELSE %IF %LENGTH(&totlab.) %THEN %DO;
        WHERE &first. NE "&totlab.";
      %END;
      CLASS &above. &orderof.;
      VAR n;
      OUTPUT OUT=_freq_tot(KEEP=&above. &orderof. tot) SUM=tot;
    RUN;
    PROC SORT DATA=_freq_tot; BY &above. DESCENDING tot &orderof.; RUN;
    DATA _freq_tot;
      SET _freq_tot;
      %IF %LENGTH(&above.) %THEN %DO;
        BY &above.;
        IF first.%SCAN(&above., -1, %STR( )) THEN &twin. = 0;
      %END;
      &twin. + 1;
      KEEP &above. &orderof. &twin.;
    RUN;
    PROC SORT DATA=_freq_tot; BY &above. &orderof.; RUN;
    PROC SORT DATA=_freq_cells; BY &above. &orderof.; RUN;
    DATA _freq_cells;
      MERGE _freq_cells(IN=cell) _freq_tot;
      BY &above. &orderof.;
      IF cell;
      /* a row without a subject in the group of the order: after the others */
      IF MISSING(&twin.) THEN &twin. = 1E6;
    RUN;
    PROC SORT DATA=_freq_cells; BY &by. &var.; RUN;
  %END;

  /* Step 9: one row per cell and statistic: the result */
  DATA &out.;
    LENGTH groups block $200;
    MERGE _freq_cells(IN=planned) _freq_n _freq_events;
    BY &by. &var.;
    IF planned;
    n      = COALESCE(n, 0);
    events = COALESCE(events, 0);
    pct    = .;
    IF bign > 0 THEN pct = 100 * n / bign;
    groups = "&by. &var.";
    block  = DEQUOTE(%_spl_quote(label));
    %DO i = 1 %TO %SYSFUNC(COUNTW(&lvtwin.%STR( ), %STR( )));
      %LET w = %SCAN(&lvtwin., &i., %STR( ));  /* <V>N:<the place of V in levels=> */
      %SCAN(&w., 1, :) = _freq_lv%SCAN(&w., 2, :);
      %LET twin = &twin. %SCAN(&w., 1, :);
    %END;
    %_spl_rows(stats=&stats.)
    KEEP &by. &var. &keep. &twin. groups block stat value text;
  RUN;

  /* Step 10: the work data sets are deleted (kept with debug=yes) */
  %IF %UPCASE(&debug.) ne YES %THEN %DO;
    PROC DATASETS LIBRARY=work NOLIST NOWARN;
      DELETE _FREQ_:;
    QUIT;
  %END;
  %_spl_end(freq, &t0., &debug.)
%MEND freq;
