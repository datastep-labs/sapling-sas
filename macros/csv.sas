/*******************************************************************************
| Macro Name    : csv.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.9.1
| Created By    : Sapling
| Date          : 16NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : The records of a listing (or the numbers of a figure, out= of
|                 a figure macro) as a CSV file: a line with the names of the
|                 variables, then one line per record in the order of the
|                 data. sapling sas check compares it with the listing or the
|                 figure of R.
| Procedure     : DATA steps (FILE, PUT)
| Proven        : the listings of the dummy study SYNHTN01 (sapling sas check:
|                 listings the same in R and SAS); ran on SAS 9.4 M9,
|                 2026-11-12
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| data        The records of the listing                          Required
| var         The variables of the listing                        Required
| folder      The folder in the outputs: listings or figures      listings
| file        The name of the listing, without extension          Required
|-------------------------------------------------------------------------------
|
| Output        : FILE: <out>/<folder>/<file>.csv: the names of VAR, then one
|                 line per record.
|
| Example:
|
 %csv(data=adae, var=trt01a usubjid aedecod astdt, file=l14_5_1)
|
|-------------------------------------------------------------------------------
| Change Log :
| Date        Programmer   Description
|-------------------------------------------------------------------------------
| 12-NOV-2026 Sapling      1.2.0: initial version: the CSV file of a listing
|                          that the printer of 1.1.0 wrote, as a step of the
|                          program.
| 12-NOV-2026 Sapling      1.3.0: folder= (figures: the numbers of a figure).
| 16-NOV-2026 Sapling      1.9.0: a missing output folder is made, with a NOTE
|                          (%_spl_folder). The license line; the example in the
|                          house case.
|
*******************************************************************************/
%MACRO csv(
     data   =           /* The records of the listing */
   , var    =           /* The variables of the listing */
   , folder = listings  /* The folder in the outputs: listings or figures */
   , file   =           /* The name of the listing */
) / DES = 'The records of a listing as a CSV file (DATA steps)';
  %LOCAL t0 csv names;
  %LET t0 = %_spl_begin(csv);

  /* Step 1: the parameters */
  %IF not %_spl_need(csv, data var file) %THEN %RETURN;
  %IF not %_spl_vars(csv, data, var) %THEN %RETURN;
  %IF not %_spl_oneof(csv, folder, listings figures) %THEN %RETURN;

  %LET csv = &spl_out./%LOWCASE(&folder.)/%LOWCASE(&file.).csv;  /* the CSV file */
  /* the line of the names: the variables, separated by commas */
  %LET names = %SYSFUNC(TRANSLATE(%SYSFUNC(COMPBL(%UPCASE(&var.))), %STR(,), %STR( )));

  /* Step 2: the line of the names, then one line per record */
  %_spl_folder(csv, &csv.)
  DATA _NULL_;
    FILE "&csv." LRECL=32767;
    PUT "&names.";
  RUN;
  DATA _NULL_;
    SET &data.;
    FILE "&csv." DSD MOD LRECL=32767;
    PUT (&var.) (:);
  RUN;
  %_spl_end(csv, &t0.)
%MEND csv;
