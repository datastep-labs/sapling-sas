# %table_tte

Makes a time-to-event table in one call: the Kaplan-Meier summary, the log-rank test and the hazard ratios.

**Procedure:** none of its own (those of %km, %logrank, %cox, %table) · **Family:** [Tables in one call](index.md#onecall)

## Syntax

```sas
%table_tte(
     data     =
   , adsl     =
   , pop      =
   , where    =
   , var      = AVAL
   , cnsr     = CNSR
   , by       =
   , time     =
   , strata   =
   , order    =
   , pairs    =
   , format   =
   , name     =
   , show     = no
   , title    =
   , footnote =
   , file     =
   , debug    = no
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

`var=`
:   The time: one numeric variable. *(optional, default `AVAL`)*

`cnsr=`
:   The censoring variable: one numeric variable, 0 for an event and a positive value for a censoring (the ADaM CNSR: 1, 2 ... name the reason). A missing or negative value on a record used stops the macro with an ERROR. *(optional, default `CNSR`)*

`by=`
:   The groups of the columns: one character variable, such as `by = trt01a`. *(required)*

`time=`
:   A time: adds a block with the percent without an event at that time and its limits (time= of [%km](km.md)), such as `time = 182`. *(optional)*

`strata=`
:   The strata of the log-rank test and of the Cox model: variables separated by blanks, such as `strata = sitegr1`. *(optional)*

`order=`
:   The numeric twin of `by=`, such as `order = trt01an`: it gives the order of the columns and of the groups in the comparisons. *(optional)*

`pairs=`
:   The pairs of groups to compare, separated by #: each group in quotes, then the group it is compared with ("Xanomeline High Dose" "Placebo"). When not given, each later group is compared with each earlier one. *(optional)*

`format=`
:   The labels of the categories: pairs of a variable and a format, as in a FORMAT statement (`format = sex $sexf. race $racef.`), as `format=` of [%layout](layout.md). *(optional)*

`name=`
:   The name of the table: the first part of the names of its data sets, such as `name = t14_3_01`. When not given, the last part of `file=` is used; without `file=`, `name=` is required. *(optional)*

`show=`
:   yes: write the long program to the log. A file path, without quotes: write the long program to that file. In both cases the macro runs it. *(optional, default `no`)*

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

The data sets: &lt;name&gt;_km, &lt;name&gt;_surv (with `time=`), &lt;name&gt;_lr and &lt;name&gt;_cox (the results), &lt;name&gt; (the stacked results), &lt;name&gt;_cols, &lt;name&gt;_display, &lt;name&gt;_pop (with `adsl=`) and &lt;name&gt;_rec (with `adsl=` or `where=`). The files: &lt;file&gt;.rtf, &lt;file&gt;.lst and the numbers file (only with `file=`). The global macro variable: &lt;name&gt;_print. With `show=`: the long program, in the log or in a file. In the printed table, a comparison is in the column of the group, on the rows under "vs" and the group it is compared with: the hazard ratio is the hazard of the column group over the hazard of the group on the row (below 1: fewer events in the column group).

## Details

Use [%kmplot](kmplot.md) for the Kaplan-Meier curves; to add or change a block, start from its long program (show=). A block is the rows of one call in the table. The table has these blocks:

- the subjects, the events, and the median time with its 95% interval in each group ([%km](km.md))
- with `time=`: the percent without an event at that time and its limits ([%km](km.md))
- the log-rank test of the groups ([%logrank](logrank.md))
- the hazard ratio of each pair of groups from a Cox model, with its interval and p-value ([%cox](cox.md))

The table has no Total column. The long program is the program the macro writes and runs: the population, the records, one call per block, [%stack](stack.md) and [%table](table.md), the calls a person would write by hand. The macro computes nothing itself. These data sets stay in WORK, for a change and a second print:

- &lt;name&gt;_km, &lt;name&gt;_surv, &lt;name&gt;_lr and &lt;name&gt;_cox: the results, one row per number (the [result shape](../explanation/result-shape.md))
- &lt;name&gt;: the stacked results
- &lt;name&gt;_cols: the columns ([%columns](columns.md))
- &lt;name&gt;_display: the display data set, one row per printed line ([%layout](layout.md))

The global macro variable &lt;name&gt;_print keeps the call of [%print](print.md): change &lt;name&gt;_display, then print again with `%print(&<name>_print.)`. CNSR 0 is an event and any positive value is a censoring, as in ADaM, where the value names the reason of the censoring: a CNSR of 2 is censored as 1 is. A record used with a missing or negative CNSR stops the macro with an ERROR.

## Examples

The examples run on the [example data](../tutorial/index.md#the-example-data) after `examples/setup.sas`. The output under each call is the output of that run. They also read `adttde` (made by the [example of %tte](tte.md#examples)). All examples of the reference run as one program: [examples/reference.sas](https://github.com/datastep-labs/sapling-sas/blob/main/examples/reference.sas).

Makes the table of the time to the event: Kaplan Meier, the log rank test and the hazard ratio.

```sas
%table_tte(
     data  = adttde
   , by    = trt01a
   , order = trt01an
   , pairs = "Xanomeline High Dose" "Placebo"
   , title = "Table 14.6.1 Time to the first skin event"
   , file  = &spl_out./tlf/t14_6_1
 )
```

```text
tlf/t14_6_1.lst: 20 lines
Table 14.6.1 Time to the first skin event

                                                        Placebo   Xanomeline Low Dose  Xanomeline High Dose  All
                                                        (N=85)    (N=95)               (N=72)                groups
-------------------------------------------------------------------------------------------------------------------

Kaplan-Meier: subjects, events, median time and 95% CI
  n                                                     85        95                   72
  Events                                                20        39                   39
  Median                                                NE        80.0                 57.0
  Confidence interval                                   (NE, NE)  (51.0, NE)           (46.0, 177.0)

Log-rank test
  p-value                                                                                                    <0.001

Cox model: hazard ratio (95% CI) and p-value
  vs Placebo
    Hazard ratio                                                                       3.59
    Confidence interval                                                                (2.09, 6.19)
    p-value                                                                            <0.001
```

Takes the N of each column from adsl= and stratifies the test and the Cox model by sex.

```sas
%table_tte(
     data   = adttde
   , adsl   = adsl
   , by     = trt01a
   , strata = sex
   , order  = trt01an
   , title  = "Table 14.6.2 Time to the first skin event, stratified by sex"
   , file   = &spl_out./tlf/t14_6_2
 )
```

```text
tlf/t14_6_2.lst: 24 lines
Table 14.6.2 Time to the first skin event, stratified by sex

                                                        Placebo   Xanomeline Low Dose  Xanomeline High Dose  All
                                                        (N=86)    (N=96)               (N=72)                groups
-------------------------------------------------------------------------------------------------------------------

Kaplan-Meier: subjects, events, median time and 95% CI
  n                                                     85        95                   72
  Events                                                20        39                   39
  Median                                                NE        80.0                 57.0
  Confidence interval                                   (NE, NE)  (51.0, NE)           (46.0, 177.0)

Log-rank test
  p-value                                                                                                    <0.001

Cox model: hazard ratio (95% CI) and p-value
  vs Placebo
    Hazard ratio                                                  3.24                 3.74
    Confidence interval                                           (1.86, 5.62)         (2.16, 6.48)
    p-value                                                       <0.001               <0.001
  vs Xanomeline Low Dose
    Hazard ratio                                                                       1.16
    Confidence interval                                                                (0.74, 1.81)
    p-value                                                                            0.521
```

## Messages

A wrong call writes the message and its fix to the log and stops. The macro also gives the [messages every macro shares](index.md#messages-every-macro-shares).

| Message | Fix |
|---|---|
| name= is required when file= is blank. | give name=&lt;the name of the table&gt;, as t14_5_2. |
| adsl=&lt;ds&gt; does not exist. | give adsl= the data set of the subjects. |

## See also

Tables in one call: [%table](table.md), [%table_summary](table_summary.md), [%table_ae](table_ae.md), [%table_visit](table_visit.md), [%table_shift](table_shift.md), [%table_response](table_response.md), [%table_model](table_model.md).

Named on this page: [%km](km.md), [%layout](layout.md), [%kmplot](kmplot.md), [%logrank](logrank.md), [%cox](cox.md), [%stack](stack.md), [%columns](columns.md), [%print](print.md).

## Proof

Checked against its long program, written out by hand: the same display data set (PROC COMPARE), on a made-up study; ran on SAS 9.4 M9, 2026-11-13.

The examples of this page ran on SAS 9.4 M9 on 2026-11-27, with a log free of ERROR and WARNING.

[Source of %table_tte](https://github.com/datastep-labs/sapling-sas/blob/main/macros/table_tte.sas)
