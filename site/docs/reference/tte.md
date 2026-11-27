# %tte

Returns one time-to-event parameter: for each subject the date of the first event, or else of the latest censoring.

**Procedure:** PROC SORT, MERGE · **Family:** [ADaM steps](index.md#adam)

## Syntax

```sas
%tte(
     subjects      =
   , events        =
   , censors       =
   , event         =
   , date          =
   , time          =
   , priority      =
   , start         =
   , start_time    =
   , end           =
   , censor_date   =
   , seq           =
   , adtf          =
   , atmf          =
   , keep          =
   , censor_cnsr   = 1
   , end_cnsr      = 1
   , censor_desc   =
   , censor_source =
   , end_desc      = "End of at-risk period"
   , event_desc    =
   , source        =
   , paramcd       =
   , out           =
   , debug         = no
 )
```

## Parameters

`subjects=`
:   The data set of the subjects, one record per subject (USUBJID), with the start (and the end) of the period. The result keeps its variables, so it must not have ADT, CNSR, AVAL or the other variables the macro makes. *(required)*

`events=`
:   The data set of the records the events come from, such as adae. *(required)*

`censors=`
:   The data set of the records of the censorings, with `censor_date=`. When not given, the censorings come from `subjects=`. *(optional)*

`event=`
:   The records of `events=` that are events: a condition, such as `event = trtemfl = 'Y'`. When not given, every record with a date is an event. *(optional)*

`date=`
:   The date of an event: a numeric date variable of `events=`. A record with a missing date is no event. *(required)*

`time=`
:   The time of an event: a numeric variable of `events=`, in seconds since midnight. It decides an event on the start day, and needs `end=`. *(optional)*

`priority=`
:   The variables of `events=` that order the events of one date, separated by blanks; a missing value sorts last. When not given, the events of one date keep the order of the data. *(optional)*

`start=`
:   The start of the period and the origin of AVAL: a date variable of `subjects=`. *(required)*

`start_time=`
:   The time of the start: a numeric variable of `subjects=`, in seconds since midnight. On the start day an event counts unless its time is before this time. It needs `end=`. *(optional)*

`end=`
:   The end of the at-risk period: a date variable of `subjects=`. When not given, there is no period and every date counts. *(optional)*

`censor_date=`
:   The date of a censoring: a date variable of `censors=` (or of `subjects=`). *(optional)*

`seq=`
:   The variable of `events=` that gives SRCSEQ of an event, such as aeseq. When not given, SRCSEQ is missing. *(optional)*

`adtf=`
:   The variable of `events=` that gives ADTF, the imputation flag of the date of an event. *(optional)*

`atmf=`
:   The variable of `events=` that gives ATMF, the imputation flag of the time of an event. *(optional)*

`keep=`
:   Other variables of the record taken, separated by blanks: they must be in `events=` and in `censors=` both. *(optional)*

`censor_cnsr=`
:   CNSR of a censoring: a number, or a numeric variable of `censors=`. *(optional, default `1`)*

`end_cnsr=`
:   CNSR of a subject censored at the end of the period: a number. *(optional, default `1`)*

`censor_desc=`
:   EVNTDESC of a censoring: a text in quotes, or a variable of `censors=` (or of `subjects=`). *(optional)*

`censor_source=`
:   SRCDOM of a censoring from `subjects=` and of a censoring at the end of the period: a text in quotes, such as "ADSL". SRCVAR is then the name of `censor_date=` (or of `end=`). *(optional)*

`end_desc=`
:   EVNTDESC of a subject censored at the end of the period: a text in quotes. *(optional, default `"End of at-risk period"`)*

`event_desc=`
:   EVNTDESC of an event: a text in quotes, or a variable of `events=`, such as aedecod. *(optional)*

`source=`
:   SRCDOM of an event: a text in quotes, such as "ADAE". SRCVAR is then the name of `date=`. *(optional)*

`paramcd=`
:   PARAMCD of the parameter: a text in quotes, such as "TTDE". *(required)*

`out=`
:   The name of the data set it writes. *(required)*

`debug=`
:   yes: keep the work data sets _tte_*. *(optional, default `no`)*
    Accepts: `yes`, `no`.

## Result

The data set of `out=`: one record per subject with an event, a censoring or (with `end=`) a period, in the order of `subjects=`: the variables of `subjects=`, PARAMCD, ADT, CNSR, AVAL, ATM (with `time=`), EVNTDESC, SRCDOM, SRCVAR, SRCSEQ, ADTF and ATMF (when their parameters are given) and the variables of `keep=`. With `end=`, a subject with no START or no END gets no record and a WARNING that names it; a subject whose START is after its END gets no record. Two records of a subject in `subjects=` give an ERROR line.

## Details

It writes the records of an ADTTE parameter; [%km](km.md), [%logrank](logrank.md) and [%cox](cox.md) then analyse them. The rule:

- An event is a record of `events=` that meets `event=` and has a date. The first event of a subject is taken; `priority=` orders the events of one date.
- When a subject has no event, the latest censoring is taken: the latest date of `censors=` (or of `subjects=`); on one date, the last record.
- AVAL is ADT - START + 1, in days.

Without `end=`, every date counts, and a date before START becomes START (as admiral does). A subject with no event and no censoring gets no record. With `end=`, the at-risk period runs from START to END: only the events and censorings in it count, and a subject with neither is censored at END. An event on the start day counts unless `time=` and `start_time=` are both there and the event time is before the start time.

## Examples

The examples run on the [example data](../tutorial/index.md#the-example-data) after `examples/setup.sas`. The output under each call is the output of that run.

Derives the time to the first skin event from the first dose: CNSR 0 is an event, 1 a censoring.

```sas
%tte(
     subjects      = adsl
   , events        = adae
   , event         = trtemfl = 'Y' AND aebodsys = 'SKIN AND SUBCUTANEOUS TISSUE DISORDERS'
   , date          = astdt
   , start         = trtsdt
   , censor_date   = trtedt
   , seq           = aeseq
   , censor_desc   = "End of treatment"
   , censor_source = "ADSL"
   , event_desc    = aedecod
   , source        = "ADAE"
   , paramcd       = "TTDE"
   , out           = adttde
 )
```

```text
adttde: the first 15 of 252 rows
USUBJID      TRT01A                PARAMCD  TRTSDT   ADT        CNSR  AVAL  EVNTDESC           SRCDOM  SRCVAR  SRCSEQ
01-701-1015  Placebo               TTDE     02JAN14  02JUL2014     1   182  End of treatment   ADSL    TRTEDT
01-701-1023  Placebo               TTDE     05AUG12  07AUG2012     0     3  ERYTHEMA           ADAE    ASTDT        2
01-701-1028  Xanomeline High Dose  TTDE     19JUL13  14JAN2014     1   180  End of treatment   ADSL    TRTEDT
01-701-1033  Xanomeline Low Dose   TTDE     18MAR14  31MAR2014     1    14  End of treatment   ADSL    TRTEDT
01-701-1034  Xanomeline High Dose  TTDE     01JUL14  30DEC2014     1   183  End of treatment   ADSL    TRTEDT
01-701-1047  Placebo               TTDE     12FEB13  09MAR2013     1    26  End of treatment   ADSL    TRTEDT
01-701-1097  Xanomeline Low Dose   TTDE     01JAN14  03JAN2014     0     3  ERYTHEMA           ADAE    ASTDT        1
01-701-1111  Xanomeline Low Dose   TTDE     07SEP12  16SEP2012     1    10  End of treatment   ADSL    TRTEDT
01-701-1115  Xanomeline Low Dose   TTDE     30NOV12  23JAN2013     1    55  End of treatment   ADSL    TRTEDT
01-701-1118  Placebo               TTDE     12MAR14  09SEP2014     1   182  End of treatment   ADSL    TRTEDT
01-701-1130  Placebo               TTDE     15FEB14  22MAY2014     0    97  PRURITUS           ADAE    ASTDT        7
01-701-1133  Xanomeline High Dose  TTDE     28OCT12  28APR2013     1   183  End of treatment   ADSL    TRTEDT
01-701-1146  Xanomeline High Dose  TTDE     20MAY13  26JUN2013     1    38  End of treatment   ADSL    TRTEDT
01-701-1148  Xanomeline High Dose  TTDE     23AUG13  12FEB2014     0   174  ACTINIC KERATOSIS  ADAE    ASTDT       10
01-701-1153  Placebo               TTDE     23SEP13  16MAR2014     1   175  End of treatment   ADSL    TRTEDT
```

## Messages

A wrong call writes the message and its fix to the log and stops. The macro also gives the [messages every macro shares](index.md#messages-every-macro-shares).

| Message | Fix |
|---|---|
| &lt;dsn&gt;=&lt;dsname&gt; does not exist | give &lt;dsn&gt;= a data set that exists (make it first). |
| censors=&lt;censors&gt; has no date | give censor_date= the date of a censoring in it. |
| time= and start_time= need end=, the end of the period | give end=, or give neither time= nor start_time=. |
| more than one record of the subject in subjects=&lt;subjects&gt; (with the USUBJID of the record) | give one record per subject. |

## See also

ADaM steps: [%merge_subject](merge_subject.md), [%pick](pick.md), [%summarize](summarize.md), [%summarize_groups](summarize_groups.md), [%baseline](baseline.md), [%flag_first](flag_first.md), [%flag_if_any](flag_if_any.md), [%windows](windows.md), [%visits](visits.md), [%locf](locf.md), [%relchange](relchange.md), [%param_wide](param_wide.md), [%pool](pool.md).

Named on this page: [%km](km.md), [%logrank](logrank.md), [%cox](cox.md).

Guides that use %tte: [Make a Kaplan-Meier figure with the number at risk](../how-to/kaplan-meier-figure.md), [Run the examples of the reference](../how-to/run-the-examples.md).

## Proof

The examples of this page ran on SAS 9.4M9 on 2026-11-27, with a log free of ERROR and WARNING.

[Source of %tte](https://github.com/datastep-labs/sapling-sas/blob/main/macros/tte.sas)
