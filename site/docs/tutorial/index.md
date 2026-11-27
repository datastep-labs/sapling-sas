# Tutorial: your first table

In this tutorial you make a table of age and sex by treatment, from the example data to an RTF file. You run one
call at a time and look at what each call made. It takes about fifteen minutes.

You need SAS 9.4 and a copy of the repository
[datastep-labs/sapling-sas](https://github.com/datastep-labs/sapling-sas). You may run the tutorial and the examples
to evaluate the macros; using them in your own work needs a license (see the README of the repository).

## The example data

The folder `examples/data` holds the example data: eight data sets of the R packages `pharmaverseadam` and
`pharmaversesdtm`, the subjects of the CDISC pilot study. The program `examples/setup.sas` reads them.

1. Open `examples/setup.sas`.
2. Find the line `%LET spl_root = /path/to/sapling-sas;`, below the header box. Change the path to the folder of
   your copy of the repository, for example:

    ```sas
    %LET spl_root = /home/me/sapling-sas;
    ```

3. Submit the whole program. The log has the line `NOTE: [study] ends after ... seconds.` and no ERROR.

The program loads the macros, reads the data, and makes the WORK data sets `adsl`, `adae`, `advs`, `adlb`, `adtte`
and `adrs`. It also sets the *output folder*, `examples/out` in your copy, which the programs call `&spl_out.`: every
table and file of this tutorial goes there. `adsl` holds the safety population. These are its first rows:

```text
adsl: the first 5 of 254 rows
USUBJID      TRT01A                TRT01AN  AGE  SEX  RACE
01-701-1015  Placebo                     0   63  F    WHITE
01-701-1023  Placebo                     0   64  M    WHITE
01-701-1028  Xanomeline High Dose       81   71  M    WHITE
01-701-1033  Xanomeline Low Dose        54   74  M    WHITE
01-701-1034  Xanomeline High Dose       81   77  F    WHITE
```

Each row is one subject. You use `trt01a` for the columns of the table, `age` and `sex` for its rows.

## Step 1: summarize a numeric variable

Call `%describe` for the age in each treatment group:

```sas
%describe(
     data  = adsl
   , var   = age
   , by    = trt01a
   , total = yes
   , label = "Age (years)"
   , out   = t_age
 )
```

```text
t_age: the first 7 of 24 rows
TRT01A   BLOCK        STAT           VALUE  TEXT
Placebo  Age (years)  n                 86    86
Placebo  Age (years)  mean    75.209302326  75.2
Placebo  Age (years)  sd      8.5901671271  8.59
Placebo  Age (years)  median            76  76.0
Placebo  Age (years)  min               52    52
Placebo  Age (years)  max               89    89
Total    Age (years)  n                254   254
```

`t_age` is the *result* of the call: one row per number. `VALUE` holds the number with all its digits. `TEXT` holds
it as the table will print it. `total = yes` added the group `Total`.

## Step 2: count the categories

Call `%freq` for the sex in each treatment group:

```sas
%freq(
     data  = adsl
   , var   = sex
   , by    = trt01a
   , total = yes
   , label = "Sex"
   , out   = t_sex
 )
```

```text
t_sex: the first 6 of 16 rows
TRT01A   SEX  BLOCK  STAT         VALUE  TEXT
Placebo  F    Sex    n               53  53
Placebo  F    Sex    pct   61.627906977  (61.6%)
Placebo  M    Sex    n               33  33
Placebo  M    Sex    pct   38.372093023  (38.4%)
Total    F    Sex    n              143  143
Total    F    Sex    pct   56.299212598  (56.3%)
```

The result has the same variables as `t_age`, and one more: `SEX`, the category. Every statistics macro writes this
shape, so the next calls can use any of them.

## Step 3: stack the blocks

Put the two results under each other, in the order of the table:

```sas
%stack(t_age t_sex, out=t_first)
```

```text
t_first: the first 4 of 40 rows
RESULT  ORD  BLOCK        TRT01A   STAT    TEXT
T_AGE     1  Age (years)  Placebo  n         86
T_AGE     1  Age (years)  Placebo  mean    75.2
T_AGE     1  Age (years)  Placebo  sd      8.59
T_AGE     1  Age (years)  Placebo  median  76.0
```

`RESULT` and `ORD` say which result each row came from, and its place in the table.

## Step 4: make the columns

Make the columns of the table and the N of each:

```sas
%columns(
     data  = t_first
   , n     = adsl
   , var   = trt01a
   , order = trt01an
   , total = yes
   , out   = t_first_cols
 )
```

```text
t_first_cols: 4 rows
HEADER                       COLVALUE              COL  BIGN
Placebo|(N=86)               Placebo                 1    86
Xanomeline Low Dose|(N=96)   Xanomeline Low Dose     2    96
Xanomeline High Dose|(N=72)  Xanomeline High Dose    3    72
Total|(N=254)                Total                   4   254
```

The columns come from the data: three treatment groups, in the order of `trt01an`, then `Total`. Each `HEADER` holds
the name of the column and its N.

## Step 5: keep every number

Write every number of the table to a CSV file:

```sas
%ard(data=t_first, columns=t_first_cols, file=t_first)
```

```text
ard/t_first.csv: the first 8 of 45 lines
result,stat,g1_value,g2_value,g3_value,g4_value,g5_value,raw,formatted
N,n,Placebo,,,,,86,(N=86)
N,n,Xanomeline Low Dose,,,,,96,(N=96)
N,n,Xanomeline High Dose,,,,,72,(N=72)
N,n,Total,,,,,254,(N=254)
T_AGE,n,Placebo,,,,,86,86
T_AGE,mean,Placebo,,,,,75.2093023255814,75.2
T_AGE,sd,Placebo,,,,,8.59016712714192,8.59
```

The file is `examples/out/ard/t_first.csv`: `file=` of `%ard` is a name, and the macro puts the file in the folder
`ard` of the output folder. Each line holds one number as SAS keeps it, written with the format `BEST32.` (`raw`,
up to 15 significant digits), and its printed text (`formatted`). A second program can check its own numbers against this file.

## Step 6: lay out the rows

Make the rows of the table:

```sas
%layout(
     data    = t_first
   , columns = t_first_cols
   , var     = trt01a
   , file    = &spl_out./tlf/t_first
   , setup   = t_first_print
   , out     = t_first_display
 )
```

```text
t_first_display: 9 rows
GRP  ROW          C1           C2           C3           C4
  1  Age (years)
  1  n            86           96           72           254
  1  Mean (SD)    75.2 (8.59)  76.0 (8.11)  73.8 (7.94)  75.1 (8.25)
  1  Median       76.0         78.0         75.5         77.0
  1  Min, Max     52, 89       51, 88       56, 88       51, 89
  2
  2  Sex
  2  F            53 (61.6%)   55 (57.3%)   35 (48.6%)   143 (56.3%)
  3  M            33 (38.4%)   41 (42.7%)   37 (51.4%)   111 (43.7%)
```

`t_first_display` holds one row per printed line: `ROW` is the label, `C1` to `C4` are the cells of the four columns.
`GRP` numbers the rows that must stay on one page: the age block is group 1, and each category of sex is a group of
its own. You can change this data set with a DATA step before you print it, for example to rename a row.

Here `file=` is a path without its extension: `%print` adds `.rtf` and `.lst`.

## Step 7: print the table

Write the titles, then print:

```sas
TITLE1 "Table 1 Age and sex by treatment";
TITLE2 "Safety population";
FOOTNOTE1 J=L "Program: first_table.sas";
%print(&t_first_print.)
```

```text
tlf/t_first.lst: 18 lines
Table 1 Age and sex by treatment
Safety population

             Placebo      Xanomeline Low Dose  Xanomeline High Dose  Total
             (N=86)       (N=96)               (N=72)                (N=254)
--------------------------------------------------------------------------------

Age (years)
  n          86           96                   72                    254
  Mean (SD)  75.2 (8.59)  76.0 (8.11)          73.8 (7.94)           75.1 (8.25)
  Median     76.0         78.0                 75.5                  77.0
  Min, Max   52, 89       51, 88               56, 88                51, 89

Sex
  F           53 (61.6%)   55 (57.3%)           35 (48.6%)           143 (56.3%)
  M           33 (38.4%)   41 (42.7%)           37 (51.4%)           111 (43.7%)

Program: first_table.sas
```

`%print` wrote two files to the folder `tlf` of the output folder: `t_first.rtf` for Word and `t_first.lst`, the text
you see above. `&t_first_print.` holds the call of `%print` that `%layout` prepared with `setup=`.

## What you made

You made a table in seven calls. Each call made a data set or a file that you could open:

| Call | It made |
|---|---|
| `%describe`, `%freq` | the results, one row per number |
| `%stack` | the results in the order of the table |
| `%columns` | the columns and their N |
| `%ard` | the numbers file |
| `%layout` | the rows of the table |
| `%print` | the RTF file and the listing |

Next:

- [How-to guides](../how-to/index.md): a demographic table with tests, an adverse event table, a model, a figure.
- [How a program reads](../explanation/program.md): why the calls come in this order.
- [Reference](../reference/index.md): every parameter of every macro.
