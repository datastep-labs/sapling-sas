# %table_model

Makes a table of a continuous endpoint in one call: descriptive statistics, and the LS means of a model.

**Procedure:** none of its own (those of %describe, %lsmeans, %mmrm, %table) · **Family:** [Tables in one call](index.md#onecall)

## Syntax

```sas
%table_model(
     data     =
   , adsl     =
   , pop      =
   , where    =
   , var      = CHG
   , covars   =
   , visit    = AVISIT
   , by       =
   , at       =
   , order    =
   , describe =
   , method   = ancova
   , model    =
   , type     = un
   , fallback =
   , pairs    =
   , names    =
   , format   =
   , name     =
   , show     = no
   , stats    =
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
:   The records to use: a condition in parentheses, such as `where = (paramcd = 'SYSBP')`. *(optional)*

`var=`
:   The response: one numeric variable. *(optional, default `CHG`)*

`covars=`
:   The covariates of the model, separated by blanks, such as `covars = base`. *(optional)*

`visit=`
:   The variable of the visit: one variable. *(optional, default `AVISIT`)*

`by=`
:   The groups of the columns: one character variable, such as `by = trt01a`. *(required)*

`at=`
:   The visit of the table: a value of `visit=` in quotes, such as `at = "Week 24"`. It selects the records of the descriptive blocks and of the ANCOVA, and the visit of the LS means of the MMRM. When not given, the ANCOVA uses all records. *(optional)*

`order=`
:   The numeric twin of `by=`, such as `order = trt01an`: it gives the order of the columns and of the groups in the comparisons. *(optional)*

`describe=`
:   The variables with a descriptive block before the model, separated by blanks, such as `describe = base aval chg`. *(optional)*

`method=`
:   ancova ([%lsmeans](lsmeans.md)) or mmrm ([%mmrm](mmrm.md), which needs `at=`). *(optional, default `ancova`)*
    Accepts: `ancova`, `mmrm`.

`model=`
:   The fixed effects of the MMRM, separated by blanks. When not given: the covariates, the `by=` variable, the `visit=` variable and the interaction of the two (such as trt01p*avisit). *(optional)*

`type=`
:   The covariance structure of the MMRM: TYPE= of the REPEATED statement, such as un, cs, ar(1) or toep (type= of [%mmrm](mmrm.md)). *(optional, default `un`)*

`fallback=`
:   Other covariance structures of the MMRM to try in their order when one does not converge, separated by blanks, such as `fallback = toep cs`. *(optional)*

`pairs=`
:   The pairs of groups to compare, separated by #: each group in quotes, then the group it is compared with ("Xanomeline High Dose" "Placebo"). When not given, each later group is compared with each earlier one. *(optional)*

`names=`
:   The labels of the blocks: pairs variable="text", separated by blanks, such as `names = chg="Change from baseline"`. A block without a pair has the label of its variable, or its name. *(optional)*

`format=`
:   The labels of the categories: pairs of a variable and a format, as in a FORMAT statement (`format = sex $sexf. race $racef.`), as `format=` of [%layout](layout.md). *(optional)*

`name=`
:   The name of the table: the first part of the names of its data sets, such as `name = t14_3_01`. When not given, the last part of `file=` is used; without `file=`, `name=` is required. *(optional)*

`show=`
:   yes: write the long program to the log. A file path, without quotes: write the long program to that file. In both cases the macro runs it. *(optional, default `no`)*

`stats=`
:   The statistics of the model block, each name with its pattern. When not given: the LS means with their SE, the difference with its SE and limits, and the p-value. *(optional)*

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

The data sets: &lt;name&gt;_&lt;variable&gt; (the descriptive results), &lt;name&gt;_ancova or &lt;name&gt;_mmrm (the result of the model), &lt;name&gt; (the stacked results), &lt;name&gt;_cols, &lt;name&gt;_display, &lt;name&gt;_at (with `at=`), &lt;name&gt;_pop (with `adsl=`) and &lt;name&gt;_rec (with `adsl=` or `where=`). The files: &lt;file&gt;.rtf, &lt;file&gt;.lst and the numbers file (only with `file=`). The global macro variable: &lt;name&gt;_print. With `show=`: the long program, in the log or in a file.

## Details

Use [%table_visit](table_visit.md) for the statistics at every visit without a model; to add or change a block, start from its long program (show=). A block is the rows of one call in the table. The table has these blocks:

- one block per variable of `describe=`: its descriptive statistics on the records of the visit of `at=` ([%describe](describe.md))
- with method=ancova: the LS means and the differences of pairs of groups from an ANCOVA on the records of the visit of `at=` ([%lsmeans](lsmeans.md))
- with method=mmrm: the same from a mixed model for repeated measures over all visits, at the visit of `at=` ([%mmrm](mmrm.md))

With method=ancova, the records of the visit of `at=` must be one record per subject: give `where=` the parameter and the analysis flag, as [%lsmeans](lsmeans.md) uses the first record of a subject (with a NOTE when it leaves one out). The table has no Total column. The long program is the program the macro writes and runs: the population, the records, one call per block, [%stack](stack.md) and [%table](table.md), the calls a person would write by hand. The macro computes nothing itself. These data sets stay in WORK, for a change and a second print:

- &lt;name&gt;_&lt;variable&gt; and &lt;name&gt;_ancova or &lt;name&gt;_mmrm: the results, one row per number (the [result shape](../explanation/result-shape.md))
- &lt;name&gt;: the stacked results
- &lt;name&gt;_cols: the columns ([%columns](columns.md))
- &lt;name&gt;_display: the display data set, one row per printed line ([%layout](layout.md))

The global macro variable &lt;name&gt;_print keeps the call of [%print](print.md): change &lt;name&gt;_display, then print again with %print(&&lt;name&gt;_print.).

## Examples

The examples run on the [example data](../tutorial/index.md#the-example-data) after `examples/setup.sas`. The output under each call is the output of that run.

Makes the ANCOVA table at Week 12: three descriptive blocks, then the LS means and difference.

```sas
%table_model(
     data     = advs
   , adsl     = adsl
   , where    = (paramcd = 'SYSBP' AND anl01fl = 'Y' AND avisitn < 99)
   , covars   = base
   , by       = trt01p
   , at       = "Week 12"
   , order    = trt01pn
   , describe = base aval chg
   , pairs    = "Xanomeline High Dose" "Placebo"
   , title    = "Table 14.3.1 ANCOVA of the change of systolic blood pressure at Week 12"
   , file     = &spl_out./tlf/t14_3_1
 )
```

```text
tlf/t14_3_1.lst: 30 lines
Table 14.3.1 ANCOVA of the change of systolic blood pressure at Week 12

                           Placebo        Xanomeline Low Dose  Xanomeline High Dose
                           (N=86)         (N=84)               (N=84)
-----------------------------------------------------------------------------------

Baseline Value
  n                        68             41                   41
  Mean (SD)                137.8 (17.68)  136.6 (16.12)        138.7 (16.98)
  Median                   139.0          137.0                140.0
  Min, Max                 90, 180        100, 178             100, 170

Analysis Value
  n                        68             41                   41
  Mean (SD)                134.5 (14.35)  134.1 (15.76)        129.2 (15.50)
  Median                   132.0          135.0                130.0
  Min, Max                 100, 164       104, 170             100, 160

Change from Baseline
  n                        68             41                   41
  Mean (SD)                -3.2 (15.53)   -2.5 (16.23)         -9.5 (16.48)
  Median                   -4.5           -7.0                 -10.0
  Min, Max                 -40, 24        -43, 30              -48, 30

ANCOVA, adjusted for base
  LS mean (SE)             -3.2 (1.58)    -3.1 (2.03)          -8.9 (2.03)
  vs Placebo
    Difference (SE)                                            -5.7 (2.57)
    Confidence interval                                        (-10.8, -0.7)
    p-value                                                    0.027
```

Uses method=mmrm on five visits: the LS means and the differences at Week 24.

```sas
%table_model(
     data     = advs
   , adsl     = adsl
   , where    = (paramcd = 'SYSBP' AND anl01fl = 'Y' AND avisitn IN (4 8 12 16 24))
   , covars   = base
   , visit    = avisit
   , by       = trt01p
   , at       = "Week 24"
   , order    = trt01pn
   , method   = mmrm
   , type     = un
   , fallback = toep
   , title    = "Table 14.3.3 MMRM of the change of systolic blood pressure at Week 24"
   , file     = &spl_out./tlf/t14_3_3
 )
```

```text
tlf/t14_3_3.lst: 16 lines
Table 14.3.3 MMRM of the change of systolic blood pressure at Week 24

                          Placebo      Xanomeline Low Dose  Xanomeline High Dose
                          (N=86)       (N=84)               (N=84)
--------------------------------------------------------------------------------
```

```text
MMRM: Week 24
  LS mean (SE)            -1.8 (1.72)  -1.4 (2.41)          -5.9 (2.31)
  vs Placebo
    Difference (SE)                    0.4 (2.96)           -4.1 (2.88)
    Confidence interval                (-5.5, 6.2)          (-9.8, 1.6)
    p-value                            0.903                0.157
  vs Xanomeline Low Dose
    Difference (SE)                                         -4.4 (3.34)
    Confidence interval                                     (-11.0, 2.1)
    p-value                                                 0.184
```

## Messages

A wrong call writes the message and its fix to the log and stops. The macro also gives the [messages every macro shares](index.md#messages-every-macro-shares).

| Message | Fix |
|---|---|
| name= is required when file= is blank. | give name=&lt;the name of the table&gt;, as t14_5_2. |
| adsl=&lt;ds&gt; does not exist. | give adsl= the data set of the subjects. |

## See also

Tables in one call: [%table](table.md), [%table_summary](table_summary.md), [%table_ae](table_ae.md), [%table_visit](table_visit.md), [%table_shift](table_shift.md), [%table_response](table_response.md), [%table_tte](table_tte.md).

Named on this page: [%lsmeans](lsmeans.md), [%mmrm](mmrm.md), [%layout](layout.md), [%describe](describe.md), [%stack](stack.md), [%columns](columns.md), [%print](print.md).

Guides that use %table_model: [Make an efficacy table with an ANCOVA](../how-to/efficacy-table.md), [Run the examples of the reference](../how-to/run-the-examples.md).

## Proof

The examples of this page ran on SAS 9.4M9 on 2026-11-27, with a log free of ERROR and WARNING.

[Source of %table_model](https://github.com/datastep-labs/sapling-sas/blob/main/macros/table_model.sas)
