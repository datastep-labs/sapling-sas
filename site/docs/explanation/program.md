# How a program reads

A program that uses the library reads like the table it makes. A reviewer who reads the program from top to bottom
sees the population, each block of the table, the columns, and the print. Nothing happens out of sight.

## The order of the calls

Every table program has the same five parts, in the same order, after the library is loaded (part 0).

```sas
%LET spl_root  = /opt/sapling-sas;                         /* 0. load the library  */
%LET studydir  = /studies/cdiscpilot01;
%INCLUDE "&spl_root./macros/sapling.sas";

%study(
     CDISCPILOT01
   , program = t14_2_01
   , adam    = &studydir./adam
   , out     = &studydir./out
 )                                                          /* 1. start the program */

DATA saf;                                                  /* 2. the population    */
  SET adam.adsl;
  WHERE saffl = 'Y';
RUN;

%describe(data=saf, var=age, by=trt01p, label="Age", out=t_age)     /* 3. one call per block */
%freq(data=saf, var=race, by=trt01p, label="Race", out=t_race)

%stack(t_age t_race, out=t14_2_01)                        /* 4. the table as data */
%columns(data=t14_2_01, n=saf, var=trt01p, order=trt01pn, out=t14_2_01_cols)
%ard(data=t14_2_01, columns=t14_2_01_cols, file=t14_2_01)
%layout(
     data    = t14_2_01
   , columns = t14_2_01_cols
   , var     = trt01p
   , file    = &spl_out./tlf/t14_2_01
   , setup   = t14_2_01_print
   , out     = t14_2_01_display
 )

TITLE1 "Table 14-2.01 Summary of Demographic and Baseline Characteristics";
%print(&t14_2_01_print.)                                  /* 5. the output        */
```

0. **Load the library.** `spl_root` names the folder that holds `macros/`, and the loader `macros/sapling.sas`
   includes every macro. A program of a study does this once, at the top; a program run in a session that has the
   library already leaves it out. [Use the macros in your own program](../how-to/own-program.md) shows the steps.
1. **Start.** `%study` sets the options of the program, the library `ADAM` and the output folder `&spl_out.`.
2. **The population.** A plain DATA step selects the subjects. The macros do not hide a population inside a parameter.
3. **The blocks.** Each block of the table is one call of one statistics macro: `%describe` for a number, `%freq` for
   categories, `%ancova` or `%lsmeans` for a model. Each call writes one data set, its *result*.
4. **The table as data.** `%stack` puts the results under each other in the order of the table. `%columns` makes the
   columns and the N of each. `%ard` writes every number to a CSV file. `%layout` makes the *display data set*: one
   row per printed line, one variable per column.
5. **The output.** The program writes its own titles and footnotes. `%print` prints the display data set as RTF and
   as a text listing.

A figure follows the same pattern up to part 3. Then one call of its figure macro (`%kmplot`, `%meanplot`, ...)
computes what it draws and writes the figure.

## Why the steps are separate

Each step writes a data set that a person can open. A programmer who checks a table can stop after any step and look:

| After | Look at | To check |
|---|---|---|
| a statistics macro | its result | the numbers of one block |
| `%stack` | the stacked results | the order of the blocks |
| `%columns` | the columns data set | the column order and each N |
| `%ard` | the numbers file | every number written with `BEST32.` (15 significant digits) and as printed |
| `%layout` | the display data set | each printed line, before it is printed |

A change in one step is made in one place. For example, a sponsor who wants another row label changes the display
data set in a DATA step and prints it again with `%print(&t14_2_01_print.)`. No statistic is computed again.

## The groups come from the data

The columns of a table are the values of the `by=` variable. The program never types the treatment names. A study
with four arms gives four columns without a change of the program. `order=` names the numeric variable that sorts
the columns (`trt01pn`), and `total=yes` adds a column of all subjects.
