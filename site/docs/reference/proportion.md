# %proportion

Returns the percent of subjects in each category and group, with its confidence interval by a method you name.

**Procedure:** PROC FREQ (BINOMIAL) · **Family:** [Describe the data](index.md#describe)

## Syntax

```sas
%proportion(
     data   =
   , denom  =
   , where  =
   , var    =
   , by     =
   , levels =
   , ci     = clopper-pearson
   , level  = 0.95
   , stats  = n="XX" pct="(XX.X%)" lcl="XX.X" ucl="XX.X"
   , label  =
   , out    =
   , debug  = no
 )
```

## Parameters

`data=`
:   The input data set: the records, with USUBJID. *(required)*

`denom=`
:   The subjects of the percent: a data set with one row per subject and the variable of `by=`. When not given, the subjects of `data=` (without `where=`). *(optional)*

`where=`
:   The records to use: a condition in parentheses, such as `where = (avisit = 'Week 24')`. *(optional)*

`var=`
:   The category: one variable. *(required)*

`by=`
:   The groups: one variable, the columns of the table. *(required)*

`levels=`
:   The planned categories: the variable, then its values in quotes (`levels = avalc 'CR' 'PR'`). A planned category without a subject shows with `n = 0`. *(optional)*

`ci=`
:   The method of the interval: clopper-pearson (the exact interval, CL=EXACT; exact is another name for it), wilson (the score interval, CL=WILSON), wald (CL=WALD) or agresti-coull (CL=AGRESTICOULL). *(optional, default `clopper-pearson`)*

`level=`
:   The confidence level: a number between 0 and 1 (`level = 0.90`). *(optional, default `0.95`)*

`stats=`
:   The statistics, in the order of the rows: each name with its pattern of the printed number, separated by blanks. The names are n, pct, lcl and ucl. A name without a pattern takes its default pattern: see the table of default patterns (How a number is kept and printed). *(optional, default `n="XX" pct="(XX.X%)" lcl="XX.X" ucl="XX.X"`)*

`label=`
:   The label of the block in the table: a text in quotes. A block is the rows of one call in the table. *(optional)*

`out=`
:   The name of the result data set. *(required)*

`debug=`
:   yes: keep the work data sets _proportion_*. *(optional, default `no`)*
    Accepts: `yes`, `no`.

## Result

The data set of `out=`: the [result shape](../explanation/result-shape.md), one row per group, category and statistic: the variables of `by=` and `var=`, GROUPS (by= and `var=`), BLOCK, STAT, VALUE and TEXT. When no record qualifies and `levels=` is not given, the result has no row.

## Details

Use [%freq](freq.md) for counts and percents without an interval. The statistics are n, pct, and lcl and ucl: the limits of the interval, in percent like pct. A subject is counted once in each category. The percent is of the subjects of the group in `denom=`. The interval comes from the BINOMIAL option of PROC FREQ.

## Examples

The examples run on the [example data](../tutorial/index.md#the-example-data) after `examples/setup.sas`. The output under each call is the output of that run. All examples of the reference run as one program: [examples/reference.sas](https://github.com/datastep-labs/sapling-sas/blob/main/examples/reference.sas).

Gives the percent that completed and that discontinued, each with its Clopper Pearson limits.

```sas
%proportion(
     data   = adsl
   , var    = eosstt
   , by     = trt01a
   , levels = eosstt 'COMPLETED' 'DISCONTINUED'
   , ci     = clopper-pearson
   , out    = eos_ci
 )
```

```text
eos_ci: the first 15 of 24 rows
TRT01A                EOSSTT        GROUPS         BLOCK  STAT         VALUE  TEXT
Placebo               COMPLETED     TRT01A EOSSTT         n               58  58
Placebo               COMPLETED     TRT01A EOSSTT         pct   67.441860465  (67.4%)
Placebo               COMPLETED     TRT01A EOSSTT         lcl   56.483815765  56.5
Placebo               COMPLETED     TRT01A EOSSTT         ucl   77.159305166  77.2
Placebo               DISCONTINUED  TRT01A EOSSTT         n               28  28
Placebo               DISCONTINUED  TRT01A EOSSTT         pct   32.558139535  (32.6%)
Placebo               DISCONTINUED  TRT01A EOSSTT         lcl   22.840694834  22.8
Placebo               DISCONTINUED  TRT01A EOSSTT         ucl   43.516184235  43.5
Xanomeline High Dose  COMPLETED     TRT01A EOSSTT         n               27  27
Xanomeline High Dose  COMPLETED     TRT01A EOSSTT         pct           37.5  (37.5%)
Xanomeline High Dose  COMPLETED     TRT01A EOSSTT         lcl    26.36109476  26.4
Xanomeline High Dose  COMPLETED     TRT01A EOSSTT         ucl   49.701407063  49.7
Xanomeline High Dose  DISCONTINUED  TRT01A EOSSTT         n               45  45
Xanomeline High Dose  DISCONTINUED  TRT01A EOSSTT         pct           62.5  (62.5%)
Xanomeline High Dose  DISCONTINUED  TRT01A EOSSTT         lcl   50.298592937  50.3
```

Gives the percent of the best responses CR and PR of the N of denom=, with Wilson limits.

```sas
%proportion(
     data   = adrs
   , denom  = adsl
   , where  = (paramcd = 'BOR')
   , var    = avalc
   , by     = trt01a
   , levels = avalc 'CR' 'PR'
   , ci     = wilson
   , out    = bor_ci
 )
```

```text
bor_ci: the first 15 of 24 rows
TRT01A                AVALC  GROUPS        BLOCK  STAT         VALUE  TEXT
Placebo               CR     TRT01A AVALC         n                1  1
Placebo               CR     TRT01A AVALC         pct   1.1627906977  ( 1.2%)
Placebo               CR     TRT01A AVALC         lcl   0.2055568665  0.2
Placebo               CR     TRT01A AVALC         ucl   6.2964065893  6.3
Placebo               PR     TRT01A AVALC         n                1  1
Placebo               PR     TRT01A AVALC         pct   1.1627906977  ( 1.2%)
Placebo               PR     TRT01A AVALC         lcl   0.2055568665  0.2
Placebo               PR     TRT01A AVALC         ucl   6.2964065893  6.3
Xanomeline High Dose  CR     TRT01A AVALC         n                1  1
Xanomeline High Dose  CR     TRT01A AVALC         pct   1.3888888889  ( 1.4%)
Xanomeline High Dose  CR     TRT01A AVALC         lcl   0.2455951883  0.2
Xanomeline High Dose  CR     TRT01A AVALC         ucl   7.4566021475  7.5
Xanomeline High Dose  PR     TRT01A AVALC         n                0  0
Xanomeline High Dose  PR     TRT01A AVALC         pct              0  ( 0.0%)
Xanomeline High Dose  PR     TRT01A AVALC         lcl   3.270486E-16  0.0
```

## Messages

A wrong call writes the message and its fix to the log and stops. The macro also gives the [messages every macro shares](index.md#messages-every-macro-shares).

| Message | Fix |
|---|---|
| ci=&lt;ci&gt; is not one of: clopper-pearson wilson wald agresti-coull | give ci= one of them. |

## See also

Describe the data: [%describe](describe.md), [%freq](freq.md), [%rate](rate.md), [%worst](worst.md), [%termflags](termflags.md).

## Proof

Checked against its known answer (on a small data set, the numbers worked out independently in R); ran on SAS 9.4 M9, 2026-11-12.

The known answers and test cases are kept with the development of the library, not in this repository.

The examples of this page ran on SAS 9.4 M9 on 2026-11-27, with a log free of ERROR and WARNING.

[Source of %proportion](https://github.com/datastep-labs/sapling-sas/blob/main/macros/proportion.sas)
