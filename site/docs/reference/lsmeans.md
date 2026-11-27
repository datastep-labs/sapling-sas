# %lsmeans

The ANCOVA of the groups: returns the differences of the LS means of pairs of groups in a linear model, with confidence limits and p-values.

**Procedure:** PROC MIXED (LSMEANS) · **Family:** [Compare groups with a model](index.md#models)

## Syntax

```sas
%lsmeans(
     data   =
   , where  =
   , var    =
   , by     =
   , within =
   , covars =
   , class  =
   , pairs  = all
   , order  =
   , level  = 0.95
   , stats  = diff="XX.X" diff_se="XX.XX" lcl="XX.X" ucl="XX.X" pval="X.XXX"
   , label  =
   , out    =
   , debug  = no
 )
```

## Parameters

<a id="data"></a>`data=`
:   The input data set, with USUBJID. *(required)*

<a id="where"></a>`where=`
:   The records to use: a condition in parentheses, such as `where = (paramcd = 'SYSBP' AND avisit = 'Week 12')`. *(optional)*

<a id="var"></a>`var=`
:   The response: one numeric variable. *(required)*

<a id="by"></a>`by=`
:   The groups of the model: one character variable. *(required)*

<a id="within"></a>`within=`
:   One model in each group of these variables, separated by blanks (`within = paramcd`). *(optional)*

<a id="covars"></a>`covars=`
:   The covariates: numeric variables separated by blanks (`covars = base`). *(optional)*

<a id="class"></a>`class=`
:   The class factors besides the groups: variables separated by blanks (`class = sex`). *(optional)*

<a id="pairs"></a>`pairs=`
:   The pairs of groups to compare. all: each later group against each earlier one, in the order of `order=` (or of the values). Or the pairs separated by #, each the group first and then the group it is compared with, a value with a blank or a hyphen in quotes: `pairs = "Drug" "Placebo" # "High" "Low"`. *(optional, default `all`)*

<a id="order"></a>`order=`
:   The order of the groups: one numeric variable with one value per group (`order = trt01pn`). *(optional)*

<a id="level"></a>`level=`
:   The confidence level of the limits: a number between 0 and 1. *(optional, default `0.95`)*

<a id="stats"></a>`stats=`
:   The statistics, in the order of the rows: each name with the pattern of its printed number, separated by blanks. The names are diff, diff_se, lcl, ucl, pval, lsmean, lsmean_se, lsmean_lcl and lsmean_ucl. A name without a pattern takes its default pattern: see the [table of default patterns](../explanation/numbers.md#the-table-of-default-patterns). *(optional, default `diff="XX.X" diff_se="XX.XX" lcl="XX.X" ucl="XX.X" pval="X.XXX"`)*

<a id="label"></a>`label=`
:   The label of the block in the table: a text in quotes. A block is the rows of one call in the table. *(optional)*

<a id="out"></a>`out=`
:   The name of the result data set. *(required)*

<a id="debug"></a>`debug=`
:   yes: keep the work data sets _lsmeans_*. *(optional, default `no`)*
    Accepts: `yes`, `no`.

## Result

The data set of `out=`: the [result shape](../explanation/result-shape.md). A row of a difference has the group in the `by=` variable and the group it is compared with in VERSUS: diff is the LS mean of the group minus the LS mean of VERSUS (a negative diff: a smaller LS mean in the group), diff_se its standard error, lcl and ucl its confidence limits, pval the p-value of the test that it is 0. With pairs=all the group is the later one in the order of `order=`. A row of an LS mean has VERSUS blank. GROUPS is the `by=` variable, VERSUS and the `within=` variables.

## Details

Use [%ancova](ancova.md) for the test of one numeric term (a dose response), and [%mmrm](mmrm.md) for repeated visits of a subject. The model is PROC MIXED without a random effect (least squares): the covariates, the class factors and the groups, one record per subject (the first with a value; when `where=` leaves a second record of a subject, the log has a NOTE with their number). Give a `where=` that leaves one record per subject, such as one parameter at one visit with `anl01fl = 'Y'`; otherwise each subject has the first of its records in the order of `data=`, whichever it is. The LS mean of each group comes when `stats=` asks for it.

## Examples

The examples run on the [example data](../tutorial/index.md#the-example-data) after `examples/setup.sas`. The output under each call is the output of that run. All examples of the reference run as one program: [examples/reference.sas](https://github.com/datastep-labs/sapling-sas/blob/main/examples/reference.sas).

<a id="ex-sbp_ls"></a>

Gives the difference of the LS means of every pair at Week 12, adjusted for baseline and sex.

```sas
%lsmeans(
     data   = advs
   , where  = (paramcd = 'SYSBP' AND avisit = 'Week 12' AND anl01fl = 'Y')
   , var    = chg
   , by     = trt01p
   , covars = base
   , class  = sex
   , pairs  = all
   , order  = trt01pn
   , out    = sbp_ls
 )
```

```text
sbp_ls: 15 rows
TRT01P                VERSUS               GROUPS         BLOCK  STAT            VALUE   TEXT
Xanomeline High Dose  Placebo              TRT01P VERSUS         diff     -5.237880107   -5.2
Xanomeline High Dose  Placebo              TRT01P VERSUS         diff_se  2.5065985028   2.51
Xanomeline High Dose  Placebo              TRT01P VERSUS         lcl      -10.19207069  -10.2
Xanomeline High Dose  Placebo              TRT01P VERSUS         ucl      -0.283689527   -0.3
Xanomeline High Dose  Placebo              TRT01P VERSUS         pval     0.0383969398  0.038
Xanomeline High Dose  Xanomeline Low Dose  TRT01P VERSUS         diff     -5.107252039   -5.1
Xanomeline High Dose  Xanomeline Low Dose  TRT01P VERSUS         diff_se  2.8059410396   2.81
Xanomeline High Dose  Xanomeline Low Dose  TRT01P VERSUS         lcl      -10.65308104  -10.7
Xanomeline High Dose  Xanomeline Low Dose  TRT01P VERSUS         ucl      0.4385769613    0.4
Xanomeline High Dose  Xanomeline Low Dose  TRT01P VERSUS         pval     0.0707974243  0.071
Xanomeline Low Dose   Placebo              TRT01P VERSUS         diff     -0.130628069   -0.1
Xanomeline Low Dose   Placebo              TRT01P VERSUS         diff_se  2.5025212718   2.50
Xanomeline Low Dose   Placebo              TRT01P VERSUS         lcl      -5.076760167   -5.1
Xanomeline Low Dose   Placebo              TRT01P VERSUS         ucl      4.8155040297    4.8
Xanomeline Low Dose   Placebo              TRT01P VERSUS         pval     0.9584423033  0.958
```

<a id="ex-sbp_ls90"></a>

Without class=sex, two pairs at a 90 percent level: High Dose -5.73 here, not -5.24 as above.

```sas
%lsmeans(
     data   = advs
   , where  = (paramcd = 'SYSBP' AND avisit = 'Week 12' AND anl01fl = 'Y')
   , var    = chg
   , by     = trt01p
   , covars = base
   , pairs  = "Xanomeline High Dose" "Placebo"
            # "Xanomeline Low Dose"  "Placebo"
   , order  = trt01pn
   , level  = 0.90
   , stats  = lsmean lsmean_se diff lcl ucl pval
   , out    = sbp_ls90
 )
```

```text
sbp_ls90: 14 rows
TRT01P                VERSUS   GROUPS         BLOCK  STAT              VALUE   TEXT
Placebo                        TRT01P VERSUS         lsmean      -3.19678836   -3.2
Placebo                        TRT01P VERSUS         lsmean_se  1.5750339768   1.58
Xanomeline High Dose           TRT01P VERSUS         lsmean     -8.924823955   -8.9
Xanomeline High Dose           TRT01P VERSUS         lsmean_se  2.0294106838   2.03
Xanomeline Low Dose            TRT01P VERSUS         lsmean      -3.11464901   -3.1
Xanomeline Low Dose            TRT01P VERSUS         lsmean_se  2.0295585525   2.03
Xanomeline High Dose  Placebo  TRT01P VERSUS         diff       -5.728035595   -5.7
Xanomeline High Dose  Placebo  TRT01P VERSUS         lcl        -9.980368028  -10.0
Xanomeline High Dose  Placebo  TRT01P VERSUS         ucl        -1.475703163   -1.5
Xanomeline High Dose  Placebo  TRT01P VERSUS         pval       0.0272855793  0.027
Xanomeline Low Dose   Placebo  TRT01P VERSUS         diff       0.0821393501    0.1
Xanomeline Low Dose   Placebo  TRT01P VERSUS         lcl        -4.170619641   -4.2
Xanomeline Low Dose   Placebo  TRT01P VERSUS         ucl        4.3348983413    4.3
Xanomeline Low Dose   Placebo  TRT01P VERSUS         pval       0.9745379028  0.975
```

<a id="ex-sbp_ls_vis"></a>

Fits one model at each visit with within=avisit: High Dose against Placebo at Week 12 and 24.

```sas
%lsmeans(
     data   = advs
   , where  = (paramcd = 'SYSBP' AND avisit IN ('Week 12' 'Week 24') AND anl01fl = 'Y')
   , var    = chg
   , by     = trt01p
   , within = avisit
   , covars = base
   , class  = sex
   , pairs  = "Xanomeline High Dose" "Placebo"
   , order  = trt01pn
   , out    = sbp_ls_vis
 )
```

```text
sbp_ls_vis: 10 rows
TRT01P                VERSUS   AVISIT   GROUPS                BLOCK  STAT            VALUE   TEXT
Xanomeline High Dose  Placebo  Week 12  TRT01P VERSUS AVISIT         diff     -5.237880107   -5.2
Xanomeline High Dose  Placebo  Week 12  TRT01P VERSUS AVISIT         diff_se  2.5065985028   2.51
Xanomeline High Dose  Placebo  Week 12  TRT01P VERSUS AVISIT         lcl      -10.19207069  -10.2
Xanomeline High Dose  Placebo  Week 12  TRT01P VERSUS AVISIT         ucl      -0.283689527   -0.3
Xanomeline High Dose  Placebo  Week 12  TRT01P VERSUS AVISIT         pval     0.0383969398  0.038
Xanomeline High Dose  Placebo  Week 24  TRT01P VERSUS AVISIT         diff     -3.200754613   -3.2
Xanomeline High Dose  Placebo  Week 24  TRT01P VERSUS AVISIT         diff_se  3.3340595813   3.33
Xanomeline High Dose  Placebo  Week 24  TRT01P VERSUS AVISIT         lcl      -9.810138883   -9.8
Xanomeline High Dose  Placebo  Week 24  TRT01P VERSUS AVISIT         ucl      3.4086296557    3.4
Xanomeline High Dose  Placebo  Week 24  TRT01P VERSUS AVISIT         pval     0.3392108933  0.339
```

## Messages

The macro gives only the [messages every macro shares](index.md#messages-every-macro-shares).

The macro also writes these NOTE lines to the log, without stopping:

- `NOTE: [lsmeans] <ndup> record(s) of where= are a second record of a subject:`
- `NOTE: [lsmeans] the first record of each subject is used.`

## See also

Compare groups with a model: [%mmrm](mmrm.md), [%logistic](logistic.md), [%risk](risk.md), [%rateratio](rateratio.md).

Named on this page: [%ancova](ancova.md).

Guides that use %lsmeans: [Make an efficacy table with an ANCOVA](../how-to/efficacy-table.md).

## Proof

Checked against its known answer (on a small data set, the numbers worked out independently in R); ran on SAS 9.4 M9, 2026-11-12.

The known answers and test cases are kept with the development of the library, not in this repository.

The examples of this page ran on SAS 9.4 M9 on 2026-11-27, with a log free of ERROR and WARNING.

Used in the proof against pharmaverse: [t14_3_01](https://github.com/datastep-labs/sapling-sas/blob/main/proof/pilot1/programs/t14_3_01.sas) (R Submission Pilot 1), [t14_3_02](https://github.com/datastep-labs/sapling-sas/blob/main/proof/pilot1/programs/t14_3_02.sas) (R Submission Pilot 1). See [what the proof shows](../explanation/proof.md).

[Source of %lsmeans](https://github.com/datastep-labs/sapling-sas/blob/main/macros/lsmeans.sas)
