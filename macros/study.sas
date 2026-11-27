/*******************************************************************************
| Macro Name    : study.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.10.0
| Created By    : Sapling
| Date          : 27NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : Starts a program: sets the study, the program and the output
|                 folder, opens the ADaM library, sets the options. Call it
|                 once, at the top of each program, before any other macro of
|                 the library. The ADaM library ADAM is read only. %ard names
|                 the numbers file after the program when its file= is not
|                 given. The macro also clears the TITLE and FOOTNOTE
|                 statements. The options, and why each is set:
|                 - NODATE NONUMBER NOCENTER: no date and no page number at the
|                   top of a page, and the text starts at the left margin, as
|                   the outputs are laid out.
|                 - LS=160: a line of a listing is 160 characters wide, the
|                   width of a landscape table.
|                 - PS=32767: the longest page SAS has, so that SAS never breaks
|                   a part of a listing; %print starts each page itself (rows=).
|                 - FORMDLIM=' ': a new page of the LISTING output is a blank
|                   line, not a form feed.
|                 - MISSING=' ': a missing number prints as a blank, not as a
|                   period.
|                 - VALIDVARNAME=UPCASE: the names of the variables a program
|                   makes are in upper case, as in the ADaM data sets.
|                 - NOFMTERR: a format that is not found does not stop the
|                   program: the value prints with the default format, and the
|                   log has only a NOTE. The risk: a code prints in place of its
|                   label (F in place of Female); look for the NOTE "Format ...
|                   was not found" in the log.
|                 To set an option back, write an OPTIONS statement after the
|                 call of %study: OPTIONS FMTERR stops the program again at a
|                 format that is not found, OPTIONS CENTER centers the output
|                 again.
| Procedure     : LIBNAME, OPTIONS
| Proven        : Every program of a made-up study: each ran with a clean log,
|                 and 570 of 570 numbers the same as those of a second program
|                 in R; ran on SAS 9.4 M9, 2026-11-12
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| id          The name of the study: a text without quotes,       Required
|             given first, without a keyword
|             (%study(CDISCPILOT01, ...))
| program     The name of this program, without quotes (program   Required
|             = t14_2_01). %ard names the numbers file after it
|             when its file= is not given
| adam        The folder of the ADaM data sets: a path without    &spl_root./adam
|             quotes. The macro opens it as the library ADAM,
|             read only. SPL_ROOT is the folder of the library
|             (it holds macros/): give adam= when the study is
|             in a folder of its own.
| out         The output folder: a path without quotes. The       &spl_root./out
|             macros write into its folders tlf, listings,
|             figures and ard. SPL_ROOT is the folder of the
|             library (it holds macros/): give out= when the
|             study is in a folder of its own.
|-------------------------------------------------------------------------------
|
| Output        : CODE: the global macro variables SPL_STUDY, SPL_PROGRAM (in
|                 lower case) and SPL_OUT; the library ADAM (read only); the
|                 options NODATE NONUMBER NOCENTER LS=160 PS=32767 MISSING=' '
|                 VALIDVARNAME=upcase NOFMTERR FORMDLIM=' '; no TITLE and no
|                 FOOTNOTE.
|
| Example:
|
 * Starts the program of the examples: it sets SPL_STUDY, SPL_PROGRAM and SPL_OUT and opens ADAM.;
 %study(
     CDISCPILOT01
   , program = examples
   , adam    = &spl_root./examples/adam
   , out     = &spl_root./examples/out
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
| 27-NOV-2026 Sapling      1.10.0: the example runs on the example data
|                          (sas/examples). The text of the header for the
|                          manual: the summary, the form of each parameter. No
|                          number changes.
| 27-NOV-2026 Sapling      1.10.0: The header names no internal tool. No number
|                          changes.
| 27-NOV-2026 Sapling      1.10.0: a caption for each call of the example (a
|                          comment line before it). No number changes.
| 27-NOV-2026 Sapling      1.10.0: Proven in plain words, for the published
|                          manual. The text says why each option is set, the
|                          risk of NOFMTERR, how to set an option back, and that
|                          adam= and out= name the folders of a study outside
|                          the folder of the library. No number changes.
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
