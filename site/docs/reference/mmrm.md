# %mmrm

Returns the differences of the LS means of pairs of groups at one visit from a repeated measures mixed model.

**Procedure:** PROC MIXED (REPEATED, LSMEANS) · **Family:** [Compare groups with a model](index.md#models)

## Syntax

```sas
%mmrm(
     data     =
   , where    =
   , var      =
   , by       =
   , visit    =
   , at       =
   , class    =
   , subject  = USUBJID
   , model    =
   , type     = un
   , fallback =
   , ddfm     = bw
   , method   = reml
   , pairs    = all
   , order    =
   , level    = 0.95
   , stats    = diff="XX.X" diff_se="XX.XX" lcl="XX.X" ucl="XX.X" pval="X.XXX"
   , label    =
   , out      =
   , debug    = no
 )
```

## Parameters

`data=`
:   The input data set: one record per subject and visit. *(required)*

`where=`
:   The records to use: a condition in parentheses, such as `where = (paramcd = 'SYSBP' AND anl01fl = 'Y')`. *(optional)*

`var=`
:   The response: one numeric variable. *(required)*

`by=`
:   The groups: one character variable. *(required)*

`visit=`
:   The visit: one variable, the repeated factor of the REPEATED statement. The macro adds it to the class factors. *(required)*

`at=`
:   The visit of the LS means and their differences: a value of `visit=` in quotes (`at = "Week 24"`). *(required)*

`class=`
:   The class factors besides the groups and the subject: variables separated by blanks. *(optional)*

`subject=`
:   The subject: one variable. *(optional, default `USUBJID`)*

`model=`
:   The fixed effects: the MODEL statement after the equal sign. It must have the term of the groups by visit: `model = base trt01p avisit trt01p*avisit`. *(required)*

`type=`
:   The covariance structure: TYPE= of REPEATED (un, cs, ar(1), toep ...). *(optional, default `un`)*

`fallback=`
:   Other covariance structures to try in their order when one does not converge, separated by blanks (`fallback = toep cs`). *(optional)*

`ddfm=`
:   The degrees of freedom: DDFM= of MODEL (bw is between-within, kr is Kenward-Roger). *(optional, default `bw`)*

`method=`
:   The estimation method: reml or ml. *(optional, default `reml`)*

`pairs=`
:   The pairs of groups to compare. all: each later group against each earlier one, in the order of `order=` (or of the values). Or the pairs separated by #, each the group first and then the group it is compared with, a value with a blank or a hyphen in quotes: `pairs = "Drug" "Placebo" # "High" "Low"`. *(optional, default `all`)*

`order=`
:   The order of the groups: one numeric variable with one value per group (`order = trt01pn`). *(optional)*

`level=`
:   The confidence level of the limits: a number between 0 and 1. *(optional, default `0.95`)*

`stats=`
:   The statistics, in the order of the rows: each name with the pattern of its printed number, separated by blanks. The names are diff, diff_se, lcl, ucl, pval, lsmean and lsmean_se. A name without a pattern takes its default pattern (n="XX", mean="XX.X", pval="X.XXX" ...; see [%describe](describe.md)). *(optional, default `diff="XX.X" diff_se="XX.XX" lcl="XX.X" ucl="XX.X" pval="X.XXX"`)*

`label=`
:   The label of the block in the table: a text in quotes. A block is the rows of one call in the table. *(optional)*

`out=`
:   The name of the result data set. *(required)*

`debug=`
:   yes: keep the work data sets _mmrm_*. *(optional, default `no`)*
    Accepts: `yes`, `no`.

## Result

The data set of `out=`: the [result shape](../explanation/result-shape.md), as in [%lsmeans](lsmeans.md). A row of a difference has the group in the `by=` variable and the group it is compared with in VERSUS; a row of an LS mean has VERSUS blank. GROUPS is the `by=` variable and VERSUS. When no structure converges, the macro stops with an ERROR and writes no result.

## Details

Use [%lsmeans](lsmeans.md) for one record per subject, and [%ancova](ancova.md) for the test of one numeric term. The model is PROC MIXED with a REPEATED statement: one record per subject and visit (the first with a value). When the covariance structure of `type=` does not converge, the macro tries the structures of `fallback=` in their order. The log names the structure used, in a NOTE such as "[mmrm] The covariance structure TYPE=un converged." (a structure that did not converge has its own NOTE, and the WARNING lines of PROC MIXED of that fit are not used). The macro adds `visit=` to the class factors: `class=` needs only the others. The LS mean of each group at the visit comes when `stats=` asks for it.

!!! note "Good to know"

    The model is fitted by iteration: another program gives the same numbers to about five digits, not to the last one. A structure may converge in one program and not in the other. On visits that are very closely correlated, PROC MIXED stops AR(1) with an infinite likelihood where the function mmrm() of the R package sapling converges, so the same call may use the next structure of `fallback=` in SAS. The NOTE "[mmrm] The covariance structure TYPE=... converged" names the structure used. The WARNING lines of a fit that did not converge are followed by a NOTE that says so.

## Examples

The examples run on the [example data](../tutorial/index.md#the-example-data) after `examples/setup.sas`. The output under each call is the output of that run.

Fits the MMRM of the change at five visits and compares the groups at Week 24.

```sas
%mmrm(
     data     = advs
   , where    = (paramcd = 'SYSBP' AND anl01fl = 'Y' AND avisitn IN (4 8 12 16 24))
   , var      = chg
   , by       = trt01p
   , visit    = avisit
   , at       = "Week 24"
   , model    = base trt01p avisit trt01p*avisit base*avisit
   , type     = un
   , fallback = toep
   , pairs    = all
   , order    = trt01pn
   , out      = sbp_mmrm
 )
```

```text
sbp_mmrm: 15 rows
TRT01P                VERSUS               GROUPS         BLOCK  STAT            VALUE   TEXT
Xanomeline High Dose  Placebo              TRT01P VERSUS         diff     -4.201385478   -4.2
Xanomeline High Dose  Placebo              TRT01P VERSUS         diff_se  2.8735794511   2.87
Xanomeline High Dose  Placebo              TRT01P VERSUS         lcl      -9.866781474   -9.9
Xanomeline High Dose  Placebo              TRT01P VERSUS         ucl       1.464010518    1.5
Xanomeline High Dose  Placebo              TRT01P VERSUS         pval     0.1452448096  0.145
Xanomeline High Dose  Xanomeline Low Dose  TRT01P VERSUS         diff     -4.763463558   -4.8
Xanomeline High Dose  Xanomeline Low Dose  TRT01P VERSUS         diff_se  3.3442556767   3.34
Xanomeline High Dose  Xanomeline Low Dose  TRT01P VERSUS         lcl       -11.3568197  -11.4
Xanomeline High Dose  Xanomeline Low Dose  TRT01P VERSUS         ucl      1.8298925831    1.8
Xanomeline High Dose  Xanomeline Low Dose  TRT01P VERSUS         pval     0.1558519544  0.156
Xanomeline Low Dose   Placebo              TRT01P VERSUS         diff     0.5620780798    0.6
Xanomeline Low Dose   Placebo              TRT01P VERSUS         diff_se  2.9635317687   2.96
Xanomeline Low Dose   Placebo              TRT01P VERSUS         lcl      -5.280663109   -5.3
Xanomeline Low Dose   Placebo              TRT01P VERSUS         ucl      6.4048192683    6.4
Xanomeline Low Dose   Placebo              TRT01P VERSUS         pval     0.8497584465  0.850
```

## Messages

A wrong call writes the message and its fix to the log and stops. The macro also gives the [messages every macro shares](index.md#messages-every-macro-shares).

| Message | Fix |
|---|---|
| no covariance structure of type=&lt;type&gt; fallback=&lt;fallback&gt; converged | give fallback= more types (cs, ar(1), toep) or check it. |

## See also

Compare groups with a model: [%lsmeans](lsmeans.md), [%logistic](logistic.md), [%risk](risk.md), [%rateratio](rateratio.md).

Named on this page: [%describe](describe.md), [%ancova](ancova.md).

Guides that use %mmrm: [Make an efficacy table with an ANCOVA](../how-to/efficacy-table.md), [Run the examples of the reference](../how-to/run-the-examples.md).

## Proof

Checked against its known answers: numbers worked out independently in R and compared on SAS by the tests of the library (the tests are kept with the development of the library, not in this repository).

The examples of this page ran on SAS 9.4M9 on 2026-11-27, with a log free of ERROR and WARNING.

[Source of %mmrm](https://github.com/datastep-labs/sapling-sas/blob/main/macros/mmrm.sas)
