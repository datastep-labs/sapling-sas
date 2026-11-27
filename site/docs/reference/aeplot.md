# %aeplot

Draws the percent and risk difference of each adverse event as PNG and RTF files and returns the numbers drawn.

**Procedure:** PROC SUMMARY, PROC SGPANEL (and PROC FREQ in %risk) · **Family:** [Figures](index.md#figures)

## Syntax

```sas
%aeplot(
     data      =
   , plot      =
   , par       =
   , columns   =
   , denom     =
   , where     =
   , term      = AEDECOD
   , by        =
   , reference =
   , threshold =
   , sort      = difference
   , ci        = wald
   , level     = 0.95
   , max       = 30
   , xlabel    =
   , file      =
   , width     = 6.5in
   , height    = 4.5in
   , out       =
   , outpar    =
   , debug     = no
 )
```

## Parameters

<a id="data"></a>`data=`
:   The input data set: the adverse event records. *(required)*

<a id="plot"></a>`plot=`
:   Draw again: the `out=` of an earlier %aeplot call, changed or not. It is drawn as it is, and no statistic is computed. Give it instead of `data=`. *(optional)*

<a id="par"></a>`par=`
:   The drawing parameters of an earlier %aeplot call: its `outpar=`. A drawing parameter given in the call wins over its row of `par=`. *(optional)*

<a id="columns"></a>`columns=`
:   The data set of [%columns](columns.md): it gives the order of the groups and their colours. When not given, the groups come in the order of `denom=`. *(optional)*

<a id="denom"></a>`denom=`
:   The population: a data set with one row per subject and the variable of `by=`. *(required)*

<a id="where"></a>`where=`
:   The records to use: a condition in parentheses, such as `where = (trtemfl = 'Y')`. *(optional)*

<a id="term"></a>`term=`
:   The term of a row: one variable of `data=` (`term = aebodsys`). *(optional, default `AEDECOD`)*

<a id="by"></a>`by=`
:   The groups: one character variable of `denom=`. *(required)*

<a id="reference"></a>`reference=`
:   The reference group of the risk difference: a value of `by=`, in quotes (`reference = 'Placebo'`). *(required)*

<a id="threshold"></a>`threshold=`
:   A percent: only the terms that this percent of the subjects of a group or more have, in at least one group (`threshold = 5`). *(optional)*

<a id="sort"></a>`sort=`
:   The order of the terms from the top: difference (the risk difference of the first group that is not the reference, the largest first), frequency (the percent of all subjects, the largest first) or alphabetical. *(optional, default `difference`)*
    Accepts: `difference`, `frequency`, `alphabetical`.

<a id="ci"></a>`ci=`
:   The type of the interval of the risk difference, as `ci=` of [%risk](risk.md). *(optional, default `wald`)*

<a id="level"></a>`level=`
:   The confidence level: a number between 0 and 1. *(optional, default `0.95`)*

<a id="max"></a>`max=`
:   The most terms to show: a positive whole number. The first terms in the order of `sort=` are shown. *(optional, default `30`)*

<a id="xlabel"></a>`xlabel=`
:   The heading of the right panel: a text in quotes. When not given, Risk difference (%) with 95% CI, with the level of `level=`. *(optional)*

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
:   yes: keep the work data sets _aeplot_*. *(optional, default `no`)*
    Accepts: `yes`, `no`.

## Result

The data set of `out=`: the variable of `term=`, the variable of `by=`, KIND, X, LOWER, UPPER and N. A row of KIND percent is one term and group: X is the percent of its subjects and N the subjects with the term. A row of KIND difference is one term and group that is not the reference: X is the risk difference in percent (100 x RD of [%risk](risk.md)), and LOWER and UPPER its limits in percent. The data set of `outpar=`: one row per drawing parameter, in the order of the table: PARAMETER ($32), its name, and VALUE ($500), its value as drawn (a label in quotes). The files: &lt;file&gt;.png and &lt;file&gt;.rtf.

## Details

Use [%barplot](barplot.md) for the percents of the categories of one variable without a difference. The figure has two panels side by side that share the axis of the terms. The left panel shows the percent of the subjects of each group with the term, as dots. The right panel shows the risk difference of each group against the reference group, with its confidence interval and a line at 0. The flags are those of [%termflags](termflags.md) and the risk differences those of [%risk](risk.md) (ci=, `level=`), so the figure and a table made with them cannot differ. The terms are those that reach `threshold=`, in the order of `sort=`, at most `max=` of them. To draw the figure again without computing, give `plot=` the `out=` and `par=` the `outpar=` of an earlier call.

!!! note "Good to know"

    Draw again: `plot=` takes the `out=` of an earlier %aeplot call, changed or not, and draws it as it is, with no statistic computed: the terms from the top in the order of their first row (to drop or move a term, change its rows). `par=` takes the `outpar=` of that call and gives the drawing parameters: columns, term, by, xlabel, file, width, height. These change the picture, not the numbers. The other parameters compute (sort= and `max=` choose the rows of `out=` and their order); with `plot=` the log has a NOTE for each one given, as it is not used. A drawing parameter given in the call wins over its row of `par=`, and the row wins over the default of the table.

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

<a id="ex-f_ae_risk"></a>

Draws the percent of each term of 5 percent or more and its risk difference against Placebo.

```sas
%aeplot(
     data      = adae
   , columns   = t14_2_1_cols
   , denom     = adsl
   , where     = (trtemfl = 'Y')
   , term      = aedecod
   , by        = trt01a
   , reference = "Placebo"
   , threshold = 5
   , file      = &spl_out./figures/f_ae_risk
   , out       = f_ae_risk
 )
```

![Draws the percent of each term of 5 percent or more and its risk difference against Placebo.](../examples/aeplot.png)

## Messages

A wrong call writes the message and its fix to the log and stops. The macro also gives the [messages every macro shares](index.md#messages-every-macro-shares).

| Message | Fix |
|---|---|
| max=&lt;max&gt; is not a positive whole number | give max= the most terms to show, such as 30. |
| reference=&lt;reference&gt; is not a group of by=&lt;by&gt; in denom=&lt;denom&gt; | give reference= a value of &lt;by&gt; in quotes. |
| data= and plot= are both given | give data= to compute, or plot= to draw an out= again. |
| plot=&lt;plot&gt; does not exist | give plot= an out= of %aeplot (make it first). |
| plot=&lt;plot&gt; has no variable &lt;variable&gt; | give plot= the shape of out=: &lt;the variables of out=&gt;. |
| par=&lt;par&gt; does not exist | give par= an outpar= of %aeplot (make it first). |
| par=&lt;par&gt; has no variables PARAMETER and VALUE | give par= an outpar= of %aeplot. |
| par=&lt;par&gt; has a row of no drawing parameter (with the PARAMETER of the record) | give par= rows of outpar= of %aeplot only. |

The macro also writes these NOTE lines to the log, without stopping:

- `NOTE: [aeplot] %_spl_nobs(_aeplot_all) terms qualified: the first <max> are shown.`

## See also

Figures: [%kmplot](kmplot.md), [%forestplot](forestplot.md), [%meanplot](meanplot.md), [%lineplot](lineplot.md), [%boxplot](boxplot.md), [%barplot](barplot.md), [%profileplot](profileplot.md), [%scatterplot](scatterplot.md).

Named on this page: [%columns](columns.md), [%risk](risk.md), [%termflags](termflags.md).

## Proof

Its known answer: the percents and the Wald intervals, worked out by hand; ran on SAS 9.4 M9, 2026-11-27 (the cases of the 9 figure macros: 103 of 103 the same).

The known answers and test cases are kept with the development of the library, not in this repository.

The examples of this page ran on SAS 9.4 M9 on 2026-11-27, with a log free of ERROR and WARNING.

[Source of %aeplot](https://github.com/datastep-labs/sapling-sas/blob/main/macros/aeplot.sas)
