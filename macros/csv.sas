/*******************************************************************************
| Macro Name    : csv.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.10.0
| Created By    : Sapling
| Date          : 27NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : Writes the records of a listing, or the numbers of a figure,
|                 to a CSV file. Use %ard for the numbers of a table. The first
|                 line has the names of the variables, in upper case; then one
|                 line per record, in the order of the data. The values are
|                 written with their formats, so that a second program, in SAS
|                 or R, can compare its listing or figure with this file.
| Procedure     : DATA steps (FILE, PUT)
| Proven        : The listings of a made-up study: the same as the listings of a
|                 second program in R; ran on SAS 9.4 M9, 2026-11-12
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| data        The records: the data set of the listing, or out=   Required
|             of a figure macro
| var         The variables to write: names separated by blanks,  Required
|             in the order of the columns
| folder      The folder in the outputs: listings or figures      listings
| file        The name of the CSV file, without its extension     Required
|-------------------------------------------------------------------------------
|
| Output        : FILE: <out>/<folder>/<file>.csv, where <out> is the output
|                 folder that %study set: a line with the names of var=, then
|                 one line per record.
|
| Example:
|
 * Writes the listing as a CSV file: the names of var= in the first line, then one line per record.;
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
| 27-NOV-2026 Sapling      1.10.0: the text of the header for the manual: the
|                          summary, the form of each parameter. No number
|                          changes.
| 27-NOV-2026 Sapling      1.10.0: The header names no internal tool. No number
|                          changes.
| 27-NOV-2026 Sapling      1.10.0: a caption for each call of the example (a
|                          comment line before it). No number changes.
| 27-NOV-2026 Sapling      1.10.0: Proven in plain words, for the published
|                          manual. No number changes.
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
