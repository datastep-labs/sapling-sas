# %table_visit

Makes a table of the descriptive statistics of each variable by group, parameter and visit in one call.

**Procedure:** none of its own (those of %describe, %table) · **Family:** [Tables in one call](index.md#onecall)

## Syntax

```sas
%table_visit(
     data      =
   , adsl      =
   , pop       =
   , where     =
   , vars      =
   , by        =
   , param     = PARAMCD
   , visit     = AVISIT
   , keep      =
   , order     =
   , post      =
   , postwhere = (ablfl NE 'Y')
   , names     =
   , total     = no
   , format    =
   , name      =
   , show      = no
   , stats     =
   , title     =
   , footnote  =
   , file      =
   , debug     = no
 )
```

## Parameters

`data=`
:   The input data set: the records, with USUBJID. *(required)*

`adsl=`
:   The subjects: a data set with one row per subject. It gives the population and the N of each column, and its variables are merged onto the records by USUBJID. When not given, the N of a column is the subjects of its records. *(optional)*

`pop=`
:   The population: a condition on `adsl=` in parentheses, such as `pop = (saffl = 'Y')`. It is used only with `adsl=`. *(optional)*

`where=`
:   The records to use: a condition in parentheses, such as `where = (trtemfl = 'Y')`. *(optional)*

`vars=`
:   The numeric variables to describe, separated by blanks: one block each, such as `vars = aval chg`. *(required)*

`by=`
:   The groups of the columns: one character variable, such as `by = trt01a`. *(required)*

`param=`
:   The variable of the parameter: one variable. *(optional, default `PARAMCD`)*

`visit=`
:   The variable of the visit: one variable. *(optional, default `AVISIT`)*

`keep=`
:   Other variables to keep for the names and the order of the rows, separated by blanks (keep= of [%describe](describe.md)), such as `keep = param paramn avisitn`. *(optional)*

`order=`
:   The numeric twin of `by=`, such as `order = trt01an`: it gives the order of the columns. *(optional)*

`post=`
:   The variables of `vars=` whose block uses only the records of `postwhere=`, separated by blanks, such as `post = chg`. *(optional)*

`postwhere=`
:   The records after baseline: a condition in parentheses. *(optional, default `(ablfl NE 'Y')`)*

`names=`
:   The labels of the blocks: pairs variable="text", separated by blanks, such as `names = chg="Change from baseline"`. A block without a pair has the label of its variable, or its name. *(optional)*

`total=`
:   yes: add the column Total, all groups together. *(optional, default `no`)*
    Accepts: `yes`, `no`.

`format=`
:   The labels of the categories: pairs of a variable and a format, as in a FORMAT statement (`format = sex $sexf. race $racef.`), as `format=` of [%layout](layout.md). *(optional)*

`name=`
:   The name of the table: the first part of the names of its data sets, such as `name = t14_3_01`. When not given, the last part of `file=` is used; without `file=`, `name=` is required. *(optional)*

`show=`
:   yes: write the long program to the log. A file path, without quotes: write the long program to that file. In both cases the macro runs it. *(optional, default `no`)*

`stats=`
:   The statistics, each name with its pattern, separated by blanks (stats= of [%describe](describe.md)). *(optional)*

`title=`
:   The titles of the table: one text in quotes per line (TITLE1, TITLE2 ...). They hold for this table only. When not given, the TITLE statements in force in the program are used. *(optional)*

`footnote=`
:   The footnotes of the table: one text in quotes per line (FOOTNOTE1, FOOTNOTE2 ...). They hold for this table only. When not given, the FOOTNOTE statements in force in the program are used. *(optional)*

`file=`
:   The output file without its extension: the macro writes &lt;file&gt;.rtf, &lt;file&gt;.lst and the numbers file. When not given, nothing is printed. *(optional)*

`debug=`
:   yes: keep the work data sets of the macros that the long program calls. *(optional, default `no`)*
    Accepts: `yes`, `no`.

## Result

The data sets: &lt;name&gt;_&lt;variable&gt; (the result of each variable), &lt;name&gt; (the stacked results), &lt;name&gt;_cols, &lt;name&gt;_display, &lt;name&gt;_pop (with `adsl=`) and &lt;name&gt;_rec (with `adsl=` or `where=`). The files: &lt;file&gt;.rtf, &lt;file&gt;.lst and the numbers file (only with `file=`). The global macro variable: &lt;name&gt;_print. With `show=`: the long program, in the log or in a file.

## Details

Use it for vital signs or laboratory values over the visits; use [%table_summary](table_summary.md) for one row per subject, and [%table_model](table_model.md) for a model at one visit. A block is the rows of one variable of `vars=` in the table: one [%describe](describe.md) of the records with `by=` the group, the parameter and the visit. The long program is the program the macro writes and runs: the population, the records, one [%describe](describe.md) per variable, [%stack](stack.md) and [%table](table.md), the calls a person would write by hand. The macro computes nothing itself. These data sets stay in WORK, for a change and a second print:

- &lt;name&gt;_&lt;variable&gt;: the result of each variable, one row per number (the [result shape](../explanation/result-shape.md))
- &lt;name&gt;: the stacked results
- &lt;name&gt;_cols: the columns ([%columns](columns.md))
- &lt;name&gt;_display: the display data set, one row per printed line ([%layout](layout.md))

The global macro variable &lt;name&gt;_print keeps the call of [%print](print.md): change &lt;name&gt;_display, then print again with `%print(&<name>_print.)`.

## Examples

The examples run on the [example data](../tutorial/index.md#the-example-data) after `examples/setup.sas`. The output under each call is the output of that run. All examples of the reference run as one program: [examples/reference.sas](https://github.com/datastep-labs/sapling-sas/blob/main/examples/reference.sas).

Makes the table of the value at each visit and of its change after baseline.

```sas
%table_visit(
     data  = adam.advs
   , adsl  = adam.adsl
   , pop   = (saffl = 'Y')
   , where = (paramcd = 'SYSBP' AND (ablfl = 'Y' OR anl01fl = 'Y'))
   , vars  = aval chg
   , by    = trt01a
   , keep  = param paramn avisitn
   , order = trt01an
   , post  = chg
   , title = "Table 14.7.1 Systolic blood pressure by visit"
   , file  = &spl_out./tlf/t14_7_1
 )
```

```text
tlf/t14_7_1.lst: the first 40 of 122 lines
Table 14.7.1 Systolic blood pressure by visit

                                  Placebo        Xanomeline Low Dose  Xanomeline High Dose
                                  (N=86)         (N=96)               (N=72)
------------------------------------------------------------------------------------------

Analysis Value
  Systolic Blood Pressure (mmHg)
    Baseline
      n                           85             96                   72
      Mean (SD)                   138.6 (16.75)  139.8 (17.57)        139.0 (16.71)
      Median                      140.0          138.5                140.0
      Min, Max                    90, 180        100, 188             100, 180
    Week 2
      n                           83             75                   72
      Mean (SD)                   135.0 (16.09)  137.3 (17.50)        134.0 (14.88)
      Median                      132.0          137.0                133.0
      Min, Max                    96, 172        108, 190             106, 183
    Week 4
      n                           78             65                   67
      Mean (SD)                   135.0 (17.63)  136.1 (17.75)        134.4 (16.21)
      Median                      132.0          134.0                132.0
      Min, Max                    94, 182        102, 180             104, 181
    Week 6
      n                           74             59                   56
      Mean (SD)                   134.3 (18.14)  135.1 (16.94)        132.8 (16.73)
      Median                      131.5          132.0                130.0
      Min, Max                    100, 200       104, 195             100, 170
    Week 8
      n                           71             54                   51
      Mean (SD)                   137.9 (17.63)  136.1 (15.49)        135.2 (16.20)
      Median                      138.0          137.5                134.0
      Min, Max                    90, 189        100, 170             106, 188
    Week 12
      n                           68             41                   41
      Mean (SD)                   134.5 (14.35)  134.1 (15.76)        129.2 (15.50)
      Median                      132.0          135.0                130.0
      Min, Max                    100, 164       104, 170             100, 160
    Week 16
      n                           67             32                   33
```

Names the blocks, asks for Q1 and Q3 and adds a Total column.

```sas
%table_visit(
     data  = advs
   , adsl  = adsl
   , where = (paramcd = 'DIABP' AND (ablfl = 'Y' OR anl01fl = 'Y') AND avisitn IN (0 12 24))
   , vars  = aval chg
   , by    = trt01a
   , keep  = param paramn avisitn
   , order = trt01an
   , post  = chg
   , names = aval="Value" chg="Change from baseline"
   , total = yes
   , stats = n mean sd median q1 q3 min max
   , title = "Table 14.7.2 Diastolic blood pressure at Week 12 and Week 24"
   , file  = &spl_out./tlf/t14_7_2
 )
```

```text
tlf/t14_7_2.lst: the first 40 of 41 lines
Table 14.7.2 Diastolic blood pressure at Week 12 and Week 24

                                   Placebo       Xanomeline Low Dose  Xanomeline High Dose  Total
                                   (N=86)        (N=96)               (N=72)                (N=254)
--------------------------------------------------------------------------------------------------------

Value
  Diastolic Blood Pressure (mmHg)
    Baseline
      n                            85            96                   72                    253
      Mean (SD)                    75.7 (11.09)  76.5 (9.68)          77.1 (9.94)           76.4 (10.22)
      Median                       76.0          76.0                 78.0                  76.0
      Q1, Q3                       70.0, 84.0    70.0, 83.0           70.0, 84.0            70.0, 84.0
      Min, Max                     40, 99        57, 100              51, 98                40, 100
    Week 12
      n                            68            41                   41                    150
      Mean (SD)                    72.6 (10.31)  76.3 (11.49)         73.9 (9.15)           74.0 (10.40)
      Median                       72.0          78.0                 76.0                  74.0
      Q1, Q3                       66.5, 80.0    68.0, 86.0           68.0, 80.0            68.0, 80.0
      Min, Max                     50, 99        57, 100              56, 90                50, 100
    Week 24
      n                            59            25                   28                    112
      Mean (SD)                    72.9 (11.32)  75.8 (9.37)          74.5 (9.13)           74.0 (10.38)
      Median                       74.0          76.0                 74.5                  75.5
      Q1, Q3                       66.0, 80.0    70.0, 82.0           67.0, 80.0            68.0, 80.0
      Min, Max                     44, 109       60, 90               60, 92                44, 109

Change from baseline
  Diastolic Blood Pressure (mmHg)
    Week 12
      n                            68            41                   41                    150
      Mean (SD)                    -2.9 (8.88)   -1.1 (10.38)         -3.3 (10.45)          -2.5 (9.72)
      Median                       -3.5          0.0                  -2.0                  -2.0
      Q1, Q3                       -10.0, 2.5    -10.0, 4.0           -10.0, 0.0            -10.0, 3.0
      Min, Max                     -26, 20       -21, 26              -36, 20               -36, 26
    Week 24
      n                            59            25                   28                    112
      Mean (SD)                    -1.1 (10.91)  -0.8 (8.00)          -1.9 (9.37)           -1.2 (9.88)
      Median                       -1.0          -2.0                 -1.0                  -1.5
      Q1, Q3                       -10.0, 4.0    -6.0, 4.0            -8.0, 2.5             -8.0, 4.0
```

## Messages

A wrong call writes the message and its fix to the log and stops. The macro also gives the [messages every macro shares](index.md#messages-every-macro-shares).

| Message | Fix |
|---|---|
| name= is required when file= is blank. | give name=&lt;the name of the table&gt;, as t14_5_2. |
| adsl=&lt;ds&gt; does not exist. | give adsl= the data set of the subjects. |

## See also

Tables in one call: [%table](table.md), [%table_summary](table_summary.md), [%table_ae](table_ae.md), [%table_shift](table_shift.md), [%table_response](table_response.md), [%table_model](table_model.md), [%table_tte](table_tte.md).

Named on this page: [%describe](describe.md), [%layout](layout.md), [%stack](stack.md), [%columns](columns.md), [%print](print.md).

## Proof

Checked against its long program, written out by hand: the same display data set (PROC COMPARE), on a made-up study; ran on SAS 9.4 M9, 2026-11-13.

The examples of this page ran on SAS 9.4 M9 on 2026-11-27, with a log free of ERROR and WARNING.

[Source of %table_visit](https://github.com/datastep-labs/sapling-sas/blob/main/macros/table_visit.sas)
