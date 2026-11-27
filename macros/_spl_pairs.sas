/*******************************************************************************
| Macro Name    : _spl_pairs.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.10.0
| Created By    : Sapling
| Date          : 16NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : The differences of the pairs of groups asked for, from the
|                 table Diffs of PROC MIXED (it has each pair once, in one
|                 direction). It computes nothing: a difference the other way
|                 round is the same difference with its sign and its limits
|                 turned.
| Used By       : %lsmeans, %mmrm, %cox, %logistic, %rateratio (inner part)
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| by          The groups: a character variable                    Required
| within      The variables of the separate models (BY groups of  Optional
|             PROC MIXED)
| diffs       The Diffs table (the group in BY, the group it is   Required
|             compared with in _BY)
| records     The records of the model (for the groups and their  Required
|             order)
| pairs       all: each later group against each earlier one, in  Required
|             the order of ORDER (else of the values); or the
|             pairs separated by #, the group first, then the
|             group it is compared with (%_spl_pairlist reads
|             them, and the form "A"-"B" of 1.0)
| order       A numeric variable of the records with one value    Optional
|             per group
| out         The data set: WITHIN, BY (the group), VERSUS (the   Required
|             group it is compared with), diff, diff_se, lcl,
|             ucl, pval
|-------------------------------------------------------------------------------
|
| Output        : OUT: WITHIN, BY (the group), VERSUS (the group it is compared
|                 with), diff, diff_se, lcl, ucl, pval: one row per pair asked
|                 for (in each group of WITHIN).
|
| Example:
|
 %_spl_pairs(
     by      = trt01p
   , within  =
   , diffs   = _lsmeans_diffs
   , records = _lsmeans_records
   , pairs   = all
   , order   = trt01pn
   , out     = _lsmeans_pairs
 )
|
|-------------------------------------------------------------------------------
| Change Log :
| Date        Programmer   Description
|-------------------------------------------------------------------------------
| 11-NOV-2026 Sapling      1.0.0: initial version.
| 12-NOV-2026 Sapling      1.1.0: the house standard (docs/sas-style.md). No
|                          number changes.
| 12-NOV-2026 Sapling      1.1.0: the pairs read by %_spl_pairlist (the
|                          pairs separated by #; "A"-"B" still read).
| 16-NOV-2026 Sapling      1.9.0: the license line; the example in the house
|                          case (names in lower case). No number changes.
|
*******************************************************************************/
%MACRO _spl_pairs(
     by      =   /* The groups: a character variable */
   , within  =   /* The variables of the separate models */
   , diffs   =   /* The Diffs table (BY and _BY) */
   , records =   /* The records of the model (the groups, their order) */
   , pairs   =   /* all, or the pairs: each group, then its comparator */
   , order   =   /* A numeric variable with one value per group */
   , out     =   /* The differences of the pairs asked for */
) / DES = 'The differences of the pairs of groups asked for, from the table Diffs of a procedure';

  /* Step 1: the pairs asked for: _A minus _B */
  %IF %QUPCASE(%SUPERQ(pairs)) = ALL %THEN %DO;
    PROC SORT DATA=&records.(KEEP=&by. &order.) OUT=_pairs_groups NODUPKEY; BY &order. &by.; RUN;
    DATA _pairs_asked;
      LENGTH _a _b $200;
      DO _i = 1 TO _ngroup;
        SET _pairs_groups(KEEP=&by.) POINT=_i NOBS=_ngroup;
        _a = &by.;
        DO _j = 1 TO _i - 1;
          SET _pairs_groups(KEEP=&by.) POINT=_j;
          _b = &by.;
          OUTPUT;
        END;
      END;
      STOP;
      KEEP _a _b;
    RUN;
  %END;
  %ELSE %DO;
    DATA _pairs_asked;
      %_spl_pairlist(list=pairs)
      KEEP _a _b;
    RUN;
  %END;
  PROC SORT DATA=_pairs_asked; BY _a _b; RUN;

  /* Step 2: each difference of the procedure in both directions */
  DATA _pairs_both;
    LENGTH _a _b $200;
    SET &diffs.;
    _a      = &by.;
    _b      = _&by.;
    diff    = estimate;
    diff_se = stderr;
    lcl     = lower;
    ucl     = upper;
    pval    = probt;
    OUTPUT;
    _a   = _&by.;
    _b   = &by.;
    diff = -estimate;
    lcl  = -upper;
    ucl  = -lower;
    OUTPUT;
    KEEP &within. _a _b diff diff_se lcl ucl pval;
  RUN;
  PROC SORT DATA=_pairs_both; BY _a _b &within.; RUN;

  /* Step 3: the differences of the pairs asked for */
  DATA &out.;
    LENGTH &by. versus $200;
    MERGE _pairs_both(IN=fitted) _pairs_asked(IN=asked);
    BY _a _b;
    IF fitted AND asked;
    &by. = _a;
    versus = _b;
    DROP _a _b;
  RUN;

  /* Step 4: the work data sets are deleted */
  PROC DATASETS LIBRARY=work NOLIST NOWARN;
    DELETE _pairs_:;
  QUIT;
%MEND _spl_pairs;
