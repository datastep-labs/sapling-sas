# %rateratio

Returns the rate ratios of pairs of groups from a Poisson or negative binomial model, with confidence limits and p-values.

**Procedure:** PROC GENMOD (LSMEANS) · **Family:** [Compare groups with a model](index.md#models)

## Syntax

```sas
%rateratio(
     data     =
   , where    =
   , var      =
   , by       =
   , exposure =
   , within   =
   , covars   =
   , class    =
   , dist     = poisson
   , pairs    = all
   , order    =
   , level    = 0.95
   , stats    = irr="XX.XX" lcl="XX.XX" ucl="XX.XX" pval="X.XXX"
   , label    =
   , out      =
   , debug    = no
 )
```

## Parameters

`data=`
:   The input data set, with USUBJID: one record per subject. *(required)*

`where=`
:   The records to use: a condition in parentheses, such as `where = (trtdurd &gt; 0)`. *(optional)*

`var=`
:   The count: one numeric variable (`var = teaecnt`). *(required)*

`by=`
:   The groups of the model: one character variable. *(required)*

`exposure=`
:   The exposure of each subject: a numeric variable, or an expression of variables of `data=`, such as `exposure = trtdurd` / 365.25 for years. A subject with an exposure of 0 or less is not used in the model. *(required)*

`within=`
:   One model in each group of these variables, separated by blanks, such as the levels of a subgroup (`within = sex`). *(optional)*

`covars=`
:   The covariates: numeric variables separated by blanks (`covars = age`). *(optional)*

`class=`
:   The class factors besides the groups: variables separated by blanks (`class = sex`). *(optional)*

`dist=`
:   The distribution of the count: poisson, or negbin (also nb) for the negative binomial. *(optional, default `poisson`)*
    Accepts: `poisson`, `negbin`, `nb`.

`pairs=`
:   The pairs of groups to compare. all: each later group against each earlier one, in the order of `order=` (or of the values). Or the pairs separated by #, each the group first and then the group it is compared with, a value with a blank or a hyphen in quotes: `pairs = "Drug" "Placebo" # "High" "Low"`. *(optional, default `all`)*

`order=`
:   The order of the groups: one numeric variable with one value per group (`order = trt01an`). *(optional)*

`level=`
:   The confidence level of the limits: a number between 0 and 1. *(optional, default `0.95`)*

`stats=`
:   The statistics, in the order of the rows: each name with the pattern of its printed number, separated by blanks. The names are irr, lcl, ucl and pval. A name without a pattern takes its default pattern (n="XX", mean="XX.X", pval="X.XXX" ...; see [%describe](describe.md)). *(optional, default `irr="XX.XX" lcl="XX.XX" ucl="XX.XX" pval="X.XXX"`)*

`label=`
:   The label of the block in the table: a text in quotes. A block is the rows of one call in the table. *(optional)*

`out=`
:   The name of the result data set. *(required)*

`debug=`
:   yes: keep the work data sets _rateratio_*. *(optional, default `no`)*
    Accepts: `yes`, `no`.

## Result

The data set of `out=`: the [result shape](../explanation/result-shape.md), one row per pair and statistic: the group in the `by=` variable, the group it is compared with in VERSUS, and the variables of `within=`. irr is the rate of the count per unit of exposure in the group over that rate in VERSUS, adjusted for the covariates and the class factors (a rate ratio above 1: more events per unit of exposure in the group), lcl and ucl its confidence limits, pval its p-value. With pairs=all the group is the later one in the order of `order=`. GROUPS is the `by=` variable, VERSUS and the `within=` variables.

## Details

Use [%rate](rate.md) for the rate of each group without a model. The model is PROC GENMOD of a count with the logarithm of the exposure as the offset, on the groups, the covariates and the class factors, one record per subject (the first with a count). The dispersion k of a negative binomial model is estimated by maximum likelihood. All pairs come from one fit.

!!! note "Good to know"

    The standard errors of a negative binomial model are those of PROC GENMOD: the observed information of the coefficients and the dispersion together. The R twin of this macro (rateratio() of the R package sapling, a separate product) computes the same.

## Examples

The examples run on the [example data](../tutorial/index.md#the-example-data) after `examples/setup.sas`. The output under each call is the output of that run. All examples of the reference run as one program: [examples/reference.sas](https://github.com/datastep-labs/sapling-sas/blob/main/examples/reference.sas).

Compares the event counts in a negative binomial model: STAT irr is the rate ratio.

```sas
%rateratio(
     data     = adsl
   , where    = (trtdurd > 0)
   , var      = teaecnt
   , by       = trt01a
   , exposure = trtdurd / 365.25
   , dist     = negbin
   , order    = trt01an
   , out      = ae_rr
 )
```

```text
ae_rr: 12 rows
TRT01A                VERSUS               GROUPS         BLOCK  STAT         VALUE  TEXT
Xanomeline High Dose  Placebo              TRT01A VERSUS         irr   2.8601040327  2.86
Xanomeline High Dose  Placebo              TRT01A VERSUS         lcl   2.0274811362  2.03
Xanomeline High Dose  Placebo              TRT01A VERSUS         ucl   4.0346590317  4.03
Xanomeline High Dose  Placebo              TRT01A VERSUS         pval  2.1476518E-9  <0.001
Xanomeline High Dose  Xanomeline Low Dose  TRT01A VERSUS         irr   0.7532323329  0.75
Xanomeline High Dose  Xanomeline Low Dose  TRT01A VERSUS         lcl   0.5337935161  0.53
Xanomeline High Dose  Xanomeline Low Dose  TRT01A VERSUS         ucl   1.0628809272  1.06
Xanomeline High Dose  Xanomeline Low Dose  TRT01A VERSUS         pval  0.1067713297  0.107
Xanomeline Low Dose   Placebo              TRT01A VERSUS         irr   3.7971073567  3.80
Xanomeline Low Dose   Placebo              TRT01A VERSUS         lcl   2.6965090769  2.70
Xanomeline Low Dose   Placebo              TRT01A VERSUS         ucl   5.3469222119  5.35
Xanomeline Low Dose   Placebo              TRT01A VERSUS         pval  2.170719E-14  <0.001
```

## Messages

A wrong call writes the message and its fix to the log and stops. The macro also gives the [messages every macro shares](index.md#messages-every-macro-shares).

| Message | Fix |
|---|---|
| exposure=&lt;exptext&gt; has &lt;badexp&gt;, not a variable of &lt;data&gt; | give exposure= variables of data=, or an expression. |

## See also

Compare groups with a model: [%lsmeans](lsmeans.md), [%mmrm](mmrm.md), [%logistic](logistic.md), [%risk](risk.md).

Named on this page: [%describe](describe.md), [%rate](rate.md).

## Proof

Checked against its known answers: a Poisson and a negative binomial model (on a small data set, the numbers worked out independently in R); ran on SAS 9.4 M9, 2026-11-12.

The known answers and test cases are kept with the development of the library, not in this repository.

The examples of this page ran on SAS 9.4 M9 on 2026-11-27, with a log free of ERROR and WARNING.

[Source of %rateratio](https://github.com/datastep-labs/sapling-sas/blob/main/macros/rateratio.sas)
