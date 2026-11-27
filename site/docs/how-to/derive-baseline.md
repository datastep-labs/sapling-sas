# Derive analysis visits, the baseline and the change from baseline

This guide shows how to derive the analysis variables of a BDS data set such as ADVS from its collected records: the
analysis visit of each record by its study day, the baseline flag, one analysis record per visit, the baseline value
and the change from baseline.

## Before you start

- Submit `examples/setup.sas`, or start your own program as [Use the macros in your own program](own-program.md)
  shows.
- Have the records with the value (`aval`) and the study day (`ady`), one row per measurement. The guide starts from
  the blood pressure records of `advs` and keeps only the collected variables.
- Have the visit windows and the baseline rule of the plan. The guide uses: baseline is the last value on or before
  day 1; Week 4, Week 12 and Week 24 are windows around their target days.

```sas
DATA vs;
  SET advs;
  WHERE paramcd IN ('SYSBP' 'DIABP');
  KEEP usubjid trt01a paramcd param adt ady aval vsseq;
RUN;
```

```text
vs: the first 5 of 5851 rows
USUBJID      TRT01A   ADT      ADY  PARAM                            PARAMCD  AVAL  VSSEQ
01-701-1015  Placebo  26DEC13   -7  Diastolic Blood Pressure (mmHg)  DIABP      64      1
01-701-1015  Placebo  31DEC13   -2  Diastolic Blood Pressure (mmHg)  DIABP      68      4
01-701-1015  Placebo  02JAN14    1  Diastolic Blood Pressure (mmHg)  DIABP      56      7
01-701-1015  Placebo  14JAN14   13  Diastolic Blood Pressure (mmHg)  DIABP      67     10
01-701-1015  Placebo  16JAN14   15  Diastolic Blood Pressure (mmHg)  DIABP      56     13
```

## Steps

### 1. Put each record in its analysis window

Call `%windows` with one window per analysis visit, `#` between the windows. A window is its number (`avisitn`), its
name, its first day, its last day, its target day and its range as printed. A period is a limit that is open:

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

`%windows` changes `vs` in place. It adds `avisit`, `avisitn`, the limits of the window and `awtdiff`, the distance
of the record from the target day. A record in no window keeps them missing.

### 2. Flag the baseline record

Call `%flag_first` on the records that can be the baseline, and choose the last one by the study day:

```sas
%flag_first(
     data  = vs
   , where = (ady <= 1 AND NOT MISSING(aval))
   , by    = usubjid paramcd
   , order = ady vsseq
   , which = last
   , new   = ablfl
 )
```

### 3. Flag one analysis record per visit

Call `%flag_first` again, by visit. The record nearest to the target day is chosen first. On a tie, the earlier
day wins, then the earlier record:

```sas
%flag_first(
     data  = vs
   , where = (NOT MISSING(avisitn) AND NOT MISSING(aval))
   , by    = usubjid paramcd avisitn
   , order = awtdiff ady vsseq
   , new   = anl01fl
 )
```

### 4. Give every record its baseline value

Call `%baseline`. It copies `aval` of the record with `ablfl = 'Y'` to every record of the subject and parameter:

```sas
%baseline(data=vs, value=aval, by=usubjid paramcd, new=base)
```

### 5. Compute the change from baseline

Compute the change in a DATA step, after the baseline visit only:

```sas
DATA vs;
  SET vs;
  IF avisitn > 0 AND NOT MISSING(base) THEN chg = aval - base;
RUN;
```

```text
vs where usubjid = '01-701-1015' AND paramcd = 'SYSBP': 15 rows
USUBJID      PARAMCD  ADY  AVISIT    AWTDIFF  AVAL  ABLFL  ANL01FL  BASE  CHG
01-701-1015  SYSBP     -7  Baseline        8   131                   130
01-701-1015  SYSBP     -2  Baseline        3   138                   130
01-701-1015  SYSBP      1  Baseline        0   130  Y      Y         130
01-701-1015  SYSBP     13  Week 4         15   137                   130    7
01-701-1015  SYSBP     15  Week 4         13   114                   130  -16
01-701-1015  SYSBP     29  Week 4          1   138         Y         130    8
01-701-1015  SYSBP     31  Week 4          3   138                   130    8
01-701-1015  SYSBP     42  Week 4         14   148                   130   18
01-701-1015  SYSBP     63  Week 12        21   138                   130    8
01-701-1015  SYSBP     84  Week 12         0   139         Y         130    9
01-701-1015  SYSBP     84  Week 12         0   139                   130    9
01-701-1015  SYSBP    126  Week 12        42   163                   130   33
01-701-1015  SYSBP    140  Week 24        28   137                   130    7
01-701-1015  SYSBP    168  Week 24         0   129         Y         130   -1
01-701-1015  SYSBP    182  Week 24        14   127                   130   -3
```

Each window has one record with `anl01fl = 'Y'`: the one an analysis of the visit uses. The baseline record has both
flags.

## Related

- Reference: [%windows](../reference/windows.md), [%flag_first](../reference/flag_first.md),
  [%baseline](../reference/baseline.md), [%visits](../reference/visits.md), [%locf](../reference/locf.md),
  [%relchange](../reference/relchange.md).
- How-to: [Make an efficacy table with an ANCOVA](efficacy-table.md) uses `base`, `chg` and `anl01fl`.
