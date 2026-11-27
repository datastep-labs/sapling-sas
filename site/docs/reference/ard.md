# %ard

Writes every number of a table to a CSV file, the numbers file.

**Procedure:** DATA steps (FILE, PUT) · **Family:** [Build a table](index.md#table)

## Syntax

```sas
%ard(
     data    =
   , columns =
   , file    =
 )
```

## Parameters

`data=`
:   The stacked results (out= of [%stack](stack.md)). *(required)*

`columns=`
:   The columns (out= of [%columns](columns.md)). When given, the N of each column comes first, as the result N. *(optional)*

`file=`
:   The name of the numbers file, without its extension. When not given, it is the name of the program that [%study](study.md) set; without [%study](study.md), `file=` is required. *(optional)*

## Result

The files: &lt;out&gt;/ard/&lt;file&gt;.csv, where &lt;out&gt; is the output folder that [%study](study.md) set and &lt;file&gt; is in lower case. Its columns: result (the name of the result), stat (the statistic), g1_value to g5_value (the values of the group variables in the order of GROUPS of the result: the column first, then the levels of the row, such as VERSUS of a comparison), raw (the value written with BEST32., up to 15 significant digits; blank for a missing value) and formatted (the printed text).

## Details

Use [%csv](csv.md) for the records of a listing or the numbers of a figure. The numbers file has one line per number: the result it comes from, its statistic, the values of its groups, and the number as stored and as printed. The number as stored is the value as SAS keeps it, written with the format BEST32. (up to 15 significant digits); the number as printed is the TEXT of the result. It reads the results, never the printed page, so that a second program, in SAS or R, can compare its numbers with this file.

- With `columns=`, the first lines are the N of each column (the result N).
- A number has the values of at most five groups (g1_value to g5_value), in the order of GROUPS.

## Examples

The examples run on the [example data](../tutorial/index.md#the-example-data) after `examples/setup.sas`. The output under each call is the output of that run. They also read `t14_2_1` (made by the [example of %stack](stack.md#examples)), `t14_2_1_cols` (made by the [example of %columns](columns.md#examples)). All examples of the reference run as one program: [examples/reference.sas](https://github.com/datastep-labs/sapling-sas/blob/main/examples/reference.sas).

Writes every number of the table and each column N to one CSV file: the raw value and the text.

```sas
%ard(data=t14_2_1, columns=t14_2_1_cols, file=t14_2_1)
```

```text
ard/t14_2_1.csv: the first 40 of 47 lines
result,stat,g1_value,g2_value,g3_value,g4_value,g5_value,raw,formatted
N,n,Placebo,,,,,86,(N=86)
N,n,Xanomeline Low Dose,,,,,96,(N=96)
N,n,Xanomeline High Dose,,,,,72,(N=72)
N,n,Total,,,,,254,(N=254)
AGE_DESCRIBE,n,Placebo,,,,,86,86
AGE_DESCRIBE,mean,Placebo,,,,,75.2093023255814,75.2
AGE_DESCRIBE,sd,Placebo,,,,,8.59016712714192,8.59
AGE_DESCRIBE,median,Placebo,,,,,76,76.0
AGE_DESCRIBE,min,Placebo,,,,,52,52
AGE_DESCRIBE,max,Placebo,,,,,89,89
AGE_DESCRIBE,n,Total,,,,,254,254
AGE_DESCRIBE,mean,Total,,,,,75.0866141732283,75.1
AGE_DESCRIBE,sd,Total,,,,,8.24623389621605,8.25
AGE_DESCRIBE,median,Total,,,,,77,77.0
AGE_DESCRIBE,min,Total,,,,,51,51
AGE_DESCRIBE,max,Total,,,,,89,89
AGE_DESCRIBE,n,Xanomeline High Dose,,,,,72,72
AGE_DESCRIBE,mean,Xanomeline High Dose,,,,,73.7777777777777,73.8
AGE_DESCRIBE,sd,Xanomeline High Dose,,,,,7.94385620024704,7.94
AGE_DESCRIBE,median,Xanomeline High Dose,,,,,75.5,75.5
AGE_DESCRIBE,min,Xanomeline High Dose,,,,,56,56
AGE_DESCRIBE,max,Xanomeline High Dose,,,,,88,88
AGE_DESCRIBE,n,Xanomeline Low Dose,,,,,96,96
AGE_DESCRIBE,mean,Xanomeline Low Dose,,,,,75.9583333333333,76.0
AGE_DESCRIBE,sd,Xanomeline Low Dose,,,,,8.11355807037846,8.11
AGE_DESCRIBE,median,Xanomeline Low Dose,,,,,78,78.0
AGE_DESCRIBE,min,Xanomeline Low Dose,,,,,51,51
AGE_DESCRIBE,max,Xanomeline Low Dose,,,,,88,88
AGE_ANOVA,pval,,,,,,0.23464711808588,0.235
SEX_FREQ,n,Placebo,F,,,,53,53
SEX_FREQ,pct,Placebo,F,,,,61.6279069767441,(61.6%)
SEX_FREQ,n,Placebo,M,,,,33,33
SEX_FREQ,pct,Placebo,M,,,,38.3720930232558,(38.4%)
SEX_FREQ,n,Total,F,,,,143,143
SEX_FREQ,pct,Total,F,,,,56.2992125984252,(56.3%)
SEX_FREQ,n,Total,M,,,,111,111
SEX_FREQ,pct,Total,M,,,,43.7007874015748,(43.7%)
SEX_FREQ,n,Xanomeline High Dose,F,,,,35,35
SEX_FREQ,pct,Xanomeline High Dose,F,,,,48.6111111111111,(48.6%)
```

## Messages

The macro gives only the [messages every macro shares](index.md#messages-every-macro-shares).

## See also

Build a table: [%stack](stack.md), [%columns](columns.md), [%layout](layout.md), [%print](print.md), [%csv](csv.md).

Named on this page: [%study](study.md).

Guides that use %ard: [Tutorial: your first table](../tutorial/index.md), [Check a table against an independent program](../how-to/check-a-table.md), [Make a demographic table with tests](../how-to/demographic-table.md), [Use the macros in your own program](../how-to/own-program.md).

## Proof

The tables of a made-up study: 759 of 759 numbers the same as those of a second program in R; ran on SAS 9.4 M9, 2026-11-12.

The examples of this page ran on SAS 9.4 M9 on 2026-11-27, with a log free of ERROR and WARNING.

Used in the proof against pharmaverse: [t14_2_01](https://github.com/datastep-labs/sapling-sas/blob/main/proof/pilot1/programs/t14_2_01.sas) (R Submission Pilot 1), [t14_3_01](https://github.com/datastep-labs/sapling-sas/blob/main/proof/pilot1/programs/t14_3_01.sas) (R Submission Pilot 1), [t14_3_02](https://github.com/datastep-labs/sapling-sas/blob/main/proof/pilot1/programs/t14_3_02.sas) (R Submission Pilot 1), [adverse_events](https://github.com/datastep-labs/sapling-sas/blob/main/proof/pharmaverse/programs/adverse_events.sas) (pharmaverse examples), [demographic](https://github.com/datastep-labs/sapling-sas/blob/main/proof/pharmaverse/programs/demographic.sas) (pharmaverse examples). See [what the proof shows](../explanation/proof.md).

[Source of %ard](https://github.com/datastep-labs/sapling-sas/blob/main/macros/ard.sas)
