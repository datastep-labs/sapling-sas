# %interaction_phreg

Returns the p-value of the treatment-by-subgroup interaction in a Cox model of a time to an event.

**Procedure:** PROC PHREG · **Family:** [Subgroups](index.md#subgroups)

## Syntax

```sas
%interaction_phreg(
     data   =
   , where  =
   , var    =
   , by     =
   , factor =
   , cnsr   = CNSR
   , covars =
   , class  =
   , strata =
   , ties   = efron
   , stats  = pval="X.XXX"
   , label  =
   , out    =
   , debug  = no
 )
```

## Parameters

`data=`
:   The input data set: one record per subject, with USUBJID, the time and the censoring variable. *(required)*

`where=`
:   The records to use: a condition in parentheses, such as `where = (ittfl = 'Y')`. *(optional)*

`var=`
:   The time: one numeric variable, such as aval. *(required)*

`by=`
:   The groups of the model, the treatment: one variable. *(required)*

`factor=`
:   The factor of the subgroups: one variable whose values are its levels (`factor = sex`). *(required)*

`cnsr=`
:   The censoring variable: one numeric variable, 0 for an event and a positive value for a censoring (the ADaM CNSR: 1, 2 ... name the reason). A missing or negative value on a record used stops the macro with an ERROR. *(optional, default `CNSR`)*

`covars=`
:   The numeric covariates of the model, separated by blanks (`covars = base`). *(optional)*

`class=`
:   The other class factors of the model, separated by blanks (`class = sitegr1`). *(optional)*

`strata=`
:   The strata of the models, separated by blanks (`strata = sitegr1`). When not given, the models have no strata. *(optional)*

`ties=`
:   The method for tied times: efron, breslow, or exact (TIES=DISCRETE of PROC PHREG). discrete is accepted as another name of exact. *(optional, default `efron`)*
    Accepts: `efron`, `breslow`, `exact`, `discrete`.

`stats=`
:   The statistic with its pattern of the printed number: pval. *(optional, default `pval="X.XXX"`)*

`label=`
:   The label of the block in the table: a text in quotes. A block is the rows of one call in the table. *(optional)*

`out=`
:   The name of the result data set. *(required)*

`debug=`
:   yes: keep the work data sets _interaction_phreg_*. *(optional, default `no`)*
    Accepts: `yes`, `no`.

## Result

The data set of `out=`: the [result shape](../explanation/result-shape.md), one row for all groups and levels together: GROUPS (blank), BLOCK, STAT (pval), VALUE and TEXT.

## Details

Use [%interaction_glm](interaction_glm.md) for a continuous variable, [%interaction_logistic](interaction_logistic.md) for a response, and [%interaction_genmod](interaction_genmod.md) for a count with its exposure. The macro fits two models with PROC PHREG, in the strata of `strata=`: the groups, the covariates, the class factors and the factor; and the same model with the treatment-by-factor terms. pval is the likelihood-ratio test: the difference of the likelihood-ratio chi-squares of the two fits (twice the difference of the log partial likelihoods), with the difference of their degrees of freedom. The models use one record per subject: a record with a missing time, group or level is not used. CNSR 0 is an event and any positive value is a censoring, as in ADaM, where the value names the reason of the censoring: a CNSR of 2 is censored as 1 is. A record used with a missing or negative CNSR stops the macro with an ERROR.

## Examples

The examples run on the [example data](../tutorial/index.md#the-example-data) after `examples/setup.sas`. The output under each call is the output of that run. They also read `adttde` (made by the [example of %tte](tte.md#examples)).

Tests the treatment by sex interaction of the time to the event in a Cox model.

```sas
%interaction_phreg(
     data   = adttde
   , var    = aval
   , by     = trt01a
   , factor = sex
   , label  = "Sex"
   , out    = ttde_int
 )
```

```text
ttde_int: 1 row
GROUPS  BLOCK  STAT         VALUE   TEXT
        Sex    pval  0.0656344881  0.066
```

## Messages

A wrong call writes the message and its fix to the log and stops. The macro also gives the [messages every macro shares](index.md#messages-every-macro-shares).

| Message | Fix |
|---|---|
| cnsr=&lt;cnsr&gt; is missing or negative on &lt;nbad&gt; record(s) | give each record CNSR 0 (event) or more (censor). |

## See also

Subgroups: [%interaction_glm](interaction_glm.md), [%interaction_logistic](interaction_logistic.md), [%interaction_genmod](interaction_genmod.md).

Guides that use %interaction_phreg: [Run the examples of the reference](../how-to/run-the-examples.md).

## Proof

Checked against its known answers: numbers worked out independently in R and compared on SAS by the tests of the library (the tests are kept with the development of the library, not in this repository).

The examples of this page ran on SAS 9.4M9 on 2026-11-27, with a log free of ERROR and WARNING.

[Source of %interaction_phreg](https://github.com/datastep-labs/sapling-sas/blob/main/macros/interaction_phreg.sas)
