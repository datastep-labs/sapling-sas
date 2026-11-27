# %baseline

Gives every record of a group the value of the group's baseline record, as a new variable such as BASE.

**Procedure:** PROC SORT, MERGE · **Family:** [ADaM steps](index.md#adam)

## Syntax

```sas
%baseline(
     data    =
   , value   =
   , by      =
   , flag    = ABLFL
   , replace = no
   , new     =
   , debug   = no
 )
```

## Parameters

`data=`
:   The data set to change in place, such as advs. *(required)*

`value=`
:   The variable whose baseline value is taken, such as aval. *(required)*

`by=`
:   The groups, each with one baseline record: variables separated by blanks (`by = usubjid paramcd`). *(required)*

`flag=`
:   The baseline flag: a character variable that is 'Y' on the baseline record. *(optional, default `ABLFL`)*

`replace=`
:   yes: `data=` has the variable `new=` already; the macro drops it and makes it again. *(optional, default `no`)*

`new=`
:   The name of the new variable, such as base. *(required)*

`debug=`
:   yes: keep the work data sets _baseline_*. *(optional, default `no`)*
    Accepts: `yes`, `no`.

## Result

The data sets: `data=`, changed in place: the variable `new=` on every record, with the value of `value=` on the baseline record of its group. A group with no baseline record gets a missing value.

## Details

The macro does not make the change from baseline: CHG = AVAL - BASE is a DATA step after %baseline (see the how-to guide Derive analysis visits, the baseline and the change from baseline). The baseline record is the one whose `flag=` variable is 'Y'. A group with no baseline record gets a missing value. The rows of `data=` keep their order. When a group has two baseline records, the log has an ERROR line that names the group, and `data=` is not changed.

## Examples

The examples run on the [example data](../tutorial/index.md#the-example-data) after `examples/setup.sas`. The output under each call is the output of that run. All examples of the reference run as one program: [examples/reference.sas](https://github.com/datastep-labs/sapling-sas/blob/main/examples/reference.sas).

Copies the systolic records.

```sas
DATA vs;
  SET advs;
  WHERE paramcd = 'SYSBP';
RUN;
```

Copies the value of the baseline record to BASE on each record of its subject and parameter.

```sas
%baseline(
     data    = vs
   , value   = aval
   , by      = usubjid paramcd
   , replace = yes
   , new     = base
 )
```

```text
vs: the first 15 of 2926 rows
USUBJID      PARAMCD  AVISIT            ABLFL  AVAL  BASE
01-701-1015  SYSBP                              131   130
01-701-1015  SYSBP                              138   130
01-701-1015  SYSBP    Baseline          Y       130   130
01-701-1015  SYSBP                              137   130
01-701-1015  SYSBP    Week 2                    114   130
01-701-1015  SYSBP    Week 4                    138   130
01-701-1015  SYSBP                              138   130
01-701-1015  SYSBP    Week 6                    148   130
01-701-1015  SYSBP    Week 8                    138   130
01-701-1015  SYSBP    Week 12                   139   130
01-701-1015  SYSBP    End of Treatment          139   130
01-701-1015  SYSBP    Week 16                   163   130
01-701-1015  SYSBP    Week 20                   137   130
01-701-1015  SYSBP    Week 24                   129   130
01-701-1015  SYSBP    Week 26                   127   130
```

## Messages

A wrong call writes the message and its fix to the log and stops. The macro also gives the [messages every macro shares](index.md#messages-every-macro-shares).

| Message | Fix |
|---|---|
| a group of by=&lt;by&gt; has more than one baseline record (flag=&lt;flag&gt;) | give flag= one record in each group. |

## See also

ADaM steps: [%merge_subject](merge_subject.md), [%pick](pick.md), [%summarize](summarize.md), [%summarize_groups](summarize_groups.md), [%flag_first](flag_first.md), [%flag_if_any](flag_if_any.md), [%windows](windows.md), [%visits](visits.md), [%locf](locf.md), [%relchange](relchange.md), [%param_wide](param_wide.md), [%pool](pool.md), [%tte](tte.md).

Guides that use %baseline: [Derive analysis visits, the baseline and the change from baseline](../how-to/derive-baseline.md).

## Proof

Checked on its test cases of the baseline value (small made-up records): every value the same as that of the expected records; ran on SAS 9.4 M9, 2026-11-12.

The known answers and test cases are kept with the development of the library, not in this repository.

The examples of this page ran on SAS 9.4 M9 on 2026-11-27, with a log free of ERROR and WARNING.

[Source of %baseline](https://github.com/datastep-labs/sapling-sas/blob/main/macros/baseline.sas)
