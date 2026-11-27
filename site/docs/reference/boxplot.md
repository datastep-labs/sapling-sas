# %boxplot

Draws box plots of a variable in each group as PNG and RTF files and returns the numbers drawn.

**Procedure:** PROC MEANS, PROC SGPANEL · **Family:** [Figures](index.md#figures)

## Syntax

```sas
%boxplot(
     data     =
   , plot     =
   , par      =
   , columns  =
   , where    =
   , y        =
   , x        =
   , by       =
   , panel    =
   , outliers = yes
   , mean     = yes
   , xformat  =
   , xlabel   =
   , ylabel   =
   , ref      =
   , file     =
   , width    = 6.5in
   , height   = 4.5in
   , out      =
   , outpar   =
   , debug    = no
 )
```

## Parameters

<a id="data"></a>`data=`
:   The input data set: one record per value. *(required)*

<a id="plot"></a>`plot=`
:   Draw again: the `out=` of an earlier %boxplot call, changed or not. It is drawn as it is, and no statistic is computed. Give it instead of `data=`. *(optional)*

<a id="par"></a>`par=`
:   The drawing parameters of an earlier %boxplot call: its `outpar=`. A drawing parameter given in the call wins over its row of `par=`. *(optional)*

<a id="columns"></a>`columns=`
:   The data set of [%columns](columns.md): it gives the order of the groups and their colours. When not given, the groups come in the order of the data. *(optional)*

<a id="where"></a>`where=`
:   The records to use: a condition in parentheses, such as `where = (anl01fl = 'Y')`. *(optional)*

<a id="y"></a>`y=`
:   The variable of the boxes: one numeric variable (`y = aval`). *(required)*

<a id="x"></a>`x=`
:   The category of the x axis: one variable, such as the visit (`x = avisitn`). When not given, there is one box per group. *(optional)*

<a id="by"></a>`by=`
:   The groups: one variable, one box per group. *(required)*

<a id="panel"></a>`panel=`
:   A variable: one panel per value, one under the other, each with its own y axis (`panel = paramcd`). *(optional)*

<a id="outliers"></a>`outliers=`
:   yes: show the values beyond the whiskers as markers. *(optional, default `yes`)*
    Accepts: `yes`, `no`.

<a id="mean"></a>`mean=`
:   yes: show the mean as a marker in the box. *(optional, default `yes`)*
    Accepts: `yes`, `no`.

<a id="xformat"></a>`xformat=`
:   The format of the categories of x, as in a FORMAT statement (`xformat = visfmt.`). When not given, the format of x. *(optional)*

<a id="xlabel"></a>`xlabel=`
:   The label of the x axis: a text in quotes. When not given, the label of `x=` (or its name). *(optional)*

<a id="ylabel"></a>`ylabel=`
:   The label of the y axis: a text in quotes. When not given, the label of `y=` (or its name). *(optional)*

<a id="ref"></a>`ref=`
:   Reference lines on the y axis: one value or several, separated by blanks (`ref = 0 50`). *(optional)*

<a id="file"></a>`file=`
:   The output file without its extension: the macro writes &lt;file&gt;.png (300 dpi) and &lt;file&gt;.rtf. *(required)*

<a id="width"></a>`width=`
:   The width of the figure: a length with its unit (`width = 9in`). *(optional, default `6.5in`)*

<a id="height"></a>`height=`
:   The height of the figure: a length with its unit (`height = 6in`). *(optional, default `4.5in`)*

<a id="out"></a>`out=`
:   The name of the data set of the numbers drawn. When not given, they are not kept. *(optional)*

<a id="outpar"></a>`outpar=`
:   The name of the data set of the drawing parameters, one row each. Give it to `par=` of a later call to draw the figure again. *(optional)*

<a id="debug"></a>`debug=`
:   yes: keep the work data sets _boxplot_*. *(optional, default `no`)*
    Accepts: `yes`, `no`.

## Result

The data set of `out=`: one row per box: the variables of `panel=` and `by=`, KIND (box), X (the category; missing without `x=`), N, MEAN, MEDIAN, Q1, Q3, MIN, MAX, WLOW and WHIGH. WLOW and WHIGH are the ends of the whiskers: the smallest and the largest value within Q1 - 1.5 IQR and Q3 + 1.5 IQR. The data set of `outpar=`: one row per drawing parameter, in the order of the table: PARAMETER ($32), its name, and VALUE ($500), its value as drawn (a label in quotes). The files: &lt;file&gt;.png and &lt;file&gt;.rtf.

## Details

Use [%meanplot](meanplot.md) for the mean and its error bars only. With `x=`, there is one box per group at each visit. The box goes from Q1 to Q3, with a line at the median and a marker at the mean. The whiskers go to the most extreme values within 1.5 times the interquartile range of the box; the values beyond them are outliers. The quantiles are those of PROC MEANS with QNTLDEF=5 and of VBOX (its default PERCENTILE=5; R quantile type 2). A record with a missing value, category, group or panel is not used. To draw the figure again without computing, give `plot=` the `out=` and `par=` the `outpar=` of an earlier call.

!!! note "Good to know"

    Draw again: `plot=` takes the `out=` of an earlier %boxplot call, changed or not, and draws it as it is, with no statistic computed, each box from its statistics: the whiskers from WLOW to WHIGH, the box from Q1 to Q3 with the line of the MEDIAN, the MEAN, and as outliers only MIN and MAX when they are beyond a whisker (out= has no other value; from `data=` every outlier is drawn). `par=` takes the `outpar=` of that call and gives the drawing parameters: columns, by, panel, outliers, mean, xformat, xlabel, ylabel, ref, file, width, height. These change the picture, not the numbers. The other parameters compute; with `plot=` the log has a NOTE for each one given, as it is not used. A drawing parameter given in the call wins over its row of `par=`, and the row wins over the default of the table.

## Examples

The examples run on the [example data](../tutorial/index.md#the-example-data) after `examples/setup.sas`. The output under each call is the output of that run. They also read `t14_2_1_cols` (made by the [example of %columns](columns.md#ex-t14_2_1_cols)). All examples of the reference run as one program: [examples/reference.sas](https://github.com/datastep-labs/sapling-sas/blob/main/examples/reference.sas).

??? note "Before these examples: the calls that make their inputs"

    Run `examples/setup.sas`, then these calls from the examples of %describe, %anova, %freq, %chisq, %stack, %columns, in this order. Then the examples of this page run as shown.

    ```sas
    /* from the example of %describe */
    * Summarizes age in each group and in the Total: n, mean, SD, median, minimum and maximum.;
    %describe(
         data  = adsl
       , var   = age
       , by    = trt01a
       , total = yes
       , label = "Age (years)"
       , out   = age_describe
     )
    /* from the example of %anova */
    * Tests age across the three groups: one row, the p value of the F test.;
    %anova(
         data  = adsl
       , var   = age
       , by    = trt01a
       , label = "Age (years)"
       , out   = age_anova
     )
    /* from the example of %freq */
    * Counts each sex in each group and in the Total: n and the percent of the subjects of the group.;
    %freq(
         data  = adsl
       , var   = sex
       , by    = trt01a
       , total = yes
       , label = "Sex"
       , out   = sex_freq
     )
    /* from the example of %chisq */
    * Tests sex across the groups: one row, the p value of the chi square test.;
    %chisq(
         data  = adsl
       , var   = sex
       , by    = trt01a
       , label = "Sex"
       , out   = sex_chisq
     )
    /* from the example of %stack */
    * Stacks four results in the order of the table: RESULT and ORD tell where each row came from.;
    %stack(age_describe age_anova sex_freq sex_chisq, out=t14_2_1)
    /* from the example of %columns */
    * Makes the four columns with their N from adsl, the Total last, in the order of TRT01AN.;
    %columns(
         data  = t14_2_1
       , n     = adsl
       , var   = trt01a
       , order = trt01an
       , total = yes
       , out   = t14_2_1_cols
     )
    ```

<a id="ex-f_sbp_box"></a>

Draws a box of the change of the systolic blood pressure at each visit for each group.

```sas
%boxplot(
     data    = advs
   , columns = t14_2_1_cols
   , where   = (paramcd = 'SYSBP' AND anl01fl = 'Y' AND avisitn IN (4 12 24))
   , y       = chg
   , x       = avisitn
   , by      = trt01a
   , xformat = VISIT.
   , ref     = 0
   , file    = &spl_out./figures/f_sbp_box
   , out     = f_sbp_box
 )
```

![Draws a box of the change of the systolic blood pressure at each visit for each group.](../examples/boxplot.png)

## Messages

A wrong call writes the message and its fix to the log and stops. The macro also gives the [messages every macro shares](index.md#messages-every-macro-shares).

| Message | Fix |
|---|---|
| data= and plot= are both given | give data= to compute, or plot= to draw an out= again. |
| plot=&lt;plot&gt; does not exist | give plot= an out= of %boxplot (make it first). |
| plot=&lt;plot&gt; has no variable &lt;variable&gt; | give plot= the shape of out=: &lt;the variables of out=&gt;. |
| par=&lt;par&gt; does not exist | give par= an outpar= of %boxplot (make it first). |
| par=&lt;par&gt; has no variables PARAMETER and VALUE | give par= an outpar= of %boxplot. |
| par=&lt;par&gt; has a row of no drawing parameter (with the PARAMETER of the record) | give par= rows of outpar= of %boxplot only. |

## See also

Figures: [%kmplot](kmplot.md), [%forestplot](forestplot.md), [%meanplot](meanplot.md), [%lineplot](lineplot.md), [%barplot](barplot.md), [%aeplot](aeplot.md), [%profileplot](profileplot.md), [%scatterplot](scatterplot.md).

Named on this page: [%columns](columns.md).

## Proof

Its known answer: the quartiles and the whiskers, worked out by hand; ran on SAS 9.4 M9, 2026-11-27 (the cases of the 9 figure macros: 103 of 103 the same).

The known answers and test cases are kept with the development of the library, not in this repository.

The examples of this page ran on SAS 9.4 M9 on 2026-11-27, with a log free of ERROR and WARNING.

[Source of %boxplot](https://github.com/datastep-labs/sapling-sas/blob/main/macros/boxplot.sas)
