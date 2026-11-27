# %param_wide

Returns the values of several parameters side by side: one record per group, with the variables of each parameter.

**Procedure:** PROC SORT, MERGE · **Family:** [ADaM steps](index.md#adam)

## Syntax

```sas
%param_wide(
     data   =
   , where  =
   , params =
   , vars   =
   , by     =
   , out    =
   , debug  = no
 )
```

## Parameters

`data=`
:   The input data set, with PARAMCD and the BY variables, such as advs. *(required)*

`where=`
:   The records to read: a condition in parentheses, such as `where = (anl01fl = 'Y')`. *(optional)*

`params=`
:   The parameter codes, separated by blanks (`params = sysbp diabp`). They are compared with PARAMCD in upper case. *(required)*

`vars=`
:   The variables to keep of each parameter, separated by blanks (`vars = aval chg`). *(required)*

`by=`
:   The groups: variables separated by blanks, such as the subject and the visit (`by = usubjid avisitn`). *(required)*

`out=`
:   The name of the data set it writes. *(required)*

`debug=`
:   yes: keep the work data sets _param_wide_*. *(optional, default `no`)*
    Accepts: `yes`, `no`.

## Result

The data set of `out=`: one record per group that has a record of every parameter: the BY variables, then &lt;PARAMCD&gt;_&lt;VAR&gt; for each parameter and each variable of `vars=`.

## Details

The variables of each parameter are named &lt;PARAMCD&gt;_&lt;VAR&gt;, such as SYSBP_AVAL. Only a group that has a record of every parameter of `params=` gets a record. Two records of one parameter in a group give an ERROR line that names the group. A code of `params=` with no record stops the macro with an ERROR.

## Examples

The examples run on the [example data](../tutorial/index.md#the-example-data) after `examples/setup.sas`. The output under each call is the output of that run. All examples of the reference run as one program: [examples/reference.sas](https://github.com/datastep-labs/sapling-sas/blob/main/examples/reference.sas).

Puts the value and the change of SYSBP and DIABP side by side: one row per subject and visit.

```sas
%param_wide(
     data   = advs
   , where  = (anl01fl = 'Y')
   , params = sysbp diabp
   , vars   = aval chg
   , by     = usubjid avisitn
   , out    = bp_wide
 )
```

```text
bp_wide: the first 15 of 1603 rows
USUBJID      AVISITN  SYSBP_AVAL  SYSBP_CHG  DIABP_AVAL  DIABP_CHG
01-701-1015        2         114        -16          56          0
01-701-1015        4         138          8          64          8
01-701-1015        6         148         18          55         -1
01-701-1015        8         138          8          67         11
01-701-1015       12         139          9          68         12
01-701-1015       16         163         33          66         10
01-701-1015       20         137          7          67         11
01-701-1015       24         129         -1          63          7
01-701-1015       26         127         -3          61          5
01-701-1015       99         139          9          68         12
01-701-1023        2         122         -8          88          4
01-701-1028        2         134         -4          78         -7
01-701-1028        4         130         -8          69        -16
01-701-1028        6         131         -7          69        -16
01-701-1028        8         137         -1          76         -9
```

## Messages

A wrong call writes the message and its fix to the log and stops. The macro also gives the [messages every macro shares](index.md#messages-every-macro-shares).

| Message | Fix |
|---|---|
| params=&lt;p&gt; has no record in data= (with where=) | give params= the codes of PARAMCD in data=. |

## See also

ADaM steps: [%merge_subject](merge_subject.md), [%pick](pick.md), [%summarize](summarize.md), [%summarize_groups](summarize_groups.md), [%baseline](baseline.md), [%flag_first](flag_first.md), [%flag_if_any](flag_if_any.md), [%windows](windows.md), [%visits](visits.md), [%locf](locf.md), [%relchange](relchange.md), [%pool](pool.md), [%tte](tte.md).

## Proof

Checked on its test cases of a value computed from other parameters (small made-up records): every value the same as that of the expected records; ran on SAS 9.4 M9, 2026-11-12.

The known answers and test cases are kept with the development of the library, not in this repository.

The examples of this page ran on SAS 9.4 M9 on 2026-11-27, with a log free of ERROR and WARNING.

[Source of %param_wide](https://github.com/datastep-labs/sapling-sas/blob/main/macros/param_wide.sas)
