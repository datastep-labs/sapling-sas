# %adjust

Adds the adjusted p-values of a family of pairs of groups to a result: one row padj per pair.

**Procedure:** PROC MULTTEST (INPVALUES=); a DATA step · **Family:** [Test the groups](index.md#tests)

## Syntax

```sas
%adjust(
     data    =
   , by      =
   , family  =
   , method  =
   , weights =
   , pattern = "X.XXX"
   , out     =
   , debug   = no
 )
```

## Parameters

`data=`
:   A result of pairs with the variables of `by=`, VERSUS, STAT and VALUE: the `out=` of [%lsmeans](lsmeans.md), [%mmrm](mmrm.md), [%cox](cox.md) and the other macros of pairs. *(required)*

`by=`
:   The groups: the variable of `data=` with the group of each pair (`by = trt01p`). *(required)*

`family=`
:   The pairs of the family in their order, separated by #: each the group first and then the group it is compared with, each value in quotes: `family = "High"` "Placebo" # "Low" "Placebo". The old form "A"-"B" is still read. *(required)*

`method=`
:   The adjustment: bonferroni, holm, hochberg or hierarchy. *(required)*
    Accepts: `bonferroni`, `holm`, `hochberg`, `hierarchy`.

`weights=`
:   The weights of a weighted Bonferroni test: one number per pair, in the order of `family=`, separated by blanks (`weights = 0.8 0.2`). Only with method=bonferroni. *(optional)*

`pattern=`
:   The pattern of the printed adjusted p-value, in quotes. *(optional, default `"X.XXX"`)*

`out=`
:   The name of the result data set. *(required)*

`debug=`
:   yes: keep the work data sets _adjust_*. *(optional, default `no`)*
    Accepts: `yes`, `no`.

## Result

The data set of `out=`: the rows of `data=`, then one row per pair of the family with STAT padj, VALUE the adjusted p-value and TEXT the printed value. When `data=` has no p-value of a pair of `family=`, `out=` is `data=` as it is and the log has a NOTE.

## Details

Use it after [%lsmeans](lsmeans.md), [%mmrm](mmrm.md), [%cox](cox.md), [%logistic](logistic.md), [%risk](risk.md), [%rateratio](rateratio.md), [%ttest](ttest.md) or [%wilcoxon](wilcoxon.md): it reads their rows with STAT pval. The family is the hypotheses of one multiplicity block: the pairs of `family=`, in their order. `method=` gives the adjustment:

- bonferroni: Bonferroni (PROC MULTTEST); with `weights=`, the weighted Bonferroni test in a DATA step (the p-value divided by its weight, at most 1)
- holm: Holm, the step-down Bonferroni test (PROC MULTTEST STEPBON)
- hochberg: Hochberg (PROC MULTTEST)
- hierarchy: the fixed sequence in a DATA step; each adjusted p-value is the largest p-value of its hypothesis and of the hypotheses before it

Every row of `data=` with STAT pval and a pair of `family=` is one hypothesis of the family. When `data=` has a pair in several rows (the terms, visits or subgroups of `within=`), all of them are adjusted together, as one family. For a family in each term, call %adjust once per term, on a data set with only the rows of that term (a DATA step with WHERE first).

## Examples

The examples run on the [example data](../tutorial/index.md#the-example-data) after `examples/setup.sas`. The output under each call is the output of that run. They also read `sbp_ls` (made by the [example of %lsmeans](lsmeans.md#examples)).

```sas
%adjust(
     data   = sbp_ls
   , by     = trt01p
   , family = "Xanomeline High Dose" "Placebo"
            # "Xanomeline Low Dose"  "Placebo"
   , method = hochberg
   , out    = sbp_adj
 )
```

```text
sbp_adj, the rows of the p-values where stat IN ('pval' 'padj'): 5 rows
TRT01P                VERSUS               GROUPS         STAT         VALUE   TEXT
Xanomeline High Dose  Placebo              TRT01P VERSUS  pval  0.0383969398  0.038
Xanomeline High Dose  Xanomeline Low Dose  TRT01P VERSUS  pval  0.0707974243  0.071
Xanomeline Low Dose   Placebo              TRT01P VERSUS  pval  0.9584423033  0.958
Xanomeline High Dose  Placebo              TRT01P VERSUS  padj  0.0767938796  0.077
Xanomeline Low Dose   Placebo              TRT01P VERSUS  padj  0.9584423033  0.958
```

## Messages

The macro gives only the [messages every macro shares](index.md#messages-every-macro-shares).

## See also

Test the groups: [%anova](anova.md), [%ttest](ttest.md), [%wilcoxon](wilcoxon.md), [%chisq](chisq.md), [%fisher](fisher.md), [%cmh](cmh.md), [%ancova](ancova.md).

Named on this page: [%lsmeans](lsmeans.md), [%mmrm](mmrm.md), [%cox](cox.md), [%logistic](logistic.md), [%risk](risk.md), [%rateratio](rateratio.md).

## Proof

Checked against its known answers: numbers worked out independently in R, compared on SAS by the tests of the library.

The examples of this page ran on SAS 9.4M9 on 2026-11-27, with a log free of ERROR and WARNING.

[Source of %adjust](https://github.com/datastep-labs/sapling-sas/blob/main/macros/adjust.sas)
