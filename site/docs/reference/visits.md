# %visits

Gives each record its analysis visit, AVISIT and AVISITN, from the value of its variable VISIT.

**Procedure:** DATA steps (SET POINT=) · **Family:** [ADaM steps](index.md#adam)

## Syntax

```sas
%visits(
     data   =
   , visits =
 )
```

## Parameters

`data=`
:   The data set to change in place, with the variable VISIT, such as adlb. *(required)*

`visits=`
:   The visits, separated by #. Each visit is "VISIT" AVISITN "AVISIT": the value of VISIT in quotes, then the analysis visit as a number and as a text (# "WEEK 2" 2 "Week 2"). *(required)*

## Result

The data sets: `data=`, changed in place: AVISIT and AVISITN on each record whose visit is in `visits=`, missing on the others.

## Details

Use [%windows](windows.md) when the analysis visit comes from the study day of the record. The value of VISIT must match exactly, in upper and lower case. A record whose visit is not in `visits=` gets missing values only when `data=` does not have AVISIT and AVISITN yet. When `data=` has them already (from an earlier step), a record whose visit is not in `visits=` keeps its old AVISIT and AVISITN: drop them before the call when such a record must have none.

## Examples

The examples run on the [example data](../tutorial/index.md#the-example-data) after `examples/setup.sas`. The output under each call is the output of that run. All examples of the reference run as one program: [examples/reference.sas](https://github.com/datastep-labs/sapling-sas/blob/main/examples/reference.sas).

Copies the ALT records that are not derived, without an analysis visit.

```sas
DATA lb;
  SET adlb;
  WHERE paramcd = 'ALT' AND MISSING(dtype);
  KEEP usubjid paramcd visit aval;
RUN;
```

Maps each collected visit to its analysis visit and its number: SCREENING 1 is the Baseline.

```sas
%visits(
     data   = lb
   , visits = "SCREENING 1" 0  "Baseline"
            # "WEEK 2"      2  "Week 2"
            # "WEEK 4"      4  "Week 4"
            # "WEEK 6"      6  "Week 6"
            # "WEEK 8"      8  "Week 8"
            # "WEEK 12"     12 "Week 12"
            # "WEEK 16"     16 "Week 16"
            # "WEEK 20"     20 "Week 20"
            # "WEEK 24"     24 "Week 24"
            # "WEEK 26"     26 "Week 26"
 )
```

```text
lb: the first 15 of 1814 rows
USUBJID      PARAMCD  VISIT        AVISIT    AVISITN
01-701-1015  ALT      SCREENING 1  Baseline        0
01-701-1015  ALT      WEEK 2       Week 2          2
01-701-1015  ALT      WEEK 4       Week 4          4
01-701-1015  ALT      WEEK 6       Week 6          6
01-701-1015  ALT      WEEK 8       Week 8          8
01-701-1015  ALT      WEEK 12      Week 12        12
01-701-1015  ALT      WEEK 16      Week 16        16
01-701-1015  ALT      WEEK 20      Week 20        20
01-701-1015  ALT      WEEK 24      Week 24        24
01-701-1015  ALT      WEEK 26      Week 26        26
01-701-1023  ALT      SCREENING 1  Baseline        0
01-701-1023  ALT      WEEK 2       Week 2          2
01-701-1023  ALT      WEEK 4       Week 4          4
01-701-1028  ALT      SCREENING 1  Baseline        0
01-701-1028  ALT      WEEK 2       Week 2          2
```

## Messages

A wrong call writes the message and its fix to the log and stops. The macro also gives the [messages every macro shares](index.md#messages-every-macro-shares).

| Message | Fix |
|---|---|
| row &lt;n&gt; of &lt;parameter&gt;= has not &lt;n&gt; values. | write a row as &lt;the form of a row&gt;, # between the rows. |

## See also

ADaM steps: [%merge_subject](merge_subject.md), [%pick](pick.md), [%summarize](summarize.md), [%summarize_groups](summarize_groups.md), [%baseline](baseline.md), [%flag_first](flag_first.md), [%flag_if_any](flag_if_any.md), [%windows](windows.md), [%locf](locf.md), [%relchange](relchange.md), [%param_wide](param_wide.md), [%pool](pool.md), [%tte](tte.md).

## Proof

Checked on its test cases of the analysis visit of each collected visit (small made-up records): every value the same as that of the expected records; ran on SAS 9.4 M9, 2026-11-12.

The known answers and test cases are kept with the development of the library, not in this repository.

The examples of this page ran on SAS 9.4 M9 on 2026-11-27, with a log free of ERROR and WARNING.

[Source of %visits](https://github.com/datastep-labs/sapling-sas/blob/main/macros/visits.sas)
