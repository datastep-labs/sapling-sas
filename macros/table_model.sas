/*******************************************************************************
| Macro Name    : table_model.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.10.0
| Created By    : Sapling
| Date          : 27NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : Makes a table of a continuous endpoint in one call:
|                 descriptive statistics, and the LS means of a model. Use
|                 %table_visit for the statistics at every visit without a
|                 model; to add or change a block, start from its long program
|                 (show=). A block is the rows of one call in the table. The
|                 table has these blocks:
|                 - one block per variable of describe=: its descriptive
|                   statistics on the records of the visit of at= (%describe)
|                 - with method=ancova: the LS means and the differences of
|                   pairs of groups from an ANCOVA on the records of the visit
|                   of at= (%lsmeans), in a block with the label "ANCOVA,
|                   adjusted for" and the names of covars= in lower case, such
|                   as "ANCOVA, adjusted for base" (without covars=: "Analysis
|                   of variance")
|                 - with method=mmrm: the same from a mixed model for repeated
|                   measures over all visits, at the visit of at= (%mmrm), in a
|                   block with the label "MMRM: " and the visit, such as "MMRM:
|                   Week 24"
|                 With method=ancova, the records of the visit of at= must be
|                 one record per subject: give where= the parameter and the
|                 analysis flag, as %lsmeans uses the first record of a subject
|                 (with a NOTE when it leaves one out). The label of the model
|                 block is not changed by names=: change its row in
|                 <name>_display and print again, or start from the long program
|                 (show=). The table has no Total column. The long program is
|                 the program the macro writes and runs: the population, the
|                 records, one call per block, %stack and %table, the calls a
|                 person would write by hand. The macro computes nothing itself.
|                 These data sets stay in WORK, for a change and a second print:
|                 - <name>_<variable> and <name>_ancova or <name>_mmrm: the
|                   results, one row per number (the result shape, see %stack)
|                 - <name>: the stacked results
|                 - <name>_cols: the columns (%columns)
|                 - <name>_display: the display data set, one row per printed
|                   line (%layout)
|                 The global macro variable <name>_print keeps the call of
|                 %print: change <name>_display, then print again with
|                 %print(&<name>_print.).
| Procedure     : none of its own (those of %describe, %lsmeans, %mmrm, %table)
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
|             such as where = (paramcd = 'SYSBP')
| var         The response: one numeric variable                  CHG
| covars      The covariates of the model, separated by blanks,   Optional
|             such as covars = base
| visit       The variable of the visit: one variable             AVISIT
| by          The groups of the columns: one character variable,  Required
|             such as by = trt01a
| at          The visit of the table: a value of visit= in        Optional
|             quotes, such as at = "Week 24". It selects the
|             records of the descriptive blocks and of the
|             ANCOVA, and the visit of the LS means of the MMRM.
|             When not given, the ANCOVA uses all records.
| order       The numeric twin of by=, such as order = trt01an:   Optional
|             it gives the order of the columns and of the
|             groups in the comparisons
| describe    The variables with a descriptive block before the   Optional
|             model, separated by blanks, such as describe =
|             base aval chg
| method      ancova (%lsmeans) or mmrm (%mmrm, which needs at=)  ancova
| model       The fixed effects of the MMRM, separated by         Optional
|             blanks. When not given: the covariates, the by=
|             variable, the visit= variable and the interaction
|             of the two (such as trt01p*avisit).
| type        The covariance structure of the MMRM: TYPE= of the  un
|             REPEATED statement, such as un, cs, ar(1) or toep
|             (type= of %mmrm)
| fallback    Other covariance structures of the MMRM to try in   Optional
|             their order when one does not converge, separated
|             by blanks, such as fallback = toep cs
| pairs       The pairs of groups to compare, separated by #:     Optional
|             each group in quotes, then the group it is
|             compared with ("Xanomeline High Dose" "Placebo").
|             When not given, each later group is compared with
|             each earlier one.
| names       The labels of the blocks: pairs variable="text",    Optional
|             separated by blanks, such as names = chg="Change
|             from baseline". A block without a pair has the
|             label of its variable, or its name.
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
| stats       The statistics of the model block, each name with   Optional
|             its pattern. When not given: the LS means with
|             their SE, the difference with its SE and limits,
|             and the p-value.
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
| Output        : DATA: <name>_<variable> (the descriptive results),
|                 <name>_ancova or <name>_mmrm (the result of the model), <name>
|                 (the stacked results), <name>_cols, <name>_display, <name>_at
|                 (with at=), <name>_pop (with adsl=) and <name>_rec (with adsl=
|                 or where=). FILE: <file>.rtf, <file>.lst and the numbers file
|                 (only with file=). SETUP: the global macro variable
|                 <name>_print. SHOW: the long program, in the log or in a file.
|                 In the printed table, a comparison is in the column of the
|                 group, on the rows under "vs" and the group it is compared
|                 with: the LS mean of the column group minus the LS mean of the
|                 group on the row.
|
| Example:
|
 * Makes the ANCOVA table at Week 12: three descriptive blocks, then the LS means and difference.;
 %table_model(
     data     = advs
   , adsl     = adsl
   , where    = (paramcd = 'SYSBP' AND anl01fl = 'Y' AND avisitn < 99)
   , covars   = base
   , by       = trt01p
   , at       = "Week 12"
   , order    = trt01pn
   , describe = base aval chg
   , pairs    = "Xanomeline High Dose" "Placebo"
   , title    = "Table 14.3.1 ANCOVA of the change of systolic blood pressure at Week 12"
   , file     = &spl_out./tlf/t14_3_1
 )
 * Uses method=mmrm on five visits: the LS means and the differences at Week 24.;
 %table_model(
     data     = advs
   , adsl     = adsl
   , where    = (paramcd = 'SYSBP' AND anl01fl = 'Y' AND avisitn IN (4 8 12 16 24))
   , covars   = base
   , visit    = avisit
   , by       = trt01p
   , at       = "Week 24"
   , order    = trt01pn
   , method   = mmrm
   , type     = un
   , fallback = toep
   , title    = "Table 14.3.3 MMRM of the change of systolic blood pressure at Week 24"
   , file     = &spl_out./tlf/t14_3_3
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
| 27-NOV-2026 Sapling      1.10.0: the example runs on the example data
|                          (sas/examples). The text of the header for the
|                          manual: the summary, the form of each parameter. No
|                          number changes.
| 27-NOV-2026 Sapling      1.10.0: The example gives adsl=: the N of the columns
|                          is that of the population. No number changes.
| 27-NOV-2026 Sapling      1.10.0: the text of where= and model=; the text says
|                          that the ANCOVA needs one record per subject. No
|                          number changes.
| 27-NOV-2026 Sapling      1.10.0: a caption for each call of the example; a
|                          second call with other forms of its parameters. No
|                          number changes.
| 27-NOV-2026 Sapling      1.10.0: The label of the model block ("ANCOVA,
|                          adjusted for base", "MMRM: Week 24") and the
|                          direction of a difference in the printed table;
|                          Proven in plain words, for the published manual. No
|                          number changes.
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
