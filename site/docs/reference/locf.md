# %locf

Adds last-observation-carried-forward records (DTYPE = 'LOCF') to the analysis windows in which a group has no analysed record.

**Procedure:** PROC SORT, a DATA step (SET POINT=) · **Family:** [ADaM steps](index.md#adam)

## Syntax

```sas
%locf(
     data    =
   , windows =
   , where   =
   , by      = USUBJID PARAMCD
   , flag    = ANL01FL
   , day     = ADY
   , length  = $8
   , debug   = no
 )
```

## Parameters

`data=`
:   The data set to change in place, such as advs: the new records are added to it. *(required)*

`windows=`
:   The windows, in the form of `windows=` of [%windows](windows.md): baseline first, then one window or more after it. *(required)*

`where=`
:   The records to carry forward: a condition in parentheses, such as `where = (paramcd = 'SYSBP')`. When not given, all analysed records count. *(optional)*

`by=`
:   The groups, each carried forward by itself: variables separated by blanks. *(optional, default `USUBJID PARAMCD`)*

`flag=`
:   The flag of the analysed records: a character variable that is 'Y' on them. *(optional, default `ANL01FL`)*

`day=`
:   The numeric variable of the study day: it gives AWTDIFF of a new record. *(optional, default `ADY`)*

`length=`
:   The length of DTYPE, such as $8. *(optional, default `$8`)*

`debug=`
:   yes: keep the work data sets _locf_*. *(optional, default `no`)*
    Accepts: `yes`, `no`.

## Result

The data sets: `data=`, changed in place: the new records are added, and all records are sorted by the groups, AVISITN and DTYPE.

## Details

Use [%windows](windows.md) first: it gives each record the AVISITN of its window. The rule:

- An analysed record has `flag=` equal to 'Y' and a window after baseline.
- For each window, from the second window after baseline on, that has no analysed record of the group, the macro copies the last analysed record before it and moves the copy to that window.
- Baseline is not carried forward, and the first window after baseline is not filled.

The new records get the window variables of their window and DTYPE = 'LOCF'; the other records get a blank DTYPE.

## Examples

The examples run on the [example data](../tutorial/index.md#the-example-data) after `examples/setup.sas`. The output under each call is the output of that run.

Copies the systolic records of the analysis visits.

```sas
DATA vs;
  SET advs;
  WHERE paramcd = 'SYSBP' AND avisitn IN (0 4 12 24);
RUN;
```

Carries the last value forward into a visit without a value: DTYPE is LOCF on the new records.

```sas
%locf(
     data    = vs
   , windows = 0  "Baseline" .   1   1   "<=1"
             # 4  "Week 4"   2   42  28  "2-42"
             # 12 "Week 12"  43  126 84  "43-126"
             # 24 "Week 24"  127 210 168 "127-210"
   , where   = (paramcd = 'SYSBP')
   , length  = $7
 )
```

```text
vs where dtype = 'LOCF': the first 15 of 158 rows
USUBJID      PARAMCD  ADY  AVISIT   AVISITN  AVAL  DTYPE
01-701-1115  SYSBP     27  Week 12       12   115  LOCF
01-701-1115  SYSBP     27  Week 24       24   115  LOCF
01-701-1146  SYSBP     28  Week 12       12   121  LOCF
01-701-1146  SYSBP     28  Week 24       24   121  LOCF
01-701-1180  SYSBP     28  Week 12       12   124  LOCF
01-701-1180  SYSBP     28  Week 24       24   124  LOCF
01-701-1188  SYSBP     30  Week 12       12   145  LOCF
01-701-1188  SYSBP     30  Week 24       24   145  LOCF
01-701-1211  SYSBP     27  Week 12       12   115  LOCF
01-701-1211  SYSBP     27  Week 24       24   115  LOCF
01-701-1275  SYSBP     86  Week 24       24   123  LOCF
01-701-1294  SYSBP     83  Week 24       24   123  LOCF
01-701-1302  SYSBP     69  Week 24       24   115  LOCF
01-701-1429  SYSBP     29  Week 12       12   172  LOCF
01-701-1429  SYSBP     29  Week 24       24   172  LOCF
```

## Messages

The macro gives only the [messages every macro shares](index.md#messages-every-macro-shares).

## See also

ADaM steps: [%merge_subject](merge_subject.md), [%pick](pick.md), [%summarize](summarize.md), [%summarize_groups](summarize_groups.md), [%baseline](baseline.md), [%flag_first](flag_first.md), [%flag_if_any](flag_if_any.md), [%windows](windows.md), [%visits](visits.md), [%relchange](relchange.md), [%param_wide](param_wide.md), [%pool](pool.md), [%tte](tte.md).

Guides that use %locf: [Derive analysis visits, the baseline and the change from baseline](../how-to/derive-baseline.md), [Run the examples of the reference](../how-to/run-the-examples.md).

## Proof

The examples of this page ran on SAS 9.4M9 on 2026-11-27, with a log free of ERROR and WARNING.

[Source of %locf](https://github.com/datastep-labs/sapling-sas/blob/main/macros/locf.sas)
