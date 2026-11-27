/*******************************************************************************
| Macro Name    : table_tte.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.10.0
| Created By    : Sapling
| Date          : 27NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : Makes a time-to-event table in one call: the Kaplan-Meier
|                 summary, the log-rank test and the hazard ratios. Use %kmplot
|                 for the Kaplan-Meier curves; to add or change a block, start
|                 from its long program (show=). A block is the rows of one call
|                 in the table. The table has these blocks:
|                 - the subjects, the events, and the median time with its 95%
|                   interval in each group (%km)
|                 - with time=: the percent without an event at that time and
|                   its limits (%km)
|                 - the log-rank test of the groups (%logrank)
|                 - the hazard ratio of each pair of groups from a Cox model,
|                   with its interval and p-value (%cox)
|                 The table has no Total column. The long program is the program
|                 the macro writes and runs: the population, the records, one
|                 call per block, %stack and %table, the calls a person would
|                 write by hand. The macro computes nothing itself. These data
|                 sets stay in WORK, for a change and a second print:
|                 - <name>_km, <name>_surv, <name>_lr and <name>_cox: the
|                   results, one row per number (the result shape, see %stack)
|                 - <name>: the stacked results
|                 - <name>_cols: the columns (%columns)
|                 - <name>_display: the display data set, one row per printed
|                   line (%layout)
|                 The global macro variable <name>_print keeps the call of
|                 %print: change <name>_display, then print again with
|                 %print(&<name>_print.). CNSR 0 is an event and any positive
|                 value is a censoring, as in ADaM, where the value names the
|                 reason of the censoring: a CNSR of 2 is censored as 1 is. A
|                 record used with a missing or negative CNSR stops the macro
|                 with an ERROR.
|                 In the second example the column N of Placebo is 86 (from
|                 adsl=) while n of the Kaplan-Meier block is 85: the 2 subjects
|                 with a missing TRTEDT have no event and no censoring date, so
|                 %tte gives them no record in adttde.
| Procedure     : none of its own (those of %km, %logrank, %cox, %table)
| Proven        : Checked against its long program, written out by hand: the
|                 same display data set (PROC COMPARE), on a made-up study; ran
|                 on SAS 9.4 M9, 2026-11-13
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
| var         The time: one numeric variable                      AVAL
| cnsr        The censoring variable: one numeric variable, 0     CNSR
|             for an event and a positive value for a censoring
|             (the ADaM CNSR: 1, 2 ... name the reason). A
|             missing or negative value on a record used stops
|             the macro with an ERROR.
| by          The groups of the columns: one character variable,  Required
|             such as by = trt01a
| time        A time: adds a block with the percent without an    Optional
|             event at that time and its limits (time= of %km),
|             such as time = 182
| strata      The strata of the log-rank test and of the Cox      Optional
|             model: variables separated by blanks, such as
|             strata = sitegr1
| order       The numeric twin of by=, such as order = trt01an:   Optional
|             it gives the order of the columns and of the
|             groups in the comparisons
| pairs       The pairs of groups to compare, separated by #:     Optional
|             each group in quotes, then the group it is
|             compared with ("Xanomeline High Dose" "Placebo").
|             When not given, each later group is compared with
|             each earlier one.
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
| Output        : DATA: <name>_km, <name>_surv (with time=), <name>_lr and
|                 <name>_cox (the results), <name> (the stacked results),
|                 <name>_cols, <name>_display, <name>_pop (with adsl=) and
|                 <name>_rec (with adsl= or where=). FILE: <file>.rtf,
|                 <file>.lst and the numbers file (only with file=). SETUP: the
|                 global macro variable <name>_print. SHOW: the long program, in
|                 the log or in a file. In the printed table, a comparison is in
|                 the column of the group, on the rows under "vs" and the group
|                 it is compared with: the hazard ratio is the hazard of the
|                 column group over the hazard of the group on the row (below 1:
|                 fewer events in the column group).
|
| Example:
|
 * Makes the table of the time to the event: Kaplan Meier, the log rank test and the hazard ratio.;
 %table_tte(
     data  = adttde
   , by    = trt01a
   , order = trt01an
   , pairs = "Xanomeline High Dose" "Placebo"
   , title = "Table 14.6.1 Time to the first skin event"
   , file  = &spl_out./tlf/t14_6_1
 )
 * Takes the N of each column from adsl= and stratifies the test and the Cox model by sex.;
 %table_tte(
     data   = adttde
   , adsl   = adsl
   , by     = trt01a
   , strata = sex
   , order  = trt01an
   , title  = "Table 14.6.2 Time to the first skin event, stratified by sex"
   , file   = &spl_out./tlf/t14_6_2
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
| 16-NOV-2026 Sapling      1.9.1: with time= the survival is a block of its own,
|                          <name>_surv, and the median keeps its own limits
|                          (DEV-030: before, the limits of the survival were
|                          printed beside the median); var=, cnsr=, by=, strata=
|                          and order= are checked (DEV-031).
| 27-NOV-2026 Sapling      1.10.0: the example runs on the example data
|                          (sas/examples). The text of the header for the
|                          manual: the summary, the form of each parameter. No
|                          number changes.
| 27-NOV-2026 Sapling      1.10.0: the text of cnsr=: 0 is an event and any
|                          positive value a censoring, as %km, %logrank and %cox
|                          now read it. No number changes on data with CNSR 0 and
|                          1.
| 27-NOV-2026 Sapling      1.10.0: a caption for each call of the example; a
|                          second call with other forms of its parameters. No
|                          number changes.
| 27-NOV-2026 Sapling      1.10.0: The direction of a hazard ratio in the
|                          printed table; the caption of the first example names
|                          the Kaplan-Meier summary (no curve); Proven in plain
|                          words, for the published manual. No number changes.
|                          The Details say why the N of a column (86) and n of
|                          the Kaplan-Meier block (85) differ. No number
|                          changes.
|
*******************************************************************************/
%MACRO table_tte(
     data     =       /* The records */
   , adsl     =       /* The subjects: the population and the N */
   , pop      =       /* The population: a condition on adsl= */
   , where    =       /* The records to use: a condition */
   , var      = AVAL  /* The time */
   , cnsr     = CNSR  /* The censoring variable: 0 = event, > 0 censored */
   , by       =       /* The groups: the columns */
   , time     =       /* Times: also the percent without event there */
   , strata   =       /* The strata of the test and the model */
   , order    =       /* The numeric twin of by=: the order */
   , pairs    =       /* The pairs: each group, then its comparator */
   , format   =       /* The labels of categories: sex $sexf. */
   , name     =       /* The name of the table (default: from file=) */
   , show     = no    /* yes: the long program in the log; or a file */
   , title    =       /* The titles: a text in quotes for each line */
   , footnote =       /* The footnotes: a text in quotes for each line */
   , file     =       /* The output without its extension */
   , debug    = no    /* yes: keep the work data sets of the macros */
) / DES = 'A time-to-event table in one call: Kaplan-Meier, the log-rank test, the hazard ratio';
  %LOCAL t0 rec popn source ds total;
  %LET t0 = %_spl_begin(table_tte);

  /* Step 1: the parameters; the names of the records and of the population */
  %IF not %_spl_need(table_tte, data var cnsr by) %THEN %RETURN;
  %IF not %_spl_oneof(table_tte, debug, yes no) %THEN %RETURN;

  /* without name=, the last part of the path of the output */
  %IF %LENGTH(&name.) = 0 %THEN %LET name = %SCAN(%SUPERQ(file), -1, /\);
  %IF %LENGTH(&name.) = 0 %THEN %DO;
    %PUT %STR(ERR)OR: [table_tte] name= is required when file= is blank.;
    %PUT %STR(ERR)OR: [table_tte]   fix: give name=<the name of the table>, as t14_5_2.;
    %RETURN;
  %END;
  %LET ds = %SCAN(%SUPERQ(adsl), 1, %STR(%());  /* adsl= without its options */
  %IF %LENGTH(&ds.) %THEN %DO;
    %IF not %SYSFUNC(EXIST(&ds.)) %THEN %DO;
      %PUT %STR(ERR)OR: [table_tte] adsl=&ds. does not exist.;
      %PUT %STR(ERR)OR: [table_tte]   fix: give adsl= the data set of the subjects.;
      %RETURN;
    %END;
  %END;
  /* the variables are in the records, or in the subjects whose variables go to them */
  %IF not %_spl_vars(table_tte, data, var cnsr by strata order, adsl) %THEN %RETURN;
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
  %LET total = no;  /* a table of comparisons has no Total column */
  %IF %QUPCASE(%SUPERQ(show)) = YES or %QUPCASE(%SUPERQ(show)) = NO %THEN %DO;
    FILENAME _tprog TEMP;
  %END;
  %ELSE %DO;
    %_spl_folder(table_tte, %SUPERQ(show))
    FILENAME _tprog "%SUPERQ(show)";
  %END;
  /* the long program also goes to the log */
  %IF %QUPCASE(%SUPERQ(show)) = YES %THEN %LET source = / SOURCE2;

  /* Step 2: the long program of the table is written: the records, the blocks, %stack, %table */
  DATA _NULL_;
    %_spl_program(begin)
    %_spl_program(records)
    %_spl_arg(data, "&rec.")
    %_spl_arg(var, LOWCASE("&var."))
    %_spl_arg(by, LOWCASE("&by."))
    %_spl_arg(cnsr, LOWCASE("&cnsr."))
    %_spl_arg(label, QUOTE("Kaplan-Meier: subjects, events, median time and 95% CI"))
    %_spl_arg(out, "&name._km")
    %_spl_call(km)
    /* with time= a block of its own: the percent at the time and its limits */
    %IF %LENGTH(&time.) %THEN %DO;
      %_spl_arg(data, "&rec.")
      %_spl_arg(var, LOWCASE("&var."))
      %_spl_arg(by, LOWCASE("&by."))
      %_spl_arg(cnsr, LOWCASE("&cnsr."))
      %_spl_arg(time)
      %_spl_arg(stats, 'surv="XX.X" lcl="XX.X" ucl="XX.X"')
      %_spl_arg(label, QUOTE("Percent without an event at &time. and 95% CI"))
      %_spl_arg(out, "&name._surv")
      %_spl_call(km)
    %END;
    %_spl_arg(data, "&rec.")
    %_spl_arg(var, LOWCASE("&var."))
    %_spl_arg(by, LOWCASE("&by."))
    %_spl_arg(cnsr, LOWCASE("&cnsr."))
    %_spl_arg(strata, LOWCASE("&strata."))
    %_spl_arg(label, QUOTE("Log-rank test"))
    %_spl_arg(out, "&name._lr")
    %_spl_call(logrank)
    %_spl_arg(data, "&rec.")
    %_spl_arg(var, LOWCASE("&var."))
    %_spl_arg(by, LOWCASE("&by."))
    %_spl_arg(cnsr, LOWCASE("&cnsr."))
    %_spl_arg(strata, LOWCASE("&strata."))
    %_spl_arg(pairs)
    %_spl_arg(order, LOWCASE("&order."))
    %_spl_arg(label, QUOTE("Cox model: hazard ratio (95% CI) and p-value"))
    %_spl_arg(out, "&name._cox")
    %_spl_call(cox)
    %_spl_program(table)
    %_spl_program(end)
  RUN;

  /* Step 3: the long program runs */
  %INCLUDE _tprog &source.;
  %_spl_end(table_tte, &t0., &debug.)
%MEND table_tte;
