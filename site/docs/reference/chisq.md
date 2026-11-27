# %chisq

Returns the p-value of the Pearson chi-square test of the groups against the categories of a response.

**Procedure:** PROC FREQ (CHISQ, FISHER) · **Family:** [Test the groups](index.md#tests)

## Syntax

```sas
%chisq(
     data   =
   , where  =
   , var    =
   , by     =
   , within =
   , exact  = no
   , stats  = pval="X.XXX"
   , label  =
   , out    =
   , debug  = no
 )
```

## Parameters

`data=`
:   The input data set: the records, with USUBJID. *(required)*

`where=`
:   The records to use: a condition in parentheses, such as `where = (avisit = 'Week 24')`. *(optional)*

`var=`
:   The categories of the response: one variable, numeric or character. *(required)*

`by=`
:   The groups to compare: one variable. *(required)*

`within=`
:   One test in each group of these variables, separated by blanks, such as a parameter and a visit (`within = paramcd avisit`). *(optional)*

`exact=`
:   yes: Fisher's exact test of the same table instead of the chi-square test. *(optional, default `no`)*
    Accepts: `yes`, `no`.

`stats=`
:   The statistic pval and the pattern of its printed number, such as `stats = pval="X.XXXX"`. *(optional, default `pval="X.XXX"`)*

`label=`
:   The label of the block in the table: a text in quotes. A block is the rows of one call in the table. *(optional)*

`out=`
:   The name of the result data set. *(required)*

`debug=`
:   yes: keep the work data sets _chisq_*. *(optional, default `no`)*
    Accepts: `yes`, `no`.

## Result

The data set of `out=`: the [result shape](../explanation/result-shape.md): one row with STAT pval, or one row per group of `within=` with the variables of `within=`. GROUPS has the names of the `within=` variables. VALUE is missing where PROC FREQ makes no test (a table with one row or one column).

## Details

Use [%fisher](fisher.md) for subjects with a record against subjects without (an adverse event), and [%cmh](cmh.md) for a test within strata. The test has no continuity correction. Each subject counts once in each group and category. A record with a missing group, category or value of `within=` is not used. With exact=yes the macro gives Fisher's exact test of the same table.

## Examples

The examples run on the [example data](../tutorial/index.md#the-example-data) after `examples/setup.sas`. The output under each call is the output of that run. All examples of the reference run as one program: [examples/reference.sas](https://github.com/datastep-labs/sapling-sas/blob/main/examples/reference.sas).

Tests sex across the groups: one row, the p value of the chi square test.

```sas
%chisq(
     data  = adsl
   , var   = sex
   , by    = trt01a
   , label = "Sex"
   , out   = sex_chisq
 )
```

```text
sex_chisq: 1 row
GROUPS  BLOCK  STAT         VALUE   TEXT
        Sex    pval  0.2514896384  0.251
```

Runs the exact test of the normal range within each parameter: one p value per parameter.

```sas
%chisq(
     data   = adlb
   , where  = (avisit = 'Week 24')
   , var    = anrind
   , by     = trt01a
   , within = paramcd
   , exact  = yes
   , out    = nr_test
 )
```

```text
nr_test: 2 rows
PARAMCD  GROUPS   BLOCK  STAT         VALUE   TEXT
ALT      PARAMCD         pval   0.530391367  0.530
AST      PARAMCD         pval  0.8843208549  0.884
```

## Messages

The macro gives only the [messages every macro shares](index.md#messages-every-macro-shares).

## See also

Test the groups: [%anova](anova.md), [%ttest](ttest.md), [%wilcoxon](wilcoxon.md), [%fisher](fisher.md), [%cmh](cmh.md), [%ancova](ancova.md), [%adjust](adjust.md).

Guides that use %chisq: [Make a demographic table with tests](../how-to/demographic-table.md).

## Proof

Checked against its known answers: the chi-square test and the exact test (on a small data set, the numbers worked out independently in R); ran on SAS 9.4 M9, 2026-11-12.

The known answers and test cases are kept with the development of the library, not in this repository.

The examples of this page ran on SAS 9.4 M9 on 2026-11-27, with a log free of ERROR and WARNING.

[Source of %chisq](https://github.com/datastep-labs/sapling-sas/blob/main/macros/chisq.sas)
