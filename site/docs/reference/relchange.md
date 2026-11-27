# %relchange

Returns new records with the change from the record before, relative to the normal range, flagged in ANRIND.

**Procedure:** PROC SORT, a DATA step (LAG) · **Family:** [ADaM steps](index.md#adam)

## Syntax

```sas
%relchange(
     data   =
   , where  =
   , value  =
   , by     = USUBJID PARAMCD
   , lo     = A1LO
   , hi     = A1HI
   , order  = VISITNUM ADT LBSEQ
   , prefix = _
   , digits = 1
   , limit  = 1
   , reset  = BASE CHG BNRIND R2A1LO R2A1HI BR2A1LO BR2A1HI
   , out    =
   , debug  = no
 )
```

## Parameters

`data=`
:   The input data set, such as adlb; it is not changed. *(required)*

`where=`
:   The records to read: a condition in parentheses, such as `where = (paramcd = 'ALT')`. The record before is one of these records. *(optional)*

`value=`
:   The numeric variable of the measured value, such as lbstresn. *(required)*

`by=`
:   The groups: variables separated by blanks. The first record of a group has no record before. *(optional, default `USUBJID PARAMCD`)*

`lo=`
:   The numeric variable of the lower limit of the normal range. *(optional, default `A1LO`)*

`hi=`
:   The numeric variable of the upper limit of the normal range. *(optional, default `A1HI`)*

`order=`
:   The variables that sort the records of a group and so give the record before, separated by blanks. A missing value sorts first. *(optional, default `VISITNUM ADT LBSEQ`)*

`prefix=`
:   The text put before PARAMCD in the new records, without quotes. *(optional, default `_`)*

`digits=`
:   The number of decimals of AVAL. *(optional, default `1`)*

`limit=`
:   The limit of ANRIND, in half ranges: H above `limit=`, L below -`limit=`. The value 1 is half the normal range. *(optional, default `1`)*

`reset=`
:   The variables that are set missing on the new records, separated by blanks; a variable that `data=` does not have is skipped. *(optional, default `BASE CHG BNRIND R2A1LO R2A1HI BR2A1LO BR2A1HI`)*

`out=`
:   The name of the data set of the new records. *(required)*

`debug=`
:   yes: keep the work data sets _relchange_*. *(optional, default `no`)*
    Accepts: `yes`, `no`.

## Result

The data set of `out=`: one new record for each record read, sorted by `by=` and `order=`, with the variables of `data=`. The limits and the variables of `reset=` are missing. PARAMCD keeps its length in `data=`, so it must be long enough for the new codes (the generated programs give it the length of the specification, which lists them).

## Details

Each new record compares a value with the value of the record before it in its group (by=, sorted by `order=`): the change is divided by half the width of the normal range, so 1 is a change as large as half the range, and limit=1 flags a change larger than half the normal range as abnormal. For each record read, the new record has:

- PARAMCD: `prefix=` before the code of the record
- AVAL: (value - the value of the record before) / ((upper limit - lower limit) / 2), rounded to `digits=` decimals
- ANRIND: H when AVAL is above `limit=`, L when it is below -`limit=`, N between, blank when AVAL is missing

AVAL is missing on the first record of a group, on a record with no AVISITN, and when a value or a limit is missing or the upper limit is not above the lower one. For the change from baseline (CHG = AVAL - BASE), use [%baseline](baseline.md) and a DATA step.

## Examples

The examples run on the [example data](../tutorial/index.md#the-example-data) after `examples/setup.sas`. The output under each call is the output of that run.

Adds a record per value: its change from the record before, relative to half the normal range.

```sas
%relchange(
     data  = adlb
   , where = (paramcd = 'ALT' AND MISSING(dtype))
   , value = lbstresn
   , lo    = anrlo
   , hi    = anrhi
   , out   = alt_rel
 )
```

```text
alt_rel: the first 15 of 1814 rows
USUBJID      PARAMCD  VISITNUM  AVISIT    LBSTRESN  ANRLO  ANRHI  AVAL  ANRIND
01-701-1015  _ALT            1  Baseline        27
01-701-1015  _ALT            4  Week 2          41                   1  N
01-701-1015  _ALT            5  Week 4          18                -1.6  L
01-701-1015  _ALT            7  Week 6          26                 0.6  N
01-701-1015  _ALT            8  Week 8          22                -0.3  N
01-701-1015  _ALT            9  Week 12         27                 0.4  N
01-701-1015  _ALT           10  Week 16         17                -0.7  N
01-701-1015  _ALT           11  Week 20         21                 0.3  N
01-701-1015  _ALT           12  Week 24         23                 0.1  N
01-701-1015  _ALT           13  Week 26         23                   0  N
01-701-1023  _ALT            1  Baseline        23
01-701-1023  _ALT            4  Week 2          30                 0.4  N
01-701-1023  _ALT            5  Week 4          38                 0.4  N
01-701-1028  _ALT            1  Baseline        26
01-701-1028  _ALT            4  Week 2          30                 0.3  N
```

## Messages

The macro gives only the [messages every macro shares](index.md#messages-every-macro-shares).

## See also

ADaM steps: [%merge_subject](merge_subject.md), [%pick](pick.md), [%summarize](summarize.md), [%summarize_groups](summarize_groups.md), [%baseline](baseline.md), [%flag_first](flag_first.md), [%flag_if_any](flag_if_any.md), [%windows](windows.md), [%visits](visits.md), [%locf](locf.md), [%param_wide](param_wide.md), [%pool](pool.md), [%tte](tte.md).

Guides that use %relchange: [Derive analysis visits, the baseline and the change from baseline](../how-to/derive-baseline.md), [Run the examples of the reference](../how-to/run-the-examples.md).

## Proof

The examples of this page ran on SAS 9.4M9 on 2026-11-27, with a log free of ERROR and WARNING.

[Source of %relchange](https://github.com/datastep-labs/sapling-sas/blob/main/macros/relchange.sas)
