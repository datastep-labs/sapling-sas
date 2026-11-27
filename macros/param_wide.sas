/*******************************************************************************
| Macro Name    : param_wide.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.9.1
| Created By    : Sapling
| Date          : 27NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : Returns the values of several parameters side by side: one
|                 record per group, with the variables of each parameter. The
|                 variables of each parameter are named <PARAMCD>_<VAR>, such as
|                 SYSBP_AVAL. Only a group that has a record of every parameter
|                 of params= gets a record. Two records of one parameter in a
|                 group give an ERROR line that names the group. A code of
|                 params= with no record stops the macro with an ERROR.
| Procedure     : PROC SORT, MERGE
| Proven        : the fixtures of the step kind computed (src/adam_steps.ts;
|                 node tools/adam_steps_sas.ts); ran on SAS 9.4 M9, 2026-11-12
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| data        The input data set, with PARAMCD and the BY         Required
|             variables, such as advs
| where       The records to read: a condition in parentheses,    Optional
|             such as where = (anl01fl = 'Y')
| params      The parameter codes, separated by blanks (params =  Required
|             sysbp diabp). They are compared with PARAMCD in
|             upper case.
| vars        The variables to keep of each parameter, separated  Required
|             by blanks (vars = aval chg)
| by          The groups: variables separated by blanks, such as  Required
|             the subject and the visit (by = usubjid avisitn)
| out         The name of the data set it writes                  Required
| debug       yes: keep the work data sets _param_wide_*          no
|-------------------------------------------------------------------------------
|
| Output        : OUT: one record per group that has a record of every
|                 parameter: the BY variables, then <PARAMCD>_<VAR> for each
|                 parameter and each variable of vars=.
|
| Example:
|
 * Puts the value and the change of SYSBP and DIABP side by side: one row per subject and visit.;
 %param_wide(
     data   = advs
   , where  = (anl01fl = 'Y')
   , params = sysbp diabp
   , vars   = aval chg
   , by     = usubjid avisitn
   , out    = bp_wide
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
| 16-NOV-2026 Sapling      1.9.1: params= in any case (DEV-023: params=weight
|                          reads PARAMCD WEIGHT); a code without a record stops
|                          with the ERROR of the macro.
| 27-NOV-2026 Sapling      1.9.1: the example runs on the example data
|                          (sas/examples). The text of the header for the
|                          manual: the summary, the form of each parameter. No
|                          number changes.
| 27-NOV-2026 Sapling      1.9.1: a caption for each call of the example (a
|                          comment line before it). No number changes.
|
*******************************************************************************/
%MACRO param_wide(
     data   =     /* The records, with PARAMCD and BY */
   , where  =     /* The records to read, in parentheses */
   , params =     /* The parameter codes */
   , vars   =     /* The variables of each parameter to keep (AVAL) */
   , by     =     /* The groups (the subject and the visit) */
   , out    =     /* One record per group */
   , debug  = no  /* yes: keep the work data sets _param_wide_* */
) / DES = 'The values of several parameters side by side, one record per group (PROC SORT, MERGE)';
  %LOCAL t0 i j n p v lastby rename;
  %LET t0 = %_spl_begin(param_wide);

  /* Step 1: the parameters */
  %IF not %_spl_need(param_wide, data params vars by out) %THEN %RETURN;
  %IF not %_spl_vars(param_wide, data, vars by) %THEN %RETURN;
  %IF not %_spl_oneof(param_wide, debug, yes no) %THEN %RETURN;

  %LET lastby = %SCAN(&by., -1, %STR( ));  /* the last variable of by= */
  %LET n      = %SYSFUNC(COUNTW(&params., %STR( )));  /* the number of parameters */
  %DO i = 1 %TO &n.;
    %LET p      = %SCAN(&params., &i., %STR( ));
    %LET rename = ;
    %DO j = 1 %TO %SYSFUNC(COUNTW(&vars., %STR( )));
      %LET v      = %SCAN(&vars., &j., %STR( ));
      %LET rename = &rename. &v.=&p._&v.;
    %END;

    /* Step 2: the records of each parameter, its variables under their new names */
    /* the code of params= in any case: PARAMCD is compared in upper case */
    DATA _param_wide_&i.;
      SET &data.;
      IF UPCASE(paramcd) = "%UPCASE(&p.)";
      %IF %LENGTH(%SUPERQ(where)) %THEN %DO;
        IF &where.;
      %END;
      KEEP &by. &vars.;
      RENAME &rename.;
    RUN;
    /* a code of params= without a record: no result */
    %IF %_spl_nobs(_param_wide_&i.) = 0 %THEN %DO;
      %PUT %STR(ERR)OR: [param_wide] params=&p. has no record in data= (with where=);
      %PUT %STR(ERR)OR: [param_wide]   fix: give params= the codes of PARAMCD in data=.;
      %GOTO finish;
    %END;
    PROC SORT DATA=_param_wide_&i.; BY &by.; RUN;

    /* Step 3: one record of the parameter in each group */
    DATA _NULL_;
      SET _param_wide_&i.;
      BY &by.;
      IF first.&lastby. AND NOT last.&lastby. THEN PUT
          "ERR" "OR: [param_wide] a group of by=&by. has two records of the parameter &p.: "
          "choose one with where= " (&by.) (=);
    RUN;
  %END;

  /* Step 4: the groups that have a record of every parameter */
  DATA &out.;
    MERGE
    %DO i = 1 %TO &n.;
      _PARAM_WIDE_&i.(in = _inparam&i.)
    %END;
    ;
    BY &by.;
    IF _inparam1
    %DO i = 2 %TO &n.;
      AND _inparam&i.
    %END;
    ;
  RUN;

  /* Step 5: the work data sets are deleted (kept with debug=yes) */
  %finish:
  %IF %UPCASE(&debug.) ne YES %THEN %DO;
    PROC DATASETS LIBRARY=work NOLIST NOWARN;
      DELETE _param_wide_:;
    QUIT;
  %END;
  %_spl_end(param_wide, &t0., &debug.)
%MEND param_wide;
