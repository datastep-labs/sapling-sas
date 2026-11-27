/*******************************************************************************
| Macro Name    : columns.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.10.0
| Created By    : Sapling
| Date          : 27NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : Returns the columns of a table: one row per column, with its N
|                 and the header that shows the N. A header is the value, a |
|                 and the N: Placebo|(N=86). %layout reads it to place each
|                 number and to label each column; the N comes from the
|                 population of n=, not from the counts of %freq.
|                 - The columns are the values of the column variable in the
|                   results and in the population.
|                 - They are in the order of the numeric twin of order=, else of
|                   their values; the Total is last.
|                 - The N of a column is the number of subjects of n= with its
|                   value; the N of the Total is all subjects of n=.
|                 - Without n= the columns have no N, and the header is the
|                   value alone.
|                 - With page= each page has the same columns, and the N of a
|                   column is the N of its page: with page = sex on the example
|                   data, Placebo|(N=33) on the page of the males and
|                   Placebo|(N=53) on the page of the females.
| Procedure     : PROC SUMMARY
| Proven        : The tables of a made-up study: the N of every column the same
|                 as that of a second program in R; ran on SAS 9.4 M9,
|                 2026-11-12
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| data        The stacked results (out= of %stack)                Required
| n           The population: a data set with USUBJID and the     Optional
|             column variable, such as adsl. Each subject counts
|             once in the N of its column. When not given, the
|             columns have no N.
| var         The column variable: one variable, the first        Required
|             variable of by= of the statistics macros (var =
|             trt01a)
| order       The numeric twin of var= in n=, such as order =     Optional
|             trt01an: the columns are in its order. When not
|             given, the columns are in the order of their
|             values.
| page        A variable of the results and of n=, such as page   Optional
|             = sex: one page per value. The N of a column is
|             then the N of its page. Give %layout the same
|             page=.
| total       yes: the results have the group Total (total = yes  no
|             of the statistics macros); it is the last column,
|             and its N is all subjects of n=. A text in quotes
|             is the other name that the statistics macros gave
|             the Total.
| out         The name of the data set of the columns             Required
| debug       yes: keep the work data sets _columns_*             no
|-------------------------------------------------------------------------------
|
| Output        : OUT: one row per column: COL (its number: 1, 2 ...), COLVALUE
|                 (the value of var=), BIGN (the N) and HEADER (the value, a |
|                 and (N=86); %print splits a header at the |). With page=: one
|                 row per page and column, the page variable first; BIGN is the
|                 N of the page (0: no subject of the column on the page).
|
| Example:
|
 * Makes the four columns with their N from adsl, the Total last, in the order of TRT01AN.;
 %columns(
     data  = t14_2_1
   , n     = adsl
   , var   = trt01a
   , order = trt01an
   , total = yes
   , out   = t14_2_1_cols
 )
 * Gives page=sex: one row per column and sex, the N of each column on the page of its sex.;
 %columns(
     data  = t14_1_1
   , n     = adsl
   , var   = trt01a
   , order = trt01an
   , page  = sex
   , total = yes
   , out   = t14_1_1_cols
 )
 * Leaves out n=: the columns have no N and come in the order of their values, the Total last.;
 %columns(
     data  = t14_2_1
   , var   = trt01a
   , total = yes
   , out   = t14_2_1_cols_no_n
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
| 27-NOV-2026 Sapling      1.10.0: page=: the columns on each page of a page
|                          variable, the N of each column that of its page.
|                          Without page= no change.
| 27-NOV-2026 Sapling      1.10.0: the example runs on the example data
|                          (sas/examples). The text of the header for the
|                          manual: the summary, the form of each parameter. No
|                          number changes.
| 27-NOV-2026 Sapling      1.10.0: The header names no internal tool. No number
|                          changes.
| 27-NOV-2026 Sapling      1.10.0: the N of a page in the text is that of the
|                          example data. No number changes.
| 27-NOV-2026 Sapling      1.10.0: a caption for each call of the example; two
|                          more calls: page= and a call without n=. No number
|                          changes.
| 27-NOV-2026 Sapling      1.10.0: Proven in plain words, for the published
|                          manual. No number changes.
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
