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

`data=`
:   The input data set: one record per subject and visit. *(required)*

`plot=`
:   Draw again: the `out=` of an earlier %meanplot call, changed or not. It is drawn as it is, and no statistic is computed. Give it instead of `data=`. *(optional)*

`par=`
:   The drawing parameters of an earlier %meanplot call: its `outpar=`. A drawing parameter given in the call wins over its row of `par=`. *(optional)*

`columns=`
:   The data set of [%columns](columns.md): it gives the order of the groups and their colours. When not given, the groups come in the order of the data. *(optional)*

`where=`
:   The records to use: a condition in parentheses, such as `where = (anl01fl = 'Y')`. *(optional)*

`y=`
:   The variable to summarize: one numeric variable (`y = aval`). *(required)*

`x=`
:   The visit: one numeric variable (`x = avisitn`). Its values are the ticks, printed with `xformat=`. *(required)*

`by=`
:   The groups: one variable, one line per group. *(required)*

`panel=`
:   A variable: one panel per value, one under the other, each with its own y axis (`panel = paramcd`). *(optional)*

`stat=`
:   The statistic: mean or median. *(optional, default `mean`)*
    Accepts: `mean`, `median`.

`error=`
:   The error bars: se, sd or ci for the mean; iqr (Q1 and Q3) for the median; or none. *(optional, default `se`)*
    Accepts: `se`, `sd`, `ci`, `iqr`, `none`.

`level=`
:   The confidence level of error=ci: a number between 0 and 1. *(optional, default `0.95`)*

`connect=`
:   yes: join the points of a group by a line. *(optional, default `yes`)*
    Accepts: `yes`, `no`.

`ntable=`
:   yes: show the n of each visit and group under the axis. *(optional, default `no`)*
    Accepts: `yes`, `no`.

`xformat=`
:   The format of the ticks of x, as in a FORMAT statement (`xformat = visfmt.`). When not given, the format of x. *(optional)*

`xlabel=`
:   The label of the x axis: a text in quotes. When not given, the label of `x=` (or its name). *(optional)*

`ylabel=`
:   The label of the y axis: a text in quotes. When not given, the statistic, the error bars and the label of `y=`. *(optional)*

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
:   yes: keep the work data sets _meanplot_*. *(optional, default `no`)*
    Accepts: `yes`, `no`.

## Result

The data set of `out=`: one row per panel, group and visit: the variables of `panel=` and `by=`, KIND (mean or median), X (the visit), Y (the statistic), LOWER and UPPER (the ends of the error bar; missing for se, sd and ci when there is one value) and N. The data set of `outpar=`: one row per drawing parameter, in the order of the table: PARAMETER ($32), its name, and VALUE ($500), its value as drawn (a label in quotes). The files: &lt;file&gt;.png and &lt;file&gt;.rtf.

## Details

It computes the statistic from the records; use [%lineplot](lineplot.md) for values computed before (the LS means of [%mmrm](mmrm.md) by visit) and [%profileplot](profileplot.md) for the line of each subject. The error bars are the SE, the SD or the confidence interval of the mean, or Q1 and Q3 of the median. The points of a group are joined by a line, and the groups stand a little apart on the x axis so that their bars do not overlap. With ntable=yes, the n of each visit and group is shown under the axis. The quantiles are those of PROC MEANS with QNTLDEF=5 (R quantile type 2). A record with a missing value, visit, group or panel is not used. To draw the figure again without computing, give `plot=` the `out=` and `par=` the `outpar=` of an earlier call.

!!! note "Good to know"

    Draw again: `plot=` takes the `out=` of an earlier %meanplot call, changed or not, and draws it as it is, with no statistic computed (error bars where LOWER has a value). `par=` takes the `outpar=` of that call and gives the drawing parameters: columns, by, panel, connect, ntable, xformat, xlabel, ylabel, ref, file, width, height. These change the picture, not the numbers. The other parameters compute; with `plot=` the log has a NOTE for each one given, as it is not used. A drawing parameter given in the call wins over its row of `par=`, and the row wins over the default of the table.

## Examples

The examples run on the [example data](../tutorial/index.md#the-example-data) after `examples/setup.sas`. The output under each call is the output of that run. They also read `t14_2_1_cols` (made by the [example of %columns](columns.md#examples)). All examples of the reference run as one program: [examples/reference.sas](https://github.com/datastep-labs/sapling-sas/blob/main/examples/reference.sas).

??? note "Before these examples: the calls that make their inputs"

    Run `examples/setup.sas`, then these examples of other pages ([%tte](tte.md), [%describe](describe.md), [%anova](anova.md), [%freq](freq.md), [%chisq](chisq.md), [%cox](cox.md), [%stack](stack.md), [%columns](columns.md)), in this order. Then the examples of this page run as shown.

    ```sas
    /* the example of %tte */
    * Derives the time to the first skin event from the first dose: CNSR 0 is an event, 1 a censoring.;
    %tte(
         subjects      = adsl
       , events        = adae
       , event         = trtemfl = 'Y' AND aebodsys = 'SKIN AND SUBCUTANEOUS TISSUE DISORDERS'
       , date          = astdt
       , start         = trtsdt
       , censor_date   = trtedt
       , seq           = aeseq
       , censor_desc   = "End of treatment"
       , censor_source = "ADSL"
       , event_desc    = aedecod
       , source        = "ADAE"
       , paramcd       = "TTDE"
       , out           = adttde
     )
    TITLE;
    FOOTNOTE;
    /* the example of %describe */
    * Summarizes age in each group and in the Total: n, mean, SD, median, minimum and maximum.;
    %describe(
         data  = adsl
       , var   = age
       , by    = trt01a
       , total = yes
       , label = "Age (years)"
       , out   = age_describe
     )
    * Uses three BY variables: one row per group, parameter, visit and statistic, with PARAM kept.;
    %describe(
         data  = advs
       , where = (anl01fl = 'Y')
       , var   = aval
       , by    = trt01a paramcd avisit
       , keep  = param avisitn
       , out   = vs
     )
    * Adds the SE, Q1 and Q3 and calls the Total All subjects: the rows keep the order of stats=.;
    %describe(
         data  = advs
       , where = (paramcd = 'WEIGHT' AND ablfl = 'Y')
       , var   = aval
       , by    = trt01a
       , total = "All subjects"
       , stats = n mean sd se median q1 q3 min="XX.X" max="XX.X"
       , label = "Weight at baseline (kg)"
       , out   = wt_describe
     )
    * Adds sex as a second BY variable: the rows of each group and sex, for a page per sex.;
    %describe(
         data  = adsl
       , var   = age
       , by    = trt01a sex
       , total = yes
       , label = "Age (years)"
       , out   = age_sex
     )
    TITLE;
    FOOTNOTE;
    /* the example of %anova */
    * Tests age across the three groups: one row, the p value of the F test.;
    %anova(
         data  = adsl
       , var   = age
       , by    = trt01a
       , label = "Age (years)"
       , out   = age_anova
     )
    TITLE;
    FOOTNOTE;
    /* the example of %freq */
    * Counts each sex in each group and in the Total: n and the percent of the subjects of the group.;
    %freq(
         data  = adsl
       , var   = sex
       , by    = trt01a
       , total = yes
       , label = "Sex"
       , out   = sex_freq
     )
    * Counts subjects and events of each term under its class: the percent uses the N of denom=.;
    %freq(
         data  = adae
       , denom = adsl
       , where = (trtemfl = 'Y')
       , var   = aebodsys aedecod
       , by    = trt01a
       , stats = n pct events
       , out   = teae
     )
    * Counts the shift at Week 24 with planned levels: a level without a subject has a row of 0.;
    %freq(
         data   = adlb
       , denom  = adsl
       , where  = (avisit = 'Week 24')
       , var    = paramcd bnrind anrind
       , by     = trt01a
       , levels = bnrind 'LOW' 'NORMAL' 'HIGH' anrind 'LOW' 'NORMAL' 'HIGH'
       , out    = shift
     )
    * Keeps the terms that reach 5 percent in a group: AEDECODN ranks them, the most subjects first.;
    %freq(
         data      = adae
       , denom     = adsl
       , where     = (trtemfl = 'Y')
       , var       = aedecod
       , by        = trt01a
       , threshold = 5
       , order     = frequency
       , out       = common
     )
    * Adds sex as a second BY variable: the age groups of each group and sex, for a page per sex.;
    %freq(
         data  = adsl
       , var   = agegr1
       , by    = trt01a sex
       , total = yes
       , label = "Age group"
       , out   = agegr_sex
     )
    TITLE;
    FOOTNOTE;
    /* the example of %chisq */
    * Tests sex across the groups: one row, the p value of the chi square test.;
    %chisq(
         data  = adsl
       , var   = sex
       , by    = trt01a
       , label = "Sex"
       , out   = sex_chisq
     )
    * Runs the exact test of the normal range within each parameter: one p value per parameter.;
    %chisq(
         data   = adlb
       , where  = (avisit = 'Week 24')
       , var    = anrind
       , by     = trt01a
       , within = paramcd
       , exact  = yes
       , out    = nr_test
     )
    TITLE;
    FOOTNOTE;
    /* the example of %cox */
    * Gives the hazard ratio of each pair, stratified by sex, with its limits and p value.;
    %cox(
         data   = adttde
       , var    = aval
       , by     = trt01a
       , strata = sex
       , order  = trt01an
       , out    = ttde_hr
     )
    * Gives the hazard ratio against Placebo for each sex: the rows carry SEX, for a forest plot.;
    %cox(
         data   = adttde
       , var    = aval
       , by     = trt01a
       , within = sex
       , pairs  = "Xanomeline High Dose" "Placebo"
                # "Xanomeline Low Dose"  "Placebo"
       , out    = hr_sex
     )
    * Gives the hazard ratio against Placebo for each age group.;
    %cox(
         data   = adttde
       , var    = aval
       , by     = trt01a
       , within = agegr1
       , pairs  = "Xanomeline High Dose" "Placebo"
                # "Xanomeline Low Dose"  "Placebo"
       , out    = hr_age
     )
    * Uses the Breslow ties, and as p value the log rank test of the two groups of each pair.;
    %cox(
         data   = adttde
       , var    = aval
       , by     = trt01a
       , pairs  = "Xanomeline High Dose" "Placebo"
                # "Xanomeline Low Dose"  "Placebo"
       , ties   = breslow
       , pvalue = logrank
       , out    = ttde_hr_lr
     )
    TITLE;
    FOOTNOTE;
    /* the example of %stack */
    * Stacks four results in the order of the table: RESULT and ORD tell where each row came from.;
    %stack(age_describe age_anova sex_freq sex_chisq, out=t14_2_1)
    * Stacks the hazard ratios by sex and by age group, for one forest plot.;
    %stack(hr_sex hr_age, out=hr_sub)
    * Stacks age and the age groups by sex: the results of a table with a page per sex.;
    %stack(age_sex agegr_sex, out=t14_1_1)
    TITLE;
    FOOTNOTE;
    /* the example of %columns */
    * Makes the four columns with their N from adsl, the Total last, in the order of TRT01AN.;
    %columns(
         data  = t14_2_1
       , n     = adsl
       , var   = trt01a
       , order = trt01an
       , total = yes
       , out   = t14_2_1_cols
     )
    * Gives page=sex: one row per column and sex, the N of each column on the page of its sex.;
    %columns(
         data  = t14_1_1
       , n     = adsl
       , var   = trt01a
       , order = trt01an
       , page  = sex
       , total = yes
       , out   = t14_1_1_cols
     )
    * Leaves out n=: the columns have no N and come in the order of their values, the Total last.;
    %columns(
         data  = t14_2_1
       , var   = trt01a
       , total = yes
       , out   = t14_2_1_cols_no_n
     )
    TITLE;
    FOOTNOTE;
    ```

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

*No output is shown for this call: it makes `f_bp_mean` for the calls after it.*

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

Named on this page: [%columns](columns.md), [%mmrm](mmrm.md), [%tte](tte.md), [%describe](describe.md), [%anova](anova.md), [%freq](freq.md), [%chisq](chisq.md), [%cox](cox.md), [%stack](stack.md).

## Proof

Its known answer: the means, SE, SD and limits, worked out by hand; ran on SAS 9.4 M9, 2026-11-27 (the cases of the 9 figure macros: 103 of 103 the same).

The known answers and test cases are kept with the development of the library, not in this repository.

The examples of this page ran on SAS 9.4 M9 on 2026-11-27, with a log free of ERROR and WARNING.

[Source of %meanplot](https://github.com/datastep-labs/sapling-sas/blob/main/macros/meanplot.sas)
