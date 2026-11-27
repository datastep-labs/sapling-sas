/*******************************************************************************
| Macro Name    : mmrm.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.9.1
| Created By    : Sapling
| Date          : 16NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : The mixed model for repeated measures, one record per subject
|                 and visit (PROC MIXED, REPEATED): at one visit the differences
|                 of the LS means of pairs of groups (diff, diff_se, lcl, ucl,
|                 pval) and, when stats= asks for them, the LS mean of each
|                 group (lsmean, lsmean_se). When the covariance structure does
|                 not converge the next one of fallback= is tried.
| Procedure     : PROC MIXED (REPEATED, LSMEANS)
| Proven        : the known answer of the method mmrm (src/methods.ts, worked
|                 out by tools/method_answers.R; node tools/methods_sas.ts); ran
|                 on SAS 9.4 M9, 2026-11-12
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| data        The records                                         Required
| where       The records to use, a condition in parentheses      Optional
| var         The response                                        Required
| by          The groups: a character variable                    Required
| visit       The repeated variable (REPEATED), a class factor    Required
| at          The visit of the LS means, in quotes                Required
| class       The class factors besides the groups and the        Optional
|             subject (the visit is one)
| subject     The subject (default USUBJID)                       USUBJID
| model       The fixed effects: the MODEL statement after the    Required
|             equal sign
| type        The covariance structure: TYPE= of REPEATED         un
|             (default un)
| fallback    Other structures to try in their order, when one    Optional
|             does not converge
| ddfm        The degrees of freedom: DDFM= of MODEL (default     bw
|             bw: between-within)
| method      reml (default) or ml                                reml
| pairs       all: each later group against each earlier one, in  all
|             the order of ORDER; or the pairs separated by #,
|             one pair per line, the group first, then the group
|             it is compared with (a value with a blank or a
|             hyphen in quotes): "Drug" "Placebo" # "High"
|             "Low". The form "A"-"B" of version 1.0 is still
|             read.
| order       A numeric variable with one value per group: the    Optional
|             order of the groups
| level       The confidence level (default 0.95)                 0.95
| stats       The statistics, as in %lsmeans                      diff="XX.X"
|                                                                 diff_se="XX.XX" lcl="XX.X"
|                                                                 ucl="XX.X" pval="X.XXX"
| label       The label of the block in a table, in quotes        Optional
| out         The result                                          Required
| debug       yes: keep the work data sets of the macro           no
|             (_mmrm_*)
|-------------------------------------------------------------------------------
|
| Output        : OUT: as %lsmeans: the rows of the differences (BY, VERSUS) and of
|                 the LS means.
| Note          : The model is fitted by iteration: another program gives the
|                 same numbers to about five digits, not to the last one. A
|                 structure may converge in one engine and not in the other:
|                 on visits very closely correlated PROC MIXED stops AR(1) with
|                 an infinite likelihood where nlme (the R twin mmrm())
|                 converges, so the same call may use the next structure of
|                 fallback= in SAS. The NOTE "[mmrm] The covariance structure
|                 TYPE=... converged" names the one used; the WARNING lines of
|                 a fit that did not converge are followed by a NOTE that says
|                 so.
|
| Example:
|
 %mmrm(
     data     = adqsadas
   , where    = (paramcd = 'ACTOT' AND anl01fl = 'Y')
   , var      = chg
   , by       = trt01p
   , visit    = avisit
   , at       = "Week 24"
   , class    = sitegr1 avisit
   , model    = base sitegr1 trt01p avisit trt01p*avisit base*avisit
   , type     = un
   , fallback = toep
   , ddfm     = bw
   , pairs    = all
   , order    = trt01pn
   , out      = mmrm
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
