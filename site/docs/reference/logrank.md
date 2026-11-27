# %logrank

Returns the p-value of the log-rank test that compares the time to an event between the groups.

**Procedure:** PROC LIFETEST (STRATA) · **Family:** [Time to an event](index.md#time)

## Syntax

```sas
%logrank(
     data   =
   , where  =
   , var    =
   , by     =
   , cnsr   = CNSR
   , strata =
   , stats  = pval="X.XXX"
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
:   The groups to compare: one variable. *(required)*

`cnsr=`
:   The censoring variable: one numeric variable, 0 for an event and a positive value for a censoring (the ADaM CNSR: 1, 2 ... name the reason). A missing or negative value on a record used stops the macro with an ERROR. *(optional, default `CNSR`)*

`strata=`
:   The strata of a stratified test: one variable or several, separated by blanks (`strata = sitegr1`). When not given, the test is not stratified. *(optional)*

`stats=`
:   The statistic with its pattern of the printed number: pval. *(optional, default `pval="X.XXX"`)*

`label=`
:   The label of the block in the table: a text in quotes. A block is the rows of one call in the table. *(optional)*

`out=`
:   The name of the result data set. *(required)*

`debug=`
:   yes: keep the work data sets _logrank_*. *(optional, default `no`)*
    Accepts: `yes`, `no`.

## Result

The data set of `out=`: the [result shape](../explanation/result-shape.md), one row for all groups together: GROUPS (blank), BLOCK, STAT (pval), VALUE and TEXT.

## Details

Use [%km](km.md) for the medians of the groups, and [%cox](cox.md) for a hazard ratio with its confidence interval. The test uses one record per subject: when a subject has several records, the first one in the order of USUBJID is used, so `where=` must select one parameter. With `strata=`, the test is the stratified log-rank test: each combination of the values of the strata variables is one stratum (STRATA strata / GROUP=by of PROC LIFETEST). With only one group there is no test, and the p-value is missing. CNSR 0 is an event and any positive value is a censoring, as in ADaM, where the value names the reason of the censoring: a CNSR of 2 is censored as 1 is. A record used with a missing or negative CNSR stops the macro with an ERROR.

## Examples

The examples run on the [example data](../tutorial/index.md#the-example-data) after `examples/setup.sas`. The output under each call is the output of that run. They also read `adttde` (made by the [example of %tte](tte.md#examples)).

```sas
%logrank(
     data   = adttde
   , var    = aval
   , by     = trt01a
   , strata = sex
   , out    = ttde_test
 )
```

```text
ttde_test: 1 row
GROUPS  BLOCK  STAT         VALUE  TEXT
               pval  1.4463308E-6  <0.001
```

## Messages

A wrong call writes the message and its fix to the log and stops. The macro also gives the [messages every macro shares](index.md#messages-every-macro-shares).

| Message | Fix |
|---|---|
| cnsr=&lt;cnsr&gt; is missing or negative on &lt;nbad&gt; record(s) used | give each record CNSR 0 (an event) or more (a censoring). |

## See also

Time to an event: [%km](km.md), [%cox](cox.md).

Named on this page: [%stack](stack.md).

## Proof

Checked against its known answers: numbers worked out independently in R, compared on SAS by the tests of the library.

The examples of this page ran on SAS 9.4M9 on 2026-11-27, with a log free of ERROR and WARNING.

[Source of %logrank](https://github.com/datastep-labs/sapling-sas/blob/main/macros/logrank.sas)
