/*******************************************************************************
| Macro Name    : pool.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.10.0
| Created By    : Sapling
| Date          : 27NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : Pools small groups, such as sites, into one group: a new
|                 variable that is the group, or the pooled value. A group of
|                 var= goes into the pooled group when it has fewer than min=
|                 records in one of the groups of by=, such as a treatment. The
|                 macro counts records: in a data set with one record per
|                 subject, such as adsl, these are the subjects. A group that
|                 has no record in a group of by= counts 0 there and is pooled.
|                 The rows of data= keep their order.
| Procedure     : PROC FREQ, PROC SUMMARY, MERGE
| Proven        : Checked on its test cases of the pooled groups (small made-up
|                 records): every value the same as that of the expected
|                 records; ran on SAS 9.4 M9, 2026-11-12
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| data        The data set to change in place, one record per     Required
|             subject, such as adsl
| var         The variable of the groups to pool, such as siteid  Required
| by          The variable whose every group must have min=       Required
|             records in a group of var=, such as the treatment
| min         The smallest number of records: a whole number      Required
| length      The length of the new variable, such as $3          Optional
| new         The name of the new variable: the value of var=,    Required
|             or into= for a small group
| into        The value of the pooled group, without quotes       Required
| debug       yes: keep the work data sets _pool_*                no
|-------------------------------------------------------------------------------
|
| Output        : DATA: data=, changed in place: the variable new=, with the
|                 value of var=, or the value of into= for a small group.
|
| Example:
|
 * Copies the subjects with their site and their planned treatment.;
 DATA sl;
   SET adsl;
   KEEP usubjid siteid trt01p;
 RUN;
 * Pools each site with fewer than 3 subjects in a group into the site group 900.;
 %pool(
     data   = sl
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
