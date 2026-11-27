# %worst

Keeps the records of each subject at its worst level, such as the highest severity or toxicity grade.

**Procedure:** PROC SORT, a DATA step (BY, FIRST.) · **Family:** [Describe the data](index.md#describe)

## Syntax

```sas
%worst(
     data   =
   , where  =
   , var    =
   , by     =
   , levels =
   , out    =
   , debug  = no
 )
```

## Parameters

<a id="data"></a>`data=`
:   The input data set: the records, with USUBJID. *(required)*

<a id="where"></a>`where=`
:   The records to use: a condition in parentheses, such as `where = (trtemfl = 'Y')`. *(optional)*

<a id="var"></a>`var=`
:   The graded variable: one variable, character or numeric (`var = aesev`). *(required)*

<a id="by"></a>`by=`
:   The variables of a row: one or several, separated by blanks (`by = aebodsys aedecod`). The macro keeps the worst records of each subject in each row. When not given, the worst of all the records of the subject. *(optional)*

<a id="levels"></a>`levels=`
:   The values of `var=` from the least to the most severe, separated by blanks: texts in quotes, numbers without (`levels = 'MILD' 'MODERATE' 'SEVERE'`). *(required)*

<a id="out"></a>`out=`
:   The name of the data set of the records kept. *(required)*

<a id="debug"></a>`debug=`
:   yes: keep the work data sets _worst_*. *(optional, default `no`)*
    Accepts: `yes`, `no`.

## Result

The data set of `out=`: the records of `data=` at the worst level of each subject and row, with all the variables of `data=`, sorted by USUBJID and the variables of `by=`.

## Details

Use it before [%freq](freq.md), so that [%freq](freq.md) counts each subject once in each row, at its worst level; the macro computes no statistic. The worst level is the value of `var=` that comes last in `levels=` (levels= goes from the least to the most severe). The macro looks for it for each subject in each row of `by=`, or in all the records of the subject when `by=` is not given. A record whose value is not in `levels=`, such as a missing grade, is never the worst and is left out. When a subject has several records at its worst level, all of them stay.

## Examples

The examples run on the [example data](../tutorial/index.md#the-example-data) after `examples/setup.sas`. The output under each call is the output of that run. All examples of the reference run as one program: [examples/reference.sas](https://github.com/datastep-labs/sapling-sas/blob/main/examples/reference.sas).

<a id="ex-ae_worst"></a>

Keeps the records of each subject and term at the worst severity, the last value of levels=.

```sas
%worst(
     data   = adae
   , where  = (trtemfl = 'Y')
   , var    = aesev
   , by     = aebodsys aedecod
   , levels = 'MILD' 'MODERATE' 'SEVERE'
   , out    = ae_worst
 )
```

```text
ae_worst: the first 15 of 1013 rows
USUBJID      TRT01A                AEBODSYS                                              AEDECOD                               AESEV     ASTDT
01-701-1015  Placebo               GASTROINTESTINAL DISORDERS                            DIARRHOEA                             MILD      09JAN14
01-701-1015  Placebo               GENERAL DISORDERS AND ADMINISTRATION SITE CONDITIONS  APPLICATION SITE ERYTHEMA             MILD      03JAN14
01-701-1015  Placebo               GENERAL DISORDERS AND ADMINISTRATION SITE CONDITIONS  APPLICATION SITE PRURITUS             MILD      03JAN14
01-701-1023  Placebo               CARDIAC DISORDERS                                     ATRIOVENTRICULAR BLOCK SECOND DEGREE  MILD      26AUG12
01-701-1023  Placebo               SKIN AND SUBCUTANEOUS TISSUE DISORDERS                ERYTHEMA                              MODERATE  07AUG12
01-701-1028  Xanomeline High Dose  GENERAL DISORDERS AND ADMINISTRATION SITE CONDITIONS  APPLICATION SITE ERYTHEMA             MILD      21JUL13
01-701-1028  Xanomeline High Dose  GENERAL DISORDERS AND ADMINISTRATION SITE CONDITIONS  APPLICATION SITE PRURITUS             MILD      08AUG13
01-701-1034  Xanomeline High Dose  GENERAL DISORDERS AND ADMINISTRATION SITE CONDITIONS  APPLICATION SITE PRURITUS             MILD      27AUG14
01-701-1034  Xanomeline High Dose  GENERAL DISORDERS AND ADMINISTRATION SITE CONDITIONS  FATIGUE                               MILD      02NOV14
01-701-1047  Placebo               CARDIAC DISORDERS                                     BUNDLE BRANCH BLOCK LEFT              MILD      10MAR13
01-701-1047  Placebo               GASTROINTESTINAL DISORDERS                            HIATUS HERNIA                         MODERATE  12FEB13
01-701-1047  Placebo               GASTROINTESTINAL DISORDERS                            HIATUS HERNIA                         MODERATE  12FEB13
01-701-1047  Placebo               INFECTIONS AND INFESTATIONS                           UPPER RESPIRATORY TRACT INFECTION     MILD      06MAR13
01-701-1097  Xanomeline Low Dose   GENERAL DISORDERS AND ADMINISTRATION SITE CONDITIONS  APPLICATION SITE PRURITUS             MODERATE  21FEB14
01-701-1097  Xanomeline Low Dose   GENERAL DISORDERS AND ADMINISTRATION SITE CONDITIONS  APPLICATION SITE VESICLES             MILD      20FEB14
```

## Messages

The macro gives only the [messages every macro shares](index.md#messages-every-macro-shares).

## See also

Describe the data: [%describe](describe.md), [%freq](freq.md), [%proportion](proportion.md), [%rate](rate.md), [%termflags](termflags.md).

## Proof

Checked against its known answer: the worst records counted by hand (a second program in R gives the same); ran on SAS 9.4 M9, 2026-11-12.

The known answers and test cases are kept with the development of the library, not in this repository.

The examples of this page ran on SAS 9.4 M9 on 2026-11-27, with a log free of ERROR and WARNING.

[Source of %worst](https://github.com/datastep-labs/sapling-sas/blob/main/macros/worst.sas)
