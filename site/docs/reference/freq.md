# %freq

Counts the subjects in each category and group, with their percent of the subjects of the group.

**Procedure:** PROC FREQ · **Family:** [Describe the data](index.md#describe)

## Syntax

```sas
%freq(
     data      =
   , denom     =
   , where     =
   , var       =
   , by        =
   , keep      =
   , levels    =
   , total     = no
   , threshold =
   , order     =
   , orderof   =
   , orderby   =
   , stats     = n="XX" pct="(XX.X%)"
   , label     =
   , out       =
   , debug     = no
 )
```

## Parameters

<a id="data"></a>`data=`
:   The input data set: the records to count, with USUBJID. *(required)*

<a id="denom"></a>`denom=`
:   The subjects of each group: the N of the percent and the columns. A data set with one row per subject and the variables of `by=`; data set options are allowed: `adsl(where=(saffl = 'Y'))`. When not given, the subjects of `data=` (without `where=`). *(optional)*

<a id="where"></a>`where=`
:   The records to count: a condition in parentheses, such as `where = (trtemfl = 'Y')`. *(optional)*

<a id="var"></a>`var=`
:   The categories: one variable or several, separated by blanks, nested in their order (`var = aebodsys aedecod`: a term within its class). When not given, the macro counts the subjects with any record. *(optional)*

<a id="by"></a>`by=`
:   The groups: one variable or several, separated by blanks. The first variable gives the columns of the table; the others give its rows or its pages (`by = trt01a sex`, with `page=` of [%layout](layout.md)). *(required)*

<a id="keep"></a>`keep=`
:   Other variables to keep with the categories for their names and order, separated by blanks. PARAM and PARAMN go with PARAMCD, AVISITN with AVISIT, any &lt;V&gt;N with V. Each gets the value of the first record of its category. *(optional)*

<a id="levels"></a>`levels=`
:   The planned categories of some variables of `var=`: each variable followed by its values in quotes (`levels = bnrind 'LOW' 'NORMAL' 'HIGH'`). A planned category shows also without a subject; a record of another category is not counted. The rows of a planned variable V follow the order given, through its twin VN (1, 2 ...) in `out=`, unless `keep=` has VN. The categories of the other variables come from the records counted. *(optional)*

<a id="total"></a>`total=`
:   yes: add the group "Total", all groups of the first BY variable together. A text in quotes gives the Total another name ("All subjects"). The first BY variable must be character. *(optional, default `no`)*

<a id="threshold"></a>`threshold=`
:   A percent (`threshold = 5`): keep only the categories with this percent of the subjects or more in at least one group (the Total counts as a group). The macro compares the percent itself, not its rounded text. *(optional)*

<a id="order"></a>`order=`
:   frequency: order the rows of `orderof=` by their subjects, the most first, and equal counts by their value. The rank goes into the twin &lt;V&gt;N, and [%print](print.md) orders the rows by it. When not given, the rows are in the order of the values. *(optional)*

<a id="orderof"></a>`orderof=`
:   The variable of `var=` whose rows order=frequency ranks: one variable. When not given, the last variable of `var=`. *(optional)*

<a id="orderby"></a>`orderby=`
:   The group whose subjects rank the rows for order=frequency: a value of the first BY variable, in quotes (`orderby = "Placebo"`). When not given, all groups together, without the Total. *(optional)*

<a id="stats"></a>`stats=`
:   The statistics, in the order of the rows: each name with its pattern of the printed number, separated by blanks. The names are n, pct and events. A name without a pattern takes its default pattern: see the [table of default patterns](../explanation/numbers.md#the-table-of-default-patterns). *(optional, default `n="XX" pct="(XX.X%)"`)*

<a id="label"></a>`label=`
:   The label of the block in the table: a text in quotes. A block is the rows of one call in the table. *(optional)*

<a id="out"></a>`out=`
:   The name of the result data set. *(required)*

<a id="debug"></a>`debug=`
:   yes: keep the work data sets _freq_*. *(optional, default `no`)*
    Accepts: `yes`, `no`.

## Result

The data set of `out=`: the [result shape](../explanation/result-shape.md), one row per group, category and statistic: the variables of `by=` and `var=`, the variables of `keep=`, GROUPS, BLOCK, STAT, VALUE and TEXT. Every group of `denom=` has every category: `n = 0` when no subject has it. With `levels=`, the twin &lt;V&gt;N of each planned variable gives its place in `levels=`; with order=frequency, the twin of `orderof=` gives the rank.

## Details

Use [%proportion](proportion.md) when the percent needs a confidence interval, and [%worst](worst.md) for the worst grade of each subject. A subject is counted once in each cell. A record with a missing group or category is not counted. The percent is of the subjects of the group in `denom=`. Without `var=`, the macro counts the subjects with any record. The name events in `stats=` adds the number of records of each cell.

## Examples

The examples run on the [example data](../tutorial/index.md#the-example-data) after `examples/setup.sas`. The output under each call is the output of that run. All examples of the reference run as one program: [examples/reference.sas](https://github.com/datastep-labs/sapling-sas/blob/main/examples/reference.sas).

<a id="ex-sex_freq"></a>

Counts each sex in each group and in the Total: n and the percent of the subjects of the group.

```sas
%freq(
     data  = adsl
   , var   = sex
   , by    = trt01a
   , total = yes
   , label = "Sex"
   , out   = sex_freq
 )
```

```text
sex_freq: the first 15 of 16 rows
TRT01A                SEX  GROUPS      BLOCK  STAT         VALUE  TEXT
Placebo               F    TRT01A SEX  Sex    n               53  53
Placebo               F    TRT01A SEX  Sex    pct   61.627906977  (61.6%)
Placebo               M    TRT01A SEX  Sex    n               33  33
Placebo               M    TRT01A SEX  Sex    pct   38.372093023  (38.4%)
Total                 F    TRT01A SEX  Sex    n              143  143
Total                 F    TRT01A SEX  Sex    pct   56.299212598  (56.3%)
Total                 M    TRT01A SEX  Sex    n              111  111
Total                 M    TRT01A SEX  Sex    pct   43.700787402  (43.7%)
Xanomeline High Dose  F    TRT01A SEX  Sex    n               35  35
Xanomeline High Dose  F    TRT01A SEX  Sex    pct   48.611111111  (48.6%)
Xanomeline High Dose  M    TRT01A SEX  Sex    n               37  37
Xanomeline High Dose  M    TRT01A SEX  Sex    pct   51.388888889  (51.4%)
Xanomeline Low Dose   F    TRT01A SEX  Sex    n               55  55
Xanomeline Low Dose   F    TRT01A SEX  Sex    pct   57.291666667  (57.3%)
Xanomeline Low Dose   M    TRT01A SEX  Sex    n               41  41
```

<a id="ex-teae"></a>

Counts subjects and events of each term under its class: the percent uses the N of denom=.

```sas
%freq(
     data  = adae
   , denom = adsl
   , where = (trtemfl = 'Y')
   , var   = aebodsys aedecod
   , by    = trt01a
   , stats = n pct events
   , out   = teae
 )
```

```text
teae: the first 15 of 2070 rows
TRT01A   AEBODSYS           AEDECOD                               GROUPS                   BLOCK  STAT           VALUE  TEXT
Placebo  CARDIAC DISORDERS  ATRIAL FIBRILLATION                   TRT01A AEBODSYS AEDECOD         n                  1  1
Placebo  CARDIAC DISORDERS  ATRIAL FIBRILLATION                   TRT01A AEBODSYS AEDECOD         pct     1.1627906977  ( 1.2%)
Placebo  CARDIAC DISORDERS  ATRIAL FIBRILLATION                   TRT01A AEBODSYS AEDECOD         events             1  1
Placebo  CARDIAC DISORDERS  ATRIAL FLUTTER                        TRT01A AEBODSYS AEDECOD         n                  0  0
Placebo  CARDIAC DISORDERS  ATRIAL FLUTTER                        TRT01A AEBODSYS AEDECOD         pct                0  ( 0.0%)
Placebo  CARDIAC DISORDERS  ATRIAL FLUTTER                        TRT01A AEBODSYS AEDECOD         events             0  0
Placebo  CARDIAC DISORDERS  ATRIAL HYPERTROPHY                    TRT01A AEBODSYS AEDECOD         n                  1  1
Placebo  CARDIAC DISORDERS  ATRIAL HYPERTROPHY                    TRT01A AEBODSYS AEDECOD         pct     1.1627906977  ( 1.2%)
Placebo  CARDIAC DISORDERS  ATRIAL HYPERTROPHY                    TRT01A AEBODSYS AEDECOD         events             2  2
Placebo  CARDIAC DISORDERS  ATRIOVENTRICULAR BLOCK FIRST DEGREE   TRT01A AEBODSYS AEDECOD         n                  1  1
Placebo  CARDIAC DISORDERS  ATRIOVENTRICULAR BLOCK FIRST DEGREE   TRT01A AEBODSYS AEDECOD         pct     1.1627906977  ( 1.2%)
Placebo  CARDIAC DISORDERS  ATRIOVENTRICULAR BLOCK FIRST DEGREE   TRT01A AEBODSYS AEDECOD         events             1  1
Placebo  CARDIAC DISORDERS  ATRIOVENTRICULAR BLOCK SECOND DEGREE  TRT01A AEBODSYS AEDECOD         n                  1  1
Placebo  CARDIAC DISORDERS  ATRIOVENTRICULAR BLOCK SECOND DEGREE  TRT01A AEBODSYS AEDECOD         pct     1.1627906977  ( 1.2%)
Placebo  CARDIAC DISORDERS  ATRIOVENTRICULAR BLOCK SECOND DEGREE  TRT01A AEBODSYS AEDECOD         events             1  1
```

<a id="ex-shift"></a>

Counts the shift at Week 24 with planned levels: a level without a subject has a row of 0.

```sas
%freq(
     data   = adlb
   , denom  = adsl
   , where  = (avisit = 'Week 24')
   , var    = paramcd bnrind anrind
   , by     = trt01a
   , levels = bnrind 'LOW' 'NORMAL' 'HIGH' anrind 'LOW' 'NORMAL' 'HIGH'
   , out    = shift
 )
```

```text
shift: the first 15 of 108 rows
TRT01A   PARAMCD  BNRIND  ANRIND  BNRINDN  ANRINDN  GROUPS                        BLOCK  STAT         VALUE  TEXT
Placebo  ALT      HIGH    HIGH          3        3  TRT01A PARAMCD BNRIND ANRIND         n                0  0
Placebo  ALT      HIGH    HIGH          3        3  TRT01A PARAMCD BNRIND ANRIND         pct              0  ( 0.0%)
Placebo  ALT      HIGH    LOW           3        1  TRT01A PARAMCD BNRIND ANRIND         n                0  0
Placebo  ALT      HIGH    LOW           3        1  TRT01A PARAMCD BNRIND ANRIND         pct              0  ( 0.0%)
Placebo  ALT      HIGH    NORMAL        3        2  TRT01A PARAMCD BNRIND ANRIND         n                3  3
Placebo  ALT      HIGH    NORMAL        3        2  TRT01A PARAMCD BNRIND ANRIND         pct    3.488372093  ( 3.5%)
Placebo  ALT      LOW     HIGH          1        3  TRT01A PARAMCD BNRIND ANRIND         n                0  0
Placebo  ALT      LOW     HIGH          1        3  TRT01A PARAMCD BNRIND ANRIND         pct              0  ( 0.0%)
Placebo  ALT      LOW     LOW           1        1  TRT01A PARAMCD BNRIND ANRIND         n                0  0
Placebo  ALT      LOW     LOW           1        1  TRT01A PARAMCD BNRIND ANRIND         pct              0  ( 0.0%)
Placebo  ALT      LOW     NORMAL        1        2  TRT01A PARAMCD BNRIND ANRIND         n                0  0
Placebo  ALT      LOW     NORMAL        1        2  TRT01A PARAMCD BNRIND ANRIND         pct              0  ( 0.0%)
Placebo  ALT      NORMAL  HIGH          2        3  TRT01A PARAMCD BNRIND ANRIND         n                2  2
Placebo  ALT      NORMAL  HIGH          2        3  TRT01A PARAMCD BNRIND ANRIND         pct   2.3255813953  ( 2.3%)
Placebo  ALT      NORMAL  LOW           2        1  TRT01A PARAMCD BNRIND ANRIND         n                1  1
```

<a id="ex-common"></a>

Keeps the terms that reach 5 percent in a group: AEDECODN ranks them, the most subjects first.

```sas
%freq(
     data      = adae
   , denom     = adsl
   , where     = (trtemfl = 'Y')
   , var       = aedecod
   , by        = trt01a
   , threshold = 5
   , order     = frequency
   , out       = common
 )
```

```text
common: the first 15 of 144 rows
TRT01A   AEDECOD                      AEDECODN  GROUPS          BLOCK  STAT         VALUE  TEXT
Placebo  APPLICATION SITE DERMATITIS         6  TRT01A AEDECOD         n                5  5
Placebo  APPLICATION SITE DERMATITIS         6  TRT01A AEDECOD         pct   5.8139534884  ( 5.8%)
Placebo  APPLICATION SITE ERYTHEMA           4  TRT01A AEDECOD         n                3  3
Placebo  APPLICATION SITE ERYTHEMA           4  TRT01A AEDECOD         pct    3.488372093  ( 3.5%)
Placebo  APPLICATION SITE IRRITATION         7  TRT01A AEDECOD         n                3  3
Placebo  APPLICATION SITE IRRITATION         7  TRT01A AEDECOD         pct    3.488372093  ( 3.5%)
Placebo  APPLICATION SITE PRURITUS           2  TRT01A AEDECOD         n                6  6
Placebo  APPLICATION SITE PRURITUS           2  TRT01A AEDECOD         pct    6.976744186  ( 7.0%)
Placebo  APPLICATION SITE VESICLES          16  TRT01A AEDECOD         n                1  1
Placebo  APPLICATION SITE VESICLES          16  TRT01A AEDECOD         pct   1.1627906977  ( 1.2%)
Placebo  BLISTER                            24  TRT01A AEDECOD         n                0  0
Placebo  BLISTER                            24  TRT01A AEDECOD         pct              0  ( 0.0%)
Placebo  COUGH                              17  TRT01A AEDECOD         n                1  1
Placebo  COUGH                              17  TRT01A AEDECOD         pct   1.1627906977  ( 1.2%)
Placebo  DIARRHOEA                           9  TRT01A AEDECOD         n                9  9
```

<a id="ex-agegr_sex"></a>

Adds sex as a second BY variable: the age groups of each group and sex, for a page per sex.

```sas
%freq(
     data  = adsl
   , var   = agegr1
   , by    = trt01a sex
   , total = yes
   , label = "Age group"
   , out   = agegr_sex
 )
```

```text
agegr_sex: the first 15 of 32 rows
TRT01A   SEX  AGEGR1  GROUPS             BLOCK      STAT         VALUE  TEXT
Placebo  F    18-64   TRT01A SEX AGEGR1  Age group  n                9  9
Placebo  F    18-64   TRT01A SEX AGEGR1  Age group  pct   16.981132075  (17.0%)
Placebo  F    >64     TRT01A SEX AGEGR1  Age group  n               44  44
Placebo  F    >64     TRT01A SEX AGEGR1  Age group  pct   83.018867925  (83.0%)
Placebo  M    18-64   TRT01A SEX AGEGR1  Age group  n                5  5
Placebo  M    18-64   TRT01A SEX AGEGR1  Age group  pct   15.151515152  (15.2%)
Placebo  M    >64     TRT01A SEX AGEGR1  Age group  n               28  28
Placebo  M    >64     TRT01A SEX AGEGR1  Age group  pct   84.848484848  (84.8%)
Total    F    18-64   TRT01A SEX AGEGR1  Age group  n               19  19
Total    F    18-64   TRT01A SEX AGEGR1  Age group  pct   13.286713287  (13.3%)
Total    F    >64     TRT01A SEX AGEGR1  Age group  n              124  124
Total    F    >64     TRT01A SEX AGEGR1  Age group  pct   86.713286713  (86.7%)
Total    M    18-64   TRT01A SEX AGEGR1  Age group  n               14  14
Total    M    18-64   TRT01A SEX AGEGR1  Age group  pct   12.612612613  (12.6%)
Total    M    >64     TRT01A SEX AGEGR1  Age group  n               97  97
```

## Messages

A wrong call writes the message and its fix to the log and stops. The macro also gives the [messages every macro shares](index.md#messages-every-macro-shares).

| Message | Fix |
|---|---|
| total= needs a character group first in by= (&lt;first&gt; is numeric) | give by= a character group first (TRT01A), or total=no. |
| levels= names the variable &lt;w&gt;, and var=&lt;var&gt; does not have it. | give levels= variables of var= only, or add &lt;w&gt; to var=. |

The macro also writes these NOTE lines to the log, without stopping:

- `NOTE: [freq] No data qualified: no record meets where= and the conditions of the macro.`

## See also

Describe the data: [%describe](describe.md), [%proportion](proportion.md), [%rate](rate.md), [%worst](worst.md), [%termflags](termflags.md).

Named on this page: [%layout](layout.md), [%print](print.md).

Guides that use %freq: [Tutorial: your first table](../tutorial/index.md), [Make an adverse event table](../how-to/adverse-event-table.md), [Check a table against an independent program](../how-to/check-a-table.md), [Make a demographic table with tests](../how-to/demographic-table.md), [Make one page per subgroup](../how-to/page-per-subgroup.md).

## Proof

Checked against its known answers: the counts and the percents of the subjects (on a small data set, the numbers worked out independently in R); ran on SAS 9.4 M9, 2026-11-12.

The known answers and test cases are kept with the development of the library, not in this repository.

The examples of this page ran on SAS 9.4 M9 on 2026-11-27, with a log free of ERROR and WARNING.

Used in the proof against pharmaverse: [t14_2_01](https://github.com/datastep-labs/sapling-sas/blob/main/proof/pilot1/programs/t14_2_01.sas) (R Submission Pilot 1), [adverse_events](https://github.com/datastep-labs/sapling-sas/blob/main/proof/pharmaverse/programs/adverse_events.sas) (pharmaverse examples), [demographic](https://github.com/datastep-labs/sapling-sas/blob/main/proof/pharmaverse/programs/demographic.sas) (pharmaverse examples). See [what the proof shows](../explanation/proof.md).

[Source of %freq](https://github.com/datastep-labs/sapling-sas/blob/main/macros/freq.sas)
