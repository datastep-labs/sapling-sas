/*******************************************************************************
| Macro Name    : _spl_csv.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.9.1
| Created By    : Sapling
| Date          : 16NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : Write a data set as a CSV file: a line with the names of the
|                 variables, then one line per row (a DATA step; values with a
|                 comma or a quote are quoted).
| Used By       : tools/figures_sas.ts: out= of a figure as a CSV (inner part)
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| data        The data set (data set options such as KEEP= are    Required
|             allowed)
| file        The CSV file to write                               Required
|-------------------------------------------------------------------------------
|
| Output        : FILE:  a line with the names of the variables, then
|                 one line per row.
|
| Example:
|
 %_spl_csv(data=l14_3_1(KEEP=usubjid aedecod), file=&spl_out./listings/l14_3_1.csv)
|
|-------------------------------------------------------------------------------
| Change Log :
| Date        Programmer   Description
|-------------------------------------------------------------------------------
| 11-NOV-2026 Sapling      1.0.0: initial version.
| 12-NOV-2026 Sapling      1.1.0: the house standard (docs/sas-style.md). No
|                          number changes.
| 12-NOV-2026 Sapling      1.2.0: used by %csv and %plot.
| 16-NOV-2026 Sapling      1.9.0: a missing output folder is made, with a NOTE
|                          (%_spl_folder). The license line; the example in the
|                          house case.
|
*******************************************************************************/
%MACRO _spl_csv(
     data =   /* The data set (options such as KEEP= allowed) */
   , file =   /* The CSV file to write */
) / DES = 'Write a data set as a CSV file (DATA steps)';
  %LOCAL header;

  /* Step 1: the names of the variables in their order */
  PROC CONTENTS DATA=&data. OUT=_csv_names(KEEP=name varnum) NOPRINT;
  RUN;
  PROC SORT DATA=_csv_names; BY varnum; RUN;
  DATA _NULL_;
    SET _csv_names END=last;
    LENGTH names $32767;
    RETAIN names;
    names = CATX(',', names, name);
    IF last THEN CALL SYMPUTX('header', names, 'L');
  RUN;

  /* Step 2: the line of the names, then one line per row */
  %_spl_folder(csv, %SUPERQ(file))
  DATA _NULL_;
    FILE "&file." LRECL=32767;
    PUT "&header.";
  RUN;
  DATA _NULL_;
    SET &data.;
    FILE "&file." DSD MOD LRECL=32767;
    PUT (_ALL_) (:);
  RUN;

  /* Step 3: the work data sets are deleted */
  PROC DATASETS LIBRARY=work NOLIST NOWARN;
    DELETE _csv_:;
  QUIT;
%MEND _spl_csv;
