/*******************************************************************************
| Macro Name    : table_tte.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.9.1
| Created By    : Sapling
| Date          : 16NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : A time-to-event table in one call: the Kaplan-Meier summary of
|                 each group (%km), the log-rank test (%logrank) and the hazard
|                 ratio of pairs of groups from a Cox model (%cox). The macro
|                 writes the long program of the table and runs it; it computes
|                 nothing itself. The results <name>_km (<name>_surv with
|                 time=), <name>_lr and <name>_cox, the table <name>,
|                 <name>_cols and <name>_display stay, and the setup
|                 <name>_print. show= gives the long program.
| Procedure     : none of its own (those of %km, %logrank, %cox, %table)
| Proven        : node tools/tables_sas.ts (the same display data set as the
|                 long program, on the made-up study SYNHTN01); ran on SAS
|                 9.4 M9, 2026-11-13
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| data        The records (a data set with USUBJID)               Required
| adsl        The subjects, one row per subject: the population   Optional
|             and the N of the columns; its variables go to the
|             records (blank: the records have all they need)
| pop         The population: a condition on adsl= in parentheses Optional
| where       The records to use: a condition in parentheses      Optional
| var         The time                                            AVAL
| cnsr        The censoring variable: 1 is censored               CNSR
| by          The groups: a character variable, the columns       Required
| time        A time: also the percent without an event at it and Optional
|             its limits, a block of its own (<name>_surv, time=
|             of %km); the median keeps its own limits
| strata      The strata of the log-rank test and the Cox model   Optional
| order       Its numeric twin (TRT01AN): the order of columns    Optional
| pairs       The pairs of the hazard ratio: each group, then its Optional
|             comparator, in quotes (blank: all pairs)
| format      The labels of categories: variable and format, as   Optional
|             in a FORMAT statement (format= of %layout)
| name        The name of the table: the first part of the names  Optional
|             of its data sets (default: the last part of file=)
| show        yes: the long program in the log; a file: the long  no
|             program is written there (and run)
| title       The titles of the table: a text in quotes for each   Optional
|             line (TITLE1, TITLE2 ...); blank: the TITLE
|             statements of the program
| footnote    The footnotes: a text in quotes for each line        Optional
|             (FOOTNOTE1 ...); blank: those of the program
| file        The output without its extension: <file>.rtf,       Optional
|             <file>.lst and the numbers file (blank: no print)
| debug       yes: keep the work data sets of the macros called   no
|-------------------------------------------------------------------------------
|
| Output        : DATA: <name>_km, <name>_surv (with time=), <name>_lr and
|                 <name>_cox (the results), <name> (the table), <name>_cols,
|                 <name>_display, <name>_pop and <name>_rec; FILE:
|                 <file>.rtf, <file>.lst and the numbers
|                 file (with file=); SETUP: the global macro variable
|                 <name>_print; SHOW: the long program.
|
| Example:
|
 %table_tte(
     data  = adam.adtte
   , adsl  = adam.adsl
   , pop   = (saffl = 'Y')
   , where = (paramcd = 'TTAE')
   , by    = trt01a
   , order = trt01an
   , pairs = "Drug X 10 mg" "Placebo"
   , file  = &spl_out./tlf/t14_6_1
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
|
*******************************************************************************/
%MACRO table_tte(
     data     =       /* The records */
   , adsl     =       /* The subjects: the population and the N */
   , pop      =       /* The population: a condition on adsl= */
   , where    =       /* The records to use: a condition */
   , var      = AVAL  /* The time */
   , cnsr     = CNSR  /* The censoring variable: 1 is censored */
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
