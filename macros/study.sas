/*******************************************************************************
| Macro Name    : study.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.9.1
| Created By    : Sapling
| Date          : 16NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : Start a program: the ADaM library (read only), the output
|                 folder and the name of the program (in the footnote of each
|                 output), the options of the outputs.
| Procedure     : LIBNAME, OPTIONS
| Proven        : every program of the dummy study SYNHTN01 (sapling sas run:
|                 SAS RUN PASS; sapling sas check: SAS CHECK PASS, 570 of 570
|                 numbers of R the same in SAS); ran on SAS 9.4 M9, 2026-11-12
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| id          The study (first, without a keyword)                Required
| program     The name of this program: its outputs are named     Required
|             after it
| adam        The folder of the ADaM data sets (default           &spl_root./adam
|             &spl_root./adam)
| out         The output folder, with the folders tlf, listings,  &spl_root./out
|             figures and ard (default &spl_root./out)
|-------------------------------------------------------------------------------
|
| Output        : CODE: the population and the records in DATA steps, the statistics
|                 macros (%describe, %freq, %ancova, ...), then %stack and
|                 %print (a figure: its figure macro).
|
| Example:
|
 %study(
     CDISCPILOT01
   , program = t14_2_01
 )
|
|-------------------------------------------------------------------------------
| Change Log :
| Date        Programmer   Description
|-------------------------------------------------------------------------------
| 11-NOV-2026 Sapling      1.0.0: initial version.
| 12-NOV-2026 Sapling      1.0.0: ran on SAS 9.4 M9.
| 12-NOV-2026 Sapling      1.1.0: the house standard (docs/sas-style.md). No
|                          number changes.
| 16-NOV-2026 Sapling      1.9.0: the license line; the example in the house
|                          case (names in lower case). No number changes.
|
*******************************************************************************/
%MACRO study(
     id                          /* The study (first, without a keyword) */
   , program =                   /* The name of this program */
   , adam    = &spl_root./adam   /* The folder of the ADaM data sets */
   , out     = &spl_root./out    /* The output folder */
) / DES = 'Start a program: the ADaM library, the output folder, the options';
  %LOCAL t0;
  %GLOBAL spl_study spl_out spl_program;
  %LET t0 = %_spl_begin(study);
  %IF not %_spl_need(study, id program adam out) %THEN %RETURN;

  /* the globals of the library (SPL_STUDY, SPL_OUT, SPL_PROGRAM), the options, the ADaM library */
  %LET spl_study   = &id.;
  %LET spl_out     = &out.;
  %LET spl_program = %LOWCASE(&program.);
  OPTIONS NODATE NONUMBER NOCENTER LS=160 PS=32767 MISSING=' ' VALIDVARNAME=upcase NOFMTERR
          FORMDLIM=' ';
  LIBNAME adam "&adam." ACCESS=readonly;
  TITLE;
  FOOTNOTE;
  %_spl_end(study, &t0.)
%MEND study;
