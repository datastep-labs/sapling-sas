# %termflags

Returns one record per subject and term, with a flag that says whether the subject has the term.

**Procedure:** PROC SORT, MERGE, PROC SUMMARY · **Family:** [Describe the data](index.md#describe)

## Syntax

```sas
%termflags(
     data      =
   , denom     =
   , where     =
   , terms     =
   , by        =
   , threshold =
   , out       =
   , debug     = no
 )
```

## Parameters

<a id="data"></a>`data=`
:   The input data set: the records of the events, with USUBJID. *(required)*

<a id="denom"></a>`denom=`
:   The subjects of the groups: a data set with one row per subject (the population), with USUBJID and the variable of `by=`. *(required)*

<a id="where"></a>`where=`
:   The records to use: a condition in parentheses, such as `where = (trtemfl = 'Y')`. *(optional)*

<a id="terms"></a>`terms=`
:   The variables of a row: one or several, separated by blanks, nested in their order (`terms = aebodsys aedecod`: a term within its class). When not given, one row of all the records, such as "any event" of an overview table. *(optional)*

<a id="by"></a>`by=`
:   The groups: one variable of `denom=`. *(required)*

<a id="threshold"></a>`threshold=`
:   A percent (`threshold = 5`): keep only the terms with this percent of the subjects or more in at least one group. The macro compares the percent itself, not its rounded text. It needs `terms=`. *(optional)*

<a id="out"></a>`out=`
:   The name of the result data set. *(required)*

<a id="debug"></a>`debug=`
:   yes: keep the work data sets _termflags_*. *(optional, default `no`)*
    Accepts: `yes`, `no`.

## Result

The data set of `out=`: one record per subject of `denom=` and term: USUBJID, the variable of `by=`, the variables of `terms=` and FLAG ("Y" or "N"), sorted by the variables of `terms=` and USUBJID.

## Details

Use it before [%risk](risk.md) to compare the groups on the subjects with a term; [%freq](freq.md) counts the subjects but gives no flag per subject. The macro computes no statistic. A term is each combination of the values of `terms=` in the records. FLAG is "Y" when the subject has a record of the term and "N" when not. The subjects are those of `denom=`: a subject with a record who is not in `denom=` is left out. Then [%risk](risk.md) compares the groups on FLAG within each term (within= the variables of `terms=`), with the subjects of each group as the denominator.

## Examples

The examples run on the [example data](../tutorial/index.md#the-example-data) after `examples/setup.sas`. The output under each call is the output of that run. All examples of the reference run as one program: [examples/reference.sas](https://github.com/datastep-labs/sapling-sas/blob/main/examples/reference.sas).

<a id="ex-ae_flags"></a>

Flags each subject for each term that reaches 5 percent: FLAG is Y with the term, N without.

```sas
%termflags(
     data      = adae
   , denom     = adsl
   , where     = (trtemfl = 'Y')
   , terms     = aebodsys aedecod
   , by        = trt01a
   , threshold = 5
   , out       = ae_flags
 )
```

```text
ae_flags: the first 15 of 6096 rows
USUBJID      TRT01A                AEBODSYS           AEDECOD                FLAG
01-701-1015  Placebo               CARDIAC DISORDERS  MYOCARDIAL INFARCTION  N
01-701-1023  Placebo               CARDIAC DISORDERS  MYOCARDIAL INFARCTION  N
01-701-1028  Xanomeline High Dose  CARDIAC DISORDERS  MYOCARDIAL INFARCTION  N
01-701-1033  Xanomeline Low Dose   CARDIAC DISORDERS  MYOCARDIAL INFARCTION  N
01-701-1034  Xanomeline High Dose  CARDIAC DISORDERS  MYOCARDIAL INFARCTION  N
01-701-1047  Placebo               CARDIAC DISORDERS  MYOCARDIAL INFARCTION  N
01-701-1097  Xanomeline Low Dose   CARDIAC DISORDERS  MYOCARDIAL INFARCTION  N
01-701-1111  Xanomeline Low Dose   CARDIAC DISORDERS  MYOCARDIAL INFARCTION  N
01-701-1115  Xanomeline Low Dose   CARDIAC DISORDERS  MYOCARDIAL INFARCTION  N
01-701-1118  Placebo               CARDIAC DISORDERS  MYOCARDIAL INFARCTION  N
01-701-1130  Placebo               CARDIAC DISORDERS  MYOCARDIAL INFARCTION  N
01-701-1133  Xanomeline High Dose  CARDIAC DISORDERS  MYOCARDIAL INFARCTION  N
01-701-1146  Xanomeline High Dose  CARDIAC DISORDERS  MYOCARDIAL INFARCTION  N
01-701-1148  Xanomeline High Dose  CARDIAC DISORDERS  MYOCARDIAL INFARCTION  N
01-701-1153  Placebo               CARDIAC DISORDERS  MYOCARDIAL INFARCTION  N
```

## Messages

A wrong call writes the message and its fix to the log and stops. The macro also gives the [messages every macro shares](index.md#messages-every-macro-shares).

| Message | Fix |
|---|---|
| threshold= selects terms and terms= is empty | give terms= the variables of a row, or no threshold=. |

## See also

Describe the data: [%describe](describe.md), [%freq](freq.md), [%proportion](proportion.md), [%rate](rate.md), [%worst](worst.md).

Named on this page: [%risk](risk.md).

## Proof

Checked against its known answer: the risk difference of each term of an adverse event table (on a small data set, the numbers worked out independently in R); ran on SAS 9.4 M9, 2026-11-12.

The known answers and test cases are kept with the development of the library, not in this repository.

The examples of this page ran on SAS 9.4 M9 on 2026-11-27, with a log free of ERROR and WARNING.

[Source of %termflags](https://github.com/datastep-labs/sapling-sas/blob/main/macros/termflags.sas)
