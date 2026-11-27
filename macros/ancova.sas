/*******************************************************************************
| Macro Name    : ancova.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.10.0
| Created By    : Sapling
| Date          : 27NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : Returns the Type III p-value of one numeric term in a linear
|                 model, such as the test of a dose response (test = trt01pn):
|                 the test of one numeric term, not a comparison of the groups.
|                 For the ANCOVA comparison of the groups, use %lsmeans; for a
|                 model of repeated visits, %mmrm. The model is PROC GLM: the
|                 class factors, the covariates and the tested term, one record
|                 per subject (the first with a value; when where= leaves a
|                 second record of a subject, the log has a NOTE with their
|                 number). Give a where= that leaves one record per subject,
|                 such as one parameter at one visit with anl01fl = 'Y';
|                 otherwise each subject has the first of its records in the
|                 order of data=, whichever it is. The coefficient of the term,
|                 its standard error and its confidence limits come when stats=
|                 asks for them. The macro writes a result: a data set with one
|                 row per number (the result shape, see %stack).
| Procedure     : PROC GLM
| Proven        : Checked against its known answer (on a small data set, the
|                 numbers worked out independently in R); ran on SAS 9.4 M9,
|                 2026-11-12
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| data        The input data set, with USUBJID                    Required
| where       The records to use: a condition in parentheses,     Optional
|             such as where = (paramcd = 'SYSBP' AND avisit =
|             'Week 12')
| var         The response: one numeric variable                  Required
| covars      The covariates: numeric variables separated by      Optional
|             blanks (covars = base)
| class       The class factors: variables separated by blanks    Optional
|             (class = sex)
| test        The tested term: one numeric variable, such as a    Required
|             dose or the number of a treatment (test = trt01pn)
| level       The confidence level of the limits: a number        0.95
|             between 0 and 1
| stats       The statistics, in the order of the rows: each      pval="X.XXX"
|             name with the pattern of its printed number,
|             separated by blanks. The names are pval, estimate,
|             se, lcl and ucl. A name without a pattern takes
|             its default pattern (n="XX", mean="XX.X",
|             pval="X.XXX" ...; see %describe).
| label       The label of the block in the table: a text in      Optional
|             quotes. A block is the rows of one call in the
|             table.
| out         The name of the result data set                     Required
| debug       yes: keep the work data sets _ancova_*              no
|-------------------------------------------------------------------------------
|
| Output        : OUT: the result shape (see %stack): one row per statistic, of
|                 all subjects together (GROUPS is blank). STAT is pval,
|                 estimate, se, lcl or ucl.
|
| Example:
|
 * Tests a linear dose response of the change at Week 12, adjusted for baseline: one p value.;
 %ancova(
     data   = advs
   , where  = (paramcd = 'SYSBP' AND avisit = 'Week 12' AND anl01fl = 'Y')
   , var    = chg
   , covars = base
   , test   = trt01pn
   , label  = "Dose response"
   , out    = sbp_dose
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
| 27-NOV-2026 Sapling      1.10.0: the example runs on the example data
|                          (sas/examples). The text of the header for the
|                          manual: the summary, the form of each parameter. No
|                          number changes.
| 27-NOV-2026 Sapling      1.10.0: a NOTE when where= leaves a second record of
|                          a subject (the first is used, as before). No number
|                          changes.
| 27-NOV-2026 Sapling      1.10.0: The example analyses the records of anl01fl =
|                          'Y' (one record per subject). The text of stats=: a
|                          name without a pattern takes its default pattern. No
|                          number changes.
| 27-NOV-2026 Sapling      1.10.0: the text says to give a where= that leaves one
|                          record per subject. No number changes.
| 27-NOV-2026 Sapling      1.10.0: a caption for each call of the example (a
|                          comment line before it). No number changes.
| 27-NOV-2026 Sapling      1.10.0: The first sentence says that the macro tests
|                          one numeric term (a dose response) and names %lsmeans
|                          for the ANCOVA comparison of the groups; Proven in
|                          plain words, for the published manual. No number
|                          changes.
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
  %LOCAL t0 cond ndup;
  %LET t0 = %_spl_begin(ancova);

  /* Step 1: the parameters */
  %IF not %_spl_need(ancova, data var test out) %THEN %RETURN;
  %IF not %_spl_vars(ancova, data, var test) %THEN %RETURN;
  %IF not %_spl_oneof(ancova, debug, yes no) %THEN %RETURN;

  %LET cond = not missing(&var.);  /* the records that count */
  %IF %LENGTH(%SUPERQ(where)) %THEN %LET cond = &cond. and &where.;  /* plus where= */

  /* Step 2: one record per subject with a value */
  PROC SORT DATA=&data. OUT=_ancova_subjects NODUPKEY DUPOUT=_ancova_dups;
    WHERE &cond.;
    BY usubjid;
  RUN;
  %LET ndup = %_spl_nobs(_ancova_dups);  /* the second records of a subject, dropped */
  %IF &ndup. > 0 %THEN %DO;
    %PUT NOTE: [ancova] &ndup. record(s) of where= are a second record of a subject:;
    %PUT NOTE: [ancova]   the first record of each subject is used.;
  %END;

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
