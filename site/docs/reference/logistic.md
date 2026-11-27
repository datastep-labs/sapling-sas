# %logistic

Returns the odds ratios of pairs of groups from a logistic regression, with their Wald confidence limits and p-values.

**Procedure:** PROC LOGISTIC (LSMEANS) · **Family:** [Compare groups with a model](index.md#models)

## Syntax

```sas
%logistic(
     data   =
   , where  =
   , var    =
   , event  = "Y"
   , by     =
   , within =
   , covars =
   , class  =
   , pairs  = all
   , order  =
   , level  = 0.95
   , stats  = or="XX.XX" lcl="XX.XX" ucl="XX.XX" pval="X.XXX"
   , label  =
   , out    =
   , debug  = no
 )
```

## Parameters

`data=`
:   The input data set, with USUBJID. *(required)*

`where=`
:   The records to use: a condition in parentheses, such as `where = (paramcd = 'RESP')`. *(optional)*

`var=`
:   The response: one variable with two values, numeric or character. *(required)*

`event=`
:   The value of `var=` that is the event, in quotes; for a number also in quotes (`event = "1"`). PROC LOGISTIC alone models the first value in sort order. *(optional, default `"Y"`)*

`by=`
:   The groups of the model: one character variable. *(required)*

`within=`
:   One model in each group of these variables, separated by blanks, such as the levels of a subgroup (`within = sex`). *(optional)*

`covars=`
:   The covariates: numeric variables separated by blanks (`covars = age`). *(optional)*

`class=`
:   The class factors besides the groups: variables separated by blanks (`class = sex`). *(optional)*

`pairs=`
:   The pairs of groups to compare. all: each later group against each earlier one, in the order of `order=` (or of the values). Or the pairs separated by #, each the group first and then the group it is compared with, a value with a blank or a hyphen in quotes: `pairs = "Drug" "Placebo" # "High" "Low"`. *(optional, default `all`)*

`order=`
:   The order of the groups: one numeric variable with one value per group (`order = trt01pn`). *(optional)*

`level=`
:   The confidence level of the limits: a number between 0 and 1. *(optional, default `0.95`)*

`stats=`
:   The statistics, in the order of the rows: each name with the pattern of its printed number, separated by blanks. The names are or, lcl, ucl and pval. A name without a pattern takes its default pattern (n="XX", mean="XX.X", pval="X.XXX" ...; see [%describe](describe.md)). *(optional, default `or="XX.XX" lcl="XX.XX" ucl="XX.XX" pval="X.XXX"`)*

`label=`
:   The label of the block in the table: a text in quotes. A block is the rows of one call in the table. *(optional)*

`out=`
:   The name of the result data set. *(required)*

`debug=`
:   yes: keep the work data sets _logistic_*. *(optional, default `no`)*
    Accepts: `yes`, `no`.

## Result

The data set of `out=`: the [result shape](../explanation/result-shape.md), one row per pair and statistic: the group in the `by=` variable, the group it is compared with in VERSUS, and the variables of `within=`. or is the odds of the event of `event=` in the group over the odds in VERSUS, adjusted for the covariates and the class factors (an odds ratio above 1: the event is more likely in the group), lcl and ucl its Wald confidence limits, pval its p-value. With pairs=all the group is the later one in the order of `order=`. GROUPS is the `by=` variable, VERSUS and the `within=` variables.

## Details

Use [%risk](risk.md) for a risk difference, relative risk or odds ratio from the 2 x 2 table of a pair, without a model. The model is PROC LOGISTIC of a response with two values: the probability of the event of `event=` on the groups, the class factors and the covariates, one record per subject (the first with a response). All pairs come from one fit.

!!! note "Good to know"

    The iterations go on until no parameter changes by more than 1E-10 (XCONV=). PROC LOGISTIC alone stops at a relative gradient of 1E-8. So the estimate is the maximum to the digits R gives: the odds ratio 7 of a 2 x 2 table is 7, where GCONV=1E-10 gave 6.9999907.

## Examples

The examples run on the [example data](../tutorial/index.md#the-example-data) after `examples/setup.sas`. The output under each call is the output of that run. All examples of the reference run as one program: [examples/reference.sas](https://github.com/datastep-labs/sapling-sas/blob/main/examples/reference.sas).

Gives the odds ratio of discontinuation for each pair, adjusted for age and sex.

```sas
%logistic(
     data   = adsl
   , var    = eosstt
   , event  = "DISCONTINUED"
   , by     = trt01a
   , covars = age
   , class  = sex
   , order  = trt01an
   , out    = eos_or
 )
```

```text
eos_or: 12 rows
TRT01A                VERSUS               GROUPS         BLOCK  STAT         VALUE  TEXT
Xanomeline High Dose  Placebo              TRT01A VERSUS         or    3.5771402807  3.58
Xanomeline High Dose  Placebo              TRT01A VERSUS         lcl   1.8361365787  1.84
Xanomeline High Dose  Placebo              TRT01A VERSUS         ucl   6.9689437792  6.97
Xanomeline High Dose  Placebo              TRT01A VERSUS         pval  0.0001797931  <0.001
Xanomeline High Dose  Xanomeline Low Dose  TRT01A VERSUS         or    0.6112659206  0.61
Xanomeline High Dose  Xanomeline Low Dose  TRT01A VERSUS         lcl   0.3137784513  0.31
Xanomeline High Dose  Xanomeline Low Dose  TRT01A VERSUS         ucl   1.1907956847  1.19
Xanomeline High Dose  Xanomeline Low Dose  TRT01A VERSUS         pval  0.1479745838  0.148
Xanomeline Low Dose   Placebo              TRT01A VERSUS         or    5.8520198165  5.85
Xanomeline Low Dose   Placebo              TRT01A VERSUS         lcl   3.0717911672  3.07
Xanomeline Low Dose   Placebo              TRT01A VERSUS         ucl   11.148588582  11.15
Xanomeline Low Dose   Placebo              TRT01A VERSUS         pval  7.7570593E-8  <0.001
```

Gives the odds ratio against Placebo for each sex: the rows carry SEX.

```sas
%logistic(
     data   = adsl
   , var    = eosstt
   , event  = "DISCONTINUED"
   , by     = trt01a
   , within = sex
   , pairs  = "Xanomeline High Dose" "Placebo"
            # "Xanomeline Low Dose"  "Placebo"
   , out    = eos_or_sex
 )
```

```text
eos_or_sex: the first 15 of 16 rows
TRT01A                VERSUS   SEX  GROUPS             BLOCK  STAT         VALUE   TEXT
Xanomeline High Dose  Placebo  F    TRT01A VERSUS SEX         or     3.028340081   3.03
Xanomeline High Dose  Placebo  F    TRT01A VERSUS SEX         lcl   1.2483932973   1.25
Xanomeline High Dose  Placebo  F    TRT01A VERSUS SEX         ucl   7.3461173381   7.35
Xanomeline High Dose  Placebo  F    TRT01A VERSUS SEX         pval  0.0142595202  0.014
Xanomeline High Dose  Placebo  M    TRT01A VERSUS SEX         or     4.380952381   4.38
Xanomeline High Dose  Placebo  M    TRT01A VERSUS SEX         lcl   1.5891752186   1.59
Xanomeline High Dose  Placebo  M    TRT01A VERSUS SEX         ucl   12.077172825  12.08
Xanomeline High Dose  Placebo  M    TRT01A VERSUS SEX         pval  0.0043000381  0.004
Xanomeline Low Dose   Placebo  F    TRT01A VERSUS SEX         or               4   4.00
Xanomeline Low Dose   Placebo  F    TRT01A VERSUS SEX         lcl   1.7948200154   1.79
Xanomeline Low Dose   Placebo  F    TRT01A VERSUS SEX         ucl   8.9145428858   8.91
Xanomeline Low Dose   Placebo  F    TRT01A VERSUS SEX         pval  0.0006977303  0.001
Xanomeline Low Dose   Placebo  M    TRT01A VERSUS SEX         or              11  11.00
Xanomeline Low Dose   Placebo  M    TRT01A VERSUS SEX         lcl   3.7062356935   3.71
Xanomeline Low Dose   Placebo  M    TRT01A VERSUS SEX         ucl   32.647680829  32.65
```

## Messages

The macro gives only the [messages every macro shares](index.md#messages-every-macro-shares).

## See also

Compare groups with a model: [%lsmeans](lsmeans.md), [%mmrm](mmrm.md), [%risk](risk.md), [%rateratio](rateratio.md).

Named on this page: [%describe](describe.md).

## Proof

Checked against its known answer (on a small data set, the numbers worked out independently in R); ran on SAS 9.4 M9, 2026-11-12.

The known answers and test cases are kept with the development of the library, not in this repository.

The examples of this page ran on SAS 9.4 M9 on 2026-11-27, with a log free of ERROR and WARNING.

[Source of %logistic](https://github.com/datastep-labs/sapling-sas/blob/main/macros/logistic.sas)
