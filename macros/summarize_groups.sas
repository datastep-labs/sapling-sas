/*******************************************************************************
| Macro Name    : summarize_groups.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.9.1
| Created By    : Sapling
| Date          : 16NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : One record per group of BY with a summary of each variable of
|                 VARS over the records of the group: the sum, the mean, the
|                 largest or the smallest value (a missing value of a BY
|                 variable is a group of its own). A group without records has
|                 no record.
| Procedure     : PROC SUMMARY
| Proven        : the fixtures of the step kind parameter (src/adam_steps.ts;
|                 node tools/adam_steps_sas.ts); ran on SAS 9.4 M9, 2026-11-12
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| data        The records (prepare the values with a DATA step;   Required
|             a condition as 0 or 1)
| by          The groups                                          Required
| vars        The variables to summarize                          Required
| stats       One statistic per variable, in the same order:      Required
|             sum, mean, max or min. A sum or a mean of only
|             missing values is missing.
| out         One record per group: the BY variables and VARS     Required
|             (their summaries)
|-------------------------------------------------------------------------------
|
| Output        : OUT: one record per group of BY with the summary of each
|                 variable of VARS (under its own name).
|
| Example:
|
 %summarize_groups(
     data  = _recs
   , by    = usubjid avisit
   , vars  = _s1 _s2
   , stats = max sum
   , out   = _sums
 )
|
|-------------------------------------------------------------------------------
| Change Log :
| Date        Programmer   Description
|-------------------------------------------------------------------------------
| 12-NOV-2026 Sapling      1.0.0: initial version.
| 12-NOV-2026 Sapling      1.0.0: ran on SAS 9.4 M9.
| 12-NOV-2026 Sapling      1.1.0: the house standard (docs/sas-style.md). No
|                          number changes.
| 16-NOV-2026 Sapling      1.9.0: the license line; the example in the house
|                          case (names in lower case). No number changes.
|
*******************************************************************************/
%MACRO summarize_groups(
     data  =   /* The records */
   , by    =   /* The groups */
   , vars  =   /* The variables to summarize */
   , stats =   /* One statistic per variable: sum, mean, max or min */
   , out   =   /* One record per group */
) / DES = 'One record per group with the sum, mean, largest or smallest value (PROC SUMMARY)';
  %LOCAL t0 i;
  %LET t0 = %_spl_begin(summarize_groups);
  %IF not %_spl_need(summarize_groups, data by vars stats out) %THEN %RETURN;
  %IF not %_spl_vars(summarize_groups, data, by vars) %THEN %RETURN;
  %IF %SYSFUNC(COUNTW(&vars., %STR( ))) ne %SYSFUNC(COUNTW(&stats., %STR( ))) %THEN %DO;
    %PUT %STR(ERR)OR: [summarize_groups] stats=&stats. needs one statistic for each of vars=&vars.;
    %PUT %STR(ERR)OR: [summarize_groups]   fix: give one of sum mean max min for each.;
    %RETURN;
  %END;

  /* the summary of each variable over the records of each group */
  PROC SUMMARY DATA=&data. NWAY MISSING;
    CLASS &by.;
    VAR &vars.;
    OUTPUT OUT=&out.(DROP=_TYPE_ _FREQ_)
    %DO i = 1 %TO %SYSFUNC(COUNTW(&vars., %STR( )));
      %SCAN(&stats., &i., %STR( ))(%SCAN(&vars., &i., %STR( ))) = %SCAN(&vars., &i., %STR( ))
    %END;
    ;
  RUN;
  %_spl_end(summarize_groups, &t0.)
%MEND summarize_groups;
