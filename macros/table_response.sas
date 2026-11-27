/*******************************************************************************
| Macro Name    : table_response.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.9.1
| Created By    : Sapling
| Date          : 16NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : A table of a binary response in one call: the subjects with
|                 the event and their percent with its interval in each group
|                 (%proportion), the comparison of pairs of groups (%risk: risk
|                 difference, relative risk or odds ratio, with its test), and
|                 with covars= the odds ratio adjusted for them (%logistic). The
|                 macro writes the long program of the table and runs it; it
|                 computes nothing itself. The results <name>_prop,
|                 <name>_<measure> and <name>_adj, the table <name>, <name>_cols
|                 and <name>_display stay, and the setup <name>_print. show=
|                 gives the long program.
| Procedure     : none of its own (those of %proportion, %risk, %logistic, %table)
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
| var         The response: a variable with two values            Required
| event       The value that is the event, in quotes              "Y"
| by          The groups: a character variable, the columns       Required
| covars      Covariates: also the odds ratio adjusted for them   Optional
|             (%logistic)
| order       Its numeric twin (TRT01AN): the order of columns    Optional
| pairs       The pairs compared: each group, then the group it   Optional
|             is compared with, in quotes; # between pairs
|             (blank: all pairs)
| ci          The interval of the percent (ci= of %proportion)    clopper-pearson
| measure     rd, rr or or: the comparison of %risk; none: no     rd
|             comparison
| diffci      The interval of a risk difference (ci= of %risk)    wald
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
| Output        : DATA: <name>_prop, <name>_<measure> and <name>_adj (the
|                 results), <name> (the table), <name>_cols, <name>_display, and
|                 <name>_pop and <name>_rec with adsl= or where=; FILE:
|                 <file>.rtf, <file>.lst and the numbers file (with file=);
|                 SETUP: the global macro variable <name>_print; SHOW: the long
|                 program.
|
| Example:
|
 %table_response(
     data   = adrs
   , var    = avalc
   , by     = trtp
   , order  = trtpn
   , pairs  = "Drug X 10 mg" "Placebo"
   , diffci = newcombe
   , covars = base
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
