# %csv

Writes the records of a listing, or the numbers of a figure, to a CSV file.

**Procedure:** DATA steps (FILE, PUT) · **Family:** [Build a table](index.md#table)

## Syntax

```sas
%csv(
     data   =
   , var    =
   , folder = listings
   , file   =
 )
```

## Parameters

<a id="data"></a>`data=`
:   The records: the data set of the listing, or `out=` of a figure macro. *(required)*

<a id="var"></a>`var=`
:   The variables to write: names separated by blanks, in the order of the columns. *(required)*

<a id="folder"></a>`folder=`
:   The folder in the outputs: listings or figures. *(optional, default `listings`)*
    Accepts: `listings`, `figures`.

<a id="file"></a>`file=`
:   The name of the CSV file, without its extension. *(required)*

## Result

The files: &lt;out&gt;/&lt;folder&gt;/&lt;file&gt;.csv, where &lt;out&gt; is the output folder that [%study](study.md) set: a line with the names of `var=`, then one line per record.

## Details

Use [%ard](ard.md) for the numbers of a table. The first line has the names of the variables, in upper case; then one line per record, in the order of the data. The values are written with their formats, so that a second program, in SAS or R, can compare its listing or figure with this file.

## Examples

The examples run on the [example data](../tutorial/index.md#the-example-data) after `examples/setup.sas`. The output under each call is the output of that run. All examples of the reference run as one program: [examples/reference.sas](https://github.com/datastep-labs/sapling-sas/blob/main/examples/reference.sas).

Writes the listing as a CSV file: the names of var= in the first line, then one line per record.

```sas
%csv(data=adae, var=trt01a usubjid aedecod astdt, file=l14_5_1)
```

```text
listings/l14_5_1.csv: the first 40 of 1192 lines
TRT01A,USUBJID,AEDECOD,ASTDT
Placebo,01-701-1015,APPLICATION SITE ERYTHEMA,03JAN14
Placebo,01-701-1015,APPLICATION SITE PRURITUS,03JAN14
Placebo,01-701-1015,DIARRHOEA,09JAN14
Placebo,01-701-1023,ERYTHEMA,07AUG12
Placebo,01-701-1023,ERYTHEMA,07AUG12
Placebo,01-701-1023,ERYTHEMA,07AUG12
Placebo,01-701-1023,ATRIOVENTRICULAR BLOCK SECOND DEGREE,26AUG12
Xanomeline High Dose,01-701-1028,APPLICATION SITE ERYTHEMA,21JUL13
Xanomeline High Dose,01-701-1028,APPLICATION SITE PRURITUS,08AUG13
Xanomeline High Dose,01-701-1034,APPLICATION SITE PRURITUS,27AUG14
Xanomeline High Dose,01-701-1034,FATIGUE,02NOV14
Placebo,01-701-1047,HIATUS HERNIA,12FEB13
Placebo,01-701-1047,HIATUS HERNIA,12FEB13
Placebo,01-701-1047,UPPER RESPIRATORY TRACT INFECTION,06MAR13
Placebo,01-701-1047,BUNDLE BRANCH BLOCK LEFT,10MAR13
Xanomeline Low Dose,01-701-1097,PRURITUS GENERALISED,20FEB14
Xanomeline Low Dose,01-701-1097,APPLICATION SITE PRURITUS,21FEB14
Xanomeline Low Dose,01-701-1097,PRURITUS GENERALISED,21MAR14
Xanomeline Low Dose,01-701-1097,PRURITUS GENERALISED,31MAR14
Xanomeline Low Dose,01-701-1097,PRURITUS GENERALISED,19APR14
Xanomeline Low Dose,01-701-1097,ERYTHEMA,03JAN14
Xanomeline Low Dose,01-701-1097,APPLICATION SITE VESICLES,20FEB14
Xanomeline Low Dose,01-701-1097,APPLICATION SITE PRURITUS,21FEB14
Xanomeline Low Dose,01-701-1097,PHARYNGOLARYNGEAL PAIN,19APR14
Xanomeline Low Dose,01-701-1097,NASAL CONGESTION,19APR14
Xanomeline Low Dose,01-701-1111,ARTHRALGIA,13SEP12
Xanomeline Low Dose,01-701-1111,CELLULITIS,13SEP12
Xanomeline Low Dose,01-701-1111,MICTURITION URGENCY,07SEP12
Xanomeline Low Dose,01-701-1115,APPLICATION SITE ERYTHEMA,02DEC12
Xanomeline Low Dose,01-701-1115,APPLICATION SITE PRURITUS,02DEC12
Xanomeline Low Dose,01-701-1115,FATIGUE,14JAN13
Xanomeline Low Dose,01-701-1115,APPLICATION SITE IRRITATION,19JAN13
Xanomeline Low Dose,01-701-1115,APPLICATION SITE DERMATITIS,19JAN13
Xanomeline Low Dose,01-701-1115,APPLICATION SITE ERYTHEMA,02DEC12
Xanomeline Low Dose,01-701-1115,APPLICATION SITE PRURITUS,02DEC12
Xanomeline Low Dose,01-701-1115,APPLICATION SITE IRRITATION,26DEC12
Xanomeline Low Dose,01-701-1115,APPLICATION SITE IRRITATION,26DEC12
Placebo,01-701-1130,URINARY TRACT INFECTION,09MAR14
Placebo,01-701-1130,PYREXIA,09MAR14
```

## Messages

The macro gives only the [messages every macro shares](index.md#messages-every-macro-shares).

## See also

Build a table: [%stack](stack.md), [%columns](columns.md), [%ard](ard.md), [%layout](layout.md), [%print](print.md).

Named on this page: [%study](study.md).

## Proof

The listings of a made-up study: the same as the listings of a second program in R; ran on SAS 9.4 M9, 2026-11-12.

The examples of this page ran on SAS 9.4 M9 on 2026-11-27, with a log free of ERROR and WARNING.

Used in the proof against pharmaverse: [f14_1](https://github.com/datastep-labs/sapling-sas/blob/main/proof/pilot1/programs/f14_1.sas) (R Submission Pilot 1). See [what the proof shows](../explanation/proof.md).

[Source of %csv](https://github.com/datastep-labs/sapling-sas/blob/main/macros/csv.sas)
