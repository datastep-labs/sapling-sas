# %pick

Gives each subject the value of its first or last record in another data set, as a new variable.

**Procedure:** PROC SORT, MERGE · **Family:** [ADaM steps](index.md#adam)

## Syntax

```sas
%pick(
     data   =
   , from   =
   , value  =
   , order  =
   , which  = first
   , length =
   , format =
   , unique = no
   , new    =
   , debug  = no
 )
```

## Parameters

`data=`
:   The data set to change in place, such as adsl. *(required)*

`from=`
:   The data set of the records, with USUBJID. When the value or a sort key is not a variable yet (a date from a text, a difference), make it first in a DATA step. *(required)*

`value=`
:   The variable of `from=` that gives the value. *(required)*

`order=`
:   The sort keys within a subject: variables separated by blanks; write descending before a key as in a BY statement (`order = descending astdt`). When not given, the records keep the order they have in `from=`. *(optional)*

`which=`
:   first or last: the record of the subject that gives the value. *(optional, default `first`)*
    Accepts: `first`, `last`.

`length=`
:   The length of the new variable when it is a text, such as $40. *(optional)*

`format=`
:   The format of the new variable, such as date9. *(optional)*

`unique=`
:   yes: each subject must have at most one record in `from=`, so that no order is needed. Two records of a subject give an ERROR line that names the subject. *(optional, default `no`)*

`new=`
:   The name of the new variable. *(required)*

`debug=`
:   yes: keep the work data sets _pick_*. *(optional, default `no`)*
    Accepts: `yes`, `no`.

## Result

The data sets: `data=`, changed in place: the variable `new=` on every row of a subject, with the value of its first (or last) record in `from=`. A subject with no record gets a missing value. With unique=yes, a subject with two records gets an ERROR line that names it.

## Details

Use [%merge_subject](merge_subject.md) when the other data set has one row per subject. Use [%flag_first](flag_first.md) to flag a record instead of copying a value. The records of a subject are sorted by `order=`, and `which=` takes the first or the last one. A missing sort key sorts last. The rows of `data=` keep their order. A subject with no record in `from=` gets a missing value. When `data=` has the variable `new=` already, the new values replace it and the log says so.

## Examples

The examples run on the [example data](../tutorial/index.md#the-example-data) after `examples/setup.sas`. The output under each call is the output of that run. All examples of the reference run as one program: [examples/reference.sas](https://github.com/datastep-labs/sapling-sas/blob/main/examples/reference.sas).

Copies the subjects with USUBJID and TRTSDT only.

```sas
DATA sl;
  SET adsl;
  KEEP usubjid trtsdt;
RUN;
```

Takes the date of the first exposure record of each subject, as a text of 10.

```sas
%pick(
     data   = sl
   , from   = sdtm.ex
   , value  = exstdtc
   , order  = exstdtc exseq
   , which  = first
   , length = $10
   , new    = exfstdtc
 )
```

Takes the dose of the last exposure record of each subject.

```sas
%pick(
     data  = sl
   , from  = sdtm.ex
   , value = exdose
   , order = exstdtc exseq
   , which = last
   , new   = exldose
 )
```

```text
sl: the first 15 of 254 rows
USUBJID      TRTSDT   EXFSTDTC    EXLDOSE
01-701-1015  02JAN14  2014-01-02        0
01-701-1023  05AUG12  2012-08-05        0
01-701-1028  19JUL13  2013-07-19       54
01-701-1033  18MAR14  2014-03-18       54
01-701-1034  01JUL14  2014-07-01       54
01-701-1047  12FEB13  2013-02-12        0
01-701-1097  01JAN14  2014-01-01       54
01-701-1111  07SEP12  2012-09-07       54
01-701-1115  30NOV12  2012-11-30       54
01-701-1118  12MAR14  2014-03-12        0
01-701-1130  15FEB14  2014-02-15        0
01-701-1133  28OCT12  2012-10-28       54
01-701-1146  20MAY13  2013-05-20       81
01-701-1148  23AUG13  2013-08-23       54
01-701-1153  23SEP13  2013-09-23        0
```

## Messages

A wrong call writes the message and its fix to the log and stops. The macro also gives the [messages every macro shares](index.md#messages-every-macro-shares).

| Message | Fix |
|---|---|
| more than one record in from=&lt;from&gt; of &lt;USUBJID&gt; | give unique=no with order= and which= (the record to keep), or remove the duplicate records. |

The macro also writes these NOTE lines to the log, without stopping:

- `NOTE: [pick] data=<data> has <new> already: new=<new> replaces it.`

## See also

ADaM steps: [%merge_subject](merge_subject.md), [%summarize](summarize.md), [%summarize_groups](summarize_groups.md), [%baseline](baseline.md), [%flag_first](flag_first.md), [%flag_if_any](flag_if_any.md), [%windows](windows.md), [%visits](visits.md), [%locf](locf.md), [%relchange](relchange.md), [%param_wide](param_wide.md), [%pool](pool.md), [%tte](tte.md).

## Proof

Checked on its test cases of a value from one record, from the first or the last record, and from an intercurrent event (small made-up records): every value the same as that of the expected records; ran on SAS 9.4 M9, 2026-11-12.

The known answers and test cases are kept with the development of the library, not in this repository.

The examples of this page ran on SAS 9.4 M9 on 2026-11-27, with a log free of ERROR and WARNING.

[Source of %pick](https://github.com/datastep-labs/sapling-sas/blob/main/macros/pick.sas)
