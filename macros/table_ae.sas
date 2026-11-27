/*******************************************************************************
| Macro Name    : table_ae.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.9.1
| Created By    : Sapling
| Date          : 27NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : Makes a table of the subjects with adverse events by system
|                 organ class and preferred term in one call. Use it for any
|                 count of subjects by nested levels of records; to add a block
|                 that it does not make, start from its long program (show=).
|                 The long program is the program the macro writes and runs: the
|                 population, the records, one %freq, %stack and %table, the
|                 calls a person would write by hand. The macro computes nothing
|                 itself. A subject is counted once in each row, and the percent
|                 is of the subjects of the group. These data sets stay in WORK,
|                 for a change and a second print:
|                 - <name>_ae: the result, one row per number (the result shape,
|                   see %stack)
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
| var         The variables of the rows, nested in their order    Required
|             and separated by blanks, such as var = aebodsys
|             aedecod
| by          The groups of the columns: one character variable,  Required
|             such as by = trt01a
| order       The numeric twin of by=, such as order = trt01an:   Optional
|             it gives the order of the columns
| sort        frequency: the rows of the last variable of var=    Optional
|             in the order of their subjects, the most first
|             (order=frequency of %freq). When not given, the
|             rows are in the order of their values.
| threshold   A percent: keep only the rows whose percent of      Optional
|             subjects reaches it in at least one group
|             (threshold= of %freq), such as threshold = 5
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
|             separated by blanks (stats= of %freq), such as
|             stats = n pct events
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
| Output        : DATA: <name>_ae (the result), <name> (the stacked results),
|                 <name>_cols, <name>_display, <name>_pop (with adsl=) and
|                 <name>_rec (with adsl= or where=). FILE: <file>.rtf,
|                 <file>.lst and the numbers file (only with file=). SETUP: the
|                 global macro variable <name>_print. SHOW: the long program, in
|                 the log or in a file.
|
| Example:
|
 %table_ae(
     data  = adam.adae
   , adsl  = adam.adsl
   , pop   = (saffl = 'Y')
   , where = (trtemfl = 'Y')
   , var   = aebodsys aedecod
   , by    = trt01a
   , order = trt01an
   , sort  = frequency
   , label = "Treatment-emergent adverse events"
   , title = "Table 14.5.2 Treatment-emergent adverse events by SOC and PT"
   , file  = &spl_out./tlf/t14_5_2
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
|                          show= is made. The license line; the example in the
|                          house case. No number changes.
| 16-NOV-2026 Sapling      1.9.1: var=, by= and order= are checked before the
|                          long program (DEV-031). No number changes.
| 27-NOV-2026 Sapling      1.9.1: the example runs on the example data
|                          (sas/examples). The text of the header for the
|                          manual: the summary, the form of each parameter. No
|                          number changes.
|
*******************************************************************************/
%MACRO table_ae(
     data      =       /* The records */
   , adsl      =       /* The subjects: the population and the N */
   , pop       =       /* The population: a condition on adsl= */
   , where     =       /* The records to use: a condition */
   , var       =       /* The levels: variables, nested in order */
   , by        =       /* The groups: the columns */
   , order     =       /* The numeric twin of by=: the order */
   , sort      =       /* frequency: the rows by their subjects */
   , threshold =       /* A percent: only the rows that reach it */
   , total     = no    /* yes: also all groups together, as Total */
   , format    =       /* The labels of categories: sex $sexf. */
   , name      =       /* The name of the table (default: from file=) */
   , show      = no    /* yes: the long program in the log; or a file */
   , label     =       /* The label of the block, in quotes */
   , stats     =       /* The statistics, each with its pattern */
   , title     =       /* The titles: a text in quotes for each line */
   , footnote  =       /* The footnotes: a text in quotes for each line */
   , file      =       /* The output without its extension */
   , debug     = no    /* yes: keep the work data sets of the macros */
) / DES = 'An adverse event table in one call: subjects by the levels of var=';
  %LOCAL t0 rec popn source ds;
  %LET t0 = %_spl_begin(table_ae);

  /* Step 1: the parameters; the names of the records and of the population */
  %IF not %_spl_need(table_ae, data var by) %THEN %RETURN;
  %IF not %_spl_oneof(table_ae, total, yes no) %THEN %RETURN;
  %IF not %_spl_oneof(table_ae, debug, yes no) %THEN %RETURN;
  %IF %LENGTH(&sort.) %THEN %DO;
    %IF not %_spl_oneof(table_ae, sort, frequency) %THEN %RETURN;
  %END;

  /* without name=, the last part of the path of the output */
  %IF %LENGTH(&name.) = 0 %THEN %LET name = %SCAN(%SUPERQ(file), -1, /\);
  %IF %LENGTH(&name.) = 0 %THEN %DO;
    %PUT %STR(ERR)OR: [table_ae] name= is required when file= is blank.;
    %PUT %STR(ERR)OR: [table_ae]   fix: give name=<the name of the table>, as t14_5_2.;
    %RETURN;
  %END;
  %LET ds = %SCAN(%SUPERQ(adsl), 1, %STR(%());  /* adsl= without its options */
  %IF %LENGTH(&ds.) %THEN %DO;
    %IF not %SYSFUNC(EXIST(&ds.)) %THEN %DO;
      %PUT %STR(ERR)OR: [table_ae] adsl=&ds. does not exist.;
      %PUT %STR(ERR)OR: [table_ae]   fix: give adsl= the data set of the subjects.;
      %RETURN;
    %END;
  %END;
  /* the variables are in the records, or in the subjects whose variables go to them */
  %IF not %_spl_vars(table_ae, data, var by order, adsl) %THEN %RETURN;
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
    %_spl_folder(table_ae, %SUPERQ(show))
    FILENAME _tprog "%SUPERQ(show)";
  %END;
  /* the long program also goes to the log */
  %IF %QUPCASE(%SUPERQ(show)) = YES %THEN %LET source = / SOURCE2;

  /* Step 2: the long program of the table is written: the records, the blocks, %stack, %table */
  DATA _NULL_;
    %_spl_program(begin)
    %_spl_program(records)
    %_spl_arg(data, "&rec.")
    %IF %LENGTH(&adsl.) %THEN %DO;
      %_spl_arg(denom, "&popn.")
    %END;
    %_spl_arg(var, LOWCASE("&var."))
    %_spl_arg(by, LOWCASE("&by."))
    %_spl_arg(total, LOWCASE("&total."))
    %_spl_arg(threshold)
    %_spl_arg(order, LOWCASE("&sort."))
    %_spl_arg(stats)
    %_spl_arg(label)
    %_spl_arg(out, "&name._ae")
    %_spl_call(freq)
    %_spl_program(table)
    %_spl_program(end)
  RUN;

  /* Step 3: the long program runs */
  %INCLUDE _tprog &source.;
  %_spl_end(table_ae, &t0., &debug.)
%MEND table_ae;
