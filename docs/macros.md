# The SAS macros: the reference manual

Made by `node tools/sas_macros_doc.ts` from the headers of `sas/macros/` (the macro library 1.9.1); do not edit it. How a macro is
written: [sas-style.md](sas-style.md); what the library computes and how a program reads: [sas.md](sas.md). The same as data for an
agent: `sas/macros/index.json` (and `sapling find <macro>`, the MCP tool `sapling_sas_macros`).

Every macro a person calls checks its parameters first and stops with one line that names the parameter and the fix
(`ERROR: [describe] var=AGEX is not a variable of adsl: give var= a variable of data=`), writes a begin and an end line
in the log (`%LET spl_quiet = yes;` keeps them out), and keeps its work data sets with `debug=yes`.

## The global macro variables

| Variable | It is |
|---|---|
| `SPL_ROOT` | the folder of the study on the SAS server (the one line a program sets: %LET spl_root = ...;) |
| `SPL_STUDY` | the study, set by %study |
| `SPL_OUT` | the output folder, set by %study |
| `SPL_PROGRAM` | the name of the program, set by %study |
| `SPL_QUIET` | yes: no begin and end lines of the macros in the log (%LET spl_quiet = yes; before the calls) |

## Setting up a program

| Macro | It does |
|---|---|
| [`%import_xpt`](#importxpt) | Read SAS transport files (XPORT version 5) into SAS data sets (PROC COPY) |
| [`%study`](#study) | Start a program: the ADaM library, the output folder, the options |

## The statistics macros (one block of a table each)

| Macro | It does |
|---|---|
| [`%adjust`](#adjust) | The adjusted p-values of a family of pairs of groups (PROC MULTTEST) |
| [`%ancova`](#ancova) | The Type III test of a term in a linear model (PROC GLM) |
| [`%anova`](#anova) | The F test of a one-way analysis of variance (PROC GLM) |
| [`%ard`](#ard) | Every number of a table as a CSV file, with every digit (DATA steps) |
| [`%chisq`](#chisq) | The Pearson chi-square test of groups against categories (PROC FREQ) |
| [`%cmh`](#cmh) | The Cochran-Mantel-Haenszel test of groups against categories in strata (PROC FREQ) |
| [`%columns`](#columns) | The columns of a table and the N of each (PROC SUMMARY) |
| [`%cox`](#cox) | The hazard ratio of pairs of groups from a Cox model (PROC PHREG) |
| [`%csv`](#csv) | The records of a listing as a CSV file (DATA steps) |
| [`%describe`](#describe) | Descriptive statistics of a variable in each group (PROC MEANS) |
| [`%fisher`](#fisher) | Fisher exact test of subjects with a record against those without (PROC FREQ) |
| [`%freq`](#freq) | Frequencies of subjects in each group and category (PROC FREQ) |
| [`%interaction_genmod`](#interactiongenmod) | The likelihood-ratio test of the treatment-by-factor interaction, counts (PROC GENMOD) |
| [`%interaction_glm`](#interactionglm) | The F test of the treatment-by-factor interaction in a linear model (PROC GLM) |
| [`%interaction_logistic`](#interactionlogistic) | The likelihood-ratio test of the treatment-by-factor interaction (PROC LOGISTIC) |
| [`%interaction_phreg`](#interactionphreg) | The likelihood-ratio test of the treatment-by-factor interaction (PROC PHREG) |
| [`%km`](#km) | The Kaplan-Meier summary of a time in each group (PROC LIFETEST) |
| [`%layout`](#layout) | The display data set of a table: its rows and a column per group (DATA steps) |
| [`%logistic`](#logistic) | The odds ratio of pairs of groups from a logistic regression (PROC LOGISTIC) |
| [`%logrank`](#logrank) | The log-rank test of a time between groups (PROC LIFETEST) |
| [`%lsmeans`](#lsmeans) | The differences of the LS means of pairs of groups in a linear model (PROC MIXED) |
| [`%mmrm`](#mmrm) | The mixed model for repeated measures: LS means and differences at a visit (PROC MIXED) |
| [`%proportion`](#proportion) | The percent of subjects in each category and group with its interval (PROC FREQ) |
| [`%rate`](#rate) | The exposure-adjusted incidence rate of each group, exact Poisson limits (PROC FREQ) |
| [`%rateratio`](#rateratio) | The rate ratio of pairs of groups, Poisson or negative binomial model (PROC GENMOD) |
| [`%risk`](#risk) | The risk difference, relative risk or odds ratio of pairs of groups (PROC FREQ) |
| [`%table`](#table) | A table in one call: %columns, %ard, %layout and %print |
| [`%table_ae`](#tableae) | An adverse event table in one call: subjects by the levels of var= |
| [`%table_model`](#tablemodel) | A model table in one call: descriptive blocks, then ANCOVA or MMRM |
| [`%table_response`](#tableresponse) | A responder table in one call: percent with interval, comparison, adjusted odds ratio |
| [`%table_shift`](#tableshift) | A shift table in one call: the category at baseline against the category after it |
| [`%table_summary`](#tablesummary) | A summary table in one call: the variables, # after a categorical one |
| [`%table_tte`](#tablette) | A time-to-event table in one call: Kaplan-Meier, the log-rank test, the hazard ratio |
| [`%table_visit`](#tablevisit) | A table by visit in one call: each variable of vars= by parameter and visit |
| [`%termflags`](#termflags) | The flag Y or N of each term for every subject of the population (PROC SORT, MERGE) |
| [`%ttest`](#ttest) | The two-sample t-test of each pair of groups (PROC TTEST) |
| [`%wilcoxon`](#wilcoxon) | The Wilcoxon rank-sum test and Hodges-Lehmann shift of pairs (PROC NPAR1WAY) |
| [`%worst`](#worst) | The records of each subject at its worst level (PROC SORT, a DATA step) |

## Tables and listings

| Macro | It does |
|---|---|
| [`%print`](#print) | Print a table or a listing into RTF and a monospace listing (PROC REPORT) |
| [`%stack`](#stack) | Put results one under another: the blocks of a table (a DATA step) |

## Figures (one macro per figure: docs/sas.md "Figures")

| Macro | It does |
|---|---|
| [`%aeplot`](#aeplot) | Adverse events: percent by group and risk difference (PROC SUMMARY, PROC SGPANEL) |
| [`%barplot`](#barplot) | Bars of the categories of a variable in each group (PROC FREQ, PROC SGPANEL) |
| [`%boxplot`](#boxplot) | Box plots by group and visit (PROC MEANS, PROC SGPANEL) |
| [`%forestplot`](#forestplot) | Forest plot of results in the levels of subgroups (PROC SGPLOT) |
| [`%kmplot`](#kmplot) | Kaplan-Meier curves with the number at risk (PROC LIFETEST, PROC SGPANEL) |
| [`%lineplot`](#lineplot) | Lines through values given, with their interval (PROC SGPANEL) |
| [`%meanplot`](#meanplot) | Mean or median by visit with error bars (PROC MEANS, PROC SGPANEL) |
| [`%profileplot`](#profileplot) | One line per subject by visit, coloured by group (PROC MEANS, PROC SGPANEL) |
| [`%scatterplot`](#scatterplot) | Two variables against each other by group (PROC REG, PROC SGPANEL) |

## The steps of an ADaM program

| Macro | It does |
|---|---|
| [`%baseline`](#baseline) | Give every record of a group the value of its baseline record (PROC SORT, MERGE) |
| [`%flag_first`](#flagfirst) | Flag the first or last record of each group that meets a condition (PROC SORT, MERGE) |
| [`%flag_if_any`](#flagifany) | Flag the subjects with a record in another data set that meets a condition (PROC SORT) |
| [`%locf`](#locf) | Last observation carried forward into the analysis windows, as new records (PROC SORT) |
| [`%merge_subject`](#mergesubject) | Copy variables from another data set by subject (PROC SORT, MERGE) |
| [`%param_wide`](#paramwide) | The values of several parameters side by side, one record per group (PROC SORT, MERGE) |
| [`%pick`](#pick) | The value of the first or last record of each subject in another data set (PROC SORT) |
| [`%pool`](#pool) | Pool small groups into one pooled group (PROC FREQ, PROC SUMMARY, MERGE) |
| [`%relchange`](#relchange) | New records of the change from the record before, relative to the normal range (LAG) |
| [`%summarize`](#summarize) | The sum or mean of the records of each subject in another data set (PROC SUMMARY) |
| [`%summarize_groups`](#summarizegroups) | One record per group with the sum, mean, largest or smallest value (PROC SUMMARY) |
| [`%tte`](#tte) | One time-to-event parameter: the first event, else the latest censoring (PROC SORT) |
| [`%visits`](#visits) | Give each record its analysis visit by its visit (a DATA step) |
| [`%windows`](#windows) | Put each record in its analysis window by its study day (a DATA step) |

## The inner parts (a person does not call them)

| Macro | It does |
|---|---|
| [`%_spl_arg`](#splarg) | One parameter of a call in the long program of a one-call table (DATA step statements) |
| [`%_spl_begin`](#splbegin) | The begin line of a macro in the log |
| [`%_spl_call`](#splcall) | One call of a macro in the long program of a one-call table (DATA step statements) |
| [`%_spl_chars`](#splchars) | The character variables among some variables of a data set |
| [`%_spl_csv`](#splcsv) | Write a data set as a CSV file (DATA steps) |
| [`%_spl_empty`](#splempty) | The result shape without a row: no data qualified |
| [`%_spl_end`](#splend) | The end line of a macro in the log |
| [`%_spl_figure_attrs`](#splfigureattrs) | The colours, markers and line patterns of the groups of a figure |
| [`%_spl_figure_close`](#splfigureclose) | Close the destinations of a figure and set back what it changed |
| [`%_spl_figure_dodge`](#splfiguredodge) | Move the groups of a figure a little apart on the x axis |
| [`%_spl_figure_label`](#splfigurelabel) | The label of an axis, in quotes |
| [`%_spl_figure_nodata`](#splfigurenodata) | The figure and the result when no record qualified |
| [`%_spl_figure_open`](#splfigureopen) | Open the PNG and RTF destinations of a figure |
| [`%_spl_figure_outpar`](#splfigureoutpar) | Write the drawing parameters of a figure macro as a data set |
| [`%_spl_figure_par`](#splfigurepar) | Read par= and the defaults of a figure macro, and check plot= |
| [`%_spl_folder`](#splfolder) | Make the folder of a file and the folders above it that are missing |
| [`%_spl_levels`](#spllevels) | The planned categories of some variables as rows (DATA step statements) |
| [`%_spl_need`](#splneed) | Check the parameters a macro needs |
| [`%_spl_nobs`](#splnobs) | The number of rows of a data set |
| [`%_spl_oneof`](#sploneof) | Check that a parameter is one of a list |
| [`%_spl_pairlist`](#splpairlist) | The pairs of groups of a parameter as rows _K _A _B (DATA step statements) |
| [`%_spl_pairs`](#splpairs) | The differences of the pairs of groups asked for, from the table Diffs of a procedure |
| [`%_spl_program`](#splprogram) | The fixed parts of the long program of a one-call table (DATA step statements) |
| [`%_spl_quote`](#splquote) | The value of a parameter as a text in single quotes (DATA step code) |
| [`%_spl_rows`](#splrows) | The result shape: one row per statistic (DATA step statements) |
| [`%_spl_stackpairs`](#splstackpairs) | The records of each pair of groups asked for, one under the other |
| [`%_spl_text`](#spltext) | The text of a number by its pattern (DATA step statements) |
| [`%_spl_total`](#spltotal) | The name of the group of all groups together, from total= |
| [`%_spl_vars`](#splvars) | Check that variables are in a data set |
| [`%_spl_windows`](#splwindows) | The rows of windows= or visits= of a call as a data set |

### %_spl_arg

<a id="splarg"></a>

One parameter of a call that a one-call table writes into its long program: its name and its value. A parameter without a value is left out.

**File:** `sas/macros/_spl_arg.sas` (16NOV2026)

| Parameter | Default | It is |
|---|---|---|
| `_name` | **required** | The name of the parameter in the call; without _value also the parameter of the calling macro whose value is written |
| `_value` |  | A DATA step expression with the value (a text) |

```sas
%_spl_arg(data, "&rec.")
%_spl_arg(where)
```

**Output:** CODE: DATA step statements that add the parameter to the arrays PN and PV of %_spl_program(begin).

### %_spl_begin

<a id="splbegin"></a>

The begin line of a macro in the log, with the version of the macro library; it gives the time it began, for the end line (%_spl_end). The version below is the one place of the version of the library: every header says the same.

**File:** `sas/macros/_spl_begin.sas` (16NOV2026)

| Parameter | Default | It is |
|---|---|---|
| `_macro` | **required** | The name of the calling macro |

```sas
%_spl_begin(describe)
```

**Output:** TEXT: the text of the time it began (seconds); the line NOTE: [describe] begins (Sapling macro library 1.1.0). in the log, unless SPL_QUIET is yes (a global macro variable: %LET spl_quiet = yes; before the calls keeps the log short).

### %_spl_call

<a id="splcall"></a>

One call of a macro in the long program of a one-call table: the parameters given by %_spl_arg since the last call, one per line, the equal signs under each other.

**File:** `sas/macros/_spl_call.sas` (16NOV2026)

| Parameter | Default | It is |
|---|---|---|
| `_macro` | **required** | The name of the macro called, without the percent sign |

```sas
%_spl_call(freq)
```

**Output:** CODE: DATA step statements that write the call to the file of the long program and start the next list of parameters.

### %_spl_chars

<a id="splchars"></a>

The character variables among some variables of a data set (their names, separated by blanks). The statistics macros give them one length ($200) in their results, so that results stack without a cut value.

**File:** `sas/macros/_spl_chars.sas` (16NOV2026)

| Parameter | Default | It is |
|---|---|---|
| `data` | **required** | The data set (data set options after it are ignored) |
| `vars` | **required** | The variables |

```sas
%_spl_chars(adae, TRT01A AEBODSYS AEDECOD AVISITN)
```

**Output:** TEXT: the names of the character variables among VARS, separated by blanks (a variable not in DATA is left out).

### %_spl_csv

<a id="splcsv"></a>

Write a data set as a CSV file: a line with the names of the variables, then one line per row (a DATA step; values with a comma or a quote are quoted).

**File:** `sas/macros/_spl_csv.sas` (16NOV2026)

| Parameter | Default | It is |
|---|---|---|
| `data` | **required** | The data set (data set options such as KEEP= are allowed) |
| `file` | **required** | The CSV file to write |

```sas
%_spl_csv(data=l14_3_1(KEEP=usubjid aedecod), file=&spl_out./listings/l14_3_1.csv)
```

**Output:** FILE:  a line with the names of the variables, then one line per row.

### %_spl_empty

<a id="splempty"></a>

The result of a statistics macro when no record qualifies: the result shape without a row, and a NOTE that says so. A procedure never runs on no record, so the log has no error of one.

**File:** `sas/macros/_spl_empty.sas` (16NOV2026)

| Parameter | Default | It is |
|---|---|---|
| `keep` |  | The group variables of the result (BY, WITHIN) |
| `macro` | **required** | The name of the calling macro |
| `like` | **required** | The records (without a row): the types and lengths of the group variables |
| `add` |  | Character group variables the records do not have (VERSUS) |
| `out` | **required** | The result to write |

```sas
%_spl_empty(macro=cox, out=&out., like=_cox_records, keep=&by. &within., add=versus)
```

**Output:** OUT: KEEP, ADD, GROUPS, BLOCK, STAT, VALUE and TEXT and no row; the line NOTE: [macro] No data qualified ... in the log.

### %_spl_end

<a id="splend"></a>

The end line of a macro in the log: its run time since its begin line (%_spl_begin), and with debug=yes that its work data sets are kept.

**File:** `sas/macros/_spl_end.sas` (16NOV2026)

| Parameter | Default | It is |
|---|---|---|
| `_macro` | **required** | The name of the calling macro |
| `_start` | **required** | The time it began (%_spl_begin) |
| `_debug` |  | The debug= of the calling macro |

```sas
%_spl_end(describe, &t0., &debug.)
```

**Output:** LOG: NOTE: [describe] ends after 0.42 seconds. in the log, unless SPL_QUIET is yes; with debug=yes always the line that names the kept work data sets.

### %_spl_figure_attrs

<a id="splfigureattrs"></a>

The look of the groups of a figure: an attribute map (DATTRMAP=) that gives each value of the group variable a colour, a marker and a line pattern, in the order of the columns of %columns (columns=; a value not in it after them), else in the order the values come in the data. Eight colours safe for colour blindness (Okabe and Ito, without the yellow, and a grey), each with another marker and line pattern, so that groups differ in black and white too; a ninth group starts the list again. ID grp has all attributes; ID grpcol the colours only, solid lines (an error bar; a marker of its own, such as the censoring mark: give it to a copy of the group variable, as SGPLOT takes one ID per variable). The data get _ORDER, the place of their group.

**File:** `sas/macros/_spl_figure_attrs.sas` (16NOV2026)

| Parameter | Default | It is |
|---|---|---|
| `data` | **required** | The rows of the figure: they get _ORDER |
| `columns` |  | The columns of %columns (COL, COLVALUE) |
| `var` | **required** | The group variable |
| `out` | **required** | The attribute map |

```sas
%_spl_figure_attrs(data=_kmplot_plot, columns=&columns., var=&by., out=_kmplot_attrs)
```

**Output:** OUT: the attribute map: ID, VALUE, _ORDER and the attributes; DATA: data= with _ORDER.

### %_spl_figure_close

<a id="splfigureclose"></a>

Close the destinations of a figure (%_spl_figure_open) and set back what it changed: the RTF file closed, LISTING closed and opened again (its style LISTING) when it was open before, the options of ODS GRAPHICS reset.

**File:** `sas/macros/_spl_figure_close.sas` (16NOV2026)

| Parameter | Default | It is |
|---|---|---|
| `listing` | `no` | yes: LISTING was open before the figure |

```sas
%_spl_figure_close(listing=&listing.)
```

**Output:** CODE: the ODS statements that close the destinations.

### %_spl_figure_dodge

<a id="splfiguredodge"></a>

Move the groups a little apart on a numeric x axis, so that their error bars do not overlap: _XPLOT = x + (_ORDER - (G + 1) / 2) * STEP, G the number of groups, STEP the smaller of half the smallest distance of two x values divided by G - 1 and 3% of the range of x. The x of the data stays as it is. With offset= the room the axis needs at each end, so that the outer groups are not cut at the edge of the plot.

**File:** `sas/macros/_spl_figure_dodge.sas` (16NOV2026)

| Parameter | Default | It is |
|---|---|---|
| `data` | **required** | The rows of the figure, with _ORDER (%_spl_figure_attrs) |
| `x` | **required** | The numeric x variable |
| `offset` |  | A macro variable of the caller: it gets the offset of each end of the axis (OFFSETMIN=, OFFSETMAX= of COLAXIS), a fraction of its length |

```sas
%_spl_figure_dodge(data=_meanplot_plot, x=x, offset=xoff)
```

**Output:** DATA: data= with _XPLOT; with offset= that macro variable.

### %_spl_figure_label

<a id="splfigurelabel"></a>

The label of an axis, as a text in quotes: the text given (in quotes, or put in quotes), else the label of the variable, else its name.

**File:** `sas/macros/_spl_figure_label.sas` (16NOV2026)

| Parameter | Default | It is |
|---|---|---|
| `_data` | **required** | The data set |
| `_var` |  | The variable of the axis |
| `_text` |  | The text given, or nothing |

```sas
%_spl_figure_label(&data., &time., %SUPERQ(xlabel))
```

**Output:** TEXT: the label in double quotes.

### %_spl_figure_nodata

<a id="splfigurenodata"></a>

No record qualified for a figure: out= in the shape of the figure with no row, the NOTE No data qualified, and the figure that says so (a blank plot with the text, in the PNG and the RTF of file=, under the titles of the program).

**File:** `sas/macros/_spl_figure_nodata.sas` (16NOV2026)

| Parameter | Default | It is |
|---|---|---|
| `keep` |  | The variables of like= kept in out= |
| `macro` | **required** | The name of the calling macro |
| `like` | **required** | The records, without a row |
| `chars` |  | Character variables of out= ($200) |
| `nums` |  | Numeric variables of out= |
| `file` | **required** | The output without its extension |
| `width` | **required** | The width of the figure |
| `height` | **required** | The height of the figure |
| `out` |  | The result to write (none: no data set) |

```sas
%_spl_figure_nodata(
    keep   = &by.
  , macro  = kmplot
  , like   = _kmplot_records
  , chars  = kind
  , nums   = x y n censored
  , file   = &file.
  , width  = &width.
  , height = &height.
  , out    = &out.
)
```

**Output:** OUT: no row; FILE: <file>.png and <file>.rtf with the text.

### %_spl_figure_open

<a id="splfigureopen"></a>

Open the destinations of one figure: the PNG image (the LISTING destination with GPATH=, 300 dpi, image name and size from ODS GRAPHICS) and the RTF file with the figure on a page (the titles and footnotes of the program as text of the page: NOGTITLE NOGFOOTNOTE). The PNG carries the titles and the footnotes in the image (LISTING draws them in the graph, as SAS does by default), so a PNG alone says what it is. Both use the style HTMLBLUE: tick values 9pt, axis labels and legend 10pt, titles 11pt. It notes in the macro variable named by state= whether LISTING was open, for %_spl_figure_close.

**File:** `sas/macros/_spl_figure_open.sas` (16NOV2026)

| Parameter | Default | It is |
|---|---|---|
| `file` | **required** | The output without its extension: <file>.png and <file>.rtf |
| `width` | **required** | The width of the figure |
| `height` | **required** | The height of the figure |
| `state` | **required** | The name of a local macro variable of the caller: yes when LISTING was open, else no |

```sas
%_spl_figure_open(file=&file., width=&width., height=&height., state=LISTING)
```

**Output:** CODE: the ODS statements that open the destinations.

### %_spl_figure_outpar

<a id="splfigureoutpar"></a>

The drawing parameters of a figure macro as a data set (its outpar=): one row per parameter in the order of the signature, PARAMETER its name in lower case and VALUE its value as the macro draws it (given, from par=, the default, or made by the macro: the label of an axis, the format of the ticks). par= of a later call reads it back.

**File:** `sas/macros/_spl_figure_outpar.sas` (16NOV2026)

| Parameter | Default | It is |
|---|---|---|
| `names` | **required** | The drawing parameters of the caller, in their order (names= of %_spl_figure_par) |
| `out` |  | The data set to write; blank: none |

```sas
%_spl_figure_outpar(names=&drawn., out=&outpar.)
```

**Output:** DATA: out= with PARAMETER ($32) and VALUE ($500).

### %_spl_figure_par

<a id="splfigurepar"></a>

The parameters of a figure macro, before its checks. With plot= (draw the out= of a call again): data= is not given, plot= has the variables of out=, and each parameter of the computation that has a value gets a NOTE (it is not used). With par= (the outpar= of a call): each drawing parameter that the call leaves blank gets the VALUE of its row; a row that names no drawing parameter is an error. Then each parameter still blank gets its default from draw= or compute=. So a value in the call wins over a row of par=, and a row of par= over the default: the defaults of these parameters are here, not in the signature of the macro.

**File:** `sas/macros/_spl_figure_par.sas` (16NOV2026)

| Parameter | Default | It is |
|---|---|---|
| `macro` | **required** | The name of the calling macro |
| `draw` | **required** | Its drawing parameters in the order of its signature, each as name or name=default |
| `compute` |  | Its parameters of the computation that plot= does not use, each as name or name=default |
| `shape` | **required** | The variables of its out= that plot= must have |
| `names` | **required** | The name of a local macro variable of the caller: the names of the drawing parameters |
| `state` | **required** | The name of a local macro variable of the caller: 1 when the parameters are right, else 0 |

```sas
%_spl_figure_par(
    macro   = kmplot
  , draw    = columns by panel atrisk=yes xlabel ylabel="Survival (%)" file
  , compute = where time cnsr=CNSR
  , shape   = kind x y lower upper n censored
  , names   = drawn
  , state   = ok
)
```

**Output:** LOG: one ERROR with its fix for a wrong plot= or par=, a NOTE for each parameter not used. The local macro variables of the caller: the parameters set from par= and from the defaults, state= and names=.

### %_spl_folder

<a id="splfolder"></a>

Make the folder of a file the macro writes, and each folder above it that is missing, with a NOTE that names the folder made. A path that starts with ~ is in the home folder. Nothing is made when the folder is there or the file has no folder.

**File:** `sas/macros/_spl_folder.sas` (16NOV2026)

| Parameter | Default | It is |
|---|---|---|
| `_macro` | **required** | The name of the calling macro |
| `_file` | **required** | The file the macro writes: a path |

```sas
%_spl_folder(print, %SUPERQ(file).rtf)
```

**Output:** LOG: NOTE: [print] made the folder ~/study/out/tlf. for a folder it made; a WARNING when the folder cannot be made.

### %_spl_levels

<a id="spllevels"></a>

The planned categories of some variables as rows: every combination of their values, by DO loops. A character variable gets the length $200.

**File:** `sas/macros/_spl_levels.sas` (16NOV2026)

| Parameter | Default | It is |
|---|---|---|
| `data` | **required** | The data set of the variables (it tells which ones are character) |
| `levels` | **required** | Each variable followed by its values: a text in quotes, a number without |
| `order` |  | A prefix: the place of each value in its list as the variables <prefix>1, <prefix>2 ... (one for each variable, in the order of levels=) |

```sas
%_spl_levels(levels=bnrind 'LOW' 'NORMAL' 'HIGH' anrind 'LOW' 'NORMAL' 'HIGH', data=adlbc)
```

**Output:** CODE: DATA step statements: LENGTH of the character variables ($200), then DO loops that output every combination of the planned values (DO BNRIND = ...; DO ANRIND = ...; OUTPUT; END; END;); with order= also the place of each value in its list.

### %_spl_need

<a id="splneed"></a>

Check the parameters a macro needs: each must have a value, and a data set of data=, denom=, columns= or from= must exist. For each one that does not it writes one line that names the parameter and the fix: ERROR: [describe] data= is required: give data=<value> ... ERROR: [describe] data=adsx does not exist: give data= ... It gives 1 when all are there, 0 when one is not: the caller then stops (%RETURN).

**File:** `sas/macros/_spl_need.sas` (16NOV2026)

| Parameter | Default | It is |
|---|---|---|
| `_macro` | **required** | The name of the calling macro (for the message) |
| `_params` | **required** | The names of its parameters that must have a value |

```sas
%_spl_need(describe, data var by out)
```

**Output:** TEXT: 1 or 0, as text.

### %_spl_nobs

<a id="splnobs"></a>

The number of rows of a data set (with the WHERE= of its data set options, when it has one); 0 when the data set does not exist.

**File:** `sas/macros/_spl_nobs.sas` (16NOV2026)

| Parameter | Default | It is |
|---|---|---|
| `_data` | **required** | The data set |

```sas
%_spl_nobs(_describe_values)
```

**Output:** TEXT: the number, as text.

### %_spl_oneof

<a id="sploneof"></a>

Check that the value of a parameter is one of a list (in any case). When it is not it writes one line that names the parameter and the fix: ERROR: [cox] ties=fast is not one of efron breslow exact ... It gives 1 or 0: the caller then stops (%RETURN).

**File:** `sas/macros/_spl_oneof.sas` (16NOV2026)

| Parameter | Default | It is |
|---|---|---|
| `_macro` | **required** | The name of the calling macro (for the message) |
| `_param` | **required** | The parameter |
| `_list` | **required** | Its values, separated by blanks |

```sas
%_spl_oneof(cox, ties, efron breslow exact discrete)
```

**Output:** TEXT: 1 or 0, as text.

### %_spl_pairlist

<a id="splpairlist"></a>

The pairs of groups of a parameter as rows: _K (the place of the pair), _A (the group) and _B (the group it is compared with). The pairs are separated by #, one pair per line, the first group against the second; a value with a blank or a hyphen is in quotes: pairs = "Xanomeline High Dose" "Placebo" # "Xanomeline Low Dose"  "Placebo" The form of version 1.0 is still read: "A"-"B" "C"-"D" (no #, every item a pair joined by a hyphen outside quotes).

**File:** `sas/macros/_spl_pairlist.sas` (16NOV2026)

| Parameter | Default | It is |
|---|---|---|
| `list` | **required** | The parameter of the calling macro that holds the pairs (pairs, family) |

```sas
%_spl_pairlist(list=pairs)
```

**Output:** CODE: DATA step statements: one row (OUTPUT) per pair with _K, _A and _B ($200).

### %_spl_pairs

<a id="splpairs"></a>

The differences of the pairs of groups asked for, from the table Diffs of PROC MIXED (it has each pair once, in one direction). It computes nothing: a difference the other way round is the same difference with its sign and its limits turned.

**File:** `sas/macros/_spl_pairs.sas` (16NOV2026)

| Parameter | Default | It is |
|---|---|---|
| `by` | **required** | The groups: a character variable |
| `within` |  | The variables of the separate models (BY groups of PROC MIXED) |
| `diffs` | **required** | The Diffs table (the group in BY, the group it is compared with in _BY) |
| `records` | **required** | The records of the model (for the groups and their order) |
| `pairs` | **required** | all: each later group against each earlier one, in the order of ORDER (else of the values); or the pairs separated by #, the group first, then the group it is compared with (%_spl_pairlist reads them, and the form "A"-"B" of 1.0) |
| `order` |  | A numeric variable of the records with one value per group |
| `out` | **required** | The data set: WITHIN, BY (the group), VERSUS (the group it is compared with), diff, diff_se, lcl, ucl, pval |

```sas
%_spl_pairs(
    by      = trt01p
  , within  =
  , diffs   = _lsmeans_diffs
  , records = _lsmeans_records
  , pairs   = all
  , order   = trt01pn
  , out     = _lsmeans_pairs
)
```

**Output:** OUT: WITHIN, BY (the group), VERSUS (the group it is compared with), diff, diff_se, lcl, ucl, pval: one row per pair asked for (in each group of WITHIN).

### %_spl_program

<a id="splprogram"></a>

The fixed parts of the DATA step with which a one-call table writes its long program: begin (the file and the variables), records (the population and the records, from the parameters ADSL, POP, DATA, WHERE and NAME of the calling macro), table (the %table call, from BY, ORDER, TOTAL, FORMAT, FILE, NAME and DEBUG, with the TITLE and FOOTNOTE statements of TITLE and FOOTNOTE before it and their clearing after it), titles and untitled (those statements alone), end (the routine that writes a call). It computes nothing.

**File:** `sas/macros/_spl_program.sas` (16NOV2026)

| Parameter | Default | It is |
|---|---|---|
| `_part` | **required** | begin, names, label, records, table, titles, untitled or end |
| `_var` |  | With label: the variable of the block, in lower case |

```sas
%_spl_program(begin)
%_spl_program(records)
%_spl_program(table)
%_spl_program(end)
```

**Output:** CODE: DATA step statements. It reads the macro variables REC (the records the calls read), POPN (the data set with the N of the columns), DS and NAMES of the calling macro.

### %_spl_quote

<a id="splquote"></a>

The value of a parameter as a text in single quotes, for a DATA step: each single quote in it doubled, nothing in it resolved. The code the macro writes holds the value itself (SYMGET would read it when the step runs), so that the flat program of sapling sas run --flat (the code without a macro) has it too. An empty value gives a blank text.

**File:** `sas/macros/_spl_quote.sas` (16NOV2026)

| Parameter | Default | It is |
|---|---|---|
| `_param` | **required** | The name of the parameter (label, pairs) |

```sas
%_spl_quote(label)
```

**Output:** TEXT: a text in single quotes: 'Age (years)', '"A" "B" # "C" "B"'.

### %_spl_rows

<a id="splrows"></a>

The result shape: one row per statistic of the row just read. Each statistic is a numeric variable of the same name (n, mean, pval ...); the row gets STAT (its name), VALUE (its number), PATTERN and TEXT (the number as printed, %_spl_text: a p value, pval or padj, never as 0 or 1).

**File:** `sas/macros/_spl_rows.sas` (16NOV2026)

| Parameter | Default | It is |
|---|---|---|
| `missing` |  | The text of a statistic without a value (default blank; %km gives NE: not estimable) |
| `stats` | **required** | The statistics in their order, each with its pattern (mean="XX.X") or without (the default pattern of the statistic below) |

```sas
%_spl_rows(stats=n="XX" mean="XX.X" sd)
```

**Output:** CODE: DATA step statements: one row per statistic with STAT, VALUE and TEXT. The default patterns: XX for n, events, min, max; XX.X for mean, median, q1, q3, lsmean, diff, estimate, lcl, ucl; (XX.X%) for pct; X.XXX for pval; XX.XX for sd, se, lsmean_se, diff_se and any other statistic.

### %_spl_stackpairs

<a id="splstackpairs"></a>

The records of each pair of groups asked for, one under the other: the pair (_PAIR), its group (_A) and the group it is compared with (_B), and the side of each record (_SIDE: 1 in _A, 2 in _B). A procedure then runs BY _PAIR _A _B on the 2 groups of each pair, the group first. It computes nothing.

**File:** `sas/macros/_spl_stackpairs.sas` (16NOV2026)

| Parameter | Default | It is |
|---|---|---|
| `by` | **required** | The groups: a character variable |
| `records` | **required** | The records (one per subject) |
| `pairs` | **required** | all: each later group against each earlier one, in the order of ORDER (else of the values); or the pairs separated by #, the group first, then the group it is compared with (%_spl_pairlist reads them, and the form "A"-"B" of 1.0) |
| `order` |  | A numeric variable of the records with one value per group |
| `macro` | **required** | The macro that calls (for the message) |
| `out` | **required** | The data set: the records of each pair with _PAIR, _A, _B, _SIDE, sorted by them |

```sas
%_spl_stackpairs(
    macro   = ttest
  , records = _ttest_records
  , by      = trt01p
  , pairs   = all
  , order   = trt01pn
  , out     = _ttest_pairs
)
```

**Output:** OUT: the records of each pair with _PAIR, _A, _B and _SIDE (1 in _A, 2 in _B), sorted by them. The macro variable PAIRSOK of the caller: 1, or 0 when a pair names a group that no record has (an error in the log).

### %_spl_text

<a id="spltext"></a>

The text of a number by its pattern. A pattern shows one number as one group of X: XX, XX.X, (XX.X%), (N=XX). The number is rounded (ROUND) to the decimals of the X group, right aligned in its width and put in its place; the text is trimmed. A p value never prints as 0 or 1: rounded to 0 it is < and the smallest step (X.XXX: <0.001), rounded to 1 it is > and one step less (>0.999). The number is unchanged.

**File:** `sas/macros/_spl_text.sas` (16NOV2026)

| Parameter | Default | It is |
|---|---|---|
| `value` | **required** | The numeric variable |
| `pattern` | **required** | The character variable with the pattern |
| `text` | **required** | The character variable to write (blank when the number is missing) |
| `pvalue` | `0` | A condition that is true when the number is a p value (STAT IN ('pval' 'padj')) |

```sas
%_spl_text(
      value   = value
    , pattern = pattern
    , text    = text
    , pvalue  = stat IN ('pval' 'padj')
  )
```

**Output:** CODE: DATA step statements: TEXT is the number of VALUE as its PATTERN shows it (9.46 with (XX.X%) gives ( 9.5%); 86 with (N=XX) gives (N=86); 3 with XX gives 3; a p value 0.00004 with X.XXX gives <0.001).

### %_spl_total

<a id="spltotal"></a>

The name of the group of all groups together, from total=: nothing for no, Total for yes, else the text in quotes.

**File:** `sas/macros/_spl_total.sas` (16NOV2026)

| Parameter | Default | It is |
|---|---|---|
| `total` | **required** | The value of total= (no, yes, or a name in quotes) |

```sas
%_spl_total(%SUPERQ(total))
```

**Output:** TEXT: nothing for no (or empty), Total for yes, else the text of the quotes.

### %_spl_vars

<a id="splvars"></a>

Check that the variables of some parameters are variables of a data set. For each one that is not it writes one line that names the parameter and the fix: ERROR: [describe] var=AGEX is not a variable of adsl: give ... It gives 1 when all are there, 0 when one is not: the caller then stops (%RETURN). A data set that cannot be opened is the business of %_spl_need. With _also (the subjects adsl= of a one-call table, whose variables go to the records) a variable of either data set is there.

**File:** `sas/macros/_spl_vars.sas` (16NOV2026)

| Parameter | Default | It is |
|---|---|---|
| `_macro` | **required** | The name of the calling macro (for the message) |
| `_data` | **required** | The parameter that names the data set (data, denom) |
| `_params` | **required** | The parameters whose values are variables of it |
| `_also` |  | The parameter that names a second data set where the variables may be (adsl) |

```sas
%_spl_vars(describe, data, var by)
%_spl_vars(table_ae, data, var by, adsl)
```

**Output:** TEXT: 1 or 0, as text.

### %_spl_windows

<a id="splwindows"></a>

The rows of windows= (or visits=) of a call as a data set: one row per window, the rows of the call separated by #, the values of a row by blanks, a text in quotes, a missing number as a period.

**File:** `sas/macros/_spl_windows.sas` (16NOV2026)

| Parameter | Default | It is |
|---|---|---|
| `_macro` | **required** | The macro that calls |
| `_name` | **required** | The name of its parameter with the rows |
| `_kind` | **required** | day: AVISITN AVISIT AWLO AWHI AWTARGET AWRANGE; visit: VISIT AVISITN AVISIT |
| `_out` | **required** | The data set of the rows |

```sas
%_spl_windows(windows, windows, day, _windows_rows)
```

**Output:** DATA: _out, one row per window in the order of the call. The macro variable ROWSOK of the caller: 1, or 0 when a row has not its number of values (an error in the log).

### %adjust

<a id="adjust"></a>

The adjusted p-values of a family of pairs of groups (the hypotheses of a multiplicity block): the p-values (STAT = pval) of a result of pairs (%lsmeans, %cox, %logistic, %risk, %rateratio, %ttest, %wilcoxon), in the order of family=, adjusted by method= (PROC MULTTEST INPVALUES=: bonferroni, holm (STEPBON), hochberg; a DATA step: bonferroni with weights, hierarchy, the fixed sequence: the largest p-value of a hypothesis and those before it). The result is the input with a row padj for each pair of the family. The family is every p-value of data= of a pair of family=: when data= has a pair in several rows (the terms, visits or subgroups of WITHIN), all of them are adjusted together, as one family (a pair in two terms: two hypotheses). For a family in each term, call %adjust once per term on a data set of the rows of that term (a DATA step with WHERE first).

**Procedure:** PROC MULTTEST (INPVALUES=); a DATA step  
**Proven:** the known answer of the method riskdiff (src/methods.ts, worked out by tools/method_answers.R; node tools/methods_sas.ts) with the adjusted p-values of a family; ran on SAS 9.4 M9, 2026-11-12  
**File:** `sas/macros/adjust.sas` (16NOV2026)

| Parameter | Default | It is |
|---|---|---|
| `data` | **required** | A result of pairs: BY, VERSUS, STAT, VALUE |
| `by` | **required** | The groups: the variable of the group of each pair |
| `family` | **required** | The pairs of the family in their order, separated by #, one pair per line, the group first, then the group it is compared with: "High" "Placebo" # "Low" "Placebo". The form "A"-"B" of version 1.0 is still read. |
| `method` | **required** | bonferroni, holm, hochberg or hierarchy |
| `weights` |  | The weight of each hypothesis of a weighted Bonferroni test, in the order of family=, separated by blanks |
| `pattern` | `"X.XXX"` | The pattern of the adjusted p-value (default "X.XXX") |
| `out` | **required** | The result |
| `debug` | `no` | yes: keep the work data sets of the macro (_adjust_*) |

```sas
%adjust(
    data   = resp_rd
  , by     = trt01p
  , family = "High" "Placebo"
           # "Low"  "Placebo"
  , method = hochberg
  , out    = resp_rd
)
```

**Output:** OUT: the rows of data= and a row padj per pair of the family.

### %aeplot

<a id="aeplot"></a>

The adverse events of the subjects as two panels side by side that share the axis of the terms: at the left the percent of the subjects of each group with the term (dots), at the right the risk difference of each group against the reference group with its interval and a line at 0. The flags are those of %termflags, the risk differences those of %risk (ci=, level=), so that the figure and a table made with them cannot differ. The terms: those of threshold=, sorted by sort=, at most max= of them.

**Procedure:** PROC SUMMARY, PROC SGPANEL (and PROC FREQ in %risk)  
**Proven:** its known answer in tools/figures_sas.ts (percents and Wald intervals worked out by hand); not yet run on a SAS server  
**File:** `sas/macros/aeplot.sas` (16NOV2026)

| Parameter | Default | It is |
|---|---|---|
| `data` | **required** | The adverse event records |
| `plot` |  | Draw again: an out= of %aeplot (not with data=) |
| `par` |  | The drawing parameters: an outpar= of %aeplot |
| `columns` |  | The columns of %columns: the order of the groups and their colours (default: the order of denom=) |
| `denom` | **required** | The population: one row per subject with by= |
| `where` |  | The records to use, a condition in parentheses (TRTEMFL = 'Y') |
| `term` | `AEDECOD` | The term of a row |
| `by` | **required** | The groups: a character variable of denom= |
| `reference` | **required** | The reference group: a value of by=, in quotes |
| `threshold` |  | A percent: only the terms with this percent of the subjects of a group or more, in at least one group |
| `sort` | `difference` | The order of the terms from the top: difference (the risk difference of the first group that is not the reference, largest first), frequency (the percent of all subjects, largest first) or alphabetical |
| `ci` | `wald` | The interval of the risk difference: ci= of %risk |
| `level` | `0.95` | The confidence level |
| `max` | `30` | The most terms shown (the first in sort=) |
| `xlabel` |  | The heading of the right panel (default: Risk difference (%) with 95% CI, the level of level=) |
| `file` | **required** | The output without its extension: <file>.png (300 dpi) and <file>.rtf |
| `width` | `6.5in` | The width of the figure |
| `height` | `4.5in` | The height of the figure |
| `out` |  | The numbers drawn |
| `outpar` |  | The drawing parameters: one row each |
| `debug` | `no` | yes: keep the work data sets _aeplot_* |

```sas
%aeplot(
    data      = adae
  , columns   = t14_5_1_cols
  , denom     = adsl
  , where     = (trtemfl = 'Y')
  , term      = aedecod
  , by        = trta
  , reference = "Placebo"
  , threshold = 5
  , file      = &spl_out./figures/f14_5_3
  , out       = f14_5_3
)
```

**Output:** OUT: TERM and BY, KIND, X, LOWER, UPPER, N. KIND percent: one row per term and group, X the percent of its subjects, N the subjects with the term. KIND difference: one row per term and group that is not the reference, X the risk difference in percent (100 x RD of %risk), LOWER and UPPER its limits in percent. OUTPAR: one row per drawing parameter in the order of the table: PARAMETER ($32) its name, VALUE ($500) its value as drawn (a label in quotes). FILE: <file>.png and <file>.rtf.

### %ancova

<a id="ancova"></a>

A linear model of a variable, one record per subject (PROC GLM): class factors, covariates and the tested term. The Type III test of the tested term (pval); its coefficient, its standard error and confidence limits (estimate, se, lcl, ucl) when stats= asks for them.

**Procedure:** PROC GLM  
**Proven:** the known answer of the method ancova (src/methods.ts, worked out by tools/method_answers.R; node tools/methods_sas.ts); ran on SAS 9.4 M9, 2026-11-12  
**File:** `sas/macros/ancova.sas` (16NOV2026)

| Parameter | Default | It is |
|---|---|---|
| `data` | **required** | The records |
| `where` |  | The records to use, a condition in parentheses |
| `var` | **required** | The response |
| `covars` |  | The covariates, separated by blanks |
| `class` |  | The class factors, separated by blanks |
| `test` | **required** | The tested term: a numeric variable (a dose, a treatment number) |
| `level` | `0.95` | The confidence level of the limits (default 0.95) |
| `stats` | `pval="X.XXX"` | The statistics, each with its pattern (default pval="X.XXX"); also estimate, se, lcl, ucl |
| `label` |  | The label of the block in a table, in quotes |
| `out` | **required** | The result |
| `debug` | `no` | yes: keep the work data sets of the macro (_ancova_*) |

```sas
%ancova(
    data   = advs
  , where  = (paramcd = 'SYSBP' AND avisit = 'Week 12')
  , var    = chg
  , covars = base
  , class  = sitegr1
  , test   = trtpn
  , out    = chg_test
)
```

**Output:** OUT: one row per statistic, of all subjects together (GROUPS is blank).

### %anova

<a id="anova"></a>

The one-way analysis of variance of a variable between groups (PROC GLM): the F test of the model (pval).

**Procedure:** PROC GLM  
**Proven:** the known answer of the method anova (src/methods.ts, worked out by tools/method_answers.R; node tools/methods_sas.ts); ran on SAS 9.4 M9, 2026-11-12  
**File:** `sas/macros/anova.sas` (16NOV2026)

| Parameter | Default | It is |
|---|---|---|
| `data` | **required** | The records |
| `where` |  | The records to use, a condition in parentheses |
| `var` | **required** | The variable |
| `by` | **required** | The groups to compare: one variable |
| `stats` | `pval="X.XXX"` | The statistic and its pattern (default pval="X.XXX") |
| `label` |  | The label of the block in a table, in quotes |
| `out` | **required** | The result |
| `debug` | `no` | yes: keep the work data set of the macro (_anova_overall) |

```sas
%anova(
    data  = adsl
  , var   = age
  , by    = trt01a
  , label = "Age (years)"
  , out   = age_test
)
```

**Output:** OUT: one row, of all groups together (GROUPS is blank).

### %ard

<a id="ard"></a>

Every number of a table as a CSV file, with every digit: one line per number with the result it comes from, its statistic and the values of its groups (in the order of GROUPS), then the number and its text. The N of each column comes first (result N). It reads the results, never the printed page: sapling sas check compares these numbers with those of R.

**Procedure:** DATA steps (FILE, PUT)  
**Proven:** the tables of the dummy study SYNHTN01 (sapling sas check: SAS CHECK PASS, 759 of 759 numbers); ran on SAS 9.4 M9, 2026-11-12  
**File:** `sas/macros/ard.sas` (16NOV2026)

| Parameter | Default | It is |
|---|---|---|
| `data` | **required** | The results (%stack) |
| `columns` |  | The columns (%columns): the N of each column |
| `file` |  | The name of the output, without extension (default: the program that %study set; without %study it is required) |

```sas
%ard(data=t14_2_1, columns=t14_2_1_cols)
```

**Output:** FILE: <out>/ard/<file>.csv: result, stat, g1_value ... g5_value, raw, formatted; the N of each column first (result N), then every number of the results.

### %barplot

<a id="barplot"></a>

Bars of the categories of a variable in each group: the percent of the subjects of the group (denom=: the subjects of the population; a subject counts once in a category) or of its records, or the count; the groups side by side or stacked, the value on each bar. One panel per value of panel=.

**Procedure:** PROC FREQ, PROC SGPANEL  
**Proven:** its known answer in tools/figures_sas.ts (counts and percents worked out by hand); not yet run on a SAS server  
**File:** `sas/macros/barplot.sas` (16NOV2026)

| Parameter | Default | It is |
|---|---|---|
| `data` | **required** | The records |
| `plot` |  | Draw again: an out= of %barplot (not with data=) |
| `par` |  | The drawing parameters: an outpar= of %barplot |
| `columns` |  | The columns of %columns: the order of the groups and their colours (default: the order of the data) |
| `denom` |  | The population: one row per subject (USUBJID) with by=; its subjects of a group are the N of the percent (default: the records of the group) |
| `where` |  | The records to use, a condition in parentheses |
| `var` | **required** | The category |
| `by` | **required** | The groups: one colour each |
| `panel` |  | One panel per value of this variable |
| `stat` | `percent` | percent or count |
| `stacked` | `no` | yes: the groups stacked in one bar |
| `labels` | `yes` | yes: the value on each bar |
| `xlabel` |  | The label of the x axis (default: the label of var=) |
| `ylabel` |  | The label of the y axis (default: Subjects (%), Records (%), Subjects or Records) |
| `ref` |  | Reference lines on the y axis: values |
| `file` | **required** | The output without its extension: <file>.png (300 dpi) and <file>.rtf |
| `width` | `6.5in` | The width of the figure |
| `height` | `4.5in` | The height of the figure |
| `out` |  | The numbers drawn |
| `outpar` |  | The drawing parameters: one row each |
| `debug` | `no` | yes: keep the work data sets _barplot_* |

```sas
%barplot(
    data    = adae
  , columns = t14_5_1_cols
  , denom   = adsl
  , where   = (trtemfl = 'Y')
  , var     = aesev
  , by      = trta
  , file    = &spl_out./figures/f14_5_2
  , out     = f14_5_2
)
```

**Output:** OUT: one row per bar: PANEL and BY, KIND bar, X (the category as printed), Y (the percent or the count), N (the subjects or records of the bar), DENOM (the N of the percent). A category without a record in a group has no bar. OUTPAR: one row per drawing parameter in the order of the table: PARAMETER ($32) its name, VALUE ($500) its value as drawn (a label in quotes). FILE: <file>.png and <file>.rtf.

### %baseline

<a id="baseline"></a>

Give every record of a group the value of the group's baseline record (the one with the baseline flag).

**Procedure:** PROC SORT, MERGE  
**Proven:** the fixtures of the step kind baseline (src/adam_steps.ts; node tools/adam_steps_sas.ts); ran on SAS 9.4 M9, 2026-11-12  
**File:** `sas/macros/baseline.sas` (16NOV2026)

| Parameter | Default | It is |
|---|---|---|
| `data` | **required** | The working data set (changed in place) |
| `value` | **required** | The variable whose baseline value is taken (AVAL) |
| `by` | **required** | The groups (one baseline record in each) |
| `flag` | `ABLFL` | The baseline flag (default ABLFL = 'Y') |
| `replace` | `no` | yes: NEW is in the data already and is made again (default no) |
| `new` | **required** | The variable to make (BASE) |
| `debug` | `no` | yes: keep the work data sets _baseline_* |

```sas
%baseline(
    data  = advs
  , value = aval
  , by    = usubjid paramcd
  , new   = base
)
```

**Output:** DATA: NEW on every record: the VALUE of the baseline record of its group (missing for a group without one); two baseline records in a group are an ERROR that names the group. The rows keep their order.

### %boxplot

<a id="boxplot"></a>

Box plots of a variable in each group (and at each visit of x=): the box from Q1 to Q3 with the median, the whiskers to the most extreme values within 1.5 times the interquartile range of the box, the values beyond as outliers, the mean as a marker. The quantiles are those of PROC MEANS QNTLDEF=5 and of VBOX (its default PERCENTILE=5; R quantile type 2). One panel per value of panel=.

**Procedure:** PROC MEANS, PROC SGPANEL  
**Proven:** its known answer in tools/figures_sas.ts (quartiles and whiskers worked out by hand); not yet run on a SAS server  
**File:** `sas/macros/boxplot.sas` (16NOV2026)

| Parameter | Default | It is |
|---|---|---|
| `data` | **required** | The records |
| `plot` |  | Draw again: an out= of %boxplot (not with data=) |
| `par` |  | The drawing parameters: an outpar= of %boxplot |
| `columns` |  | The columns of %columns: the order of the groups and their colours (default: the order of the data) |
| `where` |  | The records to use, a condition in parentheses |
| `y` | **required** | The variable |
| `x` |  | The category of the x axis (the visit, AVISITN) (default: one box per group) |
| `by` | **required** | The groups: one box each |
| `panel` |  | One panel per value of this variable, one under the other, each with its own y axis |
| `outliers` | `yes` | yes: the values beyond the whiskers as markers |
| `mean` | `yes` | yes: the mean as a marker in the box |
| `xformat` |  | The format of the categories of x (default: the format of x) |
| `xlabel` |  | The label of the x axis (default: the label of x) |
| `ylabel` |  | The label of the y axis (default: the label of y) |
| `ref` |  | Reference lines on the y axis: values |
| `file` | **required** | The output without its extension: <file>.png (300 dpi) and <file>.rtf |
| `width` | `6.5in` | The width of the figure |
| `height` | `4.5in` | The height of the figure |
| `out` |  | The numbers drawn |
| `outpar` |  | The drawing parameters: one row each |
| `debug` | `no` | yes: keep the work data sets _boxplot_* |

```sas
%boxplot(
    data    = advs
  , columns = t14_3_1_cols
  , where   = (paramcd = 'SYSBP' AND anl01fl = 'Y')
  , y       = chg
  , x       = avisitn
  , by      = trta
  , xformat = VISIT.
  , ref     = 0
  , file    = &spl_out./figures/f14_3_1
  , out     = f14_3_1
)
```

**Output:** OUT: one row per box: PANEL, BY, KIND box, X (the category; missing without x=), N, MEAN, MEDIAN, Q1, Q3, MIN, MAX, WLOW and WHIGH (the ends of the whiskers: the smallest and the largest value within Q1 - 1.5 IQR and Q3 + 1.5 IQR). OUTPAR: one row per drawing parameter in the order of the table: PARAMETER ($32) its name, VALUE ($500) its value as drawn (a label in quotes). FILE: <file>.png and <file>.rtf.

### %chisq

<a id="chisq"></a>

The Pearson chi-square test (without continuity correction) of groups against categories, each subject once in each group and category (PROC FREQ): pval. With exact=yes Fisher's exact test of the same table.

**Procedure:** PROC FREQ (CHISQ, FISHER)  
**Proven:** the known answer of the methods chisq, fisher (src/methods.ts, worked out by tools/method_answers.R; node tools/methods_sas.ts); ran on SAS 9.4 M9, 2026-11-12  
**File:** `sas/macros/chisq.sas` (16NOV2026)

| Parameter | Default | It is |
|---|---|---|
| `data` | **required** | The records |
| `where` |  | The records to use, a condition in parentheses |
| `var` | **required** | The categories (the response): one variable |
| `by` | **required** | The groups to compare: one variable |
| `within` |  | One test in each group of these variables (a parameter, a visit) |
| `exact` | `no` | yes: Fisher's exact test (default no) |
| `stats` | `pval="X.XXX"` | The statistic and its pattern (default pval="X.XXX") |
| `label` |  | The label of the block in a table, in quotes |
| `out` | **required** | The result |
| `debug` | `no` | yes: keep the work data sets of the macro (_chisq_*) |

```sas
%chisq(
    data  = adsl
  , var   = sex
  , by    = trt01a
  , label = "Sex"
  , out   = sex_test
)
%chisq(
    data   = adlbc
  , var    = anrind
  , by     = trt01a
  , within = paramcd
  , exact  = yes
  , out    = nr_test
)
```

**Output:** OUT: one row, or one per group of WITHIN (GROUPS: their names). Where PROC FREQ makes no test (a table with one row or one column) the value is missing.

### %cmh

<a id="cmh"></a>

The Cochran-Mantel-Haenszel test of groups against categories in strata (PROC FREQ), each subject once in each group, category and stratum: pval. The test of general association, or (statistic=rowmean) the test that the mean scores of the groups differ, the scores being the values of the numeric response.

**Procedure:** PROC FREQ (CMH)  
**Proven:** the known answer of the method cmh (src/methods.ts, worked out by tools/method_answers.R; node tools/methods_sas.ts); ran on SAS 9.4 M9, 2026-11-12  
**File:** `sas/macros/cmh.sas` (16NOV2026)

| Parameter | Default | It is |
|---|---|---|
| `data` | **required** | The records |
| `where` |  | The records to use, a condition in parentheses |
| `var` | **required** | The categories (the response): one variable |
| `by` | **required** | The groups to compare: one variable |
| `strata` |  | The stratification variables, separated by blanks |
| `within` |  | One test in each group of these variables (a parameter, a visit) |
| `statistic` | `general` | general (default): general association; rowmean: row mean scores differ |
| `stats` | `pval="X.XXX"` | The statistic and its pattern (default pval="X.XXX") |
| `label` |  | The label of the block in a table, in quotes |
| `out` | **required** | The result |
| `debug` | `no` | yes: keep the work data sets of the macro (_cmh_*) |

```sas
%cmh(
    data      = adqscibc
  , var       = aval
  , by        = trt01p
  , strata    = sitegr1
  , within    = avisit
  , statistic = rowmean
  , out       = cibic_test
)
```

**Output:** OUT: one row, or one per group of WITHIN (GROUPS: their names). Where PROC FREQ makes no test the value is missing.

### %columns

<a id="columns"></a>

The columns of a table: each value of the column variable in the results (and in the population), in the order of ORDER (else of the values), the total last; the N of each column from the population (its subjects, the total all of them) and the header of the column with its N: Placebo|(N=86). With page= the columns are the same on each page (each value of the page variable) and the N of a column is the N of its page: Placebo|(N=40) on the page of the males.

**Procedure:** PROC SUMMARY  
**Proven:** the tables of the dummy study SYNHTN01 (sapling sas check: the N of every column the same as R); ran on SAS 9.4 M9, 2026-11-12  
**File:** `sas/macros/columns.sas` (27NOV2026)

| Parameter | Default | It is |
|---|---|---|
| `data` | **required** | The results (%stack) |
| `n` |  | The population, one row per subject (USUBJID): its subjects of each column are the N in the header |
| `var` | **required** | The column variable: the first BY of the statistics macros |
| `order` |  | Its numeric twin in N= (TRT01AN): the order of the columns (default: the order of the values) |
| `page` |  | A variable of the results and of N= (SEX): one page per value; the N of a column is the N of its page |
| `total` | `no` | yes: the results have the group Total (total=yes of the statistics macros): the last column, its N all subjects of N=. A text in quotes is another name. |
| `out` | **required** | The columns |
| `debug` | `no` | yes: keep the work data sets _columns_* |

```sas
%columns(
    data  = t14_2_1
  , n     = adsl
  , var   = trt01a
  , order = trt01an
  , total = yes
  , out   = t14_2_1_cols
)
%columns(
    data  = t14_1_1
  , n     = adsl
  , var   = trt01a
  , order = trt01an
  , page  = sex
  , total = yes
  , out   = t14_1_1_cols
)
```

**Output:** OUT: one row per column: COL (1, 2, ...), COLVALUE (the value), BIGN (the N) and HEADER (the value, a | and (N=86): the split character of %print). With page=: one row per page and column, the page variable first, BIGN the N of the page (0: no subject of the column on the page).

### %cox

<a id="cox"></a>

A Cox proportional hazards model of a time, one record per subject (PROC PHREG): the groups, the covariates and the class factors, stratified by the strata (each combination of their values a stratum with its own baseline hazard). The hazard ratio of pairs of groups from one fit (hr), its Wald confidence limits (lcl, ucl) and the Wald p-value of the pair (pval). With pvalue=logrank the p-value is the log-rank test of the two groups of the pair, stratified by the same strata (PROC LIFETEST); the hazard ratio and its limits stay those of the model.

**Procedure:** PROC PHREG (LSMEANS); PROC LIFETEST for pvalue=logrank  
**Proven:** the known answer of the method cox (src/methods.ts, worked out by tools/method_answers.R; node tools/methods_sas.ts); ran on SAS 9.4 M9, 2026-11-12  
**File:** `sas/macros/cox.sas` (16NOV2026)

| Parameter | Default | It is |
|---|---|---|
| `data` | **required** | The records |
| `where` |  | The records to use, a condition in parentheses |
| `var` | **required** | The time |
| `by` | **required** | The groups of the model: a character variable |
| `cnsr` | `CNSR` | The censoring variable: 1 = censored (default CNSR) |
| `within` |  | One model in each group of these variables (the levels of a subgroup) |
| `covars` |  | The covariates |
| `class` |  | The class factors |
| `strata` |  | The strata variables, separated by blanks |
| `pairs` | `all` | all: each later group against each earlier one, in the order of ORDER; or the pairs separated by #, one pair per line, the group first, then the group it is compared with (a value with a blank or a hyphen in quotes): "Drug" "Placebo" # "High" "Low". The form "A"-"B" of version 1.0 is still read. |
| `order` |  | A numeric variable with one value per group: the order of the groups |
| `ties` | `efron` | The likelihood of tied times: efron (default), breslow, or exact (the discrete likelihood, TIES=DISCRETE; R coxph calls it exact) |
| `pvalue` | `wald` | wald (default): the Wald test of the pair in the model; logrank: the log-rank test of the two groups of the pair, in the strata |
| `level` | `0.95` | The confidence level (default 0.95) |
| `stats` | `hr="XX.XX" lcl="XX.XX" ucl="XX.XX" pval="X.XXX"` | The statistics, each with its pattern (default hr="XX.XX" lcl="XX.XX" ucl="XX.XX" pval="X.XXX") |
| `label` |  | The label of the block in a table, in quotes |
| `out` | **required** | The result |
| `debug` | `no` | yes: keep the work data sets of the macro (_cox_*) |

```sas
%cox(
    data   = adtte
  , where  = (paramcd = 'PFS')
  , var    = aval
  , by     = trt01p
  , strata = strat1 strat2
  , order  = trt01pn
  , out    = pfs_hr
)
```

**Output:** OUT: one row per pair and statistic (BY: the group, VERSUS: the group it is compared with); GROUPS is BY VERSUS (and WITHIN).

### %csv

<a id="csv"></a>

The records of a listing (or the numbers of a figure, out= of a figure macro) as a CSV file: a line with the names of the variables, then one line per record in the order of the data. sapling sas check compares it with the listing or the figure of R.

**Procedure:** DATA steps (FILE, PUT)  
**Proven:** the listings of the dummy study SYNHTN01 (sapling sas check: listings the same in R and SAS); ran on SAS 9.4 M9, 2026-11-12  
**File:** `sas/macros/csv.sas` (16NOV2026)

| Parameter | Default | It is |
|---|---|---|
| `data` | **required** | The records of the listing |
| `var` | **required** | The variables of the listing |
| `folder` | `listings` | The folder in the outputs: listings or figures |
| `file` | **required** | The name of the listing, without extension |

```sas
%csv(data=adae, var=trt01a usubjid aedecod astdt, file=l14_5_1)
```

**Output:** FILE: <out>/<folder>/<file>.csv: the names of VAR, then one line per record.

### %describe

<a id="describe"></a>

Descriptive statistics of a variable in each group: n, mean, SD, median, minimum and maximum of the values that are not missing; Q1, Q3 and the standard error when stats= asks for them.

**Procedure:** PROC MEANS  
**Proven:** the known answer of the method contsumm (src/methods.ts, worked out by tools/method_answers.R); ran on SAS 9.4 M9, 2026-11-12  
**File:** `sas/macros/describe.sas` (16NOV2026)

| Parameter | Default | It is |
|---|---|---|
| `data` | **required** | The records: a data set |
| `where` |  | The records to use, a condition in parentheses |
| `var` | **required** | The variable |
| `by` | **required** | The groups: variables. The first gives the columns of a table, the others its rows (a parameter, a visit). |
| `keep` |  | Variables kept in the result for the names and the order of its rows (PARAM, AVISITN): the largest value in each group (the ID statement) |
| `total` | `no` | yes: also all groups of the first BY variable together, as the group "Total" (a record without a group is in none, nor in the Total); a text in quotes is another name for it |
| `qntldef` | `5` | The definition of the quantiles, 1 to 5 (5 is the SAS default) |
| `stats` | `n="XX" mean="XX.X" sd="XX.XX" median="XX.X" min="XX" max="XX"` | The statistics in the order of the rows, each with its pattern; also q1, q3 and se |
| `label` |  | The label of the block in a table, in quotes |
| `out` | **required** | The result |
| `debug` | `no` | yes: keep the work data sets _describe_* |

```sas
%describe(
    data  = adsl
  , var   = age
  , by    = trt01a
  , total = yes
  , label = "Age (years)"
  , out   = age
)
%describe(
    data  = advs
  , where = (anl01fl = 'Y')
  , var   = aval
  , by    = trt01a paramcd avisit
  , keep  = param avisitn
  , out   = vs
)
```

**Output:** OUT: one row per group and statistic: the BY variables (and KEEP), GROUPS (the names of the BY variables), BLOCK (the label), STAT, VALUE (the number) and TEXT (the number as printed). A group without a value has no row; no value at all: no row and the NOTE "No data qualified".

### %fisher

<a id="fisher"></a>

Fisher's exact test of "subjects with a record against subjects without" between groups (PROC FREQ): pval. Every subject of DENOM is counted, with a record or without: the usual test of an adverse event between treatments. With exact=no the Pearson chi-square test of the same table.

**Procedure:** PROC FREQ (FISHER, CHISQ)  
**Proven:** the known answer of the method fisher (src/methods.ts, worked out by tools/method_answers.R; node tools/methods_sas.ts); ran on SAS 9.4 M9, 2026-11-12  
**File:** `sas/macros/fisher.sas` (16NOV2026)

| Parameter | Default | It is |
|---|---|---|
| `data` | **required** | The records |
| `denom` | **required** | The subjects (one row each, with BY): a data set, with options if needed |
| `where` |  | The records to use, a condition in parentheses |
| `by` | **required** | The groups to compare: one variable, on DENOM |
| `within` |  | One test in each group of these variables (each term) |
| `exact` | `yes` | no: the chi-square test (default yes) |
| `stats` | `pval="X.XXX"` | The statistic and its pattern (default pval="X.XXX") |
| `label` |  | The label of the block in a table, in quotes |
| `out` | **required** | The result |
| `debug` | `no` | yes: keep the work data sets of the macro (_fisher_*) |

```sas
%fisher(
    data   = adae
  , denom  = adsl
  , where  = (trtemfl = 'Y')
  , by     = trt01a
  , within = aebodsys aedecod
  , out    = pt_test
)
```

**Output:** OUT: one row, or one per group of WITHIN (GROUPS: their names). Where PROC FREQ makes no test the value is missing.

### %flag_first

<a id="flagfirst"></a>

Flag one record of each group: the first (or last) one, among the records that meet a condition. The other records keep a blank flag.

**Procedure:** PROC SORT, MERGE  
**Proven:** the fixtures of the step kind flag.extreme (src/adam_steps.ts; node tools/adam_steps_sas.ts); ran on SAS 9.4 M9, 2026-11-12  
**File:** `sas/macros/flag_first.sas` (16NOV2026)

| Parameter | Default | It is |
|---|---|---|
| `data` | **required** | The working data set (changed in place) |
| `where` |  | The records that can be chosen, a condition in parentheses |
| `by` | **required** | The groups |
| `order` | **required** | The sort keys within a group; "descending" before a key as in a BY statement. A missing key sorts last; records with equal keys keep their order. |
| `which` | `first` | first (default) or last |
| `new` | **required** | The flag to make (Y on the chosen record) |
| `debug` | `no` | yes: keep the work data sets _flag_first_* |

```sas
%flag_first(
    data  = advs
  , where = (NOT MISSING(avisitn) AND NOT MISSING(aval))
  , by    = usubjid paramcd avisitn
  , order = awtdiff ady vsseq
  , new   = anl01fl
)
```

**Output:** DATA: NEW: Y on the first (last) record of each group among the records that meet where=; the others keep a blank NEW. The rows keep their order.

### %flag_if_any

<a id="flagifany"></a>

Flag the subjects that have a record in another data set that meets a condition.

**Procedure:** PROC SORT, MERGE  
**Proven:** the fixtures of the step kinds flag.condition, flag.any (src/adam_steps.ts; node tools/adam_steps_sas.ts); ran on SAS 9.4 M9, 2026-11-12  
**File:** `sas/macros/flag_if_any.sas` (16NOV2026)

| Parameter | Default | It is |
|---|---|---|
| `data` | **required** | The working data set (changed in place) |
| `from` | **required** | The data set of the records |
| `where` | **required** | The condition on FROM, in parentheses |
| `else` | `N` | The value of the other subjects: N (default) or blank |
| `new` | **required** | The flag to make: Y for a subject with such a record |
| `debug` | `no` | yes: keep the work data sets _flag_if_any_* |

```sas
%flag_if_any(
    data  = adsl
  , from  = sdtm.ds
  , where = (dsdecod = 'COMPLETED')
  , new   = complfl
)
```

**Output:** DATA: NEW: Y on every row of a subject that has such a record in FROM, else N (or blank with else=blank), in the order of its rows.

### %forestplot

<a id="forestplot"></a>

The forest plot of results in the levels of subgroups: one row per level under a heading row of its factor, the estimate as a marker with its interval as a bar, a line at no difference, a log axis for a ratio, and the estimate (lower, upper) as text at the right. It draws results (of %cox, %logistic, %rateratio, %lsmeans or %risk with within=), so that the figure and the table of the same results cannot differ.

**Procedure:** PROC SUMMARY, PROC SGPLOT  
**Proven:** its known answer in tools/figures_sas.ts (made-up results, arranged by hand); not yet run on a SAS server  
**File:** `sas/macros/forestplot.sas` (16NOV2026)

| Parameter | Default | It is |
|---|---|---|
| `data` | **required** | The results: rows of STAT and VALUE (the result shape), with the variables of within= |
| `plot` |  | Draw again: an out= of %forestplot (not with data=) |
| `par` |  | The drawing parameters: an outpar= of %forestplot |
| `columns` |  | The columns of %columns: the order and colours of the groups of by= |
| `where` |  | The results to use, a condition in parentheses |
| `estimate` | **required** | The statistic of the estimate (hr, or, irr, rr, rd, diff) |
| `lower` | `lcl` | The statistic of the lower limit |
| `upper` | `ucl` | The statistic of the upper limit |
| `within` | **required** | The variables of the levels, one per factor, in the order of the rows; a row is the level of the first of them that has a value |
| `group` |  | A variable with the heading of each factor (default: the label of the variable of within=) |
| `by` |  | The group of a pair (the results with VERSUS: the pair is by= vs VERSUS); one colour per pair |
| `scale` | `log` | log (a ratio) or linear (a difference) |
| `text` | `yes` | yes: the estimate (lower, upper) as text at the right under the name of the statistic (HR (CI)), and the n when the results have a statistic n |
| `xlabel` | `"Estimate (95% CI)"` | The label of the x axis |
| `ref` | `1` | The line of no difference: 1 for a ratio, 0 for a difference |
| `file` | **required** | The output without its extension: <file>.png (300 dpi) and <file>.rtf |
| `width` | `6.5in` | The width of the figure |
| `height` | `4.5in` | The height of the figure |
| `out` |  | The numbers drawn |
| `outpar` |  | The drawing parameters: one row each |
| `debug` | `no` | yes: keep the work data sets _forestplot_* |

```sas
%forestplot(
    data     = t14_2_sg
  , estimate = hr
  , within   = sex agegr1 race
  , by       = trta
  , scale    = log
  , ref      = 1
  , file     = &spl_out./figures/f14_2_sg
  , out      = f14_2_sg
)
```

**Output:** OUT: one row per level and pair: FACTOR (the variable of within=), LEVEL (its value as printed), PAIR (by= vs VERSUS; blank without by=), KIND estimate, X (the estimate), LOWER, UPPER, N (missing unless the results have n). OUTPAR: one row per drawing parameter in the order of the table: PARAMETER ($32) its name, VALUE ($500) its value as drawn (a label in quotes). FILE: <file>.png and <file>.rtf.

### %freq

<a id="freq"></a>

Frequencies of subjects (PROC FREQ): the subjects of each category in each group (n), their percent of the subjects of the group (pct), and the records (events) when stats= asks for them. A subject is counted once in each cell. Without var= the cell is "a record at all".

**Procedure:** PROC FREQ  
**Proven:** the known answer of the methods count, catsumm (src/methods.ts, worked out by tools/method_answers.R; node tools/methods_sas.ts); ran on SAS 9.4 M9, 2026-11-12  
**File:** `sas/macros/freq.sas` (27NOV2026)

| Parameter | Default | It is |
|---|---|---|
| `data` | **required** | The records |
| `denom` |  | The subjects of each group: the N of the percent and the columns (default: DATA without WHERE). A data set, with options if needed: adsl(where=(...)). |
| `where` |  | The records to count, a condition in parentheses |
| `var` |  | The categories: variables, nested in their order (a term within its class) |
| `by` | **required** | The groups: variables. The first gives the columns of a table, the others its rows or its pages (sex for page= of %layout) |
| `keep` |  | Variables to keep with the categories for their names and order: PARAM and PARAMN go with PARAMCD, AVISITN with AVISIT (a twin <V>N with V); the value of the first record of the category |
| `levels` |  | The planned categories of some variables of var=: each variable and its values. They show also without a subject; a record of another category is not counted. The categories of the other variables come from the records counted: a record of another category of a planned variable brings none. The rows of a planned variable V in the order given: its twin VN (1, 2 ...) in out=, unless keep= has VN. |
| `total` | `no` | yes: also all groups of the first BY variable together, as the group "Total" (a text in quotes is another name for it); that variable a character variable. Default no. |
| `threshold` |  | A percent: only the categories with this percent of the subjects of a group or more, in at least one group (the percent itself, not its rounded text) |
| `order` |  | frequency: the rows of the variable ORDEROF in the order of their subjects, the most first (equal counts by their value), as its twin <V>N (%print orders the rows by it); default: the order of the values |
| `orderof` |  | The variable of VAR whose rows are ordered (default: the last of VAR; the term above a graded variable of %worst) |
| `orderby` |  | The group of BY whose subjects order the rows, in quotes (default: all the groups) |
| `stats` | `n="XX" pct="(XX.X%)"` | The statistics, each with its pattern (default n="XX" pct="(XX.X%)"); also events |
| `label` |  | The label of the block in a table, in quotes |
| `out` | **required** | The result |
| `debug` | `no` | yes: keep the work data sets of the macro (_freq_*) |

```sas
%freq(
    data  = adsl
  , var   = sex
  , by    = trt01a
  , total = yes
  , label = "Sex"
  , out   = sex
)
%freq(
    data  = adae
  , denom = adsl
  , where = (trtemfl = 'Y')
  , var   = aebodsys aedecod
  , by    = trt01a
  , stats = n pct events
  , out   = teae
)
%freq(
    data   = adlbc
  , denom  = adsl
  , var    = paramcd bnrind anrind
  , by     = trt01a
  , levels = bnrind 'LOW' 'NORMAL' 'HIGH' anrind 'LOW' 'NORMAL' 'HIGH'
  , out    = shift
)
%freq(
    data      = adae
  , denom     = adsl
  , where     = (trtemfl = 'Y')
  , var       = aedecod
  , by        = trt01a
  , threshold = 5
  , order     = frequency
  , out       = common
)
```

**Output:** OUT: one row per group, category and statistic: BY and VAR (and KEEP), GROUPS (their names), BLOCK, STAT, VALUE, TEXT. Every group of DENOM has every category: n = 0 when no subject has it. With levels= the twin <V>N of each planned variable (its place in levels=); with order=frequency the twin of ORDEROF.

### %import_xpt

<a id="importxpt"></a>

Read SAS transport files (XPORT version 5) into SAS data sets.

**Procedure:** LIBNAME XPORT, PROC COPY  
**Proven:** the ADaM and SDTM transport files (sapling sas run, sapling sas adam run) of the dummy study SYNHTN01 (sapling sas run: SAS RUN PASS; sapling sas check: SAS CHECK PASS, 570 of 570 numbers of R the same in SAS); ran on SAS 9.4 M9, 2026-11-12  
**File:** `sas/macros/import_xpt.sas` (16NOV2026)

| Parameter | Default | It is |
|---|---|---|
| `dir` | **required** | The folder of the transport files (<member>.xpt) |
| `members` | **required** | The names of the data sets, separated by blanks: the file <member>.xpt, else in lower case (VTXC reads vtxc.xpt) |
| `out` | **required** | The folder the data sets are written to |

```sas
%import_xpt(
    dir     = /DATA/htn3/xpt
  , members = adsl adae advs
  , out     = /DATA/htn3/adam
)
```

**Output:** FILE: the data sets <out>/<member>.sas7bdat. The macro stands alone: a program includes it without the library (00_import.sas), so it calls no other macro of the library and writes no begin and end lines.

### %interaction_genmod

<a id="interactiongenmod"></a>

The test of the interaction of the treatment and a factor in a count model with its exposure, one record per subject (PROC GENMOD, the logarithm of the exposure the offset): Poisson or negative binomial (the dispersion k estimated in each model), the model of the groups, the covariates, the class factors and the factor, against the same with the treatment-by-factor terms. The likelihood-ratio test (pval): twice the difference of the full log likelihoods of the two fits, with the difference of the numbers of their estimated coefficients.

**Procedure:** PROC GENMOD  
**Proven:** the known answer of the methods interaction-poisson, interaction-negbin (src/methods.ts, worked out by tools/method_answers.R; node tools/methods_sas.ts); ran on SAS 9.4 M9, 2026-11-12  
**File:** `sas/macros/interaction_genmod.sas` (16NOV2026)

| Parameter | Default | It is |
|---|---|---|
| `data` | **required** | The records |
| `where` |  | The records to use, a condition in parentheses |
| `var` | **required** | The count |
| `by` | **required** | The groups of the model: a character variable |
| `factor` | **required** | The factor of the subgroups: a variable whose values are its levels |
| `exposure` | **required** | The exposure of each subject: a variable, or an expression of it. Above 0. |
| `covars` |  | The covariates |
| `class` |  | The class factors |
| `dist` | `poisson` | poisson (default) or negbin |
| `stats` | `pval="X.XXX"` | The statistic and its pattern (default pval="X.XXX") |
| `label` |  | The label of the block in a table, in quotes |
| `out` | **required** | The result |
| `debug` | `no` | yes: keep the work data sets of the macro (_interaction_genmod_*) |

```sas
%interaction_genmod(
    data     = adsl
  , var      = exacnt
  , by       = trt01p
  , factor   = sex
  , exposure = trtdur / 365.25
  , dist     = negbin
  , label    = "Sex"
  , out      = sex_int
)
```

**Output:** OUT: one row, of all groups and levels together (GROUPS is blank).

### %interaction_glm

<a id="interactionglm"></a>

The test of the interaction of the treatment and a factor in a linear model, one record per subject (PROC GLM): the variable on the groups, the covariates, the class factors, the factor and the treatment-by-factor terms; the Type III F test of the treatment-by-factor terms (pval). For the term of the highest order this is the F test of the model with the factor against the same model with the terms.

**Procedure:** PROC GLM  
**Proven:** the known answer of the method interaction-lm (src/methods.ts, worked out by tools/method_answers.R; node tools/methods_sas.ts); ran on SAS 9.4 M9, 2026-11-12  
**File:** `sas/macros/interaction_glm.sas` (16NOV2026)

| Parameter | Default | It is |
|---|---|---|
| `data` | **required** | The records |
| `where` |  | The records to use, a condition in parentheses |
| `var` | **required** | The variable |
| `by` | **required** | The groups of the model: a character variable |
| `factor` | **required** | The factor of the subgroups: a variable whose values are its levels |
| `covars` |  | The covariates |
| `class` |  | The class factors |
| `stats` | `pval="X.XXX"` | The statistic and its pattern (default pval="X.XXX") |
| `label` |  | The label of the block in a table, in quotes |
| `out` | **required** | The result |
| `debug` | `no` | yes: keep the work data sets of the macro (_interaction_glm_*) |

```sas
%interaction_glm(
    data   = adqsadas
  , where  = (paramcd = 'ACTOT' AND avisit = 'Week 24')
  , var    = chg
  , by     = trtp
  , factor = sex
  , covars = base
  , class  = sitegr1
  , label  = "Sex"
  , out    = sex_int
)
```

**Output:** OUT: one row, of all groups and levels together (GROUPS is blank).

### %interaction_logistic

<a id="interactionlogistic"></a>

The test of the interaction of the treatment and a factor in a logistic regression, one record per subject (PROC LOGISTIC, the event EVENT=): the model of the groups, the covariates, the class factors and the factor, against the same with the treatment-by-factor terms. The likelihood-ratio test (pval): the difference of the likelihood-ratio chi-squares of the two fits, with the difference of their degrees of freedom.

**Procedure:** PROC LOGISTIC  
**Proven:** the known answer of the method interaction-logistic (src/methods.ts, worked out by tools/method_answers.R; node tools/methods_sas.ts); ran on SAS 9.4 M9, 2026-11-12  
**File:** `sas/macros/interaction_logistic.sas` (16NOV2026)

| Parameter | Default | It is |
|---|---|---|
| `data` | **required** | The records |
| `where` |  | The records to use, a condition in parentheses |
| `var` | **required** | The response |
| `event` | `"Y"` | The value of the response that is the event, in quotes (default "Y") |
| `by` | **required** | The groups of the model: a character variable |
| `factor` | **required** | The factor of the subgroups: a variable whose values are its levels |
| `covars` |  | The covariates |
| `class` |  | The class factors |
| `stats` | `pval="X.XXX"` | The statistic and its pattern (default pval="X.XXX") |
| `label` |  | The label of the block in a table, in quotes |
| `out` | **required** | The result |
| `debug` | `no` | yes: keep the work data sets of the macro (_interaction_logistic_*) |

```sas
%interaction_logistic(
    data   = adsl
  , var    = respfl
  , event  = "Y"
  , by     = trt01a
  , factor = sex
  , covars = age
  , label  = "Sex"
  , out    = sex_int
)
```

**Output:** OUT: one row, of all groups and levels together (GROUPS is blank).

### %interaction_phreg

<a id="interactionphreg"></a>

The test of the interaction of the treatment and a factor in a Cox model, one record per subject (PROC PHREG): the model of the groups, the covariates, the class factors and the factor, stratified by the strata, against the same with the treatment-by-factor terms. The likelihood-ratio test (pval): the difference of the likelihood-ratio chi-squares of the two fits (twice the difference of the log partial likelihoods), with the difference of their degrees of freedom.

**Procedure:** PROC PHREG  
**Proven:** the known answer of the method interaction-cox (src/methods.ts, worked out by tools/method_answers.R; node tools/methods_sas.ts); ran on SAS 9.4 M9, 2026-11-12  
**File:** `sas/macros/interaction_phreg.sas` (16NOV2026)

| Parameter | Default | It is |
|---|---|---|
| `data` | **required** | The records |
| `where` |  | The records to use, a condition in parentheses |
| `var` | **required** | The time |
| `by` | **required** | The groups of the model: a character variable |
| `factor` | **required** | The factor of the subgroups: a variable whose values are its levels |
| `cnsr` | `CNSR` | The censoring variable: 1 = censored (default CNSR) |
| `covars` |  | The covariates |
| `class` |  | The class factors |
| `strata` |  | The strata variables, separated by blanks |
| `ties` | `efron` | efron (default), breslow, or exact (TIES=DISCRETE) |
| `stats` | `pval="X.XXX"` | The statistic and its pattern (default pval="X.XXX") |
| `label` |  | The label of the block in a table, in quotes |
| `out` | **required** | The result |
| `debug` | `no` | yes: keep the work data sets of the macro (_interaction_phreg_*) |

```sas
%interaction_phreg(
    data   = adtte
  , where  = (paramcd = 'PFS')
  , var    = aval
  , by     = trt01p
  , factor = sex
  , strata = strat1
  , label  = "Sex"
  , out    = sex_int
)
```

**Output:** OUT: one row, of all groups and levels together (GROUPS is blank).

### %km

<a id="km"></a>

The Kaplan-Meier summary of a time in each group (PROC LIFETEST): the subjects (n), the events (events), the median time (median) and its confidence limits (lcl, ucl; the limits of Brookmeyer and Crowley). A median the curve does not reach is missing. With time= the survival at that time in percent (surv; TIMELIST=, OUTSURV=) and its limits (lcl, ucl: then of the survival, not of the median).

**Procedure:** PROC LIFETEST  
**Proven:** the known answer of the methods km, kmrate (src/methods.ts, worked out by tools/method_answers.R; node tools/methods_sas.ts); ran on SAS 9.4 M9, 2026-11-12  
**File:** `sas/macros/km.sas` (16NOV2026)

| Parameter | Default | It is |
|---|---|---|
| `data` | **required** | The records |
| `where` |  | The records to use, a condition in parentheses |
| `var` | **required** | The time |
| `by` | **required** | The groups: one variable |
| `cnsr` | `CNSR` | The censoring variable: 1 = censored (default CNSR) |
| `time` |  | A time: the survival at it (surv) and its limits |
| `conftype` | `linear` | The interval of the survival function: CONFTYPE= of PROC LIFETEST, linear (default: Sapling's stated default plain; PROC LIFETEST alone uses loglog), log, loglog |
| `level` | `0.95` | The confidence level (default 0.95) |
| `stats` | `n="XX" events="XX" median="XX.X" lcl="XX.X" ucl="XX.X"` | The statistics, each with its pattern (default n="XX" events="XX" median="XX.X" lcl="XX.X" ucl="XX.X") |
| `label` |  | The label of the block in a table, in quotes |
| `out` | **required** | The result |
| `debug` | `no` | yes: keep the work data sets of the macro (_km_*) |

```sas
%km(
    data  = adtte
  , where = (paramcd = 'TTDE')
  , var   = aval
  , by    = trt01a
  , out   = ttde
)
```

**Output:** OUT: one row per group and statistic.

### %kmplot

<a id="kmplot"></a>

The Kaplan-Meier curve of a time in each group: the survival in percent as steps, a mark at each censored time, the number at risk under the axis at its ticks (the subjects whose time is that time or later), in the order of the groups; with median=yes the median time of each group and its interval.

**Procedure:** PROC LIFETEST, PROC SUMMARY, PROC SGPANEL  
**Proven:** its known answer in tools/figures_sas.ts (survival and number at risk worked out by hand); not yet run on a SAS server  
**File:** `sas/macros/kmplot.sas` (16NOV2026)

| Parameter | Default | It is |
|---|---|---|
| `data` | **required** | The records: one per subject |
| `plot` |  | Draw again: an out= of %kmplot (not with data=) |
| `par` |  | The drawing parameters: an outpar= of %kmplot |
| `columns` |  | The columns of %columns: the order of the groups and their colours (default: the order of the data) |
| `where` |  | The records to use, a condition in parentheses |
| `time` | **required** | The time |
| `cnsr` | `CNSR` | The censoring variable: 1 = censored |
| `by` | **required** | The groups: one curve each |
| `panel` |  | One panel per value of this variable |
| `atrisk` | `yes` | yes: the number at risk under the axis |
| `times` |  | The times of the ticks and of the number at risk, separated by blanks (default: from 0 by a step of 1, 2, 2.5 or 5 times a power of 10, to the first tick at or after the last time) |
| `median` | `no` | yes: the median of each group and its interval as text in the plot |
| `conftype` | `linear` | The interval of the median: CONFTYPE= of PROC LIFETEST (linear, log, loglog, asinsqrt, logit), as %km |
| `level` | `0.95` | The confidence level |
| `xlabel` |  | The label of the x axis (default: the label of time=) |
| `ylabel` | `"Survival (%)"` | The label of the y axis |
| `ref` |  | Reference lines on the y axis: values |
| `file` | **required** | The output without its extension: <file>.png (300 dpi) and <file>.rtf |
| `width` | `6.5in` | The width of the figure |
| `height` | `4.5in` | The height of the figure |
| `out` |  | The numbers drawn |
| `outpar` |  | The drawing parameters: one row each |
| `debug` | `no` | yes: keep the work data sets _kmplot_* |

```sas
%kmplot(
    data    = adtte
  , columns = t14_1_cols
  , where   = (paramcd = 'TTDE')
  , time    = aval
  , cnsr    = cnsr
  , by      = trta
  , median  = yes
  , xlabel  = "Days to the first dermatologic event"
  , file    = &spl_out./figures/f14_1
  , out     = f14_1
)
```

**Output:** OUT: one row per number drawn: PANEL and BY, KIND, X, Y, LOWER, UPPER, N, CENSORED. KIND curve: X a time (0 and each time with an event or a censoring), Y the survival in percent after it, CENSORED 1 when a subject is censored at it. KIND atrisk: X a tick, N the number at risk. KIND median: X the median, LOWER and UPPER its limits (missing: not reached). OUTPAR: one row per drawing parameter in the order of the table, PARAMETER ($32) its name and VALUE ($500) its value as drawn (a label in quotes). FILE: <file>.png and <file>.rtf.

### %layout

<a id="layout"></a>

The display data set of a table: one row per printed line, as the shells have it. The label of a block, the levels of its groups indented by two blanks each (a term under its class, a visit under its parameter, vs B under A), the statistics of a line put in the template of the line; one column per group with its header and N from %columns, and the column All groups for a p-value of all groups; the p-value of each category (a test of each term, a block of the same label) stands in the row of its category. A category that format= names shows its label. It computes nothing: every number is the TEXT of a result. The line table (Step 3), line: label = template: 0 a category of a frequency block = {n} {pct} {events}; 1 n = {n}; 2 Events = {events}; 2.5 Patient-years = {exposure}; 3 Mean (SD) = {mean} ({sd}) [{se}] (se only: Mean (SE); sd and se: Mean (SD) [SE]); 4 Median = {median}; 5 Q1, Q3 = {q1}, {q3}; 6 Min, Max = {min}, {max}; 7 LS mean (SE) = {lsmean} ({lsmean_se}); 8 Difference (SE) = {diff} ({diff_se}); 9 the estimate by its STAT (hr Hazard ratio, or Odds ratio, irr Rate ratio, rd Risk difference, rr Relative risk, rate Rate per 100 patient-years, else Estimate) = {estimate}; 10 Confidence interval = ({lcl}, {ucl}); 11 p-value = {pval}; 11.5 Adjusted p-value = {padj}; 12 any other STAT, labelled by it = {value}. A part that is missing leaves out its piece of the template with its brackets or its comma (a confidence interval without its upper limit prints the lower limit alone); a TEXT that has the brackets of its piece already is not bracketed twice; the counts of a frequency block are right aligned to the widest count. With setup= it also keeps the %print call of OUT in a global macro variable of that name: %print(&name.) prints the display data set again after a change. The setup holds data=, by=, var=, together= and label= (row=" " and the labels of label=), and rows=, file= and nodata= when they are given here. A parameter that is not in the setup is added after it: %print(&name., file=...); one that is in it cannot be given twice (SAS stops a call with a keyword given twice): give it to %layout again, or write the %print call. With page= (a BY variable of the results, such as SEX) the table is one page per value: the page variable is no level of the rows, each page starts with its first block, and the header of each column on a page has the N of that page (%columns with the same page=).

**Procedure:** DATA steps, PROC FORMAT, PROC SORT, PROC TRANSPOSE  
**Proven:** the tables of the dummy study SYNHTN01 (sapling sas run: SAS RUN PASS, flat programs 12 of 12) and the cases of setup= in node tools/print_sas.ts; ran on SAS 9.4 M9, 2026-11-12; the 12 tables of the CDISC pilot (the p value of each term in T14_5_2), 2026-11-13  
**File:** `sas/macros/layout.sas` (27NOV2026)

| Parameter | Default | It is |
|---|---|---|
| `data` | **required** | The results (%stack) |
| `columns` | **required** | The columns (%columns) |
| `var` | **required** | The column variable of the results (as var= of %columns) |
| `page` |  | A BY variable of the results: one page per value (as page= of %columns), kept in the setup |
| `format` |  | The labels of categories: variable and format, as in a FORMAT statement (sex $sexf. race $racef.); a level of that variable shows its formatted value |
| `label` |  | Column labels for %print: name="text" pairs, kept in the setup after row=" " |
| `rows` |  | The rows of a page for %print, kept in the setup |
| `file` |  | The output for %print without its extension, kept in the setup |
| `nodata` |  | The text %print prints when there is no row, kept in the setup |
| `setup` |  | The name of a global macro variable that keeps the %print call of OUT (blank: none is made) |
| `out` | **required** | The display data set |
| `debug` | `no` | yes: keep the work data sets _layout_* |

```sas
%layout(
    data    = t14_2_1
  , columns = t14_2_1_cols
  , var     = trt01a
  , format  = sex $sexf.
  , file    = &spl_out./tlf/t14_2_1
  , setup   = t14_2_1_print
  , out     = t14_2_1_display
)
```

**Output:** OUT: one row per printed line: GRP (the rows that stay on one page: a block, or a level of its first group), ROW (the label, indented, format $CHARw.), C1 ... Cn (the cells, labelled with the header of their column) and C99 (All groups: only when a result has a p-value of all groups). With page=: also the page variable (with its format of format=) and HEAD_C1 ... HEAD_Cn, the header of each column on its page; C1 ... Cn are labelled with the column value. SETUP: with setup=, the global macro variable of that name: the parameters of %print for OUT, such as data=t14_2_1_display, by=row, var=c:, together=grp, label=row=" " (a NOTE in the log shows it); print with %print(&name.).

### %lineplot

<a id="lineplot"></a>

Lines through values given (the LS means of %lsmeans or %mmrm by visit, a rate by month): one line per group, with the interval of lower= and upper= as error bars (the groups a little apart on the x axis) or as a band. Nothing is computed: the figure draws the values of data=. One panel per value of panel=.

**Procedure:** PROC SGPANEL  
**Proven:** its known answer in tools/figures_sas.ts (the values given); not yet run on a SAS server  
**File:** `sas/macros/lineplot.sas` (16NOV2026)

| Parameter | Default | It is |
|---|---|---|
| `data` | **required** | The values: one row per group and x |
| `plot` |  | Draw again: an out= of %lineplot (not with data=) |
| `par` |  | The drawing parameters: an outpar= of %lineplot |
| `columns` |  | The columns of %columns: the order of the groups and their colours (default: the order of the data) |
| `where` |  | The rows to use, a condition in parentheses |
| `x` | **required** | The x: a numeric variable (AVISITN) |
| `y` | **required** | The value |
| `by` | **required** | The groups: one line each |
| `panel` |  | One panel per value of this variable, one under the other, each with its own y axis |
| `lower` |  | The lower end of the interval: a variable |
| `upper` |  | The upper end of the interval: a variable |
| `band` | `no` | yes: the interval as a band; no: as error bars |
| `xformat` |  | The format of the ticks of x (default: the format of x) |
| `xlabel` |  | The label of the x axis (default: the label of x) |
| `ylabel` |  | The label of the y axis (default: the label of y) |
| `ref` |  | Reference lines on the y axis: values |
| `file` | **required** | The output without its extension: <file>.png (300 dpi) and <file>.rtf |
| `width` | `6.5in` | The width of the figure |
| `height` | `4.5in` | The height of the figure |
| `out` |  | The numbers drawn |
| `outpar` |  | The drawing parameters: one row each |
| `debug` | `no` | yes: keep the work data sets _lineplot_* |

```sas
%lineplot(
    data    = lsm_chg
  , columns = t14_3_1_cols
  , x       = avisitn
  , y       = estimate
  , by      = trtp
  , lower   = lcl
  , upper   = ucl
  , xformat = VISIT.
  , ylabel  = "LS mean change from baseline (95% CI)"
  , ref     = 0
  , file    = &spl_out./figures/f14_3_2
  , out     = f14_3_2
)
```

**Output:** OUT: one row per panel, group and x: PANEL and BY, KIND line, X, Y, LOWER, UPPER. OUTPAR: one row per drawing parameter in the order of the table: PARAMETER ($32) its name, VALUE ($500) its value as drawn (a label in quotes). FILE: <file>.png and <file>.rtf.

### %locf

<a id="locf"></a>

Last observation carried forward into the analysis windows, as new records (ADaM: DTYPE = 'LOCF'). For each window after the first one after baseline in which a group has no analysed record: a copy of the last analysed record before it, moved to that window. Baseline is not carried.

**Procedure:** PROC SORT, a DATA step (SET POINT=)  
**Proven:** the fixtures of the step kind impute (src/adam_steps.ts; node tools/adam_steps_sas.ts); ran on SAS 9.4 M9, 2026-11-12  
**File:** `sas/macros/locf.sas` (16NOV2026)

| Parameter | Default | It is |
|---|---|---|
| `data` | **required** | The working data set (changed in place; the new records are added) |
| `windows` | **required** | The windows, as windows= of %windows (baseline and one or more after it) |
| `where` |  | The records LOCF is for, a condition in parentheses |
| `by` | `USUBJID PARAMCD` | The groups (default USUBJID PARAMCD) |
| `flag` | `ANL01FL` | The flag of the analysed records (default ANL01FL = 'Y') |
| `day` | `ADY` | The study day (default ADY) |
| `length` | `$8` | The length of DTYPE (default $8) |
| `debug` | `no` | yes: keep the work data sets _locf_* |

```sas
%locf(
    data    = adqs
  , windows = &advs_windows.
  , where   = (paramcd = 'ACTOT')
)
```

**Output:** DATA: sorted by the groups, AVISITN and DTYPE (the new order of the records).

### %logistic

<a id="logistic"></a>

A logistic regression of a response with two values, one record per subject (PROC LOGISTIC): the probability of the event (event=) on the groups, the covariates and the class factors. The odds ratio of pairs of groups from one fit (or), its Wald confidence limits (lcl, ucl) and the Wald p-value of the pair (pval).

**Procedure:** PROC LOGISTIC (LSMEANS)  
**Proven:** the known answer of the method logistic (src/methods.ts, worked out by tools/method_answers.R; node tools/methods_sas.ts); ran on SAS 9.4 M9, 2026-11-12  
**File:** `sas/macros/logistic.sas` (16NOV2026)

| Parameter | Default | It is |
|---|---|---|
| `data` | **required** | The records |
| `where` |  | The records to use, a condition in parentheses |
| `var` | **required** | The response: two values |
| `event` | `"Y"` | The value that is the event, in quotes (default "Y"; a number: "1"). PROC LOGISTIC alone models the first value in sort order. |
| `by` | **required** | The groups of the model: a character variable |
| `within` |  | One model in each group of these variables (the levels of a subgroup) |
| `covars` |  | The covariates |
| `class` |  | The class factors |
| `pairs` | `all` | all: each later group against each earlier one, in the order of ORDER; or the pairs separated by #, one pair per line, the group first, then the group it is compared with (a value with a blank or a hyphen in quotes): "Drug" "Placebo" # "High" "Low". The form "A"-"B" of version 1.0 is still read. |
| `order` |  | A numeric variable with one value per group: the order of the groups |
| `level` | `0.95` | The confidence level (default 0.95) |
| `stats` | `or="XX.XX" lcl="XX.XX" ucl="XX.XX" pval="X.XXX"` | The statistics, each with its pattern (default or="XX.XX" lcl="XX.XX" ucl="XX.XX" pval="X.XXX") |
| `label` |  | The label of the block in a table, in quotes |
| `out` | **required** | The result |
| `debug` | `no` | yes: keep the work data sets of the macro (_logistic_*) |

```sas
%logistic(
    data   = adrs
  , where  = (paramcd = 'BOR')
  , var    = crit1fl
  , event  = "Y"
  , by     = trt01p
  , covars = age
  , class  = sex
  , order  = trt01pn
  , out    = resp_or
)
```

**Output:** OUT: one row per pair and statistic (BY: the group, VERSUS: the group it is compared with); GROUPS is BY VERSUS (and WITHIN).

### %logrank

<a id="logrank"></a>

The log-rank test of a time between groups (PROC LIFETEST, STRATA), one record per subject: pval. With strata= the stratified log-rank test (STRATA strata / GROUP=by): each combination of the values of the strata variables one stratum. With one group there is no test: the value is missing.

**Procedure:** PROC LIFETEST (STRATA)  
**Proven:** the known answer of the method logrank (src/methods.ts, worked out by tools/method_answers.R; node tools/methods_sas.ts); ran on SAS 9.4 M9, 2026-11-12  
**File:** `sas/macros/logrank.sas` (16NOV2026)

| Parameter | Default | It is |
|---|---|---|
| `data` | **required** | The records |
| `where` |  | The records to use, a condition in parentheses |
| `var` | **required** | The time |
| `by` | **required** | The groups to compare: one variable |
| `cnsr` | `CNSR` | The censoring variable: 1 = censored (default CNSR) |
| `strata` |  | The strata variables of a stratified test, separated by blanks |
| `stats` | `pval="X.XXX"` | The statistic and its pattern (default pval="X.XXX") |
| `label` |  | The label of the block in a table, in quotes |
| `out` | **required** | The result |
| `debug` | `no` | yes: keep the work data sets of the macro (_logrank_*) |

```sas
%logrank(
    data   = adtte
  , where  = (paramcd = 'TTDE')
  , var    = aval
  , by     = trt01a
  , strata = strat1 strat2
  , out    = ttde_test
)
```

**Output:** OUT: one row, of all groups together (GROUPS is blank).

### %lsmeans

<a id="lsmeans"></a>

A linear model of a variable, one record per subject (PROC MIXED without a random effect: least squares): covariates, class factors and the groups. The differences of the LS means of pairs of groups (diff, diff_se, lcl, ucl, pval) and, when stats= asks for them, the LS mean of each group (lsmean, lsmean_se) and its confidence limits (lsmean_lcl, lsmean_ucl).

**Procedure:** PROC MIXED (LSMEANS)  
**Proven:** the known answer of the method lsmeans (src/methods.ts, worked out by tools/method_answers.R; node tools/methods_sas.ts); ran on SAS 9.4 M9, 2026-11-12  
**File:** `sas/macros/lsmeans.sas` (27NOV2026)

| Parameter | Default | It is |
|---|---|---|
| `data` | **required** | The records |
| `where` |  | The records to use, a condition in parentheses |
| `var` | **required** | The response |
| `by` | **required** | The groups of the model: a character variable |
| `within` |  | One model in each group of these variables |
| `covars` |  | The covariates |
| `class` |  | The class factors |
| `pairs` | `all` | all: each later group against each earlier one, in the order of ORDER; or the pairs separated by #, one pair per line, the group first, then the group it is compared with (a value with a blank or a hyphen in quotes): "Drug" "Placebo" # "High" "Low". The form "A"-"B" of version 1.0 is still read. |
| `order` |  | A numeric variable with one value per group: the order of the groups |
| `level` | `0.95` | The confidence level (default 0.95) |
| `stats` | `diff="XX.X" diff_se="XX.XX" lcl="XX.X" ucl="XX.X" pval="X.XXX"` | The statistics, each with its pattern (default diff="XX.X" diff_se="XX.XX" lcl="XX.X" ucl="XX.X" pval="X.XXX"); also lsmean, lsmean_se, lsmean_lcl and lsmean_ucl |
| `label` |  | The label of the block in a table, in quotes |
| `out` | **required** | The result |
| `debug` | `no` | yes: keep the work data sets of the macro (_lsmeans_*) |

```sas
%lsmeans(
    data   = adqsadas
  , where  = (paramcd = 'ACTOT' AND avisit = 'Week 24')
  , var    = chg
  , by     = trt01p
  , covars = base
  , class  = sitegr1
  , pairs  = all
  , order  = trt01pn
  , out    = pairs
)
```

**Output:** OUT: the rows of the differences (BY: the group, VERSUS: the group it is compared with) and of the LS means (VERSUS blank); GROUPS is BY VERSUS WITHIN.

### %meanplot

<a id="meanplot"></a>

The mean (or the median) of a variable at each visit in each group, with its error bars (SE, SD, the confidence interval of the mean, or Q1 and Q3 of the median), joined by lines; the groups a little apart on the x axis so that their bars do not overlap; with ntable=yes the n of each visit and group under the axis. One panel per value of panel=.

**Procedure:** PROC MEANS, PROC SGPANEL  
**Proven:** its known answer in tools/figures_sas.ts (means, SE, SD, limits worked out by hand); not yet run on a SAS server  
**File:** `sas/macros/meanplot.sas` (16NOV2026)

| Parameter | Default | It is |
|---|---|---|
| `data` | **required** | The records |
| `plot` |  | Draw again: an out= of %meanplot (not with data=) |
| `par` |  | The drawing parameters: an outpar= of %meanplot |
| `columns` |  | The columns of %columns: the order of the groups and their colours (default: the order of the data) |
| `where` |  | The records to use, a condition in parentheses |
| `y` | **required** | The variable |
| `x` | **required** | The visit: a numeric variable (AVISITN); its ticks are its values, printed with xformat= |
| `by` | **required** | The groups: one line each |
| `panel` |  | One panel per value of this variable (PARAMCD), one under the other, each with its own y axis |
| `stat` | `mean` | mean or median |
| `error` | `se` | The error bars: se, sd, ci (of the mean), iqr (Q1 and Q3, of the median) or none |
| `level` | `0.95` | The confidence level of error=ci |
| `connect` | `yes` | yes: the points of a group joined by a line |
| `ntable` | `no` | yes: the n of each visit and group under the axis |
| `xformat` |  | The format of the ticks of x (default: the format of x) |
| `xlabel` |  | The label of the x axis (default: the label of x) |
| `ylabel` |  | The label of the y axis (default: the statistic, the error bars and the label of y) |
| `ref` |  | Reference lines on the y axis: values |
| `file` | **required** | The output without its extension: <file>.png (300 dpi) and <file>.rtf |
| `width` | `6.5in` | The width of the figure |
| `height` | `4.5in` | The height of the figure |
| `out` |  | The numbers drawn |
| `outpar` |  | The drawing parameters: one row each |
| `debug` | `no` | yes: keep the work data sets _meanplot_* |

```sas
%meanplot(
    data    = advs
  , columns = t14_7_1_cols
  , where   = (anl01fl = 'Y' AND avisitn > 0)
  , y       = chg
  , x       = avisitn
  , by      = trta
  , panel   = param
  , ntable  = yes
  , xformat = VISIT.
  , ref     = 0
  , file    = &spl_out./figures/f14_7_1
  , out     = f14_7_1
)
```

**Output:** OUT: one row per panel, group and visit: PANEL and BY, KIND (mean or median), X (the visit), Y (the statistic), LOWER and UPPER (the ends of the error bar; missing with one value for se, sd, ci), N. OUTPAR: one row per drawing parameter in the order of the table: PARAMETER ($32) its name, VALUE ($500) its value as drawn (a label in quotes). FILE: <file>.png and <file>.rtf. The quantiles are those of PROC MEANS QNTLDEF=5 (R type 2). Draw again: plot= (an out= of %meanplot, changed or not) is drawn as it is, without a statistic (error bars where LOWER has a value), and par= (an outpar= of %meanplot) gives the drawing parameters: columns, by, panel, connect, ntable, xformat, xlabel, ylabel, ref, file, width, height. They change the picture, not the numbers; the others compute, and with plot= a NOTE says each one given is not used. A drawing parameter given in the call wins over its row of par=, the row over the default of the table.

### %merge_subject

<a id="mergesubject"></a>

Copy variables from another data set by subject (USUBJID). The other data set has one row per subject; the rows of DATA stay as they are, in their order.

**Procedure:** PROC SORT, MERGE  
**Proven:** the fixtures of the step kinds copy, period (src/adam_steps.ts; node tools/adam_steps_sas.ts); ran on SAS 9.4 M9, 2026-11-12  
**File:** `sas/macros/merge_subject.sas` (16NOV2026)

| Parameter | Default | It is |
|---|---|---|
| `data` | **required** | The working data set (changed in place) |
| `from` | **required** | The data set to copy from |
| `vars` | **required** | The variables, separated by blanks; NEW=OLD copies under another name |
| `debug` | `no` | yes: keep the work data sets _merge_subject_* |

```sas
%merge_subject(
    data = advs
  , from = adam.adsl
  , vars = age sex trtp=trt01p trtpn=trt01pn
)
```

**Output:** DATA: the variables of FROM of its subject on every row, in the order of its rows; a subject not in FROM gets missing values.

### %mmrm

<a id="mmrm"></a>

The mixed model for repeated measures, one record per subject and visit (PROC MIXED, REPEATED): at one visit the differences of the LS means of pairs of groups (diff, diff_se, lcl, ucl, pval) and, when stats= asks for them, the LS mean of each group (lsmean, lsmean_se). When the covariance structure does not converge the next one of fallback= is tried.

**Procedure:** PROC MIXED (REPEATED, LSMEANS)  
**Proven:** the known answer of the method mmrm (src/methods.ts, worked out by tools/method_answers.R; node tools/methods_sas.ts); ran on SAS 9.4 M9, 2026-11-12  
**File:** `sas/macros/mmrm.sas` (16NOV2026)

| Parameter | Default | It is |
|---|---|---|
| `data` | **required** | The records |
| `where` |  | The records to use, a condition in parentheses |
| `var` | **required** | The response |
| `by` | **required** | The groups: a character variable |
| `visit` | **required** | The repeated variable (REPEATED), a class factor |
| `at` | **required** | The visit of the LS means, in quotes |
| `class` |  | The class factors besides the groups and the subject (the visit is one) |
| `subject` | `USUBJID` | The subject (default USUBJID) |
| `model` | **required** | The fixed effects: the MODEL statement after the equal sign |
| `type` | `un` | The covariance structure: TYPE= of REPEATED (default un) |
| `fallback` |  | Other structures to try in their order, when one does not converge |
| `ddfm` | `bw` | The degrees of freedom: DDFM= of MODEL (default bw: between-within) |
| `method` | `reml` | reml (default) or ml |
| `pairs` | `all` | all: each later group against each earlier one, in the order of ORDER; or the pairs separated by #, one pair per line, the group first, then the group it is compared with (a value with a blank or a hyphen in quotes): "Drug" "Placebo" # "High" "Low". The form "A"-"B" of version 1.0 is still read. |
| `order` |  | A numeric variable with one value per group: the order of the groups |
| `level` | `0.95` | The confidence level (default 0.95) |
| `stats` | `diff="XX.X" diff_se="XX.XX" lcl="XX.X" ucl="XX.X" pval="X.XXX"` | The statistics, as in %lsmeans |
| `label` |  | The label of the block in a table, in quotes |
| `out` | **required** | The result |
| `debug` | `no` | yes: keep the work data sets of the macro (_mmrm_*) |

```sas
%mmrm(
    data     = adqsadas
  , where    = (paramcd = 'ACTOT' AND anl01fl = 'Y')
  , var      = chg
  , by       = trt01p
  , visit    = avisit
  , at       = "Week 24"
  , class    = sitegr1 avisit
  , model    = base sitegr1 trt01p avisit trt01p*avisit base*avisit
  , type     = un
  , fallback = toep
  , ddfm     = bw
  , pairs    = all
  , order    = trt01pn
  , out      = mmrm
)
```

**Output:** OUT: as %lsmeans: the rows of the differences (BY, VERSUS) and of the LS means.

### %param_wide

<a id="paramwide"></a>

The values of several parameters side by side: one record per group of BY that has a record of every parameter of PARAMS, with the variables VARS of each parameter as <PARAMCD>_<VAR> (WEIGHT_AVAL). Two records of one parameter in a group are an ERROR.

**Procedure:** PROC SORT, MERGE  
**Proven:** the fixtures of the step kind computed (src/adam_steps.ts; node tools/adam_steps_sas.ts); ran on SAS 9.4 M9, 2026-11-12  
**File:** `sas/macros/param_wide.sas` (16NOV2026)

| Parameter | Default | It is |
|---|---|---|
| `data` | **required** | The records (with PARAMCD and the BY variables) |
| `where` |  | The records to read, a condition in parentheses |
| `params` | **required** | The parameter codes |
| `vars` | **required** | The variables of each parameter to keep (AVAL) |
| `by` | **required** | The groups (the subject and the visit) |
| `out` | **required** | One record per group: BY, then <PARAMCD>_<VAR> for each parameter and variable |
| `debug` | `no` | yes: keep the work data sets _param_wide_* |

```sas
%param_wide(
    data   = work.advs
  , params = weight height
  , vars   = aval
  , by     = usubjid avisitn
  , out    = work._bmi
)
```

**Output:** OUT: one record per group of BY that has a record of every parameter: BY, then <PARAMCD>_<VAR> for each parameter and variable. Two records of one parameter in a group are an ERROR that names the group.

### %pick

<a id="pick"></a>

Give each subject the value of its first (or last) record in another data set.

**Procedure:** PROC SORT, MERGE  
**Proven:** the fixtures of the step kinds derive.from.one, derive.from.extreme, ice (src/adam_steps.ts; node tools/adam_steps_sas.ts); ran on SAS 9.4 M9, 2026-11-12  
**File:** `sas/macros/pick.sas` (16NOV2026)

| Parameter | Default | It is |
|---|---|---|
| `data` | **required** | The working data set (changed in place) |
| `from` | **required** | The data set of the records. Prepare it with a DATA step when the value or a sort key is not a variable yet (a date of a text, a difference). |
| `value` | **required** | The variable of FROM that gives the value |
| `order` |  | The sort keys within a subject; "descending" before a key as in a BY statement. A missing key sorts last. Without order: the first record as the data are. |
| `which` | `first` | first (default) or last |
| `length` |  | The length of a text variable, e.g. $40 |
| `format` |  | The format, e.g. date9 |
| `unique` | `no` | yes: each subject has at most one record in FROM (the plan names one record and no order); two records are an ERROR. Default no. |
| `new` | **required** | The variable to make |
| `debug` | `no` | yes: keep the work data sets _pick_* |

```sas
%pick(
    data   = adsl
  , from   = ex
  , value  = exstdt
  , order  = exstdt exseq
  , which  = first
  , format = date9.
  , new    = trtsdt
)
```

**Output:** DATA: NEW on every row of a subject: the value of its first (or last) record in FROM; missing for a subject without a record. With unique=yes two records of a subject are an ERROR that names the subject.

### %pool

<a id="pool"></a>

Pool small groups: a group (e.g. a site) that has fewer than MIN subjects in one of the groups of BY (e.g. a treatment) goes into one pooled group.

**Procedure:** PROC FREQ, PROC SUMMARY, MERGE  
**Proven:** the fixtures of the step kind pool (src/adam_steps.ts; node tools/adam_steps_sas.ts); ran on SAS 9.4 M9, 2026-11-12  
**File:** `sas/macros/pool.sas` (16NOV2026)

| Parameter | Default | It is |
|---|---|---|
| `data` | **required** | The working data set (changed in place) |
| `var` | **required** | The groups to pool (SITEID) |
| `by` | **required** | The variable whose every group must have MIN subjects (the treatment) |
| `min` | **required** | The smallest number of subjects |
| `length` |  | The length of NEW, e.g. $3 |
| `new` | **required** | The variable to make: VAR, or INTO for a small group |
| `into` | **required** | The value of the pooled group |
| `debug` | `no` | yes: keep the work data sets _pool_* |

```sas
%pool(
    data   = adsl
  , var    = siteid
  , by     = trt01p
  , min    = 3
  , length = $3
  , new    = sitegr1
  , into   = 900
)
```

**Output:** DATA: NEW: the value of VAR, or INTO for a group of VAR with fewer than MIN subjects in one of the groups of BY. The rows keep their order.

### %print

<a id="print"></a>

Print a table or a listing: one PROC REPORT into an RTF file and a monospace listing beside it. A table is printed from its display data set (%layout), a listing from its records. The BY columns come first, a repeated value shown once; the VAR columns follow, numbers right, text left as written. ODS wraps and pages the RTF; the rows of one TOGETHER value stay on one page of the listing when they fit in ROWS. The parameters of a table can come from the setup of %layout (setup=): %print(&name.) prints its display data set again after a change; a parameter that is not in the setup is added after it: %print(&name., file=...). A keyword given twice stops the call (SAS): change it in %layout. page= prints one page (or more) per value of a variable, into the same two files: the report of each value under a BY statement, so that a title of the program can name it (OPTIONS NOBYLINE and TITLE2 "Sex: #BYVAL1"); a column X with a variable HEAD_X has the header of its page from it.

**Procedure:** PROC REPORT  
**Proven:** its cases of node tools/print_sas.ts (PRINT SAS PASS: 18 cases) and the tables and listings of the dummy study SYNHTN01 (flat programs 12 of 12); ran on SAS 9.4 M9, 2026-11-12  
**File:** `sas/macros/print.sas` (27NOV2026)

| Parameter | Default | It is |
|---|---|---|
| `data` | **required** | The rows: the display data set of %layout, or the records of a listing |
| `by` |  | The left columns, printed first: a repeated value shown once |
| `var` | **required** | The other columns, in print order; a list such as c: or c1-c5 is allowed |
| `page` |  | A variable: a new page for each value, its value for #BYVAL1 of a title; a variable HEAD_X gives the header of the column X on the page of its row |
| `together` |  | A variable: the rows of one value stay on one page |
| `label` |  | Column labels: name="text" pairs; \| splits a header (default: the labels of the variables) |
| `rows` | `40` | The rows of a page, for together= |
| `file` | **required** | The output without its extension: <file>.rtf and <file>.lst |
| `nodata` | `No data qualified` | The text printed when there is no row |
| `debug` | `no` | yes: keep the work data sets _print_* |

```sas
%print(
    data     = t14_2_1_display
  , by       = row
  , var      = c:
  , together = grp
  , label    = %STR(row=" ")
  , file     = &spl_out./tlf/t14_2_1
)
%print(data=adae, by=trt01a usubjid, var=aedecod astdt aesev, file=&spl_out./listings/l14_5_1)
%print(
    data     = t14_1_1_display
  , by       = row
  , var      = c:
  , page     = sex
  , together = grp
  , label    = %STR(row=" ")
  , file     = &spl_out./tlf/t14_1_1
)
```

**Output:** FILE: <file>.rtf (style journal, landscape) and <file>.lst (the LISTING destination), under the titles and footnotes of the program; no row: the text of nodata=. With page=: the pages of each value in the order of the rows.

### %profileplot

<a id="profileplot"></a>

The profile of each subject: one thin line per subject through its values by visit, in the colour and the line pattern of its group; with mean=yes the mean of each group at each visit as a thick line with markers. One panel per value of panel=.

**Procedure:** PROC MEANS, PROC SGPANEL  
**Proven:** its known answer in tools/figures_sas.ts (the values and the means worked out by hand); not yet run on a SAS server  
**File:** `sas/macros/profileplot.sas` (16NOV2026)

| Parameter | Default | It is |
|---|---|---|
| `data` | **required** | The records |
| `plot` |  | Draw again: an out= of %profileplot, not with data= |
| `par` |  | The drawing parameters: an outpar= of %profileplot |
| `columns` |  | The columns of %columns: the order of the groups and their colours (default: the order of the data) |
| `where` |  | The records to use, a condition in parentheses |
| `x` | **required** | The visit: a numeric variable (AVISITN, ADY) |
| `y` | **required** | The variable |
| `subject` | `USUBJID` | The subject: one line each |
| `by` | **required** | The groups: one colour each |
| `panel` |  | One panel per value of this variable, one under the other, each with its own y axis |
| `mean` | `no` | yes: the mean of each group as a thick line |
| `xformat` |  | The format of the ticks of x (default: the format of x) |
| `xlabel` |  | The label of the x axis (default: the label of x) |
| `ylabel` |  | The label of the y axis (default: the label of y) |
| `ref` |  | Reference lines on the y axis: values |
| `file` | **required** | The output without its extension: <file>.png (300 dpi) and <file>.rtf |
| `width` | `6.5in` | The width of the figure |
| `height` | `4.5in` | The height of the figure |
| `out` |  | The numbers drawn |
| `outpar` |  | The drawing parameters: one row each |
| `debug` | `no` | yes: keep the work data sets _profileplot_* |

```sas
%profileplot(
    data    = adlbc
  , columns = t14_6_cols
  , where   = (paramcd = 'ALT' AND anl01fl = 'Y')
  , x       = ady
  , y       = aval
  , by      = trta
  , mean    = no
  , ref     = 40
  , file    = &spl_out./figures/f14_6_1
  , out     = f14_6_1
)
```

**Output:** OUT: one row per point: PANEL, BY and SUBJECT, KIND (subject: a value of a subject; mean: the mean of a group, SUBJECT blank), X, Y, N (the values of a mean). OUTPAR: one row per drawing parameter in the order of the table: PARAMETER ($32) its name, VALUE ($500) its value as drawn (a label in quotes). FILE: <file>.png and <file>.rtf.

### %proportion

<a id="proportion"></a>

The subjects in each category of a variable in each group, their percent of the subjects of the group, and the confidence interval of that percent by a named method (PROC FREQ, BINOMIAL): n, pct, lcl, ucl (the limits in percent, as pct).

**Procedure:** PROC FREQ (BINOMIAL)  
**Proven:** the known answer of the method propci (src/methods.ts, worked out by tools/method_answers.R; node tools/methods_sas.ts); ran on SAS 9.4 M9, 2026-11-12  
**File:** `sas/macros/proportion.sas` (16NOV2026)

| Parameter | Default | It is |
|---|---|---|
| `data` | **required** | The records |
| `denom` |  | The subjects of the percent: a data set with one row per subject and BY (default: the subjects of data=) |
| `where` |  | The records to use, a condition in parentheses |
| `var` | **required** | The category |
| `by` | **required** | The groups: one variable |
| `levels` |  | The categories of the plan: the variable, then its values in quotes. A category without a subject shows with n = 0. |
| `ci` | `clopper-pearson` | The interval: clopper-pearson (default; the exact interval, CL=EXACT; exact is another name for it), wilson (the score interval, CL=WILSON), wald (CL=WALD), agresti-coull (CL=AGRESTICOULL) |
| `level` | `0.95` | The confidence level (default 0.95) |
| `stats` | `n="XX" pct="(XX.X%)" lcl="XX.X" ucl="XX.X"` | The statistics, each with its pattern (default n="XX" pct="(XX.X%)" lcl="XX.X" ucl="XX.X") |
| `label` |  | The label of the block in a table, in quotes |
| `out` | **required** | The result |
| `debug` | `no` | yes: keep the work data sets of the macro (_proportion_*) |

```sas
%proportion(
    data   = adrs
  , denom  = adsl
  , where  = (paramcd = 'BOR')
  , var    = avalc
  , by     = trt01a
  , levels = avalc 'CR' 'PR'
  , ci     = clopper-pearson
  , out    = bor_ci
)
```

**Output:** OUT: one row per group, category and statistic; GROUPS is BY VAR.

### %rate

<a id="rate"></a>

The exposure-adjusted incidence rate of each group: the subjects with a record (n; PROC FREQ), the sum of the exposure of the subjects of the group (exposure; PROC MEANS), the rate n / exposure times per= (rate) and its exact Poisson limits (lcl, ucl: the chi-square quantiles of 2n and 2(n + 1) degrees of freedom, halved, divided by the exposure; CINV).

**Procedure:** PROC FREQ, PROC MEANS, CINV  
**Proven:** the known answer of the methods eair, eventrate (src/methods.ts, worked out by tools/method_answers.R; node tools/methods_sas.ts); ran on SAS 9.4 M9, 2026-11-12  
**File:** `sas/macros/rate.sas` (16NOV2026)

| Parameter | Default | It is |
|---|---|---|
| `data` | **required** | The records (the events) |
| `denom` | **required** | The subjects of the groups with their exposure: one row per subject |
| `where` |  | The records to use, a condition in parentheses |
| `by` | **required** | The groups: one variable, in data= and in denom= |
| `exposure` | **required** | The exposure of a subject: a variable of denom=, or an expression of it (TRTDUR / 365.25: in years) |
| `count` | `subjects` | subjects (default): the subjects with a record (n); events: every record (events), the rate and its limits of the number of events |
| `per` | `100` | The rate per this many units of exposure (default 100: per 100 patient-years) (the line of %layout reads "Rate per 100 patient-years": with another per=, change LABEL in the display data set) |
| `level` | `0.95` | The confidence level (default 0.95) |
| `stats` |  | The statistics, each with its pattern (default n="XX" exposure="XX.X" rate="XX.XX" lcl="XX.XX" ucl="XX.XX") |
| `label` |  | The label of the block in a table, in quotes |
| `out` | **required** | The result |
| `debug` | `no` | yes: keep the work data sets of the macro (_rate_*) |

```sas
%rate(
    data     = adae
  , denom    = adsl
  , where    = (trtemfl = 'Y')
  , by       = trt01a
  , exposure = trtdur / 365.25
  , out      = ae_rate
)
%rate(
    data     = adae
  , denom    = adsl
  , where    = (trtemfl = 'Y')
  , by       = trt01a
  , exposure = trtdur / 365.25
  , count    = events
  , out      = ae_events
)
```

**Output:** OUT: one row per group and statistic; GROUPS is BY.

### %rateratio

<a id="rateratio"></a>

A count model of a count with its exposure, one record per subject (PROC GENMOD, the logarithm of the exposure the offset): Poisson or negative binomial (the dispersion k by maximum likelihood), on the groups, the covariates and the class factors. The rate ratio of pairs of groups from one fit (irr), its Wald confidence limits (lcl, ucl) and the Wald p-value of the pair (pval).

**Procedure:** PROC GENMOD (LSMEANS)  
**Proven:** the known answer of the methods poisson, negbin (src/methods.ts, worked out by tools/method_answers.R; node tools/methods_sas.ts); ran on SAS 9.4 M9, 2026-11-12  
**File:** `sas/macros/rateratio.sas` (16NOV2026)

| Parameter | Default | It is |
|---|---|---|
| `data` | **required** | The records |
| `where` |  | The records to use, a condition in parentheses |
| `var` | **required** | The count |
| `by` | **required** | The groups of the model: a character variable |
| `exposure` | **required** | The exposure of each subject: a variable, or an expression of it (TRTDUR / 365.25: in years). Above 0. |
| `within` |  | One model in each group of these variables (the levels of a subgroup) |
| `covars` |  | The covariates |
| `class` |  | The class factors |
| `dist` | `poisson` | poisson (default) or negbin |
| `pairs` | `all` | all: each later group against each earlier one, in the order of ORDER; or the pairs separated by #, one pair per line, the group first, then the group it is compared with (a value with a blank or a hyphen in quotes): "Drug" "Placebo" # "High" "Low". The form "A"-"B" of version 1.0 is still read. |
| `order` |  | A numeric variable with one value per group: the order of the groups |
| `level` | `0.95` | The confidence level (default 0.95) |
| `stats` | `irr="XX.XX" lcl="XX.XX" ucl="XX.XX" pval="X.XXX"` | The statistics, each with its pattern (default irr="XX.XX" lcl="XX.XX" ucl="XX.XX" pval="X.XXX") |
| `label` |  | The label of the block in a table, in quotes |
| `out` | **required** | The result |
| `debug` | `no` | yes: keep the work data sets of the macro (_rateratio_*) |

```sas
%rateratio(
    data     = adexac
  , var      = aval
  , by       = trt01p
  , exposure = trtdur / 365.25
  , covars   = base
  , dist     = negbin
  , order    = trt01pn
  , out      = exac_rr
)
```

**Output:** OUT: one row per pair and statistic (BY: the group, VERSUS: the group it is compared with); GROUPS is BY VERSUS (and WITHIN).

### %relchange

<a id="relchange"></a>

New records of the change from the record before, relative to the normal range (the pilot SAP 8.3: a change larger than half the normal range is abnormal). For each record: a record of the parameter PREFIX + PARAMCD whose AVAL is (value - the value of the record before) / ((upper - lower limit) / 2), rounded as ROUND; ANRIND H above +LIMIT, L below -LIMIT, else N.

**Procedure:** PROC SORT, a DATA step (LAG)  
**Proven:** the fixtures of the step kind relchange (src/adam_steps.ts; node tools/adam_steps_sas.ts); ran on SAS 9.4 M9, 2026-11-12  
**File:** `sas/macros/relchange.sas` (16NOV2026)

| Parameter | Default | It is |
|---|---|---|
| `data` | **required** | The records (not changed) |
| `where` |  | The records to read, a condition in parentheses (the record before is one of them) |
| `value` | **required** | The measured value (LBSTRESN) |
| `by` | `USUBJID PARAMCD` | The groups (default USUBJID PARAMCD) |
| `lo` | `A1LO` | The limits (default A1LO, A1HI) |
| `hi` | `A1HI` | The limits (default A1LO, A1HI) |
| `order` | `VISITNUM ADT LBSEQ` | The order that gives the record before (default VISITNUM ADT LBSEQ; a missing value sorts first) |
| `prefix` | `_` | The prefix of the new PARAMCD (default _) |
| `digits` | `1` | The decimals of AVAL (default 1) |
| `limit` | `1` | ANRIND is H above +LIMIT and L below -LIMIT (default 1: half the range) |
| `reset` | `BASE CHG BNRIND R2A1LO R2A1HI BR2A1LO BR2A1HI` | The variables set missing on the new records, those that DATA has (default BASE CHG BNRIND R2A1LO R2A1HI BR2A1LO BR2A1HI); the limits are set missing too |
| `out` | **required** | The new records: one for each record of DATA, sorted by BY and ORDER |
| `debug` | `no` | yes: keep the work data sets _relchange_* |

```sas
%relchange(
    data  = work.adlbc
  , value = lbstresn
  , out   = work._relchange
)
```

**Output:** OUT: has the variables of DATA. AVAL has a value on a scheduled visit (AVISITN not missing) when the value, the value before and both limits are there and the upper limit is above the lower one; it is missing on the first record of a group. PARAMCD keeps its length in DATA: it must hold the new codes (the generated programs give it the length of the specification, which lists them).

### %risk

<a id="risk"></a>

The comparison of two proportions of each pair of groups, one record per subject (PROC FREQ): the 2 x 2 table of the two groups (the group first) and the event (event=) against the rest. measure=rd: the risk difference (rd) with the interval of ci=; measure=rr: the relative risk (rr), measure=or: the odds ratio (or), each with the Wald interval of its logarithm; the p-value of Pearson's chi-square test without continuity correction (pval). With strata= the Mantel-Haenszel risk difference (COMMONRISKDIFF, CL=MH) and the CMH test.

**Procedure:** PROC FREQ (RISKDIFF, RELRISK, CHISQ; COMMONRISKDIFF, CMH)  
**Proven:** the known answer of the methods riskdiff, riskratio, oddsratio, perterm (src/methods.ts, worked out by tools/method_answers.R; node tools/methods_sas.ts); ran on SAS 9.4 M9, 2026-11-12  
**File:** `sas/macros/risk.sas` (16NOV2026)

| Parameter | Default | It is |
|---|---|---|
| `data` | **required** | The records |
| `where` |  | The records to use, a condition in parentheses |
| `var` | **required** | The response: two values |
| `event` | `"Y"` | The value that is the event, in quotes (default "Y") |
| `by` | **required** | The groups: a character variable |
| `within` |  | One comparison in each group of these variables (each term of an adverse event table: the flags of %termflags) |
| `strata` |  | The strata variables of the Mantel-Haenszel risk difference |
| `pairs` | `all` | all: each later group against each earlier one, in the order of ORDER; or the pairs separated by #, one pair per line, the group first, then the group it is compared with (a value with a blank or a hyphen in quotes): "Drug" "Placebo" # "High" "Low". The form "A"-"B" of version 1.0 is still read. |
| `order` |  | A numeric variable with one value per group: the order of the groups |
| `measure` | `rd` | rd (default), rr or or |
| `ci` | `wald` | The interval of a risk difference: wald (default), newcombe, miettinen-nurminen (CL=MN), agresti-caffo (CL=AC); with strata: mh |
| `level` | `0.95` | The confidence level (default 0.95) |
| `stats` |  | The statistics, each with its pattern (default rd="X.XXX" lcl="X.XXX" ucl="X.XXX" pval="X.XXX"; with measure=rr or or: rr= or or= "XX.XX") |
| `label` |  | The label of the block in a table, in quotes |
| `out` | **required** | The result |
| `debug` | `no` | yes: keep the work data sets of the macro (_risk_*) |

```sas
%risk(
    data  = adrs
  , where = (paramcd = 'BOR')
  , var   = crit1fl
  , event = "Y"
  , by    = trt01p
  , order = trt01pn
  , ci    = newcombe
  , out   = resp_rd
)
%risk(
    data   = adae
  , var    = aoccfl
  , event  = "Y"
  , by     = trt01a
  , within = aebodsys aedecod
  , pairs  = "Drug" "Placebo"
  , ci     = newcombe
  , out    = ae_rd
)
```

**Output:** OUT: one row per pair and statistic (BY: the group, VERSUS: the group it is compared with, and WITHIN); GROUPS is BY VERSUS WITHIN.

### %scatterplot

<a id="scatterplot"></a>

The values of two variables against each other (a shift plot of baseline and post baseline values, two measures of a subject), one colour and marker per group; with fit=linear the least squares line of each group (its slope, intercept and R-square in out=), with fit=loess the loess curve of SGPLOT (its smoothing chosen by SGPLOT, not in out=); identity=yes the line y = x. One panel per value of panel=.

**Procedure:** PROC REG, PROC SGPANEL  
**Proven:** its known answer in tools/figures_sas.ts (the points, and the slope, intercept and R-square worked out by hand); not yet run on a SAS server  
**File:** `sas/macros/scatterplot.sas` (16NOV2026)

| Parameter | Default | It is |
|---|---|---|
| `data` | **required** | The records |
| `plot` |  | Draw again: an out= of %scatterplot, not with data= |
| `par` |  | The drawing parameters: an outpar= of %scatterplot |
| `columns` |  | The columns of %columns: the order of the groups and their colours (default: the order of the data) |
| `where` |  | The records to use, a condition in parentheses |
| `x` | **required** | The variable of the x axis (BASE) |
| `y` | **required** | The variable of the y axis (AVAL) |
| `by` | **required** | The groups: one colour and marker each |
| `panel` |  | One panel per value of this variable |
| `fit` | `none` | none, linear (a line per group) or loess |
| `identity` | `no` | yes: the line y = x |
| `xlabel` |  | The label of the x axis (default: the label of x) |
| `ylabel` |  | The label of the y axis (default: the label of y) |
| `ref` |  | Reference lines on the y axis: values |
| `file` | **required** | The output without its extension: <file>.png (300 dpi) and <file>.rtf |
| `width` | `6.5in` | The width of the figure |
| `height` | `4.5in` | The height of the figure |
| `out` |  | The numbers drawn |
| `outpar` |  | The drawing parameters: one row each |
| `debug` | `no` | yes: keep the work data sets _scatterplot_* |

```sas
%scatterplot(
    data     = adlbc
  , columns  = t14_6_cols
  , where    = (paramcd = 'ALT' AND avisitn = 24)
  , x        = base
  , y        = aval
  , by       = trta
  , identity = yes
  , file     = &spl_out./figures/f14_6_2
  , out      = f14_6_2
)
```

**Output:** OUT: PANEL and BY, KIND, X, Y; KIND point: one row per value; with fit=linear KIND fit: one row per group with SLOPE, INTERCEPT, RSQUARE and N (X and Y missing). OUTPAR: one row per drawing parameter in the order of the table: PARAMETER ($32) its name, VALUE ($500) its value as drawn (a label in quotes). FILE: <file>.png and <file>.rtf.

### %stack

<a id="stack"></a>

Put results one under another: the blocks of a table, in the order given.

**Procedure:** a DATA step (SET INDSNAME=)  
**Proven:** the tables of the dummy study SYNHTN01 (sapling sas run: SAS RUN PASS; sapling sas check: SAS CHECK PASS, 570 of 570 numbers of R the same in SAS); ran on SAS 9.4 M9, 2026-11-12  
**File:** `sas/macros/stack.sas` (16NOV2026)

| Parameter | Default | It is |
|---|---|---|
| `results` | **required** | The results (of %describe, %freq, a test or a model, or a DATA step of your own in the same shape), separated by blanks |
| `out` | **required** | The table |

```sas
%stack(
    age sex race
  , out = t14_2_01
)
```

**Output:** OUT: all rows, with RESULT (the name of the result each row comes from) and ORD (its place in the list: 1, 2, ...; a result without a row keeps its number, and a result named twice has the place of its first name). %layout lays the blocks out in this order. Each variable has the longest length it has in the results: no text is cut.

### %study

<a id="study"></a>

Start a program: the ADaM library (read only), the output folder and the name of the program (in the footnote of each output), the options of the outputs.

**Procedure:** LIBNAME, OPTIONS  
**Proven:** every program of the dummy study SYNHTN01 (sapling sas run: SAS RUN PASS; sapling sas check: SAS CHECK PASS, 570 of 570 numbers of R the same in SAS); ran on SAS 9.4 M9, 2026-11-12  
**File:** `sas/macros/study.sas` (16NOV2026)

| Parameter | Default | It is |
|---|---|---|
| `id` | **required** | The study (first, without a keyword) |
| `program` | **required** | The name of this program: its outputs are named after it |
| `adam` | `&spl_root./adam` | The folder of the ADaM data sets (default &spl_root./adam) |
| `out` | `&spl_root./out` | The output folder, with the folders tlf, listings, figures and ard (default &spl_root./out) |

```sas
%study(
    CDISCPILOT01
  , program = t14_2_01
)
```

**Output:** CODE: the population and the records in DATA steps, the statistics macros (%describe, %freq, %ancova, ...), then %stack and %print (a figure: its figure macro).

### %summarize

<a id="summarize"></a>

Give each subject a summary of its records in another data set: the sum or the mean of a variable. A subject without a record gets a missing value; a sum of only missing values is missing.

**Procedure:** PROC SUMMARY, MERGE  
**Proven:** the fixtures of the step kind derive.from.summary (src/adam_steps.ts; node tools/adam_steps_sas.ts); ran on SAS 9.4 M9, 2026-11-12  
**File:** `sas/macros/summarize.sas` (16NOV2026)

| Parameter | Default | It is |
|---|---|---|
| `data` | **required** | The working data set (changed in place) |
| `from` | **required** | The data set of the records (prepare the value with a DATA step) |
| `value` | **required** | The variable of FROM to summarize. To count records, give a 0/1 variable and stat=sum; for "some record meets it" stat=max, for "every record meets it" stat=min. |
| `stat` | `sum` | sum (default), mean, max or min |
| `new` | **required** | The variable to make |
| `debug` | `no` | yes: keep the work data sets _summarize_* |

```sas
%summarize(
    data  = adsl
  , from  = ex
  , value = dose_days
  , stat  = sum
  , new   = cumdose
)
```

**Output:** DATA: NEW on every row of a subject: the sum, mean, maximum or minimum of VALUE over its records in FROM; missing for a subject without a record.

### %summarize_groups

<a id="summarizegroups"></a>

One record per group of BY with a summary of each variable of VARS over the records of the group: the sum, the mean, the largest or the smallest value (a missing value of a BY variable is a group of its own). A group without records has no record.

**Procedure:** PROC SUMMARY  
**Proven:** the fixtures of the step kind parameter (src/adam_steps.ts; node tools/adam_steps_sas.ts); ran on SAS 9.4 M9, 2026-11-12  
**File:** `sas/macros/summarize_groups.sas` (16NOV2026)

| Parameter | Default | It is |
|---|---|---|
| `data` | **required** | The records (prepare the values with a DATA step; a condition as 0 or 1) |
| `by` | **required** | The groups |
| `vars` | **required** | The variables to summarize |
| `stats` | **required** | One statistic per variable, in the same order: sum, mean, max or min. A sum or a mean of only missing values is missing. |
| `out` | **required** | One record per group: the BY variables and VARS (their summaries) |

```sas
%summarize_groups(
    data  = _recs
  , by    = usubjid avisit
  , vars  = _s1 _s2
  , stats = max sum
  , out   = _sums
)
```

**Output:** OUT: one record per group of BY with the summary of each variable of VARS (under its own name).

### %table

<a id="table"></a>

A table in one call: %columns, %ard (only with file=: the numbers file belongs to an output), %layout and %print, in that order, with the same parameters as the separate calls; it holds no logic of its own. It leaves the columns <data>_cols and the display data set OUT; with setup= also the global macro variable that %print(&name.) prints from, for a second print after a change of OUT. Without file= it prints nothing: change OUT, then %print(&name., file=...).

**Procedure:** none of its own (those of %columns, %ard, %layout, %print)  
**Proven:** its cases of node tools/print_sas.ts (the same .lst and the same numbers file as the separate calls); ran on SAS 9.4 M9, 2026-11-12  
**File:** `sas/macros/table.sas` (16NOV2026)

| Parameter | Default | It is |
|---|---|---|
| `data` | **required** | The results (%stack) |
| `n` |  | The population, one row per subject: the N of each column (n= of %columns) |
| `var` | **required** | The column variable of the results |
| `order` |  | Its numeric twin in N= (TRT01AN): the order of the columns |
| `total` | `no` | yes: the results have the group Total (total= of %columns) |
| `format` |  | The labels of categories: variable and format, as in a FORMAT statement (format= of %layout) |
| `label` |  | Column labels: name="text" pairs (label= of %print) |
| `rows` | `40` | The rows of a page, for the rows of one level |
| `file` |  | The output without its extension: <file>.rtf, <file>.lst and the numbers file <out>/ard/<last part of file>.csv (blank: nothing is printed) |
| `nodata` |  | The text printed when there is no row |
| `setup` |  | The name of a global macro variable that keeps the %print call of OUT (blank: none is left) |
| `out` |  | The display data set (default: <data>_display) |
| `debug` | `no` | yes: keep the work data sets of the macros it calls |

```sas
%table(
    data  = t14_2_1
  , n     = adsl
  , var   = trt01a
  , order = trt01an
  , total = yes
  , file  = &spl_out./tlf/t14_2_1
  , setup = t14_2_1_print
)
```

**Output:** OUT: the display data set of %layout; DATA: <data>_cols, the columns of %columns; FILE: <file>.rtf and <file>.lst of %print and the numbers file of %ard (with file=); SETUP: with setup=, the global macro variable of that name with the parameters of %print for OUT.

### %table_ae

<a id="tableae"></a>

A table of adverse events (or other occurrences) in one call: the subjects with a record in each level of var= (system organ class, preferred term), with their percent of the population. The macro writes the long program of the table (the population, the records, one %freq, %stack, %table) and runs it; it computes nothing itself. The result <name>_ae, the table <name>, <name>_cols and <name>_display stay, and the setup <name>_print. show= gives the long program.

**Procedure:** none of its own (those of %freq, %table)  
**Proven:** node tools/tables_sas.ts (the same display data set as the long program, on the made-up study SYNHTN01); ran on SAS 9.4 M9, 2026-11-13  
**File:** `sas/macros/table_ae.sas` (16NOV2026)

| Parameter | Default | It is |
|---|---|---|
| `data` | **required** | The records (a data set with USUBJID) |
| `adsl` |  | The subjects, one row per subject: the population and the N of the columns; its variables go to the records (blank: the records have all they need) |
| `pop` |  | The population: a condition on adsl= in parentheses |
| `where` |  | The records to use: a condition in parentheses |
| `var` | **required** | The levels of the rows: variables, nested in their order (aebodsys aedecod) |
| `by` | **required** | The groups: a character variable, the columns |
| `order` |  | Its numeric twin (TRT01AN): the order of columns |
| `sort` |  | frequency: the rows by their subjects (order= of %freq); blank: by their names |
| `threshold` |  | A percent: only the rows that reach it in a group |
| `total` | `no` | yes: also all groups together, as Total |
| `format` |  | The labels of categories: variable and format, as in a FORMAT statement (format= of %layout) |
| `name` |  | The name of the table: the first part of the names of its data sets (default: the last part of file=) |
| `show` | `no` | yes: the long program in the log; a file: the long program is written there (and run) |
| `label` |  | The label of the block, in quotes |
| `stats` |  | The statistics, each with its pattern (stats= of %freq) |
| `title` |  | The titles of the table: a text in quotes for each line (TITLE1, TITLE2 ...); blank: the TITLE statements of the program |
| `footnote` |  | The footnotes: a text in quotes for each line (FOOTNOTE1 ...); blank: those of the program |
| `file` |  | The output without its extension: <file>.rtf, <file>.lst and the numbers file (blank: no print) |
| `debug` | `no` | yes: keep the work data sets of the macros called |

```sas
%table_ae(
    data  = adam.adae
  , adsl  = adam.adsl
  , pop   = (saffl = 'Y')
  , where = (trtemfl = 'Y')
  , var   = aebodsys aedecod
  , by    = trt01a
  , order = trt01an
  , sort  = frequency
  , label = "Treatment-emergent adverse events"
  , file  = &spl_out./tlf/t14_5_2
)
```

**Output:** DATA: <name>_ae (the result), <name> (the table), <name>_cols, <name>_display, <name>_pop and <name>_rec; FILE: <file>.rtf, <file>.lst and the numbers file (with file=); SETUP: the global macro variable <name>_print; SHOW: the long program.

### %table_model

<a id="tablemodel"></a>

A table of a continuous endpoint in one call: the descriptive statistics of the variables of describe= at the visit of at=, then the LS means and the differences of pairs of groups from an ANCOVA (%lsmeans, method=ancova) or from a mixed model for repeated measures over all visits (%mmrm, method=mmrm). The macro writes the long program of the table and runs it; it computes nothing itself. The results <name>_<variable> and <name>_ancova or <name>_mmrm, the table <name>, <name>_cols and <name>_display stay, and the setup <name>_print. show= gives the long program.

**Procedure:** none of its own (those of %describe, %lsmeans, %mmrm, %table)  
**Proven:** node tools/tables_sas.ts (the same display data set as the long program, on the made-up study SYNHTN01); ran on SAS 9.4 M9, 2026-11-13  
**File:** `sas/macros/table_model.sas` (16NOV2026)

| Parameter | Default | It is |
|---|---|---|
| `data` | **required** | The records (a data set with USUBJID) |
| `adsl` |  | The subjects, one row per subject: the population and the N of the columns; its variables go to the records (blank: the records have all they need) |
| `pop` |  | The population: a condition on adsl= in parentheses |
| `where` |  | The records to use: a condition in parentheses |
| `var` | `CHG` | The response |
| `covars` |  | The covariates of the model (base) |
| `visit` | `AVISIT` | The visit |
| `by` | **required** | The groups: a character variable, the columns |
| `at` |  | The visit of the table, in quotes ("Week 12"): the records of the descriptive blocks and the ANCOVA, the visit of the LS means of the MMRM |
| `order` |  | Its numeric twin (TRT01AN): the order of columns |
| `describe` |  | Variables with a descriptive block before the model (base aval chg) |
| `method` | `ancova` | ancova (%lsmeans) or mmrm (%mmrm; at= is required) |
| `model` |  | The fixed effects of the MMRM (default: covars= by= visit= by=*visit=) |
| `type` | `un` | The covariance structure of the MMRM |
| `fallback` |  | Other structures to try, in their order |
| `pairs` |  | The pairs compared: each group, then the group it is compared with, in quotes (blank: all pairs) |
| `names` |  | The label of a block when it is not the label of the variable: chg="Change from baseline" |
| `format` |  | The labels of categories: variable and format, as in a FORMAT statement (format= of %layout) |
| `name` |  | The name of the table: the first part of the names of its data sets (default: the last part of file=) |
| `show` | `no` | yes: the long program in the log; a file: the long program is written there (and run) |
| `stats` |  | The statistics of the model, each with its pattern (default: the LS means, their difference with its SE and limits, the p-value) |
| `title` |  | The titles of the table: a text in quotes for each line (TITLE1, TITLE2 ...); blank: the TITLE statements of the program |
| `footnote` |  | The footnotes: a text in quotes for each line (FOOTNOTE1 ...); blank: those of the program |
| `file` |  | The output without its extension: <file>.rtf, <file>.lst and the numbers file (blank: no print) |
| `debug` | `no` | yes: keep the work data sets of the macros called |

```sas
%table_model(
    data     = advs
  , where    = (paramcd = 'SYSBP' AND anl01fl = 'Y' AND avisitn > 0)
  , covars   = base
  , at       = "Week 12"
  , describe = base aval chg
  , by       = trtp
  , order    = trtpn
  , pairs    = "Drug X 10 mg" "Placebo"
  , file     = &spl_out./tlf/t14_3_1
)
```

**Output:** DATA: <name>_<variable> (the descriptive results), <name>_ancova or <name>_mmrm, <name> (the table), <name>_cols, <name>_display, <name>_at with at=, and <name>_pop and <name>_rec with adsl= or where=; FILE: <file>.rtf, <file>.lst and the numbers file (with file=); SETUP: the global macro variable <name>_print; SHOW: the long program.

### %table_response

<a id="tableresponse"></a>

A table of a binary response in one call: the subjects with the event and their percent with its interval in each group (%proportion), the comparison of pairs of groups (%risk: risk difference, relative risk or odds ratio, with its test), and with covars= the odds ratio adjusted for them (%logistic). The macro writes the long program of the table and runs it; it computes nothing itself. The results <name>_prop, <name>_<measure> and <name>_adj, the table <name>, <name>_cols and <name>_display stay, and the setup <name>_print. show= gives the long program.

**Procedure:** none of its own (those of %proportion, %risk, %logistic, %table)  
**Proven:** node tools/tables_sas.ts (the same display data set as the long program, on the made-up study SYNHTN01); ran on SAS 9.4 M9, 2026-11-13  
**File:** `sas/macros/table_response.sas` (16NOV2026)

| Parameter | Default | It is |
|---|---|---|
| `data` | **required** | The records (a data set with USUBJID) |
| `adsl` |  | The subjects, one row per subject: the population and the N of the columns; its variables go to the records (blank: the records have all they need) |
| `pop` |  | The population: a condition on adsl= in parentheses |
| `where` |  | The records to use: a condition in parentheses |
| `var` | **required** | The response: a variable with two values |
| `event` | `"Y"` | The value that is the event, in quotes |
| `by` | **required** | The groups: a character variable, the columns |
| `covars` |  | Covariates: also the odds ratio adjusted for them (%logistic) |
| `order` |  | Its numeric twin (TRT01AN): the order of columns |
| `pairs` |  | The pairs compared: each group, then the group it is compared with, in quotes; # between pairs (blank: all pairs) |
| `ci` | `clopper-pearson` | The interval of the percent (ci= of %proportion) |
| `measure` | `rd` | rd, rr or or: the comparison of %risk; none: no comparison |
| `diffci` | `wald` | The interval of a risk difference (ci= of %risk) |
| `format` |  | The labels of categories: variable and format, as in a FORMAT statement (format= of %layout) |
| `name` |  | The name of the table: the first part of the names of its data sets (default: the last part of file=) |
| `show` | `no` | yes: the long program in the log; a file: the long program is written there (and run) |
| `title` |  | The titles of the table: a text in quotes for each line (TITLE1, TITLE2 ...); blank: the TITLE statements of the program |
| `footnote` |  | The footnotes: a text in quotes for each line (FOOTNOTE1 ...); blank: those of the program |
| `file` |  | The output without its extension: <file>.rtf, <file>.lst and the numbers file (blank: no print) |
| `debug` | `no` | yes: keep the work data sets of the macros called |

```sas
%table_response(
    data   = adrs
  , var    = avalc
  , by     = trtp
  , order  = trtpn
  , pairs  = "Drug X 10 mg" "Placebo"
  , diffci = newcombe
  , covars = base
  , file   = &spl_out./tlf/t14_3_2
)
```

**Output:** DATA: <name>_prop, <name>_<measure> and <name>_adj (the results), <name> (the table), <name>_cols, <name>_display, and <name>_pop and <name>_rec with adsl= or where=; FILE: <file>.rtf, <file>.lst and the numbers file (with file=); SETUP: the global macro variable <name>_print; SHOW: the long program.

### %table_shift

<a id="tableshift"></a>

A shift table in one call: the subjects in each pair of categories, the category at baseline against the category after it (the two variables of var=), within the levels of within= (parameter, visit). The macro writes the long program of the table (the population, the records, one %freq, %stack, %table) and runs it; it computes nothing itself. The result <name>_shift, the table <name>, <name>_cols and <name>_display stay, and the setup <name>_print. show= gives the long program.

**Procedure:** none of its own (those of %freq, %table)  
**Proven:** node tools/tables_sas.ts (the same display data set as the long program, on the made-up study SYNHTN01); ran on SAS 9.4 M9, 2026-11-13  
**File:** `sas/macros/table_shift.sas` (16NOV2026)

| Parameter | Default | It is |
|---|---|---|
| `data` | **required** | The records (a data set with USUBJID) |
| `adsl` |  | The subjects, one row per subject: the population and the N of the columns; its variables go to the records (blank: the records have all they need) |
| `pop` |  | The population: a condition on adsl= in parentheses |
| `where` |  | The records to use: a condition in parentheses |
| `var` | `BNRIND ANRIND` | Two variables: the category at baseline, then the category after it |
| `within` |  | The levels above them (paramcd avisit) |
| `by` | **required** | The groups: a character variable, the columns |
| `keep` |  | Variables kept for the names and the order of the rows (param avisitn) |
| `order` |  | Its numeric twin (TRT01AN): the order of columns |
| `levels` |  | The planned categories of both variables, in quotes ('LOW' 'NORMAL' 'HIGH'): each is a row also without a subject |
| `total` | `no` | yes: also all groups together, as Total |
| `format` |  | The labels of categories: variable and format, as in a FORMAT statement (format= of %layout) |
| `name` |  | The name of the table: the first part of the names of its data sets (default: the last part of file=) |
| `show` | `no` | yes: the long program in the log; a file: the long program is written there (and run) |
| `label` |  | The label of the block, in quotes |
| `stats` |  | The statistics, each with its pattern (stats= of %freq) |
| `title` |  | The titles of the table: a text in quotes for each line (TITLE1, TITLE2 ...); blank: the TITLE statements of the program |
| `footnote` |  | The footnotes: a text in quotes for each line (FOOTNOTE1 ...); blank: those of the program |
| `file` |  | The output without its extension: <file>.rtf, <file>.lst and the numbers file (blank: no print) |
| `debug` | `no` | yes: keep the work data sets of the macros called |

```sas
%table_shift(
    data   = adlbc
  , where  = (anl01fl = 'Y' AND avisitn > 0)
  , within = paramcd avisit
  , levels = 'LOW' 'NORMAL' 'HIGH'
  , by     = trt01a
  , order  = trt01an
  , file   = &spl_out./tlf/t14_8_1
)
```

**Output:** DATA: <name>_shift (the result), <name> (the table), <name>_cols, <name>_display, and <name>_pop and <name>_rec with adsl= or where=; FILE: <file>.rtf, <file>.lst and the numbers file (with file=); SETUP: the global macro variable <name>_print; SHOW: the long program.

### %table_summary

<a id="tablesummary"></a>

A summary table (demographics, baseline) in one call: you name the variables, with # after a categorical one. The macro writes the long program of the table (the population, one %describe per continuous variable, one %freq per categorical variable, %stack, %table) and runs it; it computes nothing itself. The results <name>_<variable>_summ, the table <name>, the columns <name>_cols and the display data set <name>_display stay, and the setup <name>_print, for a change and a second %print. show= gives the long program, to read it or to go on from it by hand.

**Procedure:** none of its own (those of %describe, %freq, %table)  
**Proven:** its cases of node tools/print_sas.ts (the same .lst and the same numbers file as the long program); ran on SAS 9.4 M9, 2026-11-13  
**File:** `sas/macros/table_summary.sas` (16NOV2026)

| Parameter | Default | It is |
|---|---|---|
| `data` | **required** | The subjects, one row per subject (ADSL) |
| `where` |  | The population: a condition in parentheses |
| `vars` | **required** | The variables in the order of the table. A name: continuous (%describe). A name and #: categorical (%freq), sex#. A name, # and a numeric variable: the categories in the order of that variable, agegr1#agegr1n |
| `by` | **required** | The groups: a character variable, the columns |
| `order` |  | Its numeric twin (TRT01AN): the order of columns |
| `levels` |  | The planned categories of some variables: a variable, its values (levels= of %freq) |
| `total` | `no` | yes: also all groups together, as Total |
| `catstats` |  | The statistics of a categorical variable (stats= of %freq) |
| `names` |  | The label of a block when it is not the label of the variable: age="Age (years)" sex="Sex" |
| `format` |  | The labels of categories: variable and format, as in a FORMAT statement (format= of %layout) |
| `name` |  | The name of the table: the first part of the names of its data sets (default: the last part of file=) |
| `show` | `no` | yes: the long program in the log; a file: the long program is written there (and run) |
| `stats` |  | The statistics of a continuous variable, each with its pattern (stats= of %describe) |
| `title` |  | The titles of the table: a text in quotes for each line (TITLE1, TITLE2 ...); blank: the TITLE statements of the program |
| `footnote` |  | The footnotes: a text in quotes for each line (FOOTNOTE1 ...); blank: those of the program |
| `file` |  | The output without its extension: <file>.rtf, <file>.lst and the numbers file (blank: nothing is printed) |
| `debug` | `no` | yes: keep the work data sets of the macros called |

```sas
%table_summary(
    data  = adsl
  , where = (saffl = 'Y')
  , vars  = age agegr1#agegr1n sex# race# ethnic#
  , by    = trt01a
  , order = trt01an
  , total = yes
  , file  = &spl_out./tlf/t14_2_1
)
```

**Output:** DATA: <name>_<variable>_summ (one result per variable), <name> (the table), <name>_cols, <name>_display, and <name>_pop with where=; FILE: <file>.rtf, <file>.lst and the numbers file (with file=); SETUP: the global macro variable <name>_print for %print(&<name>_print.); SHOW: the long program.

### %table_tte

<a id="tablette"></a>

A time-to-event table in one call: the Kaplan-Meier summary of each group (%km), the log-rank test (%logrank) and the hazard ratio of pairs of groups from a Cox model (%cox). The macro writes the long program of the table and runs it; it computes nothing itself. The results <name>_km (<name>_surv with time=), <name>_lr and <name>_cox, the table <name>, <name>_cols and <name>_display stay, and the setup <name>_print. show= gives the long program.

**Procedure:** none of its own (those of %km, %logrank, %cox, %table)  
**Proven:** node tools/tables_sas.ts (the same display data set as the long program, on the made-up study SYNHTN01); ran on SAS 9.4 M9, 2026-11-13  
**File:** `sas/macros/table_tte.sas` (16NOV2026)

| Parameter | Default | It is |
|---|---|---|
| `data` | **required** | The records (a data set with USUBJID) |
| `adsl` |  | The subjects, one row per subject: the population and the N of the columns; its variables go to the records (blank: the records have all they need) |
| `pop` |  | The population: a condition on adsl= in parentheses |
| `where` |  | The records to use: a condition in parentheses |
| `var` | `AVAL` | The time |
| `cnsr` | `CNSR` | The censoring variable: 1 is censored |
| `by` | **required** | The groups: a character variable, the columns |
| `time` |  | A time: also the percent without an event at it and its limits, a block of its own (<name>_surv, time= of %km); the median keeps its own limits |
| `strata` |  | The strata of the log-rank test and the Cox model |
| `order` |  | Its numeric twin (TRT01AN): the order of columns |
| `pairs` |  | The pairs of the hazard ratio: each group, then its comparator, in quotes (blank: all pairs) |
| `format` |  | The labels of categories: variable and format, as in a FORMAT statement (format= of %layout) |
| `name` |  | The name of the table: the first part of the names of its data sets (default: the last part of file=) |
| `show` | `no` | yes: the long program in the log; a file: the long program is written there (and run) |
| `title` |  | The titles of the table: a text in quotes for each line (TITLE1, TITLE2 ...); blank: the TITLE statements of the program |
| `footnote` |  | The footnotes: a text in quotes for each line (FOOTNOTE1 ...); blank: those of the program |
| `file` |  | The output without its extension: <file>.rtf, <file>.lst and the numbers file (blank: no print) |
| `debug` | `no` | yes: keep the work data sets of the macros called |

```sas
%table_tte(
    data  = adam.adtte
  , adsl  = adam.adsl
  , pop   = (saffl = 'Y')
  , where = (paramcd = 'TTAE')
  , by    = trt01a
  , order = trt01an
  , pairs = "Drug X 10 mg" "Placebo"
  , file  = &spl_out./tlf/t14_6_1
)
```

**Output:** DATA: <name>_km, <name>_surv (with time=), <name>_lr and <name>_cox (the results), <name> (the table), <name>_cols, <name>_display, <name>_pop and <name>_rec; FILE: <file>.rtf, <file>.lst and the numbers file (with file=); SETUP: the global macro variable <name>_print; SHOW: the long program.

### %table_visit

<a id="tablevisit"></a>

A table by visit in one call (vital signs, laboratory values): the descriptive statistics of each variable of vars= in each group, parameter and visit. The macro writes the long program of the table (the population, the records, one %describe per variable, %stack, %table) and runs it; it computes nothing itself. The results <name>_<variable>, the table <name>, <name>_cols and <name>_display stay, and the setup <name>_print. show= gives the long program.

**Procedure:** none of its own (those of %describe, %table)  
**Proven:** node tools/tables_sas.ts (the same display data set as the long program, on the made-up study SYNHTN01); ran on SAS 9.4 M9, 2026-11-13  
**File:** `sas/macros/table_visit.sas` (16NOV2026)

| Parameter | Default | It is |
|---|---|---|
| `data` | **required** | The records (a data set with USUBJID) |
| `adsl` |  | The subjects, one row per subject: the population and the N of the columns; its variables go to the records (blank: the records have all they need) |
| `pop` |  | The population: a condition on adsl= in parentheses |
| `where` |  | The records to use: a condition in parentheses |
| `vars` | **required** | The variables: a block of each (aval chg) |
| `by` | **required** | The groups: a character variable, the columns |
| `param` | `PARAMCD` | The parameter |
| `visit` | `AVISIT` | The visit |
| `keep` |  | Variables kept for the names and the order of the rows (param paramn avisitn) |
| `order` |  | Its numeric twin (TRT01AN): the order of columns |
| `post` |  | The variables of vars= whose block has only the records of postwhere= (chg) |
| `postwhere` | `(ablfl NE 'Y')` | The records after baseline: a condition in parentheses |
| `names` |  | The label of a block when it is not the label of the variable: chg="Change from baseline" |
| `total` | `no` | yes: also all groups together, as Total |
| `format` |  | The labels of categories: variable and format, as in a FORMAT statement (format= of %layout) |
| `name` |  | The name of the table: the first part of the names of its data sets (default: the last part of file=) |
| `show` | `no` | yes: the long program in the log; a file: the long program is written there (and run) |
| `stats` |  | The statistics, each with its pattern (stats= of %describe) |
| `title` |  | The titles of the table: a text in quotes for each line (TITLE1, TITLE2 ...); blank: the TITLE statements of the program |
| `footnote` |  | The footnotes: a text in quotes for each line (FOOTNOTE1 ...); blank: those of the program |
| `file` |  | The output without its extension: <file>.rtf, <file>.lst and the numbers file (blank: no print) |
| `debug` | `no` | yes: keep the work data sets of the macros called |

```sas
%table_visit(
    data  = adam.advs
  , adsl  = adam.adsl
  , pop   = (saffl = 'Y')
  , where = (anl01fl = 'Y')
  , vars  = aval chg
  , by    = trt01a
  , order = trt01an
  , keep  = param paramn avisitn
  , post  = chg
  , file  = &spl_out./tlf/t14_7_1
)
```

**Output:** DATA: <name>_<variable> (one result per variable), <name> (the table), <name>_cols, <name>_display, <name>_pop and <name>_rec; FILE: <file>.rtf, <file>.lst and the numbers file (with file=); SETUP: the global macro variable <name>_print; SHOW: the long program.

### %termflags

<a id="termflags"></a>

The flag of each row of occurrence data for every subject: one record per subject of DENOM (with its group BY) and per term (each combination of TERMS in the records), FLAG "Y" when the subject has a record of the term and "N" when not. With threshold= only the terms whose percent of the subjects of a group reaches it in at least one group. It computes no statistic: %risk then compares the groups on FLAG within each term (within=TERMS), one record per subject, the subjects of the group the denominator.

**Procedure:** PROC SORT, MERGE, PROC SUMMARY  
**Proven:** the known answer of the method perterm (src/methods.ts, worked out by tools/method_answers.R; node tools/methods_sas.ts); ran on SAS 9.4 M9, 2026-11-12  
**File:** `sas/macros/termflags.sas` (16NOV2026)

| Parameter | Default | It is |
|---|---|---|
| `data` | **required** | The records (the events) |
| `denom` | **required** | The subjects of the groups: one row per subject (the population) |
| `where` |  | The records to use, a condition in parentheses |
| `terms` |  | The variables of a row (a term within its class); none: one row of all the records (a row of an overview: any event, a serious event) |
| `by` | **required** | The groups: a variable of DENOM |
| `threshold` |  | A percent: only the terms with this percent of the subjects of a group or more, in at least one group (the percent itself, not its rounded text) |
| `out` | **required** | The result: USUBJID, BY, TERMS and FLAG, sorted by TERMS and USUBJID |
| `debug` | `no` | yes: keep the work data sets of the macro (_termflags_*) |

```sas
%termflags(
    data      = adae
  , denom     = adsl
  , where     = (trtemfl = 'Y')
  , terms     = aebodsys aedecod
  , by        = trt01a
  , threshold = 5
  , out       = ae_flags
)
```

**Output:** OUT: one record per subject and term.

### %tte

<a id="tte"></a>

One time-to-event parameter in one call: for each subject the first event, else the latest censoring. With end= an at-risk period from START to END: only the events and censorings in it count, else the subject is censored at the end of the period.

**Procedure:** PROC SORT, MERGE  
**Proven:** the fixtures of the step kinds tte and tte.period (src/adam_steps.ts; node tools/adam_steps_sas.ts); ran on SAS 9.4 M9, 2026-11-12  
**File:** `sas/macros/tte.sas` (16NOV2026)

| Parameter | Default | It is |
|---|---|---|
| `subjects` | **required** | One record per subject (USUBJID) with START (and END). The result keeps its variables: it must not have ADT, CNSR, AVAL or the values below. |
| `events` | **required** | The records the events come from: a data set |
| `censors` |  | The records of the censorings: the latest date in the period (on one date the last record). Default: SUBJECTS. |
| `event` |  | Which records of EVENTS are events: a condition. Default: all. |
| `date` | **required** | The date of an event, a variable of EVENTS (missing: no event) |
| `time` |  | The time of an event (seconds since midnight), a variable of EVENTS, for the start day |
| `priority` |  | Variables of EVENTS that order the events of one date (a missing value last). Default: the order of the data. |
| `start` | **required** | The start of the period and the origin of AVAL, a date of SUBJECTS |
| `start_time` |  | The time of the start, of SUBJECTS: on the start day an event counts unless both times are there and the event time is before it |
| `end` |  | The end of the at-risk period, a date of SUBJECTS. Without END: no period, every date counts, a date before START is START (as admiral). |
| `censor_date` |  | The date of a censoring, of CENSORS (or of SUBJECTS) |
| `seq` |  | SRCSEQ of an event: a variable of EVENTS. Default: missing. |
| `adtf` |  | ADTF of an event: the flag of its date, a variable of EVENTS |
| `atmf` |  | ATMF of an event: the flag of its time, a variable of EVENTS |
| `keep` |  | Other variables of the record taken, in EVENTS and CENSORS both (the values of the rows that the program stacked before the call) |
| `censor_cnsr` | `1` | CNSR of a censoring: a number, or a variable of CENSORS |
| `end_cnsr` | `1` | CNSR at the end of the period |
| `censor_desc` |  | EVNTDESC of a censoring: a text in quotes, or a variable |
| `censor_source` |  | SRCDOM of a censoring of SUBJECTS and of the end of the period, in quotes; SRCVAR is then the name of CENSOR_DATE (of END) |
| `end_desc` | `"End of at-risk period"` | EVNTDESC at the end of the period |
| `event_desc` |  | EVNTDESC of an event: a text in quotes, or a variable of EVENTS |
| `source` |  | SRCDOM of an event, in quotes; SRCVAR is then the name of DATE |
| `paramcd` | **required** | PARAMCD, in quotes |
| `out` | **required** | The result (see Output) |
| `debug` | `no` | yes: keep the work data sets _tte_* |

```sas
%tte(
    subjects      = work.adsl
  , events        = adam.adlb
  , event         = paramcd IN ('ALT', 'AST') AND r2a1hi >= 3
  , date          = adt
  , priority      = paramcd
  , start         = trtsdt
  , end           = dcutdt
  , censor_date   = dcutdt
  , seq           = aseq
  , censor_desc   = "Cutoff date"
  , censor_source = "ADSL"
  , event_desc    = "ALT/AST >= 3x ULN"
  , source        = "ADLB"
  , paramcd       = "DIL3X"
  , out           = work.dil3x
)
```

**Output:** OUT: one record per subject with an event, a censoring or (with end=) a period: the variables of SUBJECTS, PARAMCD, ADT, CNSR, AVAL (ADT - START + 1), ATM (with time=) and the values above, in the order of SUBJECTS. With end= a subject without START or without END gets no record and a WARNING that names it (USUBJID=); a subject whose START is after its END gets no record. Two records of a subject in SUBJECTS are an ERROR.

### %ttest

<a id="ttest"></a>

The two-sample t-test of each pair of groups, one record per subject (PROC TTEST, BY each pair, the group first): the difference of the means (diff: the group minus the group it is compared with), its standard error (diff_se), its confidence limits (lcl, ucl) and the two-sided p-value (pval): Student's with the pooled variance (variances=equal) or Welch's with Satterthwaite's df (variances=unequal).

**Procedure:** PROC TTEST  
**Proven:** the known answer of the method ttest (src/methods.ts, worked out by tools/method_answers.R; node tools/methods_sas.ts); ran on SAS 9.4 M9, 2026-11-12  
**File:** `sas/macros/ttest.sas` (16NOV2026)

| Parameter | Default | It is |
|---|---|---|
| `data` | **required** | The records |
| `where` |  | The records to use, a condition in parentheses |
| `var` | **required** | The variable |
| `by` | **required** | The groups: a character variable |
| `pairs` | `all` | all: each later group against each earlier one, in the order of ORDER; or the pairs separated by #, one pair per line, the group first, then the group it is compared with (a value with a blank or a hyphen in quotes): "Drug" "Placebo" # "High" "Low". The form "A"-"B" of version 1.0 is still read. |
| `order` |  | A numeric variable with one value per group: the order of the groups |
| `variances` | `equal` | equal (default: the Pooled row) or unequal (the Satterthwaite row) |
| `level` | `0.95` | The confidence level (default 0.95) |
| `stats` | `diff="XX.X" diff_se="XX.XX" lcl="XX.X" ucl="XX.X" pval="X.XXX"` | The statistics, each with its pattern (default diff="XX.X" diff_se="XX.XX" lcl="XX.X" ucl="XX.X" pval="X.XXX") |
| `label` |  | The label of the block in a table, in quotes |
| `out` | **required** | The result |
| `debug` | `no` | yes: keep the work data sets of the macro (_ttest_*) |

```sas
%ttest(
    data  = advs
  , where = (paramcd = 'SYSBP' AND avisit = 'Week 12')
  , var   = chg
  , by    = trt01p
  , order = trt01pn
  , out   = sbp_t
)
```

**Output:** OUT: one row per pair and statistic (BY: the group, VERSUS: the group it is compared with); GROUPS is BY VERSUS.

### %visits

<a id="visits"></a>

Give each record its analysis visit by its visit: AVISIT and AVISITN. A record of a visit that is not in the list keeps them missing.

**Procedure:** DATA steps (SET POINT=)  
**Proven:** the fixtures of the step kind windows.visit (src/adam_steps.ts; node tools/adam_steps_sas.ts); ran on SAS 9.4 M9, 2026-11-12  
**File:** `sas/macros/visits.sas` (16NOV2026)

| Parameter | Default | It is |
|---|---|---|
| `data` | **required** | The working data set (changed in place) |
| `visits` | **required** | The visits, # between them; a visit is "VISIT" AVISITN "AVISIT" |

```sas
%visits(
    data   = adlb
  , visits = "SCREENING" 0 "Baseline"
           # "WEEK 2"    2 "Week 2"
)
```

**Output:** DATA: AVISIT and AVISITN on each record of a visit in the list; missing on the others.

### %wilcoxon

<a id="wilcoxon"></a>

The Wilcoxon rank-sum test of each pair of groups, one record per subject (PROC NPAR1WAY, BY each pair, the group first): the two-sided p-value of the normal approximation with the continuity correction (pval; CORRECT=), the Hodges-Lehmann estimate of the shift (estimate: the group minus the group it is compared with) and its asymptotic (Moses) confidence limits (lcl, ucl; HL).

**Procedure:** PROC NPAR1WAY (WILCOXON, HL)  
**Proven:** the known answer of the method wilcoxon (src/methods.ts, worked out by tools/method_answers.R; node tools/methods_sas.ts); ran on SAS 9.4 M9, 2026-11-12  
**File:** `sas/macros/wilcoxon.sas` (16NOV2026)

| Parameter | Default | It is |
|---|---|---|
| `data` | **required** | The records |
| `where` |  | The records to use, a condition in parentheses |
| `var` | **required** | The variable |
| `by` | **required** | The groups: a character variable |
| `pairs` | `all` | all: each later group against each earlier one, in the order of ORDER; or the pairs separated by #, one pair per line, the group first, then the group it is compared with (a value with a blank or a hyphen in quotes): "Drug" "Placebo" # "High" "Low". The form "A"-"B" of version 1.0 is still read. |
| `order` |  | A numeric variable with one value per group: the order of the groups |
| `correction` | `yes` | yes (default): the continuity correction of the test; no |
| `level` | `0.95` | The confidence level (default 0.95) |
| `stats` | `estimate="XX.XX" lcl="XX.XX" ucl="XX.XX" pval="X.XXX"` | The statistics, each with its pattern (default estimate="XX.XX" lcl="XX.XX" ucl="XX.XX" pval="X.XXX") |
| `label` |  | The label of the block in a table, in quotes |
| `out` | **required** | The result |
| `debug` | `no` | yes: keep the work data sets of the macro (_wilcoxon_*) |

```sas
%wilcoxon(
    data  = adqs
  , where = (paramcd = 'PAIN' AND avisit = 'Week 12')
  , var   = chg
  , by    = trt01p
  , order = trt01pn
  , out   = pain_w
)
```

**Output:** OUT: one row per pair and statistic (BY: the group, VERSUS: the group it is compared with); GROUPS is BY VERSUS.

### %windows

<a id="windows"></a>

Put each record in its analysis window by its study day: AVISIT, AVISITN, AWLO, AWHI, AWTARGET, AWRANGE, AWU (DAYS) and AWTDIFF (the distance to the target day). A record in no window keeps them missing. The first window (in the order of AVISITN) that holds the day is taken.

**Procedure:** DATA steps (SET POINT=)  
**Proven:** the fixtures of the step kind windows.day (src/adam_steps.ts; node tools/adam_steps_sas.ts); ran on SAS 9.4 M9, 2026-11-12  
**File:** `sas/macros/windows.sas` (16NOV2026)

| Parameter | Default | It is |
|---|---|---|
| `data` | **required** | The working data set (changed in place) |
| `windows` | **required** | The windows in the order of AVISITN, # between them; a window is AVISITN "AVISIT" AWLO AWHI AWTARGET "AWRANGE" (a period: a limit that is open) |
| `day` | `ADY` | The study day (default ADY) |

```sas
%windows(
    data    = advs
  , windows = 0 "Baseline" .  1  1  "<=1"
            # 4 "Week 4"   2  42 28 "2-42"
            # 8 "Week 8"   43 70 56 "43-70"
  , day     = ady
)
```

**Output:** DATA: AVISIT, AVISITN, AWLO, AWHI, AWTARGET, AWRANGE, AWU and AWTDIFF on each record in a window; missing on a record in no window.

### %worst

<a id="worst"></a>

The records of each subject at its worst level (the maximum severity or toxicity grade): for each subject and each value of BY (a term, or nothing: all its records), only the records whose VAR is the highest of LEVELS, in their order from the least to the most severe. A record whose VAR is not one of LEVELS (a missing grade) is never the worst and is left out. It computes no statistic: %freq then counts each subject once in each row, at its worst level.

**Procedure:** PROC SORT, a DATA step (BY, FIRST.)  
**Proven:** the known answer of the method catsumm with worst= (src/methods.ts, counted by hand; R ars_worst gives the same, test/safety-r.test.ts; node tools/methods_sas.ts); ran on SAS 9.4 M9, 2026-11-12  
**File:** `sas/macros/worst.sas` (16NOV2026)

| Parameter | Default | It is |
|---|---|---|
| `data` | **required** | The records |
| `where` |  | The records to use, a condition in parentheses |
| `var` | **required** | The graded variable |
| `by` |  | The variables of a row (the worst of each subject in each row); default: none (the worst of all the records of the subject) |
| `levels` | **required** | Its values from the least to the most severe (texts in quotes, numbers without) |
| `out` | **required** | The records kept (all the variables of DATA) |
| `debug` | `no` | yes: keep the work data sets of the macro (_worst_*) |

```sas
%worst(
    data   = adae
  , where  = (trtemfl = 'Y')
  , var    = aesev
  , by     = aebodsys aedecod
  , levels = 'MILD' 'MODERATE' 'SEVERE'
  , out    = ae_worst
)
```

**Output:** OUT: the records of DATA at the worst level of each subject and row.
