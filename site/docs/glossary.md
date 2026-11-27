# Glossary

The words the manual uses with one fixed meaning.

block
:   The rows of a table that one call of a statistics macro makes, under one label (`label=`). A table is a stack of
    blocks.

columns data set
:   The data set `%columns` makes: one row per column of the table, with its value, its N and its header.

display data set
:   The data set `%layout` makes: one row per printed line of the table, `ROW` for the label and `C1`, `C2`, ... for
    the cells. `%print` prints it.

example data
:   The data sets in `examples/data`, read by `examples/setup.sas`: subjects of the CDISC pilot study, from the R
    packages `pharmaverseadam` and `pharmaversesdtm`.

long program
:   The program a one-call table (`%table_summary`, `%table_ae`, `%table_model` ...) writes and runs: the population,
    the records, one call per block, `%stack` and `%table`, the calls a person would write by hand. `show = yes`
    writes it to the log, `show=` with a file path (without quotes) to that file; start from it to add or change a
    block.

numbers file
:   The CSV file `%ard` writes: every number of a table, written with the format `BEST32.` (at most 15
    significant digits, the last one cut, not rounded), and its printed text.

output folder
:   The folder where tables, figures and numbers files go. `%study` sets it; a program calls it `&spl_out.`.

pattern
:   The printed form of a statistic, written with `X` for the digits: `XX.X` prints one decimal. See
    [How a number is kept and printed](explanation/numbers.md).

result
:   The data set a statistics macro writes (`out=`): one row per number, in the [result shape](explanation/result-shape.md).

result shape
:   The variables every result has: the group variables (of `by=`, and of `var=` or `within=` for a category or a
    level), `GROUPS`, `BLOCK`, `STAT`, `VALUE` and `TEXT`.

setup
:   `setup=` of `%layout`: the name of a global macro variable that `%layout` fills with the call of `%print` for its
    display data set. The program prints with `%print(&<setup>.)`, such as `%print(&t_first_print.)`.

twin
:   The numeric variable that gives the order of a character variable: `TRT01AN` is the twin of `TRT01A`. Macros sort
    columns by the twin (`order=` of `%columns`, `%table` and the one-call tables), and the groups of a comparison
    (`order=` of `%lsmeans`, `%cox` ...). `order=` of `%freq` is not a twin: `order = frequency` ranks the rows by
    their subjects and writes the rank into the twin of the variable. See
    [How the parameters are named](explanation/conventions.md).
