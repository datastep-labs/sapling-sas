# %table_shift

Makes a shift table in one call: the subjects in each category at baseline against each category after baseline.

**Procedure:** none of its own (those of %freq, %table) · **Family:** [Tables in one call](index.md#onecall)

## Syntax

```sas
%table_shift(
     data     =
   , adsl     =
   , pop      =
   , where    =
   , var      = BNRIND ANRIND
   , within   =
   , by       =
   , keep     =
   , order    =
   , levels   =
   , total    = no
   , format   =
   , name     =
   , show     = no
   , label    =
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
:   The population: a condition on `adsl=` in parentheses, such as pop = (`saffl = 'Y'`). It is used only with `adsl=`. *(optional)*

`where=`
:   The records to use: a condition in parentheses, such as where = (`trtemfl = 'Y'`). *(optional)*

`var=`
:   Two variables, separated by a blank: the category at baseline, then the category after baseline. *(optional, default `BNRIND ANRIND`)*

`within=`
:   The levels above the two variables of `var=`, nested in their order and separated by blanks, such as `within = paramcd avisit`. *(optional)*

`by=`
:   The groups of the columns: one character variable, such as `by = trt01a`. *(required)*

`keep=`
:   Other variables to keep for the names and the order of the rows, separated by blanks (keep= of [%freq](freq.md)), such as `keep = param avisitn`. *(optional)*

`order=`
:   The numeric twin of `by=`, such as `order = trt01an`: it gives the order of the columns. *(optional)*

`levels=`
:   The planned categories of both variables of `var=`: values in quotes, separated by blanks, such as `levels = 'LOW'` 'NORMAL' 'HIGH'. A planned category has a row also without a subject; a record of another category is not counted (levels= of [%freq](freq.md)). *(optional)*

`total=`
:   yes: add the column Total, all groups together. *(optional, default `no`)*
    Accepts: `yes`, `no`.

`format=`
:   The labels of the categories: pairs of a variable and a format, as in a FORMAT statement (`format = sex $sexf. race $racef.`), as `format=` of [%layout](layout.md). *(optional)*

`name=`
:   The name of the table: the first part of the names of its data sets, such as `name = t14_3_01`. When not given, the last part of `file=` is used; without `file=`, `name=` is required. *(optional)*

`show=`
:   yes: write the long program to the log. A file path, without quotes: write the long program to that file. In both cases the macro runs it. *(optional, default `no`)*

`label=`
:   The label of the block in the table: a text in quotes. *(optional)*

`stats=`
:   The statistics, each name with its pattern, separated by blanks (stats= of [%freq](freq.md)). *(optional)*

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

The data sets: &lt;name&gt;_shift (the result), &lt;name&gt; (the stacked results), &lt;name&gt;_cols, &lt;name&gt;_display, &lt;name&gt;_pop (with `adsl=`) and &lt;name&gt;_rec (with `adsl=` or `where=`). The files: &lt;file&gt;.rtf, &lt;file&gt;.lst and the numbers file (only with `file=`). The global macro variable: the global macro variable &lt;name&gt;_print. With `show=`: the long program, in the log or in a file.

## Details

Use [%table_ae](table_ae.md) for the subjects by nested levels of events; to add a block that it does not make, start from its long program (show=). The rows are the levels of `within=` (such as the parameter and the visit), then the category at baseline, then the category after it, in one [%freq](freq.md). The percent is of the subjects of the group that have a record in the records used. The long program is the program the macro writes and runs: the population, the records, one [%freq](freq.md), [%stack](stack.md) and [%table](table.md), the calls a person would write by hand. The macro computes nothing itself. These data sets stay in WORK, for a change and a second print:

- &lt;name&gt;_shift: the result, one row per number (the [result shape](../explanation/result-shape.md))
- &lt;name&gt;: the stacked results
- &lt;name&gt;_cols: the columns ([%columns](columns.md))
- &lt;name&gt;_display: the display data set, one row per printed line ([%layout](layout.md))

The global macro variable &lt;name&gt;_print keeps the call of [%print](print.md): change &lt;name&gt;_display, then print again with %print(&&lt;name&gt;_print.).

## Examples

The examples run on the [example data](../tutorial/index.md#the-example-data) after `examples/setup.sas`. The output under each call is the output of that run.

```sas
%table_shift(
     data   = adlb
   , where  = (avisit IN ('Week 12' 'Week 24'))
   , within = paramcd avisit
   , by     = trt01a
   , order  = trt01an
   , levels = 'LOW' 'NORMAL' 'HIGH'
   , title  = "Table 14.8.1 Shift from baseline of the normal range"
   , file   = &spl_out./tlf/t14_8_1
 )
```

```text
tlf/t14_8_1.lst: the first 40 of 67 lines
Table 14.8.1 Shift from baseline of the normal range

                Placebo     Xanomeline Low Dose  Xanomeline High Dose
                (N=68)      (N=52)               (N=50)
---------------------------------------------------------------------

  ALT
    Week 12
      LOW
        LOW      0 ( 0.0%)   0 ( 0.0%)            0 ( 0.0%)
        NORMAL   0 ( 0.0%)   0 ( 0.0%)            0 ( 0.0%)
        HIGH     0 ( 0.0%)   0 ( 0.0%)            0 ( 0.0%)
      NORMAL
        LOW      0 ( 0.0%)   0 ( 0.0%)            0 ( 0.0%)
        NORMAL  61 (89.7%)  47 (90.4%)           44 (88.0%)
        HIGH     3 ( 4.4%)   2 ( 3.8%)            2 ( 4.0%)
      HIGH
        LOW      0 ( 0.0%)   0 ( 0.0%)            0 ( 0.0%)
        NORMAL   2 ( 2.9%)   1 ( 1.9%)            3 ( 6.0%)
        HIGH     1 ( 1.5%)   1 ( 1.9%)            1 ( 2.0%)
    Week 24
      LOW
        LOW      0 ( 0.0%)   0 ( 0.0%)            0 ( 0.0%)
        NORMAL   0 ( 0.0%)   0 ( 0.0%)            0 ( 0.0%)
        HIGH     0 ( 0.0%)   0 ( 0.0%)            0 ( 0.0%)
      NORMAL
        LOW      1 ( 1.5%)   0 ( 0.0%)            0 ( 0.0%)
        NORMAL  51 (75.0%)  24 (46.2%)           28 (56.0%)
        HIGH     2 ( 2.9%)   2 ( 3.8%)            0 ( 0.0%)
      HIGH
        LOW      0 ( 0.0%)   0 ( 0.0%)            0 ( 0.0%)
        NORMAL   3 ( 4.4%)   0 ( 0.0%)            2 ( 4.0%)
        HIGH     0 ( 0.0%)   0 ( 0.0%)            0 ( 0.0%)

Table 14.8.1 Shift from baseline of the normal range

                Placebo     Xanomeline Low Dose  Xanomeline High Dose
                (N=68)      (N=52)               (N=50)
---------------------------------------------------------------------
```

## Messages

A wrong call writes the message and its fix to the log and stops. The macro also gives the [messages every macro shares](index.md#messages-every-macro-shares).

| Message | Fix |
|---|---|
| var=&lt;var&gt; has not two variables. | give var= two variables: at baseline, then after it. |
| name= is required when file= is blank. | give name=&lt;the name of the table&gt;, as t14_5_2. |
| adsl=&lt;ds&gt; does not exist. | give adsl= the data set of the subjects. |

## See also

Tables in one call: [%table](table.md), [%table_summary](table_summary.md), [%table_ae](table_ae.md), [%table_visit](table_visit.md), [%table_response](table_response.md), [%table_model](table_model.md), [%table_tte](table_tte.md).

Named on this page: [%freq](freq.md), [%stack](stack.md), [%columns](columns.md), [%layout](layout.md), [%print](print.md).

## Proof

The examples of this page ran on SAS 9.4M9 on 2026-11-27, with a log free of ERROR and WARNING.

[Source of %table_shift](https://github.com/datastep-labs/sapling-sas/blob/main/macros/table_shift.sas)
