# The result shape

Every statistics macro writes its numbers in one shape, its *result*. `%describe`, `%freq`, `%ancova`, `%km` and the
others all write the same variables. That is why `%stack`, `%columns`, `%ard` and `%layout` work with any of them,
and why a programmer can read any result without the manual of its macro.

## One row per number

A result has one row per number. A row says which group the number belongs to, which statistic it is, and its value.

| Variable | Holds | Example |
|---|---|---|
| the `by=` variables | the group, with the names and values of the data | `TRT01A = 'Placebo'` |
| the `var=` and `within=` variables | the category or the level of the row: a category of `%freq`, a term of `%fisher` | `SEX = 'F'` |
| `VERSUS` | the group a comparison is made against (only a macro that compares groups) | `'Placebo'` |
| `GROUPS` | the names of the group variables, in order | `'TRT01A VERSUS'` |
| `BLOCK` | the label of the block in the table (`label=`) | `'Age (years)'` |
| `STAT` | the statistic | `n`, `mean`, `sd`, `pct`, `diff`, `pval` |
| `VALUE` | the number, with every digit | `75.2093023255814` |
| `TEXT` | the number as the table prints it | `75.2` |

This is the result of a call of `%describe` on the example data, its first rows:

```sas
%describe(data=adsl, var=age, by=trt01a, label="Age (years)", out=age)
```

```text
age: the first 4 of 18 rows
TRT01A   GROUPS  BLOCK        STAT           VALUE  TEXT
Placebo  TRT01A  Age (years)  n                 86    86
Placebo  TRT01A  Age (years)  mean    75.209302326  75.2
Placebo  TRT01A  Age (years)  sd      8.5901671271  8.59
Placebo  TRT01A  Age (years)  median            76  76.0
```

The listing shows `VALUE` in at most 12 characters; the data set keeps the full value that SAS computed.

## Why one shape

A table mixes many kinds of numbers: counts, means, p-values, hazard ratios. If each macro wrote its own shape, each
next step would need a branch for each macro. With one shape, the next steps read every result in the same way:

- `%stack` puts results of different macros under each other.
- `%layout` finds the line and the column of each number from `BLOCK`, `STAT` and the group variables.
- `%ard` writes every `VALUE` to a CSV file, for a check against another program or another language.

The shape is long, not wide: one row per number, not one variable per statistic. A long shape keeps every number
with its own label. A new statistic is a new value of `STAT`, not a new variable.

## No data qualified

When a statistics macro finds no record to use, it writes its result with no row and this line in the log:

```text
NOTE: [describe] No data qualified: no record meets where= and the conditions of the macro.
```

It does not stop the program. When the whole table has no row, `%print` prints the text of `nodata=`
(`No data qualified` by default) under the titles of the table. An empty table is a result of the study, not an
error of the program.
