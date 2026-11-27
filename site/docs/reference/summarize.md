# %summarize

Gives each subject the sum, mean, largest or smallest value of a variable over its records in another data set.

**Procedure:** PROC SUMMARY, MERGE · **Family:** [ADaM steps](index.md#adam)

## Syntax

```sas
%summarize(
     data  =
   , from  =
   , value =
   , stat  = sum
   , new   =
   , debug = no
 )
```

## Parameters

`data=`
:   The data set to change in place, such as adsl. *(required)*

`from=`
:   The data set of the records, with USUBJID. When the value is not a variable yet, make it first in a DATA step. *(required)*

`value=`
:   The numeric variable of `from=` to summarize. To count records, give a 0/1 variable and stat=sum; for "some record meets it" use stat=max, for "every record meets it" stat=min. *(required)*

`stat=`
:   The statistic: sum, mean, max or min. *(optional, default `sum`)*
    Accepts: `sum`, `mean`, `max`, `min`.

`new=`
:   The name of the new variable. *(required)*

`debug=`
:   yes: keep the work data sets _summarize_*. *(optional, default `no`)*
    Accepts: `yes`, `no`.

## Result

The data sets: `data=`, changed in place: the variable `new=` on every row of a subject, with the sum, mean, maximum or minimum of `value=` over its records in `from=`. A subject with no record gets a missing value.

## Details

Use [%summarize_groups](summarize_groups.md) for one record per group instead of a new variable on each subject. A subject with no record gets a missing value. A sum of only missing values is missing. The rows of `data=` keep their order.

## Examples

The examples run on the [example data](../tutorial/index.md#the-example-data) after `examples/setup.sas`. The output under each call is the output of that run.

```sas
DATA sl;
  SET adsl;
  KEEP usubjid trtdurd;
RUN;
```

```sas
%summarize(
     data  = sl
   , from  = sdtm.ex
   , value = exendy
   , stat  = max
   , new   = exlstdy
 )
```

```sas
%summarize(
     data  = sl
   , from  = sdtm.ex
   , value = exdose
   , stat  = mean
   , new   = exmdose
 )
```

```text
sl: the first 15 of 254 rows
USUBJID      TRTDURD  EXLSTDY  EXMDOSE
01-701-1015      182      182        0
01-701-1023       28       28        0
01-701-1028      180      180       63
01-701-1033       14       14       54
01-701-1034      183      183       63
01-701-1047       26       26        0
01-701-1097      190      190       54
01-701-1111       10       10       54
01-701-1115       55       55       54
01-701-1118      182      182        0
01-701-1130      183      183        0
01-701-1133      183      183       63
01-701-1146       38       38     67.5
01-701-1148      182      182       63
01-701-1153      175      175        0
```

## Messages

The macro gives only the [messages every macro shares](index.md#messages-every-macro-shares).

## See also

ADaM steps: [%merge_subject](merge_subject.md), [%pick](pick.md), [%summarize_groups](summarize_groups.md), [%baseline](baseline.md), [%flag_first](flag_first.md), [%flag_if_any](flag_if_any.md), [%windows](windows.md), [%visits](visits.md), [%locf](locf.md), [%relchange](relchange.md), [%param_wide](param_wide.md), [%pool](pool.md), [%tte](tte.md).

## Proof

The examples of this page ran on SAS 9.4M9 on 2026-11-27, with a log free of ERROR and WARNING.

[Source of %summarize](https://github.com/datastep-labs/sapling-sas/blob/main/macros/summarize.sas)
