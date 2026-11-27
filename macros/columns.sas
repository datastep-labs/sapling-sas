/*******************************************************************************
| Macro Name    : columns.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.9.1
| Created By    : Sapling
| Date          : 27NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : The columns of a table: each value of the column variable in
|                 the results (and in the population), in the order of ORDER
|                 (else of the values), the total last; the N of each column
|                 from the population (its subjects, the total all of them) and
|                 the header of the column with its N: Placebo|(N=86).
|                 With page= the columns are the same on each page (each
|                 value of the page variable) and the N of a column is the
|                 N of its page: Placebo|(N=40) on the page of the males.
| Procedure     : PROC SUMMARY
| Proven        : the tables of the dummy study SYNHTN01 (sapling sas check:
|                 the N of every column the same as R); ran on SAS 9.4 M9,
|                 2026-11-12
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| data        The results (%stack)                                Required
| n           The population, one row per subject (USUBJID): its  Optional
|             subjects of each column are the N in the header
| var         The column variable: the first BY of the statistics Required
|             macros
| order       Its numeric twin in N= (TRT01AN): the order of the  Optional
|             columns (default: the order of the values)
| page        A variable of the results and of N= (SEX): one page Optional
|             per value; the N of a column is the N of its page
| total       yes: the results have the group Total (total=yes of no
|             the statistics macros): the last column, its N all
|             subjects of N=. A text in quotes is another name.
| out         The columns                                         Required
| debug       yes: keep the work data sets _columns_*             no
|-------------------------------------------------------------------------------
|
| Output        : OUT: one row per column: COL (1, 2, ...), COLVALUE (the
|                 value), BIGN (the N) and HEADER (the value, a | and (N=86):
|                 the split character of %print). With page=: one row per
|                 page and column, the page variable first, BIGN the N of the
|                 page (0: no subject of the column on the page).
|
| Example:
|
 %columns(
     data  = t14_2_1
   , n     = adsl
   , var   = trt01a
   , order = trt01an
   , total = yes
   , out   = t14_2_1_cols
 )
 %columns(
     data  = t14_1_1
   , n     = adsl
   , var   = trt01a
   , order = trt01an
   , page  = sex
   , total = yes
   , out   = t14_1_1_cols
 )
|
|-------------------------------------------------------------------------------
| Change Log :
| Date        Programmer   Description
|-------------------------------------------------------------------------------
| 12-NOV-2026 Sapling      1.2.0: initial version, from the inner part
|                          _spl_columns of the printer of 1.1.0 (the same
|                          columns and N): a step of the program, data in and
|                          data out, before %ard and %layout.
| 16-NOV-2026 Sapling      1.9.0: the license line; the example in the house
|                          case (names in lower case). No number changes.
| 27-NOV-2026 Sapling      1.9.1: page=: the columns on each page of a page
|                          variable, the N of each column that of its page.
|                          Without page= no change.
|
*******************************************************************************/
%MACRO columns(
     data  =      /* The results (%stack) */
   , n     =      /* The population: its subjects are the N */
   , var   =      /* The column variable */
   , order =      /* Its numeric twin in N= (TRT01AN): the order */
   , page  =      /* A variable: one page per value, the N of its page */
   , total = no   /* yes: the group Total of the results is the last column */
   , out   =      /* The columns */
   , debug = no   /* yes: keep the work data sets _columns_* */
) / DES = 'The columns of a table and the N of each (PROC SUMMARY)';
  %LOCAL t0 totlab sources;
  %LET t0 = %_spl_begin(columns);

  /* Step 1: the parameters */
  %IF not %_spl_need(columns, data var out) %THEN %RETURN;
  %IF not %_spl_oneof(columns, debug, yes no) %THEN %RETURN;
  %IF not %_spl_vars(columns, data, page) %THEN %RETURN;
  %IF %LENGTH(&n.) %THEN %DO;
    %IF not %_spl_vars(columns, n, var order page) %THEN %RETURN;
  %END;
  %IF %LENGTH(&page.) and %UPCASE(&page.) = %UPCASE(&var.) %THEN %DO;
    %PUT %STR(ERR)OR: [columns] page=&page. is the column variable var=&var.;
    %PUT %STR(ERR)OR: [columns]   fix: give page= another BY variable, such as sex.;
    %RETURN;
  %END;

  %LET var    = %UPCASE(&var.);              /* the column variable, as GROUPS names it */
  %LET page   = %UPCASE(&page.);             /* the page variable, as GROUPS names it */
  %LET totlab = %_spl_total(%SUPERQ(total));  /* the name of the total column */

  /* Step 2: the values of the column variable in the results, with their page */
  DATA _columns_values;
    LENGTH colvalue $200;
    SET &data.;
    IF INDEXW(groups, "&var.");
    %IF %LENGTH(&page.) %THEN %DO;
      IF INDEXW(groups, "&page.");
    %END;
    colvalue = STRIP(VVALUEX("&var."));
    KEEP colvalue &page.;
  RUN;

  %IF %LENGTH(&n.) %THEN %DO;

    /* Step 3: the N of each value on each page, and of all of them for the total */
    DATA _columns_subjects;
      LENGTH colvalue $200;
      SET &n.;
      colvalue = STRIP(VVALUEX("&var."));
      IF colvalue = ' ' THEN DELETE;
      ordern = .;
      %IF %LENGTH(&order.) %THEN %DO;
        ordern = &order.;
      %END;
      OUTPUT;
      %IF %LENGTH(&totlab.) %THEN %DO;
        colvalue = "&totlab.";
        ordern   = .;
        OUTPUT;
      %END;
      KEEP colvalue ordern usubjid &page.;
    RUN;
    PROC SORT DATA=_columns_subjects NODUPKEY; BY &page. colvalue usubjid; RUN;
    PROC SUMMARY DATA=_columns_subjects NWAY;
      CLASS &page. colvalue;
      VAR ordern;
      OUTPUT OUT=_columns_n(DROP=_TYPE_ RENAME=(_FREQ_ = bign)) MIN=ordern;
    RUN;
  %END;
  %ELSE %DO;
    DATA _columns_n;
      SET _columns_values(OBS=0);
      CALL MISSING(bign, ordern);
    RUN;
  %END;

  /* Step 4: the columns in their order, the total last; a column without a subject has no N */
  PROC SORT DATA=_columns_values OUT=_columns_names(KEEP=colvalue) NODUPKEY; BY colvalue; RUN;
  PROC SORT DATA=_columns_n OUT=_columns_order(KEEP=colvalue ordern) NODUPKEY; BY colvalue; RUN;
  DATA _columns_all;
    MERGE _columns_names _columns_order(IN=_inpop);
    BY colvalue;
    inpop = _inpop;
    IF colvalue = "&totlab." AND colvalue NE ' ' THEN last = 1;
    ELSE                                              last = 0;
  RUN;
  PROC SORT DATA=_columns_all; BY last ordern colvalue; RUN;

  /* Step 5: each column on each page (no page=: one page) with its N and its header */
  %IF %LENGTH(&page.) %THEN %DO;
    PROC SORT DATA=_columns_values OUT=_columns_pages(KEEP=&page.) NODUPKEY; BY &page.; RUN;
  %END;
  %ELSE %DO;
    DATA _columns_pages;
      OUTPUT;
    RUN;
  %END;
  DATA _columns_grid;
    SET _columns_pages;
    DO _i = 1 TO _ncol;
      SET _columns_all(KEEP=colvalue inpop) POINT=_i NOBS=_ncol;
      col = _i;
      OUTPUT;
    END;
  RUN;
  PROC SORT DATA=_columns_grid; BY &page. colvalue; RUN;
  DATA &out.;
    LENGTH header $220;
    MERGE _columns_grid(IN=_ingrid) _columns_n(KEEP=&page. colvalue bign);
    BY &page. colvalue;
    IF _ingrid;
    IF inpop AND MISSING(bign) THEN bign = 0;
    header = colvalue;
    IF NOT MISSING(bign) THEN header = CATX('|', colvalue, CATS('(N=', bign, ')'));
    KEEP &page. col colvalue bign header;
  RUN;
  PROC SORT DATA=&out.; BY &page. col; RUN;

  /* Step 6: the work data sets are deleted (kept with debug=yes) */
  %IF %UPCASE(&debug.) ne YES %THEN %DO;
    PROC DATASETS LIBRARY=work NOLIST NOWARN;
      DELETE _columns_:;
    QUIT;
  %END;
  %_spl_end(columns, &t0., &debug.)
%MEND columns;
