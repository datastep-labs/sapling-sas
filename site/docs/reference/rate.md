# %rate

Returns the exposure-adjusted incidence rate of each group, with its exact Poisson confidence limits.

**Procedure:** PROC FREQ, PROC MEANS, CINV · **Family:** [Describe the data](index.md#describe)

## Syntax

```sas
%rate(
     data     =
   , denom    =
   , where    =
   , by       =
   , exposure =
   , count    = subjects
   , per      = 100
   , level    = 0.95
   , stats    =
   , label    =
   , out      =
   , debug    = no
 )
```

## Parameters

`data=`
:   The input data set: the records of the events, with USUBJID. *(required)*

`denom=`
:   The subjects of the groups with their exposure: a data set with one row per subject, USUBJID and the variable of `by=`. *(required)*

`where=`
:   The records to use: a condition in parentheses, such as `where = (trtemfl = 'Y')`. *(optional)*

`by=`
:   The groups: one variable, in `data=` and in `denom=`. *(required)*

`exposure=`
:   The exposure of a subject: a numeric variable of `denom=`, or an expression of its variables (`exposure = trtdur` / 365.25 gives years). *(required)*

`count=`
:   What the rate counts: subjects (the subjects with a record, each once) or events (every record). *(optional, default `subjects`)*
    Accepts: `subjects`, `events`.

`per=`
:   The units of exposure of the rate: a number (`per = 1000` gives the rate per 1000 patient-years). The row label of [%layout](layout.md) reads "Rate per 100 patient-years"; with another `per=`, change LABEL in the display data set. *(optional, default `100`)*

`level=`
:   The confidence level: a number between 0 and 1 (`level = 0.90`). *(optional, default `0.95`)*

`stats=`
:   The statistics, in the order of the rows: each name with its pattern of the printed number, separated by blanks. The names are n, events, exposure, rate, lcl and ucl. When not given: n (events with count=events), exposure, rate, lcl and ucl. A name without a pattern takes its default pattern (n="XX", mean="XX.X", pval="X.XXX" ...; see [%describe](describe.md)). *(optional)*

`label=`
:   The label of the block in the table: a text in quotes. A block is the rows of one call in the table. *(optional)*

`out=`
:   The name of the result data set. *(required)*

`debug=`
:   yes: keep the work data sets _rate_*. *(optional, default `no`)*
    Accepts: `yes`, `no`.

## Result

The data set of `out=`: the [result shape](../explanation/result-shape.md), one row per group and statistic: the variable of `by=`, GROUPS (by=), BLOCK, STAT, VALUE and TEXT. Every group of `denom=` has its rows: `n = 0` when no subject of it has a record.

## Details

Use [%freq](freq.md) for the percent of subjects with an event, and [%rateratio](rateratio.md) to compare the rates of two groups. The statistics:

- n: the subjects with a record (PROC FREQ); events: every record
- exposure: the sum of the exposure of the subjects of the group in `denom=` (PROC MEANS)
- rate: n (or events with count=events) divided by the exposure, times `per=`
- lcl, ucl: the exact Poisson limits, the chi-square quantiles (CINV) of 2n and 2(n + 1) degrees of freedom, halved, divided by the exposure, times `per=`

## Examples

The examples run on the [example data](../tutorial/index.md#the-example-data) after `examples/setup.sas`. The output under each call is the output of that run.

Gives the subjects with an event per 100 patient years, with the exposure and the limits.

```sas
%rate(
     data     = adae
   , denom    = adsl(WHERE=(trtdurd > 0))
   , where    = (trtemfl = 'Y')
   , by       = trt01a
   , exposure = trtdurd / 365.25
   , out      = ae_rate
 )
```

```text
ae_rate: 15 rows
TRT01A                GROUPS  BLOCK  STAT             VALUE    TEXT
Placebo               TRT01A         n                   65      65
Placebo               TRT01A         exposure  34.800821355    34.8
Placebo               TRT01A         rate      186.77720085  186.78
Placebo               TRT01A         lcl        144.1507004  144.15
Placebo               TRT01A         ucl       238.06287493  238.06
Xanomeline High Dose  TRT01A         n                   68      68
Xanomeline High Dose  TRT01A         exposure   22.12183436    22.1
Xanomeline High Dose  TRT01A         rate      307.38861386  307.39
Xanomeline High Dose  TRT01A         lcl       238.69928638  238.70
Xanomeline High Dose  TRT01A         ucl       389.68831315  389.69
Xanomeline Low Dose   TRT01A         n                   84      84
Xanomeline Low Dose   TRT01A         exposure  22.579055441    22.6
Xanomeline Low Dose   TRT01A         rate      372.02619134  372.03
Xanomeline Low Dose   TRT01A         lcl       296.74266009  296.74
Xanomeline Low Dose   TRT01A         ucl       460.59373936  460.59
```

Counts the events, not the subjects, with count=events: a subject adds each of its events.

```sas
%rate(
     data     = adae
   , denom    = adsl(WHERE=(trtdurd > 0))
   , where    = (trtemfl = 'Y')
   , by       = trt01a
   , exposure = trtdurd / 365.25
   , count    = events
   , out      = ae_events
 )
```

```text
ae_events: 15 rows
TRT01A                GROUPS  BLOCK  STAT             VALUE     TEXT
Placebo               TRT01A         events             281      281
Placebo               TRT01A         exposure  34.800821355     34.8
Placebo               TRT01A         rate      807.45220675   807.45
Placebo               TRT01A         lcl       715.79396212   715.79
Placebo               TRT01A         ucl       907.59372386   907.59
Xanomeline High Dose  TRT01A         events             414      414
Xanomeline High Dose  TRT01A         exposure   22.12183436     22.1
Xanomeline High Dose  TRT01A         rate      1871.4542079  1871.45
Xanomeline High Dose  TRT01A         lcl       1695.5016572  1695.50
Xanomeline High Dose  TRT01A         ucl       2060.7063864  2060.71
Xanomeline Low Dose   TRT01A         events             427      427
Xanomeline Low Dose   TRT01A         exposure  22.579055441     22.6
Xanomeline Low Dose   TRT01A         rate      1891.1331393  1891.13
Xanomeline Low Dose   TRT01A         lcl       1715.9914371  1715.99
Xanomeline Low Dose   TRT01A         ucl       2079.3019306  2079.30
```

Gives the rate of severe events per 1000 patient years with per=1000.

```sas
%rate(
     data     = adae
   , denom    = adsl(WHERE=(trtdurd > 0))
   , where    = (trtemfl = 'Y' AND aesev = 'SEVERE')
   , by       = trt01a
   , exposure = trtdurd / 365.25
   , per      = 1000
   , out      = ae_rate1000
 )
```

```text
ae_rate1000: 15 rows
TRT01A                GROUPS  BLOCK  STAT             VALUE     TEXT
Placebo               TRT01A         n                    5        5
Placebo               TRT01A         exposure  34.800821355     34.8
Placebo               TRT01A         rate      143.67476988   143.67
Placebo               TRT01A         lcl       46.650806702    46.65
Placebo               TRT01A         ucl       335.28898529   335.29
Xanomeline High Dose  TRT01A         n                    8        8
Xanomeline High Dose  TRT01A         exposure   22.12183436     22.1
Xanomeline High Dose  TRT01A         rate      361.63366337   361.63
Xanomeline High Dose  TRT01A         lcl       156.12774784   156.13
Xanomeline High Dose  TRT01A         ucl         712.562483   712.56
Xanomeline Low Dose   TRT01A         n                   16       16
Xanomeline Low Dose   TRT01A         exposure  22.579055441     22.6
Xanomeline Low Dose   TRT01A         rate      708.62131684   708.62
Xanomeline Low Dose   TRT01A         lcl       405.03830983   405.04
Xanomeline Low Dose   TRT01A         ucl       1150.7566233  1150.76
```

## Messages

The macro gives only the [messages every macro shares](index.md#messages-every-macro-shares).

## See also

Describe the data: [%describe](describe.md), [%freq](freq.md), [%proportion](proportion.md), [%worst](worst.md), [%termflags](termflags.md).

Named on this page: [%layout](layout.md), [%rateratio](rateratio.md).

Guides that use %rate: [Run the examples of the reference](../how-to/run-the-examples.md).

## Proof

Checked against its known answers: numbers worked out independently in R and compared on SAS by the tests of the library (the tests are kept with the development of the library, not in this repository).

The examples of this page ran on SAS 9.4M9 on 2026-11-27, with a log free of ERROR and WARNING.

[Source of %rate](https://github.com/datastep-labs/sapling-sas/blob/main/macros/rate.sas)
