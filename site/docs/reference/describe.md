# %describe

Returns the descriptive statistics of a numeric variable in each group: n, mean, SD, median, minimum and maximum.

**Procedure:** PROC MEANS · **Family:** [Describe the data](index.md#describe)

## Syntax

```sas
%describe(
     data    =
   , where   =
   , var     =
   , by      =
   , keep    =
   , total   = no
   , qntldef = 5
   , stats   = n="XX" mean="XX.X" sd="XX.XX" median="XX.X" min="XX" max="XX"
   , label   =
   , out     =
   , debug   = no
 )
```

## Parameters

<a id="data"></a>`data=`
:   The input data set. *(required)*

<a id="where"></a>`where=`
:   The records to use: a condition in parentheses, such as `where = (anl01fl = 'Y')`. When not given, all records are used. *(optional)*

<a id="var"></a>`var=`
:   The variable to describe: one numeric variable. *(required)*

<a id="by"></a>`by=`
:   The groups: one variable or several, separated by blanks. The first variable gives the columns of the table; the others give its rows, such as a parameter and a visit (`by = trt01a paramcd avisit`). *(required)*

<a id="keep"></a>`keep=`
:   Other variables to keep in the result, separated by blanks, for the names and the order of the rows (`keep = param avisitn`). Each gets its largest value in the group (the ID statement of PROC MEANS). *(optional)*

<a id="total"></a>`total=`
:   yes: add the group "Total", all groups of the first BY variable together. A text in quotes gives the Total another name ("All subjects"). A record with a missing group is counted in no group and not in the Total. *(optional, default `no`)*

<a id="qntldef"></a>`qntldef=`
:   The definition of the quantiles: a number from 1 to 5, as QNTLDEF= of PROC MEANS (5 is the default of SAS). *(optional, default `5`)*

<a id="stats"></a>`stats=`
:   The statistics, in the order of the rows: each name with its pattern of the printed number, separated by blanks. The names are n, mean, sd, median, min, max, q1, q3 and se. A name without a pattern takes its default pattern: XX for n, min and max; XX.X for mean, median, q1 and q3; XX.XX for sd and se. *(optional, default `n="XX" mean="XX.X" sd="XX.XX" median="XX.X" min="XX" max="XX"`)*

<a id="label"></a>`label=`
:   The label of the block in the table: a text in quotes. A block is the rows of one call in the table. *(optional)*

<a id="out"></a>`out=`
:   The name of the result data set. *(required)*

<a id="debug"></a>`debug=`
:   yes: keep the work data sets _describe_*. *(optional, default `no`)*
    Accepts: `yes`, `no`.

## Result

The data set of `out=`: the [result shape](../explanation/result-shape.md), one row per group and statistic: the BY variables, the variables of `keep=`, GROUPS, BLOCK, STAT, VALUE and TEXT. A group with no value has no row. When no record has a value, the result has no row and the log has the NOTE "No data qualified".

## Details

Use [%freq](freq.md) for the subjects of each category of a variable. Only the values that are not missing count. Q1, Q3 and the standard error come when `stats=` asks for them. The default pattern of min and max is XX, a whole number: a lab value of 3.9 prints as 4. Give min="XX.X" max="XX.X" in `stats=` for values with decimals.

## Examples

The examples run on the [example data](../tutorial/index.md#the-example-data) after `examples/setup.sas`. The output under each call is the output of that run. All examples of the reference run as one program: [examples/reference.sas](https://github.com/datastep-labs/sapling-sas/blob/main/examples/reference.sas).

<a id="ex-age_describe"></a>

Summarizes age in each group and in the Total: n, mean, SD, median, minimum and maximum.

```sas
%describe(
     data  = adsl
   , var   = age
   , by    = trt01a
   , total = yes
   , label = "Age (years)"
   , out   = age_describe
 )
```

```text
age_describe: the first 15 of 24 rows
TRT01A                GROUPS  BLOCK        STAT           VALUE  TEXT
Placebo               TRT01A  Age (years)  n                 86    86
Placebo               TRT01A  Age (years)  mean    75.209302326  75.2
Placebo               TRT01A  Age (years)  sd      8.5901671271  8.59
Placebo               TRT01A  Age (years)  median            76  76.0
Placebo               TRT01A  Age (years)  min               52    52
Placebo               TRT01A  Age (years)  max               89    89
Total                 TRT01A  Age (years)  n                254   254
Total                 TRT01A  Age (years)  mean    75.086614173  75.1
Total                 TRT01A  Age (years)  sd      8.2462338962  8.25
Total                 TRT01A  Age (years)  median            77  77.0
Total                 TRT01A  Age (years)  min               51    51
Total                 TRT01A  Age (years)  max               89    89
Xanomeline High Dose  TRT01A  Age (years)  n                 72    72
Xanomeline High Dose  TRT01A  Age (years)  mean    73.777777778  73.8
Xanomeline High Dose  TRT01A  Age (years)  sd      7.9438562002  7.94
```

<a id="ex-vs"></a>

Uses three BY variables: one row per group, parameter, visit and statistic, with PARAM kept.

```sas
%describe(
     data  = advs
   , where = (anl01fl = 'Y')
   , var   = aval
   , by    = trt01a paramcd avisit
   , keep  = param avisitn
   , out   = vs
 )
```

```text
vs: the first 15 of 540 rows
TRT01A   PARAMCD  AVISIT            PARAM                            AVISITN  GROUPS                 BLOCK  STAT           VALUE   TEXT
Placebo  DIABP    End of Treatment  Diastolic Blood Pressure (mmHg)       99  TRT01A PARAMCD AVISIT         n                 74     74
Placebo  DIABP    End of Treatment  Diastolic Blood Pressure (mmHg)       99  TRT01A PARAMCD AVISIT         mean    73.054054054   73.1
Placebo  DIABP    End of Treatment  Diastolic Blood Pressure (mmHg)       99  TRT01A PARAMCD AVISIT         sd      10.172339465  10.17
Placebo  DIABP    End of Treatment  Diastolic Blood Pressure (mmHg)       99  TRT01A PARAMCD AVISIT         median            72   72.0
Placebo  DIABP    End of Treatment  Diastolic Blood Pressure (mmHg)       99  TRT01A PARAMCD AVISIT         min               50     50
Placebo  DIABP    End of Treatment  Diastolic Blood Pressure (mmHg)       99  TRT01A PARAMCD AVISIT         max               99     99
Placebo  DIABP    Week 12           Diastolic Blood Pressure (mmHg)       12  TRT01A PARAMCD AVISIT         n                 68     68
Placebo  DIABP    Week 12           Diastolic Blood Pressure (mmHg)       12  TRT01A PARAMCD AVISIT         mean    72.588235294   72.6
Placebo  DIABP    Week 12           Diastolic Blood Pressure (mmHg)       12  TRT01A PARAMCD AVISIT         sd      10.314799242  10.31
Placebo  DIABP    Week 12           Diastolic Blood Pressure (mmHg)       12  TRT01A PARAMCD AVISIT         median            72   72.0
Placebo  DIABP    Week 12           Diastolic Blood Pressure (mmHg)       12  TRT01A PARAMCD AVISIT         min               50     50
Placebo  DIABP    Week 12           Diastolic Blood Pressure (mmHg)       12  TRT01A PARAMCD AVISIT         max               99     99
Placebo  DIABP    Week 16           Diastolic Blood Pressure (mmHg)       16  TRT01A PARAMCD AVISIT         n                 67     67
Placebo  DIABP    Week 16           Diastolic Blood Pressure (mmHg)       16  TRT01A PARAMCD AVISIT         mean    74.253731343   74.3
Placebo  DIABP    Week 16           Diastolic Blood Pressure (mmHg)       16  TRT01A PARAMCD AVISIT         sd      10.359219702  10.36
```

<a id="ex-wt_describe"></a>

Adds the SE, Q1 and Q3 and calls the Total All subjects: the rows keep the order of stats=.

```sas
%describe(
     data  = advs
   , where = (paramcd = 'WEIGHT' AND ablfl = 'Y')
   , var   = aval
   , by    = trt01a
   , total = "All subjects"
   , stats = n mean sd se median q1 q3 min="XX.X" max="XX.X"
   , label = "Weight at baseline (kg)"
   , out   = wt_describe
 )
```

```text
wt_describe: the first 15 of 36 rows
TRT01A        GROUPS  BLOCK                    STAT           VALUE   TEXT
All subjects  TRT01A  Weight at baseline (kg)  n                254    254
All subjects  TRT01A  Weight at baseline (kg)  mean    66.595393701   66.6
All subjects  TRT01A  Weight at baseline (kg)  sd      14.123258074  14.12
All subjects  TRT01A  Weight at baseline (kg)  se      0.8861720266   0.89
All subjects  TRT01A  Weight at baseline (kg)  median        66.455   66.5
All subjects  TRT01A  Weight at baseline (kg)  q1             55.34   55.3
All subjects  TRT01A  Weight at baseline (kg)  q3             77.11   77.1
All subjects  TRT01A  Weight at baseline (kg)  min            34.02   34.0
All subjects  TRT01A  Weight at baseline (kg)  max           107.96  108.0
Placebo       TRT01A  Weight at baseline (kg)  n                 86     86
Placebo       TRT01A  Weight at baseline (kg)  mean     62.75744186   62.8
Placebo       TRT01A  Weight at baseline (kg)  sd      12.770388007  12.77
Placebo       TRT01A  Weight at baseline (kg)  se      1.3770663537   1.38
Placebo       TRT01A  Weight at baseline (kg)  median         60.56   60.6
Placebo       TRT01A  Weight at baseline (kg)  q1             53.52   53.5
```

<a id="ex-age_sex"></a>

Adds sex as a second BY variable: the rows of each group and sex, for a page per sex.

```sas
%describe(
     data  = adsl
   , var   = age
   , by    = trt01a sex
   , total = yes
   , label = "Age (years)"
   , out   = age_sex
 )
```

```text
age_sex: the first 15 of 48 rows
TRT01A   SEX  GROUPS      BLOCK        STAT           VALUE  TEXT
Placebo  F    TRT01A SEX  Age (years)  n                 53    53
Placebo  F    TRT01A SEX  Age (years)  mean    76.358490566  76.4
Placebo  F    TRT01A SEX  Age (years)  sd      8.7334334151  8.73
Placebo  F    TRT01A SEX  Age (years)  median            78  78.0
Placebo  F    TRT01A SEX  Age (years)  min               59    59
Placebo  F    TRT01A SEX  Age (years)  max               89    89
Placebo  M    TRT01A SEX  Age (years)  n                 33    33
Placebo  M    TRT01A SEX  Age (years)  mean    73.363636364  73.4
Placebo  M    TRT01A SEX  Age (years)  sd      8.1463879335  8.15
Placebo  M    TRT01A SEX  Age (years)  median            74  74.0
Placebo  M    TRT01A SEX  Age (years)  min               52    52
Placebo  M    TRT01A SEX  Age (years)  max               85    85
Total    F    TRT01A SEX  Age (years)  n                143   143
Total    F    TRT01A SEX  Age (years)  mean     75.65034965  75.7
Total    F    TRT01A SEX  Age (years)  sd       8.193314641  8.19
```

## Messages

A wrong call writes the message and its fix to the log and stops. The macro also gives the [messages every macro shares](index.md#messages-every-macro-shares).

| Message | Fix |
|---|---|
| var=&lt;var&gt; is not numeric | give var= a numeric variable. |
| total= needs a character group first in by= (&lt;first&gt; is numeric) | give by= a character group first, or total=no. |

## See also

Describe the data: [%freq](freq.md), [%proportion](proportion.md), [%rate](rate.md), [%worst](worst.md), [%termflags](termflags.md).

Guides that use %describe: [Tutorial: your first table](../tutorial/index.md), [Check a table against an independent program](../how-to/check-a-table.md), [Make a demographic table with tests](../how-to/demographic-table.md), [Make an efficacy table with an ANCOVA](../how-to/efficacy-table.md), [Use the macros in your own program](../how-to/own-program.md), [Make one page per subgroup](../how-to/page-per-subgroup.md).

## Proof

Checked against its known answer (on a small data set, the numbers worked out independently in R); ran on SAS 9.4 M9, 2026-11-12.

The known answers and test cases are kept with the development of the library, not in this repository.

The examples of this page ran on SAS 9.4 M9 on 2026-11-27, with a log free of ERROR and WARNING.

Used in the proof against pharmaverse: [t14_2_01](https://github.com/datastep-labs/sapling-sas/blob/main/proof/pilot1/programs/t14_2_01.sas) (R Submission Pilot 1), [t14_3_01](https://github.com/datastep-labs/sapling-sas/blob/main/proof/pilot1/programs/t14_3_01.sas) (R Submission Pilot 1), [t14_3_02](https://github.com/datastep-labs/sapling-sas/blob/main/proof/pilot1/programs/t14_3_02.sas) (R Submission Pilot 1), [demographic](https://github.com/datastep-labs/sapling-sas/blob/main/proof/pharmaverse/programs/demographic.sas) (pharmaverse examples). See [what the proof shows](../explanation/proof.md).

[Source of %describe](https://github.com/datastep-labs/sapling-sas/blob/main/macros/describe.sas)
