# %merge_subject

Copies variables from a data set with one row per subject to every row of that subject, matched by USUBJID.

**Procedure:** PROC SORT, MERGE · **Family:** [ADaM steps](index.md#adam)

## Syntax

```sas
%merge_subject(
     data  =
   , from  =
   , vars  =
   , debug = no
 )
```

## Parameters

`data=`
:   The data set to change in place, such as adsl or adae. *(required)*

`from=`
:   The data set to copy from: one row per subject, with USUBJID. *(required)*

`vars=`
:   The variables to copy, separated by blanks. new=old copies the variable old under the name new (`vars = trtsdt trt01a=arm`). *(required)*

`debug=`
:   yes: keep the work data sets _merge_subject_*. *(optional, default `no`)*
    Accepts: `yes`, `no`.

## Result

The data sets: `data=`, changed in place: the variables of `vars=` added to every row, with the values of the subject in `from=`. A subject not in `from=` gets missing values.

## Details

Use [%pick](pick.md) when the other data set has more rows per subject and one of them gives the value. The rows of `data=` keep their order. A subject that `from=` does not have gets missing values. The macro stops with an ERROR when `from=` has two rows of one subject, or when a variable of `vars=` is not in `from=`.

## Examples

The examples run on the [example data](../tutorial/index.md#the-example-data) after `examples/setup.sas`. The output under each call is the output of that run.

```sas
DATA tt;
  SET adtte;
  KEEP usubjid paramcd aval cnsr;
RUN;
```

```sas
%merge_subject(
     data = tt
   , from = adsl
   , vars = agegr1 race trtp=trt01p trtpn=trt01pn
 )
```

```text
tt: the first 15 of 512 rows
USUBJID      PARAMCD  AVAL  CNSR  AGEGR1  RACE   TRTP                  TRTPN
01-701-1015  OS        182     1  18-64   WHITE  Placebo                   0
01-701-1015  PFS        64     1  18-64   WHITE  Placebo                   0
01-701-1015  RSD         1     1  18-64   WHITE  Placebo                   0
01-701-1023  OS         29     1  18-64   WHITE  Placebo                   0
01-701-1023  PFS         1     1  18-64   WHITE  Placebo                   0
01-701-1028  OS        180     1  >64     WHITE  Xanomeline High Dose     81
01-701-1028  PFS        43     0  >64     WHITE  Xanomeline High Dose     81
01-701-1033  OS         28     1  >64     WHITE  Xanomeline Low Dose      54
01-701-1033  PFS         1     1  >64     WHITE  Xanomeline Low Dose      54
01-701-1034  OS        183     1  >64     WHITE  Xanomeline High Dose     81
01-701-1034  PFS        43     1  >64     WHITE  Xanomeline High Dose     81
01-701-1047  OS         55     1  >64     WHITE  Placebo                   0
01-701-1047  PFS         1     1  >64     WHITE  Placebo                   0
01-701-1097  OS        190     1  >64     WHITE  Xanomeline Low Dose      54
01-701-1097  PFS        22     1  >64     WHITE  Xanomeline Low Dose      54
```

## Messages

A wrong call writes the message and its fix to the log and stops. The macro also gives the [messages every macro shares](index.md#messages-every-macro-shares).

| Message | Fix |
|---|---|
| vars=&lt;bad&gt; is not a variable of &lt;fromds&gt; | give vars= variables of from= (new=old to rename one). |
| from=&lt;from&gt; has more than one row of a subject (&lt;twice&gt;). | give from= one row per subject, or use pick.sas. |

## See also

ADaM steps: [%pick](pick.md), [%summarize](summarize.md), [%summarize_groups](summarize_groups.md), [%baseline](baseline.md), [%flag_first](flag_first.md), [%flag_if_any](flag_if_any.md), [%windows](windows.md), [%visits](visits.md), [%locf](locf.md), [%relchange](relchange.md), [%param_wide](param_wide.md), [%pool](pool.md), [%tte](tte.md).

## Proof

The examples of this page ran on SAS 9.4M9 on 2026-11-27, with a log free of ERROR and WARNING.

[Source of %merge_subject](https://github.com/datastep-labs/sapling-sas/blob/main/macros/merge_subject.sas)
