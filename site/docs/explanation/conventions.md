# How the parameters are named

Most parameter names mean the same in every macro: `data=` is the input data set, `where=` the records to use,
`out=` the result. A few names mean different things in different macros. This page lists them, so that a call
of a new macro does not surprise you. The reference page of each macro gives the exact text.

## order=

| Macros | What `order=` is | Example |
|---|---|---|
| `%columns`, `%table`, `%table_summary`, `%table_ae`, `%table_visit`, `%table_shift`, `%table_model`, `%table_response`, `%table_tte` | the numeric twin of the column variable: the columns are in its order | `order = trt01an` |
| `%lsmeans`, `%mmrm`, `%cox`, `%logistic`, `%risk`, `%rateratio`, `%ttest`, `%wilcoxon` | the numeric twin of `by=`: the order of the groups, and so which group comes first in a pair | `order = trt01pn` |
| `%freq` | a keyword, not a variable: `frequency` ranks the rows of `orderof=` by their subjects, the most first | `order = frequency` |
| `%flag_first`, `%pick`, `%relchange` | the sort keys of the records within a group, as in a BY statement | `order = descending adt` |

`%freq` writes the rank of `order = frequency` into the twin of the variable (`AEDECODN` for `AEDECOD`), and `%print`
orders the rows by it. `%table_ae` has the same ranking under another name, `sort = frequency`. `sort=` of
`%aeplot` orders the terms of a figure: `difference`, `frequency` or `alphabetical`.

## by=

| Macros | What `by=` is |
|---|---|
| the statistics macros (`%describe`, `%freq`, `%km`, ...) | the groups. The first variable gives the columns of the table; in `%describe` and `%freq` the others give its rows or its pages. |
| the macros that compare groups (`%lsmeans`, `%cox`, `%ttest`, ...) | the groups of the model: one character variable (`trt01p`, not `trt01pn`) |
| the one-call tables (`%table_*`) | the groups of the columns: one character variable |
| the figure macros (`%kmplot`, `%meanplot`, ...) | the groups: one curve, line, box or colour per group |
| the ADaM steps (`%baseline`, `%flag_first`, `%locf`, `%relchange`, `%param_wide`, ...) | the groups of records, such as the subject and the parameter (`by = usubjid paramcd`) |
| `%print` | the left columns of the listing, printed first; a repeated value is shown once |
| `%worst` | the variables of a row (`by = aebodsys aedecod`); the worst records of a subject are kept in each row |
| `%pool` | the variable whose every group must have `min=` records |

## keep=

`keep=` names other variables to keep in a result, for the names and the order of its rows. Where a group has more
than one value of such a variable, the macros take different values:

| Macro | The value kept |
|---|---|
| `%describe` | the largest value in the group (the ID statement of PROC MEANS) |
| `%freq` | the value of the first record of the category |
| `%table_visit`, `%table_shift` | `keep=` of the `%describe` or `%freq` calls they make |
| `%tte` | the value on the record taken (the event or the censoring); the variables must be in `events=` and in `censors=` |

Keep only variables with one value per group, such as `param` with `paramcd` or `avisitn` with `avisit`: then the
rule does not matter.

## where= and event=

`where=` is always a condition in parentheses: `where = (anl01fl = 'Y')`. In most macros it selects the records to
use. In `%flag_first` it selects the records that can be flagged, in `%flag_if_any` the records of `from=` that set
the flag, and in `%forestplot` and `%lineplot` the rows of the result to draw.

`event=` has two forms:

| Macros | What `event=` is | Example |
|---|---|---|
| `%tte` | a condition on the records of `events=`, without parentheses (they are allowed) | `event = trtemfl = 'Y'` |
| `%logistic`, `%risk`, `%table_response`, `%interaction_logistic` | the value of the response that is the event, in quotes | `event = "Y"` |

## file=

| Macros | What `file=` is | It writes |
|---|---|---|
| `%ard`, `%csv` | a name, without a path and without an extension | `&spl_out./ard/<file>.csv`; `%csv` into `listings` or the folder of `folder=` |
| `%print`, `%table`, `%table_*` | a path without an extension | `<file>.rtf` and `<file>.lst`; `%table` and `%table_*` also the numbers file in `ard`, named after the last part of the path |
| the figure macros | a path without an extension | `<file>.png` and `<file>.rtf` |
| `%layout` | a path without an extension, for the call of `%print` it prepares | nothing itself: it goes into the setup |

In `%ard` the default of `file=` is the name of the program that `%study` set. In `%table` and `%table_*`, a call
without `file=` prints nothing.

## total=

| Macros | What `total = yes` does |
|---|---|
| `%describe`, `%freq` | adds the group `Total`: all groups of the first `by=` variable together. A text in quotes gives it another name (`total = "All subjects"`). |
| `%columns`, `%table` | says that the results have the group `Total`: it becomes the last column, with the N of all subjects of `n=` |
| `%table_summary`, `%table_ae`, `%table_visit`, `%table_shift` | adds the column `Total` |

Give `total=` to the statistics macros and to `%columns` (or `%table`) together, with the same name: `%columns`
needs it to put the `Total` last, with the N of all subjects of `n=`.

## label=

| Macros | What `label=` is | Example |
|---|---|---|
| the statistics macros | the label of the block, a text in quotes: the heading of the rows of one call | `label = "Age (years)"` |
| `%print`, `%layout`, `%table` | the labels of columns: pairs `name="text"`, separated by blanks | `label = %STR(row=" ")` |

## out=, new= and the macros that change data=

| Macros | What they write |
|---|---|
| the statistics macros, `%stack`, `%columns`, `%layout`, `%tte`, `%worst`, `%param_wide`, `%relchange` ... | a new data set, named in `out=` |
| the figure macros | the numbers they draw, in `out=` when it is given |
| `%baseline`, `%flag_first`, `%flag_if_any`, `%pick`, `%pool`, `%summarize` | a new variable, named in `new=`, in `data=`: they change `data=` in place |
| `%locf` | new records in `data=`, in place, and `data=` sorted |

Two names of `out=` are not data sets: `out=` of `%study` is the output folder, and `out=` of `%import_xpt` is the
folder that gets the data sets.

A macro that changes `data=` in place changes the data set you give it. Copy the records into a data set of your
own first (`DATA vs; SET advs; WHERE paramcd = 'SYSBP'; RUN;`), so that a later step still has the original. Give
`new=` a name that `data=` does not have yet. Only two macros are made for a variable that is there: `%pick` replaces
it, with a NOTE in the log, and `%baseline` with `replace = yes` drops it and makes it again (with `replace = no` it
writes the values into the variable that is there).

## stats=

| Macros | What `stats=` is | Example |
|---|---|---|
| the statistics macros | the statistics, in the order of the rows, each name with the pattern of its printed number | `stats = n mean="XX.XX" sd` |
| `%table_summary`, `%table_visit`, `%table_ae`, `%table_shift`, `%table_model` | the same, passed to the `%describe`, `%freq` or model calls they make | |
| `%summarize_groups` | one summary per variable of `vars=`: `sum`, `mean`, `max` or `min`, with no pattern | `stats = sum max` |

A name without a pattern takes its default pattern: see
[the table of default patterns](numbers.md#the-table-of-default-patterns). A name the macro does not compute gives an
empty row and no message, as that page says. `%summarize` has one statistic, in `stat=`.

## Related

- Explanation: [The result shape](result-shape.md), [How a number is kept and printed](numbers.md).
- [Glossary](../glossary.md): the terms of these pages, such as *twin* and *block*.

## A name of a macro and a name of a method

`%ancova` is the Type III test of one numeric term, such as a dose response. The ANCOVA comparison of the treatment
groups (LS means and their differences) is [`%lsmeans`](../reference/lsmeans.md), and `%table_model` with
`method = ancova` calls `%lsmeans`, not `%ancova`.

