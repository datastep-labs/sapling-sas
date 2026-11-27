/*******************************************************************************
| Macro Name    : ancova.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.9.1
| Created By    : Sapling
| Date          : 16NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : A linear model of a variable, one record per subject (PROC
|                 GLM): class factors, covariates and the tested term. The Type
|                 III test of the tested term (pval); its coefficient, its
|                 standard error and confidence limits (estimate, se, lcl, ucl)
|                 when stats= asks for them.
| Procedure     : PROC GLM
| Proven        : the known answer of the method ancova (src/methods.ts, worked
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
| covars      The covariates, separated by blanks                 Optional
| class       The class factors, separated by blanks              Optional
| test        The tested term: a numeric variable (a dose, a      Required
|             treatment number)
| level       The confidence level of the limits (default 0.95)   0.95
| stats       The statistics, each with its pattern (default      pval="X.XXX"
|             pval="X.XXX"); also estimate, se, lcl, ucl
| label       The label of the block in a table, in quotes        Optional
| out         The result                                          Required
| debug       yes: keep the work data sets of the macro           no
|             (_ancova_*)
|-------------------------------------------------------------------------------
|
| Output        : OUT: one row per statistic, of all subjects together (GROUPS is
|                 blank).
|
| Example:
|
 %ancova(
     data   = advs
   , where  = (paramcd = 'SYSBP' AND avisit = 'Week 12')
   , var    = chg
   , covars = base
   , class  = sitegr1
   , test   = trtpn
   , out    = chg_test
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
| 12-NOV-2026 Sapling      1.1.0: the label is written into the code
|                          (%_spl_quote), not read by SYMGET when the step
|                          runs: the flat program has it. No number changes.
| 16-NOV-2026 Sapling      1.9.0: the license line; the example in the house
|                          case (names in lower case). No number changes.
|
*******************************************************************************/
%MACRO ancova(
     data   =                /* The records */
   , where  =                /* The records to use: a condition in parentheses */
   , var    =                /* The response */
   , covars =                /* The covariates */
   , class  =                /* The class factors */
   , test   =                /* The tested term: a numeric variable */
   , level  = 0.95           /* The confidence level of the limits */
   , stats  = pval="X.XXX"   /* The statistics, each with its pattern */
   , label  =                /* The label of the block, in quotes */
   , out    =                /* The result */
   , debug  = no             /* yes: keep the work data sets _ancova_* */
) / DES = 'The Type III test of a term in a linear model (PROC GLM)';
  %LOCAL t0 cond;
  %LET t0 = %_spl_begin(ancova);

  /* Step 1: the parameters */
  %IF not %_spl_need(ancova, data var test out) %THEN %RETURN;
  %IF not %_spl_vars(ancova, data, var test) %THEN %RETURN;
  %IF not %_spl_oneof(ancova, debug, yes no) %THEN %RETURN;

  %LET cond = not missing(&var.);  /* the records that count */
  %IF %LENGTH(%SUPERQ(where)) %THEN %LET cond = &cond. and &where.;  /* plus where= */

  /* Step 2: one record per subject with a value */
  PROC SORT DATA=&data. OUT=_ancova_subjects NODUPKEY;
    WHERE &cond.;
    BY usubjid;
  RUN;

  /* Step 3: no record qualified: the result without a row */
  %IF %_spl_nobs(_ancova_subjects) = 0 %THEN %DO;
    %_spl_empty(macro=ancova, out=&out., like=_ancova_subjects)
    %GOTO finish;
  %END;

  /* Step 4: the model: its Type III tests and its coefficients */
  ODS EXCLUDE ALL;
  ODS OUTPUT ModelANOVA=_ancova_tests ParameterEstimates=_ancova_coef;
  PROC GLM DATA=_ancova_subjects;
    %IF %LENGTH(&class.) %THEN %DO;
      CLASS &class.;
    %END;
    MODEL &var. = &class. &covars. &test. / ss3 solution clparm alpha = %SYSEVALF(1 - &level.);
  RUN;
  QUIT;
  ODS EXCLUDE NONE;

  /* Step 5: the test of the tested term, its coefficient and its limits */
  DATA _ancova_term;
    MERGE _ancova_tests(KEEP=hypothesistype source probf RENAME=(probf = pval)
                        WHERE=(hypothesistype = 3 AND UPCASE(source) = "%UPCASE(&test.)"))
          _ancova_coef(KEEP=parameter estimate stderr lowercl uppercl
                       RENAME=(stderr = se lowercl = lcl uppercl = ucl)
                       WHERE=(UPCASE(parameter) = "%UPCASE(&test.)"));
  RUN;

  /* Step 6: one row per statistic: the result */
  DATA &out.;
    LENGTH groups block $200;
    SET _ancova_term;
    groups = ' ';
    block  = DEQUOTE(%_spl_quote(label));
    %_spl_rows(stats=&stats.)
    KEEP groups block stat value text;
  RUN;

  /* Step 7: the work data sets are deleted (kept with debug=yes) */
  %finish:
  %IF %UPCASE(&debug.) ne YES %THEN %DO;
    PROC DATASETS LIBRARY=work NOLIST NOWARN;
      DELETE _ancova_:;
    QUIT;
  %END;
  %_spl_end(ancova, &t0., &debug.)
%MEND ancova;
