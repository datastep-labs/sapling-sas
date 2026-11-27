/*******************************************************************************
| Macro Name    : pool.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.9.1
| Created By    : Sapling
| Date          : 16NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : Pool small groups: a group (e.g. a site) that has fewer than
|                 MIN subjects in one of the groups of BY (e.g. a treatment)
|                 goes into one pooled group.
| Procedure     : PROC FREQ, PROC SUMMARY, MERGE
| Proven        : the fixtures of the step kind pool (src/adam_steps.ts; node
|                 tools/adam_steps_sas.ts); ran on SAS 9.4 M9, 2026-11-12
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| data        The working data set (changed in place)             Required
| var         The groups to pool (SITEID)                         Required
| by          The variable whose every group must have MIN        Required
|             subjects (the treatment)
| min         The smallest number of subjects                     Required
| length      The length of NEW, e.g. $3                          Optional
| new         The variable to make: VAR, or INTO for a small      Required
|             group
| into        The value of the pooled group                       Required
| debug       yes: keep the work data sets _pool_*                no
|-------------------------------------------------------------------------------
|
| Output        : DATA: NEW: the value of VAR, or INTO for a group of VAR
|                 with fewer than MIN subjects in one of the groups of BY. The
|                 rows keep their order.
|
| Example:
|
 %pool(
     data   = adsl
   , var    = siteid
   , by     = trt01p
   , min    = 3
   , length = $3
   , new    = sitegr1
   , into   = 900
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
| 16-NOV-2026 Sapling      1.9.1: into= is checked as required (DEV-027). No
|                          number changes.
|
*******************************************************************************/
%MACRO pool(
     data   =     /* The working data set (changed in place) */
   , var    =     /* The groups to pool (SITEID) */
   , by     =     /* The variable whose groups need MIN subjects */
   , min    =     /* The smallest number of subjects */
   , length =     /* The length of NEW, e.g. $3 */
   , new    =     /* The variable to make: VAR, or INTO when small */
   , into   =     /* The value of the pooled group */
   , debug  = no  /* yes: keep the work data sets _pool_* */
) / DES = 'Pool small groups into one pooled group (PROC FREQ, PROC SUMMARY, MERGE)';
  %LOCAL t0;
  %LET t0 = %_spl_begin(pool);

  /* Step 1: the parameters */
  %IF not %_spl_need(pool, data new var by min into) %THEN %RETURN;
  %IF not %_spl_vars(pool, data, var by) %THEN %RETURN;
  %IF not %_spl_oneof(pool, debug, yes no) %THEN %RETURN;

  /* Step 2: the subjects of each pair; sparse: also the pairs without a subject (0) */
  PROC FREQ DATA=&data. NOPRINT;
    TABLES &var. * &by. / OUT=_pool_count SPARSE;
  RUN;

  /* Step 3: the smallest number of subjects of each group in a group of BY */
  PROC SUMMARY DATA=_pool_count NWAY;
    CLASS &var.;
    VAR count;
    OUTPUT OUT=_pool_min(KEEP=&var. _minn) MIN=_minn;
  RUN;

  /* Step 4: the rows keep their order: their number now; the pooled group of their group */
  DATA &data.;
    SET &data.;
    _pool_row = _N_;
  RUN;
  PROC SORT DATA=&data.; BY &var.; RUN;
  DATA &data.;
    MERGE &data.(IN=_inrows) _pool_min;
    BY &var.;
    IF _inrows;
    %IF %LENGTH(&length.) %THEN %DO;
      LENGTH &new. &length.;
    %END;
    IF NOT MISSING(_minn) AND _minn < &min. THEN &new. = "&into.";
    ELSE                                         &new. = &var.;
    DROP _minn;
  RUN;
  PROC SORT DATA=&data. OUT=&data.(DROP=_pool_row); BY _pool_row; RUN;

  /* Step 5: the work data sets are deleted (kept with debug=yes) */
  %IF %UPCASE(&debug.) ne YES %THEN %DO;
    PROC DATASETS LIBRARY=work NOLIST NOWARN;
      DELETE _pool_:;
    QUIT;
  %END;
  %_spl_end(pool, &t0., &debug.)
%MEND pool;
