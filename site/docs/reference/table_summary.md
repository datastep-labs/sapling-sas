# %table_summary

Makes a summary table of the subjects in one call, such as demographics: one block per variable.

**Procedure:** none of its own (those of %describe, %freq, %table) · **Family:** [Tables in one call](index.md#onecall)

## Syntax

```sas
%table_summary(
     data     =
   , where    =
   , vars     =
   , by       =
   , order    =
   , levels   =
   , total    = no
   , catstats =
   , names    =
   , format   =
   , name     =
   , show     = no
   , stats    =
   , title    =
   , footnote =
   , file     =
   , debug    = no
 )
```

## Parameters

<a id="data"></a>`data=`
:   The input data set: the subjects, one row per subject, such as adsl. *(required)*

<a id="where"></a>`where=`
:   The population: a condition in parentheses, such as `where = (saffl = 'Y')`. *(optional)*

<a id="vars"></a>`vars=`
:   The variables of the table in its order, separated by blanks: a name alone for a numeric variable, a name and # for a categorical one, such as `vars = age sex# agegr1#agegr1n`. *(required)*

<a id="by"></a>`by=`
:   The groups of the columns: one character variable, such as `by = trt01a`. *(required)*

<a id="order"></a>`order=`
:   The numeric twin of `by=`, such as `order = trt01an`: it gives the order of the columns. *(optional)*

<a id="levels"></a>`levels=`
:   The planned categories of some categorical variables: each variable, then its values in quotes (levels= of [%freq](freq.md)), such as `levels = sex 'F' 'M'`. A planned category has a row also without a subject. *(optional)*

<a id="total"></a>`total=`
:   yes: add the column Total, all groups together. *(optional, default `no`)*
    Accepts: `yes`, `no`.

<a id="catstats"></a>`catstats=`
:   The statistics of a categorical variable, each name with its pattern (stats= of [%freq](freq.md)). *(optional)*

<a id="names"></a>`names=`
:   The labels of the blocks: pairs variable="text", separated by blanks, such as `names = age="Age (years)"`. A block without a pair has the label of its variable, or its name. *(optional)*

<a id="format"></a>`format=`
:   The labels of the categories: pairs of a variable and a format, as in a FORMAT statement (`format = sex $sexf. race $racef.`), as `format=` of [%layout](layout.md). *(optional)*

<a id="name"></a>`name=`
:   The name of the table: the first part of the names of its data sets, such as `name = t14_3_01`. When not given, the last part of `file=` is used; without `file=`, `name=` is required. *(optional)*

<a id="show"></a>`show=`
:   yes: write the long program to the log. A file path, without quotes: write the long program to that file. In both cases the macro runs it. *(optional, default `no`)*

<a id="stats"></a>`stats=`
:   The statistics of a numeric variable, each name with its pattern (stats= of [%describe](describe.md)). *(optional)*

<a id="title"></a>`title=`
:   The titles of the table: one text in quotes per line (TITLE1, TITLE2 ...). They hold for this table only. When not given, the TITLE statements in force in the program are used. *(optional)*

<a id="footnote"></a>`footnote=`
:   The footnotes of the table: one text in quotes per line (FOOTNOTE1, FOOTNOTE2 ...). They hold for this table only. When not given, the FOOTNOTE statements in force in the program are used. *(optional)*

<a id="file"></a>`file=`
:   The output file without its extension: the macro writes &lt;file&gt;.rtf, &lt;file&gt;.lst and the numbers file. When not given, nothing is printed. *(optional)*

<a id="debug"></a>`debug=`
:   yes: keep the work data sets of the macros that the long program calls. *(optional, default `no`)*
    Accepts: `yes`, `no`.

## Result

The data sets: &lt;name&gt;_&lt;variable&gt;_summ (the result of each variable), &lt;name&gt; (the stacked results), &lt;name&gt;_cols, &lt;name&gt;_display, and &lt;name&gt;_pop (only with `where=`). The files: &lt;file&gt;.rtf, &lt;file&gt;.lst and the numbers file (only with `file=`). The global macro variable: &lt;name&gt;_print. With `show=`: the long program, in the log or in a file.

## Details

Use [%table_visit](table_visit.md) for the values of records at each visit; to add a block that it does not make, start from its long program (show=). A block is the rows of one variable in the table. Name the variables in `vars=`, in the order of the table:

- a name alone (age): a numeric variable, described by [%describe](describe.md)
- a name and # (sex#): a categorical variable, counted by [%freq](freq.md)
- a name, # and a numeric variable (agegr1#agegr1n): a categorical variable whose categories are in the order of that variable

A character variable without # stops the macro with an ERROR. The long program is the program the macro writes and runs: the population, one [%describe](describe.md) or [%freq](freq.md) per variable, [%stack](stack.md) and [%table](table.md), the calls a person would write by hand. The macro computes nothing itself. These data sets stay in WORK, for a change and a second print:

- &lt;name&gt;_&lt;variable&gt;_summ: the result of each variable, one row per number (the [result shape](../explanation/result-shape.md))
- &lt;name&gt;: the stacked results
- &lt;name&gt;_cols: the columns ([%columns](columns.md))
- &lt;name&gt;_display: the display data set, one row per printed line ([%layout](layout.md))

The global macro variable &lt;name&gt;_print keeps the call of [%print](print.md): change &lt;name&gt;_display, then print again with `%print(&<name>_print.)`.

## Examples

The examples run on the [example data](../tutorial/index.md#the-example-data) after `examples/setup.sas`. The output under each call is the output of that run. All examples of the reference run as one program: [examples/reference.sas](https://github.com/datastep-labs/sapling-sas/blob/main/examples/reference.sas).

Makes the demographic table from one row per subject: age as numbers, the categories as rows.

```sas
%table_summary(
     data   = adam.adsl
   , where  = (saffl = 'Y')
   , vars   = age agegr1# sex# race# ethnic#
   , by     = trt01a
   , order  = trt01an
   , total  = yes
   , format = sex $sexf.
   , title  = "Table 14.2.1 Demographic characteristics" "Safety population"
   , file   = &spl_out./tlf/t14_2_1_summary
 )
```

```text
tlf/t14_2_1_summary.lst: 29 lines
Table 14.2.1 Demographic characteristics
Safety population

                                    Placebo      Xanomeline Low Dose  Xanomeline High Dose  Total
                                    (N=86)       (N=96)               (N=72)                (N=254)
-------------------------------------------------------------------------------------------------------

Age
  n                                 86           96                   72                    254
  Mean (SD)                         75.2 (8.59)  76.0 (8.11)          73.8 (7.94)           75.1 (8.25)
  Median                            76.0         78.0                 75.5                  77.0
  Min, Max                          52, 89       51, 88               56, 88                51, 89

Pooled Age Group 1
  18-64                              14 (16.3%)    8 ( 8.3%)           11 (15.3%)            33 (13.0%)
  >64                                72 (83.7%)   88 (91.7%)           61 (84.7%)           221 (87.0%)

Sex
  Female                             53 (61.6%)   55 (57.3%)           35 (48.6%)           143 (56.3%)
  Male                               33 (38.4%)   41 (42.7%)           37 (51.4%)           111 (43.7%)

Race
  AMERICAN INDIAN OR ALASKA NATIVE    0 ( 0.0%)    0 ( 0.0%)            1 ( 1.4%)             1 ( 0.4%)
  BLACK OR AFRICAN AMERICAN           8 ( 9.3%)    6 ( 6.3%)            9 (12.5%)            23 ( 9.1%)
  WHITE                              78 (90.7%)   90 (93.8%)           62 (86.1%)           230 (90.6%)

Ethnicity
  HISPANIC OR LATINO                  3 ( 3.5%)    6 ( 6.3%)            3 ( 4.2%)            12 ( 4.7%)
  NOT HISPANIC OR LATINO             83 (96.5%)   90 (93.8%)           69 (95.8%)           242 (95.3%)
```

Names the blocks, plans a race with no subject and asks for Q1 and Q3: ASIAN has a row of 0.

```sas
%table_summary(
     data     = adsl
   , vars     = age trtdurd race#
   , by       = trt01a
   , order    = trt01an
   , levels   = race 'WHITE' 'BLACK OR AFRICAN AMERICAN' 'ASIAN' 'AMERICAN INDIAN OR ALASKA NATIVE'
   , catstats = n pct
   , names    = age="Age (years)" trtdurd="Duration of treatment (days)" race="Race"
   , stats    = n mean sd median q1 q3 min max
   , title    = "Table 14.2.2 Age, duration of treatment and race"
   , file     = &spl_out./tlf/t14_2_2
 )
```

```text
tlf/t14_2_2.lst: 25 lines
Table 14.2.2 Age, duration of treatment and race

                                    Placebo        Xanomeline Low Dose  Xanomeline High Dose
                                    (N=86)         (N=96)               (N=72)
--------------------------------------------------------------------------------------------

Age (years)
  n                                 86             96                   72
  Mean (SD)                         75.2 (8.59)    76.0 (8.11)          73.8 (7.94)
  Median                            76.0           78.0                 75.5
  Q1, Q3                            69.0, 82.0     71.0, 82.0           70.0, 79.0
  Min, Max                          52, 89         51, 88               56, 88

Duration of treatment (days)
  n                                 85             95                   72
  Mean (SD)                         149.5 (60.35)  86.8 (70.47)         112.2 (65.52)
  Median                            182.0          63.0                 96.5
  Q1, Q3                            134.0, 183.0   22.0, 181.0          53.5, 183.0
  Min, Max                          7, 210         1, 212               15, 200

Race
  WHITE                             78 (90.7%)     90 (93.8%)           62 (86.1%)
  BLACK OR AFRICAN AMERICAN          8 ( 9.3%)      6 ( 6.3%)            9 (12.5%)
  ASIAN                              0 ( 0.0%)      0 ( 0.0%)            0 ( 0.0%)
  AMERICAN INDIAN OR ALASKA NATIVE   0 ( 0.0%)      0 ( 0.0%)            1 ( 1.4%)
```

## Messages

A wrong call writes the message and its fix to the log and stops. The macro also gives the [messages every macro shares](index.md#messages-every-macro-shares).

| Message | Fix |
|---|---|
| name= is required when file= is blank. | give name=&lt;the name of the table&gt;, as t14_2_1. |
| name=&lt;name&gt; is too long for the variable &lt;variable&gt;. | give name= a shorter name (&lt;name&gt;_&lt;variable&gt;_summ). |
| vars= names &lt;variable&gt;, and &lt;ds&gt; does not have it. | give vars= variables of data=, as age sex#. |
| vars= has the character variable &lt;variable&gt; without a #. | write &lt;variable&gt;# (its categories are counted). |

## See also

Tables in one call: [%table](table.md), [%table_ae](table_ae.md), [%table_visit](table_visit.md), [%table_shift](table_shift.md), [%table_response](table_response.md), [%table_model](table_model.md), [%table_tte](table_tte.md).

Named on this page: [%freq](freq.md), [%layout](layout.md), [%describe](describe.md), [%stack](stack.md), [%columns](columns.md), [%print](print.md).

Guides that use %table_summary: [Make a demographic table with tests](../how-to/demographic-table.md).

## Proof

Its test cases: the same .lst and the same numbers file as the long program; ran on SAS 9.4 M9, 2026-11-13.

The known answers and test cases are kept with the development of the library, not in this repository.

The examples of this page ran on SAS 9.4 M9 on 2026-11-27, with a log free of ERROR and WARNING.

[Source of %table_summary](https://github.com/datastep-labs/sapling-sas/blob/main/macros/table_summary.sas)
