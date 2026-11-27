# %table_ae

Makes a table of the subjects with adverse events by system organ class and preferred term in one call.

**Procedure:** none of its own (those of %freq, %table) · **Family:** [Tables in one call](index.md#onecall)

## Syntax

```sas
%table_ae(
     data      =
   , adsl      =
   , pop       =
   , where     =
   , var       =
   , by        =
   , order     =
   , sort      =
   , threshold =
   , total     = no
   , format    =
   , name      =
   , show      = no
   , label     =
   , stats     =
   , title     =
   , footnote  =
   , file      =
   , debug     = no
 )
```

## Parameters

`data=`
:   The input data set: the records, with USUBJID. *(required)*

`adsl=`
:   The subjects: a data set with one row per subject. It gives the population and the N of each column, and its variables are merged onto the records by USUBJID. When not given, the N of a column is the subjects of its records. *(optional)*

`pop=`
:   The population: a condition on `adsl=` in parentheses, such as pop = (`saffl = 'Y'`). It is used only with `adsl=`. *(optional)*

`where=`
:   The records to use: a condition in parentheses, such as where = (`trtemfl = 'Y'`). *(optional)*

`var=`
:   The variables of the rows, nested in their order and separated by blanks, such as `var = aebodsys aedecod`. *(required)*

`by=`
:   The groups of the columns: one character variable, such as `by = trt01a`. *(required)*

`order=`
:   The numeric twin of `by=`, such as `order = trt01an`: it gives the order of the columns. *(optional)*

`sort=`
:   frequency: the rows of the last variable of `var=` in the order of their subjects, the most first (order=frequency of [%freq](freq.md)). When not given, the rows are in the order of their values. *(optional)*
    Accepts: `frequency`.

`threshold=`
:   A percent: keep only the rows whose percent of subjects reaches it in at least one group (threshold= of [%freq](freq.md)), such as `threshold = 5`. *(optional)*

`total=`
:   yes: add the column Total, all groups together. *(optional, default `no`)*
    Accepts: `yes`, `no`.

`format=`
:   The labels of the categories: pairs of a variable and a format, as in a FORMAT statement (`format = sex $sexf. race $racef.`), as `format=` of [%layout](layout.md). *(optional)*

`name=`
:   The name of the table: the first part of the names of its data sets, such as `name = t14_3_01`. When not given, the last part of `file=` is used; without `file=`, `name=` is required. *(optional)*

`show=`
:   yes: write the long program to the log. A file path, without quotes: write the long program to that file. In both cases the macro runs it. *(optional, default `no`)*

`label=`
:   The label of the block in the table: a text in quotes. *(optional)*

`stats=`
:   The statistics, each name with its pattern, separated by blanks (stats= of [%freq](freq.md)), such as `stats = n pct events`. *(optional)*

`title=`
:   The titles of the table: one text in quotes per line (TITLE1, TITLE2 ...). They hold for this table only. When not given, the TITLE statements in force in the program are used. *(optional)*

`footnote=`
:   The footnotes of the table: one text in quotes per line (FOOTNOTE1, FOOTNOTE2 ...). They hold for this table only. When not given, the FOOTNOTE statements in force in the program are used. *(optional)*

`file=`
:   The output file without its extension: the macro writes &lt;file&gt;.rtf, &lt;file&gt;.lst and the numbers file. When not given, nothing is printed. *(optional)*

`debug=`
:   yes: keep the work data sets of the macros that the long program calls. *(optional, default `no`)*
    Accepts: `yes`, `no`.

## Result

The data sets: &lt;name&gt;_ae (the result), &lt;name&gt; (the stacked results), &lt;name&gt;_cols, &lt;name&gt;_display, &lt;name&gt;_pop (with `adsl=`) and &lt;name&gt;_rec (with `adsl=` or `where=`). The files: &lt;file&gt;.rtf, &lt;file&gt;.lst and the numbers file (only with `file=`). The global macro variable: the global macro variable &lt;name&gt;_print. With `show=`: the long program, in the log or in a file.

## Details

Use it for any count of subjects by nested levels of records; to add a block that it does not make, start from its long program (show=). The long program is the program the macro writes and runs: the population, the records, one [%freq](freq.md), [%stack](stack.md) and [%table](table.md), the calls a person would write by hand. The macro computes nothing itself. A subject is counted once in each row, and the percent is of the subjects of the group. These data sets stay in WORK, for a change and a second print:

- &lt;name&gt;_ae: the result, one row per number (the [result shape](../explanation/result-shape.md))
- &lt;name&gt;: the stacked results
- &lt;name&gt;_cols: the columns ([%columns](columns.md))
- &lt;name&gt;_display: the display data set, one row per printed line ([%layout](layout.md))

The global macro variable &lt;name&gt;_print keeps the call of [%print](print.md): change &lt;name&gt;_display, then print again with %print(&&lt;name&gt;_print.).

## Examples

The examples run on the [example data](../tutorial/index.md#the-example-data) after `examples/setup.sas`. The output under each call is the output of that run.

```sas
%table_ae(
     data  = adam.adae
   , adsl  = adam.adsl
   , pop   = (saffl = 'Y')
   , where = (trtemfl = 'Y')
   , var   = aebodsys aedecod
   , by    = trt01a
   , order = trt01an
   , sort  = frequency
   , label = "Treatment-emergent adverse events"
   , title = "Table 14.5.2 Treatment-emergent adverse events by SOC and PT"
   , file  = &spl_out./tlf/t14_5_2
 )
```

```text
tlf/t14_5_2.lst: the first 40 of 309 lines
Table 14.5.2 Treatment-emergent adverse events by SOC and PT

                                                                       Placebo     Xanomeline Low Dose  Xanomeline High Dose
                                                                       (N=86)      (N=96)               (N=72)
----------------------------------------------------------------------------------------------------------------------------

Treatment-emergent adverse events
  CARDIAC DISORDERS
    SINUS BRADYCARDIA                                                   2 ( 2.3%)   7 ( 7.3%)            8 (11.1%)
    MYOCARDIAL INFARCTION                                               4 ( 4.7%)   2 ( 2.1%)            4 ( 5.6%)
    ATRIAL FIBRILLATION                                                 1 ( 1.2%)   2 ( 2.1%)            2 ( 2.8%)
    SUPRAVENTRICULAR EXTRASYSTOLES                                      1 ( 1.2%)   1 ( 1.0%)            1 ( 1.4%)
    VENTRICULAR EXTRASYSTOLES                                           0 ( 0.0%)   2 ( 2.1%)            1 ( 1.4%)
    ATRIAL FLUTTER                                                      0 ( 0.0%)   1 ( 1.0%)            1 ( 1.4%)
    ATRIOVENTRICULAR BLOCK FIRST DEGREE                                 1 ( 1.2%)   1 ( 1.0%)            0 ( 0.0%)
    BUNDLE BRANCH BLOCK RIGHT                                           1 ( 1.2%)   1 ( 1.0%)            0 ( 0.0%)
    PALPITATIONS                                                        0 ( 0.0%)   2 ( 2.1%)            0 ( 0.0%)
    ATRIAL HYPERTROPHY                                                  1 ( 1.2%)   0 ( 0.0%)            0 ( 0.0%)
    ATRIOVENTRICULAR BLOCK SECOND DEGREE                                1 ( 1.2%)   0 ( 0.0%)            0 ( 0.0%)
    BRADYCARDIA                                                         1 ( 1.2%)   0 ( 0.0%)            0 ( 0.0%)
    BUNDLE BRANCH BLOCK LEFT                                            1 ( 1.2%)   0 ( 0.0%)            0 ( 0.0%)
    CARDIAC DISORDER                                                    0 ( 0.0%)   0 ( 0.0%)            1 ( 1.4%)
    CARDIAC FAILURE CONGESTIVE                                          1 ( 1.2%)   0 ( 0.0%)            0 ( 0.0%)
    SINUS ARRHYTHMIA                                                    1 ( 1.2%)   0 ( 0.0%)            0 ( 0.0%)
    SUPRAVENTRICULAR TACHYCARDIA                                        0 ( 0.0%)   1 ( 1.0%)            0 ( 0.0%)
    TACHYCARDIA                                                         1 ( 1.2%)   0 ( 0.0%)            0 ( 0.0%)
    VENTRICULAR HYPERTROPHY                                             1 ( 1.2%)   0 ( 0.0%)            0 ( 0.0%)
    WOLFF-PARKINSON-WHITE SYNDROME                                      0 ( 0.0%)   1 ( 1.0%)            0 ( 0.0%)
  CONGENITAL, FAMILIAL AND GENETIC DISORDERS
    VENTRICULAR SEPTAL DEFECT                                           0 ( 0.0%)   1 ( 1.0%)            2 ( 2.8%)
  EAR AND LABYRINTH DISORDERS
    VERTIGO                                                             0 ( 0.0%)   1 ( 1.0%)            1 ( 1.4%)
    CERUMEN IMPACTION                                                   0 ( 0.0%)   1 ( 1.0%)            0 ( 0.0%)
    EAR PAIN                                                            1 ( 1.2%)   0 ( 0.0%)            0 ( 0.0%)
  EYE DISORDERS
    VISION BLURRED                                                      0 ( 0.0%)   1 ( 1.0%)            1 ( 1.4%)
    CONJUNCTIVAL HAEMORRHAGE                                            0 ( 0.0%)   1 ( 1.0%)            0 ( 0.0%)
    CONJUNCTIVITIS                                                      1 ( 1.2%)   0 ( 0.0%)            0 ( 0.0%)
    EYE ALLERGY                                                         1 ( 1.2%)   0 ( 0.0%)            0 ( 0.0%)
    EYE PRURITUS                                                        1 ( 1.2%)   0 ( 0.0%)            0 ( 0.0%)
```

## Messages

A wrong call writes the message and its fix to the log and stops. The macro also gives the [messages every macro shares](index.md#messages-every-macro-shares).

| Message | Fix |
|---|---|
| name= is required when file= is blank. | give name=&lt;the name of the table&gt;, as t14_5_2. |
| adsl=&lt;ds&gt; does not exist. | give adsl= the data set of the subjects. |

## See also

Tables in one call: [%table](table.md), [%table_summary](table_summary.md), [%table_visit](table_visit.md), [%table_shift](table_shift.md), [%table_response](table_response.md), [%table_model](table_model.md), [%table_tte](table_tte.md).

Named on this page: [%freq](freq.md), [%stack](stack.md), [%columns](columns.md), [%layout](layout.md), [%print](print.md).

## Proof

The examples of this page ran on SAS 9.4M9 on 2026-11-27, with a log free of ERROR and WARNING.

[Source of %table_ae](https://github.com/datastep-labs/sapling-sas/blob/main/macros/table_ae.sas)
