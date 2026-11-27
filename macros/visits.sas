/*******************************************************************************
| Macro Name    : visits.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.9.1
| Created By    : Sapling
| Date          : 27NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : Gives each record its analysis visit, AVISIT and AVISITN, from
|                 the value of its variable VISIT. Use %windows when the
|                 analysis visit comes from the study day of the record. The
|                 value of VISIT must match exactly, in upper and lower case. A
|                 record whose visit is not in visits= gets missing values only
|                 when data= does not have AVISIT and AVISITN yet. When data=
|                 has them already (from an earlier step), a record whose visit
|                 is not in visits= keeps its old AVISIT and AVISITN: drop them
|                 before the call when such a record must have none.
| Procedure     : DATA steps (SET POINT=)
| Proven        : the fixtures of the step kind windows.visit
|                 (src/adam_steps.ts; node tools/adam_steps_sas.ts); ran on SAS
|                 9.4 M9, 2026-11-12
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| data        The data set to change in place, with the variable  Required
|             VISIT, such as adlb
| visits      The visits, separated by #. Each visit is "VISIT"   Required
|             AVISITN "AVISIT": the value of VISIT in quotes,
|             then the analysis visit as a number and as a text
|             (# "WEEK 2" 2 "Week 2").
|-------------------------------------------------------------------------------
|
| Output        : DATA: data=, changed in place: AVISIT and AVISITN on each
|                 record whose visit is in visits=, missing on the others.
|
| Example:
|
 * Copies the ALT records that are not derived, without an analysis visit.;
 DATA lb;
   SET adlb;
   WHERE paramcd = 'ALT' AND MISSING(dtype);
   KEEP usubjid paramcd visit aval;
 RUN;
 * Maps each collected visit to its analysis visit and its number: SCREENING 1 is the Baseline.;
 %visits(
     data   = lb
   , visits = "SCREENING 1" 0  "Baseline"
            # "WEEK 2"      2  "Week 2"
            # "WEEK 4"      4  "Week 4"
            # "WEEK 6"      6  "Week 6"
            # "WEEK 8"      8  "Week 8"
            # "WEEK 12"     12 "Week 12"
            # "WEEK 16"     16 "Week 16"
            # "WEEK 20"     20 "Week 20"
            # "WEEK 24"     24 "Week 24"
            # "WEEK 26"     26 "Week 26"
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
| 13-NOV-2026 Sapling      1.7.0: visits= takes the rows in the call (# between
|                          rows), no data set of them. No number changes.
| 16-NOV-2026 Sapling      1.9.0: the license line; the example in the house
|                          case (names in lower case). No number changes.
| 27-NOV-2026 Sapling      1.9.1: the example runs on the example data
|                          (sas/examples). The text of the header for the
|                          manual: the summary, the form of each parameter. No
|                          number changes.
| 27-NOV-2026 Sapling      1.9.1: The example first copies its records into a
|                          data set of its own, so that it changes no data set of
|                          setup.sas for a later example. No number changes.
| 27-NOV-2026 Sapling      1.9.1: the text says that a record of no visit keeps
|                          an AVISIT that data= has already. No number changes.
| 27-NOV-2026 Sapling      1.9.1: a caption for each call of the example (a
|                          comment line before it). No number changes.
|
*******************************************************************************/
%MACRO visits(
     data   =   /* The working data set (changed in place) */
   , visits =   /* The visits: "VISIT" AVISITN "AVISIT" # ... */
) / DES = 'Give each record its analysis visit by its visit (a DATA step)';
  %LOCAL t0 rowsok;
  %LET t0 = %_spl_begin(visits);
  %IF not %_spl_need(visits, data visits) %THEN %RETURN;

  /* the visits of the call as a data set, one row per visit */
  %_spl_windows(visits, visits, visit, _visits_rows)
  %IF &rowsok. = 0 %THEN %RETURN;

  /* the analysis visit of the visit of each record */
  DATA &data.;
    SET &data.;
    _found = 0;
    DO _w = 1 TO _nvisits WHILE (NOT _found);
      SET _visits_rows(RENAME=(visit = _wvisit avisitn = _wn avisit = _wname))
          POINT=_w NOBS=_nvisits;
      IF visit = _wvisit THEN DO;
        _found  = 1;
        avisit  = _wname;
        avisitn = _wn;
      END;
    END;
    DROP _found _wvisit _wn _wname;
  RUN;
  PROC DATASETS LIBRARY=work NOLIST NOWARN;
    DELETE _visits_:;
  QUIT;
  %_spl_end(visits, &t0.)
%MEND visits;
