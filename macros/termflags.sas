/*******************************************************************************
| Macro Name    : termflags.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.9.1
| Created By    : Sapling
| Date          : 27NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : Returns one record per subject and term, with a flag that says
|                 whether the subject has the term. Use it before %risk to
|                 compare the groups on the subjects with a term; %freq counts
|                 the subjects but gives no flag per subject. The macro computes
|                 no statistic. A term is each combination of the values of
|                 terms= in the records. FLAG is "Y" when the subject has a
|                 record of the term and "N" when not. The subjects are those of
|                 denom=: a subject with a record who is not in denom= is left
|                 out. Then %risk compares the groups on FLAG within each term
|                 (within= the variables of terms=), with the subjects of each
|                 group as the denominator.
| Procedure     : PROC SORT, MERGE, PROC SUMMARY
| Proven        : the known answer of the method perterm (src/methods.ts, worked
|                 out by tools/method_answers.R; node tools/methods_sas.ts); ran
|                 on SAS 9.4 M9, 2026-11-12
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| data        The input data set: the records of the events,      Required
|             with USUBJID
| denom       The subjects of the groups: a data set with one     Required
|             row per subject (the population), with USUBJID and
|             the variable of by=
| where       The records to use: a condition in parentheses,     Optional
|             such as where = (trtemfl = 'Y')
| terms       The variables of a row: one or several, separated   Optional
|             by blanks, nested in their order (terms = aebodsys
|             aedecod: a term within its class). When not given,
|             one row of all the records, such as "any event" of
|             an overview table.
| by          The groups: one variable of denom=                  Required
| threshold   A percent (threshold = 5): keep only the terms      Optional
|             with this percent of the subjects or more in at
|             least one group. The macro compares the percent
|             itself, not its rounded text. It needs terms=.
| out         The name of the result data set                     Required
| debug       yes: keep the work data sets _termflags_*           no
|-------------------------------------------------------------------------------
|
| Output        : OUT: one record per subject of denom= and term: USUBJID, the
|                 variable of by=, the variables of terms= and FLAG ("Y" or
|                 "N"), sorted by the variables of terms= and USUBJID.
|
| Example:
|
 %termflags(
     data      = adae
   , denom     = adsl
   , where     = (trtemfl = 'Y')
   , terms     = aebodsys aedecod
   , by        = trt01a
   , threshold = 5
   , out       = ae_flags
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
| 12-NOV-2026 Sapling      1.1.0: _one is dropped only where it is made (no
|                          terms): the WARNING of a DROP of a variable that is
|                          not there is gone. No number changes.
| 12-NOV-2026 Sapling      1.2.0: the comment of the terms says why, not what
|                          (the owner's rule 7). No number changes.
| 16-NOV-2026 Sapling      1.9.0: the license line; the example in the house
|                          case (names in lower case). No number changes.
| 27-NOV-2026 Sapling      1.9.1: the text of the header for the manual: the
|                          summary, the form of each parameter. No number
|                          changes.
|
*******************************************************************************/
%MACRO termflags(
     data      =     /* The records (the events) */
   , denom     =     /* The subjects of the groups: the population */
   , where     =     /* The records to use: a condition in parentheses */
   , terms     =     /* The variables of a row (none: all the records) */
   , by        =     /* The groups: a variable of denom= */
   , threshold =     /* A percent: only the terms that reach it */
   , out       =     /* The result: USUBJID, BY, TERMS and FLAG */
   , debug     = no  /* yes: keep the work data sets _termflags_* */
) / DES = 'The flag Y or N of each term for every subject of the population (PROC SORT, MERGE)';
  %LOCAL t0;
  %LET t0 = %_spl_begin(termflags);

  /* Step 1: the parameters */
  %IF not %_spl_need(termflags, data by denom out) %THEN %RETURN;
  %IF not %_spl_vars(termflags, data, terms) %THEN %RETURN;
  %IF not %_spl_vars(termflags, denom, by) %THEN %RETURN;
  %IF not %_spl_oneof(termflags, debug, yes no) %THEN %RETURN;

  /* the terms as GROUPS names them */
  %IF %LENGTH(&terms.) %THEN %LET terms = %UPCASE(%SYSFUNC(COMPBL(&terms.)));
  %IF %LENGTH(&terms.) = 0 and %LENGTH(&threshold.) %THEN %DO;
    %PUT %STR(ERR)OR: [termflags] threshold= selects terms and terms= is empty;
    %PUT %STR(ERR)OR: [termflags]   fix: give terms= the variables of a row, or no threshold=.;
    %RETURN;
  %END;
  %LET by = %UPCASE(&by.);  /* the groups, in upper case */

  /* Step 2: the subjects with a record of each term, each once */
  DATA _termflags_hits;
    SET &data.;
    %IF %LENGTH(%SUPERQ(where)) %THEN %DO;
      WHERE &where.;
    %END;
    %IF %LENGTH(&terms.) %THEN %DO;
      IF CMISS(OF &terms.) = 0;
    %END;
    KEEP usubjid &terms.;
  RUN;
  PROC SORT DATA=_termflags_hits NODUPKEY; BY &terms. usubjid; RUN;
  %IF %LENGTH(&terms.) %THEN %DO;
    PROC SORT DATA=_termflags_hits(KEEP=&terms.) OUT=_termflags_terms NODUPKEY; BY &terms.; RUN;
  %END;
  %ELSE %DO;
    /* no term: one row of all the records */
    DATA _termflags_terms;
      _one = 1;
    RUN;
  %END;

  /* Step 3: the subjects of the population, each with its group */
  DATA _termflags_subjects;
    SET &denom.(KEEP=usubjid &by.);
    IF NOT MISSING(&by.);
  RUN;
  PROC SORT DATA=_termflags_subjects NODUPKEY; BY usubjid; RUN;

  /* Step 4: every subject with every term: FLAG = Y when the subject has a record of the term */
  DATA _termflags_all;
    SET _termflags_terms;
    DO _k = 1 TO _nsub;
      SET _termflags_subjects POINT=_k NOBS=_nsub;
      OUTPUT;
    END;
    DROP _k;
    %IF %LENGTH(&terms.) = 0 %THEN %DO;
      DROP _one;
    %END;
  RUN;
  PROC SORT DATA=_termflags_all; BY &terms. usubjid; RUN;
  DATA &out.;
    LENGTH flag $1;
    MERGE _termflags_all(IN=insub) _termflags_hits(IN=hit);
    BY &terms. usubjid;
    IF insub;
    flag = IFC(hit, 'Y', 'N');
    KEEP usubjid &by. &terms. flag;
  RUN;

  %IF %LENGTH(&threshold.) %THEN %DO;

    /* Step 5: the terms that reach the threshold in at least one group */
    PROC SORT DATA=&out. OUT=_termflags_groups; BY &terms. &by.; RUN;
    DATA _termflags_pct;
      SET _termflags_groups;
      BY &terms. &by.;
      IF first.&by. THEN DO;
        _n = 0;
        _y = 0;
      END;
      _n + 1;
      _y + (flag = 'Y');
      IF last.&by. THEN DO;
        pct = 100 * _y / _n;
        OUTPUT;
      END;
      KEEP &terms. pct;
    RUN;
    PROC SUMMARY DATA=_termflags_pct NWAY;
      CLASS &terms.;
      VAR pct;
      OUTPUT OUT=_termflags_top(KEEP=&terms. top) MAX=top;
    RUN;
    DATA &out.;
      MERGE &out.(IN=inall) _termflags_top;
      BY &terms.;
      IF inall AND top >= &threshold. - 1E-9;
      DROP top;
    RUN;
  %END;

  /* Step 6: the work data sets are deleted (kept with debug=yes) */
  %IF %UPCASE(&debug.) ne YES %THEN %DO;
    PROC DATASETS LIBRARY=work NOLIST NOWARN;
      DELETE _termflags_:;
    QUIT;
  %END;
  %_spl_end(termflags, &t0., &debug.)
%MEND termflags;
