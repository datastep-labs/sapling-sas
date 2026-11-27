/*******************************************************************************
| Macro Name    : adjust.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.9.1
| Created By    : Sapling
| Date          : 16NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : The adjusted p-values of a family of pairs of groups (the
|                 hypotheses of a multiplicity block): the p-values (STAT =
|                 pval) of a result of pairs (%lsmeans, %cox, %logistic, %risk,
|                 %rateratio, %ttest, %wilcoxon), in the order of family=,
|                 adjusted by method= (PROC MULTTEST INPVALUES=: bonferroni,
|                 holm (STEPBON), hochberg; a DATA step: bonferroni with
|                 weights, hierarchy, the fixed sequence: the largest p-value of
|                 a hypothesis and those before it). The result is the input
|                 with a row padj for each pair of the family. The family is
|                 every p-value of data= of a pair of family=: when data= has a
|                 pair in several rows (the terms, visits or subgroups of
|                 WITHIN), all of them are adjusted together, as one family
|                 (a pair in two terms: two hypotheses). For a family in each
|                 term, call %adjust once per term on a data set of the rows
|                 of that term (a DATA step with WHERE first).
| Procedure     : PROC MULTTEST (INPVALUES=); a DATA step
| Proven        : the known answer of the method riskdiff (src/methods.ts,
|                 worked out by tools/method_answers.R; node
|                 tools/methods_sas.ts) with the adjusted p-values of a family;
|                 ran on SAS 9.4 M9, 2026-11-12
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| data        A result of pairs: BY, VERSUS, STAT, VALUE          Required
| by          The groups: the variable of the group of each       Required
|             pair
| family      The pairs of the family in their order, separated   Required
|             by #, one pair per line, the group first, then the
|             group it is compared with: "High" "Placebo" #
|             "Low" "Placebo". The form "A"-"B" of version 1.0
|             is still read.
| method      bonferroni, holm, hochberg or hierarchy             Required
| weights     The weight of each hypothesis of a weighted         Optional
|             Bonferroni test, in the order of family=,
|             separated by blanks
| pattern     The pattern of the adjusted p-value (default        "X.XXX"
|             "X.XXX")
| out         The result                                          Required
| debug       yes: keep the work data sets of the macro           no
|             (_adjust_*)
|-------------------------------------------------------------------------------
|
| Output        : OUT: the rows of data= and a row padj per pair of the family.
|
| Example:
|
 %adjust(
     data   = resp_rd
   , by     = trt01p
   , family = "High" "Placebo"
            # "Low"  "Placebo"
   , method = hochberg
   , out    = resp_rd
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
| 12-NOV-2026 Sapling      1.1.0: family= takes the pairs separated by #, one
|                          pair per line; the form "A"-"B" is still read.
| 12-NOV-2026 Sapling      1.2.0: the TEXT of padj never 0 or 1 (<0.001,
|                          >0.999). No number changes.
| 16-NOV-2026 Sapling      1.9.0: the license line; the example in the house
|                          case (names in lower case). No number changes.
| 16-NOV-2026 Sapling      1.9.1: data= without TEXT: the text of the adjusted
|                          p-value has its length (>0.999, not >; DEV-045); the
|                          header says that the family is every row of a pair of
|                          family= (DEV-044). No number changes.
|
*******************************************************************************/
%MACRO adjust(
     data    =           /* A result of pairs: BY, VERSUS, STAT, VALUE */
   , by      =           /* The variable of the group of each pair */
   , family  =           /* The pairs of the family in their order */
   , method  =           /* bonferroni, holm, hochberg or hierarchy */
   , weights =           /* The weights of a weighted Bonferroni test */
   , pattern = "X.XXX"   /* The pattern of the adjusted p value */
   , out     =           /* The result */
   , debug   = no        /* yes: keep the work data sets _adjust_* */
) / DES = 'The adjusted p-values of a family of pairs of groups (PROC MULTTEST)';
  %LOCAL t0 test dsid hastext;
  %LET t0 = %_spl_begin(adjust);

  /* Step 1: the parameters */
  %IF not %_spl_need(adjust, data by family method out) %THEN %RETURN;
  %IF not %_spl_vars(adjust, data, by) %THEN %RETURN;
  %IF not %_spl_oneof(adjust, method, bonferroni holm hochberg hierarchy) %THEN %RETURN;
  %IF not %_spl_oneof(adjust, debug, yes no) %THEN %RETURN;

  %LET by     = %UPCASE(&by.);       /* the groups, in upper case */
  %LET method = %LOWCASE(&method.);  /* the method, in lower case */

  /* Step 2: the pairs of the family in their order (_k), with their weights */
  DATA _adjust_family;
    %_spl_pairlist(list=family)
    KEEP _k _a _b;
  RUN;
  DATA _adjust_family;
    SET _adjust_family;
    _w = INPUT(SCAN("&weights.", _k, ' '), ?? BEST32.);
  RUN;
  PROC SORT DATA=_adjust_family; BY _a _b; RUN;

  /* Step 3: the p value of each pair of the family */
  DATA _adjust_p;
    LENGTH _a _b $200;
    SET &data.(WHERE=(stat = 'pval'));
    _a = &by.;
    _b = versus;
  RUN;
  PROC SORT DATA=_adjust_p; BY _a _b; RUN;
  DATA _adjust_p;
    MERGE _adjust_p(IN=inp) _adjust_family(IN=inf);
    BY _a _b;
    IF inp AND inf;
    raw_p = value;
  RUN;
  PROC SORT DATA=_adjust_p; BY _k; RUN;

  /* Step 4: no p value of the family in data=: the result is data= as it is */
  %IF %_spl_nobs(_adjust_p) = 0 %THEN %DO;
    DATA &out.;
      SET &data.;
    RUN;
    %PUT NOTE: [adjust] No data qualified: data=&data. has no p-value of a pair of family=.;
    %PUT NOTE: [adjust]   out=&out. has no adjusted p-value.;
    %GOTO finish;
  %END;

  /* Step 5: the adjusted p values */
  %IF &method. = hierarchy or (&method. = bonferroni and %LENGTH(&weights.)) %THEN %DO;
    DATA _adjust_p;
      SET _adjust_p;
      RETAIN _max 0;
      %IF &method. = hierarchy %THEN %DO;
        _max = MAX(_max, raw_p);
        padj = _max;
      %END;
      %ELSE %DO;
        padj = MIN(1, raw_p / _w);
      %END;
    RUN;
  %END;
  %ELSE %DO;
    %IF &method. = bonferroni %THEN %LET test = bonferroni;
    %ELSE %IF &method. = holm %THEN %LET test = stepdownbonferroni;
    %ELSE %LET test = hochberg;
    ODS EXCLUDE ALL;
    ODS OUTPUT pValues=_adjust_m;
    PROC MULTTEST INPVALUES=_adjust_p(KEEP=raw_p)
      %IF &method. = holm %THEN STEPBON;
      %ELSE %UPCASE(&method.);;
    RUN;
    ODS EXCLUDE NONE;
    DATA _adjust_p;
      MERGE _adjust_p _adjust_m(KEEP=&test. RENAME=(&test. = padj));
    RUN;
  %END;

  /* Step 6: the rows of the adjusted p values after the rows of data= */
  /* data= without TEXT (BY, VERSUS, STAT, VALUE): TEXT gets the length of the result shape */
  %LET dsid    = %SYSFUNC(OPEN(%SCAN(&data., 1, %STR(%())));
  %LET hastext = %SYSFUNC(VARNUM(&dsid., text));
  %LET dsid    = %SYSFUNC(CLOSE(&dsid.));
  DATA _adjust_rows;
    %IF &hastext. = 0 %THEN %DO;
      LENGTH text $40;
    %END;
    SET _adjust_p;
    LENGTH pattern $40;
    stat    = 'padj';
    value   = padj;
    pattern = &pattern.;
    %_spl_text(value=VALUE, pattern=PATTERN, text=TEXT, pvalue=1)
    DROP _a _b _k _w raw_p padj pattern;
  RUN;
  DATA &out.;
    SET &data. _adjust_rows;
  RUN;

  /* Step 7: the work data sets are deleted (kept with debug=yes) */
  %finish:
  %IF %UPCASE(&debug.) ne YES %THEN %DO;
    PROC DATASETS LIBRARY=work NOLIST NOWARN;
      DELETE _adjust_:;
    QUIT;
  %END;
  %_spl_end(adjust, &t0., &debug.)
%MEND adjust;
