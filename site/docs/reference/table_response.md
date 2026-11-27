# %table_response

Makes a response table in one call: the responders in each group, and the comparisons of pairs of groups.

**Procedure:** none of its own (those of %proportion, %risk, %logistic, %table) · **Family:** [Tables in one call](index.md#onecall)

## Syntax

```sas
%table_response(
     data     =
   , adsl     =
   , pop      =
   , where    =
   , var      =
   , event    = "Y"
   , by       =
   , covars   =
   , order    =
   , pairs    =
   , ci       = clopper-pearson
   , measure  = rd
   , diffci   = wald
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

<a id="data"></a>`data=`
:   The input data set: the records, with USUBJID. *(required)*

<a id="adsl"></a>`adsl=`
:   The subjects: a data set with one row per subject. It gives the population and the N of each column, and its variables are merged onto the records by USUBJID. When not given, the N of a column is the subjects of its records. *(optional)*

<a id="pop"></a>`pop=`
:   The population: a condition on `adsl=` in parentheses, such as `pop = (saffl = 'Y')`. It is used only with `adsl=`. *(optional)*

<a id="where"></a>`where=`
:   The records to use: a condition in parentheses, such as `where = (trtemfl = 'Y')`. *(optional)*

<a id="var"></a>`var=`
:   The response: one variable with two values. *(required)*

<a id="event"></a>`event=`
:   The value of `var=` that is the event: a text in quotes. *(optional, default `"Y"`)*

<a id="by"></a>`by=`
:   The groups of the columns: one character variable, such as `by = trt01a`. *(required)*

<a id="covars"></a>`covars=`
:   The covariates, separated by blanks, such as `covars = sitegr1`: they add a block with the odds ratio adjusted for them ([%logistic](logistic.md)). When not given, there is no such block. *(optional)*

<a id="order"></a>`order=`
:   The numeric twin of `by=`, such as `order = trt01an`: it gives the order of the columns and of the groups in the comparisons. *(optional)*

<a id="pairs"></a>`pairs=`
:   The pairs of groups to compare, separated by #: each group in quotes, then the group it is compared with ("Xanomeline High Dose" "Placebo"). When not given, each later group is compared with each earlier one. *(optional)*

<a id="ci"></a>`ci=`
:   The interval of the percent of responders: clopper-pearson, wilson, wald or agresti-coull (ci= of [%proportion](proportion.md)). *(optional, default `clopper-pearson`)*

<a id="measure"></a>`measure=`
:   rd (the risk difference), rr (the relative risk) or or (the odds ratio): the comparison of [%risk](risk.md); none: no comparison. *(optional, default `rd`)*
    Accepts: `rd`, `rr`, `or`, `none`.

<a id="diffci"></a>`diffci=`
:   The interval of a risk difference: wald, newcombe, miettinen-nurminen or agresti-caffo (ci= of [%risk](risk.md)). It is used only with `measure = rd`. *(optional, default `wald`)*

<a id="format"></a>`format=`
:   The labels of the categories: pairs of a variable and a format, as in a FORMAT statement (`format = sex $sexf. race $racef.`), as `format=` of [%layout](layout.md). *(optional)*

<a id="name"></a>`name=`
:   The name of the table: the first part of the names of its data sets, such as `name = t14_3_01`. When not given, the last part of `file=` is used; without `file=`, `name=` is required. *(optional)*

<a id="show"></a>`show=`
:   yes: write the long program to the log. A file path, without quotes: write the long program to that file. In both cases the macro runs it. *(optional, default `no`)*

<a id="title"></a>`title=`
:   The titles of the table: one text in quotes per line (TITLE1, TITLE2 ...). They hold for this table only. When not given, the TITLE statements in force in the program are used. *(optional)*

<a id="footnote"></a>`footnote=`
:   The footnotes of the table: one text in quotes per line (FOOTNOTE1, FOOTNOTE2 ...). They hold for this table only. When not given, the FOOTNOTE statements in force in the program are used. *(optional)*

<a id="file"></a>`file=`
:   The output file without its extension: the macro writes &lt;file&gt;.rtf, &lt;file&gt;.lst and the numbers file. When not given, nothing is printed. *(optional)*

<a id="debug"></a>`debug=`
:   yes: keep the work data sets of the macros that the long program calls. *(optional, default `no`)*
    Accepts: `yes`, `no`.

## Result

The data sets: &lt;name&gt;_prop, &lt;name&gt;_&lt;measure&gt; (with a measure) and &lt;name&gt;_adj (with `covars=`), the results; &lt;name&gt; (the stacked results), &lt;name&gt;_cols, &lt;name&gt;_display, &lt;name&gt;_pop (with `adsl=`) and &lt;name&gt;_rec (with `adsl=` or `where=`). The files: &lt;file&gt;.rtf, &lt;file&gt;.lst and the numbers file (only with `file=`). The global macro variable: &lt;name&gt;_print. With `show=`: the long program, in the log or in a file. In the printed table, a comparison is in the column of the group, on the rows under "vs" and the group it is compared with: the risk difference is the proportion of responders of the column group minus that of the group on the row (-0.013: 1.3 percentage points fewer); the relative risk and the odds ratios are the column group over the group on the row.

## Details

Use [%table_ae](table_ae.md) to count the subjects by levels of events; to add or change a block, start from its long program (show=). A block is the rows of one call in the table. The table has these blocks:

- the responders, n (%), and the interval of the percent ([%proportion](proportion.md))
- with `measure=` rd, rr or or: the risk difference, the relative risk or the odds ratio of each pair, with its interval and p-value ([%risk](risk.md))
- with `covars=`: the odds ratio adjusted for the covariates, with its interval and p-value ([%logistic](logistic.md))

The table has no Total column. The long program is the program the macro writes and runs: the population, the records, one call per block, [%stack](stack.md) and [%table](table.md), the calls a person would write by hand. The macro computes nothing itself. These data sets stay in WORK, for a change and a second print:

- &lt;name&gt;_prop, &lt;name&gt;_&lt;measure&gt; and &lt;name&gt;_adj: the results, one row per number (the [result shape](../explanation/result-shape.md))
- &lt;name&gt;: the stacked results
- &lt;name&gt;_cols: the columns ([%columns](columns.md))
- &lt;name&gt;_display: the display data set, one row per printed line ([%layout](layout.md))

The global macro variable &lt;name&gt;_print keeps the call of [%print](print.md): change &lt;name&gt;_display, then print again with `%print(&<name>_print.)`.

## Examples

The examples run on the [example data](../tutorial/index.md#the-example-data) after `examples/setup.sas`. The output under each call is the output of that run. All examples of the reference run as one program: [examples/reference.sas](https://github.com/datastep-labs/sapling-sas/blob/main/examples/reference.sas).

Makes the table of the responders with their limits and the risk difference of each pair.

```sas
%table_response(
     data   = adrs
   , where  = (paramcd = 'RSP')
   , var    = avalc
   , by     = trt01a
   , order  = trt01an
   , diffci = newcombe
   , title  = "Table 14.3.2 Responders"
   , file   = &spl_out./tlf/t14_3_2
 )
```

```text
tlf/t14_3_2.lst: 18 lines
Table 14.3.2 Responders

                                      Placebo               Xanomeline Low Dose   Xanomeline High Dose
                                      (N=86)                (N=96)                (N=72)
------------------------------------------------------------------------------------------------------

Responders, n (%) and 95% CI
  Y                                   2 ( 2.3%) (0.3, 8.1)  1 ( 1.0%) (0.0, 5.7)  1 ( 1.4%) (0.0, 7.5)

Risk difference (95% CI) and p-value
  vs Placebo
    Risk difference                                         -0.013                -0.009
    Confidence interval                                     (-0.071, 0.036)       (-0.068, 0.054)
    p-value                                                 0.497                 0.667
  vs Xanomeline Low Dose
    Risk difference                                                               0.003
    Confidence interval                                                           (-0.044, 0.065)
    p-value                                                                       0.837
```

Asks for Wilson limits of each percent, the relative risk, and the odds ratio adjusted for age.

```sas
%table_response(
     data    = adrs
   , where   = (paramcd = 'RSP')
   , var     = avalc
   , event   = "Y"
   , by      = trt01a
   , covars  = age
   , order   = trt01an
   , pairs   = "Xanomeline High Dose" "Placebo"
             # "Xanomeline Low Dose"  "Placebo"
   , ci      = wilson
   , measure = rr
   , title   = "Table 14.3.4 Responders: relative risk and odds ratio adjusted for age"
   , file    = &spl_out./tlf/t14_3_4
 )
```

```text
tlf/t14_3_4.lst: 20 lines
Table 14.3.4 Responders: relative risk and odds ratio adjusted for age

                                                  Placebo               Xanomeline Low Dose   Xanomeline High Dose
                                                  (N=86)                (N=96)                (N=72)
------------------------------------------------------------------------------------------------------------------

Responders, n (%) and 95% CI
  Y                                               2 ( 2.3%) (0.6, 8.1)  1 ( 1.0%) (0.2, 5.7)  1 ( 1.4%) (0.2, 7.5)

Relative risk (95% CI) and p-value
  vs Placebo
    Relative risk                                                       0.45                  0.60
    Confidence interval                                                 (0.04, 4.85)          (0.06, 6.45)
    p-value                                                             0.497                 0.667

Odds ratio adjusted for age (95% CI) and p-value
  vs Placebo
    Odds ratio                                                          0.46                  0.55
    Confidence interval                                                 (0.04, 5.25)          (0.05, 6.22)
    p-value                                                             0.535                 0.626
```

## Messages

A wrong call writes the message and its fix to the log and stops. The macro also gives the [messages every macro shares](index.md#messages-every-macro-shares).

| Message | Fix |
|---|---|
| name= is required when file= is blank. | give name=&lt;the name of the table&gt;, as t14_5_2. |
| adsl=&lt;ds&gt; does not exist. | give adsl= the data set of the subjects. |

## See also

Tables in one call: [%table](table.md), [%table_summary](table_summary.md), [%table_ae](table_ae.md), [%table_visit](table_visit.md), [%table_shift](table_shift.md), [%table_model](table_model.md), [%table_tte](table_tte.md).

Named on this page: [%logistic](logistic.md), [%proportion](proportion.md), [%risk](risk.md), [%layout](layout.md), [%stack](stack.md), [%columns](columns.md), [%print](print.md).

## Proof

Checked against its long program, written out by hand: the same display data set (PROC COMPARE), on a made-up study; ran on SAS 9.4 M9, 2026-11-13.

The examples of this page ran on SAS 9.4 M9 on 2026-11-27, with a log free of ERROR and WARNING.

[Source of %table_response](https://github.com/datastep-labs/sapling-sas/blob/main/macros/table_response.sas)
