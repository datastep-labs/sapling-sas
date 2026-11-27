# %flag_if_any

Flags with Y every row of each subject that has a record in another data set that meets a condition.

**Procedure:** PROC SORT, MERGE · **Family:** [ADaM steps](index.md#adam)

## Syntax

```sas
%flag_if_any(
     data  =
   , from  =
   , where =
   , else  = N
   , new   =
   , debug = no
 )
```

## Parameters

`data=`
:   The data set to change in place, such as adsl. *(required)*

`from=`
:   The data set of the records, with USUBJID, such as adae. *(required)*

`where=`
:   The condition on the records of `from=`, in parentheses, such as `where = (aesev = 'SEVERE')`. *(required)*

`else=`
:   The value for the other subjects: N, or blank for a blank value. *(optional, default `N`)*

`new=`
:   The name of the flag variable to make. *(required)*

`debug=`
:   yes: keep the work data sets _flag_if_any_*. *(optional, default `no`)*
    Accepts: `yes`, `no`.

## Result

The data sets: `data=`, changed in place: the character variable `new=` ($1) on every row of a subject, Y when the subject has such a record in `from=`, N (or blank) when not.

## Details

Use [%flag_first](flag_first.md) to flag one record of each group instead of a subject. The other subjects get N, or a blank with else=blank. The rows of `data=` keep their order.

## Examples

The examples run on the [example data](../tutorial/index.md#the-example-data) after `examples/setup.sas`. The output under each call is the output of that run. All examples of the reference run as one program: [examples/reference.sas](https://github.com/datastep-labs/sapling-sas/blob/main/examples/reference.sas).

Copies the subjects with USUBJID and EOSSTT only.

```sas
DATA sl;
  SET adsl;
  KEEP usubjid eosstt;
RUN;
```

Sets COMPLFL to Y for a subject with a disposition record COMPLETED, else to N.

```sas
%flag_if_any(
     data  = sl
   , from  = sdtm.ds
   , where = (dsdecod = 'COMPLETED')
   , new   = complfl
 )
```

```text
sl: the first 15 of 254 rows
USUBJID      EOSSTT        COMPLFL
01-701-1015  COMPLETED     Y
01-701-1023  DISCONTINUED  N
01-701-1028  COMPLETED     Y
01-701-1033  DISCONTINUED  N
01-701-1034  COMPLETED     Y
01-701-1047  DISCONTINUED  N
01-701-1097  COMPLETED     Y
01-701-1111  DISCONTINUED  N
01-701-1115  DISCONTINUED  N
01-701-1118  COMPLETED     Y
01-701-1130  COMPLETED     Y
01-701-1133  COMPLETED     Y
01-701-1146  DISCONTINUED  N
01-701-1148  COMPLETED     Y
01-701-1153  COMPLETED     Y
```

## Messages

The macro gives only the [messages every macro shares](index.md#messages-every-macro-shares).

## See also

ADaM steps: [%merge_subject](merge_subject.md), [%pick](pick.md), [%summarize](summarize.md), [%summarize_groups](summarize_groups.md), [%baseline](baseline.md), [%flag_first](flag_first.md), [%windows](windows.md), [%visits](visits.md), [%locf](locf.md), [%relchange](relchange.md), [%param_wide](param_wide.md), [%pool](pool.md), [%tte](tte.md).

## Proof

Checked on its test cases of a flag from a condition and from any record of a subject (small made-up records): every value the same as that of the expected records; ran on SAS 9.4 M9, 2026-11-12.

The known answers and test cases are kept with the development of the library, not in this repository.

The examples of this page ran on SAS 9.4 M9 on 2026-11-27, with a log free of ERROR and WARNING.

[Source of %flag_if_any](https://github.com/datastep-labs/sapling-sas/blob/main/macros/flag_if_any.sas)
