# %cmh

Returns the p-value of the Cochran-Mantel-Haenszel test of the groups against the categories of a response, within strata.

**Procedure:** PROC FREQ (CMH) · **Family:** [Test the groups](index.md#tests)

## Syntax

```sas
%cmh(
     data      =
   , where     =
   , var       =
   , by        =
   , strata    =
   , within    =
   , statistic = general
   , stats     = pval="X.XXX"
   , label     =
   , out       =
   , debug     = no
 )
```

## Parameters

<a id="data"></a>`data=`
:   The input data set: the records, with USUBJID. *(required)*

<a id="where"></a>`where=`
:   The records to use: a condition in parentheses, such as `where = (avisit = 'Week 24')`. *(optional)*

<a id="var"></a>`var=`
:   The categories of the response: one variable; numeric for statistic=rowmean. *(required)*

<a id="by"></a>`by=`
:   The groups to compare: one variable. *(required)*

<a id="strata"></a>`strata=`
:   The stratification variables, separated by blanks (`strata = sitegr1`). When not given, the test has one stratum. *(optional)*

<a id="within"></a>`within=`
:   One test in each group of these variables, separated by blanks, such as a parameter and a visit (`within = paramcd avisit`). *(optional)*

<a id="statistic"></a>`statistic=`
:   The test: general (general association) or rowmean (the mean scores of the groups differ). *(optional, default `general`)*
    Accepts: `general`, `rowmean`.

<a id="stats"></a>`stats=`
:   The statistic pval and the pattern of its printed number, such as `stats = pval="X.XXXX"`. *(optional, default `pval="X.XXX"`)*

<a id="label"></a>`label=`
:   The label of the block in the table: a text in quotes. A block is the rows of one call in the table. *(optional)*

<a id="out"></a>`out=`
:   The name of the result data set. *(required)*

<a id="debug"></a>`debug=`
:   yes: keep the work data sets _cmh_*. *(optional, default `no`)*
    Accepts: `yes`, `no`.

## Result

The data set of `out=`: the [result shape](../explanation/result-shape.md): one row with STAT pval, or one row per group of `within=` with the variables of `within=`. GROUPS has the names of the `within=` variables. VALUE is missing where PROC FREQ makes no test.

## Details

Use [%chisq](chisq.md) for the same test without strata. Each subject counts once in each group, category and stratum. A record with a missing group, category or value of `within=` is not used. `statistic=` chooses the test:

- general: the test of general association
- rowmean: the test that the mean scores of the groups differ; the scores are the values of the numeric response (SCORES=TABLE)

## Examples

The examples run on the [example data](../tutorial/index.md#the-example-data) after `examples/setup.sas`. The output under each call is the output of that run. All examples of the reference run as one program: [examples/reference.sas](https://github.com/datastep-labs/sapling-sas/blob/main/examples/reference.sas).

<a id="ex-eos_cmh"></a>

Tests the status at the end of the study across the groups, stratified by sex: one p value.

```sas
%cmh(
     data   = adsl
   , var    = eosstt
   , by     = trt01a
   , strata = sex
   , label  = "Discontinued the study"
   , out    = eos_cmh
 )
```

```text
eos_cmh: 1 row
GROUPS  BLOCK                   STAT         VALUE  TEXT
        Discontinued the study  pval  8.4616214E-8  <0.001
```

<a id="ex-agegr_cmh"></a>

Uses the row mean score statistic for the ordered age groups: one p value.

```sas
%cmh(
     data      = adsl
   , var       = agegr1
   , by        = trt01a
   , statistic = rowmean
   , label     = "Age group"
   , out       = agegr_cmh
 )
```

```text
agegr_cmh: 1 row
GROUPS  BLOCK      STAT        VALUE   TEXT
        Age group  pval  0.224684028  0.225
```

## Messages

The macro gives only the [messages every macro shares](index.md#messages-every-macro-shares).

## See also

Test the groups: [%anova](anova.md), [%ttest](ttest.md), [%wilcoxon](wilcoxon.md), [%chisq](chisq.md), [%fisher](fisher.md), [%ancova](ancova.md), [%adjust](adjust.md).

## Proof

Checked against its known answer (on a small data set, the numbers worked out independently in R); ran on SAS 9.4 M9, 2026-11-12.

The known answers and test cases are kept with the development of the library, not in this repository.

The examples of this page ran on SAS 9.4 M9 on 2026-11-27, with a log free of ERROR and WARNING.

[Source of %cmh](https://github.com/datastep-labs/sapling-sas/blob/main/macros/cmh.sas)
