# %columns

Returns the columns of a table: one row per column, with its N and the header that shows the N.

**Procedure:** PROC SUMMARY · **Family:** [Build a table](index.md#table)

## Syntax

```sas
%columns(
     data  =
   , n     =
   , var   =
   , order =
   , page  =
   , total = no
   , out   =
   , debug = no
 )
```

## Parameters

`data=`
:   The stacked results (out= of [%stack](stack.md)). *(required)*

`n=`
:   The population: a data set with USUBJID and the column variable, such as adsl. Each subject counts once in the N of its column. When not given, the columns have no N. *(optional)*

`var=`
:   The column variable: one variable, the first variable of `by=` of the statistics macros (`var = trt01a`). *(required)*

`order=`
:   The numeric twin of `var=` in `n=`, such as `order = trt01an`: the columns are in its order. When not given, the columns are in the order of their values. *(optional)*

`page=`
:   A variable of the results and of `n=`, such as `page = sex`: one page per value. The N of a column is then the N of its page. Give [%layout](layout.md) the same `page=`. *(optional)*

`total=`
:   yes: the results have the group Total (`total = yes` of the statistics macros); it is the last column, and its N is all subjects of `n=`. A text in quotes is the other name that the statistics macros gave the Total. *(optional, default `no`)*

`out=`
:   The name of the data set of the columns. *(required)*

`debug=`
:   yes: keep the work data sets _columns_*. *(optional, default `no`)*
    Accepts: `yes`, `no`.

## Result

The data set of `out=`: one row per column: COL (its number: 1, 2 ...), COLVALUE (the value of `var=`), BIGN (the N) and HEADER (the value, a | and (N=86); [%print](print.md) splits a header at the |). With `page=`: one row per page and column, the page variable first; BIGN is the N of the page (0: no subject of the column on the page).

## Details

A header is the value, a | and the N: Placebo|(N=86). [%layout](layout.md) reads it to place each number and to label each column; the N comes from the population of `n=`, not from the counts of [%freq](freq.md).

- The columns are the values of the column variable in the results and in the population.
- They are in the order of the numeric twin of `order=`, else of their values; the Total is last.
- The N of a column is the number of subjects of `n=` with its value; the N of the Total is all subjects of `n=`.
- Without `n=` the columns have no N, and the header is the value alone.
- With `page=` each page has the same columns, and the N of a column is the N of its page: with `page = sex` on the example data, Placebo|(N=33) on the page of the males and Placebo|(N=53) on the page of the females.

## Examples

The examples run on the [example data](../tutorial/index.md#the-example-data) after `examples/setup.sas`. The output under each call is the output of that run. They also read `t14_2_1` (made by the [example of %stack](stack.md#examples)).

```sas
%columns(
     data  = t14_2_1
   , n     = adsl
   , var   = trt01a
   , order = trt01an
   , total = yes
   , out   = t14_2_1_cols
 )
```

```text
t14_2_1_cols: 4 rows
HEADER                       COLVALUE              COL  BIGN
Placebo|(N=86)               Placebo                 1    86
Xanomeline Low Dose|(N=96)   Xanomeline Low Dose     2    96
Xanomeline High Dose|(N=72)  Xanomeline High Dose    3    72
Total|(N=254)                Total                   4   254
```

## Messages

A wrong call writes the message and its fix to the log and stops. The macro also gives the [messages every macro shares](index.md#messages-every-macro-shares).

| Message | Fix |
|---|---|
| page=&lt;page&gt; is the column variable var=&lt;var&gt; | give page= another BY variable, such as sex. |

## See also

Build a table: [%stack](stack.md), [%ard](ard.md), [%layout](layout.md), [%print](print.md), [%csv](csv.md).

Named on this page: [%freq](freq.md).

## Proof

The examples of this page ran on SAS 9.4M9 on 2026-11-27, with a log free of ERROR and WARNING.

Used in the proof against pharmaverse: [t14_2_01](https://github.com/datastep-labs/sapling-sas/blob/main/proof/pilot1/programs/t14_2_01.sas) (R Submission Pilot 1), [t14_3_01](https://github.com/datastep-labs/sapling-sas/blob/main/proof/pilot1/programs/t14_3_01.sas) (R Submission Pilot 1), [t14_3_02](https://github.com/datastep-labs/sapling-sas/blob/main/proof/pilot1/programs/t14_3_02.sas) (R Submission Pilot 1), [adverse_events](https://github.com/datastep-labs/sapling-sas/blob/main/proof/pharmaverse/programs/adverse_events.sas) (pharmaverse examples), [demographic](https://github.com/datastep-labs/sapling-sas/blob/main/proof/pharmaverse/programs/demographic.sas) (pharmaverse examples). See [what the proof shows](../explanation/proof.md).

[Source of %columns](https://github.com/datastep-labs/sapling-sas/blob/main/macros/columns.sas)
