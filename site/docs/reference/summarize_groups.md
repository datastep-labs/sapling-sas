# %summarize_groups

Returns one record per group with the sum, mean, largest or smallest value of each variable over the group.

**Procedure:** PROC SUMMARY · **Family:** [ADaM steps](index.md#adam)

## Syntax

```sas
%summarize_groups(
     data  =
   , by    =
   , vars  =
   , stats =
   , out   =
 )
```

## Parameters

`data=`
:   The input data set. When a value is not a variable yet (a condition as 0 or 1), make it first in a DATA step. *(required)*

`by=`
:   The groups: one variable or several, separated by blanks (`by = usubjid paramcd`). *(required)*

`vars=`
:   The numeric variables to summarize, separated by blanks. *(required)*

`stats=`
:   One statistic for each variable of `vars=`, in the same order, separated by blanks: sum, mean, max or min (`stats = sum max`). *(required)*

`out=`
:   The name of the data set it writes. *(required)*

## Result

The data set of `out=`: one record per group: the BY variables and the variables of `vars=`, each with its summary under its own name.

## Details

Use [%summarize](summarize.md) to add a summary of each subject's records to another data set. A missing value of a BY variable is a group of its own. A sum or a mean of only missing values is missing.

## Examples

The examples run on the [example data](../tutorial/index.md#the-example-data) after `examples/setup.sas`. The output under each call is the output of that run.

```sas
%summarize_groups(
     data  = advs
   , by    = usubjid paramcd
   , vars  = aval chg
   , stats = max min
   , out   = vs_extremes
 )
```

```text
vs_extremes: the first 15 of 762 rows
USUBJID      PARAMCD   AVAL    CHG
01-701-1015  DIABP       72     -1
01-701-1015  SYSBP      163    -16
01-701-1015  WEIGHT   54.43  -1.36
01-701-1023  DIABP       89      2
01-701-1023  SYSBP      133     -8
01-701-1023  WEIGHT   80.74      0
01-701-1028  DIABP       85    -16
01-701-1028  SYSBP      143    -16
01-701-1028  WEIGHT   99.79  -0.91
01-701-1033  DIABP       84     -7
01-701-1033  SYSBP      151     -6
01-701-1033  WEIGHT   89.36      0
01-701-1034  DIABP       87     -3
01-701-1034  SYSBP      188    -18
01-701-1034  WEIGHT   65.32      0
```

## Messages

A wrong call writes the message and its fix to the log and stops. The macro also gives the [messages every macro shares](index.md#messages-every-macro-shares).

| Message | Fix |
|---|---|
| stats=&lt;stats&gt; needs one statistic for each of vars=&lt;vars&gt; | give one of sum mean max min for each. |

## See also

ADaM steps: [%merge_subject](merge_subject.md), [%pick](pick.md), [%summarize](summarize.md), [%baseline](baseline.md), [%flag_first](flag_first.md), [%flag_if_any](flag_if_any.md), [%windows](windows.md), [%visits](visits.md), [%locf](locf.md), [%relchange](relchange.md), [%param_wide](param_wide.md), [%pool](pool.md), [%tte](tte.md).

## Proof

The examples of this page ran on SAS 9.4M9 on 2026-11-27, with a log free of ERROR and WARNING.

[Source of %summarize_groups](https://github.com/datastep-labs/sapling-sas/blob/main/macros/summarize_groups.sas)
