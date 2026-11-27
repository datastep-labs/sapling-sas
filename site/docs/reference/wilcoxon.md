# %wilcoxon

Returns the p-value of the Wilcoxon rank-sum test of each pair of groups, with the Hodges-Lehmann shift and its limits.

**Procedure:** PROC NPAR1WAY (WILCOXON, HL) · **Family:** [Test the groups](index.md#tests)

## Syntax

```sas
%wilcoxon(
     data       =
   , where      =
   , var        =
   , by         =
   , pairs      = all
   , order      =
   , correction = yes
   , level      = 0.95
   , stats      = estimate="XX.XX" lcl="XX.XX" ucl="XX.XX" pval="X.XXX"
   , label      =
   , out        =
   , debug      = no
 )
```

## Parameters

`data=`
:   The input data set: one record per subject, with USUBJID. *(required)*

`where=`
:   The records to use: a condition in parentheses, such as where = (`avisit = 'Week 24'`). *(optional)*

`var=`
:   The variable to compare: one numeric variable. *(required)*

`by=`
:   The groups: one character variable (trt01a, not trt01an). *(required)*

`pairs=`
:   Which groups to compare. all: each later group against each earlier one, in the order of `order=` (else of the values). Or the pairs, separated by #: in each pair the group first, then the group it is compared with, each value in quotes (`pairs = "Drug"` "Placebo" # "High" "Low"). The form "A"-"B" of version 1.0 is still read. *(optional, default `all`)*

`order=`
:   The order of the groups: one numeric variable with one value per group (`order = trt01an`). *(optional)*

`correction=`
:   yes: the continuity correction of the normal approximation; no: none. *(optional, default `yes`)*
    Accepts: `yes`, `no`.

`level=`
:   The confidence level: a number between 0 and 1 (`level = 0.90`). *(optional, default `0.95`)*

`stats=`
:   The statistics, in the order of the rows: each name with its pattern of the printed number, separated by blanks. The names are estimate, lcl, ucl and pval. A name without a pattern takes its default pattern (n="XX", mean="XX.X", pval="X.XXX" ...; see [%describe](describe.md)). *(optional, default `estimate="XX.XX" lcl="XX.XX" ucl="XX.XX" pval="X.XXX"`)*

`label=`
:   The label of the block in the table: a text in quotes. A block is the rows of one call in the table. *(optional)*

`out=`
:   The name of the result data set. *(required)*

`debug=`
:   yes: keep the work data sets _wilcoxon_*. *(optional, default `no`)*
    Accepts: `yes`, `no`.

## Result

The data set of `out=`: the [result shape](../explanation/result-shape.md), one row per pair and statistic: the variable of `by=` (the group), VERSUS (the group it is compared with), GROUPS (by= and VERSUS), BLOCK, STAT, VALUE and TEXT. When no record qualifies, the result has no row.

## Details

Use [%ttest](ttest.md) when the values are normal and the difference of the means is wanted. The test runs in PROC NPAR1WAY, BY each pair, the group first. The statistics:

- pval: the two-sided p-value of the normal approximation, with the continuity correction when correction=yes (CORRECT=)
- estimate: the Hodges-Lehmann estimate of the shift, the group minus the group it is compared with (HL)
- lcl, ucl: the asymptotic (Moses) confidence limits of the shift

The macro uses one record per subject: when a subject has several records, the first one.

## Examples

The examples run on the [example data](../tutorial/index.md#the-example-data) after `examples/setup.sas`. The output under each call is the output of that run.

```sas
%wilcoxon(
     data  = advs
   , where = (paramcd = 'DIABP' AND avisit = 'Week 12' AND anl01fl = 'Y')
   , var   = chg
   , by    = trt01p
   , order = trt01pn
   , out   = dbp_w
 )
```

```text
dbp_w: 12 rows
TRT01P                VERSUS               GROUPS         BLOCK  STAT             VALUE   TEXT
Xanomeline Low Dose   Placebo              TRT01P VERSUS         estimate             2   2.00
Xanomeline Low Dose   Placebo              TRT01P VERSUS         lcl                 -2  -2.00
Xanomeline Low Dose   Placebo              TRT01P VERSUS         ucl                  6   6.00
Xanomeline Low Dose   Placebo              TRT01P VERSUS         pval      0.2765584664  0.277
Xanomeline High Dose  Placebo              TRT01P VERSUS         estimate             0   0.00
Xanomeline High Dose  Placebo              TRT01P VERSUS         lcl                 -4  -4.00
Xanomeline High Dose  Placebo              TRT01P VERSUS         ucl                  4   4.00
Xanomeline High Dose  Placebo              TRT01P VERSUS         pval      0.9076363917  0.908
Xanomeline High Dose  Xanomeline Low Dose  TRT01P VERSUS         estimate            -2  -2.00
Xanomeline High Dose  Xanomeline Low Dose  TRT01P VERSUS         lcl                 -6  -6.00
Xanomeline High Dose  Xanomeline Low Dose  TRT01P VERSUS         ucl                  2   2.00
Xanomeline High Dose  Xanomeline Low Dose  TRT01P VERSUS         pval       0.202676797  0.203
```

```sas
%wilcoxon(
     data       = advs
   , where      = (paramcd = 'DIABP' AND avisit = 'Week 12' AND anl01fl = 'Y')
   , var        = chg
   , by         = trt01p
   , pairs      = "Xanomeline High Dose" "Placebo"
   , correction = no
   , out        = dbp_w_nocc
 )
```

```text
dbp_w_nocc: 4 rows
TRT01P                VERSUS   GROUPS         BLOCK  STAT             VALUE   TEXT
Xanomeline High Dose  Placebo  TRT01P VERSUS         estimate             0   0.00
Xanomeline High Dose  Placebo  TRT01P VERSUS         lcl                 -4  -4.00
Xanomeline High Dose  Placebo  TRT01P VERSUS         ucl                  4   4.00
Xanomeline High Dose  Placebo  TRT01P VERSUS         pval      0.9051517146  0.905
```

## Messages

The macro gives only the [messages every macro shares](index.md#messages-every-macro-shares).

## See also

Test the groups: [%anova](anova.md), [%ttest](ttest.md), [%chisq](chisq.md), [%fisher](fisher.md), [%cmh](cmh.md), [%ancova](ancova.md), [%adjust](adjust.md).

Named on this page: [%stack](stack.md), [%describe](describe.md).

## Proof

Checked against its known answers: numbers worked out independently in R, compared on SAS by the tests of the library.

The examples of this page ran on SAS 9.4M9 on 2026-11-27, with a log free of ERROR and WARNING.

[Source of %wilcoxon](https://github.com/datastep-labs/sapling-sas/blob/main/macros/wilcoxon.sas)
