/*******************************************************************************
| Macro Name    : describe.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.9.1
| Created By    : Sapling
| Date          : 27NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : Returns the descriptive statistics of a numeric variable in
|                 each group: n, mean, SD, median, minimum and maximum. Use
|                 %freq for the subjects of each category of a variable. The
|                 macro writes a result: a data set with one row per number (the
|                 result shape, see %stack). Only the values that are not
|                 missing count. Q1, Q3 and the standard error come when stats=
|                 asks for them. The default pattern of min and max is XX, a
|                 whole number: a lab value of 3.9 prints as 4. Give min="XX.X"
|                 max="XX.X" in stats= for values with decimals.
| Procedure     : PROC MEANS
| Proven        : the known answer of the method contsumm (src/methods.ts, worked
|                 out by tools/method_answers.R); ran on SAS 9.4 M9, 2026-11-12
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| data        The input data set                                  Required
| where       The records to use: a condition in parentheses,     Optional
|             such as where = (anl01fl = 'Y'). When not given,
|             all records are used.
| var         The variable to describe: one numeric variable      Required
| by          The groups: one variable or several, separated by   Required
|             blanks. The first variable gives the columns of
|             the table; the others give its rows, such as a
|             parameter and a visit (by = trt01a paramcd
|             avisit).
| keep        Other variables to keep in the result, separated    Optional
|             by blanks, for the names and the order of the rows
|             (keep = param avisitn). Each gets its largest
|             value in the group (the ID statement of PROC
|             MEANS).
| total       yes: add the group "Total", all groups of the       no
|             first BY variable together. A text in quotes gives
|             the Total another name ("All subjects"). A record
|             with a missing group is counted in no group and
|             not in the Total.
| qntldef     The definition of the quantiles: a number from 1    5
|             to 5, as QNTLDEF= of PROC MEANS (5 is the default
|             of SAS)
| stats       The statistics, in the order of the rows: each      n="XX" mean="XX.X"
|             name with its pattern of the printed number,        sd="XX.XX" median="XX.X"
|             separated by blanks. The names are n, mean, sd,     min="XX" max="XX"
|             median, min, max, q1, q3 and se. A name without a
|             pattern takes its default pattern: XX for n,
|             events, min and max; XX.X for mean, median, q1,
|             q3, lsmean, diff, estimate, lcl and ucl; (XX.X%)
|             for pct; X.XXX for pval; XX.XX for the others.
| label       The label of the block in the table: a text in      Optional
|             quotes. A block is the rows of one call in the
|             table.
| out         The name of the result data set                     Required
| debug       yes: keep the work data sets _describe_*            no
|-------------------------------------------------------------------------------
|
| Output        : OUT: the result shape (see %stack), one row per group and
|                 statistic: the BY variables, the variables of keep=, GROUPS,
|                 BLOCK, STAT, VALUE and TEXT. A group with no value has no row.
|                 When no record has a value, the result has no row and the log
|                 has the NOTE "No data qualified".
|
| Example:
|
 %describe(
     data  = adsl
   , var   = age
   , by    = trt01a
   , total = yes
   , label = "Age (years)"
   , out   = age_describe
 )
 %describe(
     data  = advs
   , where = (anl01fl = 'Y')
   , var   = aval
   , by    = trt01a paramcd avisit
   , keep  = param avisitn
   , out   = vs
 )
 %describe(
     data  = advs
   , where = (paramcd = 'WEIGHT' AND ablfl = 'Y')
   , var   = aval
   , by    = trt01a
   , total = "All subjects"
   , stats = n mean sd se median q1 q3 min="XX.X" max="XX.X"
   , label = "Weight at baseline (kg)"
   , out   = wt_describe
 )
|
|-------------------------------------------------------------------------------
| Change Log :
| Date        Programmer   Description
|-------------------------------------------------------------------------------
| 11-NOV-2026 Sapling      1.0.0: initial version.
| 12-NOV-2026 Sapling      1.0.0: ran on SAS 9.4 M9 on its known answer.
| 12-NOV-2026 Sapling      1.1.0: the house standard (header, signature, checks,
|                          log lines, debug=, no data qualified). No number
|                          changes.
| 12-NOV-2026 Sapling      1.1.0: the label is written into the code
|                          (%_spl_quote), not read by SYMGET when the step
|                          runs: the flat program has it. No number changes.
| 16-NOV-2026 Sapling      1.9.0: the license line; the example in the house
|                          case (names in lower case). No number changes.
| 16-NOV-2026 Sapling      1.9.1: a record without a group is not in the group
|                          Total (DEV-001: the Total changes where data= has
|                          such a record); a character var= stops with the ERROR
|                          of the macro (DEV-002).
| 27-NOV-2026 Sapling      1.9.1: the text of the header for the manual: the
|                          summary, the form of each parameter. No number
|                          changes.
| 27-NOV-2026 Sapling      1.9.1: The example result is age_describe, the name
|                          %stack reads. The text of stats=: a name without a
|                          pattern takes its default pattern. No number changes.
| 27-NOV-2026 Sapling      1.9.1: an example with stats= with se, q1 and q3,
|                          decimals for min and max, and the Total named in
|                          quotes; the text says that min and max print as whole
|                          numbers by default. No number changes.
|
*******************************************************************************/
%MACRO describe(
     data    =        /* The records */
   , where   =        /* The records to use: a condition in parentheses */
   , var     =        /* The variable */
   , by      =        /* The groups: the first gives the columns */
   , keep    =        /* Variables kept for the names and order of the rows */
   , total   = no     /* yes: also all groups together, as Total */
   , qntldef = 5      /* The definition of the quantiles (1 to 5) */
   , stats   = n="XX" mean="XX.X" sd="XX.XX" median="XX.X" min="XX" max="XX"
                      /* The statistics, each with its pattern */
   , label   =        /* The label of the block, in quotes */
   , out     =        /* The result */
   , debug   = no     /* yes: keep the work data sets _describe_* */
) / DES = 'Descriptive statistics of a variable in each group (PROC MEANS)';
  %LOCAL t0 first totlab chars cond;
  %LET t0 = %_spl_begin(describe);

  /* Step 1: the parameters */
  %IF not %_spl_need(describe, data var by out) %THEN %RETURN;
  %IF not %_spl_vars(describe, data, var by) %THEN %RETURN;
  %IF not %_spl_oneof(describe, debug, yes no) %THEN %RETURN;

  %LET by     = %UPCASE(%SYSFUNC(COMPBL(&by.)));  /* the groups, in upper case */
  %LET first  = %SCAN(&by., 1, %STR( ));          /* the variable of the columns */
  %LET chars  = %_spl_chars(&data., &by.);        /* the character variables */
  %LET totlab = %_spl_total(%SUPERQ(total));      /* the label of the total group */
  %IF %LENGTH(%_spl_chars(&data., &var.)) %THEN %DO;
    %PUT %STR(ERR)OR: [describe] var=&var. is not numeric;
    %PUT %STR(ERR)OR: [describe]   fix: give var= a numeric variable.;
    %RETURN;
  %END;
  %IF %LENGTH(&totlab.) and not %SYSFUNC(INDEXW(%STR( )&chars., &first.)) %THEN %DO;
    %PUT %STR(ERR)OR: [describe] total= needs a character group first in by= (&first. is numeric);
    %PUT %STR(ERR)OR: [describe]   fix: give by= a character group first, or total=no.;
    %RETURN;
  %END;
  %LET cond = not missing(&var.);  /* the records that count */
  %IF %LENGTH(%SUPERQ(where)) %THEN %LET cond = &cond. and &where.;  /* plus where= */

  /* Step 2: the values of each group; with a total each value once more in the group &totlab. */
  /* a record without a group is in no group (PROC MEANS CLASS), and so not in the total */
  DATA _describe_values;
    %IF %LENGTH(&chars.) %THEN %DO;
      LENGTH &chars. $200;
    %END;
    SET &data.;
    WHERE &cond.;
    OUTPUT;
    %IF %LENGTH(&totlab.) %THEN %DO;
      IF NOT MISSING(&first.) THEN DO;
        &first. = "&totlab.";
        OUTPUT;
      END;
    %END;
    KEEP &by. &var. &keep.;
  RUN;

  /* Step 3: no value qualified: the result without a row */
  %IF %_spl_nobs(_describe_values) = 0 %THEN %DO;
    %_spl_empty(macro=describe, out=&out., like=_describe_values, keep=&by. &keep.)
    %GOTO finish;
  %END;

  /* Step 4: the statistics of each group */
  PROC MEANS DATA=_describe_values NOPRINT NWAY QNTLDEF=&qntldef.;
    CLASS &by.;
    VAR &var.;
    %IF %LENGTH(&keep.) %THEN %DO;
      ID &keep.;
    %END;
    OUTPUT OUT=_describe_means N=n MEAN=mean STD=sd MEDIAN=median MIN=min MAX=max
           Q1=q1 Q3=q3 STDERR=se;
  RUN;

  /* Step 5: one row per group and statistic: the result */
  DATA &out.;
    LENGTH groups block $200;
    SET _describe_means;
    groups = "&by.";
    block  = DEQUOTE(%_spl_quote(label));
    %_spl_rows(stats=&stats.)
    KEEP &by. &keep. groups block stat value text;
  RUN;

  /* Step 6: the work data sets are deleted (kept with debug=yes) */
  %finish:
  %IF %UPCASE(&debug.) ne YES %THEN %DO;
    PROC DATASETS LIBRARY=work NOLIST NOWARN;
      DELETE _describe_:;
    QUIT;
  %END;
  %_spl_end(describe, &t0., &debug.)
%MEND describe;
