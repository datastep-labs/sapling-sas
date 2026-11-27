/*******************************************************************************
| Macro Name    : flag_if_any.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.10.0
| Created By    : Sapling
| Date          : 27NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : Flags with Y every row of each subject that has a record in
|                 another data set that meets a condition. Use %flag_first to
|                 flag one record of each group instead of a subject. The other
|                 subjects get N, or a blank with else=blank. The rows of data=
|                 keep their order.
| Procedure     : PROC SORT, MERGE
| Proven        : Checked on its test cases of a flag from a condition and from
|                 any record of a subject (small made-up records): every value
|                 the same as that of the expected records; ran on SAS 9.4 M9,
|                 2026-11-12
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| data        The data set to change in place, such as adsl       Required
| from        The data set of the records, with USUBJID, such as  Required
|             adae
| where       The condition on the records of from=, in           Required
|             parentheses, such as where = (aesev = 'SEVERE')
| else        The value for the other subjects: N, or blank for   N
|             a blank value
| new         The name of the flag variable to make               Required
| debug       yes: keep the work data sets _flag_if_any_*         no
|-------------------------------------------------------------------------------
|
| Output        : DATA: data=, changed in place: the character variable new=
|                 ($1) on every row of a subject, Y when the subject has such a
|                 record in from=, N (or blank) when not.
|
| Example:
|
 * Copies the subjects with USUBJID and EOSSTT only.;
 DATA sl;
   SET adsl;
   KEEP usubjid eosstt;
 RUN;
 * Sets COMPLFL to Y for a subject with a disposition record COMPLETED, else to N.;
 %flag_if_any(
     data  = sl
   , from  = sdtm.ds
   , where = (dsdecod = 'COMPLETED')
   , new   = complfl
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
| 27-NOV-2026 Sapling      1.10.0: the text of the header for the manual: the
|                          summary, the form of each parameter. No number
|                          changes.
| 27-NOV-2026 Sapling      1.10.0: The example first copies its records into a
|                          data set of its own, so that it changes no data set of
|                          setup.sas for a later example. No number changes.
| 27-NOV-2026 Sapling      1.10.0: a caption for each call of the example (a
|                          comment line before it). No number changes.
| 27-NOV-2026 Sapling      1.10.0: Proven in plain words, for the published
|                          manual. No number changes.
|
*******************************************************************************/
%MACRO flag_if_any(
     data  =     /* The working data set (changed in place) */
   , from  =     /* The data set of the records */
   , where =     /* The condition on FROM, in parentheses */
   , else  = N   /* The value of the other subjects: N or blank */
   , new   =     /* The flag to make: Y for a subject with a record */
   , debug = no  /* yes: keep the work data sets _flag_if_any_* */
) / DES = 'Flag the subjects with a record in another data set that meets a condition (PROC SORT)';
  %LOCAL t0;
  %LET t0 = %_spl_begin(flag_if_any);

  /* Step 1: the parameters */
  %IF not %_spl_need(flag_if_any, data from where new) %THEN %RETURN;
  %IF not %_spl_oneof(flag_if_any, debug, yes no) %THEN %RETURN;

  /* Step 2: the subjects with such a record */
  PROC SORT DATA=&from. OUT=_flag_if_any_hit(KEEP=usubjid) NODUPKEY;
    WHERE &where.;
    BY usubjid;
  RUN;

  /* Step 3: the rows keep their order: their number now; the flag of their subject */
  DATA &data.;
    SET &data.;
    _flag_if_any_row = _N_;
  RUN;
  PROC SORT DATA=&data.; BY usubjid; RUN;
  DATA &data.;
    MERGE &data.(IN=_inrows) _flag_if_any_hit(IN=_hit);
    BY usubjid;
    IF _inrows;
    LENGTH &new. $1;
    IF _hit THEN &new. = 'Y';
    %IF %UPCASE(&else.) = N %THEN %DO;
      ELSE &new. = 'N';
    %END;
  RUN;
  PROC SORT DATA=&data. OUT=&data.(DROP=_flag_if_any_row); BY _flag_if_any_row; RUN;

  /* Step 4: the work data sets are deleted (kept with debug=yes) */
  %IF %UPCASE(&debug.) ne YES %THEN %DO;
    PROC DATASETS LIBRARY=work NOLIST NOWARN;
      DELETE _flag_if_any_:;
    QUIT;
  %END;
  %_spl_end(flag_if_any, &t0., &debug.)
%MEND flag_if_any;
