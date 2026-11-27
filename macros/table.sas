/*******************************************************************************
| Macro Name    : table.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.9.1
| Created By    : Sapling
| Date          : 16NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : A table in one call: %columns, %ard (only with file=: the
|                 numbers file belongs to an output), %layout and %print, in
|                 that order, with the same parameters as the separate calls;
|                 it holds no logic of its own. It leaves the columns
|                 <data>_cols and the display data set OUT; with setup= also
|                 the global macro variable that %print(&name.) prints from,
|                 for a second print after a change of OUT. Without file= it
|                 prints nothing: change OUT, then %print(&name., file=...).
| Procedure     : none of its own (those of %columns, %ard, %layout, %print)
| Proven        : its cases of node tools/print_sas.ts (the same .lst and the
|                 same numbers file as the separate calls); ran on SAS 9.4 M9,
|                 2026-11-12
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| data        The results (%stack)                                Required
| n           The population, one row per subject: the N of each  Optional
|             column (n= of %columns)
| var         The column variable of the results                  Required
| order       Its numeric twin in N= (TRT01AN): the order of the  Optional
|             columns
| total       yes: the results have the group Total (total= of    no
|             %columns)
| format      The labels of categories: variable and format, as   Optional
|             in a FORMAT statement (format= of %layout)
| label       Column labels: name="text" pairs (label= of %print) Optional
| rows        The rows of a page, for the rows of one level       40
| file        The output without its extension: <file>.rtf,       Optional
|             <file>.lst and the numbers file <out>/ard/<last
|             part of file>.csv (blank: nothing is printed)
| nodata      The text printed when there is no row               Optional
| setup       The name of a global macro variable that keeps the  Optional
|             %print call of OUT (blank: none is left)
| out         The display data set (default: <data>_display)      Optional
| debug       yes: keep the work data sets of the macros it calls no
|-------------------------------------------------------------------------------
|
| Output        : OUT: the display data set of %layout; DATA: <data>_cols, the
|                 columns of %columns; FILE: <file>.rtf and <file>.lst of
|                 %print and the numbers file of %ard (with file=); SETUP:
|                 with setup=, the global macro variable of that name with the
|                 parameters of %print for OUT.
|
| Example:
|
 %table(
     data  = t14_2_1
   , n     = adsl
   , var   = trt01a
   , order = trt01an
   , total = yes
   , file  = &spl_out./tlf/t14_2_1
   , setup = t14_2_1_print
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
