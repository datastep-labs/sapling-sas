/*******************************************************************************
| Macro Name    : layout.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.9.1
| Created By    : Sapling
| Date          : 27NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : Returns the display data set of a table: one row per printed
|                 line and one column per group. %print prints it; %table runs
|                 %columns, %ard, %layout and %print in one call. The display
|                 data set is the table as the shells show it: each row a
|                 printed line, each cell a text. %layout computes nothing:
|                 every number is the TEXT of a result. The rows:
|                 - Each block starts with its label, with a blank row between
|                   two blocks.
|                 - The levels of the groups other than the column variable are
|                   indented by two blanks each: a term under its class, a visit
|                   under its parameter, vs B under A.
|                 - The levels are in the order of their numeric twin (AVISITN
|                   for AVISIT, PARAMN for PARAMCD: the name with an N added),
|                   else of their values. A level of PARAMCD shows its PARAM.
|                 - A frequency block (only the statistics n, pct, events, lcl
|                   and ucl) has one line per category. Any other block has one
|                   line per kind of statistic, by the line table below.
|                 - The p-value of each category (a test of each term, in a
|                   block of the same label) stands in the row of its category.
|                 - A result has at most four groups besides the column variable
|                   and the page variable.
|                 The columns:
|                 - C1 ... Cn: one column per group, with its header and N from
|                   %columns.
|                 - C99, All groups: the numbers of a result without the column
|                   variable, such as a p-value of all groups.
|                 The line table: the order of a line, its label, then its
|                 template.
|                 - 0, a category of a frequency block: {n} {pct} {events}
|                   ({lcl}, {ucl})
|                 - 1, n: {n}
|                 - 2, Events: {events}
|                 - 2.5, Patient-years: {exposure}
|                 - 3, Mean (SD): {mean} ({sd}) [{se}]. With se and no sd the
|                   label is Mean (SE); with both, Mean (SD) [SE].
|                 - 4, Median: {median}
|                 - 5, Q1, Q3: {q1}, {q3}
|                 - 6, Min, Max: {min}, {max}
|                 - 7, LS mean (SE): {lsmean} ({lsmean_se})
|                 - 8, Difference (SE): {diff} ({diff_se})
|                 - 9, the estimate, labelled by its STAT (hr Hazard ratio, or
|                   Odds ratio, irr Rate ratio, rd Risk difference, rr Relative
|                   risk, rate Rate per 100 patient-years, else Estimate):
|                   {estimate}
|                 - 10, Confidence interval: ({lcl}, {ucl})
|                 - 11, p-value: {pval}
|                 - 11.5, Adjusted p-value: {padj}
|                 - 12, any other STAT, labelled by its name: {value}
|                 In a template:
|                 - A part that is missing leaves out its piece with its
|                   brackets or its comma: a confidence interval without its
|                   upper limit prints the lower limit alone.
|                 - A TEXT that has the brackets of its piece already is not
|                   bracketed twice.
|                 - The counts of a frequency block are right aligned to the
|                   widest count.
|                 The setup (setup=):
|                 - The global macro variable keeps the parameters of %print for
|                   out=: data=, by=row, var=c:, together=grp and label=row=" "
|                   with the labels of label=; also page=, rows=, file= and
|                   nodata= when they are given to %layout. A NOTE in the log
|                   shows it.
|                 - %print(&name.) prints the display data set again after a
|                   change. A parameter that is not in the setup is added after
|                   it: %print(&name., file=...).
|                 - A parameter that is in the setup cannot be given again, as
|                   SAS stops a call that has a keyword twice: give it to
|                   %layout, or write the whole %print call.
|                 When data= has no row, the display data set has no row, and
|                 %print prints the text of nodata=.
| Procedure     : DATA steps, PROC FORMAT, PROC SORT, PROC TRANSPOSE
| Proven        : the tables of the dummy study SYNHTN01 (every program ran with
|                 a clean log, also as a program without a macro, 12 of 12) and
|                 the cases of setup= in node tools/print_sas.ts; ran on SAS 9.4
|                 M9, 2026-11-12; the 12 tables of the CDISC pilot (the p value
|                 of each term in T14_5_2), 2026-11-13
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| data        The stacked results (out= of %stack)                Required
| columns     The columns (out= of %columns): the place, the      Required
|             header and the N of each column
| var         The column variable of the results: the same        Required
|             variable as var= of %columns
| page        A group variable of the results, such as page =     Optional
|             sex: one page per value, in the order of its
|             numeric twin (SEXN), else of its values. It is no
|             level of the rows; each page starts with its first
|             block, and the header of a column on a page has
|             the N of that page. Give %columns the same page=.
|             It goes into the setup.
| format      The labels of categories: pairs of a variable and   Optional
|             a character format, as in a FORMAT statement
|             (format = sex $sexf. race $racef.). A value that
|             the format decodes shows its label.
| label       Column labels for %print: name="text" pairs,        Optional
|             separated by blanks. They go into the setup after
|             row=" ".
| rows        The rows of a page for %print (rows= of %print): a  Optional
|             whole number. It goes into the setup.
| file        The output of %print: a path without its extension  Optional
|             (file= of %print). It goes into the setup.
| nodata      The text that %print prints when there is no row    Optional
|             (nodata= of %print). It goes into the setup.
| setup       The name of a global macro variable that keeps the  Optional
|             %print call of out=: a SAS name that does not
|             start with SYS or SPL_. When not given, no setup
|             is made.
| out         The name of the display data set                    Required
| debug       yes: keep the work data sets _layout_*              no
|-------------------------------------------------------------------------------
|
| Output        : OUT: the display data set, one row per printed line: GRP (the
|                 rows that stay on one page: a block, or a level of its first
|                 group; a row of a value of all groups, such as a p-value in
|                 C99 only, has the GRP of the rows of its block before it), ROW
|                 (the label of the line, indented, with the format $CHARw.), C1
|                 ... Cn (the cells, labelled with the header of their column)
|                 and C99 (All groups: only when a result has a number without
|                 the column variable). With page=: also the page variable (with
|                 its format of format=) and HEAD_C1 ... HEAD_Cn, the header of
|                 each column on its page; C1 ... Cn are then labelled with the
|                 column value. SETUP: with setup=, the global macro variable of
|                 that name.
|
| Example:
|
 %layout(
     data    = t14_2_1
   , columns = t14_2_1_cols
   , var     = trt01a
   , format  = sex $sexf.
   , file    = &spl_out./tlf/t14_2_1
   , setup   = t14_2_1_print
   , out     = t14_2_1_display
 )
|
|-------------------------------------------------------------------------------
| Change Log :
| Date        Programmer   Description
|-------------------------------------------------------------------------------
| 12-NOV-2026 Sapling      1.2.0: initial version: the rows of a table of the
|                          printer of 1.1.0 (_spl_cells, _spl_lines) as a data
|                          set of the program, printed by the owner's %print.
| 12-NOV-2026 Sapling      1.2.0: every step in the macro (the inner parts
|                          _spl_cells, _spl_lines and _spl_formats are
|                          gone); the line table with a template per line:
|                          Mean (SD) prints 58.4 (10.40), a confidence
|                          interval (1.23, 4.56); labels= for the labels of
|                          categories. No number changes.
| 12-NOV-2026 Sapling      1.4.0: setup= keeps the %print call of the display
|                          data set in a global macro variable, with label=,
|                          rows=, file= and nodata= for it; %print(&name.)
|                          prints it again after a change. No number changes.
| 13-NOV-2026 Sapling      1.5.0: the p-value of each category (a test of each
|                          term) in the row of its category, not in a block
|                          of its own that repeats every term (the CDISC
|                          pilot: T14_5_2, as R and the CSR print it). No
|                          number changes.
| 13-NOV-2026 Sapling      1.8.0: labels= is now format= (its value is a list as
|                          in a FORMAT statement).
| 16-NOV-2026 Sapling      1.9.0: a block of n, pct and the interval (lcl, ucl),
|                          as %proportion gives it, has one line per category: n
|                          (pct) (lcl, ucl); it had three lines. A result with
|                          a variable R, V, K or C (a response named r): its
|                          arrays and its hash are _ar, _av, _ak and _hc. The
|                          license line; the example in the house case. No
|                          number changes.
| 16-NOV-2026 Sapling      1.9.1: the work data sets of the p value of each
|                          category only when a table has one: no notes of 0
|                          observations (DEV-007); the empty display has no note
|                          of uninitialized variables (DEV-008). No number
|                          changes.
| 27-NOV-2026 Sapling      1.9.1: page=: one page per value of a BY variable,
|                          the header of each column with the N of its page.
|                          Without page= no change.
| 27-NOV-2026 Sapling      1.9.1: the example runs on the example data
|                          (sas/examples). The text of the header for the
|                          manual: the summary, the form of each parameter. No
|                          number changes.
| 27-NOV-2026 Sapling      1.9.1: The header names no internal tool. No number
|                          changes.
| 27-NOV-2026 Sapling      1.9.1: a row of a value of all groups (C99 only, such
|                          as the p-value of a block) has the GRP of the rows of
|                          its block before it: a page break no longer separates
|                          a p-value from its block. No number changes.
|
*******************************************************************************/
%MACRO layout(
     data    =      /* The results (%stack) */
   , columns =      /* The columns (%columns) */
   , var     =      /* The column variable of the results */
   , page    =      /* A BY variable of the results: one page per value */
   , format  =      /* The labels of categories: sex $sexf. race $racef. */
   , label   =      /* Column labels for %print: name="text" pairs */
   , rows    =      /* The rows of a page for %print */
   , file    =      /* The output for %print without its extension */
   , nodata  =      /* The text %print prints when there is no row */
   , setup   =      /* The macro variable that keeps the %print call */
   , out     =      /* The display data set */
   , debug   = no   /* yes: keep the work data sets _layout_* */
) / DES = 'The display data set of a table: its rows and a column per group (DATA steps)';
  %LOCAL t0 i v nlab dsid ncol rowkeys twins hasparam deep nwidth width haspval made list npcat
         nfcat upage ptwin pformat catkeys hashkeys nopage;
  %LET t0 = %_spl_begin(layout);

  /* Step 1: the parameters */
  %IF not %_spl_need(layout, data columns var out) %THEN %RETURN;
  %IF not %_spl_oneof(layout, debug, yes no) %THEN %RETURN;
  %IF %LENGTH(&format.) %THEN %DO;
    %IF not %SYSFUNC(PRXMATCH(/^(\s*\w+\s+\$\w+\.)+\s*$/, &format.)) %THEN %DO;
      %PUT %STR(ERR)OR: [layout] format=&format. is not a list of variable and format.;
      %PUT %STR(ERR)OR: [layout]   fix: write it as in a FORMAT statement: format=sex $sexf.;
      %RETURN;
    %END;
  %END;
  %IF %LENGTH(&page.) %THEN %DO;
    %IF not %_spl_vars(layout, data, page) %THEN %RETURN;
    %IF %UPCASE(&page.) = %UPCASE(&var.) %THEN %DO;
      %PUT %STR(ERR)OR: [layout] page=&page. is the column variable var=&var.;
      %PUT %STR(ERR)OR: [layout]   fix: give page= another BY variable, such as sex.;
      %RETURN;
    %END;
    %LET v    = 0;
    %LET dsid = %SYSFUNC(OPEN(&columns.));
    %IF &dsid. %THEN %DO;
      %LET v    = %SYSFUNC(VARNUM(&dsid., &page.));
      %LET dsid = %SYSFUNC(CLOSE(&dsid.));
    %END;
    %IF &v. = 0 %THEN %DO;
      %PUT %STR(ERR)OR: [layout] columns=&columns. has no page=&page.: its N is not the N of a page;
      %PUT %STR(ERR)OR: [layout]   fix: give %NRSTR(%columns) the same page=&page..;
      %RETURN;
    %END;
  %END;
  %IF %LENGTH(&setup.) %THEN %DO;
    %IF not %SYSFUNC(NVALID(&setup., v7)) %THEN %DO;
      %PUT %STR(ERR)OR: [layout] setup=&setup. is not a SAS name;
      %PUT %STR(ERR)OR: [layout]   fix: give setup= a name such as t_sex_print.;
      %RETURN;
    %END;
    %IF %SYMLOCAL(&setup.) or %SYSFUNC(PRXMATCH(/^(SYS|SPL_)/i, &setup.)) %THEN %DO;
      %PUT %STR(ERR)OR: [layout] setup=&setup. is a name of a macro or of SAS;
      %PUT %STR(ERR)OR: [layout]   fix: give setup= another name, such as t_sex_print.;
      %RETURN;
    %END;
  %END;

  %LET var      = %UPCASE(&var.);             /* the column variable, in upper case */
  %LET upage    = %UPCASE(&page.);            /* the page variable, in upper case */
  %LET ncol     = %_spl_nobs(&columns.);      /* the number of columns */
  %LET nlab     = %SYSFUNC(COUNTW(%STR( )&format., %STR( )));  /* the words of format= */
  %LET rowkeys  = ord block freq k1 v1 r1 k2 v2 r2 k3 v3 r3 k4 v4 r4;  /* the keys of a row */
  %LET catkeys  = block v1-v4;                /* the keys of a category */
  %LET hashkeys = 'block', 'v1', 'v2', 'v3', 'v4';  /* the same, for a hash */
  %LET nwidth   = 1;                          /* the width of the widest count */
  %LET width    = 1;                          /* the width of the row labels */
  %LET haspval  = 0;                          /* 1: a value of all groups (C99) */
  %LET deep     = 0;                          /* the most levels of a result */
  %LET made     = 0;                          /* 1: OUT is made */
  %LET dsid     = %SYSFUNC(OPEN(&data.));     /* the results, open to read their variables */
  %LET hasparam = %SYSFUNC(VARNUM(&dsid., PARAM));  /* the column of PARAM (0: none) */
  /* the variables with a numeric twin for the order of the rows (AVISIT:AVISITN, PARAMCD:PARAMN) */
  %DO i = 1 %TO %SYSFUNC(ATTRN(&dsid., NVARS));
    %LET v = %UPCASE(%SYSFUNC(VARNAME(&dsid., &i.)));
    %IF &v. = PARAMCD %THEN %DO;
      %IF %SYSFUNC(VARNUM(&dsid., PARAMN)) %THEN %LET twins = &twins. PARAMCD:PARAMN;
    %END;
    %ELSE %IF %LENGTH(&v.) < 32 %THEN %DO;
      %IF %SYSFUNC(VARNUM(&dsid., &v.N)) %THEN %LET twins = &twins. &v.:&v.N;
    %END;
  %END;
  %IF %LENGTH(&page.) %THEN %DO;
    /* a page in the order of its numeric twin (SEXN), else of its values */
    %IF %SYSFUNC(VARNUM(&dsid., &upage.N)) %THEN %LET ptwin = &upage.N;
    %ELSE %LET ptwin = 0;
    %LET rowkeys  = _pk &page. &rowkeys.;
    %LET catkeys  = &page. &catkeys.;
    %LET hashkeys = "&upage.", &hashkeys.;
    %DO i = 1 %TO &nlab. %BY 2;
      %IF %UPCASE(%SCAN(&format., &i., %STR( ))) = &upage. %THEN
        %LET pformat = %SCAN(&format., %EVAL(&i. + 1), %STR( ));
    %END;
  %END;
  %LET dsid = %SYSFUNC(CLOSE(&dsid.));  /* the results are closed */

  /* Step 2: no row: the display data set without a row (%print says so) */
  %IF %_spl_nobs(&data.) = 0 %THEN %DO;
    DATA &out.;
      LENGTH grp 8 row $200 c1 $80 &page. $200;
      CALL MISSING(OF grp row c1 &page.);
      STOP;
    RUN;
    %LET made = 1;
    %GOTO finish;
  %END;

  /* Step 3: the line table: line and part of each statistic, label and template of a line */
  PROC FORMAT;
    INVALUE _layout_line
      'n' = 1
      'events' = 2
      'exposure' = 2.5
      'mean', 'sd', 'se' = 3
      'median' = 4
      'q1', 'q3' = 5
      'min', 'max' = 6
      'lsmean', 'lsmean_se' = 7
      'diff', 'diff_se' = 8
      'estimate', 'hr', 'or', 'irr', 'rd', 'rr', 'rate' = 9
      'lcl', 'ucl' = 10
      'pval' = 11
      'padj' = 11.5
      OTHER = 12;
    INVALUE _layout_part
      'sd', 'q3', 'max', 'lsmean_se', 'diff_se', 'ucl' = 2
      'se' = 3
      OTHER = 1;
    VALUE _layout_label
      1 = 'n'
      2 = 'Events'
      2.5 = 'Patient-years'
      3 = 'Mean (SD)'
      4 = 'Median'
      5 = 'Q1, Q3'
      6 = 'Min, Max'
      7 = 'LS mean (SE)'
      8 = 'Difference (SE)'
      9 = 'Estimate'
      10 = 'Confidence interval'
      11 = 'p-value'
      11.5 = 'Adjusted p-value'
      OTHER = ' ';
    VALUE $_layout_mean
      'sd' = 'Mean (SD)'
      'se' = 'Mean (SE)'
      'sd se' = 'Mean (SD) [SE]'
      OTHER = 'Mean (SD)';
    VALUE $_layout_estimate
      'hr' = 'Hazard ratio'
      'or' = 'Odds ratio'
      'irr' = 'Rate ratio'
      'rd' = 'Risk difference'
      'rr' = 'Relative risk'
      'rate' = 'Rate per 100 patient-years'
      OTHER = 'Estimate';
    VALUE _layout_template
      0 = '{n} {pct} {events} ({lcl}, {ucl})'
      1 = '{n}'
      2 = '{events}'
      2.5 = '{exposure}'
      3 = '{mean} ({sd}) [{se}]'
      4 = '{median}'
      5 = '{q1}, {q3}'
      6 = '{min}, {max}'
      7 = '{lsmean} ({lsmean_se})'
      8 = '{diff} ({diff_se})'
      9 = '{estimate}'
      10 = '({lcl}, {ucl})'
      11 = '{pval}'
      11.5 = '{padj}'
      OTHER = '{value}';
  RUN;

  /* Step 4: the kind of each block: a frequency block has only n, pct and events */
  DATA _layout_results;
    SET &data.;
    IF stat IN ('n' 'pct' 'events' 'lcl' 'ucl') THEN notfreq = 0;
    ELSE                                             notfreq = 1;
  RUN;
  PROC SUMMARY DATA=_layout_results NWAY;
    CLASS result;
    VAR notfreq;
    OUTPUT OUT=_layout_kinds(KEEP=result kind) MAX=kind;
  RUN;
  PROC SORT DATA=_layout_results; BY result; RUN;

  /* Step 5: the place of each result: its column, its levels and their order, its line and part */
  %LET nopage = 0;
  DATA _NULL_;
    SET _layout_results END=last;
    RETAIN most 0 nopage 0;
    nlev = COUNTW(groups, ' ');
    IF INDEXW(UPCASE(groups), "&var.") > 0 THEN nlev = nlev - 1;
    %IF %LENGTH(&page.) %THEN %DO;
      IF INDEXW(UPCASE(groups), "&upage.") > 0 THEN nlev = nlev - 1;
      ELSE                                          nopage = nopage + 1;
    %END;
    most = MAX(most, nlev);
    IF last THEN DO;
      CALL SYMPUTX('deep', most, 'L');
      CALL SYMPUTX('nopage', nopage, 'L');
    END;
  RUN;
  %IF &nopage. > 0 %THEN %DO;
    %PUT %STR(ERR)OR: [layout] &nopage. row(s) of data=&data. are not by page=&page..;
    %PUT %STR(ERR)OR: [layout]   fix: add &page. to by= of its macro, such as by=trt01a &page..;
    %GOTO finish;
  %END;
  %IF %LENGTH(&page.) %THEN %DO;
    /* the columns: the largest COL, as each page has every column */
    DATA _NULL_;
      SET &columns. END=last;
      RETAIN most 0;
      most = MAX(most, col);
      IF last THEN CALL SYMPUTX('ncol', most, 'L');
    RUN;
  %END;
  %IF &deep. > 4 %THEN %DO;
    %PUT %STR(ERR)OR: [layout] a result of data=&data. has &deep. groups besides var= (4 at most).;
    %PUT %STR(ERR)OR: [layout]   fix: give each result at most 4 groups besides var=.;
    %GOTO finish;
  %END;
  DATA _layout_places;
    LENGTH colvalue r1-r4 v1-v4 name _value $200 _name $32;
    IF _N_ = 1 THEN DO;
      DECLARE HASH _hc(DATASET: "&columns.");
      _hc.defineKey('COLVALUE');
      _hc.defineData('COL');
      _hc.defineDone();
    END;
    MERGE _layout_results _layout_kinds;
    BY result;
    ARRAY _ar {4} r1-r4;
    ARRAY _av {4} v1-v4;
    ARRAY _ak {4} k1-k4;
    CALL MISSING(OF k1-k4);
    IF kind = 0 THEN freq = 1;
    ELSE             freq = 0;
    col  = 99;
    nlev = 0;
    %IF %LENGTH(&page.) %THEN %DO;
      _pk = &ptwin.;
    %END;
    DO _w = 1 TO COUNTW(groups, ' ');
      _name = UPCASE(SCAN(groups, _w, ' '));
      IF _name = "&var." THEN DO;
        colvalue = STRIP(VVALUEX(_name));
        _found   = _hc.find();
      END;
      %IF %LENGTH(&page.) %THEN %DO;
        ELSE IF _name = "&upage." THEN;
      %END;
      ELSE DO;
        /* V: the text of the value (the order of rows without a twin); R: the text shown */
        nlev      = nlev + 1;
        _value    = STRIP(VVALUEX(_name));
        _av{nlev} = _value;
        %IF &hasparam. %THEN %DO;
          IF _name = 'PARAMCD' AND param NE ' ' THEN _av{nlev} = param;
        %END;
        _ar{nlev} = _av{nlev};
        /* a value that the format of format= decodes shows its label (an undecoded value comes
           back as it is, cut to the width of the format) */
        %DO i = 1 %TO &nlab. %BY 2;
          IF _name = "%UPCASE(%SCAN(&format., &i., %STR( )))" THEN DO;
            _LAB&i. = PUT(_value, %SCAN(&format., %EVAL(&i. + 1), %STR( )));
            IF _lab&i. NE SUBSTR(_value, 1, VLENGTH(_lab&i.)) THEN _ar{nlev} = _lab&i.;
          END;
        %END;
        IF _name = 'VERSUS' AND _av{nlev} NE ' ' THEN DO;
          _av{nlev} = 'vs ' || _av{nlev};
          _ar{nlev} = 'vs ' || _ar{nlev};
        END;
        %DO i = 1 %TO %SYSFUNC(COUNTW(&twins., %STR( )));
          IF _name = "%SCAN(%SCAN(&twins., &i., %STR( )), 1, :)" THEN _ak{nlev} =
              %SCAN(%SCAN(&twins., &i., %STR( )), 2, :);
        %END;
      END;
    END;
    /* the line and the part by the line table; a frequency block has one line per category */
    IF freq THEN DO;
      line = 0;
      part = WHICHC(stat, 'n', 'pct', 'events', 'lcl', 'ucl');
    END;
    ELSE DO;
      line = INPUT(stat, _layout_line.);
      part = INPUT(stat, _layout_part.);
    END;
         IF line = 9  THEN name = PUT(stat, $_layout_estimate.);
    ELSE IF line = 12 THEN name = stat;
    ELSE                   name = ' ';
    KEEP &rowkeys. line name col part stat text;
  RUN;

  /* Step 6: the cells: one per row, line and column, its parts put in the template of the line */
  DATA _NULL_;
    SET _layout_places END=last;
    RETAIN widest 1;
    IF freq AND part = 1 THEN widest = MAX(widest, LENGTHN(text));
    IF last THEN CALL SYMPUTX('nwidth', widest, 'L');
  RUN;
  PROC SORT DATA=_layout_places; BY &rowkeys. line name col part; RUN;
  DATA _layout_cells(KEEP=&rowkeys. line name col cell)
       _layout_lines(KEEP=&rowkeys. line name label);
    SET _layout_places;
    BY &rowkeys. line name col;
    LENGTH cell $80 label $200 _tpl $40 _piece $16 _spread $8;
    ARRAY _t {5} $80 _TEMPORARY_;
    ARRAY _lead {5} $16 _TEMPORARY_;
    ARRAY _close {5} $16 _TEMPORARY_;
    ARRAY _keepo {5} _TEMPORARY_;
    ARRAY _keepc {5} _TEMPORARY_;
    RETAIN _hassd _hasse;
    IF FIRST.name THEN DO;
      _hassd = 0;
      _hasse = 0;
    END;
    IF FIRST.col THEN DO _k = 1 TO 5;
      _t{_k} = ' ';
    END;
    IF stat = 'sd' THEN _hassd = 1;
    IF stat = 'se' THEN _hasse = 1;
    /* a count right aligned, so that the counts and their percents stand in columns */
    IF freq AND part = 1 AND LENGTHN(text) < &nwidth. THEN
      text = REPEAT(' ', &nwidth. - LENGTHN(text) - 1) || text;
    _t{part} = text;
    IF LAST.col THEN DO;
      /* the pieces of the template: a part with its separator and brackets (a blank is ~) */
      _tpl = TRANSLATE(TRIM(PUT(line, _layout_template.)), '~', ' ');
      _np  = 0;
      _pos = 1;
      DO WHILE (_np < 5 AND FIND(_tpl, '{', _pos) > 0);
        _np         = _np + 1;
        _open       = FIND(_tpl, '{', _pos);
        _lead{_np}  = SUBSTRN(_tpl, _pos, _open - _pos);
        _pos        = FIND(_tpl, '}', _open) + 1;
        _close{_np} = ' ';
        DO WHILE (SUBSTRN(_tpl, _pos, 1) IN (')' ']'));
          _close{_np} = CATS(_close{_np}, SUBSTR(_tpl, _pos, 1));
          _pos        = _pos + 1;
        END;
      END;
      /* a bracket stays when its parts are there and its part has no brackets of its own */
      DO _k = 1 TO _np;
        _keepo{_k} = 1;
        _keepc{_k} = 1;
      END;
      DO _k = 1 TO _np;
        IF INDEXC(_lead{_k}, '([') > 0 THEN DO;
          _j = _k;
          DO WHILE (_j < _np AND _close{_j} = ' ');
            _j = _j + 1;
          END;
          _all = 1;
          DO _i = _k TO _j;
            IF _t{_i} = ' ' THEN _all = 0;
          END;
          IF _j = _k AND FIRST(LEFT(_t{_k})) = FIRST(COMPRESS(_lead{_k}, ',~')) THEN _all = 0;
          IF NOT _all THEN DO;
            _keepo{_k} = 0;
            _keepc{_j} = 0;
          END;
        END;
      END;
      /* the cell: each part that is there with its piece; no separator before the first */
      cell   = ' ';
      _first = 1;
      DO _k = 1 TO _np;
        IF _t{_k} NE ' ' THEN DO;
          _piece = _lead{_k};
          IF NOT _keepo{_k} THEN _piece = COMPRESS(_piece, '([');
          IF _first THEN _piece = COMPRESS(_piece, ',~');
          cell = TRIMN(cell) || TRIMN(_piece) || TRIMN(_t{_k});
          IF _keepc{_k} THEN cell = TRIMN(cell) || TRIMN(_close{_k});
          _first = 0;
        END;
      END;
      cell = TRANSLATE(cell, ' ', '~');
      OUTPUT _layout_cells;
    END;
    /* the label of the line: a line of means by the spreads it has in any column */
    IF LAST.name THEN DO;
      _spread = CATX(' ', IFC(_hassd, 'sd', ' '), IFC(_hasse, 'se', ' '));
           IF line = 3    THEN label = PUT(_spread, $_layout_mean.);
      ELSE IF name NE ' ' THEN label = name;
      ELSE                     label = PUT(line, _layout_label.);
      OUTPUT _layout_lines;
    END;
  RUN;

  /* Step 7: the columns side by side */
  PROC TRANSPOSE DATA=_layout_cells OUT=_layout_wide(DROP=_NAME_) PREFIX=c;
    BY &rowkeys. line name;
    ID col;
    VAR cell;
  RUN;
  DATA _layout_wide;
    MERGE _layout_wide _layout_lines;
    BY &rowkeys. line name;
  RUN;

  /* Step 7b: the p value of each category (a test of each term) in the row of its category */
  /* the rows of such a p value and of the categories are counted first: a table without them
     makes no work data set with 0 observations */
  %LET npcat = 0;
  %LET nfcat = 0;
  DATA _NULL_;
    LENGTH c1-c&ncol. c99 $80;
    CALL MISSING(OF c1-c&ncol. c99);
    SET _layout_wide END=_last;
    IF freq = 0 AND line = 11 AND v1 NE ' ' AND c99 NE ' '
       AND CMISS(OF c1-c&ncol.) = &ncol. THEN _np + 1;
    ELSE IF freq = 1 AND line = 0 THEN _nf + 1;
    IF _last THEN DO;
      CALL SYMPUTX('npcat', SUM(_np, 0));
      CALL SYMPUTX('nfcat', SUM(_nf, 0));
    END;
  RUN;
  %IF &npcat. > 0 and &nfcat. > 0 %THEN %DO;
    DATA _layout_pcats(KEEP=&catkeys. _p) _layout_fcats(KEEP=&catkeys.);
      LENGTH c1-c&ncol. c99 _p $80;
      CALL MISSING(OF c1-c&ncol. c99);
      SET _layout_wide;
      IF freq = 0 AND line = 11 AND v1 NE ' ' AND c99 NE ' '
         AND CMISS(OF c1-c&ncol.) = &ncol. THEN DO;
        _p = c99;
        OUTPUT _layout_pcats;
      END;
      ELSE IF freq = 1 AND line = 0 THEN OUTPUT _layout_fcats;
    RUN;
    /* only a category with one p value of its own, in a block of the same label */
    PROC SORT DATA=_layout_pcats; BY &catkeys.; RUN;
    DATA _layout_pcats;
      SET _layout_pcats;
      BY &catkeys.;
      IF FIRST.v4 AND LAST.v4;
    RUN;
    DATA _layout_wide;
      LENGTH c1-c&ncol. c99 _p $80;
      IF _N_ = 1 THEN DO;
        CALL MISSING(_p);
        DECLARE HASH p(DATASET: '_layout_pcats');
        p.defineKey(&hashkeys.);
        p.defineData('_p');
        p.defineDone();
        DECLARE HASH f(DATASET: '_layout_fcats');
        f.defineKey(&hashkeys.);
        f.defineDone();
      END;
      CALL MISSING(OF c1-c&ncol. c99);
      SET _layout_wide;
      IF freq = 1 AND line = 0 THEN DO;
        IF p.find() = 0 THEN c99 = _p;
      END;
      ELSE IF freq = 0 AND line = 11 AND CMISS(OF c1-c&ncol.) = &ncol. THEN DO;
        IF p.check() = 0 AND f.check() = 0 THEN DELETE;
      END;
      DROP _p;
    RUN;
  %END;

  /* Step 8: the printed rows: a block heading, a heading per level that begins, the line */
  DATA _layout_rows;
    LENGTH row prevblock $200 c1-c&ncol. c99 $80;
    SET _layout_wide;
    BY &rowkeys.;
    ARRAY r {4} r1-r4;
    ARRAY isfirst {4} _f1-_f4;
    ARRAY c {*} c1-c&ncol. c99;
    ARRAY saved {%EVAL(&ncol. + 1)} $80 _TEMPORARY_;
    RETAIN rowno 0 grp 0 prevblock ' ';
    %IF %LENGTH(&page.) %THEN %DO;
      /* a page starts with the heading of its first block, without a blank row before it */
      IF first.&page. THEN DO;
        prevblock = ' ';
        rowno     = 0;
      END;
    %END;
    /* the rows that stay on one page: a block, or a level of its first group; */
    /* a row of a value of all groups (C99 only) stays with the rows of its block */
    IF FIRST.r1 AND (grp = 0 OR block NE prevblock OR CMISS(OF c1-c&ncol.) < &ncol. OR c99 = ' ')
      THEN grp + 1;
    isfirst{1} = FIRST.r1;
    isfirst{2} = FIRST.r2;
    isfirst{3} = FIRST.r3;
    isfirst{4} = FIRST.r4;
    /* the levels of this line; in a frequency block the last one labels the line */
    nlev = 0;
    DO _i = 1 TO 4;
      IF r{_i} NE ' ' THEN nlev = _i;
    END;
    IF freq AND nlev > 0 THEN nhead = nlev - 1;
    ELSE                      nhead = nlev;
    /* keep the numbers while the heading rows are written */
    DO _i = 1 TO DIM(c);
      saved{_i} = c{_i};
      c{_i}     = ' ';
    END;
    IF FIRST.block AND block NE prevblock AND (NOT freq OR nlev > 0) THEN DO;
      /* a blank row between the blocks with a heading */
      IF rowno > 0 THEN DO;
        row = ' ';
        rowno + 1;
        OUTPUT;
      END;
      row = block;
      rowno + 1;
      OUTPUT;
    END;
    IF FIRST.block THEN prevblock = block;
    DO _i = 1 TO nhead;
      IF isfirst{_i} AND r{_i} NE ' ' THEN DO;
        row = REPEAT(' ', 2 * _i - 1) || r{_i};
        rowno + 1;
        OUTPUT;
      END;
    END;
    /* the line with the numbers */
         IF NOT freq THEN row = REPEAT(' ', 2 * nhead + 1) || label;
    ELSE IF nlev = 0 THEN row = block;
    ELSE                  row = REPEAT(' ', 2 * nlev - 1) || r{nlev};
    DO _i = 1 TO DIM(c);
      c{_i} = saved{_i};
    END;
    rowno + 1;
    OUTPUT;
    KEEP &page. grp row c1-c&ncol. c99;
  RUN;

  /* Step 9: the display data set: ROW as wide as its longest label, the cells with headers */
  DATA _NULL_;
    SET &columns.;
    %IF %LENGTH(&page.) %THEN %DO;
      CALL SYMPUTX(CATS('head', col), colvalue, 'L');
    %END;
    %ELSE %DO;
      CALL SYMPUTX(CATS('head', col), header, 'L');
    %END;
  RUN;
  %IF %LENGTH(&page.) %THEN %DO;
    PROC TRANSPOSE DATA=&columns. OUT=_layout_heads(KEEP=&page. head_c:) PREFIX=head_c;
      BY &page. NOTSORTED;
      ID col;
      VAR header;
    RUN;
  %END;
  DATA _NULL_;
    SET _layout_rows END=last;
    RETAIN longest 1 pval 0;
    longest = MAX(longest, LENGTHN(row));
    IF NOT MISSING(c99) THEN pval = 1;
    IF last THEN DO;
      CALL SYMPUTX('width', longest, 'L');
      CALL SYMPUTX('haspval', pval, 'L');
    END;
  RUN;
  DATA &out.;
    LENGTH grp 8 row $200;
    %IF %LENGTH(&page.) %THEN %DO;
      LENGTH head_c1-head_c&ncol. $220;
      IF _N_ = 1 THEN DO;
        DECLARE HASH _hh(DATASET: '_layout_heads');
        _hh.defineKey("&upage.");
        _hh.defineData(all: 'YES');
        _hh.defineDone();
      END;
    %END;
    SET _layout_rows;
    %IF %LENGTH(&page.) %THEN %DO;
      IF _hh.find() NE 0 THEN CALL MISSING(OF head_c1-head_c&ncol.);
      %IF %LENGTH(&pformat.) %THEN %DO;
        FORMAT &page. &pformat.;
      %END;
    %END;
    FORMAT row $char&width..;
    %DO i = 1 %TO &ncol.;
      LABEL c&i. = %SYSFUNC(QUOTE(%SUPERQ(head&i.)));
    %END;
    LABEL c99 = 'All groups';
    %IF %LENGTH(&page.) %THEN %DO;
      KEEP &page. head_c1-head_c&ncol.;
    %END;
    %IF &haspval. %THEN %DO;
      KEEP grp row c1-c&ncol. c99;
    %END;
    %ELSE %DO;
      KEEP grp row c1-c&ncol.;
    %END;
  RUN;
  %LET made = 1;

  /* Step 10: the setup of %print in the global macro variable of setup= (none when blank) */
  %finish:
  %IF &made. and %LENGTH(&setup.) %THEN %DO;
    /* stored with its quoting: a comma, a quote, & or % of a label stay text in %print(&name.) */
    %LET list = data=&out., by=row, var=c:;
    %IF %LENGTH(&page.) %THEN %LET list = &list., page=&page.;
    %LET list = &list., together=grp, label=%NRSTR(row=" ");
    %IF %LENGTH(%SUPERQ(label)) %THEN %LET list = &list. %SUPERQ(label);
    %IF %LENGTH(&rows.) %THEN %LET list = &list., rows=&rows.;
    %IF %LENGTH(%SUPERQ(file)) %THEN %LET list = &list., file=%SUPERQ(file);
    %IF %LENGTH(%SUPERQ(nodata)) %THEN %LET list = &list., nodata=%SUPERQ(nodata);
    %GLOBAL &setup.;
    %LET &setup. = &list.;
    %PUT NOTE: [layout] setup=&setup. keeps the print of &out.: %SUPERQ(list);
    %PUT NOTE: [layout] print it with %NRSTR(%print)(%NRSTR(&)&setup..);
  %END;

  /* Step 11: the work data sets are deleted (kept with debug=yes) */
  %IF %UPCASE(&debug.) ne YES %THEN %DO;
    PROC DATASETS LIBRARY=work NOLIST NOWARN;
      DELETE _layout_:;
    QUIT;
  %END;
  %_spl_end(layout, &t0., &debug.)
%MEND layout;
