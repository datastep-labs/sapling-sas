/*******************************************************************************
| Macro Name    : visits.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.9.1
| Created By    : Sapling
| Date          : 16NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : Give each record its analysis visit by its visit: AVISIT and
|                 AVISITN. A record of a visit that is not in the list keeps
|                 them missing.
| Procedure     : DATA steps (SET POINT=)
| Proven        : the fixtures of the step kind windows.visit
|                 (src/adam_steps.ts; node tools/adam_steps_sas.ts); ran on SAS
|                 9.4 M9, 2026-11-12
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| data        The working data set (changed in place)             Required
| visits      The visits, # between them; a visit is "VISIT"      Required
|             AVISITN "AVISIT"
|-------------------------------------------------------------------------------
|
| Output        : DATA: AVISIT and AVISITN on each record of a visit in the
|                 list; missing on the others.
|
| Example:
|
 %visits(
     data   = adlb
   , visits = "SCREENING" 0 "Baseline"
            # "WEEK 2"    2 "Week 2"
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
