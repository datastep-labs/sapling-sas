# Use the macros in your own program

This guide shows how to start a program of your own study with the library: load the macros from the folder of the
library, read the ADaM transport files into the folder of the study, start the program with `%study`, and find the
outputs. The tutorial and the other guides start from `examples/setup.sas`, which does the same for the example
data.

## Before you start

- Have a copy of the repository [datastep-labs/sapling-sas](https://github.com/datastep-labs/sapling-sas), or of its
  folder `macros`, in a folder that SAS can read: the *folder of the library*, such as `/opt/sapling-sas`.
- Have the *folder of the study*, such as `/studies/cdiscpilot01`, with the ADaM data in its folder `adam`, as SAS
  data sets or as transport files (`.xpt`).
- Know the folder where the program may write its tables, figures and numbers files, such as the folder `out` of
  the study.

The library and the study are two folders. One copy of the library serves every study; a study holds its data and
its outputs, never the macros.

## Steps

### 1. Load the library

Set `spl_root` to the folder of the library, the folder that holds `macros/`, then include the loader
`macros/sapling.sas`. It includes every macro of the library, so that each one is ready to call:

```sas
%LET spl_root = /opt/sapling-sas;  /* the folder of the library: it holds macros/ */
%INCLUDE "&spl_root./macros/sapling.sas";
```

`spl_root` is a global macro variable that the library reads: the loader includes each macro as
`&spl_root./macros/<name>.sas`, so `spl_root` must be the folder of the library, not the folder of the study. Write
the path without quotes and without a slash at the end. Load the library once per SAS session: a second `%INCLUDE`
compiles the macros again and changes nothing.

Name the folder of the study in a macro variable of your own, for the steps below. On the example data, the folder of
the study is the folder `examples` of the library:

```sas
%LET studydir = &spl_root./examples;  /* the folder of the study: data/, adam/ and out/ */
```

### 2. Read the ADaM transport files

Skip this step if your ADaM data are SAS data sets already. `%import_xpt` copies each transport file into a SAS data
set of a folder. `members=` names the data sets; the macro reads `<dir>/<member>.xpt` (or the same name in lower
case). Read the ADaM data sets that the program uses into the folder `adam` of the study. The folder of `out=` must
exist; `OPTIONS DLCREATEDIR;` lets the LIBNAME statement of the macro make it:

```sas
OPTIONS DLCREATEDIR;
%import_xpt(
     dir     = &studydir./data
   , members = adsl adae
   , out     = &studydir./adam
 )
```

The library reads ADaM data sets: the statistics macros and the tables need the variables of ADaM, such as `TRT01A`,
`SAFFL` and `AVAL`. Make the ADaM data sets from the SDTM data before this program, in the programs of the ADaM.

`%import_xpt` stands alone: a program that only converts the data may include `macros/import_xpt.sas` without the
rest of the library.

### 3. Start the program with %study

Call `%study` once, at the top of each program, before any other macro of the library. Its first value is the name
of the study, without a keyword and without quotes. `program=` is the name of this program:

```sas
%study(
     CDISCPILOT01
   , program = t14_1_01
   , adam    = &studydir./adam
   , out     = &studydir./out
 )
```

```text
sashelp.vmacro where name = 'SPL_STUDY' OR name = 'SPL_PROGRAM': 2 rows
NAME         VALUE
SPL_PROGRAM  t14_1_01
SPL_STUDY    CDISCPILOT01
```

`%study` does four things:

- It sets the global macro variables `SPL_STUDY` (the study), `SPL_PROGRAM` (the program, in lower case) and
  `SPL_OUT` (the output folder). `%ard` names its numbers file after `SPL_PROGRAM` when its `file=` is not given.
- It opens the folder of `adam=` as the library `ADAM`, read only.
- It sets the output folder, `out=`. The programs write their files under it as `&spl_out./...`.

The defaults of `adam=` and `out=` are `&spl_root./adam` and `&spl_root./out`: folders of the library. With the
library in a folder of its own, always give `adam=` and `out=`, the folders of the study.
- It sets the options of the outputs (`NODATE NONUMBER NOCENTER`, `MISSING=' '` and the others of its
  [reference page](../reference/study.md)) and clears the TITLE and FOOTNOTE statements.

A macro reads the data set of its `data=`, never the library `ADAM` by itself. Select the population in a DATA step
of the program:

```sas
DATA saf;
  SET adam.adsl;
  WHERE saffl = 'Y';
RUN;
```

```text
saf: the first 5 of 254 rows
USUBJID      TRT01A                SAFFL
01-701-1015  Placebo               Y
01-701-1023  Placebo               Y
01-701-1028  Xanomeline High Dose  Y
01-701-1033  Xanomeline Low Dose   Y
01-701-1034  Xanomeline High Dose  Y
```

### 4. Write the outputs into their folders

Each output goes into one folder of the output folder. A program gives the path in `file=`:

| Folder | What goes there | Written by |
|---|---|---|
| `&spl_out./tlf` | the tables, as `<file>.rtf` and `<file>.lst` | `%print`, the one-call tables (`%table`, `%table_summary`, ...) |
| `&spl_out./listings` | the listings, and the CSV files of `%csv` | `%print`, `%csv` |
| `&spl_out./figures` | the figures, as `<file>.png` and `<file>.rtf`, and the numbers of a figure as CSV | the figure macros (`%kmplot`, `%meanplot`, ...), `%csv` with `folder = figures` |
| `&spl_out./ard` | the numbers files, one CSV file per output | `%ard` |

A folder that is missing is made when a macro writes its first file there, with a NOTE in the log that names it. For
example, a table of age by treatment goes to `&spl_out./tlf/t14_1_01`, and its numbers to `&spl_out./ard`:

```sas
%describe(data=saf, var=age, by=trt01a, label="Age (years)", out=t_age)
%stack(t_age, out=t_age_table)
%columns(data=t_age_table, n=saf, var=trt01a, order=trt01an, out=t_age_cols)
%ard(data=t_age_table, columns=t_age_cols)
```

```text
ard/t14_1_01.csv: the first 6 of 22 lines
result,stat,g1_value,g2_value,g3_value,g4_value,g5_value,raw,formatted
N,n,Placebo,,,,,86,(N=86)
N,n,Xanomeline Low Dose,,,,,96,(N=96)
N,n,Xanomeline High Dose,,,,,72,(N=72)
T_AGE,n,Placebo,,,,,86,86
T_AGE,mean,Placebo,,,,,75.2093023255814,75.2
```

### 5. Keep the log short

Every macro writes a line to the log when it begins and when it ends (`NOTE: [describe] begins ...`). To leave these
lines out, set the global macro variable `spl_quiet` before the calls:

```sas
%LET spl_quiet = yes;
```

The messages of a wrong call (ERROR and WARNING) are still written. Set `%LET spl_quiet = no;` to have the lines
again.

## The whole start of a program

```sas
%LET spl_root = /opt/sapling-sas;         /* the folder of the library */
%LET studydir = /studies/cdiscpilot01;    /* the folder of the study */
%INCLUDE "&spl_root./macros/sapling.sas";
%LET spl_quiet = yes;

%study(
     CDISCPILOT01
   , program = t14_1_01
   , adam    = &studydir./adam
   , out     = &studydir./out
 )

DATA saf;
  SET adam.adsl;
  WHERE saffl = 'Y';
RUN;
```

The macros come from `/opt/sapling-sas/macros`, the ADaM data sets from `/studies/cdiscpilot01/adam`, and the
outputs go to `/studies/cdiscpilot01/out`. Another study needs only another `studydir`.

## Related

- Reference: [%study](../reference/study.md), [%import_xpt](../reference/import_xpt.md),
  [%ard](../reference/ard.md), [%print](../reference/print.md).
- Explanation: [How a program reads](../explanation/program.md).
