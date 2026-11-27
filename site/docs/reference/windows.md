# %windows

Puts each record into its analysis window by its study day, and gives it AVISIT, AVISITN and the window variables.

**Procedure:** DATA steps (SET POINT=) · **Family:** [ADaM steps](index.md#adam)

## Syntax

```sas
%windows(
     data    =
   , windows =
   , day     = ADY
 )
```

## Parameters

`data=`
:   The data set to change in place, such as advs. *(required)*

`windows=`
:   The windows in the order of AVISITN, separated by #. Each window is AVISITN "AVISIT" AWLO AWHI AWTARGET "AWRANGE"; a period for AWLO or AWHI is a limit that is open (# 4 "Week 4" 2 42 28 "2-42"). *(required)*

`day=`
:   The numeric variable of the study day. *(optional, default `ADY`)*

## Result

The data sets: `data=`, changed in place: AVISIT, AVISITN, AWLO, AWHI, AWTARGET, AWRANGE, AWU and AWTDIFF on each record in a window, missing on a record in no window.

## Details

Use [%visits](visits.md) when the analysis visit comes from the visit name of the record, not from its study day. The macro writes these variables:

- AVISIT and AVISITN: the analysis visit of the window
- AWLO, AWHI and AWTARGET: the first day, the last day and the target day of the window
- AWRANGE: the window as a text; AWU: DAYS
- AWTDIFF: the distance of the study day to the target day

A record takes the first window, in the order of `windows=`, that holds its day. A record with no window, or a missing day, gets missing values only when `data=` does not have these variables yet. When `data=` has them already (an AVISIT from an earlier step), a record in no window keeps its old AVISIT, AVISITN and window values: drop them before the call when such a record must have none.

## Examples

The examples run on the [example data](../tutorial/index.md#the-example-data) after `examples/setup.sas`. The output under each call is the output of that run. All examples of the reference run as one program: [examples/reference.sas](https://github.com/datastep-labs/sapling-sas/blob/main/examples/reference.sas).

Copies the systolic records with only the variables the windows need: no old AVISIT or AVISITN.

```sas
DATA vs;
  SET advs;
  WHERE paramcd = 'SYSBP';
  KEEP usubjid paramcd param adt ady aval vsseq;
RUN;
```

Puts each record in the window of its study day, with the limits, the target and the distance.

```sas
%windows(
     data    = vs
   , windows = 0  "Baseline" .   1   1   "<=1"
             # 4  "Week 4"   2   42  28  "2-42"
             # 12 "Week 12"  43  126 84  "43-126"
             # 24 "Week 24"  127 210 168 "127-210"
   , day     = ady
 )
```

```text
vs: the first 15 of 2926 rows
USUBJID      PARAMCD  ADY  AVISIT    AVISITN  AWLO  AWHI  AWTARGET  AWRANGE  AWTDIFF
01-701-1015  SYSBP     -7  Baseline        0           1         1  <=1            8
01-701-1015  SYSBP     -2  Baseline        0           1         1  <=1            3
01-701-1015  SYSBP      1  Baseline        0           1         1  <=1            0
01-701-1015  SYSBP     13  Week 4          4     2    42        28  2-42          15
01-701-1015  SYSBP     15  Week 4          4     2    42        28  2-42          13
01-701-1015  SYSBP     29  Week 4          4     2    42        28  2-42           1
01-701-1015  SYSBP     31  Week 4          4     2    42        28  2-42           3
01-701-1015  SYSBP     42  Week 4          4     2    42        28  2-42          14
01-701-1015  SYSBP     63  Week 12        12    43   126        84  43-126        21
01-701-1015  SYSBP     84  Week 12        12    43   126        84  43-126         0
01-701-1015  SYSBP     84  Week 12        12    43   126        84  43-126         0
01-701-1015  SYSBP    126  Week 12        12    43   126        84  43-126        42
01-701-1015  SYSBP    140  Week 24        24   127   210       168  127-210       28
01-701-1015  SYSBP    168  Week 24        24   127   210       168  127-210        0
01-701-1015  SYSBP    182  Week 24        24   127   210       168  127-210       14
```

## Messages

A wrong call writes the message and its fix to the log and stops. The macro also gives the [messages every macro shares](index.md#messages-every-macro-shares).

| Message | Fix |
|---|---|
| row &lt;n&gt; of &lt;parameter&gt;= has not &lt;n&gt; values. | write a row as &lt;the form of a row&gt;, # between the rows. |

## See also

ADaM steps: [%merge_subject](merge_subject.md), [%pick](pick.md), [%summarize](summarize.md), [%summarize_groups](summarize_groups.md), [%baseline](baseline.md), [%flag_first](flag_first.md), [%flag_if_any](flag_if_any.md), [%visits](visits.md), [%locf](locf.md), [%relchange](relchange.md), [%param_wide](param_wide.md), [%pool](pool.md), [%tte](tte.md).

Guides that use %windows: [Derive analysis visits, the baseline and the change from baseline](../how-to/derive-baseline.md).

## Proof

Checked on its test cases of the analysis visit of each study day (small made-up records): every value the same as that of the expected records; ran on SAS 9.4 M9, 2026-11-12.

The known answers and test cases are kept with the development of the library, not in this repository.

The examples of this page ran on SAS 9.4 M9 on 2026-11-27, with a log free of ERROR and WARNING.

[Source of %windows](https://github.com/datastep-labs/sapling-sas/blob/main/macros/windows.sas)
