/*******************************************************************************
| Macro Name    : _spl_stackpairs.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.9.1
| Created By    : Sapling
| Date          : 27NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : The records of each pair of groups asked for, one under the
|                 other: the pair (_PAIR), its group (_A) and the group it is
|                 compared with (_B), and the side of each record (_SIDE: 1 in
|                 _A, 2 in _B). A procedure then runs BY _PAIR _A _B on the 2
|                 groups of each pair, the group first. It computes nothing.
| Used By       : %risk, %ttest, %wilcoxon (inner part)
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| by          The groups: a character variable                    Required
| records     The records (one per subject)                       Required
| pairs       all: each later group against each earlier one, in  Required
|             the order of ORDER (else of the values); or the
|             pairs separated by #, the group first, then the
|             group it is compared with (%_spl_pairlist reads
|             them, and the form "A"-"B" of 1.0)
| order       A numeric variable of the records with one value    Optional
|             per group
| macro       The macro that calls (for the message)              Required
| out         The data set: the records of each pair with _PAIR,  Required
|             _A, _B, _SIDE, sorted by them
|-------------------------------------------------------------------------------
|
| Output        : OUT: the records of each pair with _PAIR, _A, _B and _SIDE (1
|                 in _A, 2 in _B), sorted by them. The macro variable PAIRSOK
|                 of the caller: 1, or 0 when a pair names a group that no
|                 record has (an error in the log).
|
| Example:
|
 %_spl_stackpairs(
     macro   = ttest
   , records = _ttest_records
   , by      = trt01p
   , pairs   = all
   , order   = trt01pn
   , out     = _ttest_pairs
 )
|
|-------------------------------------------------------------------------------
| Change Log :
| Date        Programmer   Description
|-------------------------------------------------------------------------------
| 12-NOV-2026 Sapling      1.0.0: initial version.
| 12-NOV-2026 Sapling      1.1.0: the house standard (docs/sas-style.md). No
|                          number changes.
| 12-NOV-2026 Sapling      1.1.0: the pairs read by %_spl_pairlist (the
|                          pairs separated by #; "A"-"B" still read).
| 13-NOV-2026 Sapling      1.7.1: a pair that names a group no record has is
|                          an error (macro=, PAIRSOK of the caller).
| 16-NOV-2026 Sapling      1.9.0: the license line; the example in the house
|                          case (names in lower case). No number changes.
| 27-NOV-2026 Sapling      1.9.1: the message prints a macro variable, not a
|                          macro expression: it reads the same in the log and in
|                          the code. No number changes.
|
*******************************************************************************/
%MACRO _spl_stackpairs(
     by      =   /* The groups: a character variable */
   , records =   /* The records (one per subject) */
   , pairs   =   /* all, or the pairs: each group, then its comparator */
   , order   =   /* A numeric variable with one value per group */
   , macro   =   /* The macro that calls (for the message) */
   , out     =   /* The records of each pair */
) / DES = 'The records of each pair of groups asked for, one under the other';
  %LOCAL nogroup group;

  /* Step 1: the pairs asked for: _A against _B */
  %IF %QUPCASE(%SUPERQ(pairs)) = ALL %THEN %DO;
    PROC SORT DATA=&records.(KEEP=&by. &order.) OUT=_stackpairs_groups NODUPKEY; BY &order. &by.; RUN;
    DATA _stackpairs_asked;
      LENGTH _a _b $200;
      DO _i = 1 TO _ngroup;
        SET _stackpairs_groups(KEEP=&by.) POINT=_i NOBS=_ngroup;
        _a = &by.;
        DO _j = 1 TO _i - 1;
          SET _stackpairs_groups(KEEP=&by.) POINT=_j;
          _b = &by.;
          OUTPUT;
        END;
      END;
      STOP;
      KEEP _a _b;
    RUN;
  %END;
  %ELSE %DO;
    DATA _stackpairs_asked;
      %_spl_pairlist(list=pairs)
      KEEP _a _b;
    RUN;
  %END;

  /* Step 2: the records of each pair, the group (_side = 1) and the other group (_side = 2) */
  DATA &out.;
    LENGTH _a _b $200;
    IF _N_ = 1 THEN CALL SYMPUTX('pairsok', 1);
    SET _stackpairs_asked;
    _pair = _N_;
    DO _i = 1 TO _nrec;
      SET &records. POINT=_i NOBS=_nrec;
      IF &by. = _a THEN DO;
        _side = 1;
        _na   = 1;
        OUTPUT;
      END;
      ELSE IF &by. = _b THEN DO;
        _side = 2;
        _nb   = 1;
        OUTPUT;
      END;
    END;
    /* a group of the pair that no record has */
         IF _na NE 1 THEN CALL SYMPUTX('nogroup', _a, 'L');
    ELSE IF _nb NE 1 THEN CALL SYMPUTX('nogroup', _b, 'L');
    DROP _i _na _nb;
  RUN;
  PROC SORT DATA=&out.; BY _pair _a _b _side; RUN;
  %IF %LENGTH(%SUPERQ(nogroup)) %THEN %DO;
    DATA _NULL_;
      CALL SYMPUTX('pairsok', 0);
    RUN;
    %LET group = %SUPERQ(nogroup);  /* the group that no record has */
    %PUT %STR(ERR)OR: [&macro.] pairs= names the group "&group.", and no record has it.;
    %PUT %STR(ERR)OR: [&macro.]   fix: give pairs= the values of &by. as the data have them.;
  %END;

  /* Step 3: the work data sets are deleted */
  PROC DATASETS LIBRARY=work NOLIST NOWARN;
    DELETE _stackpairs_:;
  QUIT;
%MEND _spl_stackpairs;
