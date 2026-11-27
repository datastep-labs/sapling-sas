# Make a demographic table with tests

This guide shows how to make a table of the demographic characteristics by treatment, with a p-value for each
characteristic. You get an RTF file, a text listing and a numbers file.

## Before you start

- Submit `examples/setup.sas`, or start your own program with `%study`.
- Make a data set of your population, one row per subject. The guide uses `adsl`, the safety population of the
  example data.
- Decide which test each characteristic gets. The guide uses the analysis of variance for age, the chi-square test
  for the age group and sex, and Fisher's exact test for race.

## Steps

### 1. Summarize each continuous characteristic

Call `%describe` for the statistics and `%anova` for the p-value. Give both the same `label=`: the p-value then
prints in the block of the statistics, without a heading of its own.

```sas
%describe(
     data  = adsl
   , var   = age
   , by    = trt01a
   , total = yes
   , label = "Age (years)"
   , out   = t_age
 )
%anova(data=adsl, var=age, by=trt01a, label="Age (years)", out=t_age_test)
```

```text
t_age_test: 1 row
BLOCK        STAT         VALUE   TEXT
Age (years)  pval  0.2346471181  0.235
```

The test compares the treatment groups only: `total = yes` of `%describe` adds the group `Total` to the
statistics, not to the test.

### 2. Count each categorical characteristic

Call `%freq` for the counts and `%chisq` for the p-value:

```sas
%freq(
     data  = adsl
   , var   = agegr1
   , by    = trt01a
   , total = yes
   , label = "Age group (years)"
   , out   = t_agegr
 )
%chisq(data=adsl, var=agegr1, by=trt01a, label="Age group (years)", out=t_agegr_test)
%freq(
     data  = adsl
   , var   = sex
   , by    = trt01a
   , total = yes
   , label = "Sex"
   , out   = t_sex
 )
%chisq(data=adsl, var=sex, by=trt01a, label="Sex", out=t_sex_test)
```

If a characteristic has categories with few subjects, as race has here, use Fisher's exact test: add
`exact = yes` to `%chisq`.

```sas
%freq(
     data  = adsl
   , var   = race
   , by    = trt01a
   , total = yes
   , label = "Race"
   , out   = t_race
 )
%chisq(
     data  = adsl
   , var   = race
   , by    = trt01a
   , exact = yes
   , label = "Race"
   , out   = t_race_test
 )
```

### 3. Stack the blocks in the order of the table

Name each result, and its test after it:

```sas
%stack(
     results = t_age t_age_test t_agegr t_agegr_test t_sex t_sex_test t_race t_race_test
   , out     = t_demog
 )
```

### 4. Make the columns and the numbers file

Take the N of each column from the population, and order the columns by the numeric twin of the treatment:

```sas
%columns(
     data  = t_demog
   , n     = adsl
   , var   = trt01a
   , order = trt01an
   , total = yes
   , out   = t_demog_cols
 )
%ard(data=t_demog, columns=t_demog_cols, file=t_demog)
```

### 5. Lay out and print the table

Give `format=` the format that decodes a category. Then write the titles and the footnotes, and print:

```sas
%layout(
     data    = t_demog
   , columns = t_demog_cols
   , var     = trt01a
   , format  = sex $sexf.
   , file    = &spl_out./tlf/t_demog
   , setup   = t_demog_print
   , out     = t_demog_display
 )
TITLE1 "Table 14.1.1 Demographic characteristics";
TITLE2 "Safety population";
FOOTNOTE1 J=L "p-values: age, analysis of variance; age group and sex, chi-square test;";
FOOTNOTE2 J=L "race, Fisher's exact test.";
%print(&t_demog_print.)
```

```text
tlf/t_demog.lst: 32 lines
Table 14.1.1 Demographic characteristics
Safety population

                                    Placebo      Xanomeline Low Dose  Xanomeline High Dose  Total        All
                                    (N=86)       (N=96)               (N=72)                (N=254)      groups
---------------------------------------------------------------------------------------------------------------

Age (years)
  n                                 86           96                   72                    254
  Mean (SD)                         75.2 (8.59)  76.0 (8.11)          73.8 (7.94)           75.1 (8.25)
  Median                            76.0         78.0                 75.5                  77.0
  Min, Max                          52, 89       51, 88               56, 88                51, 89
  p-value                                                                                                0.235

Age group (years)
  18-64                              14 (16.3%)    8 ( 8.3%)           11 (15.3%)            33 (13.0%)
  >64                                72 (83.7%)   88 (91.7%)           61 (84.7%)           221 (87.0%)
  p-value                                                                                                0.223

Sex
  Female                             53 (61.6%)   55 (57.3%)           35 (48.6%)           143 (56.3%)
  Male                               33 (38.4%)   41 (42.7%)           37 (51.4%)           111 (43.7%)
  p-value                                                                                                0.251

Race
  AMERICAN INDIAN OR ALASKA NATIVE    0 ( 0.0%)    0 ( 0.0%)            1 ( 1.4%)             1 ( 0.4%)
  BLACK OR AFRICAN AMERICAN           8 ( 9.3%)    6 ( 6.3%)            9 (12.5%)            23 ( 9.1%)
  WHITE                              78 (90.7%)   90 (93.8%)           62 (86.1%)           230 (90.6%)
  p-value                                                                                                0.290

p-values: age, analysis of variance; age group and sex, chi-square test;
race, Fisher's exact test.
```

The p-values print in the column `All groups`. The numbers file is `ard/t_demog.csv` in the output folder.

## Make the table without tests in one call

If the table needs no p-values, `%table_summary` makes it in one call. Put `#` after a categorical variable:

```sas
TITLE1 "Table 14.1.2 Demographic characteristics";
TITLE2 "Safety population";
FOOTNOTE1;
%table_summary(
     data   = adsl
   , vars   = age agegr1# sex# race#
   , by     = trt01a
   , order  = trt01an
   , total  = yes
   , names  = age="Age (years)" agegr1="Age group (years)"
   , format = sex $sexf.
   , file   = &spl_out./tlf/t_demog_short
 )
```

```text
tlf/t_demog_short.lst: 25 lines
Table 14.1.2 Demographic characteristics
Safety population

                                    Placebo      Xanomeline Low Dose  Xanomeline High Dose  Total
                                    (N=86)       (N=96)               (N=72)                (N=254)
-------------------------------------------------------------------------------------------------------

Age (years)
  n                                 86           96                   72                    254
  Mean (SD)                         75.2 (8.59)  76.0 (8.11)          73.8 (7.94)           75.1 (8.25)
  Median                            76.0         78.0                 75.5                  77.0
  Min, Max                          52, 89       51, 88               56, 88                51, 89

Age group (years)
  18-64                              14 (16.3%)    8 ( 8.3%)           11 (15.3%)            33 (13.0%)
  >64                                72 (83.7%)   88 (91.7%)           61 (84.7%)           221 (87.0%)

Sex
  Female                             53 (61.6%)   55 (57.3%)           35 (48.6%)           143 (56.3%)
  Male                               33 (38.4%)   41 (42.7%)           37 (51.4%)           111 (43.7%)

Race
  AMERICAN INDIAN OR ALASKA NATIVE    0 ( 0.0%)    0 ( 0.0%)            1 ( 1.4%)             1 ( 0.4%)
  BLACK OR AFRICAN AMERICAN           8 ( 9.3%)    6 ( 6.3%)            9 (12.5%)            23 ( 9.1%)
  WHITE                              78 (90.7%)   90 (93.8%)           62 (86.1%)           230 (90.6%)
```

Add `show = yes` to see the long program that `%table_summary` runs, and continue from it by hand.

## Related

- Reference: [%describe](../reference/describe.md), [%freq](../reference/freq.md), [%anova](../reference/anova.md),
  [%chisq](../reference/chisq.md), [%stack](../reference/stack.md), [%columns](../reference/columns.md),
  [%ard](../reference/ard.md), [%layout](../reference/layout.md), [%print](../reference/print.md),
  [%table_summary](../reference/table_summary.md).
- Explanation: [How a program reads](../explanation/program.md),
  [How a number is kept and printed](../explanation/numbers.md).
