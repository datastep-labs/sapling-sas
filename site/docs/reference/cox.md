# %cox

Returns the hazard ratio of pairs of groups from a Cox proportional hazards model, with its confidence limits and p-value.

**Procedure:** PROC PHREG (LSMEANS); PROC LIFETEST for pvalue=logrank · **Family:** [Time to an event](index.md#time)

## Syntax

```sas
%cox(
     data   =
   , where  =
   , var    =
   , by     =
   , cnsr   = CNSR
   , within =
   , covars =
   , class  =
   , strata =
   , pairs  = all
   , order  =
   , ties   = efron
   , pvalue = wald
   , level  = 0.95
   , stats  = hr="XX.XX" lcl="XX.XX" ucl="XX.XX" pval="X.XXX"
   , label  =
   , out    =
   , debug  = no
 )
```

## Parameters

`data=`
:   The input data set: one record per subject, with USUBJID, the time and the censoring variable. *(required)*

`where=`
:   The records to use: a condition in parentheses, such as where = (`paramcd = 'TTDE'`). *(optional)*

`var=`
:   The time: one numeric variable, such as aval. *(required)*

`by=`
:   The groups of the model: one character variable. *(required)*

`cnsr=`
:   The censoring variable: one numeric variable, 0 for an event and a positive value for a censoring (the ADaM CNSR: 1, 2 ... name the reason). A missing or negative value on a record used stops the macro with an ERROR. *(optional, default `CNSR`)*

`within=`
:   One model in each group of these variables, separated by blanks (`within = sex` for the levels of a subgroup). A record with a missing value of one of them is not used. *(optional)*

`covars=`
:   The numeric covariates of the model, separated by blanks (`covars = age`). *(optional)*

`class=`
:   The class factors of the model, separated by blanks (`class = sitegr1`). *(optional)*

`strata=`
:   The strata of the model, separated by blanks (`strata = sitegr1`). When not given, the model has no strata. *(optional)*

`pairs=`
:   The pairs of groups to compare. all: each later group against each earlier one, in the order of `order=` (or of the values). Or a list of pairs separated by #: the group first, then the group it is compared with, each value in quotes ("Drug" "Placebo" # "High" "Low"). The old form "A"-"B" of version 1.0 is still read. *(optional, default `all`)*

`order=`
:   The order of the groups: one numeric variable with one value per group (`order = trt01pn`). *(optional)*

`ties=`
:   The method for tied times: efron, breslow, or exact (TIES=DISCRETE of PROC PHREG, which coxph of R calls exact). discrete is accepted as another name of exact. *(optional, default `efron`)*
    Accepts: `efron`, `breslow`, `exact`, `discrete`.

`pvalue=`
:   The p-value of each pair: wald (the Wald test of the pair in the model) or logrank (the log-rank test of the two groups of the pair, in the strata). logrank is not possible with `within=`. *(optional, default `wald`)*
    Accepts: `wald`, `logrank`.

`level=`
:   The confidence level: a number between 0 and 1. *(optional, default `0.95`)*

`stats=`
:   The statistics, in the order of the rows: each name with its pattern of the printed number, separated by blanks. The names are hr, lcl, ucl and pval. A name without a pattern takes its default pattern (n="XX", mean="XX.X", pval="X.XXX" ...; see [%describe](describe.md)). *(optional, default `hr="XX.XX" lcl="XX.XX" ucl="XX.XX" pval="X.XXX"`)*

`label=`
:   The label of the block in the table: a text in quotes. A block is the rows of one call in the table. *(optional)*

`out=`
:   The name of the result data set. *(required)*

`debug=`
:   yes: keep the work data sets _cox_*. *(optional, default `no`)*
    Accepts: `yes`, `no`.

## Result

The data set of `out=`: the [result shape](../explanation/result-shape.md), one row per pair and statistic: the BY variable (the group), VERSUS (the group it is compared with), the variables of `within=`, GROUPS, BLOCK, STAT, VALUE and TEXT. GROUPS is the name of the BY variable, VERSUS and the names of `within=`.

## Details

Use [%logrank](logrank.md) for the test of all groups together without a model, and [%interaction_phreg](interaction_phreg.md) for the test of a treatment-by-subgroup interaction. The model has the groups, the covariates and the class factors. With `strata=`, each combination of the values of the strata variables is a stratum with its own baseline hazard. All pairs come from one fit: hr is the hazard ratio, lcl and ucl are its Wald confidence limits, and pval is the Wald p-value of the pair. With pvalue=logrank, pval is the log-rank test of the two groups of the pair, in the same strata (PROC LIFETEST); the hazard ratio and its limits stay those of the model. The model uses one record per subject (in each group of `within=`). CNSR 0 is an event and any positive value is a censoring, as in ADaM, where the value names the reason of the censoring: a CNSR of 2 is censored as 1 is. A record used with a missing or negative CNSR stops the macro with an ERROR.

!!! note "Good to know"

    The ties of the library are Efron's, as in coxph of R; PROC PHREG by itself uses Breslow's.

## Examples

The examples run on the [example data](../tutorial/index.md#the-example-data) after `examples/setup.sas`. The output under each call is the output of that run. They also read `adttde` (made by the [example of %tte](tte.md#examples)).

```sas
%cox(
     data   = adttde
   , var    = aval
   , by     = trt01a
   , strata = sex
   , order  = trt01an
   , out    = ttde_hr
 )
```

```text
ttde_hr: 12 rows
TRT01A                VERSUS               GROUPS         BLOCK  STAT         VALUE  TEXT
Xanomeline High Dose  Placebo              TRT01A VERSUS         hr    3.7448744721  3.74
Xanomeline High Dose  Placebo              TRT01A VERSUS         lcl   2.1632083763  2.16
Xanomeline High Dose  Placebo              TRT01A VERSUS         ucl   6.4830022692  6.48
Xanomeline High Dose  Placebo              TRT01A VERSUS         pval  2.4097253E-6  <0.001
Xanomeline High Dose  Xanomeline Low Dose  TRT01A VERSUS         hr    1.1572116754  1.16
Xanomeline High Dose  Xanomeline Low Dose  TRT01A VERSUS         lcl   0.7410470208  0.74
Xanomeline High Dose  Xanomeline Low Dose  TRT01A VERSUS         ucl   1.8070902712  1.81
Xanomeline High Dose  Xanomeline Low Dose  TRT01A VERSUS         pval  0.5208169088  0.521
Xanomeline Low Dose   Placebo              TRT01A VERSUS         hr    3.2361188118  3.24
Xanomeline Low Dose   Placebo              TRT01A VERSUS         lcl   1.8648836677  1.86
Xanomeline Low Dose   Placebo              TRT01A VERSUS         ucl   5.6156129982  5.62
Xanomeline Low Dose   Placebo              TRT01A VERSUS         pval   0.000029663  <0.001
```

```sas
%cox(
     data   = adttde
   , var    = aval
   , by     = trt01a
   , within = sex
   , pairs  = "Xanomeline High Dose" "Placebo"
            # "Xanomeline Low Dose"  "Placebo"
   , out    = hr_sex
 )
```

```text
hr_sex: the first 15 of 16 rows
TRT01A                VERSUS   SEX  GROUPS             BLOCK  STAT         VALUE  TEXT
Xanomeline High Dose  Placebo  F    TRT01A VERSUS SEX         hr    1.7908593572  1.79
Xanomeline High Dose  Placebo  F    TRT01A VERSUS SEX         lcl   0.8297250323  0.83
Xanomeline High Dose  Placebo  F    TRT01A VERSUS SEX         ucl   3.8653494983  3.87
Xanomeline High Dose  Placebo  F    TRT01A VERSUS SEX         pval  0.1376926451  0.138
Xanomeline High Dose  Placebo  M    TRT01A VERSUS SEX         hr    7.8320389304  7.83
Xanomeline High Dose  Placebo  M    TRT01A VERSUS SEX         lcl    3.332064388  3.33
Xanomeline High Dose  Placebo  M    TRT01A VERSUS SEX         ucl   18.409258245  18.41
Xanomeline High Dose  Placebo  M    TRT01A VERSUS SEX         pval  2.3559352E-6  <0.001
Xanomeline Low Dose   Placebo  F    TRT01A VERSUS SEX         hr    2.1688272277  2.17
Xanomeline Low Dose   Placebo  F    TRT01A VERSUS SEX         lcl   1.0829395982  1.08
Xanomeline Low Dose   Placebo  F    TRT01A VERSUS SEX         ucl    4.343558543  4.34
Xanomeline Low Dose   Placebo  F    TRT01A VERSUS SEX         pval  0.0289016047  0.029
Xanomeline Low Dose   Placebo  M    TRT01A VERSUS SEX         hr    5.3793520332  5.38
Xanomeline Low Dose   Placebo  M    TRT01A VERSUS SEX         lcl   2.1988056105  2.20
Xanomeline Low Dose   Placebo  M    TRT01A VERSUS SEX         ucl   13.160521402  13.16
```

```sas
%cox(
     data   = adttde
   , var    = aval
   , by     = trt01a
   , within = agegr1
   , pairs  = "Xanomeline High Dose" "Placebo"
            # "Xanomeline Low Dose"  "Placebo"
   , out    = hr_age
 )
```

```text
hr_age: the first 15 of 16 rows
TRT01A                VERSUS   AGEGR1  GROUPS                BLOCK  STAT         VALUE  TEXT
Xanomeline High Dose  Placebo  18-64   TRT01A VERSUS AGEGR1         hr    4.4645904226  4.46
Xanomeline High Dose  Placebo  18-64   TRT01A VERSUS AGEGR1         lcl   1.0914069405  1.09
Xanomeline High Dose  Placebo  18-64   TRT01A VERSUS AGEGR1         ucl   18.263185711  18.26
Xanomeline High Dose  Placebo  18-64   TRT01A VERSUS AGEGR1         pval   0.037373599  0.037
Xanomeline High Dose  Placebo  >64     TRT01A VERSUS AGEGR1         hr     3.442156042  3.44
Xanomeline High Dose  Placebo  >64     TRT01A VERSUS AGEGR1         lcl   1.9100915504  1.91
Xanomeline High Dose  Placebo  >64     TRT01A VERSUS AGEGR1         ucl   6.2030734677  6.20
Xanomeline High Dose  Placebo  >64     TRT01A VERSUS AGEGR1         pval  0.0000389491  <0.001
Xanomeline Low Dose   Placebo  18-64   TRT01A VERSUS AGEGR1         hr    1.7377797438  1.74
Xanomeline Low Dose   Placebo  18-64   TRT01A VERSUS AGEGR1         lcl   0.2868641472  0.29
Xanomeline Low Dose   Placebo  18-64   TRT01A VERSUS AGEGR1         ucl   10.527207626  10.53
Xanomeline Low Dose   Placebo  18-64   TRT01A VERSUS AGEGR1         pval  0.5476632242  0.548
Xanomeline Low Dose   Placebo  >64     TRT01A VERSUS AGEGR1         hr    3.0497171134  3.05
Xanomeline Low Dose   Placebo  >64     TRT01A VERSUS AGEGR1         lcl    1.708031955  1.71
Xanomeline Low Dose   Placebo  >64     TRT01A VERSUS AGEGR1         ucl   5.4453164325  5.45
```

```sas
%cox(
     data   = adttde
   , var    = aval
   , by     = trt01a
   , pairs  = "Xanomeline High Dose" "Placebo"
            # "Xanomeline Low Dose"  "Placebo"
   , ties   = breslow
   , pvalue = logrank
   , out    = ttde_hr_lr
 )
```

```text
ttde_hr_lr: 8 rows
TRT01A                VERSUS   GROUPS         BLOCK  STAT         VALUE  TEXT
Xanomeline High Dose  Placebo  TRT01A VERSUS         hr    3.5763638018  3.58
Xanomeline High Dose  Placebo  TRT01A VERSUS         lcl   2.0775962691  2.08
Xanomeline High Dose  Placebo  TRT01A VERSUS         ucl   6.1563347188  6.16
Xanomeline High Dose  Placebo  TRT01A VERSUS         pval  1.0308797E-6  <0.001
Xanomeline Low Dose   Placebo  TRT01A VERSUS         hr    2.9802324855  2.98
Xanomeline Low Dose   Placebo  TRT01A VERSUS         lcl   1.7295616442  1.73
Xanomeline Low Dose   Placebo  TRT01A VERSUS         ucl   5.1352813572  5.14
Xanomeline Low Dose   Placebo  TRT01A VERSUS         pval  0.0000258859  <0.001
```

## Messages

A wrong call writes the message and its fix to the log and stops. The macro also gives the [messages every macro shares](index.md#messages-every-macro-shares).

| Message | Fix |
|---|---|
| pvalue=logrank is not made within groups (within=&lt;within&gt;) | write pvalue=wald. |
| cnsr=&lt;cnsr&gt; is missing or negative on &lt;nbad&gt; record(s) used | give each record CNSR 0 (an event) or more (a censoring). |

## See also

Time to an event: [%km](km.md), [%logrank](logrank.md).

Named on this page: [%interaction_phreg](interaction_phreg.md), [%stack](stack.md), [%describe](describe.md).

## Proof

Checked against its known answers: numbers worked out independently in R, compared on SAS by the tests of the library.

The examples of this page ran on SAS 9.4M9 on 2026-11-27, with a log free of ERROR and WARNING.

[Source of %cox](https://github.com/datastep-labs/sapling-sas/blob/main/macros/cox.sas)
