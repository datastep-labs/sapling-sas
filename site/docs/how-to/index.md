# How-to guides

Each guide solves one task of a clinical SAS programmer, step by step, on the example data. The guides assume that
you know SAS and the ADaM data. To learn the library from the start, do the [tutorial](../tutorial/index.md) first.

| Guide | The task it solves |
|---|---|
| [Derive analysis visits, the baseline and the change from baseline](derive-baseline.md) | Add `avisit`, `ablfl`, `anl01fl`, `base` and `chg` to the records of a BDS data set. |
| [Make a demographic table with tests](demographic-table.md) | Summarize the characteristics of the subjects by treatment, with a p-value for each. |
| [Make an adverse event table](adverse-event-table.md) | Count the subjects with an event by system organ class and preferred term, with Fisher's exact test. |
| [Make an efficacy table with an ANCOVA](efficacy-table.md) | Show an endpoint at a visit with the LS means and their differences from a model. |
| [Make a Kaplan-Meier figure with the number at risk](kaplan-meier-figure.md) | Draw the curves of a time to an event by treatment, with the median and the log-rank p-value. |
| [Make one page per subgroup](page-per-subgroup.md) | Print a table once for each value of a subgroup, with the N of each page. |
| [Check a table against an independent program](check-a-table.md) | Compare every number of a table with the numbers of a second program. |
