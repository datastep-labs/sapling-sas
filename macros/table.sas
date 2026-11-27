/*******************************************************************************
| Macro Name    : table.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.9.1
| Created By    : Sapling
| Date          : 27NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : Makes a table from the stacked results in one call: %columns,
|                 %ard, %layout and %print, in that order. Use %table when the
|                 defaults of the four steps fit; call %columns, %ard, %layout
|                 and %print one by one to change a step between them. It passes
|                 them the same parameters as the separate calls and adds no
|                 logic of its own. The display data set is the data set %layout
|                 writes: one row per printed line, one column per printed
|                 column. The numbers file is the CSV file of %ard with every
|                 number of the table; the macro writes it only with file=,
|                 because it belongs to an output. The columns <data>_cols and
|                 the display data set out= stay in WORK. With setup=, a global
|                 macro variable also keeps the call of %print for out=: change
|                 out=, then print again with %print(&<setup>.). Without file=,
|                 the macro prints nothing: change out=, then call
|                 %print(&<setup>., file=...).
| Procedure     : none of its own (those of %columns, %ard, %layout, %print)
| Proven        : its cases of node tools/print_sas.ts (the same .lst and the
|                 same numbers file as the separate calls); ran on SAS 9.4 M9,
|                 2026-11-12
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| data        The results stacked by %stack: one data set in the  Required
|             result shape
| n           The population for the N of each column: a data     Optional
|             set with one row per subject (n= of %columns).
|             When not given, the columns have no N.
| var         The column variable of the results: one variable,   Required
|             such as var = trt01a
| order       The numeric twin of var= in the data set of n=,     Optional
|             such as order = trt01an: it gives the order of the
|             columns
| total       yes: the results have the group Total, and it is    no
|             the last column (total= of %columns). A text in
|             quotes is another name for the Total.
| format      The labels of the categories: pairs of a variable   Optional
|             and a format, as in a FORMAT statement (format =
|             sex $sexf. race $racef.), as format= of %layout
| label       The labels of the columns: pairs name="text",       Optional
|             separated by blanks (label= of %print)
| rows        The number of rows a page holds: %print keeps the   40
|             rows of one level on one page when they fit
| file        The output file without its extension: the macro    Optional
|             writes <file>.rtf, <file>.lst and the numbers file
|             <out>/ard/<last part of file>.csv. When not given,
|             nothing is printed.
| nodata      The text printed when the table has no row: a text  Optional
|             in quotes
| setup       The name of a global macro variable that keeps the  Optional
|             call of %print for out=. When not given, no macro
|             variable is left.
| out         The name of the display data set. When not given,   Optional
|             it is <data>_display.
| debug       yes: keep the work data sets of the macros that     no
|             %table calls
|-------------------------------------------------------------------------------
|
| Output        : OUT: the display data set of %layout. DATA: <data>_cols, the
|                 columns of %columns. FILE: <file>.rtf and <file>.lst of
|                 %print, and the numbers file of %ard (only with file=). SETUP:
|                 with setup=, the global macro variable of that name, which
|                 holds the parameters of %print for out=.
|
| Example:
|
 * Runs columns, ard, layout and print in one call: the same table as the long program.;
 %table(
     data   = t14_2_1
   , n      = adsl
   , var    = trt01a
   , order  = trt01an
   , total  = yes
   , format = sex $sexf.
   , file   = &spl_out./tlf/t14_2_1_table
   , setup  = t14_2_1_table_print
 )
|
|-------------------------------------------------------------------------------
| Change Log :
| Date        Programmer   Description
|-------------------------------------------------------------------------------
| 12-NOV-2026 Sapling      1.4.0: initial version: %columns, %ard, %layout and
|                          %print in one call, for a person; the programs
|                          Sapling writes keep the separate calls.
| 13-NOV-2026 Sapling      1.8.0: labels= is now format= (its value is a list as
|                          in a FORMAT statement).
| 16-NOV-2026 Sapling      1.9.0: the license line; the example in the house
|                          case (names in lower case). No number changes.
| 27-NOV-2026 Sapling      1.9.1: the example runs on the example data
|                          (sas/examples). The text of the header for the
|                          manual: the summary, the form of each parameter. No
|                          number changes.
| 27-NOV-2026 Sapling      1.9.1: a caption for each call of the example (a
|                          comment line before it). No number changes.
|
*******************************************************************************/
%MACRO table(
     data   =      /* The results */
   , n      =      /* The population: its subjects are the N */
   , var    =      /* The column variable */
   , order  =      /* Its numeric twin in N= (TRT01AN): the order */
   , total  = no   /* yes: the group Total of the results is the last column */
   , format =      /* The labels of categories: sex $sexf. race $racef. */
   , label  =      /* Column labels: name="text" pairs */
   , rows   = 40   /* The rows of a page */
   , file   =      /* The output without its extension (blank: no print) */
   , nodata =      /* The text printed when there is no row */
   , setup  =      /* The macro variable that keeps the %print call */
   , out    =      /* The display data set (default: <data>_display) */
   , debug  = no   /* yes: keep the work data sets of the macros it calls */
) / DES = 'A table in one call: %columns, %ard, %layout and %print';
  %LOCAL t0 name valid;
  %LET t0 = %_spl_begin(table);

  /* Step 1: the parameters */
  %IF not %_spl_need(table, data var) %THEN %RETURN;
  %IF not %_spl_oneof(table, debug, yes no) %THEN %RETURN;

  %IF %LENGTH(&out.) = 0 %THEN %LET out = &data._display;  /* the default of out= */
  %LET name = &setup.;                                     /* the setup the print reads */
  %IF %LENGTH(&setup.) = 0 %THEN %LET name = _table_setup;  /* removed at the end */
  %LET valid = %SYSFUNC(NVALID(&name., v7));                /* 1: a name %layout may keep */

  /* Step 2: the columns, the numbers file of the output, the display data set and its setup */
  %IF &valid. %THEN %DO;
    /* the setup of an earlier call is made again: none is left when %layout stops */
    %IF %SYMGLOBL(&name.) %THEN %SYMDEL &name. / NOWARN;
  %END;
  %columns(
      data  = &data.
    , n     = &n.
    , var   = &var.
    , order = &order.
    , total = &total.
    , out   = &data._cols
    , debug = &debug.
  )
  %IF %LENGTH(%SUPERQ(file)) %THEN %DO;
    %ard(data=&data., columns=&data._cols, file=%SCAN(%SUPERQ(file), -1, /\))
  %END;
  %layout(
      data    = &data.
    , columns = &data._cols
    , var     = &var.
    , format  = &format.
    , label   = %SUPERQ(label)
    , rows    = &rows.
    , file    = %SUPERQ(file)
    , nodata  = %SUPERQ(nodata)
    , setup   = &name.
    , out     = &out.
    , debug   = &debug.
  )

  /* Step 3: the print from the setup (with file=); a setup not asked for is removed */
  %IF &valid. %THEN %DO;
    %IF %SYMGLOBL(&name.) and %LENGTH(%SUPERQ(file)) %THEN %DO;
      %print(&&&name..)
    %END;
    %IF %LENGTH(&setup.) = 0 %THEN %DO;
      %SYMDEL &name. / NOWARN;
    %END;
  %END;
  %_spl_end(table, &t0., &debug.)
%MEND table;
