# %study

Starts a program: sets the study, the program and the output folder, opens the ADaM library, sets the options.

**Procedure:** LIBNAME, OPTIONS · **Family:** [Start a program](index.md#start)

## Syntax

```sas
%study(
     <id>
   , program =
   , adam    = &spl_root./adam
   , out     = &spl_root./out
 )
```

## Parameters

`id` (the first value, without a keyword)
:   The name of the study: a text without quotes, given first, without a keyword (%study(CDISCPILOT01, ...)). *(required)*

`program=`
:   The name of this program, without quotes (`program = t14_2_01`). [%ard](ard.md) names the numbers file after it when its `file=` is not given. *(required)*

`adam=`
:   The folder of the ADaM data sets: a path without quotes. The macro opens it as the library ADAM, read only. *(optional, default `&spl_root./adam`)*

`out=`
:   The output folder: a path without quotes. The macros write into its folders tlf, listings, figures and ard. *(optional, default `&spl_root./out`)*

## Result

What it sets: the global macro variables SPL_STUDY, SPL_PROGRAM (in lower case) and SPL_OUT; the library ADAM (read only); the options NODATE NONUMBER NOCENTER LS=160 PS=32767 MISSING=' ' VALIDVARNAME=upcase NOFMTERR FORMDLIM=' '; no TITLE and no FOOTNOTE.

## Details

Call it once, at the top of each program, before any other macro of the library. The ADaM library ADAM is read only. [%ard](ard.md) names the numbers file after the program when its `file=` is not given. The options are those of the outputs: no date, no page numbers, no centering, a blank for a missing value. The macro also clears the TITLE and FOOTNOTE statements.

## Examples

The examples run on the [example data](../tutorial/index.md#the-example-data) after `examples/setup.sas`. The output under each call is the output of that run.

Starts the program of the examples: it sets SPL_STUDY, SPL_PROGRAM and SPL_OUT and opens ADAM.

```sas
%study(
     CDISCPILOT01
   , program = examples
   , adam    = &spl_root./examples/adam
   , out     = &spl_root./examples/out
 )
```

```text
the global macro variables where scope = 'GLOBAL' AND name IN ('SPL_STUDY' 'SPL_PROGRAM' 'SPL_OUT'): 3 rows
NAME         VALUE
SPL_OUT      /path/to/sapling-sas/examples/out
SPL_PROGRAM  examples
SPL_STUDY    CDISCPILOT01
```

## Messages

The macro gives only the [messages every macro shares](index.md#messages-every-macro-shares).

## See also

Start a program: [%import_xpt](import_xpt.md).

Named on this page: [%ard](ard.md).

Guides that use %study: [Use the macros in your own program](../how-to/own-program.md), [Run the examples of the reference](../how-to/run-the-examples.md).

## Proof

The examples of this page ran on SAS 9.4M9 on 2026-11-27, with a log free of ERROR and WARNING.

Used in the proof against pharmaverse: [f14_1](https://github.com/datastep-labs/sapling-sas/blob/main/proof/pilot1/programs/f14_1.sas) (R Submission Pilot 1), [t14_2_01](https://github.com/datastep-labs/sapling-sas/blob/main/proof/pilot1/programs/t14_2_01.sas) (R Submission Pilot 1), [t14_3_01](https://github.com/datastep-labs/sapling-sas/blob/main/proof/pilot1/programs/t14_3_01.sas) (R Submission Pilot 1), [t14_3_02](https://github.com/datastep-labs/sapling-sas/blob/main/proof/pilot1/programs/t14_3_02.sas) (R Submission Pilot 1), [adverse_events](https://github.com/datastep-labs/sapling-sas/blob/main/proof/pharmaverse/programs/adverse_events.sas) (pharmaverse examples), [demographic](https://github.com/datastep-labs/sapling-sas/blob/main/proof/pharmaverse/programs/demographic.sas) (pharmaverse examples). See [what the proof shows](../explanation/proof.md).

[Source of %study](https://github.com/datastep-labs/sapling-sas/blob/main/macros/study.sas)
