# %risk

Returns the risk difference, relative risk or odds ratio of pairs of groups, with its confidence interval and p-value.

**Procedure:** PROC FREQ (RISKDIFF, RELRISK, CHISQ; COMMONRISKDIFF, CMH) · **Family:** [Compare groups with a model](index.md#models)

## Syntax

```sas
%risk(
     data    =
   , where   =
   , var     =
   , event   = "Y"
   , by      =
   , within  =
   , strata  =
   , pairs   = all
   , order   =
   , measure = rd
   , ci      = wald
   , level   = 0.95
   , stats   =
   , label   =
   , out     =
   , debug   = no
 )
```

## Parameters

`data=`
:   The input data set, with USUBJID: one record per subject, or per subject and term with `within=`. *(required)*

`where=`
:   The records to use: a condition in parentheses, such as `where = (saffl = 'Y')`. *(optional)*

`var=`
:   The response: one variable with two values, numeric or character. *(required)*

`event=`
:   The value of `var=` that is the event, in quotes (`event = "DISCONTINUED"`). *(optional, default `"Y"`)*

`by=`
:   The groups: one character variable. *(required)*

`within=`
:   One comparison in each group of these variables, separated by blanks, such as each term of an adverse event table with the flags of [%termflags](termflags.md) (`within = aebodsys aedecod`). *(optional)*

`strata=`
:   The strata of the Mantel-Haenszel risk difference: variables separated by blanks. Only with measure=rd. *(optional)*

`pairs=`
:   The pairs of groups to compare. all: each later group against each earlier one, in the order of `order=` (or of the values). Or the pairs separated by #, each the group first and then the group it is compared with, a value with a blank or a hyphen in quotes: `pairs = "Drug" "Placebo" # "High" "Low"`. *(optional, default `all`)*

`order=`
:   The order of the groups: one numeric variable with one value per group (`order = trt01an`). *(optional)*

`measure=`
:   The estimate of the group against the group it is compared with: rd, the risk difference, a difference of two proportions between -1 and 1 (0.25 is 25 percentage points), not of percents; rr, the relative risk, the ratio of the two risks; or or, the odds ratio, the ratio of the two odds. A ratio has no unit. *(optional, default `rd`)*
    Accepts: `rd`, `rr`, `or`.

`ci=`
:   The interval of a risk difference: wald, newcombe, miettinen-nurminen (CL=MN) or agresti-caffo (CL=AC). With `strata=` the interval is always mh. *(optional, default `wald`)*

`level=`
:   The confidence level of the interval: a number between 0 and 1. *(optional, default `0.95`)*

`stats=`
:   The statistics, in the order of the rows: each name with the pattern of its printed number, separated by blanks. When not given: rd="X.XXX" lcl="X.XXX" ucl="X.XXX" pval="X.XXX"; for measure=rr or or, rr="XX.XX" or or="XX.XX" with lcl="XX.XX" ucl="XX.XX" pval="X.XXX". A name without a pattern takes its default pattern (n="XX", mean="XX.X", pval="X.XXX" ...; see [%describe](describe.md)). *(optional)*

`label=`
:   The label of the block in the table: a text in quotes. A block is the rows of one call in the table. *(optional)*

`out=`
:   The name of the result data set. *(required)*

`debug=`
:   yes: keep the work data sets _risk_*. *(optional, default `no`)*
    Accepts: `yes`, `no`.

## Result

The data set of `out=`: the [result shape](../explanation/result-shape.md), one row per pair and statistic: the group in the `by=` variable, the group it is compared with in VERSUS, and the variables of `within=`. The risk of a group is its subjects with the event of `event=` over its subjects in the records used. With measure=rd, rd is the risk of the group minus the risk of VERSUS, a difference of two proportions (0.25: 25 percentage points more in the group); with `strata=`, the Mantel-Haenszel estimate of that difference. With measure=rr, rr is the risk of the group over the risk of VERSUS; with measure=or, or is the odds of the event in the group over the odds in VERSUS. lcl and ucl are the limits of the estimate, pval its p-value. With pairs=all the group is the later one in the order of `order=`. GROUPS is the `by=` variable, VERSUS and the `within=` variables.

## Details

Use [%logistic](logistic.md) for an odds ratio adjusted for covariates in a model, and [%fisher](fisher.md) for only the p-value of an adverse event. For each pair the macro makes the 2 x 2 table of the two groups (the group first) by the event of `event=` against the rest, one record per subject, with PROC FREQ. `measure=` gives the estimate:

- rd: the risk difference, with the interval of `ci=`
- rr: the relative risk, with the Wald interval of its logarithm
- or: the odds ratio, with the Wald interval of its logarithm

The p-value is that of Pearson's chi-square test without continuity correction. With `strata=` the macro gives the Mantel-Haenszel risk difference (COMMONRISKDIFF, CL=MH) and the p-value of the CMH test.

## Examples

The examples run on the [example data](../tutorial/index.md#the-example-data) after `examples/setup.sas`. The output under each call is the output of that run. They also read `ae_flags` (made by the [example of %termflags](termflags.md#examples)). All examples of the reference run as one program: [examples/reference.sas](https://github.com/datastep-labs/sapling-sas/blob/main/examples/reference.sas).

Gives the risk difference of discontinuation of each pair, its Newcombe limits and p value.

```sas
%risk(
     data  = adsl
   , var   = eosstt
   , event = "DISCONTINUED"
   , by    = trt01a
   , order = trt01an
   , ci    = newcombe
   , out   = eos_rd
 )
```

```text
eos_rd: 12 rows
TRT01A                VERSUS               GROUPS         BLOCK  STAT         VALUE  TEXT
Xanomeline Low Dose   Placebo              TRT01A VERSUS         rd     0.414001938  0.414
Xanomeline Low Dose   Placebo              TRT01A VERSUS         lcl   0.2721357726  0.272
Xanomeline Low Dose   Placebo              TRT01A VERSUS         ucl    0.532469979  0.532
Xanomeline Low Dose   Placebo              TRT01A VERSUS         pval  2.1630148E-8  <0.001
Xanomeline High Dose  Placebo              TRT01A VERSUS         rd    0.2994186047  0.299
Xanomeline High Dose  Placebo              TRT01A VERSUS         lcl   0.1435882663  0.144
Xanomeline High Dose  Placebo              TRT01A VERSUS         ucl   0.4358737163  0.436
Xanomeline High Dose  Placebo              TRT01A VERSUS         pval  0.0001701248  <0.001
Xanomeline High Dose  Xanomeline Low Dose  TRT01A VERSUS         rd    -0.114583333  -0.115
Xanomeline High Dose  Xanomeline Low Dose  TRT01A VERSUS         lcl   -0.253571688  -0.254
Xanomeline High Dose  Xanomeline Low Dose  TRT01A VERSUS         ucl   0.0259371208  0.026
Xanomeline High Dose  Xanomeline Low Dose  TRT01A VERSUS         pval  0.1118759331  0.112
```

Gives the risk difference of each flagged term against Placebo, within its class and term.

```sas
%risk(
     data   = work.ae_flags
   , var    = flag
   , event  = "Y"
   , by     = trt01a
   , within = aebodsys aedecod
   , pairs  = "Xanomeline High Dose" "Placebo"
            # "Xanomeline Low Dose"  "Placebo"
   , ci     = newcombe
   , out    = ae_rd
 )
```

```text
ae_rd: the first 15 of 188 rows
TRT01A                VERSUS   AEBODSYS                    AEDECOD                GROUPS                          BLOCK  STAT         VALUE    TEXT
Xanomeline High Dose  Placebo  CARDIAC DISORDERS           MYOCARDIAL INFARCTION  TRT01A VERSUS AEBODSYS AEDECOD         rd    0.0090439276   0.009
Xanomeline High Dose  Placebo  CARDIAC DISORDERS           MYOCARDIAL INFARCTION  TRT01A VERSUS AEBODSYS AEDECOD         lcl    -0.06602471  -0.066
Xanomeline High Dose  Placebo  CARDIAC DISORDERS           MYOCARDIAL INFARCTION  TRT01A VERSUS AEBODSYS AEDECOD         ucl   0.0927307778   0.093
Xanomeline High Dose  Placebo  CARDIAC DISORDERS           MYOCARDIAL INFARCTION  TRT01A VERSUS AEBODSYS AEDECOD         pval  0.7962276725   0.796
Xanomeline High Dose  Placebo  CARDIAC DISORDERS           SINUS BRADYCARDIA      TRT01A VERSUS AEBODSYS AEDECOD         rd    0.0878552972   0.088
Xanomeline High Dose  Placebo  CARDIAC DISORDERS           SINUS BRADYCARDIA      TRT01A VERSUS AEBODSYS AEDECOD         lcl   0.0090725886   0.009
Xanomeline High Dose  Placebo  CARDIAC DISORDERS           SINUS BRADYCARDIA      TRT01A VERSUS AEBODSYS AEDECOD         ucl   0.1824866856   0.182
Xanomeline High Dose  Placebo  CARDIAC DISORDERS           SINUS BRADYCARDIA      TRT01A VERSUS AEBODSYS AEDECOD         pval  0.0238947499   0.024
Xanomeline High Dose  Placebo  GASTROINTESTINAL DISORDERS  DIARRHOEA              TRT01A VERSUS AEBODSYS AEDECOD         rd    -0.062984496  -0.063
Xanomeline High Dose  Placebo  GASTROINTESTINAL DISORDERS  DIARRHOEA              TRT01A VERSUS AEBODSYS AEDECOD         lcl   -0.149837456  -0.150
Xanomeline High Dose  Placebo  GASTROINTESTINAL DISORDERS  DIARRHOEA              TRT01A VERSUS AEBODSYS AEDECOD         ucl   0.0254081002   0.025
Xanomeline High Dose  Placebo  GASTROINTESTINAL DISORDERS  DIARRHOEA              TRT01A VERSUS AEBODSYS AEDECOD         pval  0.1366535984   0.137
Xanomeline High Dose  Placebo  GASTROINTESTINAL DISORDERS  NAUSEA                 TRT01A VERSUS AEBODSYS AEDECOD         rd    0.0484496124   0.048
Xanomeline High Dose  Placebo  GASTROINTESTINAL DISORDERS  NAUSEA                 TRT01A VERSUS AEBODSYS AEDECOD         lcl   -0.028504151  -0.029
Xanomeline High Dose  Placebo  GASTROINTESTINAL DISORDERS  NAUSEA                 TRT01A VERSUS AEBODSYS AEDECOD         ucl   0.1382228882   0.138
```

Asks for the relative risk with measure=rr: the rows of STAT rr hold the ratio of the two risks.

```sas
%risk(
     data    = adsl
   , var     = eosstt
   , event   = "DISCONTINUED"
   , by      = trt01a
   , order   = trt01an
   , measure = rr
   , out     = eos_rr
 )
```

```text
eos_rr: 12 rows
TRT01A                VERSUS               GROUPS         BLOCK  STAT         VALUE  TEXT
Xanomeline Low Dose   Placebo              TRT01A VERSUS         rr     2.271577381  2.27
Xanomeline Low Dose   Placebo              TRT01A VERSUS         lcl   1.6387804864  1.64
Xanomeline Low Dose   Placebo              TRT01A VERSUS         ucl   3.1487217724  3.15
Xanomeline Low Dose   Placebo              TRT01A VERSUS         pval  2.1630148E-8  <0.001
Xanomeline High Dose  Placebo              TRT01A VERSUS         rr    1.9196428571  1.92
Xanomeline High Dose  Placebo              TRT01A VERSUS         lcl    1.348831061  1.35
Xanomeline High Dose  Placebo              TRT01A VERSUS         ucl   2.7320164886  2.73
Xanomeline High Dose  Placebo              TRT01A VERSUS         pval  0.0001701248  <0.001
Xanomeline High Dose  Xanomeline Low Dose  TRT01A VERSUS         rr    0.8450704225  0.85
Xanomeline High Dose  Xanomeline Low Dose  TRT01A VERSUS         lcl   0.6817794151  0.68
Xanomeline High Dose  Xanomeline Low Dose  TRT01A VERSUS         ucl   1.0474707849  1.05
Xanomeline High Dose  Xanomeline Low Dose  TRT01A VERSUS         pval  0.1118759331  0.112
```

Stratifies by sex: the risk difference is the Mantel Haenszel estimate over the strata.

```sas
%risk(
     data   = adsl
   , var    = eosstt
   , event  = "DISCONTINUED"
   , by     = trt01a
   , strata = sex
   , order  = trt01an
   , out    = eos_rd_mh
 )
```

```text
eos_rd_mh: 12 rows
TRT01A                VERSUS               GROUPS         BLOCK  STAT         VALUE  TEXT
Xanomeline Low Dose   Placebo              TRT01A VERSUS         rd    0.4130789257  0.413
Xanomeline Low Dose   Placebo              TRT01A VERSUS         lcl   0.2797269668  0.280
Xanomeline Low Dose   Placebo              TRT01A VERSUS         ucl   0.5464308845  0.546
Xanomeline Low Dose   Placebo              TRT01A VERSUS         pval  2.7920645E-8  <0.001
Xanomeline High Dose  Placebo              TRT01A VERSUS         rd    0.3057674317  0.306
Xanomeline High Dose  Placebo              TRT01A VERSUS         lcl   0.1558017179  0.156
Xanomeline High Dose  Placebo              TRT01A VERSUS         ucl   0.4557331454  0.456
Xanomeline High Dose  Placebo              TRT01A VERSUS         pval  0.0001552343  <0.001
Xanomeline High Dose  Xanomeline Low Dose  TRT01A VERSUS         rd    -0.119924655  -0.120
Xanomeline High Dose  Xanomeline Low Dose  TRT01A VERSUS         lcl    -0.26218604  -0.262
Xanomeline High Dose  Xanomeline Low Dose  TRT01A VERSUS         ucl   0.0223367309  0.022
Xanomeline High Dose  Xanomeline Low Dose  TRT01A VERSUS         pval  0.0986766742  0.099
```

## Messages

A wrong call writes the message and its fix to the log and stops. The macro also gives the [messages every macro shares](index.md#messages-every-macro-shares).

| Message | Fix |
|---|---|
| ci=&lt;ci&gt; is not an interval here | give ci= wald, newcombe, miettinen-nurminen, agresti-caffo, mh. |
| strata=&lt;strata&gt; is taken by the risk difference only | give measure=rd, or no strata=. |
| pairs= names the group "&lt;group&gt;", and no record has it. | give pairs= the values of &lt;by&gt; as the data have them. |

## See also

Compare groups with a model: [%lsmeans](lsmeans.md), [%mmrm](mmrm.md), [%logistic](logistic.md), [%rateratio](rateratio.md).

Named on this page: [%termflags](termflags.md), [%describe](describe.md), [%fisher](fisher.md).

## Proof

Checked against its known answers: the risk difference, the relative risk, the odds ratio, and the risk difference of each term of an adverse event table (on a small data set, the numbers worked out independently in R); ran on SAS 9.4 M9, 2026-11-12.

The known answers and test cases are kept with the development of the library, not in this repository.

The examples of this page ran on SAS 9.4 M9 on 2026-11-27, with a log free of ERROR and WARNING.

[Source of %risk](https://github.com/datastep-labs/sapling-sas/blob/main/macros/risk.sas)
