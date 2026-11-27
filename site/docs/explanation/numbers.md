# How a number is kept and printed

Every number exists twice in a result: as `VALUE`, with every digit SAS computed, and as `TEXT`, the way the table
prints it. The two never mix. A table shows `TEXT`; every check reads `VALUE`.

## The pattern

`stats=` gives each statistic a *pattern*. The pattern shows the printed form of one number with a group of `X`:

| Pattern | The number | Prints as | Used for |
|---|---|---|---|
| `XX` | 75.2093 | `75` | counts, minimum, maximum |
| `XX.X` | 75.2093 | `75.2` | mean, median, LS mean, a difference |
| `XX.XX` | 75.2093 | `75.21` | standard deviation, standard error |
| `(XX.X%)` | 75.2093 | `(75.2%)` | a percent |
| `X.XXX` | 0.2451 | `0.245` | a p-value |

The number of `X` after the point is the number of decimals. The `X` before the point do not limit the number: `XX`
prints 254 as `254`. The text around the `X` group, such as the brackets and the percent sign, prints as written.

Each statistic has a default pattern, so `stats=` is needed only to change one. A name without a pattern in
`stats=` takes its default pattern: `stats = n mean sd` prints n with `XX`, the mean with `XX.X` and the SD with
`XX.XX`.

```sas
%describe(
     data  = adsl
   , var   = age
   , by    = trt01a
   , stats = n="XX" mean="XX.XX" sd="XX.XX" median="XX.X" min="XX" max="XX"
   , out   = age
 )
```

The order of `stats=` is also the order of the lines in the table.

!!! warning "Minimum and maximum print as whole numbers by default"
    The default pattern of `min` and `max` is `XX`, which suits ages and counts. A laboratory value with decimals
    loses them: a minimum of 3.9 prints as `4`. Give the pattern with the decimals of the data:
    `stats = n mean sd median min="XX.X" max="XX.X"`.

## Rounding

The text is `ROUND(value, 10 ** -decimals)`: SAS rounds a tie away from zero, so 2.25 with `XX.X` prints as `2.3`.
R rounds a tie to the even digit and prints `2.2`. Both are correct roundings of the same value. This is why the
[proof](proof.md) counts a reference number as the same when it is a correct rounding of the SAS value, either way.

## A p-value is never 0 or 1

A p-value that rounds to 0 prints as `<0.001` (with the pattern `X.XXX`), and one that rounds to 1 prints as
`>0.999`. Only `TEXT` changes. `VALUE` keeps the number: a p-value of 0.00004 stays 0.00004 in the result and in the
numbers file.

## The numbers file

`%ard` writes every `VALUE` of a table, and the N of each column, to a CSV file in the folder `ard` of the output
folder. Its parameter `file=` is a name, not a path: `file=t_first` writes `&spl_out./ard/t_first.csv`. These are the
first lines of the numbers file of the [tutorial](../tutorial/index.md):

```text
ard/t_first.csv: the first 7 of 45 lines
result,stat,g1_value,g2_value,g3_value,g4_value,g5_value,raw,formatted
N,n,Placebo,,,,,86,(N=86)
N,n,Xanomeline Low Dose,,,,,96,(N=96)
N,n,Xanomeline High Dose,,,,,72,(N=72)
N,n,Total,,,,,254,(N=254)
T_AGE,n,Placebo,,,,,86,86
T_AGE,mean,Placebo,,,,,75.2093023255814,75.2
```

Each line is one number: the result it comes from (`result`), its statistic (`stat`), its groups (`g1_value` to
`g5_value`: the first is the column of the table, the others the levels of the row, at most five), the value as SAS
keeps it, written with the format `BEST32.` (`raw`, up to 15 significant digits) and the printed text (`formatted`). A second program, in SAS or in R, can compare its own numbers with this file without
reading the table. The [proof](proof.md) compares this file with the published numbers of pharmaverse.
