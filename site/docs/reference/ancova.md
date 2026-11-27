# %ancova

Returns the Type III p-value of a numeric term in a linear model, such as a test of dose response.

**Procedure:** PROC GLM · **Family:** [Test the groups](index.md#tests)

## Syntax

```sas
%ancova(
     data   =
   , where  =
   , var    =
   , covars =
   , class  =
   , test   =
   , level  = 0.95
   , stats  = pval="X.XXX"
   , label  =
   , out    =
   , debug  = no
 )
```

## Parameters

`data=`
:   The input data set, with USUBJID. *(required)*

`where=`
:   The records to use: a condition in parentheses, such as `where = (paramcd = 'SYSBP' AND avisit = 'Week 12')`. *(optional)*

`var=`
:   The response: one numeric variable. *(required)*

`covars=`
:   The covariates: numeric variables separated by blanks (`covars = base`). *(optional)*

`class=`
:   The class factors: variables separated by blanks (`class = sex`). *(optional)*

`test=`
:   The tested term: one numeric variable, such as a dose or the number of a treatment (`test = trt01pn`). *(required)*

`level=`
:   The confidence level of the limits: a number between 0 and 1. *(optional, default `0.95`)*

`stats=`
:   The statistics, in the order of the rows: each name with the pattern of its printed number, separated by blanks. The names are pval, estimate, se, lcl and ucl. A name without a pattern takes its default pattern (n="XX", mean="XX.X", pval="X.XXX" ...; see [%describe](describe.md)). *(optional, default `pval="X.XXX"`)*

`label=`
:   The label of the block in the table: a text in quotes. A block is the rows of one call in the table. *(optional)*

`out=`
:   The name of the result data set. *(required)*

`debug=`
:   yes: keep the work data sets _ancova_*. *(optional, default `no`)*
    Accepts: `yes`, `no`.

## Result

The data set of `out=`: the [result shape](../explanation/result-shape.md): one row per statistic, of all subjects together (GROUPS is blank). STAT is pval, estimate, se, lcl or ucl.

## Details

Use [%lsmeans](lsmeans.md) for the differences between pairs of groups, and [%mmrm](mmrm.md) for a model of repeated visits. The model is PROC GLM: the class factors, the covariates and the tested term, one record per subject (the first with a value; when `where=` leaves a second record of a subject, the log has a NOTE with their number). Give a `where=` that leaves one record per subject, such as one parameter at one visit with `anl01fl = 'Y'`; otherwise each subject has the first of its records in the order of `data=`, whichever it is. The coefficient of the term, its standard error and its confidence limits come when `stats=` asks for them.

## Examples

The examples run on the [example data](../tutorial/index.md#the-example-data) after `examples/setup.sas`. The output under each call is the output of that run.

Tests a linear dose response of the change at Week 12, adjusted for baseline: one p value.

```sas
%ancova(
     data   = advs
   , where  = (paramcd = 'SYSBP' AND avisit = 'Week 12' AND anl01fl = 'Y')
   , var    = chg
   , covars = base
   , test   = trt01pn
   , label  = "Dose response"
   , out    = sbp_dose
 )
```

```text
sbp_dose: 1 row
GROUPS  BLOCK          STAT         VALUE   TEXT
        Dose response  pval  0.0682011221  0.068
```

## Messages

The macro gives only the [messages every macro shares](index.md#messages-every-macro-shares).

## See also

Test the groups: [%anova](anova.md), [%ttest](ttest.md), [%wilcoxon](wilcoxon.md), [%chisq](chisq.md), [%fisher](fisher.md), [%cmh](cmh.md), [%adjust](adjust.md).

Named on this page: [%describe](describe.md), [%lsmeans](lsmeans.md), [%mmrm](mmrm.md).

Guides that use %ancova: [Make an efficacy table with an ANCOVA](../how-to/efficacy-table.md), [Run the examples of the reference](../how-to/run-the-examples.md).

## Proof

Checked against its known answers: numbers worked out independently in R and compared on SAS by the tests of the library (the tests are kept with the development of the library, not in this repository).

The examples of this page ran on SAS 9.4M9 on 2026-11-27, with a log free of ERROR and WARNING.

Used in the proof against pharmaverse: [t14_3_01](https://github.com/datastep-labs/sapling-sas/blob/main/proof/pilot1/programs/t14_3_01.sas) (R Submission Pilot 1). See [what the proof shows](../explanation/proof.md).

[Source of %ancova](https://github.com/datastep-labs/sapling-sas/blob/main/macros/ancova.sas)
