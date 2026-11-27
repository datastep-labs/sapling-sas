/*******************************************************************************
| Macro Name    : mmrm.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.9.1
| Created By    : Sapling
| Date          : 27NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : Returns the differences of the LS means of pairs of groups at
|                 one visit from a repeated measures mixed model. Use %lsmeans
|                 for one record per subject, and %ancova for the test of one
|                 numeric term. The model is PROC MIXED with a REPEATED
|                 statement: one record per subject and visit (the first with a
|                 value). When the covariance structure of type= does not
|                 converge, the macro tries the structures of fallback= in their
|                 order. The log names the structure used, in a NOTE such as
|                 "[mmrm] The covariance structure TYPE=un converged." (a
|                 structure that did not converge has its own NOTE, and the
|                 WARNING lines of PROC MIXED of that fit are not used). The
|                 macro adds visit= to the class factors: class= needs only the
|                 others. The LS mean of each group at the visit comes when
|                 stats= asks for it. The macro writes a result: a data set with
|                 one row per number (the result shape, see %stack).
| Procedure     : PROC MIXED (REPEATED, LSMEANS)
| Proven        : the known answer of the method mmrm (src/methods.ts, worked
|                 out by tools/method_answers.R; node tools/methods_sas.ts); ran
|                 on SAS 9.4 M9, 2026-11-12
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| data        The input data set: one record per subject and      Required
|             visit
| where       The records to use: a condition in parentheses,     Optional
|             such as where = (paramcd = 'SYSBP' AND anl01fl =
|             'Y')
| var         The response: one numeric variable                  Required
| by          The groups: one character variable                  Required
| visit       The visit: one variable, the repeated factor of     Required
|             the REPEATED statement. The macro adds it to the
|             class factors.
| at          The visit of the LS means and their differences: a  Required
|             value of visit= in quotes (at = "Week 24")
| class       The class factors besides the groups and the        Optional
|             subject: variables separated by blanks
| subject     The subject: one variable                           USUBJID
| model       The fixed effects: the MODEL statement after the    Required
|             equal sign. It must have the term of the groups by
|             visit: model = base trt01p avisit trt01p*avisit.
| type        The covariance structure: TYPE= of REPEATED (un,    un
|             cs, ar(1), toep ...)
| fallback    Other covariance structures to try in their order   Optional
|             when one does not converge, separated by blanks
|             (fallback = toep cs)
| ddfm        The degrees of freedom: DDFM= of MODEL (bw is       bw
|             between-within, kr is Kenward-Roger)
| method      The estimation method: reml or ml                   reml
| pairs       The pairs of groups to compare. all: each later     all
|             group against each earlier one, in the order of
|             order= (or of the values). Or the pairs separated
|             by #, each the group first and then the group it
|             is compared with, a value with a blank or a hyphen
|             in quotes: pairs = "Drug" "Placebo" # "High"
|             "Low"
| order       The order of the groups: one numeric variable with  Optional
|             one value per group (order = trt01pn)
| level       The confidence level of the limits: a number        0.95
|             between 0 and 1
| stats       The statistics, in the order of the rows: each      diff="XX.X"
|             name with the pattern of its printed number,        diff_se="XX.XX" lcl="XX.X"
|             separated by blanks. The names are diff, diff_se,   ucl="XX.X" pval="X.XXX"
|             lcl, ucl, pval, lsmean and lsmean_se. A name
|             without a pattern takes its default pattern
|             (n="XX", mean="XX.X", pval="X.XXX" ...; see
|             %describe).
| label       The label of the block in the table: a text in      Optional
|             quotes. A block is the rows of one call in the
|             table.
| out         The name of the result data set                     Required
| debug       yes: keep the work data sets _mmrm_*                no
|-------------------------------------------------------------------------------
|
| Output        : OUT: the result shape (see %stack), as in %lsmeans. A row of a
|                 difference has the group in the by= variable and the group it
|                 is compared with in VERSUS; a row of an LS mean has VERSUS
|                 blank. GROUPS is the by= variable and VERSUS. When no
|                 structure converges, the macro stops with an ERROR and writes
|                 no result.
| Note          : The model is fitted by iteration: another program gives the
|                 same numbers to about five digits, not to the last one. A
|                 structure may converge in one program and not in the other. On
|                 visits that are very closely correlated, PROC MIXED stops
|                 AR(1) with an infinite likelihood where the function mmrm() of
|                 the R package sapling converges, so the same call may use the
|                 next structure of fallback= in SAS. The NOTE "[mmrm] The
|                 covariance structure TYPE=... converged" names the structure
|                 used. The WARNING lines of a fit that did not converge are
|                 followed by a NOTE that says so.
|
| Example:
|
 * Fits the MMRM of the change at five visits and compares the groups at Week 24.;
 %mmrm(
     data     = advs
   , where    = (paramcd = 'SYSBP' AND anl01fl = 'Y' AND avisitn IN (4 8 12 16 24))
   , var      = chg
   , by       = trt01p
   , visit    = avisit
   , at       = "Week 24"
   , model    = base trt01p avisit trt01p*avisit base*avisit
   , type     = un
   , fallback = toep
   , pairs    = all
   , order    = trt01pn
   , out      = sbp_mmrm
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
| 12-NOV-2026 Sapling      1.1.0: pairs= takes the pairs separated by #, one
|                          pair per line; the form "A"-"B" is still read.
| 12-NOV-2026 Sapling      1.1.0: the label is written into the code
|                          (%_spl_quote), not read by SYMGET when the step
|                          runs: the flat program has it. No number changes.
| 13-NOV-2026 Sapling      1.7.1: the visit is added to class= when it is not
|                          there; stats= may hold LS means only.
| 16-NOV-2026 Sapling      1.9.0: the license line; the example in the house
|                          case (names in lower case). No number changes.
| 16-NOV-2026 Sapling      1.9.1: no structure converged: the work data sets are
|                          deleted and the end line written (DEV-039); a NOTE
|                          after the WARNING lines of a fit that did not
|                          converge; the header names the difference of the
|                          engines (DEV-043). No number changes.
| 27-NOV-2026 Sapling      1.9.1: the example runs on the example data
|                          (sas/examples). The text of the header for the
|                          manual: the summary, the form of each parameter. No
|                          number changes.
| 27-NOV-2026 Sapling      1.9.1: The example without class=avisit (visit= adds
|                          it); the text says how the log names the covariance
|                          structure used. The text of stats=: a name without a
|                          pattern takes its default pattern. No number changes.
| 27-NOV-2026 Sapling      1.9.1: the text of the Note names the R package. No
|                          number changes.
| 27-NOV-2026 Sapling      1.9.1: a caption for each call of the example (a
|                          comment line before it). No number changes.
|
*******************************************************************************/
%MACRO mmrm(
     data     =          /* The records */
   , where    =          /* The records to use: a condition in parentheses */
   , var      =          /* The response */
   , by       =          /* The groups: a character variable */
   , visit    =          /* The repeated variable (REPEATED), a class factor */
   , at       =          /* The visit of the LS means, in quotes */
   , class    =          /* The class factors besides the groups */
   , subject  = USUBJID  /* The subject */
   , model    =          /* The fixed effects: MODEL after the equal sign */
   , type     = un       /* The covariance structure: TYPE= of REPEATED */
   , fallback =          /* Other structures to try, in their order */
   , ddfm     = bw       /* The degrees of freedom: DDFM= of MODEL */
   , method   = reml     /* reml or ml */
   , pairs    = all      /* all, or the pairs: each group, then its comparator */
   , order    =          /* A numeric variable: the order of the groups */
   , level    = 0.95     /* The confidence level */
   , stats    = diff="XX.X" diff_se="XX.XX" lcl="XX.X" ucl="XX.X" pval="X.XXX"
                         /* The statistics, each with its pattern */
   , label    =          /* The label of the block, in quotes */
   , out      =          /* The result */
   , debug    = no       /* yes: keep the work data sets _mmrm_* */
) / DES = 'The mixed model for repeated measures: LS means and differences at a visit (PROC MIXED)';
  %LOCAL t0 i item cond chars mstats dstats try converged rows;
  %LET t0 = %_spl_begin(mmrm);

  /* Step 1: the parameters; the statistics of the LS means and those of the differences */
  %IF not %_spl_need(mmrm, data var by visit at model out) %THEN %RETURN;
  %IF not %_spl_vars(mmrm, data, var by visit subject) %THEN %RETURN;
  %IF not %_spl_oneof(mmrm, debug, yes no) %THEN %RETURN;

  %LET by = %UPCASE(&by.);  /* the groups, in upper case */
  /* the visit is a class factor: added to class= when it is not there */
  %IF not %SYSFUNC(INDEXW(%UPCASE(%STR( )&class.), %UPCASE(&visit.))) %THEN
    %LET class = &class. &visit.;  /* the class factors with the visit */
  %LET chars = %_spl_chars(&data., &by.);  /* the character variables */
  %LET cond  = not missing(&var.) and not missing(&by.);  /* the records that count */
  %IF %LENGTH(%SUPERQ(where)) %THEN %LET cond = &cond. and &where.;  /* plus where= */
  %DO i = 1 %TO %SYSFUNC(COUNTW(%SUPERQ(stats), %STR( ), q));
    %LET item = %QSCAN(%SUPERQ(stats), &i., %STR( ), q);
    %IF %INDEX(%LOWCASE(&item.), lsmean) = 1 %THEN %LET mstats = &mstats. &item.;
    %ELSE %LET dstats = &dstats. &item.;
  %END;

  /* Step 2: one record per subject and visit with a value */
  DATA _mmrm_records;
    %IF %LENGTH(&chars.) %THEN %DO;
      LENGTH &chars. $200;
    %END;
    SET &data.;
    WHERE &cond.;
  RUN;
  PROC SORT DATA=_mmrm_records NODUPKEY; BY &subject. &visit.; RUN;

  /* Step 3: no record qualified: the result without a row */
  %IF %_spl_nobs(_mmrm_records) = 0 %THEN %DO;
    %_spl_empty(macro=mmrm, out=&out., like=_mmrm_records, keep=&by., add=versus)
    %GOTO finish;
  %END;

  /* Step 4: the model with the first covariance structure that converges */
  %LET converged = 0;
  %DO i = 1 %TO %SYSFUNC(COUNTW(&type. &fallback., %STR( )));
    %IF not &converged. %THEN %DO;
      %LET try = %SCAN(&type. &fallback., &i., %STR( ));
      PROC DATASETS LIBRARY=work NOLIST NOWARN;
        DELETE _mmrm_means _mmrm_diffs _mmrm_status;
      QUIT;
      ODS EXCLUDE ALL;
      ODS OUTPUT LSMeans=_mmrm_means Diffs=_mmrm_diffs ConvergenceStatus=_mmrm_status;
      PROC MIXED DATA=_mmrm_records METHOD=&method.;
        CLASS &class. &by. &subject.;
        MODEL &var. = &model. / ddfm = &ddfm.;
        REPEATED &visit. / SUBJECT=&subject. TYPE=&try.;
        LSMEANS &by. * &visit. / DIFF CL ALPHA=%SYSEVALF(1 - &level.);
      RUN;
      ODS EXCLUDE NONE;
      %IF %SYSFUNC(EXIST(_mmrm_status)) and %SYSFUNC(EXIST(_mmrm_diffs)) %THEN %DO;
        DATA _NULL_;
          SET _mmrm_status;
          IF status = 0 THEN CALL SYMPUTX('converged', 1, 'L');
        RUN;
      %END;
      %IF &converged. %THEN %PUT NOTE: [mmrm] The covariance structure TYPE=&try. converged.;
      %ELSE %DO;
        %PUT NOTE: [mmrm] The covariance structure TYPE=&try. did not converge.;
        %PUT NOTE: [mmrm]   The WARNING lines of PROC MIXED above are of this fit: not used.;
      %END;
    %END;
  %END;
  %IF not &converged. %THEN %DO;
    %PUT %STR(ERR)OR: [mmrm] no covariance structure of type=&type. fallback=&fallback. converged;
    %PUT %STR(ERR)OR: [mmrm]   fix: give fallback= more types (cs, ar(1), toep) or check it.;
    /* no result: the work data sets are deleted and the end line written */
    %GOTO finish;
  %END;

  /* Step 5: the LS means and the differences at the visit &at. */
  DATA _mmrm_means;
    SET _mmrm_means;
    WHERE &visit. = &at.;
  RUN;
  DATA _mmrm_diffs;
    SET _mmrm_diffs;
    WHERE &visit. = &at. AND _&visit. = &at.;
  RUN;
  %_spl_pairs(
      diffs   = _mmrm_diffs
    , by      = &by.
    , records = _mmrm_records
    , pairs   = &pairs.
    , order   = &order.
    , out     = _mmrm_pairs
  )

  /* Step 6: one row per group or pair and statistic: the result */
  %IF %LENGTH(&mstats.) %THEN %DO;
    DATA _mmrm_mrows;
      SET _mmrm_means(RENAME=(estimate = lsmean stderr = lsmean_se));
      %_spl_rows(stats=&mstats.)
    RUN;
  %END;
  %IF %LENGTH(&dstats.) %THEN %DO;
    DATA _mmrm_drows;
      SET _mmrm_pairs;
      %_spl_rows(stats=&dstats.)
    RUN;
  %END;
  %LET rows = ;
  %IF %LENGTH(&mstats.) %THEN %LET rows = _mmrm_mrows;
  %IF %LENGTH(&dstats.) %THEN %LET rows = &rows. _mmrm_drows;
  DATA &out.;
    LENGTH &by. versus groups block $200;
    SET &rows.;
    %IF %LENGTH(&dstats.) = 0 %THEN %DO;
      versus = ' ';
    %END;
    groups = "&by. VERSUS";
    block  = DEQUOTE(%_spl_quote(label));
    KEEP &by. versus groups block stat value text;
  RUN;

  /* Step 7: the work data sets are deleted (kept with debug=yes) */
  %finish:
  %IF %UPCASE(&debug.) ne YES %THEN %DO;
    PROC DATASETS LIBRARY=work NOLIST NOWARN;
      DELETE _mmrm_:;
    QUIT;
  %END;
  %_spl_end(mmrm, &t0., &debug.)
%MEND mmrm;
