# %anova

Returns the p-value of the F test of a one-way analysis of variance of a variable between the groups.

**Procedure:** PROC GLM · **Family:** [Test the groups](index.md#tests)

## Syntax

```sas
%anova(
     data  =
   , where =
   , var   =
   , by    =
   , stats = pval="X.XXX"
   , label =
   , out   =
   , debug = no
 )
```

## Parameters

`data=`
:   The input data set. *(required)*

`where=`
:   The records to use: a condition in parentheses, such as `where = (anl01fl = 'Y')`. *(optional)*

`var=`
:   The variable to analyse: one numeric variable. *(required)*

`by=`
:   The groups to compare: one variable. *(required)*

`stats=`
:   The statistic with its pattern of the printed number: pval. *(optional, default `pval="X.XXX"`)*

`label=`
:   The label of the block in the table: a text in quotes. A block is the rows of one call in the table. *(optional)*

`out=`
:   The name of the result data set. *(required)*

`debug=`
:   yes: keep the work data sets _anova_*. *(optional, default `no`)*
    Accepts: `yes`, `no`.

## Result

The data set of `out=`: the [result shape](../explanation/result-shape.md), one row: STAT pval, with GROUPS blank (all the groups together), BLOCK, VALUE and TEXT. When no record qualifies, the result has no row.

## Details

Use [%ttest](ttest.md) or [%wilcoxon](wilcoxon.md) to compare pairs of groups, and [%ancova](ancova.md) when the model has covariates. The model is `var=` by `by=` (PROC GLM). The p-value is that of the model, one test of all the groups together. A record with a missing value or a missing group is not used.

## Examples

The examples run on the [example data](../tutorial/index.md#the-example-data) after `examples/setup.sas`. The output under each call is the output of that run.

Tests age across the three groups: one row, the p value of the F test.

```sas
%anova(
     data  = adsl
   , var   = age
   , by    = trt01a
   , label = "Age (years)"
   , out   = age_anova
 )
```

```text
age_anova: 1 row
GROUPS  BLOCK        STAT         VALUE   TEXT
        Age (years)  pval  0.2346471181  0.235
```

## Messages

The macro gives only the [messages every macro shares](index.md#messages-every-macro-shares).

## See also

Test the groups: [%ttest](ttest.md), [%wilcoxon](wilcoxon.md), [%chisq](chisq.md), [%fisher](fisher.md), [%cmh](cmh.md), [%ancova](ancova.md), [%adjust](adjust.md).

Guides that use %anova: [Make a demographic table with tests](../how-to/demographic-table.md), [Run the examples of the reference](../how-to/run-the-examples.md).

## Proof

Checked against its known answers: numbers worked out independently in R and compared on SAS by the tests of the library (the tests are kept with the development of the library, not in this repository).

The examples of this page ran on SAS 9.4M9 on 2026-11-27, with a log free of ERROR and WARNING.

[Source of %anova](https://github.com/datastep-labs/sapling-sas/blob/main/macros/anova.sas)
