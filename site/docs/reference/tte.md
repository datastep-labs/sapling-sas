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

<a id="subjects"></a>`subjects=`
:   The data set of the subjects, one record per subject (USUBJID), with the start (and the end) of the period. The result keeps its variables, so it must not have ADT, CNSR, AVAL or the other variables the macro makes. *(required)*

<a id="events"></a>`events=`
:   The data set of the records the events come from, such as adae. *(required)*

<a id="censors"></a>`censors=`
:   The data set of the records of the censorings, with `censor_date=`. When not given, the censorings come from `subjects=`. *(optional)*

<a id="event"></a>`event=`
:   The records of `events=` that are events: a condition, such as `event = trtemfl = 'Y'`. When not given, every record with a date is an event. *(optional)*

<a id="date"></a>`date=`
:   The date of an event: a numeric date variable of `events=`. A record with a missing date is no event. *(required)*

<a id="time"></a>`time=`
:   The time of an event: a numeric variable of `events=`, in seconds since midnight. It decides an event on the start day, and needs `end=`. *(optional)*

<a id="priority"></a>`priority=`
:   The variables of `events=` that order the events of one date, separated by blanks; a missing value sorts last. When not given, the events of one date keep the order of the data. *(optional)*

<a id="start"></a>`start=`
:   The start of the period and the origin of AVAL: a date variable of `subjects=`. *(required)*

<a id="start_time"></a>`start_time=`
:   The time of the start: a numeric variable of `subjects=`, in seconds since midnight. On the start day an event counts unless its time is before this time. It needs `end=`. *(optional)*

<a id="end"></a>`end=`
:   The end of the at-risk period: a date variable of `subjects=`. When not given, there is no period and every date counts. *(optional)*

<a id="censor_date"></a>`censor_date=`
:   The date of a censoring: a date variable of `censors=` (or of `subjects=`). *(optional)*

<a id="seq"></a>`seq=`
:   The variable of `events=` that gives SRCSEQ of an event, such as aeseq. When not given, SRCSEQ is missing. *(optional)*

<a id="adtf"></a>`adtf=`
:   The variable of `events=` that gives ADTF, the imputation flag of the date of an event. *(optional)*

<a id="atmf"></a>`atmf=`
:   The variable of `events=` that gives ATMF, the imputation flag of the time of an event. *(optional)*

<a id="keep"></a>`keep=`
:   Other variables of the record taken, separated by blanks: they must be in `events=` and in `censors=` both. *(optional)*

<a id="censor_cnsr"></a>`censor_cnsr=`
:   CNSR of a censoring: a number, or a numeric variable of `censors=`. *(optional, default `1`)*

<a id="end_cnsr"></a>`end_cnsr=`
:   CNSR of a subject censored at the end of the period: a number. *(optional, default `1`)*

<a id="censor_desc"></a>`censor_desc=`
:   EVNTDESC of a censoring: a text in quotes, or a variable of `censors=` (or of `subjects=`). *(optional)*

<a id="censor_source"></a>`censor_source=`
:   SRCDOM of a censoring from `subjects=` and of a censoring at the end of the period: a text in quotes, such as "ADSL". SRCVAR is then the name of `censor_date=` (or of `end=`). *(optional)*

<a id="end_desc"></a>`end_desc=`
:   EVNTDESC of a subject censored at the end of the period: a text in quotes. *(optional, default `"End of at-risk period"`)*

<a id="event_desc"></a>`event_desc=`
:   EVNTDESC of an event: a text in quotes, or a variable of `events=`, such as aedecod. *(optional)*

<a id="source"></a>`source=`
:   SRCDOM of an event: a text in quotes, such as "ADAE". SRCVAR is then the name of `date=`. *(optional)*

<a id="paramcd"></a>`paramcd=`
:   PARAMCD of the parameter: a text in quotes, such as "TTDE". *(required)*

<a id="out"></a>`out=`
:   The name of the data set it writes. *(required)*

<a id="debug"></a>`debug=`
:   yes: keep the work data sets _tte_*. *(optional, default `no`)*
    Accepts: `yes`, `no`.

## Result

The data set of `out=`: one record per subject with an event, a censoring or (with `end=`) a period, in the order of `subjects=`: the variables of `subjects=`, PARAMCD, ADT, CNSR, AVAL, ATM (with `time=`), EVNTDESC, SRCDOM, SRCVAR, SRCSEQ, ADTF and ATMF (when their parameters are given) and the variables of `keep=`. With `end=`, a subject with no START or no END gets no record and a WARNING that names it; a subject whose START is after its END gets no record. Two records of a subject in `subjects=` give an ERROR line. Without `end=`, a subject with no event and no censoring date gets no record, and a NOTE gives their number.

## Details

It writes the records of an ADTTE parameter; [%km](km.md), [%logrank](logrank.md) and [%cox](cox.md) then analyse them. The rule:

- An event is a record of `events=` that meets `event=` and has a date. The first event of a subject is taken; `priority=` orders the events of one date.
- When a subject has no event, the latest censoring is taken: the latest date of `censors=` (or of `subjects=`); on one date, the last record.
- AVAL is ADT - START + 1, in days.

Without `end=`, every date counts, and a date before START becomes START (as admiral does). A subject with no event and no censoring date gets no record, and the log has a NOTE with the number of such subjects. With `end=`, the at-risk period runs from START to END: only the events and censorings in it count, and a subject with neither is censored at END. An event on the start day counts unless `time=` and `start_time=` are both there and the event time is before the start time.

## Examples

The examples run on the [example data](../tutorial/index.md#the-example-data) after `examples/setup.sas`. The output under each call is the output of that run. All examples of the reference run as one program: [examples/reference.sas](https://github.com/datastep-labs/sapling-sas/blob/main/examples/reference.sas).

<a id="ex-adttde"></a>

Makes TTDE. Log NOTE: 2 subject(s) with no event and no censoring date: no record (no TRTEDT).

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

Makes the subjects with the end of week 12 (day 84) and the time of the first dose.

```sas
DATA sl;
  SET adsl;
  wk12dt = trtsdt + 83;
  trtstm = TIMEPART(trtsdtm);
  FORMAT wk12dt DATE9. trtstm TIME5.;
RUN;
```

<a id="ex-adttde12"></a>

Ends the period at week 12: no event or censoring in it gives CNSR 1 on day 84. All 254 count.

```sas
%tte(
     subjects      = sl
   , events        = adae
   , event         = trtemfl = 'Y' AND aebodsys = 'SKIN AND SUBCUTANEOUS TISSUE DISORDERS'
   , date          = astdt
   , start         = trtsdt
   , end           = wk12dt
   , censor_date   = trtedt
   , seq           = aeseq
   , censor_desc   = "End of treatment"
   , censor_source = "ADSL"
   , end_desc      = "End of week 12"
   , event_desc    = aedecod
   , source        = "ADAE"
   , paramcd       = "TTDE12"
   , out           = adttde12
 )
```

```text
adttde12: the first 15 of 254 rows
USUBJID      TRT01A                PARAMCD  TRTSDT   WK12DT     ADT        CNSR  AVAL  EVNTDESC          SRCDOM  SRCVAR  SRCSEQ
01-701-1015  Placebo               TTDE12   02JAN14  26MAR2014  26MAR2014     1    84  End of week 12    ADSL    WK12DT
01-701-1023  Placebo               TTDE12   05AUG12  27OCT2012  07AUG2012     0     3  ERYTHEMA          ADAE    ASTDT        2
01-701-1028  Xanomeline High Dose  TTDE12   19JUL13  10OCT2013  10OCT2013     1    84  End of week 12    ADSL    WK12DT
01-701-1033  Xanomeline Low Dose   TTDE12   18MAR14  09JUN2014  31MAR2014     1    14  End of treatment  ADSL    TRTEDT
01-701-1034  Xanomeline High Dose  TTDE12   01JUL14  22SEP2014  22SEP2014     1    84  End of week 12    ADSL    WK12DT
01-701-1047  Placebo               TTDE12   12FEB13  06MAY2013  09MAR2013     1    26  End of treatment  ADSL    TRTEDT
01-701-1097  Xanomeline Low Dose   TTDE12   01JAN14  25MAR2014  03JAN2014     0     3  ERYTHEMA          ADAE    ASTDT        1
01-701-1111  Xanomeline Low Dose   TTDE12   07SEP12  29NOV2012  16SEP2012     1    10  End of treatment  ADSL    TRTEDT
01-701-1115  Xanomeline Low Dose   TTDE12   30NOV12  21FEB2013  23JAN2013     1    55  End of treatment  ADSL    TRTEDT
01-701-1118  Placebo               TTDE12   12MAR14  03JUN2014  03JUN2014     1    84  End of week 12    ADSL    WK12DT
01-701-1130  Placebo               TTDE12   15FEB14  09MAY2014  09MAY2014     1    84  End of week 12    ADSL    WK12DT
01-701-1133  Xanomeline High Dose  TTDE12   28OCT12  19JAN2013  19JAN2013     1    84  End of week 12    ADSL    WK12DT
01-701-1146  Xanomeline High Dose  TTDE12   20MAY13  11AUG2013  26JUN2013     1    38  End of treatment  ADSL    TRTEDT
01-701-1148  Xanomeline High Dose  TTDE12   23AUG13  14NOV2013  14NOV2013     1    84  End of week 12    ADSL    WK12DT
01-701-1153  Placebo               TTDE12   23SEP13  15DEC2013  15DEC2013     1    84  End of week 12    ADSL    WK12DT
```

Makes the start time of each event, in seconds since midnight.

```sas
DATA ae_times;
  SET adae;
  asttm = TIMEPART(astdtm);
  FORMAT asttm TIME5.;
RUN;
```

<a id="ex-adttde12t"></a>

Adds the times of the start day: all are 00:00, imputed (ATMF H), so the events of day 1 count.

```sas
%tte(
     subjects      = sl
   , events        = ae_times
   , event         = trtemfl = 'Y' AND aebodsys = 'SKIN AND SUBCUTANEOUS TISSUE DISORDERS'
   , date          = astdt
   , time          = asttm
   , start         = trtsdt
   , start_time    = trtstm
   , end           = wk12dt
   , censor_date   = trtedt
   , seq           = aeseq
   , atmf          = asttmf
   , censor_desc   = "End of treatment"
   , censor_source = "ADSL"
   , end_desc      = "End of week 12"
   , event_desc    = aedecod
   , source        = "ADAE"
   , paramcd       = "TTDE12"
   , out           = adttde12t
 )
```

```text
adttde12t where adt = trtsdt: 7 rows
USUBJID      PARAMCD  TRTSDT   TRTSTM  ADT        ATM  ATMF  CNSR  AVAL  EVNTDESC
01-704-1074  TTDE12   22JAN14  0:00    22JAN2014    0  H        0     1  PRURITUS
01-706-1384  TTDE12   15SEP12  0:00    15SEP2012    0  H        0     1  ERYTHEMA
01-708-1236  TTDE12   21SEP13  0:00    21SEP2013                1     1  End of treatment
01-716-1063  TTDE12   09MAY13  0:00    09MAY2013    0  H        0     1  HYPERHIDROSIS
01-716-1229  TTDE12   20FEB13  0:00    20FEB2013    0  H        0     1  PRURITUS
01-716-1418  TTDE12   05MAY13  0:00    05MAY2013    0  H        0     1  URTICARIA
01-717-1201  TTDE12   19DEC13  0:00    19DEC2013    0  H        0     1  SKIN IRRITATION
```

## Messages

A wrong call writes the message and its fix to the log and stops. The macro also gives the [messages every macro shares](index.md#messages-every-macro-shares).

| Message | Fix |
|---|---|
| &lt;dsn&gt;=&lt;dsname&gt; does not exist | give &lt;dsn&gt;= a data set that exists (make it first). |
| censors=&lt;censors&gt; has no date | give censor_date= the date of a censoring in it. |
| time= and start_time= need end=, the end of the period | give end=, or give neither time= nor start_time=. |
| more than one record of the subject in subjects=&lt;subjects&gt; (with the USUBJID of the record) | give one record per subject. |

The macro also writes these NOTE lines to the log, without stopping:

- `NOTE: [tte] <nodate> subject(s) with no event and no censoring date: no record.`

## See also

ADaM steps: [%merge_subject](merge_subject.md), [%pick](pick.md), [%summarize](summarize.md), [%summarize_groups](summarize_groups.md), [%baseline](baseline.md), [%flag_first](flag_first.md), [%flag_if_any](flag_if_any.md), [%windows](windows.md), [%visits](visits.md), [%locf](locf.md), [%relchange](relchange.md), [%param_wide](param_wide.md), [%pool](pool.md).

Named on this page: [%km](km.md), [%logrank](logrank.md), [%cox](cox.md).

Guides that use %tte: [Make a Kaplan-Meier figure with the number at risk](../how-to/kaplan-meier-figure.md).

## Proof

Checked on its test cases of the time to an event, also within a period (small made-up records): every value the same as that of the expected records; ran on SAS 9.4 M9, 2026-11-12.

The known answers and test cases are kept with the development of the library, not in this repository.

The examples of this page ran on SAS 9.4 M9 on 2026-11-27, with a log free of ERROR and WARNING.

[Source of %tte](https://github.com/datastep-labs/sapling-sas/blob/main/macros/tte.sas)
