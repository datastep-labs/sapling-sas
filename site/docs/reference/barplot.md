# %barplot

Draws bars of the percent of each category by group as PNG and RTF files and returns the numbers drawn.

**Procedure:** PROC FREQ, PROC SGPANEL · **Family:** [Figures](index.md#figures)

## Syntax

```sas
%barplot(
     data    =
   , plot    =
   , par     =
   , columns =
   , denom   =
   , where   =
   , var     =
   , by      =
   , panel   =
   , stat    = percent
   , stacked = no
   , labels  = yes
   , xlabel  =
   , ylabel  =
   , ref     =
   , file    =
   , width   = 6.5in
   , height  = 4.5in
   , out     =
   , outpar  =
   , debug   = no
 )
```

## Parameters

`data=`
:   The input data set: one record per subject and category, or per event. *(required)*

`plot=`
:   Draw again: the `out=` of an earlier %barplot call, changed or not. It is drawn as it is, and no statistic is computed. Give it instead of `data=`. *(optional)*

`par=`
:   The drawing parameters of an earlier %barplot call: its `outpar=`. A drawing parameter given in the call wins over its row of `par=`. *(optional)*

`columns=`
:   The data set of [%columns](columns.md): it gives the order of the groups and their colours. When not given, the groups come in the order of the data. *(optional)*

`denom=`
:   The population: a data set with one row per subject (USUBJID) and the variable of `by=`. Its subjects in a group are the N of the percent. When not given, the N is the records of the group. *(optional)*

`where=`
:   The records to use: a condition in parentheses, such as where = (`anl01fl = 'Y'`). *(optional)*

`var=`
:   The category: one variable (`var = aesev`). *(required)*

`by=`
:   The groups: one variable, one colour per group. *(required)*

`panel=`
:   A variable: one panel per value (`panel = sex`). *(optional)*

`stat=`
:   The statistic of a bar: percent or count. *(optional, default `percent`)*
    Accepts: `percent`, `count`.

`stacked=`
:   yes: stack the groups in one bar. *(optional, default `no`)*
    Accepts: `yes`, `no`.

`labels=`
:   yes: write the value on each bar. *(optional, default `yes`)*
    Accepts: `yes`, `no`.

`xlabel=`
:   The label of the x axis: a text in quotes. When not given, the label of `var=` (or its name). *(optional)*

`ylabel=`
:   The label of the y axis: a text in quotes. When not given, Subjects (%) or Records (%) for a percent, Subjects or Records for a count. *(optional)*

`ref=`
:   Reference lines on the y axis: one value or several, separated by blanks (`ref = 0 50`). *(optional)*

`file=`
:   The output file without its extension: the macro writes &lt;file&gt;.png (300 dpi) and &lt;file&gt;.rtf. *(required)*

`width=`
:   The width of the figure: a length with its unit (`width = 9in`). *(optional, default `6.5in`)*

`height=`
:   The height of the figure: a length with its unit (`height = 6in`). *(optional, default `4.5in`)*

`out=`
:   The name of the data set of the numbers drawn. When not given, they are not kept. *(optional)*

`outpar=`
:   The name of the data set of the drawing parameters, one row each. Give it to `par=` of a later call to draw the figure again. *(optional)*

`debug=`
:   yes: keep the work data sets _barplot_*. *(optional, default `no`)*
    Accepts: `yes`, `no`.

## Result

The data set of `out=`: one row per bar: the variables of `panel=` and `by=`, KIND (bar), X (the category as printed), Y (the percent or the count), N (the subjects or the records of the bar) and DENOM (the N of the percent). A category with no record in a group has no bar. The data set of `outpar=`: one row per drawing parameter, in the order of the table: PARAMETER ($32), its name, and VALUE ($500), its value as drawn (a label in quotes). The files: &lt;file&gt;.png and &lt;file&gt;.rtf.

## Details

Use [%aeplot](aeplot.md) for adverse events with their risk differences. With `denom=`, a bar is the percent of the subjects of the group in the population, and a subject counts once in a category; without it, the percent of the records of the group. stat=count gives the count instead of the percent. The groups stand side by side, or stacked in one bar with stacked=yes; the value is written on each bar. A record with a missing category, group or panel is not used. To draw the figure again without computing, give `plot=` the `out=` and `par=` the `outpar=` of an earlier call.

!!! note "Good to know"

    Draw again: `plot=` takes the `out=` of an earlier %barplot call, changed or not, and draws it as it is, with no statistic computed: the categories in the order of their first row, and the value on a bar with one decimal unless every Y is its N (a count). `par=` takes the `outpar=` of that call and gives the drawing parameters: columns, by, panel, stacked, labels, xlabel, ylabel, ref, file, width, height. These change the picture, not the numbers. The other parameters compute; with `plot=` the log has a NOTE for each one given, as it is not used. A drawing parameter given in the call wins over its row of `par=`, and the row wins over the default of the table.

## Examples

The examples run on the [example data](../tutorial/index.md#the-example-data) after `examples/setup.sas`. The output under each call is the output of that run. They also read `t14_2_1_cols` (made by the [example of %columns](columns.md#examples)).

```sas
%barplot(
     data    = adae
   , columns = t14_2_1_cols
   , denom   = adsl
   , where   = (trtemfl = 'Y')
   , var     = aesev
   , by      = trt01a
   , file    = &spl_out./figures/f_ae_sev
   , out     = f_ae_sev
 )
```

![The figure that the example of %barplot draws](../examples/barplot.png)

## Messages

The macro gives only the [messages every macro shares](index.md#messages-every-macro-shares).

## See also

Figures: [%kmplot](kmplot.md), [%forestplot](forestplot.md), [%meanplot](meanplot.md), [%lineplot](lineplot.md), [%boxplot](boxplot.md), [%aeplot](aeplot.md), [%profileplot](profileplot.md), [%scatterplot](scatterplot.md).

Named on this page: [%columns](columns.md).

## Proof

Checked against its known answers: numbers worked out independently in R, compared on SAS by the tests of the library.

The examples of this page ran on SAS 9.4M9 on 2026-11-27, with a log free of ERROR and WARNING.

[Source of %barplot](https://github.com/datastep-labs/sapling-sas/blob/main/macros/barplot.sas)
