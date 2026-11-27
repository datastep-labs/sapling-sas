# Run the examples of the reference

This guide shows how to run the examples of the reference pages yourself, with the same output as the pages show.
Each reference page has examples, and under each call the output that call made when the examples ran on SAS.

## Before you start

- Have a copy of the repository [datastep-labs/sapling-sas](https://github.com/datastep-labs/sapling-sas) and SAS 9.4.
- Set the path in `examples/setup.sas`, as the [tutorial](../tutorial/index.md#the-example-data) shows.

## Why one session and one order

The examples ran in one SAS session, after `examples/setup.sas`, one macro after the other. A later example may read
a data set that an earlier example made with its `out=`: the example of `%columns` reads the table that the example
of `%stack` made, and the example of `%kmplot` reads the time to an event of `%tte`. Each reference page says which
data sets its examples read from another example, under "They also read", with a link to that example.

So run the examples in the same session and in the order below. An example that you run alone, out of this order,
may stop with an ERROR because a data set it reads does not exist yet.

## Steps

### 1. Run the setup

Submit the whole of `examples/setup.sas`. It loads the macros, reads the example data, calls `%study`, and makes the
WORK data sets `adsl` (the safety population), `adae`, `advs`, `adlb`, `adtte` and `adrs` that the examples read.

### 2. Run the examples in this order

The program [examples/reference.sas](https://github.com/datastep-labs/sapling-sas/blob/main/examples/reference.sas)
holds every example in this order: submit it after `examples/setup.sas`, in the same session, whole or one part after
another. To run the examples of one page by hand, submit the pages before it first, in the order below: the parts in
their order, and in each part the pages in the order of its list. The code of a page is all its blocks, top to bottom.

#### Read the data and start the program

`%tte` comes this early because its result, `adttde`, is the time to an event that `%km`, `%logrank`, `%cox`,
`%kmplot` and `%table_tte` read.

1. [%import_xpt](../reference/import_xpt.md)
2. [%study](../reference/study.md)
3. [%tte](../reference/tte.md)

#### Statistics

Each statistics macro writes a result. `%adjust` reads the result of `%lsmeans`.

1. [%describe](../reference/describe.md)
2. [%anova](../reference/anova.md)
3. [%freq](../reference/freq.md)
4. [%chisq](../reference/chisq.md)
5. [%worst](../reference/worst.md)
6. [%termflags](../reference/termflags.md)
7. [%fisher](../reference/fisher.md)
8. [%cmh](../reference/cmh.md)
9. [%proportion](../reference/proportion.md)
10. [%risk](../reference/risk.md)
11. [%logistic](../reference/logistic.md)
12. [%rate](../reference/rate.md)
13. [%rateratio](../reference/rateratio.md)
14. [%ancova](../reference/ancova.md)
15. [%lsmeans](../reference/lsmeans.md)
16. [%adjust](../reference/adjust.md)
17. [%mmrm](../reference/mmrm.md)
18. [%ttest](../reference/ttest.md)
19. [%wilcoxon](../reference/wilcoxon.md)
20. [%interaction_glm](../reference/interaction_glm.md)
21. [%interaction_logistic](../reference/interaction_logistic.md)
22. [%interaction_genmod](../reference/interaction_genmod.md)
23. [%km](../reference/km.md)
24. [%logrank](../reference/logrank.md)
25. [%cox](../reference/cox.md)
26. [%interaction_phreg](../reference/interaction_phreg.md)

#### Build a table

`%stack` stacks the results of `%describe`, `%anova`, `%freq` and `%chisq`; `%columns`, `%ard`, `%layout` and
`%print` then work on that table, each on what the call before it made.

1. [%stack](../reference/stack.md)
2. [%columns](../reference/columns.md)
3. [%ard](../reference/ard.md)
4. [%layout](../reference/layout.md)
5. [%print](../reference/print.md)
6. [%table](../reference/table.md)
7. [%csv](../reference/csv.md)

#### Figures

The figures take their order and their colors from the columns of `%columns`. `%lineplot` draws the numbers that
`%meanplot` kept.

1. [%kmplot](../reference/kmplot.md)
2. [%forestplot](../reference/forestplot.md)
3. [%meanplot](../reference/meanplot.md)
4. [%lineplot](../reference/lineplot.md)
5. [%boxplot](../reference/boxplot.md)
6. [%barplot](../reference/barplot.md)
7. [%aeplot](../reference/aeplot.md)
8. [%profileplot](../reference/profileplot.md)
9. [%scatterplot](../reference/scatterplot.md)

#### Tables in one call

Each one-call table reads the data sets of `setup.sas`; `%table_tte` also reads `adttde` of `%tte`.

1. [%table_summary](../reference/table_summary.md)
2. [%table_ae](../reference/table_ae.md)
3. [%table_visit](../reference/table_visit.md)
4. [%table_model](../reference/table_model.md)
5. [%table_response](../reference/table_response.md)
6. [%table_tte](../reference/table_tte.md)
7. [%table_shift](../reference/table_shift.md)

#### ADaM steps

Each step of an ADaM program changes a data set in place. Its example first copies the records it needs into a data
set of its own (`vs`, `lb`, `sl` or `tt`), so `advs`, `adlb`, `adsl` and `adtte` stay as `setup.sas` made them.

1. [%merge_subject](../reference/merge_subject.md)
2. [%pick](../reference/pick.md)
3. [%summarize](../reference/summarize.md)
4. [%flag_if_any](../reference/flag_if_any.md)
5. [%pool](../reference/pool.md)
6. [%param_wide](../reference/param_wide.md)
7. [%summarize_groups](../reference/summarize_groups.md)
8. [%visits](../reference/visits.md)
9. [%windows](../reference/windows.md)
10. [%locf](../reference/locf.md)
11. [%baseline](../reference/baseline.md)
12. [%flag_first](../reference/flag_first.md)
13. [%relchange](../reference/relchange.md)

### 3. Compare with the pages

The output under each call on a reference page is the output of this run: the first rows of each data set of
`out=`, the first lines of each `.lst` and CSV file, and each figure. The tables, listings and figures are in the
output folder `examples/out` (`&spl_out.`), in its folders `tlf`, `listings`, `figures` and `ard`.

## Related

- Reference: [the families of the macros](../reference/index.md).
- How-to: [Use the macros in your own program](own-program.md).
