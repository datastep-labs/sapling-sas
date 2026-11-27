# %print

Prints a table or a listing with one PROC REPORT into an RTF file and a monospace listing file.

**Procedure:** PROC REPORT · **Family:** [Build a table](index.md#table)

## Syntax

```sas
%print(
     data     =
   , by       =
   , var      =
   , page     =
   , together =
   , label    =
   , rows     = 40
   , file     =
   , nodata   = No data qualified
   , debug    = no
 )
```

## Parameters

`data=`
:   The rows to print: the display data set of [%layout](layout.md), or the records of a listing. *(required)*

`by=`
:   The left columns, printed first: variables separated by blanks. A repeated value is shown once. *(optional)*

`var=`
:   The other columns, in the order of the print: variables separated by blanks. A list such as c: or c1-c5 is allowed. *(required)*

`page=`
:   A variable: each value starts a new page, and #BYVAL1 in a title prints the value. A variable HEAD_X gives the header of the column X on the page of its row. *(optional)*

`together=`
:   A variable: the rows of one value stay on one page, such as `together = grp` of [%layout](layout.md). *(optional)*

`label=`
:   Column labels: name="text" pairs, separated by blanks, such as %STR(row=" "). A | splits a header into lines. When not given, the labels of the variables are used. *(optional)*

`rows=`
:   The rows of a page for `together=`: a positive whole number. *(optional, default `40`)*

`file=`
:   The output: a path without its extension. The macro writes &lt;file&gt;.rtf and &lt;file&gt;.lst. *(required)*

`nodata=`
:   The text printed when there is no row. *(optional, default `No data qualified`)*

`debug=`
:   yes: keep the work data sets _print_*. *(optional, default `no`)*
    Accepts: `yes`, `no`.

## Result

The files: &lt;file&gt;.rtf (style journal, landscape) and &lt;file&gt;.lst (the LISTING destination), under the titles and footnotes of the program. With `page=`: the pages of each value, in the order of the rows.

## Details

It prints a table from its display data set ([%layout](layout.md)), and a listing from its records; [%table](table.md) runs [%columns](columns.md), [%ard](ard.md), [%layout](layout.md) and %print in one call.

- The BY columns come first, and a repeated value is shown once. The VAR columns follow: numbers right aligned, text left aligned as written (its leading blanks kept).
- A text column of `var=` wider than 40 characters wraps at a width of 40.
- The header of a column is its pair of `label=`, else its HEAD_X variable on the page (with `page=`), else the label of the variable. A | in a header splits it into lines.
- ODS wraps and pages the RTF. The rows of one value of `together=` stay on one page of the listing when they fit in `rows=`; a group that does not fit in what is left of a page starts a new page.
- A table that is too wide for a page goes on in a second part, and the last BY column is repeated there.
- With `page=`, each value of the page variable gets its own pages, in the same two files, under a BY statement, so that a title can name the value (OPTIONS NOBYLINE and TITLE2 "Sex: #BYVAL1").
- With no row, the report has one row: the text of `nodata=`.

The setup of [%layout](layout.md) (setup=) holds the parameters of a table: %print(&name.) prints its display data set again after a change. A parameter that is not in the setup is added after it: %print(&name., `file=`...). SAS stops a call that has a parameter twice: change that parameter in [%layout](layout.md).

## Examples

The examples run on the [example data](../tutorial/index.md#the-example-data) after `examples/setup.sas`. The output under each call is the output of that run. They also read `t14_2_1_display` (made by the [example of %layout](layout.md#examples)).

```sas
%print(
     data     = t14_2_1_display
   , by       = row
   , var      = c:
   , together = grp
   , label    = %STR(row=" ")
   , file     = &spl_out./tlf/t14_2_1
 )
```

```text
tlf/t14_2_1.lst: 15 lines
             Placebo      Xanomeline Low Dose  Xanomeline High Dose  Total        All
             (N=86)       (N=96)               (N=72)                (N=254)      groups
----------------------------------------------------------------------------------------

Age (years)
  n          86           96                   72                    254
  Mean (SD)  75.2 (8.59)  76.0 (8.11)          73.8 (7.94)           75.1 (8.25)
  Median     76.0         78.0                 75.5                  77.0
  Min, Max   52, 89       51, 88               56, 88                51, 89
  p-value                                                                         0.235

Sex
  Female      53 (61.6%)   55 (57.3%)           35 (48.6%)           143 (56.3%)
  Male        33 (38.4%)   41 (42.7%)           37 (51.4%)           111 (43.7%)
  p-value                                                                         0.251
```

```sas
%print(
     data = adae
   , by   = usubjid
   , var  = trt01a aedecod astdt aesev
   , file = &spl_out./listings/l14_5_1
 )
```

```text
listings/l14_5_1.lst: the first 40 of 1199 lines
Unique                                                                       Analysis
Subject      Actual Treatment                                                   Start
Identifier   for Period 01         Dictionary-Derived Term                       Date  Severity/Intensity
---------------------------------------------------------------------------------------------------------

01-701-1015  Placebo               APPLICATION SITE ERYTHEMA                  03JAN14  MILD
             Placebo               APPLICATION SITE PRURITUS                  03JAN14  MILD
             Placebo               DIARRHOEA                                  09JAN14  MILD
01-701-1023  Placebo               ERYTHEMA                                   07AUG12  MODERATE
             Placebo               ERYTHEMA                                   07AUG12  MILD
             Placebo               ERYTHEMA                                   07AUG12  MILD
             Placebo               ATRIOVENTRICULAR BLOCK SECOND DEGREE       26AUG12  MILD
01-701-1028  Xanomeline High Dose  APPLICATION SITE ERYTHEMA                  21JUL13  MILD
             Xanomeline High Dose  APPLICATION SITE PRURITUS                  08AUG13  MILD
01-701-1034  Xanomeline High Dose  APPLICATION SITE PRURITUS                  27AUG14  MILD
             Xanomeline High Dose  FATIGUE                                    02NOV14  MILD
01-701-1047  Placebo               HIATUS HERNIA                              12FEB13  MODERATE
             Placebo               HIATUS HERNIA                              12FEB13  MODERATE
             Placebo               UPPER RESPIRATORY TRACT INFECTION          06MAR13  MILD
             Placebo               BUNDLE BRANCH BLOCK LEFT                   10MAR13  MILD
01-701-1097  Xanomeline Low Dose   PRURITUS GENERALISED                       20FEB14  MODERATE
             Xanomeline Low Dose   APPLICATION SITE PRURITUS                  21FEB14  MODERATE
             Xanomeline Low Dose   PRURITUS GENERALISED                       21MAR14  MODERATE
             Xanomeline Low Dose   PRURITUS GENERALISED                       31MAR14  MODERATE
             Xanomeline Low Dose   PRURITUS GENERALISED                       19APR14  MODERATE
             Xanomeline Low Dose   ERYTHEMA                                   03JAN14  MILD
             Xanomeline Low Dose   APPLICATION SITE VESICLES                  20FEB14  MILD
             Xanomeline Low Dose   APPLICATION SITE PRURITUS                  21FEB14  MILD
             Xanomeline Low Dose   PHARYNGOLARYNGEAL PAIN                     19APR14  MILD
             Xanomeline Low Dose   NASAL CONGESTION                           19APR14  MILD
01-701-1111  Xanomeline Low Dose   ARTHRALGIA                                 13SEP12  MODERATE
             Xanomeline Low Dose   CELLULITIS                                 13SEP12  MODERATE
             Xanomeline Low Dose   MICTURITION URGENCY                        07SEP12  MILD
01-701-1115  Xanomeline Low Dose   APPLICATION SITE ERYTHEMA                  02DEC12  MODERATE
             Xanomeline Low Dose   APPLICATION SITE PRURITUS                  02DEC12  MODERATE
             Xanomeline Low Dose   FATIGUE                                    14JAN13  MODERATE
             Xanomeline Low Dose   APPLICATION SITE IRRITATION                19JAN13  MODERATE
             Xanomeline Low Dose   APPLICATION SITE DERMATITIS                19JAN13  MODERATE
             Xanomeline Low Dose   APPLICATION SITE ERYTHEMA                  02DEC12  MILD
             Xanomeline Low Dose   APPLICATION SITE PRURITUS                  02DEC12  MILD
```

## Messages

A wrong call writes the message and its fix to the log and stops. The macro also gives the [messages every macro shares](index.md#messages-every-macro-shares).

| Message | Fix |
|---|---|
| rows=&lt;rows&gt; is not a positive whole number | give rows= the rows of a page, such as 40. |

## See also

Build a table: [%stack](stack.md), [%columns](columns.md), [%ard](ard.md), [%layout](layout.md), [%csv](csv.md).

Named on this page: [%table](table.md).

## Proof

The examples of this page ran on SAS 9.4M9 on 2026-11-27, with a log free of ERROR and WARNING.

Used in the proof against pharmaverse: [t14_2_01](https://github.com/datastep-labs/sapling-sas/blob/main/proof/pilot1/programs/t14_2_01.sas) (R Submission Pilot 1), [t14_3_01](https://github.com/datastep-labs/sapling-sas/blob/main/proof/pilot1/programs/t14_3_01.sas) (R Submission Pilot 1), [t14_3_02](https://github.com/datastep-labs/sapling-sas/blob/main/proof/pilot1/programs/t14_3_02.sas) (R Submission Pilot 1), [adverse_events](https://github.com/datastep-labs/sapling-sas/blob/main/proof/pharmaverse/programs/adverse_events.sas) (pharmaverse examples), [demographic](https://github.com/datastep-labs/sapling-sas/blob/main/proof/pharmaverse/programs/demographic.sas) (pharmaverse examples). See [what the proof shows](../explanation/proof.md).

[Source of %print](https://github.com/datastep-labs/sapling-sas/blob/main/macros/print.sas)
