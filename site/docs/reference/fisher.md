# %fisher

Returns the p-value of Fisher's exact test of the subjects with a record against the subjects without, between groups.

**Procedure:** PROC FREQ (FISHER, CHISQ) · **Family:** [Test the groups](index.md#tests)

## Syntax

```sas
%fisher(
     data   =
   , denom  =
   , where  =
   , by     =
   , within =
   , exact  = yes
   , stats  = pval="X.XXX"
   , label  =
   , out    =
   , debug  = no
 )
```

## Parameters

`data=`
:   The input data set: the records (adverse events), with USUBJID. *(required)*

`denom=`
:   The subjects, one row each, with USUBJID and the variable of `by=`: a data set, with data set options if needed, such as `denom = adsl`(where = (`saffl = 'Y'`)). *(required)*

`where=`
:   The records to use: a condition in parentheses, such as where = (`trtemfl = 'Y'`). *(optional)*

`by=`
:   The groups to compare: one variable of `denom=`. *(required)*

`within=`
:   One test in each group of these variables of `data=`, separated by blanks, such as each preferred term (`within = aedecod`). *(optional)*

`exact=`
:   no: the Pearson chi-square test of the same table instead of Fisher's exact test. *(optional, default `yes`)*
    Accepts: `yes`, `no`.

`stats=`
:   The statistic pval and the pattern of its printed number, such as `stats = pval="X.XXXX"`. *(optional, default `pval="X.XXX"`)*

`label=`
:   The label of the block in the table: a text in quotes. A block is the rows of one call in the table. *(optional)*

`out=`
:   The name of the result data set. *(required)*

`debug=`
:   yes: keep the work data sets _fisher_*. *(optional, default `no`)*
    Accepts: `yes`, `no`.

## Result

The data set of `out=`: the [result shape](../explanation/result-shape.md): one row with STAT pval, or one row per group of `within=` with the variables of `within=`. GROUPS has the names of the `within=` variables. VALUE is missing where no test can be made (one group, or all subjects with a record, or none).

## Details

Use it for an adverse event between treatments; use [%chisq](chisq.md) for the categories of a response, and [%cmh](cmh.md) for a test within strata. Every subject of `denom=` counts, with a record in `data=` or without. A subject with a missing group in `denom=` is not used. With exact=no the macro gives the Pearson chi-square test of the same table.

## Examples

The examples run on the [example data](../tutorial/index.md#the-example-data) after `examples/setup.sas`. The output under each call is the output of that run.

```sas
%fisher(
     data   = adae
   , denom  = adsl
   , where  = (trtemfl = 'Y')
   , by     = trt01a
   , within = aebodsys
   , out    = soc_test
 )
```

```text
soc_test: the first 15 of 23 rows
AEBODSYS                                                             GROUPS    BLOCK  STAT         VALUE  TEXT
CARDIAC DISORDERS                                                    AEBODSYS         pval  0.5986482437  0.599
CONGENITAL, FAMILIAL AND GENETIC DISORDERS                           AEBODSYS         pval   0.285309692  0.285
EAR AND LABYRINTH DISORDERS                                          AEBODSYS         pval             1  >0.999
EYE DISORDERS                                                        AEBODSYS         pval             1  >0.999
GASTROINTESTINAL DISORDERS                                           AEBODSYS         pval  0.2343746419  0.234
GENERAL DISORDERS AND ADMINISTRATION SITE CONDITIONS                 AEBODSYS         pval  0.0001157448  <0.001
HEPATOBILIARY DISORDERS                                              AEBODSYS         pval  0.6220472441  0.622
IMMUNE SYSTEM DISORDERS                                              AEBODSYS         pval             1  >0.999
INFECTIONS AND INFESTATIONS                                          AEBODSYS         pval  0.1344802549  0.134
INJURY, POISONING AND PROCEDURAL COMPLICATIONS                       AEBODSYS         pval  0.8342741804  0.834
INVESTIGATIONS                                                       AEBODSYS         pval   0.545272413  0.545
METABOLISM AND NUTRITION DISORDERS                                   AEBODSYS         pval  0.0924515128  0.092
MUSCULOSKELETAL AND CONNECTIVE TISSUE DISORDERS                      AEBODSYS         pval  0.4351627482  0.435
NEOPLASMS BENIGN, MALIGNANT AND UNSPECIFIED (INCL CYSTS AND POLYPS)  AEBODSYS         pval  0.5044571998  0.504
NERVOUS SYSTEM DISORDERS                                             AEBODSYS         pval  0.0014818356  0.001
```

## Messages

The macro gives only the [messages every macro shares](index.md#messages-every-macro-shares).

## See also

Test the groups: [%anova](anova.md), [%ttest](ttest.md), [%wilcoxon](wilcoxon.md), [%chisq](chisq.md), [%cmh](cmh.md), [%ancova](ancova.md), [%adjust](adjust.md).

Named on this page: [%stack](stack.md).

## Proof

Checked against its known answers: numbers worked out independently in R, compared on SAS by the tests of the library.

The examples of this page ran on SAS 9.4M9 on 2026-11-27, with a log free of ERROR and WARNING.

[Source of %fisher](https://github.com/datastep-labs/sapling-sas/blob/main/macros/fisher.sas)
