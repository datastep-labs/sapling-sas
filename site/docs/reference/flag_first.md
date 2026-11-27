# %flag_first

Flags the first or last record of each group, among the records that meet a condition, with Y.

**Procedure:** PROC SORT, MERGE · **Family:** [ADaM steps](index.md#adam)

## Syntax

```sas
%flag_first(
     data  =
   , where =
   , by    =
   , order =
   , which = first
   , new   =
   , debug = no
 )
```

## Parameters

<a id="data"></a>`data=`
:   The data set to change in place, such as advs. *(required)*

<a id="where"></a>`where=`
:   The records that can be flagged: a condition in parentheses, such as `where = (anl01fl = 'Y')`. When not given, all records can be flagged. *(optional)*

<a id="by"></a>`by=`
:   The groups: variables separated by blanks (`by = usubjid paramcd`). *(required)*

<a id="order"></a>`order=`
:   The sort keys within a group: variables separated by blanks; write descending before a key as in a BY statement (`order = descending adt`). *(required)*

<a id="which"></a>`which=`
:   first or last: the record of the group that gets the flag. *(optional, default `first`)*
    Accepts: `first`, `last`.

<a id="new"></a>`new=`
:   The name of the flag variable to make. *(required)*

<a id="debug"></a>`debug=`
:   yes: keep the work data sets _flag_first_*. *(optional, default `no`)*
    Accepts: `yes`, `no`.

## Result

The data sets: `data=`, changed in place: the character variable `new=` ($1), Y on the first (or last) record of each group among the records that meet `where=`, blank on the other records.

## Details

Use [%pick](pick.md) to copy the value of such a record to a subject. Use [%flag_if_any](flag_if_any.md) to flag the subjects that have any record that meets a condition. The records of a group are sorted by `order=`. A missing sort key sorts last. Records with equal keys keep their order. The other records get a blank flag. The rows of `data=` keep their order.

## Examples

The examples run on the [example data](../tutorial/index.md#the-example-data) after `examples/setup.sas`. The output under each call is the output of that run. All examples of the reference run as one program: [examples/reference.sas](https://github.com/datastep-labs/sapling-sas/blob/main/examples/reference.sas).

Copies the systolic records.

```sas
DATA vs;
  SET advs;
  WHERE paramcd = 'SYSBP';
RUN;
```

Flags in ANL02FL the first record of each subject, parameter and visit by day and time point.

```sas
%flag_first(
     data  = vs
   , where = (NOT MISSING(avisitn) AND NOT MISSING(aval))
   , by    = usubjid paramcd avisitn
   , order = ady atptn vsseq
   , new   = anl02fl
 )
```

```text
vs: the first 15 of 2926 rows
USUBJID      PARAMCD  AVISITN  ADY  ATPTN  AVAL  ANL02FL
01-701-1015  SYSBP              -7    815   131
01-701-1015  SYSBP              -2    815   138
01-701-1015  SYSBP          0    1    815   130  Y
01-701-1015  SYSBP              13    815   137
01-701-1015  SYSBP          2   15    815   114  Y
01-701-1015  SYSBP          4   29    815   138  Y
01-701-1015  SYSBP              31    815   138
01-701-1015  SYSBP          6   42    815   148  Y
01-701-1015  SYSBP          8   63    815   138  Y
01-701-1015  SYSBP         12   84    815   139  Y
01-701-1015  SYSBP         99   84    815   139  Y
01-701-1015  SYSBP         16  126    815   163  Y
01-701-1015  SYSBP         20  140    815   137  Y
01-701-1015  SYSBP         24  168    815   129  Y
01-701-1015  SYSBP         26  182    815   127  Y
```

## Messages

The macro gives only the [messages every macro shares](index.md#messages-every-macro-shares).

## See also

ADaM steps: [%merge_subject](merge_subject.md), [%pick](pick.md), [%summarize](summarize.md), [%summarize_groups](summarize_groups.md), [%baseline](baseline.md), [%flag_if_any](flag_if_any.md), [%windows](windows.md), [%visits](visits.md), [%locf](locf.md), [%relchange](relchange.md), [%param_wide](param_wide.md), [%pool](pool.md), [%tte](tte.md).

Guides that use %flag_first: [Derive analysis visits, the baseline and the change from baseline](../how-to/derive-baseline.md).

## Proof

Checked on its test cases of the flag of the first or the last record (small made-up records): every value the same as that of the expected records; ran on SAS 9.4 M9, 2026-11-12.

The known answers and test cases are kept with the development of the library, not in this repository.

The examples of this page ran on SAS 9.4 M9 on 2026-11-27, with a log free of ERROR and WARNING.

[Source of %flag_first](https://github.com/datastep-labs/sapling-sas/blob/main/macros/flag_first.sas)
