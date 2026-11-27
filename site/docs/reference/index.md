# Reference

One page per macro. Every page has the same parts in the same order: the syntax with every default, the parameters, the result, the details (when the macro has them), examples with their output, the messages, the macros of the same family, and the proof.

## Start a program {#start}

Set up a program and read the data.

| Macro | It makes |
|---|---|
| [%study](study.md) | Starts a program: sets the study, the program and the output folder, opens the ADaM library, sets the options. |
| [%import_xpt](import_xpt.md) | Copies SAS transport files (XPORT version 5, .xpt) into SAS data sets in a folder. |

## Describe the data {#describe}

Counts, percents, descriptive statistics, rates, and the records a count needs.

| Macro | It makes |
|---|---|
| [%describe](describe.md) | Returns the descriptive statistics of a numeric variable in each group: n, mean, SD, median, minimum and maximum. |
| [%freq](freq.md) | Counts the subjects in each category and group, with their percent of the subjects of the group. |
| [%proportion](proportion.md) | Returns the percent of subjects in each category and group, with its confidence interval by a method you name. |
| [%rate](rate.md) | Returns the exposure-adjusted incidence rate of each group, with its exact Poisson confidence limits. |
| [%worst](worst.md) | Keeps the records of each subject at its worst level, such as the highest severity or toxicity grade. |
| [%termflags](termflags.md) | Returns one record per subject and term, with a flag that says whether the subject has the term. |

## Test the groups {#tests}

One test of the groups per call: its p-value in the result.

| Macro | It makes |
|---|---|
| [%anova](anova.md) | Returns the p-value of the F test of a one-way analysis of variance of a variable between the groups. |
| [%ttest](ttest.md) | Returns the difference of the means of each pair of groups, with its confidence limits and the t-test p-value. |
| [%wilcoxon](wilcoxon.md) | Returns the p-value of the Wilcoxon rank-sum test of each pair of groups, with the Hodges-Lehmann shift and its limits. |
| [%chisq](chisq.md) | Returns the p-value of the Pearson chi-square test of the groups against the categories of a response. |
| [%fisher](fisher.md) | Returns the p-value of Fisher's exact test of the subjects with a record against the subjects without, between groups. |
| [%cmh](cmh.md) | Returns the p-value of the Cochran-Mantel-Haenszel test of the groups against the categories of a response, within strata. |
| [%ancova](ancova.md) | Returns the Type III p-value of one numeric term in a linear model, such as the test of a dose response (test = trt01pn): the test of one numeric term, not a comparison of the groups. |
| [%adjust](adjust.md) | Adds the adjusted p-values of a family of pairs of groups to a result: one row padj per pair. |

## Compare groups with a model {#models}

Estimates of the difference between pairs of groups, with their confidence intervals and p-values.

| Macro | It makes |
|---|---|
| [%lsmeans](lsmeans.md) | The ANCOVA of the groups: returns the differences of the LS means of pairs of groups in a linear model, with confidence limits and p-values. |
| [%mmrm](mmrm.md) | Returns the differences of the LS means of pairs of groups at one visit from a repeated measures mixed model. |
| [%logistic](logistic.md) | Returns the odds ratios of pairs of groups from a logistic regression, with their Wald confidence limits and p-values. |
| [%risk](risk.md) | Returns the risk difference, relative risk or odds ratio of pairs of groups, with its confidence interval and p-value. |
| [%rateratio](rateratio.md) | Returns the rate ratios of pairs of groups from a Poisson or negative binomial model, with confidence limits and p-values. |

## Time to an event {#time}

Kaplan-Meier estimates, the log-rank test, and hazard ratios.

| Macro | It makes |
|---|---|
| [%km](km.md) | Returns the Kaplan-Meier summary of a time in each group: subjects, events, the median time and its confidence limits. |
| [%logrank](logrank.md) | Returns the p-value of the log-rank test that compares the time to an event between the groups. |
| [%cox](cox.md) | Returns the hazard ratio of pairs of groups from a Cox proportional hazards model, with its confidence limits and p-value. |

## Subgroups {#subgroups}

The test of the treatment-by-subgroup interaction, one model per call.

| Macro | It makes |
|---|---|
| [%interaction_glm](interaction_glm.md) | Returns the p-value of the treatment-by-subgroup interaction in a linear model of a continuous variable. |
| [%interaction_logistic](interaction_logistic.md) | Returns the p-value of the treatment-by-subgroup interaction in a logistic regression of a response. |
| [%interaction_genmod](interaction_genmod.md) | Returns the p-value of the treatment-by-subgroup interaction in a Poisson or negative binomial model of a count. |
| [%interaction_phreg](interaction_phreg.md) | Returns the p-value of the treatment-by-subgroup interaction in a Cox model of a time to an event. |

## Build a table {#table}

Stack the results, make the columns, keep every number, lay out the rows, print.

| Macro | It makes |
|---|---|
| [%stack](stack.md) | Stacks results one under another into one table, a block per result, in the order given. |
| [%columns](columns.md) | Returns the columns of a table: one row per column, with its N and the header that shows the N. |
| [%ard](ard.md) | Writes every number of a table to a CSV file, the numbers file. |
| [%layout](layout.md) | Returns the display data set of a table: one row per printed line and one column per group. |
| [%print](print.md) | Prints a table or a listing with one PROC REPORT into an RTF file and a monospace listing file. |
| [%csv](csv.md) | Writes the records of a listing, or the numbers of a figure, to a CSV file. |

## Tables in one call {#onecall}

A whole standard table in one call: the statistics, the columns, the numbers file and the print.

| Macro | It makes |
|---|---|
| [%table](table.md) | Makes a table from the stacked results in one call: %columns, %ard, %layout and %print, in that order. |
| [%table_summary](table_summary.md) | Makes a summary table of the subjects in one call, such as demographics: one block per variable. |
| [%table_ae](table_ae.md) | Makes a table of the subjects with adverse events by system organ class and preferred term in one call. |
| [%table_visit](table_visit.md) | Makes a table of the descriptive statistics of each variable by group, parameter and visit in one call. |
| [%table_shift](table_shift.md) | Makes a shift table in one call: the subjects in each category at baseline against each category after baseline. |
| [%table_response](table_response.md) | Makes a response table in one call: the responders in each group, and the comparisons of pairs of groups. |
| [%table_model](table_model.md) | Makes a table of a continuous endpoint in one call: descriptive statistics, and the LS means of a model. |
| [%table_tte](table_tte.md) | Makes a time-to-event table in one call: the Kaplan-Meier summary, the log-rank test and the hazard ratios. |

## Figures {#figures}

One call per figure: the macro computes what it draws and keeps those numbers.

| Macro | It makes |
|---|---|
| [%kmplot](kmplot.md) | Draws the Kaplan-Meier curve of each group as PNG and RTF files and returns the numbers drawn. |
| [%forestplot](forestplot.md) | Draws a forest plot of estimates in subgroups as PNG and RTF files and returns the numbers drawn. |
| [%meanplot](meanplot.md) | Draws the mean or median of each group by visit as PNG and RTF files and returns the numbers drawn. |
| [%lineplot](lineplot.md) | Draws lines through given values, one line per group, as PNG and RTF files and returns the numbers drawn. |
| [%boxplot](boxplot.md) | Draws box plots of a variable in each group as PNG and RTF files and returns the numbers drawn. |
| [%barplot](barplot.md) | Draws bars of the percent of each category by group as PNG and RTF files and returns the numbers drawn. |
| [%aeplot](aeplot.md) | Draws the percent and risk difference of each adverse event as PNG and RTF files and returns the numbers drawn. |
| [%profileplot](profileplot.md) | Draws one line per subject through its values by visit as PNG and RTF files and returns the numbers drawn. |
| [%scatterplot](scatterplot.md) | Draws the values of two variables against each other as PNG and RTF files and returns the numbers drawn. |

## ADaM steps {#adam}

The steps of an ADaM program that read other records: baselines, flags, windows, last observation carried forward.

| Macro | It makes |
|---|---|
| [%merge_subject](merge_subject.md) | Copies variables from a data set with one row per subject to every row of that subject, matched by USUBJID. |
| [%pick](pick.md) | Gives each subject the value of its first or last record in another data set, as a new variable. |
| [%summarize](summarize.md) | Gives each subject the sum, mean, largest or smallest value of a variable over its records in another data set. |
| [%summarize_groups](summarize_groups.md) | Returns one record per group with the sum, mean, largest or smallest value of each variable over the group. |
| [%baseline](baseline.md) | Gives every record of a group the value of the group's baseline record, as a new variable such as BASE. |
| [%flag_first](flag_first.md) | Flags the first or last record of each group, among the records that meet a condition, with Y. |
| [%flag_if_any](flag_if_any.md) | Flags with Y every row of each subject that has a record in another data set that meets a condition. |
| [%windows](windows.md) | Puts each record into its analysis window by its study day, and gives it AVISIT, AVISITN and the window variables. |
| [%visits](visits.md) | Gives each record its analysis visit, AVISIT and AVISITN, from the value of its variable VISIT. |
| [%locf](locf.md) | Adds last-observation-carried-forward records (DTYPE = 'LOCF') to the analysis windows in which a group has no analysed record. |
| [%relchange](relchange.md) | Returns new records with the change from the record before, relative to the normal range, flagged in ANRIND. |
| [%param_wide](param_wide.md) | Returns the values of several parameters side by side: one record per group, with the variables of each parameter. |
| [%pool](pool.md) | Pools small groups, such as sites, into one group: a new variable that is the group, or the pooled value. |
| [%tte](tte.md) | Returns one time-to-event parameter: for each subject the date of the first event, or else of the latest censoring. |

## Messages every macro shares

Every macro checks its parameters before it runs. A wrong call writes two lines to the log and stops; no procedure runs. These checks are the same in every macro:

| Message | Fix |
|---|---|
| &lt;parameter&gt;= is required | give &lt;parameter&gt;=&lt;value&gt; (see &lt;macro&gt;.sas). |
| &lt;parameter&gt;=&lt;data set&gt; does not exist | give &lt;parameter&gt;= a data set that exists (make it first). |
| &lt;parameter&gt;=&lt;value&gt; is not a variable of &lt;data set&gt; | give &lt;parameter&gt;= a variable of &lt;data parameter&gt;=. Where the macro has a second data parameter: give &lt;parameter&gt;= a variable of &lt;data parameter&gt;= or &lt;other data parameter&gt;=. |
| &lt;parameter&gt;=&lt;value&gt; is not one of: &lt;the values it accepts&gt; | give &lt;parameter&gt;= one of them. |
