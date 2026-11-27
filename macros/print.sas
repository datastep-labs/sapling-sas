/*******************************************************************************
| Macro Name    : print.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.9.1
| Created By    : Sapling
| Date          : 27NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : Print a table or a listing: one PROC REPORT into an RTF file
|                 and a monospace listing beside it. A table is printed from
|                 its display data set (%layout), a listing from its records.
|                 The BY columns come first, a repeated value shown once; the
|                 VAR columns follow, numbers right, text left as written.
|                 ODS wraps and pages the RTF; the rows of one TOGETHER value
|                 stay on one page of the listing when they fit in ROWS.
|                 The parameters of a table can come from the setup of %layout
|                 (setup=): %print(&name.) prints its display data set again
|                 after a change; a parameter that is not in the setup is
|                 added after it: %print(&name., file=...). A keyword given
|                 twice stops the call (SAS): change it in %layout.
|                 page= prints one page (or more) per value of a variable,
|                 into the same two files: the report of each value under a
|                 BY statement, so that a title of the program can name it
|                 (OPTIONS NOBYLINE and TITLE2 "Sex: #BYVAL1"); a column X
|                 with a variable HEAD_X has the header of its page from it.
| Procedure     : PROC REPORT
| Proven        : its cases of node tools/print_sas.ts (PRINT SAS PASS: 18 cases)
|                 and the tables and listings of the dummy study SYNHTN01
|                 (flat programs 12 of 12); ran on SAS 9.4 M9, 2026-11-12
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| data        The rows: the display data set of %layout, or the   Required
|             records of a listing
| by          The left columns, printed first: a repeated value   Optional
|             shown once
| var         The other columns, in print order; a list such as   Required
|             c: or c1-c5 is allowed
| page        A variable: a new page for each value, its value    Optional
|             for #BYVAL1 of a title; a variable HEAD_X gives the
|             header of the column X on the page of its row
| together    A variable: the rows of one value stay on one page  Optional
| label       Column labels: name="text" pairs; | splits a header Optional
|             (default: the labels of the variables)
| rows        The rows of a page, for together=                   40
| file        The output without its extension: <file>.rtf and    Required
|             <file>.lst
| nodata      The text printed when there is no row               No data
|                                                                 qualified
| debug       yes: keep the work data sets _print_*               no
|-------------------------------------------------------------------------------
|
| Output        : FILE: <file>.rtf (style journal, landscape) and <file>.lst
|                 (the LISTING destination), under the titles and footnotes
|                 of the program; no row: the text of nodata=. With page=:
|                 the pages of each value in the order of the rows.
|
| Example:
|
 %print(
     data     = t14_2_1_display
   , by       = row
   , var      = c:
   , together = grp
   , label    = %STR(row=" ")
   , file     = &spl_out./tlf/t14_2_1
 )
 %print(data=adae, by=trt01a usubjid, var=aedecod astdt aesev, file=&spl_out./listings/l14_5_1)
 %print(
     data     = t14_1_1_display
   , by       = row
   , var      = c:
   , page     = sex
   , together = grp
   , label    = %STR(row=" ")
   , file     = &spl_out./tlf/t14_1_1
 )
|
|-------------------------------------------------------------------------------
| Change Log :
| Date        Programmer   Description
|-------------------------------------------------------------------------------
| 12-NOV-2026 Sapling      1.2.0: the short printer: one PROC REPORT into RTF
|                          and LISTING; ODS wraps and pages. It replaces the
|                          copy of the owner's %PRINT 0.2.0 (no "(Continued)",
|                          no split in width by hand).
| 12-NOV-2026 Sapling      1.4.0: the parameters of a table from the setup of
|                          %layout: %print(&name.). No change of the print.
| 16-NOV-2026 Sapling      1.9.0: a missing output folder is made, with a NOTE
|                          (%_spl_folder). The license line; the example in the
|                          house case.
| 27-NOV-2026 Sapling      1.9.1: page=: a new page for each value of a
|                          variable, in the same files, its value for a
|                          title (#BYVAL1), the headers of its page from
|                          HEAD_X. Without page= no change.
|
*******************************************************************************/
%MACRO print(
     data     =                    /* The rows: the display data set, or records */
   , by       =                    /* The left columns: a repeated value shown once */
   , var      =                    /* The other columns, in print order (c: allowed) */
   , page     =                    /* A variable: a new page for each value */
   , together =                    /* A variable: the rows of one value on one page */
   , label    =                    /* Column labels: name="text" pairs */
   , rows     = 40                 /* The rows of a page, for together= */
   , file     =                    /* The output without its extension */
   , nodata   = No data qualified  /* The text printed when there is no row */
   , debug    = no                 /* yes: keep the work data sets _print_* */
) / DES = 'Print a table or a listing into RTF and a monospace listing (PROC REPORT)';
  %LOCAL t0 i j v all dsid rc list cols nby ncol columns orient listing heads npage p subset;
  %LET t0 = %_spl_begin(print);

  /* Step 1: the parameters */
  %IF not %_spl_need(print, data var rows file) %THEN %RETURN;
  %IF not %_spl_oneof(print, debug, yes no) %THEN %RETURN;
  %IF not %SYSFUNC(PRXMATCH(/^[1-9][0-9]*$/, &rows.)) %THEN %DO;
    %PUT %STR(ERR)OR: [print] rows=&rows. is not a positive whole number;
    %PUT %STR(ERR)OR: [print]   fix: give rows= the rows of a page, such as 40.;
    %RETURN;
  %END;

  /* a list in var= (c: or a numbered range) becomes its variables, in the order of the data */
  %LET all = %SYSFUNC(OPEN(&data.));  /* the data set, open to read the names of its variables */
  %DO i = 1 %TO %SYSFUNC(COUNTW(&var., %STR( )));
    %LET v    = %SCAN(&var., &i., %STR( ));
    %LET dsid = %SYSFUNC(OPEN(&data.(KEEP=&v.)));
    %IF &dsid. = 0 %THEN %LET list = &list. &v.;
    %ELSE %DO;
      %DO j = 1 %TO %SYSFUNC(ATTRN(&all., NVARS));
        %LET v = %SYSFUNC(VARNAME(&all., &j.));
        %IF %SYSFUNC(VARNUM(&dsid., &v.)) %THEN %LET list = &list. &v.;
      %END;
      %LET rc = %SYSFUNC(CLOSE(&dsid.));
    %END;
  %END;
  %LET rc  = %SYSFUNC(CLOSE(&all.));  /* the data set closed */
  %LET var = &list.;                  /* the VAR columns, one name each */
  %IF not %_spl_vars(print, data, by var page together) %THEN %RETURN;
  %LET cols    = &by. &var.;                              /* the columns, left to right */
  %LET nby     = %SYSFUNC(COUNTW(&by.%STR( ), %STR( )));  /* the number of BY columns */
  %LET ncol    = %SYSFUNC(COUNTW(&cols., %STR( )));       /* the number of columns */
  %LET orient  = %SYSFUNC(GETOPTION(ORIENTATION));        /* the orientation, set back at the end */
  %LET listing = no;                                      /* yes: LISTING was open before */
  /* the columns of the report: each BY column after its run number, then the VAR columns */
  %DO i = 1 %TO &nby.;
    %LET columns = &columns. _by&i. %SCAN(&by., &i., %STR( ));
  %END;
  %LET columns = &columns. &var.;  /* the COLUMN statement */

  %LET dsid = %SYSFUNC(OPEN(&data.));  /* the data set, open to look for HEAD_X */
  %DO i = 1 %TO &ncol.;
    %LET v = HEAD_%SCAN(&cols., &i., %STR( ));  /* the header of the column on its page */
    %IF %LENGTH(&page.) and %LENGTH(&v.) <= 32 %THEN %DO;
      %IF %SYSFUNC(VARNUM(&dsid., &v.)) = 0 %THEN %LET v = .;  /* no such variable */
    %END;
    %ELSE %LET v = .;                 /* no page=: the header of every page is the same */
    %LET heads = &heads. &v.;         /* the HEAD_X of each column, else a period */
  %END;
  %LET rc = %SYSFUNC(CLOSE(&dsid.));  /* the data set closed */

  /* Step 2: the rows, the number of their page value and a run number per BY column */
  DATA _print_rows;
    SET &data.;
    %IF %LENGTH(&page.) or &nby. %THEN %DO;
      BY &page. &by. NOTSORTED;
    %END;
    %IF %LENGTH(&page.) %THEN %DO;
      IF first.&page. THEN _pg + 1;
    %END;
    %ELSE %DO;
      _pg = 1;
    %END;
    %DO i = 1 %TO &nby.;
      IF first.%SCAN(&by., &i., %STR( )) THEN _by&i. + 1;
    %END;
  RUN;

  /* Step 3: no row: one row with the text of nodata= */
  %IF %_spl_nobs(_print_rows) = 0 %THEN %DO;
    DATA _print_rows;
      _nodata = %_spl_quote(nodata);
      _pg     = 1;
    RUN;
    %LET cols     = _nodata;
    %LET columns  = _nodata;
    %LET ncol     = 1;
    %LET nby      = 0;
    %LET together = ;
    %LET page     = ;
    %LET heads    = .;
    %LET label    = _nodata=" ";
  %END;

  /* Step 4: the page of each row: a block that does not fit in what is left starts a page */
  %IF %LENGTH(&together.) %THEN %DO;
    DATA _print_rows;
      RETAIN _page 1 _left &rows.;
      DO _n = 1 BY 1 UNTIL (last.&together.);
        SET _print_rows;
        BY _pg &together. NOTSORTED;
        IF _n = 1 AND FIRST._pg THEN _left = &rows.;
      END;
      IF _n > _left AND _left < &rows. THEN DO;
        _page + 1;
        _left = &rows.;
      END;
      _left = _left - _n;
      DO UNTIL (last.&together.);
        SET _print_rows;
        BY _pg &together. NOTSORTED;
        OUTPUT;
      END;
      DROP _n _left;
    RUN;
  %END;

  /* Step 5: the header of each column on each page and its width, from one pass over the rows */
  DATA _NULL_;
    SET _print_rows END=last;
    BY _pg;
    LENGTH _c _hv $32 _v _h $256 _l $32767 _f _o $80 _d $1;
    ARRAY _w{&ncol.} _TEMPORARY_;
    _l = %_spl_quote(label);
    DO _i = 1 TO &ncol.;
      _c = SCAN("&cols.", _i, ' ');
      IF VTYPEX(_c) = 'N' THEN _v = LEFT(VVALUEX(_c));
      ELSE                     _v = VVALUEX(_c);
      _w{_i} = MAX(_w{_i}, LENGTHN(_v), 1);
      /* the header: label= of the column, else its HEAD_X on this page, else its label */
      IF FIRST._pg THEN DO;
        _hv = SCAN("&heads.", _i, ' ');
        _h  = VLABELX(_c);
        IF _hv NE '.' THEN DO;
          IF VVALUEX(_hv) NE ' ' THEN _h = VVALUEX(_hv);
        END;
        DO _k = 1 TO COUNTW(_l, ' =', 'q') - 1 BY 2;
          IF UPCASE(SCAN(_l, _k, ' =', 'q')) = UPCASE(_c) THEN
            _h = DEQUOTE(SCAN(_l, _k + 1, ' =', 'q'));
        END;
        /* a header split at | keeps its pieces whole; another wraps at its blanks */
        IF INDEX(_h, '|') THEN _d = '|';
        ELSE                   _d = ' ';
        DO _k = 1 TO COUNTW(_h, _d);
          _w{_i} = MAX(_w{_i}, LENGTHN(SCAN(_h, _k, _d)));
        END;
        CALL SYMPUTX(CATS('head', _pg, '_', _i), QUOTE(TRIM(_h), "'"), 'L');
      END;
    END;
    IF last THEN CALL SYMPUTX('npage', _pg, 'L');
    IF last THEN DO _i = 1 TO &ncol.;
      _c = SCAN("&cols.", _i, ' ');
      /* text as written ($CHAR keeps the indent); a VAR text column wider than 40 flows */
      _f = CATS('FORMAT=$CHAR', _w{_i}, '.');
           IF VTYPEX(_c) = 'N'           THEN _o = CATX(' ', CATS('WIDTH=', _w{_i}), 'RIGHT');
      ELSE IF _i > &nby. AND _w{_i} > 40 THEN _o = CATX(' ', 'WIDTH=40 FLOW LEFT', _f);
      ELSE                                    _o = CATX(' ', CATS('WIDTH=', _w{_i}), 'LEFT', _f);
      /* a BY column is ORDER, the last one also ID: a part of the page in width repeats it; the
         first column starts the line */
      IF _i <= &nby. THEN _o = CATX(' ', 'ORDER ORDER=DATA', _o);
      ELSE                _o = CATX(' ', 'DISPLAY', _o);
      IF _i = &nby. THEN _o = CATX(' ', _o, 'ID');
      IF _i = 1 THEN _o = CATX(' ', _o, 'SPACING=0');
      CALL SYMPUTX(CATS('opt', _i), _o, 'L');
    END;
  RUN;

  /* Step 6: the report into RTF and LISTING, then the destinations and the option as they were */
  DATA _NULL_;
    SET sashelp.vdest;
    IF UPCASE(destination) = 'LISTING' THEN CALL SYMPUTX('listing', 'yes', 'L');
  RUN;
  %_spl_folder(print, %SUPERQ(file).rtf)
  OPTIONS ORIENTATION=LANDSCAPE;
  ODS RTF FILE="&file..rtf" STYLE=journal;
  ODS LISTING FILE="&file..lst";
  /* with page= one report per value, with its rows and the headers of its page */
  %DO p = 1 %TO &npage.;
    %IF %LENGTH(&page.) %THEN %LET subset = (WHERE=(_pg = &p.));
    PROC REPORT DATA=_print_rows&subset. NOWINDOWS MISSING SPLIT='|' HEADLINE HEADSKIP
                STYLE(header)=[JUST=C] STYLE(column)=[ASIS=ON];
      %IF %LENGTH(&page.) %THEN %DO;
        BY &page. NOTSORTED;
      %END;
      COLUMN
      %IF %LENGTH(&together.) %THEN _page; &columns.;
      %IF %LENGTH(&together.) %THEN %DO;
        DEFINE _page / ORDER ORDER=INTERNAL NOPRINT;
        BREAK AFTER _page / PAGE;
      %END;
      %DO i = 1 %TO &ncol.;
        %IF &i. <= &nby. %THEN %DO;
          DEFINE _by&i. / ORDER ORDER=INTERNAL NOPRINT;
        %END;
        DEFINE %SCAN(&cols., &i., %STR( )) / &&opt&i. &&head&p._&i.;
      %END;
    RUN;
  %END;
  ODS RTF CLOSE;
  ODS LISTING CLOSE;
  %IF &listing. = yes %THEN %DO;
    ODS LISTING;
  %END;
  OPTIONS ORIENTATION=&orient.;

  /* Step 7: the work data sets are deleted (kept with debug=yes) */
  %IF %UPCASE(&debug.) ne YES %THEN %DO;
    PROC DATASETS LIBRARY=work NOLIST NOWARN;
      DELETE _print_:;
    QUIT;
  %END;
  %_spl_end(print, &t0., &debug.)
%MEND print;
