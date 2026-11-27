/*******************************************************************************
| Macro Name    : describe.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.9.1
| Created By    : Sapling
| Date          : 16NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : Descriptive statistics of a variable in each group: n, mean, SD,
|                 median, minimum and maximum of the values that are not missing;
|                 Q1, Q3 and the standard error when stats= asks for them.
| Procedure     : PROC MEANS
| Proven        : the known answer of the method contsumm (src/methods.ts, worked
|                 out by tools/method_answers.R); ran on SAS 9.4 M9, 2026-11-12
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| data        The records: a data set                             Required
| where       The records to use, a condition in parentheses      Optional
| var         The variable                                        Required
| by          The groups: variables. The first gives the columns  Required
|             of a table, the others its rows (a parameter, a
|             visit).
| keep        Variables kept in the result for the names and the  Optional
|             order of its rows (PARAM, AVISITN): the largest
|             value in each group (the ID statement)
| total       yes: also all groups of the first BY variable       no
|             together, as the group "Total" (a record without a
|             group is in none, nor in the Total); a text in
|             quotes is another name for it
| qntldef     The definition of the quantiles, 1 to 5 (5 is the   5
|             SAS default)
| stats       The statistics in the order of the rows, each with  n="XX" mean="XX.X"
|             its pattern; also q1, q3 and se                     sd="XX.XX" median="XX.X"
|                                                                 min="XX" max="XX"
| label       The label of the block in a table, in quotes        Optional
| out         The result                                          Required
| debug       yes: keep the work data sets _describe_*            no
|-------------------------------------------------------------------------------
|
| Output        : OUT: one row per group and statistic: the BY variables (and KEEP),
|                 GROUPS (the names of the BY variables), BLOCK (the label), STAT,
|                 VALUE (the number) and TEXT (the number as printed). A group
|                 without a value has no row; no value at all: no row and the
|                 NOTE "No data qualified".
|
| Example:
|
 %describe(
     data  = adsl
   , var   = age
   , by    = trt01a
   , total = yes
   , label = "Age (years)"
   , out   = age
 )
 %describe(
     data  = advs
   , where = (anl01fl = 'Y')
   , var   = aval
   , by    = trt01a paramcd avisit
   , keep  = param avisitn
   , out   = vs
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
