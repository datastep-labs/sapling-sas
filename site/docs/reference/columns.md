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

<a id="data"></a>`data=`
:   The stacked results (out= of [%stack](stack.md)). *(required)*

<a id="n"></a>`n=`
:   The population: a data set with USUBJID and the column variable, such as adsl. Each subject counts once in the N of its column. When not given, the columns have no N. *(optional)*

<a id="var"></a>`var=`
:   The column variable: one variable, the first variable of `by=` of the statistics macros (`var = trt01a`). *(required)*

<a id="order"></a>`order=`
:   The numeric twin of `var=` in `n=`, such as `order = trt01an`: the columns are in its order. When not given, the columns are in the order of their values. *(optional)*

<a id="page"></a>`page=`
:   A variable of the results and of `n=`, such as `page = sex`: one page per value. The N of a column is then the N of its page. Give [%layout](layout.md) the same `page=`. *(optional)*

<a id="total"></a>`total=`
:   yes: the results have the group Total (`total = yes` of the statistics macros); it is the last column, and its N is all subjects of `n=`. A text in quotes is the other name that the statistics macros gave the Total. *(optional, default `no`)*

<a id="out"></a>`out=`
:   The name of the data set of the columns. *(required)*

<a id="debug"></a>`debug=`
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

The examples run on the [example data](../tutorial/index.md#the-example-data) after `examples/setup.sas`. The output under each call is the output of that run. They also read `t14_2_1` (made by the [example of %stack](stack.md#ex-t14_2_1)), `t14_1_1` (made by the [example of %stack](stack.md#ex-t14_1_1)). All examples of the reference run as one program: [examples/reference.sas](https://github.com/datastep-labs/sapling-sas/blob/main/examples/reference.sas).

??? note "Before these examples: the calls that make their inputs"

    Run `examples/setup.sas`, then these calls from the examples of %describe, %anova, %freq, %chisq, %stack, in this order. Then the examples of this page run as shown.

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
    ```

<a id="ex-t14_2_1_cols"></a>

Makes the four columns with their N from adsl, the Total last, in the order of TRT01AN.

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

<a id="ex-t14_1_1_cols"></a>

Gives page=sex: one row per column and sex, the N of each column on the page of its sex.

```sas
%columns(
     data  = t14_1_1
   , n     = adsl
   , var   = trt01a
   , order = trt01an
   , page  = sex
   , total = yes
   , out   = t14_1_1_cols
 )
```

```text
t14_1_1_cols: 8 rows
HEADER                       SEX  COLVALUE              COL  BIGN
Placebo|(N=53)               F    Placebo                 1    53
Xanomeline Low Dose|(N=55)   F    Xanomeline Low Dose     2    55
Xanomeline High Dose|(N=35)  F    Xanomeline High Dose    3    35
Total|(N=143)                F    Total                   4   143
Placebo|(N=33)               M    Placebo                 1    33
Xanomeline Low Dose|(N=41)   M    Xanomeline Low Dose     2    41
Xanomeline High Dose|(N=37)  M    Xanomeline High Dose    3    37
Total|(N=111)                M    Total                   4   111
```

<a id="ex-t14_2_1_cols_no_n"></a>

Leaves out n=: the columns have no N and come in the order of their values, the Total last.

```sas
%columns(
     data  = t14_2_1
   , var   = trt01a
   , total = yes
   , out   = t14_2_1_cols_no_n
 )
```

```text
t14_2_1_cols_no_n: 4 rows
HEADER                COLVALUE              COL  BIGN
Placebo               Placebo                 1
Xanomeline High Dose  Xanomeline High Dose    2
Xanomeline Low Dose   Xanomeline Low Dose     3
Total                 Total                   4
```

## Messages

A wrong call writes the message and its fix to the log and stops. The macro also gives the [messages every macro shares](index.md#messages-every-macro-shares).

| Message | Fix |
|---|---|
| page=&lt;page&gt; is the column variable var=&lt;var&gt; | give page= another BY variable, such as sex. |

## See also

Build a table: [%stack](stack.md), [%ard](ard.md), [%layout](layout.md), [%print](print.md), [%csv](csv.md).

Named on this page: [%freq](freq.md).

Guides that use %columns: [Tutorial: your first table](../tutorial/index.md), [Check a table against an independent program](../how-to/check-a-table.md), [Make a demographic table with tests](../how-to/demographic-table.md), [Make a Kaplan-Meier figure with the number at risk](../how-to/kaplan-meier-figure.md), [Use the macros in your own program](../how-to/own-program.md), [Make one page per subgroup](../how-to/page-per-subgroup.md).

## Proof

The tables of a made-up study: the N of every column the same as that of a second program in R; ran on SAS 9.4 M9, 2026-11-12.

The examples of this page ran on SAS 9.4 M9 on 2026-11-27, with a log free of ERROR and WARNING.

Used in the proof against pharmaverse: [t14_2_01](https://github.com/datastep-labs/sapling-sas/blob/main/proof/pilot1/programs/t14_2_01.sas) (R Submission Pilot 1), [t14_3_01](https://github.com/datastep-labs/sapling-sas/blob/main/proof/pilot1/programs/t14_3_01.sas) (R Submission Pilot 1), [t14_3_02](https://github.com/datastep-labs/sapling-sas/blob/main/proof/pilot1/programs/t14_3_02.sas) (R Submission Pilot 1), [adverse_events](https://github.com/datastep-labs/sapling-sas/blob/main/proof/pharmaverse/programs/adverse_events.sas) (pharmaverse examples), [demographic](https://github.com/datastep-labs/sapling-sas/blob/main/proof/pharmaverse/programs/demographic.sas) (pharmaverse examples). See [what the proof shows](../explanation/proof.md).

[Source of %columns](https://github.com/datastep-labs/sapling-sas/blob/main/macros/columns.sas)
