# %interaction_glm

Returns the p-value of the treatment-by-subgroup interaction in a linear model of a continuous variable.

**Procedure:** PROC GLM · **Family:** [Subgroups](index.md#subgroups)

## Syntax

```sas
%interaction_glm(
     data   =
   , where  =
   , var    =
   , by     =
   , factor =
   , covars =
   , class  =
   , stats  = pval="X.XXX"
   , label  =
   , out    =
   , debug  = no
 )
```

## Parameters

`data=`
:   The input data set: one record per subject, with USUBJID. *(required)*

`where=`
:   The records to use: a condition in parentheses, such as where = (`ittfl = 'Y'`). *(optional)*

`var=`
:   The variable of the model: one numeric variable, such as chg. *(required)*

`by=`
:   The groups of the model, the treatment: one variable. *(required)*

`factor=`
:   The factor of the subgroups: one variable whose values are its levels (`factor = sex`). *(required)*

`covars=`
:   The numeric covariates of the model, separated by blanks (`covars = base`). *(optional)*

`class=`
:   The other class factors of the model, separated by blanks (`class = sitegr1`). *(optional)*

`stats=`
:   The statistic with its pattern of the printed number: pval. *(optional, default `pval="X.XXX"`)*

`label=`
:   The label of the block in the table: a text in quotes. A block is the rows of one call in the table. *(optional)*

`out=`
:   The name of the result data set. *(required)*

`debug=`
:   yes: keep the work data sets _interaction_glm_*. *(optional, default `no`)*
    Accepts: `yes`, `no`.

## Result

The data set of `out=`: the [result shape](../explanation/result-shape.md), one row for all groups and levels together: GROUPS (blank), BLOCK, STAT (pval), VALUE and TEXT.

## Details

Use [%interaction_logistic](interaction_logistic.md) for a response, [%interaction_genmod](interaction_genmod.md) for a count with its exposure, and [%interaction_phreg](interaction_phreg.md) for a time to an event. The model has the groups, the covariates, the class factors, the factor and the treatment-by-factor terms. pval is the Type III F test of the treatment-by-factor terms (PROC GLM). For this term of the highest order, the test is the same as the F test of the model with the terms against the model without them. The model uses one record per subject: a record with a missing value, group or level is not used.

## Examples

The examples run on the [example data](../tutorial/index.md#the-example-data) after `examples/setup.sas`. The output under each call is the output of that run.

```sas
%interaction_glm(
     data   = advs
   , where  = (paramcd = 'SYSBP' AND avisit = 'Week 12' AND anl01fl = 'Y')
   , var    = chg
   , by     = trt01p
   , factor = sex
   , covars = base
   , label  = "Sex"
   , out    = sbp_int
 )
```

```text
sbp_int: 1 row
GROUPS  BLOCK  STAT         VALUE   TEXT
        Sex    pval  0.1755140868  0.176
```

## Messages

The macro gives only the [messages every macro shares](index.md#messages-every-macro-shares).

## See also

Subgroups: [%interaction_logistic](interaction_logistic.md), [%interaction_genmod](interaction_genmod.md), [%interaction_phreg](interaction_phreg.md).

Named on this page: [%stack](stack.md).

## Proof

Checked against its known answers: numbers worked out independently in R, compared on SAS by the tests of the library.

The examples of this page ran on SAS 9.4M9 on 2026-11-27, with a log free of ERROR and WARNING.

[Source of %interaction_glm](https://github.com/datastep-labs/sapling-sas/blob/main/macros/interaction_glm.sas)
