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

`results` (the first value, without a keyword)
:   The results to stack: data set names separated by blanks, in the order of the blocks. *(required)*

`out=`
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

The examples run on the [example data](../tutorial/index.md#the-example-data) after `examples/setup.sas`. The output under each call is the output of that run. They also read `age_describe` (made by the [example of %describe](describe.md#examples)), `age_anova` (made by the [example of %anova](anova.md#examples)), `sex_freq` (made by the [example of %freq](freq.md#examples)), `sex_chisq` (made by the [example of %chisq](chisq.md#examples)), `hr_sex` (made by the [example of %cox](cox.md#examples)), `hr_age` (made by the [example of %cox](cox.md#examples)).

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

## Messages

A wrong call writes the message and its fix to the log and stops. The macro also gives the [messages every macro shares](index.md#messages-every-macro-shares).

| Message | Fix |
|---|---|
| results=&lt;ds&gt; does not exist | give results= results that exist (make them first). |

## See also

Build a table: [%columns](columns.md), [%ard](ard.md), [%layout](layout.md), [%print](print.md), [%csv](csv.md).

Named on this page: [%describe](describe.md), [%freq](freq.md).

## Proof

The examples of this page ran on SAS 9.4M9 on 2026-11-27, with a log free of ERROR and WARNING.

Used in the proof against pharmaverse: [t14_2_01](https://github.com/datastep-labs/sapling-sas/blob/main/proof/pilot1/programs/t14_2_01.sas) (R Submission Pilot 1), [t14_3_01](https://github.com/datastep-labs/sapling-sas/blob/main/proof/pilot1/programs/t14_3_01.sas) (R Submission Pilot 1), [t14_3_02](https://github.com/datastep-labs/sapling-sas/blob/main/proof/pilot1/programs/t14_3_02.sas) (R Submission Pilot 1), [adverse_events](https://github.com/datastep-labs/sapling-sas/blob/main/proof/pharmaverse/programs/adverse_events.sas) (pharmaverse examples), [demographic](https://github.com/datastep-labs/sapling-sas/blob/main/proof/pharmaverse/programs/demographic.sas) (pharmaverse examples). See [what the proof shows](../explanation/proof.md).

[Source of %stack](https://github.com/datastep-labs/sapling-sas/blob/main/macros/stack.sas)
