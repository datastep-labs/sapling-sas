# %layout

Returns the display data set of a table: one row per printed line and one column per group.

**Procedure:** DATA steps, PROC FORMAT, PROC SORT, PROC TRANSPOSE · **Family:** [Build a table](index.md#table)

## Syntax

```sas
%layout(
     data    =
   , columns =
   , var     =
   , page    =
   , format  =
   , label   =
   , rows    =
   , file    =
   , nodata  =
   , setup   =
   , out     =
   , debug   = no
 )
```

## Parameters

<a id="data"></a>`data=`
:   The stacked results (out= of [%stack](stack.md)). *(required)*

<a id="columns"></a>`columns=`
:   The columns (out= of [%columns](columns.md)): the place, the header and the N of each column. *(required)*

<a id="var"></a>`var=`
:   The column variable of the results: the same variable as `var=` of [%columns](columns.md). *(required)*

<a id="page"></a>`page=`
:   A group variable of the results, such as `page = sex`: one page per value, in the order of its numeric twin (SEXN), else of its values. Its values are not rows of the table; each page starts with its first block, and the header of a column on a page has the N of that page. Give [%columns](columns.md) the same `page=`. It goes into the setup. *(optional)*

<a id="format"></a>`format=`
:   The labels of categories: pairs of a variable and a character format, as in a FORMAT statement (`format = sex $sexf. race $racef.`). A value that the format decodes shows its label. *(optional)*

<a id="label"></a>`label=`
:   Column labels for [%print](print.md): name="text" pairs, separated by blanks. They go into the setup after row=" ". *(optional)*

<a id="rows"></a>`rows=`
:   The rows of a page for [%print](print.md) (rows= of [%print](print.md)): a whole number. It goes into the setup. *(optional)*

<a id="file"></a>`file=`
:   The output of [%print](print.md): a path without its extension (file= of [%print](print.md)). It goes into the setup. *(optional)*

<a id="nodata"></a>`nodata=`
:   The text that [%print](print.md) prints when there is no row (nodata= of [%print](print.md)): a text without quotes, as in [%print](print.md), where a quote in it is printed. It goes into the setup. *(optional)*

<a id="setup"></a>`setup=`
:   The name of a global macro variable that keeps the [%print](print.md) call of `out=`: a SAS name that does not start with SYS or SPL_. When not given, no setup is made. *(optional)*

<a id="out"></a>`out=`
:   The name of the display data set. *(required)*

<a id="debug"></a>`debug=`
:   yes: keep the work data sets _layout_*. *(optional, default `no`)*
    Accepts: `yes`, `no`.

## Result

The data set of `out=`: the display data set, one row per printed line: GRP (the rows that stay on one page: a block, or a level of its first group; a row of a value of all groups, such as a p-value in C99 only, has the GRP of the rows of its block before it), ROW (the label of the line, indented, with the format $CHARw.), C1 ... Cn (the cells, labelled with the header of their column) and C99 (All groups: only when a result has a number without the column variable). With `page=`: also the page variable (with its format of `format=`) and HEAD_C1 ... HEAD_Cn, the header of each column on its page; C1 ... Cn are then labelled with the column value. The global macro variable: with `setup=`, the global macro variable of that name.

## Details

[%print](print.md) prints it; [%table](table.md) runs [%columns](columns.md), [%ard](ard.md), %layout and [%print](print.md) in one call. The display data set is the table as the shells show it: each row a printed line, each cell a text. %layout computes nothing: every number is the TEXT of a result. The rows:

- Each block starts with its label, with a blank row between two blocks.
- The levels of the groups other than the column variable are indented by two blanks each: a term under its class, a visit under its parameter, vs B under A.
- The levels are in the order of their numeric twin (AVISITN for AVISIT, PARAMN for PARAMCD: the name with an N added), else of their values. A level of PARAMCD shows its PARAM.
- A frequency block (only the statistics n, pct, events, lcl and ucl) has one line per category. Any other block has one line per kind of statistic, by the line table below.
- The p-value of each category (a test of each term, in a block of the same label) stands in the row of its category.
- A result has at most four groups besides the column variable and the page variable.

The columns:

- C1 ... Cn: one column per group, with its header and N from [%columns](columns.md).
- C99, All groups: the numbers of a result without the column variable, such as a p-value of all groups.

The line table: each line by its order and its label, then its template.

- line 0 (a category of a frequency block): {n} {pct} {events} ({lcl}, {ucl})
- line 1 (n): {n}
- line 2 (Events): {events}
- line 2.5 (Patient-years): {exposure}
- line 3 (Mean (SD)): {mean} ({sd}) [{se}]. With se and no sd the label is Mean (SE); with both, Mean (SD) [SE].
- line 4 (Median): {median}
- line 5 (Q1, Q3): {q1}, {q3}
- line 6 (Min, Max): {min}, {max}
- line 7 (LS mean (SE)): {lsmean} ({lsmean_se})
- line 8 (Difference (SE)): {diff} ({diff_se})
- line 9 (the estimate, labelled by its STAT): {estimate}. The labels: STAT hr: Hazard ratio; STAT or: Odds ratio; STAT irr: Rate ratio; STAT rd: Risk difference; STAT rr: Relative risk; STAT rate: Rate per 100 patient-years; STAT estimate: Estimate.
- line 10 (Confidence interval): ({lcl}, {ucl})
- line 11 (p-value): {pval}
- line 11.5 (Adjusted p-value): {padj}
- line 12 (any other STAT, labelled by its name): {value}

In a template:

- A part that is missing leaves out its piece with its brackets or its comma: a confidence interval without its upper limit prints the lower limit alone.
- A TEXT that has the brackets of its piece already is not bracketed twice.
- The counts of a frequency block are right aligned to the widest count.

The setup (setup=):

- The global macro variable keeps the parameters of [%print](print.md) for `out=`: `data=`, by=row, var=c:, together=grp and label=row=" " with the labels of `label=`; also `page=`, `rows=`, `file=` and `nodata=` when they are given to %layout. A NOTE in the log shows it.
- `%print(&name.)` prints the display data set again after a change. A parameter that is not in the setup is added after it: `%print(&name., file=...)`.
- A parameter that is in the setup cannot be given again, as SAS stops a call that has a keyword twice: give it to %layout, or write the whole [%print](print.md) call.

When `data=` has no row, the display data set has no row, and [%print](print.md) prints the text of `nodata=`.

## Examples

The examples run on the [example data](../tutorial/index.md#the-example-data) after `examples/setup.sas`. The output under each call is the output of that run. They also read `t14_2_1` (made by the [example of %stack](stack.md#ex-t14_2_1)), `t14_2_1_cols` (made by the [example of %columns](columns.md#ex-t14_2_1_cols)), `t14_1_1` (made by the [example of %stack](stack.md#ex-t14_1_1)), `t14_1_1_cols` (made by the [example of %columns](columns.md#ex-t14_1_1_cols)). All examples of the reference run as one program: [examples/reference.sas](https://github.com/datastep-labs/sapling-sas/blob/main/examples/reference.sas).

??? note "Before these examples: the calls that make their inputs"

    Run `examples/setup.sas`, then these calls from the examples of %describe, %anova, %freq, %chisq, %stack, %columns, %ard, in this order. Then the examples of this page run as shown.

    ```sas
    /* from the example of %describe */
    * Summarizes age in each group and in the Total: n, mean, SD, median, minimum and maximum.;
    %describe(
         data  = adsl
       , var   = age
       , by    = trt01a
       , total = yes
       , label = "Age (years)"
       , out   = age_describe
     )
    * Adds sex as a second BY variable: the rows of each group and sex, for a page per sex.;
    %describe(
         data  = adsl
       , var   = age
       , by    = trt01a sex
       , total = yes
       , label = "Age (years)"
       , out   = age_sex
     )
    /* from the example of %anova */
    * Tests age across the three groups: one row, the p value of the F test.;
    %anova(
         data  = adsl
       , var   = age
       , by    = trt01a
       , label = "Age (years)"
       , out   = age_anova
     )
    /* from the example of %freq */
    * Counts each sex in each group and in the Total: n and the percent of the subjects of the group.;
    %freq(
         data  = adsl
       , var   = sex
       , by    = trt01a
       , total = yes
       , label = "Sex"
       , out   = sex_freq
     )
    * Adds sex as a second BY variable: the age groups of each group and sex, for a page per sex.;
    %freq(
         data  = adsl
       , var   = agegr1
       , by    = trt01a sex
       , total = yes
       , label = "Age group"
       , out   = agegr_sex
     )
    /* from the example of %chisq */
    * Tests sex across the groups: one row, the p value of the chi square test.;
    %chisq(
         data  = adsl
       , var   = sex
       , by    = trt01a
       , label = "Sex"
       , out   = sex_chisq
     )
    /* from the example of %stack */
    * Stacks four results in the order of the table: RESULT and ORD tell where each row came from.;
    %stack(age_describe age_anova sex_freq sex_chisq, out=t14_2_1)
    * Stacks age and the age groups by sex: the results of a table with a page per sex.;
    %stack(age_sex agegr_sex, out=t14_1_1)
    /* from the example of %columns */
    * Makes the four columns with their N from adsl, the Total last, in the order of TRT01AN.;
    %columns(
         data  = t14_2_1
       , n     = adsl
       , var   = trt01a
       , order = trt01an
       , total = yes
       , out   = t14_2_1_cols
     )
    * Gives page=sex: one row per column and sex, the N of each column on the page of its sex.;
    %columns(
         data  = t14_1_1
       , n     = adsl
       , var   = trt01a
       , order = trt01an
       , page  = sex
       , total = yes
       , out   = t14_1_1_cols
     )
    /* from the example of %ard */
    * Writes every number of the table and each column N to one CSV file: the raw value and the text.;
    %ard(data=t14_2_1, columns=t14_2_1_cols, file=t14_2_1)
    ```

<a id="ex-t14_2_1_print"></a><a id="ex-t14_2_1_display"></a>

Makes the display data set: one row per printed line, one column per group, sex by its labels.

```sas
%layout(
     data    = t14_2_1
   , columns = t14_2_1_cols
   , var     = trt01a
   , format  = sex $sexf.
   , file    = &spl_out./tlf/t14_2_1
   , setup   = t14_2_1_print
   , out     = t14_2_1_display
 )
```

```text
t14_2_1_display: 11 rows
GRP  ROW          C1           C2           C3           C4             C99
  1  Age (years)
  1  n            86           96           72           254
  1  Mean (SD)    75.2 (8.59)  76.0 (8.11)  73.8 (7.94)  75.1 (8.25)
  1  Median       76.0         78.0         75.5         77.0
  1  Min, Max     52, 89       51, 88       56, 88       51, 89
  1  p-value                                                          0.235
  2
  2  Sex
  2  Female       53 (61.6%)   55 (57.3%)   35 (48.6%)   143 (56.3%)
  3  Male         33 (38.4%)   41 (42.7%)   37 (51.4%)   111 (43.7%)
  3  p-value                                                          0.251
```

<a id="ex-t14_1_1_print"></a><a id="ex-t14_1_1_display"></a>

Makes one page per sex: SEX and HEAD_C1 to HEAD_C4 hold the page and the N of each column on it.

```sas
%layout(
     data    = t14_1_1
   , columns = t14_1_1_cols
   , var     = trt01a
   , page    = sex
   , format  = sex $sexf.
   , file    = &spl_out./tlf/t14_1_1
   , setup   = t14_1_1_print
   , out     = t14_1_1_display
 )
```

```text
t14_1_1_display: the first 15 of 18 rows
SEX     GRP  ROW          C1           C2           C3           C4           HEAD_C1
Female    1  Age (years)                                                      Placebo|(N=53)
Female    1  n            53           55           35           143          Placebo|(N=53)
Female    1  Mean (SD)    76.4 (8.73)  76.2 (7.97)  73.7 (7.58)  75.7 (8.19)  Placebo|(N=53)
Female    1  Median       78.0         78.0         75.0         77.0         Placebo|(N=53)
Female    1  Min, Max     59, 89       54, 87       56, 88       54, 89       Placebo|(N=53)
Female    2                                                                   Placebo|(N=53)
Female    2  Age group                                                        Placebo|(N=53)
Female    2  18-64        9 (17.0%)    5 ( 9.1%)    5 (14.3%)    19 (13.3%)   Placebo|(N=53)
Female    3  >64          44 (83.0%)   50 (90.9%)   30 (85.7%)   124 (86.7%)  Placebo|(N=53)
Male      4  Age (years)                                                      Placebo|(N=33)
Male      4  n            33           41           37           111          Placebo|(N=33)
Male      4  Mean (SD)    73.4 (8.15)  75.6 (8.38)  73.9 (8.38)  74.4 (8.29)  Placebo|(N=33)
Male      4  Median       74.0         77.0         77.0         77.0         Placebo|(N=33)
Male      4  Min, Max     52, 85       51, 88       56, 86       51, 88       Placebo|(N=33)
Male      5                                                                   Placebo|(N=33)
```

<a id="ex-t14_2_1_label_print"></a><a id="ex-t14_2_1_label_display"></a>

Puts label= and rows= into the setup: the last column is labelled p value, 30 rows a page.

```sas
%layout(
     data    = t14_2_1
   , columns = t14_2_1_cols
   , var     = trt01a
   , format  = sex $sexf.
   , label   = c99="p-value"
   , rows    = 30
   , file    = &spl_out./tlf/t14_2_1_label
   , setup   = t14_2_1_label_print
   , out     = t14_2_1_label_display
 )
```

*No output is shown for this call: it makes `t14_2_1_label_print`, `t14_2_1_label_display` for the calls after it.*

Prints the display data set again with the call that the setup keeps.

```sas
%print(&t14_2_1_label_print.)
```

```text
tlf/t14_2_1_label.lst: 15 lines
             Placebo      Xanomeline Low Dose  Xanomeline High Dose  Total
             (N=86)       (N=96)               (N=72)                (N=254)      p-value
-----------------------------------------------------------------------------------------

Age (years)
  n          86           96                   72                    254
  Mean (SD)  75.2 (8.59)  76.0 (8.11)          73.8 (7.94)           75.1 (8.25)
  Median     76.0         78.0                 75.5                  77.0
  Min, Max   52, 89       51, 88               56, 88                51, 89
  p-value                                                                         0.235

Sex
  Female      53 (61.6%)   55 (57.3%)           35 (48.6%)           143 (56.3%)
  Male        33 (38.4%)   41 (42.7%)           37 (51.4%)           111 (43.7%)
  p-value                                                                         0.251
```

<a id="ex-t_sev50"></a>

Counts the severe events of the subjects under 50: there is none, so the result has no row.

```sas
%freq(
     data  = adae
   , denom = adsl
   , where = (aesev = 'SEVERE' AND age < 50)
   , var   = aedecod
   , by    = trt01a
   , out   = t_sev50
 )
```

*No output is shown for this call: it makes `t_sev50` for the calls after it.*

<a id="ex-t_sev50_print"></a><a id="ex-t_sev50_display"></a>

Gives nodata= for a result with no row: the display data set has no row.

```sas
%layout(
     data    = t_sev50
   , columns = t14_2_1_cols
   , var     = trt01a
   , file    = &spl_out./tlf/t_sev50
   , nodata  = No subject under 50 had a severe event
   , setup   = t_sev50_print
   , out     = t_sev50_display
 )
```

```text
t_sev50_display: 0 rows
GRP  ROW  C1
```

Prints the setup of the empty table: the page has the text of nodata= in place of the rows.

```sas
%print(&t_sev50_print.)
```

```text
tlf/t_sev50.lst: 3 lines
--------------------------------------

No subject under 50 had a severe event
```

## Messages

A wrong call writes the message and its fix to the log and stops. The macro also gives the [messages every macro shares](index.md#messages-every-macro-shares).

| Message | Fix |
|---|---|
| format=&lt;format&gt; is not a list of variable and format. | write it as in a FORMAT statement: format=sex $sexf. |
| page=&lt;page&gt; is the column variable var=&lt;var&gt; | give page= another BY variable, such as sex. |
| columns=&lt;columns&gt; has no page=&lt;page&gt;: its N is not the N of a page | give %columns the same page=&lt;page&gt;. |
| setup=&lt;setup&gt; is not a SAS name | give setup= a name such as t_sex_print. |
| setup=&lt;setup&gt; is a name of a macro or of SAS | give setup= another name, such as t_sex_print. |
| &lt;nopage&gt; row(s) of data=&lt;data&gt; are not by page=&lt;page&gt;. | add &lt;page&gt; to by= of its macro, such as by=trt01a &lt;page&gt;. |
| a result of data=&lt;data&gt; has &lt;deep&gt; groups besides var= (4 at most). | give each result at most 4 groups besides var=. |

The macro also writes these NOTE lines to the log, without stopping:

- `NOTE: [layout] setup=<setup> keeps the print of <out>: <list>`
- `NOTE: [layout] print it with %print(&<setup>.)`

## See also

Build a table: [%stack](stack.md), [%columns](columns.md), [%ard](ard.md), [%print](print.md), [%csv](csv.md).

Named on this page: [%table](table.md).

Guides that use %layout: [Tutorial: your first table](../tutorial/index.md), [Make a demographic table with tests](../how-to/demographic-table.md), [Make one page per subgroup](../how-to/page-per-subgroup.md).

## Proof

The 12 tables of a made-up study, each with a clean log, also as the code the macros wrote, run without the macros; its test cases of setup=; ran on SAS 9.4 M9, 2026-11-12. The 12 tables of the CDISC pilot study (the p-value of each term in Table 14.5.2), 2026-11-13.

The known answers and test cases are kept with the development of the library, not in this repository.

The examples of this page ran on SAS 9.4 M9 on 2026-11-27, with a log free of ERROR and WARNING.

Used in the proof against pharmaverse: [t14_2_01](https://github.com/datastep-labs/sapling-sas/blob/main/proof/pilot1/programs/t14_2_01.sas) (R Submission Pilot 1), [t14_3_01](https://github.com/datastep-labs/sapling-sas/blob/main/proof/pilot1/programs/t14_3_01.sas) (R Submission Pilot 1), [t14_3_02](https://github.com/datastep-labs/sapling-sas/blob/main/proof/pilot1/programs/t14_3_02.sas) (R Submission Pilot 1), [adverse_events](https://github.com/datastep-labs/sapling-sas/blob/main/proof/pharmaverse/programs/adverse_events.sas) (pharmaverse examples), [demographic](https://github.com/datastep-labs/sapling-sas/blob/main/proof/pharmaverse/programs/demographic.sas) (pharmaverse examples). See [what the proof shows](../explanation/proof.md).

[Source of %layout](https://github.com/datastep-labs/sapling-sas/blob/main/macros/layout.sas)
