/*******************************************************************************
| Macro Name    : table_shift.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.9.1
| Created By    : Sapling
| Date          : 27NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : Makes a shift table in one call: the subjects in each category
|                 at baseline against each category after baseline. Use
|                 %table_ae for the subjects by nested levels of events; to add
|                 a block that it does not make, start from its long program
|                 (show=). The rows are the levels of within= (such as the
|                 parameter and the visit), then the category at baseline, then
|                 the category after it, in one %freq. The percent is of the
|                 subjects of the group that have a record in the records used.
|                 The long program is the program the macro writes and runs: the
|                 population, the records, one %freq, %stack and %table, the
|                 calls a person would write by hand. The macro computes nothing
|                 itself. These data sets stay in WORK, for a change and a
|                 second print:
|                 - <name>_shift: the result, one row per number (the result
|                   shape, see %stack)
|                 - <name>: the stacked results
|                 - <name>_cols: the columns (%columns)
|                 - <name>_display: the display data set, one row per printed
|                   line (%layout)
|                 The global macro variable <name>_print keeps the call of
|                 %print: change <name>_display, then print again with
|                 %print(&<name>_print.).
| Procedure     : none of its own (those of %freq, %table)
| Proven        : node tools/tables_sas.ts (the same display data set as the
|                 long program, on the made-up study SYNHTN01); ran on SAS
|                 9.4 M9, 2026-11-13
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| data        The input data set: the records, with USUBJID       Required
| adsl        The subjects: a data set with one row per subject.  Optional
|             It gives the population and the N of each column,
|             and its variables are merged onto the records by
|             USUBJID. When not given, the N of a column is the
|             subjects of its records.
| pop         The population: a condition on adsl= in             Optional
|             parentheses, such as pop = (saffl = 'Y'). It is
|             used only with adsl=.
| where       The records to use: a condition in parentheses,     Optional
|             such as where = (trtemfl = 'Y')
| var         Two variables, separated by a blank: the category   BNRIND ANRIND
|             at baseline, then the category after baseline
| within      The levels above the two variables of var=, nested  Optional
|             in their order and separated by blanks, such as
|             within = paramcd avisit
| by          The groups of the columns: one character variable,  Required
|             such as by = trt01a
| keep        Other variables to keep for the names and the       Optional
|             order of the rows, separated by blanks (keep= of
|             %freq), such as keep = param avisitn
| order       The numeric twin of by=, such as order = trt01an:   Optional
|             it gives the order of the columns
| levels      The planned categories of both variables of var=:   Optional
|             values in quotes, separated by blanks, such as
|             levels = 'LOW' 'NORMAL' 'HIGH'. A planned category
|             has a row also without a subject; a record of
|             another category is not counted (levels= of
|             %freq).
| total       yes: add the column Total, all groups together      no
| format      The labels of the categories: pairs of a variable   Optional
|             and a format, as in a FORMAT statement (format =
|             sex $sexf. race $racef.), as format= of %layout
| name        The name of the table: the first part of the names  Optional
|             of its data sets, such as name = t14_3_01. When
|             not given, the last part of file= is used; without
|             file=, name= is required.
| show        yes: write the long program to the log. A file      no
|             path, without quotes: write the long program to
|             that file. In both cases the macro runs it.
| label       The label of the block in the table: a text in      Optional
|             quotes
| stats       The statistics, each name with its pattern,         Optional
|             separated by blanks (stats= of %freq)
| title       The titles of the table: one text in quotes per     Optional
|             line (TITLE1, TITLE2 ...). They hold for this
|             table only. When not given, the TITLE statements
|             in force in the program are used.
| footnote    The footnotes of the table: one text in quotes per  Optional
|             line (FOOTNOTE1, FOOTNOTE2 ...). They hold for
|             this table only. When not given, the FOOTNOTE
|             statements in force in the program are used.
| file        The output file without its extension: the macro    Optional
|             writes <file>.rtf, <file>.lst and the numbers
|             file. When not given, nothing is printed.
| debug       yes: keep the work data sets of the macros that     no
|             the long program calls
|-------------------------------------------------------------------------------
|
| Output        : DATA: <name>_shift (the result), <name> (the stacked results),
|                 <name>_cols, <name>_display, <name>_pop (with adsl=) and
|                 <name>_rec (with adsl= or where=). FILE: <file>.rtf,
|                 <file>.lst and the numbers file (only with file=). SETUP: the
|                 global macro variable <name>_print. SHOW: the long program, in
|                 the log or in a file.
|
| Example:
|
 %table_shift(
     data   = adlb
   , where  = (avisit IN ('Week 12' 'Week 24'))
   , within = paramcd avisit
   , by     = trt01a
   , order  = trt01an
   , levels = 'LOW' 'NORMAL' 'HIGH'
   , title  = "Table 14.8.1 Shift from baseline of the normal range"
   , file   = &spl_out./tlf/t14_8_1
 )
|
|-------------------------------------------------------------------------------
| Change Log :
| Date        Programmer   Description
|-------------------------------------------------------------------------------
| 13-NOV-2026 Sapling      1.8.0: initial version.
| 16-NOV-2026 Sapling      1.9.0: title= and footnote=: TITLE and FOOTNOTE
|                          statements written into the long program before
|                          %table and cleared after it; a missing folder of
|                          show= is made; the categories in the order of levels=
|                          (through %freq). The license line; the example in the
|                          house case. No number changes.
| 16-NOV-2026 Sapling      1.9.1: var=, by=, keep= and order= are checked before
|                          the long program (DEV-031). No number changes.
| 27-NOV-2026 Sapling      1.9.1: the example runs on the example data
|                          (sas/examples). The text of the header for the
|                          manual: the summary, the form of each parameter. No
|                          number changes.
|
*******************************************************************************/
%MACRO table_shift(
     data     =       /* The records */
   , adsl     =       /* The subjects: the population and the N */
   , pop      =       /* The population: a condition on adsl= */
   , where    =       /* The records to use: a condition */
   , var      = BNRIND ANRIND /* The category at baseline, then after it */
   , within   =       /* The levels above them: paramcd avisit */
   , by       =       /* The groups: the columns */
   , keep     =       /* Variables kept for names and order of rows */
   , order    =       /* The numeric twin of by=: the order */
   , levels   =       /* The planned categories, in quotes */
   , total    = no    /* yes: also all groups together, as Total */
   , format   =       /* The labels of categories: sex $sexf. */
   , name     =       /* The name of the table (default: from file=) */
   , show     = no    /* yes: the long program in the log; or a file */
   , label    =       /* The label of the block, in quotes */
   , stats    =       /* The statistics, each with its pattern */
   , title    =       /* The titles: a text in quotes for each line */
   , footnote =       /* The footnotes: a text in quotes for each line */
   , file     =       /* The output without its extension */
   , debug    = no    /* yes: keep the work data sets of the macros */
) / DES = 'A shift table in one call: the category at baseline against the category after it';
  %LOCAL t0 rec popn source ds first second;
  %LET t0 = %_spl_begin(table_shift);

  /* Step 1: the parameters; the names of the records and of the population */
  %IF not %_spl_need(table_shift, data var by) %THEN %RETURN;
  %IF not %_spl_oneof(table_shift, total, yes no) %THEN %RETURN;
  %IF not %_spl_oneof(table_shift, debug, yes no) %THEN %RETURN;
  %IF %SYSFUNC(COUNTW(&var., %STR( ))) ne 2 %THEN %DO;
    %PUT %STR(ERR)OR: [table_shift] var=&var. has not two variables.;
    %PUT %STR(ERR)OR: [table_shift]   fix: give var= two variables: at baseline, then after it.;
    %RETURN;
  %END;

  /* without name=, the last part of the path of the output */
  %IF %LENGTH(&name.) = 0 %THEN %LET name = %SCAN(%SUPERQ(file), -1, /\);
  %IF %LENGTH(&name.) = 0 %THEN %DO;
    %PUT %STR(ERR)OR: [table_shift] name= is required when file= is blank.;
    %PUT %STR(ERR)OR: [table_shift]   fix: give name=<the name of the table>, as t14_5_2.;
    %RETURN;
  %END;
  %LET ds = %SCAN(%SUPERQ(adsl), 1, %STR(%());  /* adsl= without its options */
  %IF %LENGTH(&ds.) %THEN %DO;
    %IF not %SYSFUNC(EXIST(&ds.)) %THEN %DO;
      %PUT %STR(ERR)OR: [table_shift] adsl=&ds. does not exist.;
      %PUT %STR(ERR)OR: [table_shift]   fix: give adsl= the data set of the subjects.;
      %RETURN;
    %END;
  %END;
  /* the variables are in the records, or in the subjects whose variables go to them */
  %IF not %_spl_vars(table_shift, data, var by keep order, adsl) %THEN %RETURN;
  %LET ds   = %SCAN(%SUPERQ(data), 1, %STR(%());  /* data= without its options */
  %LET rec  = &data.;                           /* the records the calls read */
  %LET popn = &data.;                           /* the data set with the N of the columns */
  %IF %LENGTH(&adsl.) %THEN %DO;
    %LET rec  = &name._rec;  /* the records of the population */
    %LET popn = &name._pop;  /* the population */
  %END;
  %ELSE %IF %LENGTH(%SUPERQ(where)) %THEN %DO;
    %LET rec  = &name._rec;  /* the records of where= */
    %LET popn = &name._rec;  /* and their subjects */
  %END;
  %IF %QUPCASE(%SUPERQ(show)) = YES or %QUPCASE(%SUPERQ(show)) = NO %THEN %DO;
    FILENAME _tprog TEMP;
  %END;
  %ELSE %DO;
    %_spl_folder(table_shift, %SUPERQ(show))
    FILENAME _tprog "%SUPERQ(show)";
  %END;
  /* the long program also goes to the log */
  %IF %QUPCASE(%SUPERQ(show)) = YES %THEN %LET source = / SOURCE2;

  /* Step 2: the long program of the table is written: the records, the blocks, %stack, %table */
  DATA _NULL_;
    %_spl_program(begin)
    %_spl_program(records)
    %_spl_arg(data, "&rec.")
    %_spl_arg(var, LOWCASE("&within. &var."))
    %_spl_arg(by, LOWCASE("&by."))
    %_spl_arg(keep, LOWCASE("&keep."))
    %IF %LENGTH(%SUPERQ(levels)) %THEN %DO;
      %LET first  = %LOWCASE(%SCAN(&var., 1, %STR( )));
      %LET second = %LOWCASE(%SCAN(&var., 2, %STR( )));
      part = %_spl_quote(levels);
      %_spl_arg(levels, CATX(' ', "&first.", part, "&second.", part))
    %END;
    %_spl_arg(total, LOWCASE("&total."))
    %_spl_arg(stats)
    %_spl_arg(label)
    %_spl_arg(out, "&name._shift")
    %_spl_call(freq)
    %_spl_program(table)
    %_spl_program(end)
  RUN;

  /* Step 3: the long program runs */
  %INCLUDE _tprog &source.;
  %_spl_end(table_shift, &t0., &debug.)
%MEND table_shift;
