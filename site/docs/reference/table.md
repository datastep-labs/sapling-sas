# %table

Makes a table from the stacked results in one call: [%columns](columns.md), [%ard](ard.md), [%layout](layout.md) and [%print](print.md), in that order.

**Procedure:** none of its own (those of %columns, %ard, %layout, %print) · **Family:** [Tables in one call](index.md#onecall)

## Syntax

```sas
%table(
     data   =
   , n      =
   , var    =
   , order  =
   , total  = no
   , format =
   , label  =
   , rows   = 40
   , file   =
   , nodata =
   , setup  =
   , out    =
   , debug  = no
 )
```

## Parameters

`data=`
:   The results stacked by [%stack](stack.md): one data set in the result shape. *(required)*

`n=`
:   The population for the N of each column: a data set with one row per subject (n= of [%columns](columns.md)). When not given, the columns have no N. *(optional)*

`var=`
:   The column variable of the results: one variable, such as `var = trt01a`. *(required)*

`order=`
:   The numeric twin of `var=` in the data set of `n=`, such as `order = trt01an`: it gives the order of the columns. *(optional)*

`total=`
:   yes: the results have the group Total, and it is the last column (total= of [%columns](columns.md)). A text in quotes is another name for the Total. *(optional, default `no`)*

`format=`
:   The labels of the categories: pairs of a variable and a format, as in a FORMAT statement (`format = sex $sexf. race $racef.`), as `format=` of [%layout](layout.md). *(optional)*

`label=`
:   The labels of the columns: pairs name="text", separated by blanks (label= of [%print](print.md)). *(optional)*

`rows=`
:   The number of rows a page holds: [%print](print.md) keeps the rows of one level on one page when they fit. *(optional, default `40`)*

`file=`
:   The output file without its extension: the macro writes &lt;file&gt;.rtf, &lt;file&gt;.lst and the numbers file &lt;out&gt;/ard/&lt;last part of file&gt;.csv. When not given, nothing is printed. *(optional)*

`nodata=`
:   The text printed when the table has no row: a text in quotes. *(optional)*

`setup=`
:   The name of a global macro variable that keeps the call of [%print](print.md) for `out=`. When not given, no macro variable is left. *(optional)*

`out=`
:   The name of the display data set. When not given, it is &lt;data&gt;_display. *(optional)*

`debug=`
:   yes: keep the work data sets of the macros that %table calls. *(optional, default `no`)*
    Accepts: `yes`, `no`.

## Result

The data set of `out=`: the display data set of [%layout](layout.md). The data sets: &lt;data&gt;_cols, the columns of [%columns](columns.md). The files: &lt;file&gt;.rtf and &lt;file&gt;.lst of [%print](print.md), and the numbers file of [%ard](ard.md) (only with `file=`). The global macro variable: with `setup=`, the global macro variable of that name, which holds the parameters of [%print](print.md) for `out=`.

## Details

Use %table when the defaults of the four steps fit; call [%columns](columns.md), [%ard](ard.md), [%layout](layout.md) and [%print](print.md) one by one to change a step between them. It passes them the same parameters as the separate calls and adds no logic of its own. The display data set is the data set [%layout](layout.md) writes: one row per printed line, one column per printed column. The numbers file is the CSV file of [%ard](ard.md) with every number of the table; the macro writes it only with `file=`, because it belongs to an output. The columns &lt;data&gt;_cols and the display data set `out=` stay in WORK. With `setup=`, a global macro variable also keeps the call of [%print](print.md) for `out=`: change `out=`, then print again with `%print(&<setup>.)`. Without `file=`, the macro prints nothing: change `out=`, then call `%print(&<setup>., file=...)`.

## Examples

The examples run on the [example data](../tutorial/index.md#the-example-data) after `examples/setup.sas`. The output under each call is the output of that run. They also read `t14_2_1` (made by the [example of %stack](stack.md#examples)). All examples of the reference run as one program: [examples/reference.sas](https://github.com/datastep-labs/sapling-sas/blob/main/examples/reference.sas).

Runs columns, ard, layout and print in one call: the same table as the long program.

```sas
%table(
     data   = t14_2_1
   , n      = adsl
   , var    = trt01a
   , order  = trt01an
   , total  = yes
   , format = sex $sexf.
   , file   = &spl_out./tlf/t14_2_1_table
   , setup  = t14_2_1_table_print
 )
```

```text
tlf/t14_2_1_table.lst: 15 lines
             Placebo      Xanomeline Low Dose  Xanomeline High Dose  Total        All
             (N=86)       (N=96)               (N=72)                (N=254)      groups
----------------------------------------------------------------------------------------

Age (years)
  n          86           96                   72                    254
  Mean (SD)  75.2 (8.59)  76.0 (8.11)          73.8 (7.94)           75.1 (8.25)
  Median     76.0         78.0                 75.5                  77.0
  Min, Max   52, 89       51, 88               56, 88                51, 89
  p-value                                                                         0.235

Sex
  Female      53 (61.6%)   55 (57.3%)           35 (48.6%)           143 (56.3%)
  Male        33 (38.4%)   41 (42.7%)           37 (51.4%)           111 (43.7%)
  p-value                                                                         0.251
```

## Messages

The macro gives only the [messages every macro shares](index.md#messages-every-macro-shares).

## See also

Tables in one call: [%table_summary](table_summary.md), [%table_ae](table_ae.md), [%table_visit](table_visit.md), [%table_shift](table_shift.md), [%table_response](table_response.md), [%table_model](table_model.md), [%table_tte](table_tte.md).

Named on this page: [%columns](columns.md), [%ard](ard.md), [%layout](layout.md), [%print](print.md), [%stack](stack.md).

Guides that use %table: [Make an adverse event table](../how-to/adverse-event-table.md), [Make an efficacy table with an ANCOVA](../how-to/efficacy-table.md).

## Proof

Its test cases: the same .lst and the same numbers file as the separate calls; ran on SAS 9.4 M9, 2026-11-12.

The known answers and test cases are kept with the development of the library, not in this repository.

The examples of this page ran on SAS 9.4 M9 on 2026-11-27, with a log free of ERROR and WARNING.

[Source of %table](https://github.com/datastep-labs/sapling-sas/blob/main/macros/table.sas)
