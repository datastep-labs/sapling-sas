# %stack

Stacks results one under another into one table, a block per result, in the order given.

**Procedure:** a DATA step (SET INDSNAME=) · **Family:** [Build a table](index.md#table)

## Syntax

```sas
%stack(
     <results>
   , out     =
 )
```

## Parameters

<a id="results"></a>`results` (the first value, without a keyword)
:   The results to stack: data set names separated by blanks, in the order of the blocks. Give them first, without a keyword (`%stack(a b, out=t)`), or as `results=` (`%stack(results=a b, out=t)`); a message names them `results=`. *(required)*

<a id="out"></a>`out=`
:   The name of the stacked table. *(required)*

## Result

The data set of `out=`: all rows of the results in the result shape, with two more variables: RESULT, the name of the result that the row comes from, and ORD, the place of that result in the list (1, 2, ...). A result with no row keeps its number. A result named twice has the place of its first name. [%layout](layout.md) lays out the blocks in the order of ORD.

## Details

Call it before [%columns](columns.md), [%ard](ard.md) and [%layout](layout.md), which read the stacked table. A result is the data set that a statistics macro writes ([%describe](describe.md), [%freq](freq.md), a test or a model): one row per number. Every result has the same variables, the result shape:

- the group variables, as in the data (TRT01A, AEDECOD, AVISIT ...); VERSUS: the group that a difference is made with
- GROUPS: the names of the group variables, in their order
- BLOCK: the label of the block
- STAT: the name of the statistic (n, pct, mean, pval ...)
- VALUE: the number
- TEXT: the number as printed

A block is the rows of one call in the table: the rows of one result, under its label. A DATA step of your own can write a result in the same shape. Each variable gets the longest length it has in the results, so that no text is cut.

## Examples

The examples run on the [example data](../tutorial/index.md#the-example-data) after `examples/setup.sas`. The output under each call is the output of that run. They also read `age_describe` (made by the [example of %describe](describe.md#ex-age_describe)), `age_anova` (made by the [example of %anova](anova.md#ex-age_anova)), `sex_freq` (made by the [example of %freq](freq.md#ex-sex_freq)), `sex_chisq` (made by the [example of %chisq](chisq.md#ex-sex_chisq)), `hr_sex` (made by the [example of %cox](cox.md#ex-hr_sex)), `hr_age` (made by the [example of %cox](cox.md#ex-hr_age)), `age_sex` (made by the [example of %describe](describe.md#ex-age_sex)), `agegr_sex` (made by the [example of %freq](freq.md#ex-agegr_sex)). All examples of the reference run as one program: [examples/reference.sas](https://github.com/datastep-labs/sapling-sas/blob/main/examples/reference.sas).

??? note "Before these examples: the calls that make their inputs"

    Run `examples/setup.sas`, then these calls from the examples of %tte, %describe, %anova, %freq, %chisq, %cox, in this order. Then the examples of this page run as shown.

    ```sas
    /* from the example of %tte */
    * Makes TTDE. Log NOTE: 2 subject(s) with no event and no censoring date: no record (no TRTEDT).;
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
    * Adds sex as a second BY variable: the rows of each group and sex, for a page per sex.;
    %describe(
         data  = adsl
       , var   = age
       , by    = trt01a sex
       , total = yes
       , label = "Age (years)"
       , out   = age_sex
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
    * Adds sex as a second BY variable: the age groups of each group and sex, for a page per sex.;
    %freq(
         data  = adsl
       , var   = agegr1
       , by    = trt01a sex
       , total = yes
       , label = "Age group"
       , out   = agegr_sex
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
    /* from the example of %cox */
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
    ```

<a id="ex-t14_2_1"></a>

Stacks four results in the order of the table: RESULT and ORD tell where each row came from.

```sas
%stack(age_describe age_anova sex_freq sex_chisq, out=t14_2_1)
```

```text
t14_2_1: the first 15 of 42 rows
TRT01A                SEX  RESULT        ORD  GROUPS  BLOCK        STAT           VALUE  TEXT
Placebo                    AGE_DESCRIBE    1  TRT01A  Age (years)  n                 86    86
Placebo                    AGE_DESCRIBE    1  TRT01A  Age (years)  mean    75.209302326  75.2
Placebo                    AGE_DESCRIBE    1  TRT01A  Age (years)  sd      8.5901671271  8.59
Placebo                    AGE_DESCRIBE    1  TRT01A  Age (years)  median            76  76.0
Placebo                    AGE_DESCRIBE    1  TRT01A  Age (years)  min               52    52
Placebo                    AGE_DESCRIBE    1  TRT01A  Age (years)  max               89    89
Total                      AGE_DESCRIBE    1  TRT01A  Age (years)  n                254   254
Total                      AGE_DESCRIBE    1  TRT01A  Age (years)  mean    75.086614173  75.1
Total                      AGE_DESCRIBE    1  TRT01A  Age (years)  sd      8.2462338962  8.25
Total                      AGE_DESCRIBE    1  TRT01A  Age (years)  median            77  77.0
Total                      AGE_DESCRIBE    1  TRT01A  Age (years)  min               51    51
Total                      AGE_DESCRIBE    1  TRT01A  Age (years)  max               89    89
Xanomeline High Dose       AGE_DESCRIBE    1  TRT01A  Age (years)  n                 72    72
Xanomeline High Dose       AGE_DESCRIBE    1  TRT01A  Age (years)  mean    73.777777778  73.8
Xanomeline High Dose       AGE_DESCRIBE    1  TRT01A  Age (years)  sd      7.9438562002  7.94
```

<a id="ex-hr_sub"></a>

Stacks the hazard ratios by sex and by age group, for one forest plot.

```sas
%stack(hr_sex hr_age, out=hr_sub)
```

```text
hr_sub: the first 15 of 32 rows
TRT01A                VERSUS   SEX  AGEGR1  RESULT  ORD  GROUPS             BLOCK  STAT         VALUE  TEXT
Xanomeline High Dose  Placebo  F            HR_SEX    1  TRT01A VERSUS SEX         hr    1.7908593572  1.79
Xanomeline High Dose  Placebo  F            HR_SEX    1  TRT01A VERSUS SEX         lcl   0.8297250323  0.83
Xanomeline High Dose  Placebo  F            HR_SEX    1  TRT01A VERSUS SEX         ucl   3.8653494983  3.87
Xanomeline High Dose  Placebo  F            HR_SEX    1  TRT01A VERSUS SEX         pval  0.1376926451  0.138
Xanomeline High Dose  Placebo  M            HR_SEX    1  TRT01A VERSUS SEX         hr    7.8320389304  7.83
Xanomeline High Dose  Placebo  M            HR_SEX    1  TRT01A VERSUS SEX         lcl    3.332064388  3.33
Xanomeline High Dose  Placebo  M            HR_SEX    1  TRT01A VERSUS SEX         ucl   18.409258245  18.41
Xanomeline High Dose  Placebo  M            HR_SEX    1  TRT01A VERSUS SEX         pval  2.3559352E-6  <0.001
Xanomeline Low Dose   Placebo  F            HR_SEX    1  TRT01A VERSUS SEX         hr    2.1688272277  2.17
Xanomeline Low Dose   Placebo  F            HR_SEX    1  TRT01A VERSUS SEX         lcl   1.0829395982  1.08
Xanomeline Low Dose   Placebo  F            HR_SEX    1  TRT01A VERSUS SEX         ucl    4.343558543  4.34
Xanomeline Low Dose   Placebo  F            HR_SEX    1  TRT01A VERSUS SEX         pval  0.0289016047  0.029
Xanomeline Low Dose   Placebo  M            HR_SEX    1  TRT01A VERSUS SEX         hr    5.3793520332  5.38
Xanomeline Low Dose   Placebo  M            HR_SEX    1  TRT01A VERSUS SEX         lcl   2.1988056105  2.20
Xanomeline Low Dose   Placebo  M            HR_SEX    1  TRT01A VERSUS SEX         ucl   13.160521402  13.16
```

<a id="ex-t14_1_1"></a>

Stacks age and the age groups by sex: the results of a table with a page per sex.

```sas
%stack(age_sex agegr_sex, out=t14_1_1)
```

```text
t14_1_1: the first 15 of 80 rows
TRT01A   SEX  AGEGR1  RESULT   ORD  GROUPS      BLOCK        STAT           VALUE  TEXT
Placebo  F            AGE_SEX    1  TRT01A SEX  Age (years)  n                 53    53
Placebo  F            AGE_SEX    1  TRT01A SEX  Age (years)  mean    76.358490566  76.4
Placebo  F            AGE_SEX    1  TRT01A SEX  Age (years)  sd      8.7334334151  8.73
Placebo  F            AGE_SEX    1  TRT01A SEX  Age (years)  median            78  78.0
Placebo  F            AGE_SEX    1  TRT01A SEX  Age (years)  min               59    59
Placebo  F            AGE_SEX    1  TRT01A SEX  Age (years)  max               89    89
Placebo  M            AGE_SEX    1  TRT01A SEX  Age (years)  n                 33    33
Placebo  M            AGE_SEX    1  TRT01A SEX  Age (years)  mean    73.363636364  73.4
Placebo  M            AGE_SEX    1  TRT01A SEX  Age (years)  sd      8.1463879335  8.15
Placebo  M            AGE_SEX    1  TRT01A SEX  Age (years)  median            74  74.0
Placebo  M            AGE_SEX    1  TRT01A SEX  Age (years)  min               52    52
Placebo  M            AGE_SEX    1  TRT01A SEX  Age (years)  max               85    85
Total    F            AGE_SEX    1  TRT01A SEX  Age (years)  n                143   143
Total    F            AGE_SEX    1  TRT01A SEX  Age (years)  mean     75.65034965  75.7
Total    F            AGE_SEX    1  TRT01A SEX  Age (years)  sd       8.193314641  8.19
```

## Messages

A wrong call writes the message and its fix to the log and stops. The macro also gives the [messages every macro shares](index.md#messages-every-macro-shares).

| Message | Fix |
|---|---|
| results=&lt;ds&gt; does not exist | give results= results that exist (make them first). |

## See also

Build a table: [%columns](columns.md), [%ard](ard.md), [%layout](layout.md), [%print](print.md), [%csv](csv.md).

Named on this page: [%describe](describe.md), [%freq](freq.md).

Guides that use %stack: [Tutorial: your first table](../tutorial/index.md), [Make an adverse event table](../how-to/adverse-event-table.md), [Check a table against an independent program](../how-to/check-a-table.md), [Make a demographic table with tests](../how-to/demographic-table.md), [Make an efficacy table with an ANCOVA](../how-to/efficacy-table.md), [Use the macros in your own program](../how-to/own-program.md), [Make one page per subgroup](../how-to/page-per-subgroup.md).

## Proof

The tables of a made-up study: every program ran with a clean log, and 570 of 570 numbers the same as those of a second program in R; ran on SAS 9.4 M9, 2026-11-12.

The examples of this page ran on SAS 9.4 M9 on 2026-11-27, with a log free of ERROR and WARNING.

Used in the proof against pharmaverse: [t14_2_01](https://github.com/datastep-labs/sapling-sas/blob/main/proof/pilot1/programs/t14_2_01.sas) (R Submission Pilot 1), [t14_3_01](https://github.com/datastep-labs/sapling-sas/blob/main/proof/pilot1/programs/t14_3_01.sas) (R Submission Pilot 1), [t14_3_02](https://github.com/datastep-labs/sapling-sas/blob/main/proof/pilot1/programs/t14_3_02.sas) (R Submission Pilot 1), [adverse_events](https://github.com/datastep-labs/sapling-sas/blob/main/proof/pharmaverse/programs/adverse_events.sas) (pharmaverse examples), [demographic](https://github.com/datastep-labs/sapling-sas/blob/main/proof/pharmaverse/programs/demographic.sas) (pharmaverse examples). See [what the proof shows](../explanation/proof.md).

[Source of %stack](https://github.com/datastep-labs/sapling-sas/blob/main/macros/stack.sas)
