# %km

Returns the Kaplan-Meier summary of a time in each group: subjects, events, the median time and its confidence limits.

**Procedure:** PROC LIFETEST · **Family:** [Time to an event](index.md#time)

## Syntax

```sas
%km(
     data     =
   , where    =
   , var      =
   , by       =
   , cnsr     = CNSR
   , time     =
   , conftype = linear
   , level    = 0.95
   , stats    = n="XX" events="XX" median="XX.X" lcl="XX.X" ucl="XX.X"
   , label    =
   , out      =
   , debug    = no
 )
```

## Parameters

`data=`
:   The input data set: one record per subject, with the time and the censoring variable. *(required)*

`where=`
:   The records to use: a condition in parentheses, such as where = (`paramcd = 'TTDE'`). *(optional)*

`var=`
:   The time: one numeric variable, such as aval. *(required)*

`by=`
:   The groups: one variable. *(required)*

`cnsr=`
:   The censoring variable: one numeric variable, 0 for an event and a positive value for a censoring (the ADaM CNSR: 1, 2 ... name the reason). A missing or negative value on a record used stops the macro with an ERROR. *(optional, default `CNSR`)*

`time=`
:   One time at which to give the survival: a number, such as `time = 180`. When not given, the result has no survival. *(optional)*

`conftype=`
:   The transformation of the confidence interval: linear, log or loglog, as CONFTYPE= of PROC LIFETEST (the default of PROC LIFETEST itself is loglog). *(optional, default `linear`)*
    Accepts: `linear`, `log`, `loglog`.

`level=`
:   The confidence level: a number between 0 and 1. *(optional, default `0.95`)*

`stats=`
:   The statistics, in the order of the rows: each name with its pattern of the printed number, separated by blanks. The names are n, events, median, lcl, ucl and, with `time=`, surv. A name without a pattern takes its default pattern (n="XX", mean="XX.X", pval="X.XXX" ...; see [%describe](describe.md)). *(optional, default `n="XX" events="XX" median="XX.X" lcl="XX.X" ucl="XX.X"`)*

`label=`
:   The label of the block in the table: a text in quotes. A block is the rows of one call in the table. *(optional)*

`out=`
:   The name of the result data set. *(required)*

`debug=`
:   yes: keep the work data sets _km_*. *(optional, default `no`)*
    Accepts: `yes`, `no`.

## Result

The data set of `out=`: the [result shape](../explanation/result-shape.md), one row per group and statistic: the BY variable, GROUPS, BLOCK, STAT, VALUE and TEXT. When no record qualifies, the result has no row and the log has the NOTE "No data qualified".

## Details

Use [%kmplot](kmplot.md) to draw the curve, and [%table_tte](table_tte.md) for the whole table of a time to event in one call. The statistics are n (the subjects), events, median, lcl and ucl. The limits of the median are those of Brookmeyer and Crowley, from PROC LIFETEST. A median or a limit that the curve does not reach has a missing VALUE and the TEXT NE (not estimable). Without `time=`, lcl and ucl are the limits of the median. With `time=`, surv is the survival at that time in percent, and lcl and ucl are the limits of that survival, in percent, not of the median; the default `stats=` has no surv, so give `stats=` with surv to show it. A record with a missing time or a missing group is not used. CNSR 0 is an event and any positive value is a censoring, as in ADaM, where the value names the reason of the censoring: a CNSR of 2 is censored as 1 is. A record used with a missing or negative CNSR stops the macro with an ERROR.

!!! note "Good to know"

    The macro does not give the number at risk at given times: [%kmplot](kmplot.md) draws it and keeps it in its `out=` data set.

## Examples

The examples run on the [example data](../tutorial/index.md#the-example-data) after `examples/setup.sas`. The output under each call is the output of that run. They also read `adttde` (made by the [example of %tte](tte.md#examples)).

```sas
%km(
     data  = adttde
   , var   = aval
   , by    = trt01a
   , label = "Time to the first skin event (days)"
   , out   = ttde_km
 )
```

```text
ttde_km: 15 rows
TRT01A                GROUPS  BLOCK                                STAT    VALUE  TEXT
Placebo               TRT01A  Time to the first skin event (days)  n          85  85
Placebo               TRT01A  Time to the first skin event (days)  events     20  20
Placebo               TRT01A  Time to the first skin event (days)  median         NE
Placebo               TRT01A  Time to the first skin event (days)  lcl            NE
Placebo               TRT01A  Time to the first skin event (days)  ucl            NE
Xanomeline High Dose  TRT01A  Time to the first skin event (days)  n          72  72
Xanomeline High Dose  TRT01A  Time to the first skin event (days)  events     39  39
Xanomeline High Dose  TRT01A  Time to the first skin event (days)  median     57  57.0
Xanomeline High Dose  TRT01A  Time to the first skin event (days)  lcl        46  46.0
Xanomeline High Dose  TRT01A  Time to the first skin event (days)  ucl       177  177.0
Xanomeline Low Dose   TRT01A  Time to the first skin event (days)  n          95  95
Xanomeline Low Dose   TRT01A  Time to the first skin event (days)  events     39  39
Xanomeline Low Dose   TRT01A  Time to the first skin event (days)  median     80  80.0
Xanomeline Low Dose   TRT01A  Time to the first skin event (days)  lcl        51  51.0
Xanomeline Low Dose   TRT01A  Time to the first skin event (days)  ucl            NE
```

```sas
%km(
     data  = adtte
   , where = (paramcd = 'OS')
   , var   = aval
   , by    = trt01p
   , time  = 182
   , stats = n="XX" events="XX" surv="XX.X" lcl="XX.X" ucl="XX.X"
   , out   = os_km
 )
```

```text
os_km: 15 rows
TRT01P                GROUPS  BLOCK  STAT           VALUE   TEXT
Placebo               TRT01P         n                 86     86
Placebo               TRT01P         events             2      2
Placebo               TRT01P         surv    97.148554337   97.1
Placebo               TRT01P         lcl     93.189710174   93.2
Placebo               TRT01P         ucl              100  100.0
Xanomeline High Dose  TRT01P         n                 84     84
Xanomeline High Dose  TRT01P         events             0      0
Xanomeline High Dose  TRT01P         surv             100  100.0
Xanomeline High Dose  TRT01P         lcl              100  100.0
Xanomeline High Dose  TRT01P         ucl              100  100.0
Xanomeline Low Dose   TRT01P         n                 84     84
Xanomeline Low Dose   TRT01P         events             1      1
Xanomeline Low Dose   TRT01P         surv    98.245614035   98.2
Xanomeline Low Dose   TRT01P         lcl     94.837376767   94.8
Xanomeline Low Dose   TRT01P         ucl              100  100.0
```

```sas
%km(
     data     = adttde
   , var      = aval
   , by       = trt01a
   , conftype = loglog
   , level    = 0.90
   , out      = ttde_km90
 )
```

```text
ttde_km90: 15 rows
TRT01A                GROUPS  BLOCK  STAT    VALUE  TEXT
Placebo               TRT01A         n          85  85
Placebo               TRT01A         events     20  20
Placebo               TRT01A         median         NE
Placebo               TRT01A         lcl            NE
Placebo               TRT01A         ucl            NE
Xanomeline High Dose  TRT01A         n          72  72
Xanomeline High Dose  TRT01A         events     39  39
Xanomeline High Dose  TRT01A         median     57  57.0
Xanomeline High Dose  TRT01A         lcl        46  46.0
Xanomeline High Dose  TRT01A         ucl       177  177.0
Xanomeline Low Dose   TRT01A         n          95  95
Xanomeline Low Dose   TRT01A         events     39  39
Xanomeline Low Dose   TRT01A         median     80  80.0
Xanomeline Low Dose   TRT01A         lcl        48  48.0
Xanomeline Low Dose   TRT01A         ucl            NE
```

## Messages

A wrong call writes the message and its fix to the log and stops. The macro also gives the [messages every macro shares](index.md#messages-every-macro-shares).

| Message | Fix |
|---|---|
| cnsr=&lt;cnsr&gt; is missing or negative on &lt;nbad&gt; record(s) used | give each record CNSR 0 (an event) or more (a censoring). |

## See also

Time to an event: [%logrank](logrank.md), [%cox](cox.md).

Named on this page: [%kmplot](kmplot.md), [%table_tte](table_tte.md), [%stack](stack.md), [%describe](describe.md).

## Proof

Checked against its known answers: numbers worked out independently in R, compared on SAS by the tests of the library.

The examples of this page ran on SAS 9.4M9 on 2026-11-27, with a log free of ERROR and WARNING.

[Source of %km](https://github.com/datastep-labs/sapling-sas/blob/main/macros/km.sas)
