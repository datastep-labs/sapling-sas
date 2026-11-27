/*******************************************************************************
| Macro Name    : table_response.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.9.1
| Created By    : Sapling
| Date          : 27NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : Makes a response table in one call: the responders in each
|                 group, and the comparisons of pairs of groups. Use %table_ae
|                 to count the subjects by levels of events; to add or change a
|                 block, start from its long program (show=). A block is the
|                 rows of one call in the table. The table has these blocks:
|                 - the responders, n (%), and the interval of the percent
|                   (%proportion)
|                 - with measure= rd, rr or or: the risk difference, the
|                   relative risk or the odds ratio of each pair, with its
|                   interval and p-value (%risk)
|                 - with covars=: the odds ratio adjusted for the covariates,
|                   with its interval and p-value (%logistic)
|                 The table has no Total column. The long program is the program
|                 the macro writes and runs: the population, the records, one
|                 call per block, %stack and %table, the calls a person would
|                 write by hand. The macro computes nothing itself. These data
|                 sets stay in WORK, for a change and a second print:
|                 - <name>_prop, <name>_<measure> and <name>_adj: the results,
|                   one row per number (the result shape, see %stack)
|                 - <name>: the stacked results
|                 - <name>_cols: the columns (%columns)
|                 - <name>_display: the display data set, one row per printed
|                   line (%layout)
|                 The global macro variable <name>_print keeps the call of
|                 %print: change <name>_display, then print again with
|                 %print(&<name>_print.).
| Procedure     : none of its own (those of %proportion, %risk, %logistic, %table)
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
| var         The response: one variable with two values          Required
| event       The value of var= that is the event: a text in      "Y"
|             quotes
| by          The groups of the columns: one character variable,  Required
|             such as by = trt01a
| covars      The covariates, separated by blanks, such as        Optional
|             covars = sitegr1: they add a block with the odds
|             ratio adjusted for them (%logistic). When not
|             given, there is no such block.
| order       The numeric twin of by=, such as order = trt01an:   Optional
|             it gives the order of the columns and of the
|             groups in the comparisons
| pairs       The pairs of groups to compare, separated by #:     Optional
|             each group in quotes, then the group it is
|             compared with ("Xanomeline High Dose" "Placebo").
|             When not given, each later group is compared with
|             each earlier one.
| ci          The interval of the percent of responders:          clopper-pearson
|             clopper-pearson, wilson, wald or agresti-coull
|             (ci= of %proportion)
| measure     rd (the risk difference), rr (the relative risk)    rd
|             or or (the odds ratio): the comparison of %risk;
|             none: no comparison
| diffci      The interval of a risk difference: wald, newcombe,  wald
|             miettinen-nurminen or agresti-caffo (ci= of
|             %risk). It is used only with measure = rd.
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
| Output        : DATA: <name>_prop, <name>_<measure> (with a measure) and
|                 <name>_adj (with covars=), the results; <name> (the stacked
|                 results), <name>_cols, <name>_display, <name>_pop (with adsl=)
|                 and <name>_rec (with adsl= or where=). FILE: <file>.rtf,
|                 <file>.lst and the numbers file (only with file=). SETUP: the
|                 global macro variable <name>_print. SHOW: the long program, in
|                 the log or in a file.
|
| Example:
|
 %table_response(
     data   = adrs
   , where  = (paramcd = 'RSP')
   , var    = avalc
   , by     = trt01a
   , order  = trt01an
   , diffci = newcombe
   , title  = "Table 14.3.2 Responders"
   , file   = &spl_out./tlf/t14_3_2
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
|                          show= is made; the percent and its interval on one
|                          line per category (through %layout). The license
|                          line; the example in the house case. No number
|                          changes.
| 16-NOV-2026 Sapling      1.9.1: measure=or no longer stops at a macro %IF
|                          (DEV-029); var=, by= and order= are checked before
|                          the long program (DEV-031).
| 27-NOV-2026 Sapling      1.9.1: the example runs on the example data
|                          (sas/examples). The text of the header for the
|                          manual: the summary, the form of each parameter. No
|                          number changes.
|
*******************************************************************************/
%MACRO table_response(
     data     =       /* The records */
   , adsl     =       /* The subjects: the population and the N */
   , pop      =       /* The population: a condition on adsl= */
   , where    =       /* The records to use: a condition */
   , var      =       /* The response: two values */
   , event    = "Y"   /* The value that is the event, in quotes */
   , by       =       /* The groups: the columns */
   , covars   =       /* Covariates: also the adjusted odds ratio */
   , order    =       /* The numeric twin of by=: the order */
   , pairs    =       /* The pairs: each group, then its comparator */
   , ci       = clopper-pearson /* The interval of the percent */
   , measure  = rd    /* rd, rr, or; none: no comparison */
   , diffci   = wald  /* The interval of the risk difference */
   , format   =       /* The labels of categories: sex $sexf. */
   , name     =       /* The name of the table (default: from file=) */
   , show     = no    /* yes: the long program in the log; or a file */
   , title    =       /* The titles: a text in quotes for each line */
   , footnote =       /* The footnotes: a text in quotes for each line */
   , file     =       /* The output without its extension */
   , debug    = no    /* yes: keep the work data sets of the macros */
) / DES = 'A responder table in one call: percent with interval, comparison, adjusted odds ratio';
  %LOCAL t0 rec popn source ds total;
  %LET t0 = %_spl_begin(table_response);

  /* Step 1: the parameters; the names of the records and of the population */
  %IF not %_spl_need(table_response, data var by) %THEN %RETURN;
  %IF not %_spl_oneof(table_response, debug, yes no) %THEN %RETURN;
  %IF not %_spl_oneof(table_response, measure, rd rr or none) %THEN %RETURN;

  /* without name=, the last part of the path of the output */
  %IF %LENGTH(&name.) = 0 %THEN %LET name = %SCAN(%SUPERQ(file), -1, /\);
  %IF %LENGTH(&name.) = 0 %THEN %DO;
    %PUT %STR(ERR)OR: [table_response] name= is required when file= is blank.;
    %PUT %STR(ERR)OR: [table_response]   fix: give name=<the name of the table>, as t14_5_2.;
    %RETURN;
  %END;
  %LET ds = %SCAN(%SUPERQ(adsl), 1, %STR(%());  /* adsl= without its options */
  %IF %LENGTH(&ds.) %THEN %DO;
    %IF not %SYSFUNC(EXIST(&ds.)) %THEN %DO;
      %PUT %STR(ERR)OR: [table_response] adsl=&ds. does not exist.;
      %PUT %STR(ERR)OR: [table_response]   fix: give adsl= the data set of the subjects.;
      %RETURN;
    %END;
  %END;
  /* the variables are in the records, or in the subjects whose variables go to them */
  %IF not %_spl_vars(table_response, data, var by order, adsl) %THEN %RETURN;
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
    %_spl_folder(table_response, %SUPERQ(show))
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
    %_spl_arg(levels, LOWCASE("&var. ") || %_spl_quote(event))
    %_spl_arg(ci, LOWCASE("&ci."))
    %_spl_arg(label, QUOTE("Responders, n (%) and 95% CI"))
    %_spl_arg(out, "&name._prop")
    %_spl_call(proportion)
    %IF %QLOWCASE(%SUPERQ(measure)) ne %STR(none) %THEN %DO;
      %_spl_arg(data, "&rec.")
      %_spl_arg(var, LOWCASE("&var."))
      %_spl_arg(event)
      %_spl_arg(by, LOWCASE("&by."))
      %_spl_arg(pairs)
      %_spl_arg(order, LOWCASE("&order."))
      %IF %QLOWCASE(%SUPERQ(measure)) = %STR(rd) %THEN %DO;
        %_spl_arg(ci, LOWCASE("&diffci."))
        %_spl_arg(label, QUOTE("Risk difference (95% CI) and p-value"))
      %END;
      %ELSE %DO;
        %_spl_arg(measure, LOWCASE("&measure."))
        %IF %QLOWCASE(%SUPERQ(measure)) = %STR(rr) %THEN %DO;
          %_spl_arg(label, QUOTE("Relative risk (95% CI) and p-value"))
        %END;
        %ELSE %DO;
          %_spl_arg(label, QUOTE("Odds ratio (95% CI) and p-value"))
        %END;
      %END;
      %_spl_arg(out, LOWCASE("&name._&measure."))
      %_spl_call(risk)
    %END;
    %IF %LENGTH(&covars.) %THEN %DO;
      %_spl_arg(data, "&rec.")
      %_spl_arg(var, LOWCASE("&var."))
      %_spl_arg(event)
      %_spl_arg(by, LOWCASE("&by."))
      %_spl_arg(covars, LOWCASE("&covars."))
      %_spl_arg(pairs)
      %_spl_arg(order, LOWCASE("&order."))
      part = "Odds ratio adjusted for %LOWCASE(&covars.) (95% CI) and p-value";
      %_spl_arg(label, QUOTE(STRIP(part)))
      %_spl_arg(out, "&name._adj")
      %_spl_call(logistic)
    %END;
    %_spl_program(table)
    %_spl_program(end)
  RUN;

  /* Step 3: the long program runs */
  %INCLUDE _tprog &source.;
  %_spl_end(table_response, &t0., &debug.)
%MEND table_response;
