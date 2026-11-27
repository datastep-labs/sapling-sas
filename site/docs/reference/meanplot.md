# %meanplot

Draws the mean or median of each group by visit as PNG and RTF files and returns the numbers drawn.

**Procedure:** PROC MEANS, PROC SGPANEL · **Family:** [Figures](index.md#figures)

## Syntax

```sas
%meanplot(
     data    =
   , plot    =
   , par     =
   , columns =
   , where   =
   , y       =
   , x       =
   , by      =
   , panel   =
   , stat    = mean
   , error   = se
   , level   = 0.95
   , connect = yes
   , ntable  = no
   , xformat =
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

<a id="data"></a>`data=`
:   The input data set: one record per subject and visit. *(required)*

<a id="plot"></a>`plot=`
:   Draw again: the `out=` of an earlier %meanplot call, changed or not. It is drawn as it is, and no statistic is computed. Give it instead of `data=`. *(optional)*

<a id="par"></a>`par=`
:   The drawing parameters of an earlier %meanplot call: its `outpar=`. A drawing parameter given in the call wins over its row of `par=`. *(optional)*

<a id="columns"></a>`columns=`
:   The data set of [%columns](columns.md): it gives the order of the groups and their colours. When not given, the groups come in the order of the data. *(optional)*

<a id="where"></a>`where=`
:   The records to use: a condition in parentheses, such as `where = (anl01fl = 'Y')`. *(optional)*

<a id="y"></a>`y=`
:   The variable to summarize: one numeric variable (`y = aval`). *(required)*

<a id="x"></a>`x=`
:   The visit: one numeric variable (`x = avisitn`). Its values are the ticks, printed with `xformat=`. *(required)*

<a id="by"></a>`by=`
:   The groups: one variable, one line per group. *(required)*

<a id="panel"></a>`panel=`
:   A variable: one panel per value, one under the other, each with its own y axis (`panel = paramcd`). *(optional)*

<a id="stat"></a>`stat=`
:   The statistic: mean or median. *(optional, default `mean`)*
    Accepts: `mean`, `median`.

<a id="error"></a>`error=`
:   The error bars: se, sd or ci for the mean; iqr (Q1 and Q3) for the median; or none. *(optional, default `se`)*
    Accepts: `se`, `sd`, `ci`, `iqr`, `none`.

<a id="level"></a>`level=`
:   The confidence level of error=ci: a number between 0 and 1. *(optional, default `0.95`)*

<a id="connect"></a>`connect=`
:   yes: join the points of a group by a line. *(optional, default `yes`)*
    Accepts: `yes`, `no`.

<a id="ntable"></a>`ntable=`
:   yes: show the n of each visit and group under the axis. *(optional, default `no`)*
    Accepts: `yes`, `no`.

<a id="xformat"></a>`xformat=`
:   The format of the ticks of x, as in a FORMAT statement (`xformat = visfmt.`). When not given, the format of x. *(optional)*

<a id="xlabel"></a>`xlabel=`
:   The label of the x axis: a text in quotes. When not given, the label of `x=` (or its name). *(optional)*

<a id="ylabel"></a>`ylabel=`
:   The label of the y axis: a text in quotes. When not given, the statistic, the error bars and the label of `y=`. *(optional)*

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
:   yes: keep the work data sets _meanplot_*. *(optional, default `no`)*
    Accepts: `yes`, `no`.

## Result

The data set of `out=`: one row per panel, group and visit: the variables of `panel=` and `by=`, KIND (mean or median), X (the visit), Y (the statistic), LOWER and UPPER (the ends of the error bar; missing for se, sd and ci when there is one value) and N. The data set of `outpar=`: one row per drawing parameter, in the order of the table: PARAMETER ($32), its name, and VALUE ($500), its value as drawn (a label in quotes). The files: &lt;file&gt;.png and &lt;file&gt;.rtf.

## Details

It computes the statistic from the records; use [%lineplot](lineplot.md) for values computed before (the LS means of [%mmrm](mmrm.md) by visit) and [%profileplot](profileplot.md) for the line of each subject. The error bars are the SE, the SD or the confidence interval of the mean, or Q1 and Q3 of the median. The points of a group are joined by a line, and the groups stand a little apart on the x axis so that their bars do not overlap. With ntable=yes, the n of each visit and group is shown under the axis. The quantiles are those of PROC MEANS with QNTLDEF=5 (R quantile type 2). A record with a missing value, visit, group or panel is not used. To draw the figure again without computing, give `plot=` the `out=` and `par=` the `outpar=` of an earlier call.

!!! note "Good to know"

    Draw again: `plot=` takes the `out=` of an earlier %meanplot call, changed or not, and draws it as it is, with no statistic computed (error bars where LOWER has a value). `par=` takes the `outpar=` of that call and gives the drawing parameters: columns, by, panel, connect, ntable, xformat, xlabel, ylabel, ref, file, width, height. These change the picture, not the numbers. The other parameters compute; with `plot=` the log has a NOTE for each one given, as it is not used. A drawing parameter given in the call wins over its row of `par=`, and the row wins over the default of the table.

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

<a id="ex-f_bp_mean"></a>

Draws the mean change and its SE at each visit, a panel per parameter, with the n of each point.

```sas
%meanplot(
     data    = advs
   , columns = t14_2_1_cols
   , where   = (paramcd IN ('SYSBP' 'DIABP') AND anl01fl = 'Y' AND avisitn < 99)
   , y       = chg
   , x       = avisitn
   , by      = trt01a
   , panel   = param
   , ntable  = yes
   , xformat = VISIT.
   , ref     = 0
   , file    = &spl_out./figures/f_bp_mean
   , out     = f_bp_mean
 )
```

![Draws the mean change and its SE at each visit, a panel per parameter, with the n of each point.](../examples/meanplot.png)

## Messages

A wrong call writes the message and its fix to the log and stops. The macro also gives the [messages every macro shares](index.md#messages-every-macro-shares).

| Message | Fix |
|---|---|
| error=&lt;error&gt; does not go with stat=&lt;stat&gt; | give the mean error=se, sd or ci, the median iqr or none. |
| x=&lt;x&gt; is a character variable | give x= the numeric visit (AVISITN), xformat= its labels. |
| data= and plot= are both given | give data= to compute, or plot= to draw an out= again. |
| plot=&lt;plot&gt; does not exist | give plot= an out= of %meanplot (make it first). |
| plot=&lt;plot&gt; has no variable &lt;variable&gt; | give plot= the shape of out=: &lt;the variables of out=&gt;. |
| par=&lt;par&gt; does not exist | give par= an outpar= of %meanplot (make it first). |
| par=&lt;par&gt; has no variables PARAMETER and VALUE | give par= an outpar= of %meanplot. |
| par=&lt;par&gt; has a row of no drawing parameter (with the PARAMETER of the record) | give par= rows of outpar= of %meanplot only. |

## See also

Figures: [%kmplot](kmplot.md), [%forestplot](forestplot.md), [%lineplot](lineplot.md), [%boxplot](boxplot.md), [%barplot](barplot.md), [%aeplot](aeplot.md), [%profileplot](profileplot.md), [%scatterplot](scatterplot.md).

Named on this page: [%columns](columns.md), [%mmrm](mmrm.md).

## Proof

Its known answer: the means, SE, SD and limits, worked out by hand; ran on SAS 9.4 M9, 2026-11-27 (the cases of the 9 figure macros: 103 of 103 the same).

The known answers and test cases are kept with the development of the library, not in this repository.

The examples of this page ran on SAS 9.4 M9 on 2026-11-27, with a log free of ERROR and WARNING.

[Source of %meanplot](https://github.com/datastep-labs/sapling-sas/blob/main/macros/meanplot.sas)
