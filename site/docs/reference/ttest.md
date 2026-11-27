# %ttest

Returns the difference of the means of each pair of groups, with its confidence limits and the t-test p-value.

**Procedure:** PROC TTEST · **Family:** [Test the groups](index.md#tests)

## Syntax

```sas
%ttest(
     data      =
   , where     =
   , var       =
   , by        =
   , pairs     = all
   , order     =
   , variances = equal
   , level     = 0.95
   , stats     = diff="XX.X" diff_se="XX.XX" lcl="XX.X" ucl="XX.X" pval="X.XXX"
   , label     =
   , out       =
   , debug     = no
 )
```

## Parameters

<a id="data"></a>`data=`
:   The input data set: one record per subject, with USUBJID. *(required)*

<a id="where"></a>`where=`
:   The records to use: a condition in parentheses, such as `where = (avisit = 'Week 24')`. *(optional)*

<a id="var"></a>`var=`
:   The variable to compare: one numeric variable. *(required)*

<a id="by"></a>`by=`
:   The groups: one character variable (trt01a, not trt01an). *(required)*

<a id="pairs"></a>`pairs=`
:   Which groups to compare. all: each later group against each earlier one, in the order of `order=` (else of the values). Or the pairs, separated by #: in each pair the group first, then the group it is compared with, each value in quotes (`pairs = "Drug" "Placebo" # "High" "Low"`). *(optional, default `all`)*

<a id="order"></a>`order=`
:   The order of the groups: one numeric variable with one value per group (`order = trt01an`). *(optional)*

<a id="variances"></a>`variances=`
:   equal (Student's test, the Pooled row of PROC TTEST) or unequal (Welch's test, the Satterthwaite row). *(optional, default `equal`)*
    Accepts: `equal`, `unequal`.

<a id="level"></a>`level=`
:   The confidence level: a number between 0 and 1 (`level = 0.90`). *(optional, default `0.95`)*

<a id="stats"></a>`stats=`
:   The statistics, in the order of the rows: each name with its pattern of the printed number, separated by blanks. The names are diff, diff_se, lcl, ucl and pval. A name without a pattern takes its default pattern: see the [table of default patterns](../explanation/numbers.md#the-table-of-default-patterns). *(optional, default `diff="XX.X" diff_se="XX.XX" lcl="XX.X" ucl="XX.X" pval="X.XXX"`)*

<a id="label"></a>`label=`
:   The label of the block in the table: a text in quotes. A block is the rows of one call in the table. *(optional)*

<a id="out"></a>`out=`
:   The name of the result data set. *(required)*

<a id="debug"></a>`debug=`
:   yes: keep the work data sets _ttest_*. *(optional, default `no`)*
    Accepts: `yes`, `no`.

## Result

The data set of `out=`: the [result shape](../explanation/result-shape.md), one row per pair and statistic: the variable of `by=` (the group), VERSUS (the group it is compared with), GROUPS (by= and VERSUS), BLOCK, STAT, VALUE and TEXT. When no record qualifies, the result has no row.

## Details

Use [%wilcoxon](wilcoxon.md) when the values are not normal, [%anova](anova.md) for one test of all the groups, and [%lsmeans](lsmeans.md) for a model with covariates. The test is the two-sample t-test of PROC TTEST, run BY each pair, the group first. The statistics:

- diff: the mean of the group minus the mean of the group it is compared with
- diff_se: the standard error of diff
- lcl, ucl: the confidence limits of diff
- pval: the two-sided p-value, of Student's test with the pooled variance (variances=equal) or of Welch's test with Satterthwaite's degrees of freedom (variances=unequal)

The macro uses one record per subject: when a subject has several records, the first one.

## Examples

The examples run on the [example data](../tutorial/index.md#the-example-data) after `examples/setup.sas`. The output under each call is the output of that run. All examples of the reference run as one program: [examples/reference.sas](https://github.com/datastep-labs/sapling-sas/blob/main/examples/reference.sas).

<a id="ex-sbp_t"></a>

Compares each pair of groups with the pooled t test: the difference, its SE, limits and p value.

```sas
%ttest(
     data  = advs
   , where = (paramcd = 'SYSBP' AND avisit = 'Week 12' AND anl01fl = 'Y')
   , var   = chg
   , by    = trt01p
   , order = trt01pn
   , out   = sbp_t
 )
```

```text
sbp_t: 15 rows
TRT01P                VERSUS               GROUPS         BLOCK  STAT            VALUE   TEXT
Xanomeline Low Dose   Placebo              TRT01P VERSUS         diff     0.7083931133    0.7
Xanomeline Low Dose   Placebo              TRT01P VERSUS         diff_se   3.123066813   3.12
Xanomeline Low Dose   Placebo              TRT01P VERSUS         lcl      -5.482722601   -5.5
Xanomeline Low Dose   Placebo              TRT01P VERSUS         ucl      6.8995088274    6.9
Xanomeline Low Dose   Placebo              TRT01P VERSUS         pval     0.8209917415  0.821
Xanomeline High Dose  Placebo              TRT01P VERSUS         diff     -6.267216643   -6.3
Xanomeline High Dose  Placebo              TRT01P VERSUS         diff_se  3.1425443026   3.14
Xanomeline High Dose  Placebo              TRT01P VERSUS         lcl      -12.49694421  -12.5
Xanomeline High Dose  Placebo              TRT01P VERSUS         ucl      -0.037489077    0.0
Xanomeline High Dose  Placebo              TRT01P VERSUS         pval     0.0486613727  0.049
Xanomeline High Dose  Xanomeline Low Dose  TRT01P VERSUS         diff     -6.975609756   -7.0
Xanomeline High Dose  Xanomeline Low Dose  TRT01P VERSUS         diff_se  3.6118443202   3.61
Xanomeline High Dose  Xanomeline Low Dose  TRT01P VERSUS         lcl      -14.16340902  -14.2
Xanomeline High Dose  Xanomeline Low Dose  TRT01P VERSUS         ucl      0.2121895088    0.2
Xanomeline High Dose  Xanomeline Low Dose  TRT01P VERSUS         pval     0.0569857411  0.057
```

<a id="ex-sbp_welch"></a>

Uses the Welch test of unequal variances on two pairs: the SE, limits and p value change.

```sas
%ttest(
     data      = advs
   , where     = (paramcd = 'SYSBP' AND avisit = 'Week 12' AND anl01fl = 'Y')
   , var       = chg
   , by        = trt01p
   , pairs     = "Xanomeline High Dose" "Placebo"
               # "Xanomeline Low Dose"  "Placebo"
   , variances = unequal
   , out       = sbp_welch
 )
```

```text
sbp_welch: 10 rows
TRT01P                VERSUS   GROUPS         BLOCK  STAT            VALUE   TEXT
Xanomeline High Dose  Placebo  TRT01P VERSUS         diff     -6.267216643   -6.3
Xanomeline High Dose  Placebo  TRT01P VERSUS         diff_se  3.1894074953   3.19
Xanomeline High Dose  Placebo  TRT01P VERSUS         lcl      -12.61370136  -12.6
Xanomeline High Dose  Placebo  TRT01P VERSUS         ucl      0.0792680723    0.1
Xanomeline High Dose  Placebo  TRT01P VERSUS         pval     0.0528614429  0.053
Xanomeline Low Dose   Placebo  TRT01P VERSUS         diff     0.7083931133    0.7
Xanomeline Low Dose   Placebo  TRT01P VERSUS         diff_se  3.1573187414   3.16
Xanomeline Low Dose   Placebo  TRT01P VERSUS         lcl      -5.573037559   -5.6
Xanomeline Low Dose   Placebo  TRT01P VERSUS         ucl       6.989823786    7.0
Xanomeline Low Dose   Placebo  TRT01P VERSUS         pval     0.8230341672  0.823
```

## Messages

A wrong call writes the message and its fix to the log and stops. The macro also gives the [messages every macro shares](index.md#messages-every-macro-shares).

| Message | Fix |
|---|---|
| by=&lt;by&gt; is numeric | give by= a character group (TRT01A, not TRT01AN). |
| pairs= names the group "&lt;group&gt;", and no record has it. | give pairs= the values of &lt;by&gt; as the data have them. |

## See also

Test the groups: [%anova](anova.md), [%wilcoxon](wilcoxon.md), [%chisq](chisq.md), [%fisher](fisher.md), [%cmh](cmh.md), [%ancova](ancova.md), [%adjust](adjust.md).

Named on this page: [%lsmeans](lsmeans.md).

## Proof

Checked against its known answer (on a small data set, the numbers worked out independently in R); ran on SAS 9.4 M9, 2026-11-12.

The known answers and test cases are kept with the development of the library, not in this repository.

The examples of this page ran on SAS 9.4 M9 on 2026-11-27, with a log free of ERROR and WARNING.

[Source of %ttest](https://github.com/datastep-labs/sapling-sas/blob/main/macros/ttest.sas)
