/*******************************************************************************
| Macro Name    : ard.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.9.1
| Created By    : Sapling
| Date          : 27NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : Writes every number of a table to a CSV file, the numbers
|                 file. Use %csv for the records of a listing or the numbers of
|                 a figure. The numbers file has one line per number: the result
|                 it comes from, its statistic, the values of its groups, and
|                 the number as stored and as printed. The number as stored is
|                 the value as SAS keeps it, written with the format BEST32. (up
|                 to 15 significant digits); the number as printed is the TEXT
|                 of the result. It reads the results, never the printed page,
|                 so that a second program, in SAS or R, can compare its numbers
|                 with this file.
|                 - With columns=, the first lines are the N of each column (the
|                   result N).
|                 - A number has the values of at most five groups (g1_value to
|                   g5_value), in the order of GROUPS.
| Procedure     : DATA steps (FILE, PUT)
| Proven        : the tables of the dummy study SYNHTN01 (759 of 759 numbers the
|                 same as those of a second program in R); ran on SAS 9.4 M9,
|                 2026-11-12
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| data        The stacked results (out= of %stack)                Required
| columns     The columns (out= of %columns). When given, the N   Optional
|             of each column comes first, as the result N.
| file        The name of the numbers file, without its           Optional
|             extension. When not given, it is the name of the
|             program that %study set; without %study, file= is
|             required.
|-------------------------------------------------------------------------------
|
| Output        : FILE: <out>/ard/<file>.csv, where <out> is the output folder
|                 that %study set and <file> is in lower case. Its columns:
|                 result, stat, g1_value ... g5_value, raw (the number with all
|                 its digits) and formatted (the number as printed).
|
| Example:
|
 * Writes every number of the table and each column N to one CSV file: the full value and the text.;
 %ard(data=t14_2_1, columns=t14_2_1_cols, file=t14_2_1)
|
|-------------------------------------------------------------------------------
| Change Log :
| Date        Programmer   Description
|-------------------------------------------------------------------------------
| 12-NOV-2026 Sapling      1.2.0: initial version, from the inner part _spl_ard
|                          of the printer of 1.1.0 (the same file, line for
|                          line): a step of the program before the print.
| 16-NOV-2026 Sapling      1.9.0: a missing output folder is made, with a NOTE
|                          (%_spl_folder). The license line; the example in the
|                          house case.
| 16-NOV-2026 Sapling      1.9.1: data= is checked before file=; the header says
|                          that file= is required without %study (DEV-012). No
|                          number changes.
| 27-NOV-2026 Sapling      1.9.1: the example runs on the example data
|                          (sas/examples). The text of the header for the
|                          manual: the summary, the form of each parameter. No
|                          number changes.
| 27-NOV-2026 Sapling      1.9.1: The text says what the numbers file holds
|                          (BEST32.). The header names no internal tool. No
|                          number changes.
| 27-NOV-2026 Sapling      1.9.1: a caption for each call of the example (a
|                          comment line before it). No number changes.
|
*******************************************************************************/
%MACRO ard(
     data    =   /* The results (%stack) */
   , columns =   /* The columns (%columns): the N of each */
   , file    =   /* The name of the output (default: the program) */
) / DES = 'Every number of a table as a CSV file, with every digit (DATA steps)';
  %LOCAL t0 csv;
  %LET t0 = %_spl_begin(ard);

  /* Step 1: the parameters */
  %IF not %_spl_need(ard, data) %THEN %RETURN;

  %IF %LENGTH(&file.) = 0 %THEN %LET file = &spl_program.;  /* the default of file=: the program */
  %IF not %_spl_need(ard, file) %THEN %RETURN;
  %LET csv = &spl_out./ard/%LOWCASE(&file.).csv;  /* the CSV file */

  /* Step 2: the line of the names */
  %_spl_folder(ard, &csv.)
  DATA _NULL_;
    FILE "&csv.";
    PUT 'result,stat,g1_value,g2_value,g3_value,g4_value,g5_value,raw,formatted';
  RUN;
  %IF %LENGTH(&columns.) %THEN %DO;

    /* Step 3: the N of each column */
    DATA _NULL_;
      SET &columns.(WHERE=(NOT MISSING(bign)));
      FILE "&csv." DSD MOD LRECL=4000;
      LENGTH _result _stat $32 _g2-_g5 $1 _raw _text $40;
      _result = 'N';
      _stat   = 'n';
      _raw    = STRIP(PUT(bign, BEST32.));
      _text   = CATS('(N=', bign, ')');
      CALL MISSING(OF _g2-_g5);
      PUT _result _stat colvalue _g2-_g5 _raw _text;
    RUN;
  %END;

  /* Step 4: the numbers of the results */
  DATA _NULL_;
    SET &data.;
    FILE "&csv." DSD MOD LRECL=4000;
    LENGTH _g1-_g5 $200 _raw $40;
    ARRAY g {5} _g1-_g5;
    DO _k = 1 TO 5;
      g{_k} = ' ';
      IF _k <= COUNTW(groups, ' ') THEN g{_k} = STRIP(VVALUEX(SCAN(groups, _k, ' ')));
    END;
    _raw = STRIP(PUT(value, BEST32.));
    IF MISSING(value) THEN _raw = ' ';
    PUT result stat _g1-_g5 _raw text;
  RUN;
  %_spl_end(ard, &t0.)
%MEND ard;
