# %import_xpt

Copies SAS transport files (XPORT version 5, .xpt) into SAS data sets in a folder.

**Procedure:** LIBNAME XPORT, PROC COPY · **Family:** [Start a program](index.md#start)

## Syntax

```sas
%import_xpt(
     dir     =
   , members =
   , out     =
 )
```

## Parameters

`dir=`
:   The folder of the transport files: a path without quotes. *(required)*

`members=`
:   The names of the data sets to read: one name or several, separated by blanks (`members = dm ae vs`). The file of VTXC is VTXC.xpt or, when that does not exist, vtxc.xpt. *(required)*

`out=`
:   The folder that gets the data sets: a path without quotes. The folder must exist. *(required)*

## Result

The files: one data set &lt;out&gt;/&lt;member&gt;.sas7bdat for each name of `members=`.

## Details

The macro stands alone: a program can include it without the library (00_import.sas). So it calls no other macro of the library and writes no begin and end lines in the log. A member is read from &lt;dir&gt;/&lt;member&gt;.xpt; when that file does not exist, from the same name in lower case.

## Examples

The examples run on the [example data](../tutorial/index.md#the-example-data) after `examples/setup.sas`. The output under each call is the output of that run. All examples of the reference run as one program: [examples/reference.sas](https://github.com/datastep-labs/sapling-sas/blob/main/examples/reference.sas).

Copies the six ADaM transport files of the example data into SAS data sets of one folder.

```sas
%import_xpt(
     dir     = &spl_root./examples/data
   , members = adsl adae advs adlb adtte adrs
   , out     = &spl_root./examples/adam
 )
```

```text
the data sets of &spl_root./examples/adam where libname = 'ADAM': 6 rows
MEMNAME   NOBS  NVAR
ADAE      1191   109
ADLB      5008    36
ADRS       508    21
ADSL       306    58
ADTTE      512    24
ADVS     10140    32
```

## Messages

A wrong call writes the message and its fix to the log and stops. The macro also gives the [messages every macro shares](index.md#messages-every-macro-shares).

| Message | Fix |
|---|---|
| &lt;p&gt;= is required | give &lt;p&gt;=&lt;value&gt; (see import_xpt.sas). |

## See also

Start a program: [%study](study.md).

Guides that use %import_xpt: [Use the macros in your own program](../how-to/own-program.md).

## Proof

The ADaM and SDTM transport files of a made-up study: every program ran with a clean log, and 570 of 570 numbers the same as those of a second program in R; ran on SAS 9.4 M9, 2026-11-12.

The examples of this page ran on SAS 9.4 M9 on 2026-11-27, with a log free of ERROR and WARNING.

[Source of %import_xpt](https://github.com/datastep-labs/sapling-sas/blob/main/macros/import_xpt.sas)
