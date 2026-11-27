# %interaction_genmod

Returns the p-value of the treatment-by-subgroup interaction in a Poisson or negative binomial model of a count.

**Procedure:** PROC GENMOD · **Family:** [Subgroups](index.md#subgroups)

## Syntax

```sas
%interaction_genmod(
     data     =
   , where    =
   , var      =
   , by       =
   , factor   =
   , exposure =
   , covars   =
   , class    =
   , dist     = poisson
   , stats    = pval="X.XXX"
   , label    =
   , out      =
   , debug    = no
 )
```

## Parameters

<a id="data"></a>`data=`
:   The input data set: one record per subject, with USUBJID. *(required)*

<a id="where"></a>`where=`
:   The records to use: a condition in parentheses, such as `where = (ittfl = 'Y')`. *(optional)*

<a id="var"></a>`var=`
:   The count: one numeric variable, such as the number of events of each subject. *(required)*

<a id="by"></a>`by=`
:   The groups of the model, the treatment: one variable. *(required)*

<a id="factor"></a>`factor=`
:   The factor of the subgroups: one variable whose values are its levels (`factor = sex`). *(required)*

<a id="exposure"></a>`exposure=`
:   The exposure of each subject: a numeric variable, or an expression of it (`exposure = trtdurd / 365.25`). It must be above 0, because the offset is its logarithm. *(required)*

<a id="covars"></a>`covars=`
:   The numeric covariates of the model, separated by blanks (`covars = base`). *(optional)*

<a id="class"></a>`class=`
:   The other class factors of the model, separated by blanks (`class = sitegr1`). *(optional)*

<a id="dist"></a>`dist=`
:   The distribution of the count: poisson or negbin (nb is accepted as another name of negbin). *(optional, default `poisson`)*
    Accepts: `poisson`, `negbin`, `nb`.

<a id="stats"></a>`stats=`
:   The statistic with its pattern of the printed number: pval. *(optional, default `pval="X.XXX"`)*

<a id="label"></a>`label=`
:   The label of the block in the table: a text in quotes. A block is the rows of one call in the table. *(optional)*

<a id="out"></a>`out=`
:   The name of the result data set. *(required)*

<a id="debug"></a>`debug=`
:   yes: keep the work data sets _interaction_genmod_*. *(optional, default `no`)*
    Accepts: `yes`, `no`.

## Result

The data set of `out=`: the [result shape](../explanation/result-shape.md), one row for all groups and levels together: GROUPS (blank), BLOCK, STAT (pval), VALUE and TEXT.

## Details

Use [%interaction_glm](interaction_glm.md) for a continuous variable, [%interaction_logistic](interaction_logistic.md) for a response, and [%interaction_phreg](interaction_phreg.md) for a time to an event. The macro fits two models with PROC GENMOD, with the logarithm of the exposure as the offset: the groups, the covariates, the class factors and the factor; and the same model with the treatment-by-factor terms. In a negative binomial model, each fit estimates its own dispersion k. pval is the likelihood-ratio test: twice the difference of the full log likelihoods of the two fits, with the difference of the numbers of their estimated coefficients. The models use one record per subject: a record with a missing count, group or level is not used.

## Examples

The examples run on the [example data](../tutorial/index.md#the-example-data) after `examples/setup.sas`. The output under each call is the output of that run. All examples of the reference run as one program: [examples/reference.sas](https://github.com/datastep-labs/sapling-sas/blob/main/examples/reference.sas).

<a id="ex-ae_int"></a>

Tests the treatment by sex interaction of the event counts in a negative binomial model.

```sas
%interaction_genmod(
     data     = adsl
   , where    = (trtdurd > 0)
   , var      = teaecnt
   , by       = trt01a
   , factor   = sex
   , exposure = trtdurd / 365.25
   , dist     = negbin
   , label    = "Sex"
   , out      = ae_int
 )
```

```text
ae_int: 1 row
GROUPS  BLOCK  STAT         VALUE   TEXT
        Sex    pval  0.3675383843  0.368
```

## Messages

The macro gives only the [messages every macro shares](index.md#messages-every-macro-shares).

## See also

Subgroups: [%interaction_glm](interaction_glm.md), [%interaction_logistic](interaction_logistic.md), [%interaction_phreg](interaction_phreg.md).

## Proof

Checked against its known answers: a Poisson and a negative binomial model (on a small data set, the numbers worked out independently in R); ran on SAS 9.4 M9, 2026-11-12.

The known answers and test cases are kept with the development of the library, not in this repository.

The examples of this page ran on SAS 9.4 M9 on 2026-11-27, with a log free of ERROR and WARNING.

[Source of %interaction_genmod](https://github.com/datastep-labs/sapling-sas/blob/main/macros/interaction_genmod.sas)
