/*******************************************************************************
| Macro Name    : table_summary.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.9.1
| Created By    : Sapling
| Date          : 27NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : Makes a summary table of the subjects in one call, such as
|                 demographics: one block per variable. Use %table_visit for the
|                 values of records at each visit; to add a block that it does
|                 not make, start from its long program (show=). A block is the
|                 rows of one variable in the table. Name the variables in
|                 vars=, in the order of the table:
|                 - a name alone (age): a numeric variable, described by
|                   %describe
|                 - a name and # (sex#): a categorical variable, counted by
|                   %freq
|                 - a name, # and a numeric variable (agegr1#agegr1n): a
|                   categorical variable whose categories are in the order of
|                   that variable
|                 A character variable without # stops the macro with an ERROR.
|                 The long program is the program the macro writes and runs: the
|                 population, one %describe or %freq per variable, %stack and
|                 %table, the calls a person would write by hand. The macro
|                 computes nothing itself. These data sets stay in WORK, for a
|                 change and a second print:
|                 - <name>_<variable>_summ: the result of each variable, one row
|                   per number (the result shape, see %stack)
|                 - <name>: the stacked results
|                 - <name>_cols: the columns (%columns)
|                 - <name>_display: the display data set, one row per printed
|                   line (%layout)
|                 The global macro variable <name>_print keeps the call of
|                 %print: change <name>_display, then print again with
|                 %print(&<name>_print.).
| Procedure     : none of its own (those of %describe, %freq, %table)
| Proven        : its cases of node tools/print_sas.ts (the same .lst and the
|                 same numbers file as the long program); ran on SAS 9.4 M9,
|                 2026-11-13
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| data        The input data set: the subjects, one row per       Required
|             subject, such as adsl
| where       The population: a condition in parentheses, such    Optional
|             as where = (saffl = 'Y')
| vars        The variables of the table in its order, separated  Required
|             by blanks: a name alone for a numeric variable, a
|             name and # for a categorical one, such as vars =
|             age sex# agegr1#agegr1n
| by          The groups of the columns: one character variable,  Required
|             such as by = trt01a
| order       The numeric twin of by=, such as order = trt01an:   Optional
|             it gives the order of the columns
| levels      The planned categories of some categorical          Optional
|             variables: each variable, then its values in
|             quotes (levels= of %freq), such as levels = sex
|             'F' 'M'. A planned category has a row also without
|             a subject.
| total       yes: add the column Total, all groups together      no
| catstats    The statistics of a categorical variable, each      Optional
|             name with its pattern (stats= of %freq)
| names       The labels of the blocks: pairs variable="text",    Optional
|             separated by blanks, such as names = age="Age
|             (years)". A block without a pair has the label of
|             its variable, or its name.
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
| stats       The statistics of a numeric variable, each name     Optional
|             with its pattern (stats= of %describe)
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
| Output        : DATA: <name>_<variable>_summ (the result of each variable),
|                 <name> (the stacked results), <name>_cols, <name>_display, and
|                 <name>_pop (only with where=). FILE: <file>.rtf, <file>.lst
|                 and the numbers file (only with file=). SETUP: the global
|                 macro variable <name>_print. SHOW: the long program, in the
|                 log or in a file.
|
| Example:
|
 * Makes the demographic table from one row per subject: age as numbers, the categories as rows.;
 %table_summary(
     data   = adam.adsl
   , where  = (saffl = 'Y')
   , vars   = age agegr1# sex# race# ethnic#
   , by     = trt01a
   , order  = trt01an
   , total  = yes
   , format = sex $sexf.
   , title  = "Table 14.2.1 Demographic characteristics" "Safety population"
   , file   = &spl_out./tlf/t14_2_1_summary
 )
 * Names the blocks, plans a race with no subject and asks for Q1 and Q3: ASIAN has a row of 0.;
 %table_summary(
     data     = adsl
   , vars     = age trtdurd race#
   , by       = trt01a
   , order    = trt01an
   , levels   = race 'WHITE' 'BLACK OR AFRICAN AMERICAN' 'ASIAN' 'AMERICAN INDIAN OR ALASKA NATIVE'
   , catstats = n pct
   , names    = age="Age (years)" trtdurd="Duration of treatment (days)" race="Race"
   , stats    = n mean sd median q1 q3 min max
   , title    = "Table 14.2.2 Age, duration of treatment and race"
   , file     = &spl_out./tlf/t14_2_2
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
| 27-NOV-2026 Sapling      1.9.1: the example runs on the example data
|                          (sas/examples). The text of the header for the
|                          manual: the summary, the form of each parameter. No
|                          number changes.
| 27-NOV-2026 Sapling      1.9.1: a caption for each call of the example; a
|                          second call with other forms of its parameters. No
|                          number changes.
|
*******************************************************************************/
%MACRO table_summary(
     data     =      /* The subjects, one row per subject */
   , where    =      /* The population: a condition in parentheses */
   , vars     =      /* The variables; # after a categorical one */
   , by       =      /* The groups: the columns */
   , order    =      /* The numeric twin of by=: the order of the columns */
   , levels   =      /* The planned categories: a variable, its values */
   , total    = no   /* yes: also all groups together, as Total */
   , catstats =      /* The statistics of a categorical variable */
   , names    =      /* The label of a block: age="Age (years)" */
   , format   =      /* The labels of categories: sex $sexf. race $racef. */
   , name     =      /* The name of the table (default: from file=) */
   , show     = no   /* yes: the long program in the log; or a file for it */
   , stats    =      /* The statistics of a continuous variable */
   , title    =      /* The titles: a text in quotes for each line */
   , footnote =      /* The footnotes: a text in quotes for each line */
   , file     =      /* The output without its extension (blank: no print) */
   , debug    = no   /* yes: keep the work data sets of the macros called */
) / DES = 'A summary table in one call: the variables, # after a categorical one';
  %LOCAL t0 i token variable twin list ds dsid rc ok pop program source;
  %LET t0 = %_spl_begin(table_summary);

  /* Step 1: the parameters; each variable is in data=, a character variable has its # */
  %IF not %_spl_need(table_summary, data vars by) %THEN %RETURN;
  %IF not %_spl_oneof(table_summary, total, yes no) %THEN %RETURN;
  %IF not %_spl_oneof(table_summary, debug, yes no) %THEN %RETURN;

  %IF %LENGTH(&name.) = 0 %THEN %LET name = %SCAN(%SUPERQ(file), -1, /\);  /* from file= */
  %IF %LENGTH(&name.) = 0 %THEN %DO;
    %PUT %STR(ERR)OR: [table_summary] name= is required when file= is blank.;
    %PUT %STR(ERR)OR: [table_summary]   fix: give name=<the name of the table>, as t14_2_1.;
    %RETURN;
  %END;
  %DO i = 1 %TO %SYSFUNC(COUNTW(&vars., %STR( )));
    %LET token    = %SCAN(&vars., &i., %STR( ));  /* a variable with its mark */
    %LET variable = %SCAN(&token., 1, #);         /* its name */
    %LET twin     = %SCAN(&token., 2, #);         /* the variable of its order */
    %LET list     = &list. &variable. &twin.;     /* every variable named */
    %IF %LENGTH(&name._&variable._summ) > 32 %THEN %DO;
      %PUT %STR(ERR)OR: [table_summary] name=&name. is too long for the variable &variable..;
      %PUT %STR(ERR)OR: [table_summary]   fix: give name= a shorter name (&name._&variable._summ).;
      %RETURN;
    %END;
  %END;
  %IF not %_spl_vars(table_summary, data, by order) %THEN %RETURN;
  %LET ds   = %SCAN(%SUPERQ(data), 1, %STR(%());  /* data= without its options */
  %LET ok   = 1;                      /* 0: a wrong variable of vars= */
  %LET dsid = %SYSFUNC(OPEN(&ds.));  /* data=, opened for the names and types */
  %DO i = 1 %TO %SYSFUNC(COUNTW(&list., %STR( )));
    %LET variable = %SCAN(&list., &i., %STR( ));  /* a variable named in vars= */
    %IF not %SYSFUNC(VARNUM(&dsid., &variable.)) %THEN %DO;
      %PUT %STR(ERR)OR: [table_summary] vars= names &variable., and &ds. does not have it.;
      %PUT %STR(ERR)OR: [table_summary]   fix: give vars= variables of data=, as age sex#.;
      %LET ok = 0;  /* the call stops after every such variable is named */
    %END;
  %END;
  %IF not &ok. %THEN %DO;
    %LET rc = %SYSFUNC(CLOSE(&dsid.));  /* data= closed */
    %RETURN;
  %END;
  %DO i = 1 %TO %SYSFUNC(COUNTW(&vars., %STR( )));
    %LET token    = %SCAN(&vars., &i., %STR( ));  /* a variable with its mark */
    %LET variable = %SCAN(&token., 1, #);         /* its name */
    %IF %SYSFUNC(VARTYPE(&dsid., %SYSFUNC(VARNUM(&dsid., &variable.)))) = C
        and not %INDEX(&token., #) %THEN %DO;
      %PUT %STR(ERR)OR: [table_summary] vars= has the character variable &variable. without a #.;
      %PUT %STR(ERR)OR: [table_summary]   fix: write &variable.# (its categories are counted).;
      %LET ok = 0;  /* the call stops after every such variable is named */
    %END;
  %END;
  %LET rc = %SYSFUNC(CLOSE(&dsid.));  /* data= closed */
  %IF not &ok. %THEN %RETURN;

  %LET pop = &data.;  /* the population: data=, or its records of where= */
  %IF %LENGTH(%SUPERQ(where)) %THEN %LET pop = &name._pop;  /* made by the long program */
  %LET program = _tsumm;  /* the file reference of the long program */
  %IF %QUPCASE(%SUPERQ(show)) = YES or %QUPCASE(%SUPERQ(show)) = NO %THEN %DO;
    FILENAME &program. TEMP;
  %END;
  %ELSE %DO;
    %_spl_folder(table_summary, %SUPERQ(show))
    FILENAME &program. "%SUPERQ(show)";
  %END;
  %IF %QUPCASE(%SUPERQ(show)) = YES %THEN %LET source = / SOURCE2;  /* the program in the log */

  /* Step 2: the long program of the table is written: one call per variable, %stack, %table */
  DATA _NULL_;
    FILE &program. LRECL=400;
    LENGTH vars names levels results part $32767 token variable twin item $256 block own $2000
           macro $32 line $2200;
    ARRAY pn {12} $8;
    ARRAY pv {12} $2000;
    vars   = %_spl_quote(vars);
    names  = %_spl_quote(names);
    levels = %_spl_quote(levels);
    dsid   = OPEN("&ds.");
    %IF %LENGTH(%SUPERQ(where)) %THEN %DO;
      line = %_spl_quote(where);
      PUT '/* The population: one row per subject */'
        / "DATA &pop.;"
        / "  SET &data.;"
        / '  WHERE ' line +(-1) ';'
        / 'RUN;'
        /;
    %END;
    DO i = 1 TO COUNTW(vars, ' ');
      token    = SCAN(vars, i, ' ');
      variable = LOWCASE(SCAN(token, 1, '#'));
      twin     = LOWCASE(SCAN(token, 2, '#'));
      /* the label of the block: names=, else the label of the variable, else its name */
      block = VARLABEL(dsid, VARNUM(dsid, variable));
      IF block = ' ' THEN block = variable;
      DO j = 1 TO COUNTW(names, ' ', 'q');
        item = SCAN(names, j, ' ', 'q');
        IF LOWCASE(SCAN(item, 1, '=')) = variable THEN
          block = DEQUOTE(SUBSTR(item, INDEX(item, '=') + 1));
      END;
      /* the planned categories of this variable: its part of levels= */
      own   = ' ';
      _mine = 0;
      DO j = 1 TO COUNTW(levels, ' ', 'q');
        item = SCAN(levels, j, ' ', 'q');
        IF NVALID(item, 'v7') THEN DO;
          IF LOWCASE(item) = variable THEN _mine = 1;
          ELSE                             _mine = 0;
        END;
        IF _mine THEN own = CATX(' ', own, item);
      END;
      n     = 1;
      pn{1} = 'data';
      pv{1} = "&pop.";
      n     = n + 1;
      pn{n} = 'var';
      pv{n} = variable;
      n     = n + 1;
      pn{n} = 'by';
      pv{n} = LOWCASE("&by.");
      IF INDEX(token, '#') THEN DO;
        macro = '%freq';
        IF twin NE ' ' THEN DO;
          n     = n + 1;
          pn{n} = 'keep';
          pv{n} = twin;
        END;
        IF own NE ' ' THEN DO;
          n     = n + 1;
          pn{n} = 'levels';
          pv{n} = own;
        END;
        part = %_spl_quote(catstats);
      END;
      ELSE DO;
        macro = '%describe';
        part  = %_spl_quote(stats);
      END;
      n     = n + 1;
      pn{n} = 'total';
      pv{n} = LOWCASE("&total.");
      IF part NE ' ' THEN DO;
        n     = n + 1;
        pn{n} = 'stats';
        pv{n} = part;
      END;
      n       = n + 1;
      pn{n}   = 'label';
      pv{n}   = QUOTE(STRIP(block));
      n       = n + 1;
      pn{n}   = 'out';
      pv{n}   = CATS("&name._", variable, '_summ');
      results = CATX(' ', results, pv{n});
      LINK call;
    END;
    /* the blocks one under another, in the order of vars= */
    PUT '%stack(';
    line = ' ';
    DO i = 1 TO COUNTW(results, ' ');
      IF LENGTH(line) + LENGTH(SCAN(results, i, ' ')) > 92 THEN DO;
        PUT '    ' line;
        line = ' ';
      END;
      line = CATX(' ', line, SCAN(results, i, ' '));
    END;
    PUT '    ' line;
    PUT "  , out = &name."
      / ')'
      /;
    /* the TITLE and FOOTNOTE statements of title= and footnote= */
    %_spl_program(titles)
    /* the columns with their N, the numbers file, the rows as printed, the print */
    macro = '%table';
    n     = 1;
    pn{1} = 'data';
    pv{1} = "&name.";
    n     = n + 1;
    pn{n} = 'n';
    pv{n} = "&pop.";
    n     = n + 1;
    pn{n} = 'var';
    pv{n} = LOWCASE("&by.");
    IF "&order." NE ' ' THEN DO;
      n     = n + 1;
      pn{n} = 'order';
      pv{n} = LOWCASE("&order.");
    END;
    n     = n + 1;
    pn{n} = 'total';
    pv{n} = LOWCASE("&total.");
    part  = %_spl_quote(format);
    IF part NE ' ' THEN DO;
      n     = n + 1;
      pn{n} = 'format';
      pv{n} = part;
    END;
    part = %_spl_quote(file);
    IF part NE ' ' THEN DO;
      n     = n + 1;
      pn{n} = 'file';
      pv{n} = part;
    END;
    n     = n + 1;
    pn{n} = 'setup';
    pv{n} = "&name._print";
    IF "%UPCASE(&debug.)" = 'YES' THEN DO;
      n     = n + 1;
      pn{n} = 'debug';
      pv{n} = 'yes';
    END;
    LINK call;
    %_spl_program(untitled)
    rc = CLOSE(dsid);
    STOP;
    RETURN;

    /* one call: a parameter per line, the equal signs under each other */
    CALL:
      _WIDE = 0;
    DO k = 1 TO n;
      _wide = MAX(_wide, LENGTH(pn{k}));
    END;
    PUT macro +(-1) '(';
    DO k = 1 TO n;
      IF k = 1 THEN line = '    ';
      ELSE          line = '  , ';
      line = SUBSTR(line, 1, 4) || SUBSTR(pn{k} || REPEAT(' ', 12), 1, _wide) || ' = ' || pv{k};
      _len = LENGTH(line);
      PUT line $VARYING2200. _len;
    END;
    PUT ')';
    RETURN;
  RUN;

  /* Step 3: the long program runs */
  %INCLUDE &program. &source.;
  %_spl_end(table_summary, &t0., &debug.)
%MEND table_summary;
