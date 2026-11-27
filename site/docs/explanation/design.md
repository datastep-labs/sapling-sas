# One macro, one procedure

The macros follow a small number of rules. The rules make a program easy to read for a person who knows SAS but has
never seen the library, and easy to check for a reviewer or a regulator.

## A macro holds the procedure it runs

`%describe` contains its PROC MEANS. `%freq` contains its PROC FREQ. `%lsmeans` contains its PROC MIXED. A person who
opens the file of a macro finds the procedure in it, with the options it uses. There is no dispatcher that chooses a
procedure from a text, no table of metadata, and no option that is parsed back out of a string.

## Data in, data out

A macro reads data sets and writes data sets. It keeps no state between calls: a result goes from one call to the next
only as a data set that the program names. Two calls with the same parameters give the same result. Every result is a
data set in WORK that a person can open, print and change.

One parameter is a deliberate exception. `setup=` of `%layout` names a global macro variable that keeps the call of
`%print` for the display data set, so that `%print(&t14_2_01_print.)` prints it again after a change. The program
chooses the name and the log shows its value; no other macro reads it.

## The groups come from the data

`by=` names a variable. The columns are its values. The program never lists the treatment arms.

## One printer

`%print` holds the only PROC REPORT of the library. Every table and listing goes through it, so every output has the
same look: `<file>.rtf` (ODS RTF, the style `journal`) and `<file>.lst` (a monospace listing). A figure is one call of
its figure macro, with one PROC SGPLOT or PROC SGPANEL in it.

## A clear message, then stop

Every macro checks its parameters before it does anything. A wrong call writes two lines and stops:

```text
ERROR: [describe] var=AGEX is not a variable of adsl
ERROR: [describe]   fix: give var= a variable of data=.
```

The first line names the parameter and the fault. The second line says what to change. No procedure runs on wrong
input, so the log never fills with the errors of a procedure.

## What the library leaves out on purpose

| Not in the library | Instead |
|---|---|
| A population parameter in the building blocks | a DATA step in the program, visible to the reviewer |
| A list of treatments | the values of `by=` |
| Sorting of the input | the program sorts; a macro keeps the order it is given |
| "(Continued)" lines, page headers, splits of wide tables by hand | the titles and footnotes of the program; PROC REPORT pages and splits |
| PROC SQL, PROC EXPORT | DATA steps and procedures that a SAS programmer reads at a glance |

## The tables in one call

`%table_summary`, `%table_ae` and the other one-call tables are the exception to the building blocks: one call makes a
whole standard table. They have a population parameter (`pop=`), because a standard table always has one. They hide
nothing: each call runs the long program it stands for, the same calls of `%describe`, `%freq`, `%stack`, `%layout`
and `%print` that a programmer would write. `show=yes` writes that long program to the log, and `show=<file>` writes
it to a file and runs it from there. A reviewer reads the long program; a programmer who needs a change starts from it.

## The house style

Each macro file has the same parts in the same order: a header box (purpose, procedure, proof, parameters, output,
example, change log), the signature with one parameter per line, the checks, numbered steps, and the deletion of its
work data sets (kept with `debug=yes`). Keywords are upper case, names are lower case. A checker enforces these rules
on every file.
