/*******************************************************************************
| Macro Name    : table_model.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.9.1
| Created By    : Sapling
| Date          : 16NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : A table of a continuous endpoint in one call: the descriptive
|                 statistics of the variables of describe= at the visit of at=,
|                 then the LS means and the differences of pairs of groups from
|                 an ANCOVA (%lsmeans, method=ancova) or from a mixed model for
|                 repeated measures over all visits (%mmrm, method=mmrm). The
|                 macro writes the long program of the table and runs it; it
|                 computes nothing itself. The results <name>_<variable> and
|                 <name>_ancova or <name>_mmrm, the table <name>, <name>_cols
|                 and <name>_display stay, and the setup <name>_print. show=
|                 gives the long program.
| Procedure     : none of its own (those of %describe, %lsmeans, %mmrm, %table)
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
| var         The response                                        CHG
| covars      The covariates of the model (base)                  Optional
| visit       The visit                                           AVISIT
| by          The groups: a character variable, the columns       Required
| at          The visit of the table, in quotes ("Week 12"): the  Optional
|             records of the descriptive blocks and the ANCOVA,
|             the visit of the LS means of the MMRM
| order       Its numeric twin (TRT01AN): the order of columns    Optional
| describe    Variables with a descriptive block before the model Optional
|             (base aval chg)
| method      ancova (%lsmeans) or mmrm (%mmrm; at= is required)  ancova
| model       The fixed effects of the MMRM (default: covars= by= Optional
|             visit= by=*visit=)
| type        The covariance structure of the MMRM                un
| fallback    Other structures to try, in their order             Optional
| pairs       The pairs compared: each group, then the group it   Optional
|             is compared with, in quotes (blank: all pairs)
| names       The label of a block when it is not the label of    Optional
|             the variable: chg="Change from baseline"
| format      The labels of categories: variable and format, as   Optional
|             in a FORMAT statement (format= of %layout)
| name        The name of the table: the first part of the names  Optional
|             of its data sets (default: the last part of file=)
| show        yes: the long program in the log; a file: the long  no
|             program is written there (and run)
| stats       The statistics of the model, each with its pattern  Optional
|             (default: the LS means, their difference with its
|             SE and limits, the p-value)
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
| Output        : DATA: <name>_<variable> (the descriptive results),
|                 <name>_ancova or <name>_mmrm, <name> (the table), <name>_cols,
|                 <name>_display, <name>_at with at=, and <name>_pop and
|                 <name>_rec with adsl= or where=; FILE: <file>.rtf, <file>.lst
|                 and the numbers file (with file=); SETUP: the global macro
|                 variable <name>_print; SHOW: the long program.
|
| Example:
|
 %table_model(
     data     = advs
   , where    = (paramcd = 'SYSBP' AND anl01fl = 'Y' AND avisitn > 0)
   , covars   = base
   , at       = "Week 12"
   , describe = base aval chg
   , by       = trtp
   , order    = trtpn
   , pairs    = "Drug X 10 mg" "Placebo"
   , file     = &spl_out./tlf/t14_3_1
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
|
*******************************************************************************/
%MACRO table_model(
     data     =       /* The records */
   , adsl     =       /* The subjects: the population and the N */
   , pop      =       /* The population: a condition on adsl= */
   , where    =       /* The records to use: a condition */
   , var      = CHG   /* The response */
   , covars   =       /* The covariates of the model */
   , visit    = AVISIT /* The visit */
   , by       =       /* The groups: the columns */
   , at       =       /* The visit of the table, in quotes */
   , order    =       /* The numeric twin of by=: the order */
   , describe =       /* Variables with a descriptive block first */
   , method   = ancova /* ancova or mmrm */
   , model    =       /* The fixed effects of the MMRM */
   , type     = un    /* The covariance structure of the MMRM */
   , fallback =       /* Other structures to try, in their order */
   , pairs    =       /* The pairs: each group, then its comparator */
   , names    =       /* The label of a block: chg="Change" */
   , format   =       /* The labels of categories: sex $sexf. */
   , name     =       /* The name of the table (default: from file=) */
   , show     = no    /* yes: the long program in the log; or a file */
   , stats    =       /* The statistics of the model */
   , title    =       /* The titles: a text in quotes for each line */
   , footnote =       /* The footnotes: a text in quotes for each line */
   , file     =       /* The output without its extension */
   , debug    = no    /* yes: keep the work data sets of the macros */
) / DES = 'A model table in one call: descriptive blocks, then ANCOVA or MMRM';
  %LOCAL t0 rec popn source ds total i v recat;
  %LET t0 = %_spl_begin(table_model);

  /* Step 1: the parameters; the names of the records and of the population */
  %IF not %_spl_need(table_model, data var by) %THEN %RETURN;
  %IF not %_spl_oneof(table_model, debug, yes no) %THEN %RETURN;
  %IF not %_spl_oneof(table_model, method, ancova mmrm) %THEN %RETURN;
  %IF %LOWCASE(&method.) = mmrm %THEN %DO;
    %IF not %_spl_need(table_model, visit at) %THEN %RETURN;
  %END;

  /* without name=, the last part of the path of the output */
  %IF %LENGTH(&name.) = 0 %THEN %LET name = %SCAN(%SUPERQ(file), -1, /\);
  %IF %LENGTH(&name.) = 0 %THEN %DO;
    %PUT %STR(ERR)OR: [table_model] name= is required when file= is blank.;
    %PUT %STR(ERR)OR: [table_model]   fix: give name=<the name of the table>, as t14_5_2.;
    %RETURN;
  %END;
  %LET ds = %SCAN(%SUPERQ(adsl), 1, %STR(%());  /* adsl= without its options */
  %IF %LENGTH(&ds.) %THEN %DO;
    %IF not %SYSFUNC(EXIST(&ds.)) %THEN %DO;
      %PUT %STR(ERR)OR: [table_model] adsl=&ds. does not exist.;
      %PUT %STR(ERR)OR: [table_model]   fix: give adsl= the data set of the subjects.;
      %RETURN;
    %END;
  %END;
  /* the variables are in the records, or in the subjects whose variables go to them */
  %IF not %_spl_vars(table_model, data, var by order, adsl) %THEN %RETURN;
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
  %LET recat = &rec.;  /* the records of the visit of at= */
  /* with at=: made by the long program */
  %IF %LENGTH(%SUPERQ(at)) %THEN %LET recat = &name._at;
  /* the fixed effects of the MMRM when model= is blank */
  %IF %LENGTH(&model.) = 0 %THEN %LET model = &covars. &by. &visit. &by.*&visit.;
  /* the statistics of the model when stats= is blank */
  %IF %LENGTH(%SUPERQ(stats)) = 0 %THEN
    %LET stats = lsmean="XX.X" lsmean_se="XX.XX" diff="XX.X" diff_se="XX.XX" lcl="XX.X" ucl="XX.X"
                 pval="X.XXX";
  %IF %QUPCASE(%SUPERQ(show)) = YES or %QUPCASE(%SUPERQ(show)) = NO %THEN %DO;
    FILENAME _tprog TEMP;
  %END;
  %ELSE %DO;
    %_spl_folder(table_model, %SUPERQ(show))
    FILENAME _tprog "%SUPERQ(show)";
  %END;
  /* the long program also goes to the log */
  %IF %QUPCASE(%SUPERQ(show)) = YES %THEN %LET source = / SOURCE2;

  /* Step 2: the long program of the table is written: the records, the blocks, %stack, %table */
  DATA _NULL_;
    %_spl_program(begin)
    %_spl_program(records)
    %_spl_program(names)
    %IF %LENGTH(%SUPERQ(at)) %THEN %DO;
      line = LOWCASE("  WHERE &visit. = ") || %_spl_quote(at) || ';';
      _len = LENGTH(line);
      PUT '/* The records of the visit: one per subject */'
        / "DATA &name._at;"
        / "  SET &rec.;"
        / line $VARYING2200. _len
        / 'RUN;'
        /;
    %END;
    %DO i = 1 %TO %SYSFUNC(COUNTW(&describe.%STR( ), %STR( )));
      %LET v = %LOWCASE(%SCAN(&describe., &i., %STR( )));
      %_spl_program(label, &v.)
      %_spl_arg(data, "&recat.")
      %_spl_arg(var, "&v.")
      %_spl_arg(by, LOWCASE("&by."))
      %_spl_arg(label, QUOTE(STRIP(block)))
      %_spl_arg(out, "&name._&v.")
      %_spl_call(describe)
    %END;
    %IF %LOWCASE(&method.) = ancova %THEN %DO;
      %_spl_arg(data, "&recat.")
      %_spl_arg(var, LOWCASE("&var."))
      %_spl_arg(by, LOWCASE("&by."))
      %_spl_arg(covars, LOWCASE("&covars."))
      %_spl_arg(pairs)
      %_spl_arg(order, LOWCASE("&order."))
      %_spl_arg(stats)
      %IF %LENGTH(&covars.) %THEN %DO;
        %_spl_arg(label, QUOTE("ANCOVA, adjusted for %LOWCASE(&covars.)"))
      %END;
      %ELSE %DO;
        %_spl_arg(label, QUOTE("Analysis of variance"))
      %END;
      %_spl_arg(out, "&name._ancova")
      %_spl_call(lsmeans)
    %END;
    %ELSE %DO;
      %_spl_arg(data, "&rec.")
      %_spl_arg(var, LOWCASE("&var."))
      %_spl_arg(by, LOWCASE("&by."))
      %_spl_arg(visit, LOWCASE("&visit."))
      %_spl_arg(at)
      %_spl_arg(model, LOWCASE("&model."))
      %_spl_arg(type, LOWCASE("&type."))
      %_spl_arg(fallback, LOWCASE("&fallback."))
      %_spl_arg(pairs)
      %_spl_arg(order, LOWCASE("&order."))
      %_spl_arg(stats)
      %_spl_arg(label, QUOTE("MMRM: " || DEQUOTE(%_spl_quote(at))))
      %_spl_arg(out, "&name._mmrm")
      %_spl_call(mmrm)
    %END;
    %_spl_program(table)
    %_spl_program(end)
  RUN;

  /* Step 3: the long program runs */
  %INCLUDE _tprog &source.;
  %_spl_end(table_model, &t0., &debug.)
%MEND table_model;
