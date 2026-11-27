/*******************************************************************************
| Macro Name    : table_visit.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.9.1
| Created By    : Sapling
| Date          : 16NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : A table by visit in one call (vital signs, laboratory values):
|                 the descriptive statistics of each variable of vars= in each
|                 group, parameter and visit. The macro writes the long program
|                 of the table (the population, the records, one %describe per
|                 variable, %stack, %table) and runs it; it computes nothing
|                 itself. The results <name>_<variable>, the table <name>,
|                 <name>_cols and <name>_display stay, and the setup
|                 <name>_print. show= gives the long program.
| Procedure     : none of its own (those of %describe, %table)
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
| vars        The variables: a block of each (aval chg)           Required
| by          The groups: a character variable, the columns       Required
| param       The parameter                                       PARAMCD
| visit       The visit                                           AVISIT
| keep        Variables kept for the names and the order of the   Optional
|             rows (param paramn avisitn)
| order       Its numeric twin (TRT01AN): the order of columns    Optional
| post        The variables of vars= whose block has only the     Optional
|             records of postwhere= (chg)
| postwhere   The records after baseline: a condition in          (ablfl NE 'Y')
|             parentheses
| names       The label of a block when it is not the label of    Optional
|             the variable: chg="Change from baseline"
| total       yes: also all groups together, as Total             no
| format      The labels of categories: variable and format, as   Optional
|             in a FORMAT statement (format= of %layout)
| name        The name of the table: the first part of the names  Optional
|             of its data sets (default: the last part of file=)
| show        yes: the long program in the log; a file: the long  no
|             program is written there (and run)
| stats       The statistics, each with its pattern (stats= of    Optional
|             %describe)
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
| Output        : DATA: <name>_<variable> (one result per variable), <name> (the
|                 table), <name>_cols, <name>_display, <name>_pop and
|                 <name>_rec; FILE: <file>.rtf, <file>.lst and the numbers file
|                 (with file=); SETUP: the global macro variable <name>_print;
|                 SHOW: the long program.
|
| Example:
|
 %table_visit(
     data  = adam.advs
   , adsl  = adam.adsl
   , pop   = (saffl = 'Y')
   , where = (anl01fl = 'Y')
   , vars  = aval chg
   , by    = trt01a
   , order = trt01an
   , keep  = param paramn avisitn
   , post  = chg
   , file  = &spl_out./tlf/t14_7_1
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
