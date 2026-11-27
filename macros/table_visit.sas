/*******************************************************************************
| Macro Name    : table_visit.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.9.1
| Created By    : Sapling
| Date          : 27NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : Makes a table of the descriptive statistics of each variable
|                 by group, parameter and visit in one call. Use it for vital
|                 signs or laboratory values over the visits; use %table_summary
|                 for one row per subject, and %table_model for a model at one
|                 visit. A block is the rows of one variable of vars= in the
|                 table: one %describe of the records with by= the group, the
|                 parameter and the visit. The long program is the program the
|                 macro writes and runs: the population, the records, one
|                 %describe per variable, %stack and %table, the calls a person
|                 would write by hand. The macro computes nothing itself. These
|                 data sets stay in WORK, for a change and a second print:
|                 - <name>_<variable>: the result of each variable, one row per
|                   number (the result shape, see %stack)
|                 - <name>: the stacked results
|                 - <name>_cols: the columns (%columns)
|                 - <name>_display: the display data set, one row per printed
|                   line (%layout)
|                 The global macro variable <name>_print keeps the call of
|                 %print: change <name>_display, then print again with
|                 %print(&<name>_print.).
| Procedure     : none of its own (those of %describe, %table)
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
| vars        The numeric variables to describe, separated by     Required
|             blanks: one block each, such as vars = aval chg
| by          The groups of the columns: one character variable,  Required
|             such as by = trt01a
| param       The variable of the parameter: one variable         PARAMCD
| visit       The variable of the visit: one variable             AVISIT
| keep        Other variables to keep for the names and the       Optional
|             order of the rows, separated by blanks (keep= of
|             %describe), such as keep = param paramn avisitn
| order       The numeric twin of by=, such as order = trt01an:   Optional
|             it gives the order of the columns
| post        The variables of vars= whose block uses only the    Optional
|             records of postwhere=, separated by blanks, such
|             as post = chg
| postwhere   The records after baseline: a condition in          (ablfl NE 'Y')
|             parentheses
| names       The labels of the blocks: pairs variable="text",    Optional
|             separated by blanks, such as names = chg="Change
|             from baseline". A block without a pair has the
|             label of its variable, or its name.
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
| stats       The statistics, each name with its pattern,         Optional
|             separated by blanks (stats= of %describe)
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
| Output        : DATA: <name>_<variable> (the result of each variable), <name>
|                 (the stacked results), <name>_cols, <name>_display, <name>_pop
|                 (with adsl=) and <name>_rec (with adsl= or where=). FILE:
|                 <file>.rtf, <file>.lst and the numbers file (only with file=).
|                 SETUP: the global macro variable <name>_print. SHOW: the long
|                 program, in the log or in a file.
|
| Example:
|
 * Makes the table of the value at each visit and of its change after baseline.;
 %table_visit(
     data  = adam.advs
   , adsl  = adam.adsl
   , pop   = (saffl = 'Y')
   , where = (paramcd = 'SYSBP' AND (ablfl = 'Y' OR anl01fl = 'Y'))
   , vars  = aval chg
   , by    = trt01a
   , keep  = param paramn avisitn
   , order = trt01an
   , post  = chg
   , title = "Table 14.7.1 Systolic blood pressure by visit"
   , file  = &spl_out./tlf/t14_7_1
 )
 * Names the blocks, asks for Q1 and Q3 and adds a Total column.;
 %table_visit(
     data  = advs
   , adsl  = adsl
   , where = (paramcd = 'DIABP' AND (ablfl = 'Y' OR anl01fl = 'Y') AND avisitn IN (0 12 24))
   , vars  = aval chg
   , by    = trt01a
   , keep  = param paramn avisitn
   , order = trt01an
   , post  = chg
   , names = aval="Value" chg="Change from baseline"
   , total = yes
   , stats = n mean sd median q1 q3 min max
   , title = "Table 14.7.2 Diastolic blood pressure at Week 12 and Week 24"
   , file  = &spl_out./tlf/t14_7_2
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
| 16-NOV-2026 Sapling      1.9.1: vars=, by=, param=, visit=, keep= and order=
|                          are checked before the long program (DEV-031). No
|                          number changes.
| 27-NOV-2026 Sapling      1.9.1: the example runs on the example data
|                          (sas/examples). The text of the header for the
|                          manual: the summary, the form of each parameter. No
|                          number changes.
| 27-NOV-2026 Sapling      1.9.1: a caption for each call of the example; a
|                          second call with other forms of its parameters. No
|                          number changes.
|
*******************************************************************************/
%MACRO table_visit(
     data      =       /* The records */
   , adsl      =       /* The subjects: the population and the N */
   , pop       =       /* The population: a condition on adsl= */
   , where     =       /* The records to use: a condition */
   , vars      =       /* The variables: a block of each */
   , by        =       /* The groups: the columns */
   , param     = PARAMCD /* The parameter */
   , visit     = AVISIT /* The visit */
   , keep      =       /* Variables kept for names and order of rows */
   , order     =       /* The numeric twin of by=: the order */
   , post      =       /* The variables of vars= after baseline only */
   , postwhere = (ablfl NE 'Y') /* The records after baseline */
   , names     =       /* The label of a block: chg="Change" */
   , total     = no    /* yes: also all groups together, as Total */
   , format    =       /* The labels of categories: sex $sexf. */
   , name      =       /* The name of the table (default: from file=) */
   , show      = no    /* yes: the long program in the log; or a file */
   , stats     =       /* The statistics, each with its pattern */
   , title     =       /* The titles: a text in quotes for each line */
   , footnote  =       /* The footnotes: a text in quotes for each line */
   , file      =       /* The output without its extension */
   , debug     = no    /* yes: keep the work data sets of the macros */
) / DES = 'A table by visit in one call: each variable of vars= by parameter and visit';
  %LOCAL t0 rec popn source ds i v;
  %LET t0 = %_spl_begin(table_visit);

  /* Step 1: the parameters; the names of the records and of the population */
  %IF not %_spl_need(table_visit, data vars by param visit) %THEN %RETURN;
  %IF not %_spl_oneof(table_visit, total, yes no) %THEN %RETURN;
  %IF not %_spl_oneof(table_visit, debug, yes no) %THEN %RETURN;

  /* without name=, the last part of the path of the output */
  %IF %LENGTH(&name.) = 0 %THEN %LET name = %SCAN(%SUPERQ(file), -1, /\);
  %IF %LENGTH(&name.) = 0 %THEN %DO;
    %PUT %STR(ERR)OR: [table_visit] name= is required when file= is blank.;
    %PUT %STR(ERR)OR: [table_visit]   fix: give name=<the name of the table>, as t14_5_2.;
    %RETURN;
  %END;
  %LET ds = %SCAN(%SUPERQ(adsl), 1, %STR(%());  /* adsl= without its options */
  %IF %LENGTH(&ds.) %THEN %DO;
    %IF not %SYSFUNC(EXIST(&ds.)) %THEN %DO;
      %PUT %STR(ERR)OR: [table_visit] adsl=&ds. does not exist.;
      %PUT %STR(ERR)OR: [table_visit]   fix: give adsl= the data set of the subjects.;
      %RETURN;
    %END;
  %END;
  /* the variables are in the records, or in the subjects whose variables go to them */
  %IF not %_spl_vars(table_visit, data, vars by param visit keep order, adsl) %THEN %RETURN;
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
    %_spl_folder(table_visit, %SUPERQ(show))
    FILENAME _tprog "%SUPERQ(show)";
  %END;
  /* the long program also goes to the log */
  %IF %QUPCASE(%SUPERQ(show)) = YES %THEN %LET source = / SOURCE2;

  /* Step 2: the long program of the table is written: the records, the blocks, %stack, %table */
  DATA _NULL_;
    %_spl_program(begin)
    %_spl_program(records)
    %_spl_program(names)
    %DO i = 1 %TO %SYSFUNC(COUNTW(&vars., %STR( )));
      %LET v = %LOWCASE(%SCAN(&vars., &i., %STR( )));
      %_spl_program(label, &v.)
      %_spl_arg(data, "&rec.")
      %IF %SYSFUNC(INDEXW(%LOWCASE(&post.%STR( )), &v.)) %THEN %DO;
        %_spl_arg(where, %_spl_quote(postwhere))
      %END;
      %_spl_arg(var, "&v.")
      %_spl_arg(by, LOWCASE("&by. &param. &visit."))
      %_spl_arg(keep, LOWCASE("&keep."))
      %_spl_arg(total, LOWCASE("&total."))
      %_spl_arg(stats)
      %_spl_arg(label, QUOTE(STRIP(block)))
      %_spl_arg(out, "&name._&v.")
      %_spl_call(describe)
    %END;
    %_spl_program(table)
    %_spl_program(end)
  RUN;

  /* Step 3: the long program runs */
  %INCLUDE _tprog &source.;
  %_spl_end(table_visit, &t0., &debug.)
%MEND table_visit;
