/*******************************************************************************
| Macro Name    : summarize_groups.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.9.1
| Created By    : Sapling
| Date          : 27NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : Returns one record per group with the sum, mean, largest or
|                 smallest value of each variable over the group. Use %summarize
|                 to add a summary of each subject's records to another data
|                 set. A missing value of a BY variable is a group of its own. A
|                 sum or a mean of only missing values is missing.
| Procedure     : PROC SUMMARY
| Proven        : the fixtures of the step kind parameter (src/adam_steps.ts;
|                 node tools/adam_steps_sas.ts); ran on SAS 9.4 M9, 2026-11-12
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| data        The input data set. When a value is not a variable  Required
|             yet (a condition as 0 or 1), make it first in a
|             DATA step.
| by          The groups: one variable or several, separated by   Required
|             blanks (by = usubjid paramcd)
| vars        The numeric variables to summarize, separated by    Required
|             blanks
| stats       One statistic for each variable of vars=, in the    Required
|             same order, separated by blanks: sum, mean, max or
|             min (stats = sum max)
| out         The name of the data set it writes                  Required
|-------------------------------------------------------------------------------
|
| Output        : OUT: one record per group: the BY variables and the variables
|                 of vars=, each with its summary under its own name.
|
| Example:
|
 * Takes the largest AVAL and the smallest CHG of each subject and parameter: one record each.;
 %summarize_groups(
     data  = advs
   , by    = usubjid paramcd
   , vars  = aval chg
   , stats = max min
   , out   = vs_extremes
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
| 27-NOV-2026 Sapling      1.9.1: the example runs on the example data
|                          (sas/examples). The text of the header for the
|                          manual: the summary, the form of each parameter. No
|                          number changes.
| 27-NOV-2026 Sapling      1.9.1: a caption for each call of the example (a
|                          comment line before it). No number changes.
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
