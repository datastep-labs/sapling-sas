/*******************************************************************************
| Macro Name    : _spl_program.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.9.1
| Created By    : Sapling
| Date          : 16NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : The fixed parts of the DATA step with which a one-call table writes
|                 its long program: begin (the file and the variables), records (the
|                 population and the records, from the parameters ADSL, POP, DATA,
|                 WHERE and NAME of the calling macro), table (the %table call, from
|                 BY, ORDER, TOTAL, FORMAT, FILE, NAME and DEBUG, with the TITLE
|                 and FOOTNOTE statements of TITLE and FOOTNOTE before it and their
|                 clearing after it), titles and untitled (those statements alone),
|                 end (the routine that writes a call). It computes nothing.
| Used By       : the one-call tables %table_* (inner part)
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| _part       begin, names, label, records, table, titles,        Required
|             untitled or end
| _var        With label: the variable of the block, in lower     Optional
|             case
|-------------------------------------------------------------------------------
|
| Output        : CODE: DATA step statements. It reads the macro variables REC
|                 (the records the calls read), POPN (the data set with the N
|                 of the columns), DS and NAMES of the calling macro.
|
| Example:
|
 DATA _NULL_;
   %_spl_program(begin)
   %_spl_program(records)
   %_spl_arg(data, "&rec.")
   %_spl_call(freq)
   %_spl_program(table)
   %_spl_program(end)
 RUN;
|
|-------------------------------------------------------------------------------
| Change Log :
| Date        Programmer   Description
|-------------------------------------------------------------------------------
| 13-NOV-2026 Sapling      1.8.0: initial version.
| 16-NOV-2026 Sapling      1.9.0: the parts titles and untitled (the TITLE and
|                          FOOTNOTE statements of title= and footnote=); table
|                          writes them around %table. The license line.
| 16-NOV-2026 Sapling      1.9.1: BLOCK and ITEM are set missing where names= is
|                          read: no note that they are uninitialized (DEV-032).
|                          No number changes.
|
*******************************************************************************/
%MACRO _spl_program(
     _part      /* begin, names, label, records, table, titles, untitled or end */
   , _var       /* With label: the variable of the block */
) / DES = 'The fixed parts of the long program of a one-call table (DATA step statements)';
  %IF &_part. = begin %THEN %DO;
    FILE _tprog LRECL=400;
    LENGTH part results $32767 macro $32 line $2200;
    ARRAY pn {16} $16;
    ARRAY pv {16} $2000;
    n = 0;
  %END;
  %ELSE %IF &_part. = names %THEN %DO;
    LENGTH names $32767 block item $2000;
    CALL MISSING(block, item);
    names = %_spl_quote(names);
    dsid  = OPEN("&ds.");
  %END;
  %ELSE %IF &_part. = label %THEN %DO;
    /* the label of the block: names=, else the label of the variable, else its name */
    block = ' ';
    IF dsid > 0 THEN DO;
      IF VARNUM(dsid, "&_var.") > 0 THEN block = VARLABEL(dsid, VARNUM(dsid, "&_var."));
    END;
    IF block = ' ' THEN block = "&_var.";
    DO j = 1 TO COUNTW(names, ' ', 'q');
      item = SCAN(names, j, ' ', 'q');
      IF LOWCASE(SCAN(item, 1, '=')) = "&_var." THEN
        block = DEQUOTE(SUBSTR(item, INDEX(item, '=') + 1));
    END;
  %END;
  %ELSE %IF &_part. = records %THEN %DO;
    %IF %LENGTH(&adsl.) %THEN %DO;
      PUT '/* The population: one row per subject */'
        / "PROC SORT DATA=&adsl. OUT=&name._pop;";
      %IF %LENGTH(%SUPERQ(pop)) %THEN %DO;
        line = %_spl_quote(pop);
        PUT '  WHERE ' line +(-1) ';';
      %END;
      PUT '  BY usubjid;'
        / 'RUN;'
        /;
      PUT '/* The records of the population, with the variables of the subject */'
        / "PROC SORT DATA=&data. OUT=&name._rec;";
      %IF %LENGTH(%SUPERQ(where)) %THEN %DO;
        line = %_spl_quote(where);
        PUT '  WHERE ' line +(-1) ';';
      %END;
      PUT '  BY usubjid;'
        / 'RUN;'
        / "DATA &name._rec;"
        / "  MERGE &name._pop(IN=inpop) &name._rec(IN=inrec);"
        / '  BY usubjid;'
        / '  IF inpop AND inrec;'
        / 'RUN;'
        /;
    %END;
    %ELSE %IF %LENGTH(%SUPERQ(where)) %THEN %DO;
      line = %_spl_quote(where);
      PUT '/* The records of the analysis */'
        / "DATA &name._rec;"
        / "  SET &data.;"
        / '  WHERE ' line +(-1) ';'
        / 'RUN;'
        /;
    %END;
  %END;
  %ELSE %IF &_part. = titles %THEN %DO;
    /* a TITLE (FOOTNOTE) statement for each text in quotes of title= (footnote=); a text
       without quotes is one text */
    %IF %LENGTH(%SUPERQ(title)) %THEN %DO;
      part = %_spl_quote(title);
      IF NOT INDEXC(SUBSTR(LEFT(part), 1, 1), '"''') THEN part = QUOTE(STRIP(part));
      DO _ti = 1 TO COUNTW(part, ' ', 'q');
        line = CATS('TITLE', _ti) || ' ' || STRIP(SCAN(part, _ti, ' ', 'q')) || ';';
        PUT line;
      END;
    %END;
    %IF %LENGTH(%SUPERQ(footnote)) %THEN %DO;
      part = %_spl_quote(footnote);
      IF NOT INDEXC(SUBSTR(LEFT(part), 1, 1), '"''') THEN part = QUOTE(STRIP(part));
      DO _ti = 1 TO COUNTW(part, ' ', 'q');
        line = CATS('FOOTNOTE', _ti) || ' ' || STRIP(SCAN(part, _ti, ' ', 'q')) || ';';
        PUT line;
      END;
    %END;
  %END;
  %ELSE %IF &_part. = untitled %THEN %DO;
    /* the statements of title= and footnote= end with the table */
    %IF %LENGTH(%SUPERQ(title)) %THEN %DO;
      PUT 'TITLE;';
    %END;
    %IF %LENGTH(%SUPERQ(footnote)) %THEN %DO;
      PUT 'FOOTNOTE;';
    %END;
    %IF %LENGTH(%SUPERQ(title)) or %LENGTH(%SUPERQ(footnote)) %THEN %DO;
      PUT;
    %END;
  %END;
  %ELSE %IF &_part. = table %THEN %DO;
    /* the blocks one under another */
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
    /* the columns with their N, the numbers file, the rows as printed, the print */
    %_spl_arg(data, "&name.")
    %_spl_arg(n, "&popn.")
    %_spl_arg(var, LOWCASE("&by."))
    %_spl_arg(order, LOWCASE("&order."))
    %_spl_arg(total, LOWCASE("&total."))
    %_spl_arg(format)
    %_spl_arg(file)
    %_spl_arg(setup, "&name._print")
    %IF %UPCASE(&debug.) = YES %THEN %DO;
      %_spl_arg(debug, 'yes')
    %END;
    %_spl_program(titles)
    %_spl_call(table)
    %_spl_program(untitled)
  %END;
  %ELSE %DO;
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
      line = SUBSTR(line, 1, 4) || SUBSTR(pn{k} || REPEAT(' ', 16), 1, _wide) || ' = ' || pv{k};
      _len = LENGTH(line);
      PUT line $VARYING2200. _len;
    END;
    PUT ')';
    IF macro NE '%table' THEN results = CATX(' ', results, pv{n});
    RETURN;
  %END;
%MEND _spl_program;
