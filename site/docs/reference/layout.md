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

`data=`
:   The stacked results (out= of [%stack](stack.md)). *(required)*

`columns=`
:   The columns (out= of [%columns](columns.md)): the place, the header and the N of each column. *(required)*

`var=`
:   The column variable of the results: the same variable as `var=` of [%columns](columns.md). *(required)*

`page=`
:   A group variable of the results, such as `page = sex`: one page per value, in the order of its numeric twin (SEXN), else of its values. It is no level of the rows; each page starts with its first block, and the header of a column on a page has the N of that page. Give [%columns](columns.md) the same `page=`. It goes into the setup. *(optional)*

`format=`
:   The labels of categories: pairs of a variable and a character format, as in a FORMAT statement (`format = sex $sexf. race $racef.`). A value that the format decodes shows its label. *(optional)*

`label=`
:   Column labels for [%print](print.md): name="text" pairs, separated by blanks. They go into the setup after row=" ". *(optional)*

`rows=`
:   The rows of a page for [%print](print.md) (rows= of [%print](print.md)): a whole number. It goes into the setup. *(optional)*

`file=`
:   The output of [%print](print.md): a path without its extension (file= of [%print](print.md)). It goes into the setup. *(optional)*

`nodata=`
:   The text that [%print](print.md) prints when there is no row (nodata= of [%print](print.md)). It goes into the setup. *(optional)*

`setup=`
:   The name of a global macro variable that keeps the [%print](print.md) call of `out=`: a SAS name that does not start with SYS or SPL_. When not given, no setup is made. *(optional)*

`out=`
:   The name of the display data set. *(required)*

`debug=`
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

The line table: the order of a line, its label, then its template.

- 0, a category of a frequency block: {n} {pct} {events} ({lcl}, {ucl})
- 1, n: {n}
- 2, Events: {events}
- 2.5, Patient-years: {exposure}
- 3, Mean (SD): {mean} ({sd}) [{se}]. With se and no sd the label is Mean (SE); with both, Mean (SD) [SE].
- 4, Median: {median}
- 5, Q1, Q3: {q1}, {q3}
- 6, Min, Max: {min}, {max}
- 7, LS mean (SE): {lsmean} ({lsmean_se})
- 8, Difference (SE): {diff} ({diff_se})
- 9, the estimate, labelled by its STAT (hr Hazard ratio, or Odds ratio, irr Rate ratio, rd Risk difference, rr Relative risk, rate Rate per 100 patient-years, else Estimate): {estimate}
- 10, Confidence interval: ({lcl}, {ucl})
- 11, p-value: {pval}
- 11.5, Adjusted p-value: {padj}
- 12, any other STAT, labelled by its name: {value}

In a template:

- A part that is missing leaves out its piece with its brackets or its comma: a confidence interval without its upper limit prints the lower limit alone.
- A TEXT that has the brackets of its piece already is not bracketed twice.
- The counts of a frequency block are right aligned to the widest count.

The setup (setup=):

- The global macro variable keeps the parameters of [%print](print.md) for `out=`: `data=`, by=row, var=c:, together=grp and label=row=" " with the labels of `label=`; also `page=`, `rows=`, `file=` and `nodata=` when they are given to %layout. A NOTE in the log shows it.
- %print(&name.) prints the display data set again after a change. A parameter that is not in the setup is added after it: %print(&name., `file=`...).
- A parameter that is in the setup cannot be given again, as SAS stops a call that has a keyword twice: give it to %layout, or write the whole [%print](print.md) call.

When `data=` has no row, the display data set has no row, and [%print](print.md) prints the text of `nodata=`.

## Examples

The examples run on the [example data](../tutorial/index.md#the-example-data) after `examples/setup.sas`. The output under each call is the output of that run. They also read `t14_2_1` (made by the [example of %stack](stack.md#examples)), `t14_2_1_cols` (made by the [example of %columns](columns.md#examples)).

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

## See also

Build a table: [%stack](stack.md), [%columns](columns.md), [%ard](ard.md), [%print](print.md), [%csv](csv.md).

Named on this page: [%table](table.md).

## Proof

The examples of this page ran on SAS 9.4M9 on 2026-11-27, with a log free of ERROR and WARNING.

Used in the proof against pharmaverse: [t14_2_01](https://github.com/datastep-labs/sapling-sas/blob/main/proof/pilot1/programs/t14_2_01.sas) (R Submission Pilot 1), [t14_3_01](https://github.com/datastep-labs/sapling-sas/blob/main/proof/pilot1/programs/t14_3_01.sas) (R Submission Pilot 1), [t14_3_02](https://github.com/datastep-labs/sapling-sas/blob/main/proof/pilot1/programs/t14_3_02.sas) (R Submission Pilot 1), [adverse_events](https://github.com/datastep-labs/sapling-sas/blob/main/proof/pharmaverse/programs/adverse_events.sas) (pharmaverse examples), [demographic](https://github.com/datastep-labs/sapling-sas/blob/main/proof/pharmaverse/programs/demographic.sas) (pharmaverse examples). See [what the proof shows](../explanation/proof.md).

[Source of %layout](https://github.com/datastep-labs/sapling-sas/blob/main/macros/layout.sas)
