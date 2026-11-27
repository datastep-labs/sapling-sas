/*******************************************************************************
| Macro Name    : ard.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.9.1
| Created By    : Sapling
| Date          : 16NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : Every number of a table as a CSV file, with every digit: one
|                 line per number with the result it comes from, its statistic
|                 and the values of its groups (in the order of GROUPS), then
|                 the number and its text. The N of each column comes first
|                 (result N). It reads the results, never the printed page:
|                 sapling sas check compares these numbers with those of R.
| Procedure     : DATA steps (FILE, PUT)
| Proven        : the tables of the dummy study SYNHTN01 (sapling sas check:
|                 SAS CHECK PASS, 759 of 759 numbers); ran on SAS 9.4 M9,
|                 2026-11-12
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| data        The results (%stack)                                Required
| columns     The columns (%columns): the N of each column        Optional
| file        The name of the output, without extension (default: Optional
|             the program that %study set; without %study it is
|             required)
|-------------------------------------------------------------------------------
|
| Output        : FILE: <out>/ard/<file>.csv: result, stat, g1_value ...
|                 g5_value, raw, formatted; the N of each column first (result
|                 N), then every number of the results.
|
| Example:
|
 %ard(data=t14_2_1, columns=t14_2_1_cols)
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
