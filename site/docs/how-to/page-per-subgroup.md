# Make one page per subgroup

This guide shows how to print a table once for each value of a subgroup variable, such as sex, with the N of each
column counted on its page and the value in the title. All pages go into one RTF file and one text listing.

## Before you start

- Submit `examples/setup.sas`, or start your own program as [Use the macros in your own program](own-program.md)
  shows.
- Have the population, one row per subject, with the subgroup variable. The guide uses `adsl` and makes one page
  per sex.
- Have a format for the values of the subgroup if the title should print a label, such as `$sexf.` of the example
  data (`F` = `Female`).

## Steps

### 1. Compute each block by treatment and subgroup

Give the subgroup as the second variable of `by=` in every statistics macro:

```sas
%describe(
     data  = adsl
   , var   = age
   , by    = trt01a sex
   , total = yes
   , label = "Age (years)"
   , out   = t_age
 )
%freq(
     data  = adsl
   , var   = agegr1
   , by    = trt01a sex
   , total = yes
   , label = "Age group (years)"
   , out   = t_agegr
 )
%freq(
     data  = adsl
   , var   = race
   , by    = trt01a sex
   , total = yes
   , label = "Race"
   , out   = t_race
 )
%stack(t_age t_agegr t_race, out=t_sub)
```

### 2. Make the columns of each page

Give the subgroup to `page=` of `%columns`. The N of a column is then the N of its page:

```sas
%columns(
     data  = t_sub
   , n     = adsl
   , var   = trt01a
   , order = trt01an
   , page  = sex
   , total = yes
   , out   = t_sub_cols
 )
```

```text
t_sub_cols: 8 rows
SEX  COL  HEADER                       BIGN
F      1  Placebo|(N=53)                 53
F      2  Xanomeline Low Dose|(N=55)     55
F      3  Xanomeline High Dose|(N=35)    35
F      4  Total|(N=143)                 143
M      1  Placebo|(N=33)                 33
M      2  Xanomeline Low Dose|(N=41)     41
M      3  Xanomeline High Dose|(N=37)    37
M      4  Total|(N=111)                 111
```

### 3. Lay out the pages

Give the same `page=` to `%layout`, and the format of the subgroup to `format=`:

```sas
%layout(
     data    = t_sub
   , columns = t_sub_cols
   , var     = trt01a
   , page    = sex
   , format  = sex $sexf.
   , file    = &spl_out./tlf/t_sub
   , setup   = t_sub_print
   , out     = t_sub_display
 )
```

### 4. Name the subgroup in the title and print

`%print` prints each page under a BY statement. Set `OPTIONS NOBYLINE` and put `#BYVAL1` in a title: the title then
names the value of the page. Set `OPTIONS BYLINE` again after the print:

```sas
OPTIONS NOBYLINE;
TITLE1 "Table 14.1.3 Demographic characteristics by sex";
TITLE2 "Sex: #BYVAL1";
TITLE3 "Safety population";
%print(&t_sub_print.)
OPTIONS BYLINE;
```

```text
tlf/t_sub.lst: the first 40 of 45 lines
Table 14.1.3 Demographic characteristics by sex
Sex: Female
Safety population

                                    Placebo      Xanomeline Low Dose  Xanomeline High Dose  Total
                                    (N=53)       (N=55)               (N=35)                (N=143)
-------------------------------------------------------------------------------------------------------

Age (years)
  n                                 53           55                   35                    143
  Mean (SD)                         76.4 (8.73)  76.2 (7.97)          73.7 (7.58)           75.7 (8.19)
  Median                            78.0         78.0                 75.0                  77.0
  Min, Max                          59, 89       54, 87               56, 88                54, 89

Age group (years)
  18-64                               9 (17.0%)    5 ( 9.1%)            5 (14.3%)            19 (13.3%)
  >64                                44 (83.0%)   50 (90.9%)           30 (85.7%)           124 (86.7%)

Race
  AMERICAN INDIAN OR ALASKA NATIVE    0 ( 0.0%)    0 ( 0.0%)            0 ( 0.0%)             0 ( 0.0%)
  BLACK OR AFRICAN AMERICAN           5 ( 9.4%)    6 (10.9%)            6 (17.1%)            17 (11.9%)
  WHITE                              48 (90.6%)   49 (89.1%)           29 (82.9%)           126 (88.1%)

Table 14.1.3 Demographic characteristics by sex
Sex: Male
Safety population

                                    Placebo      Xanomeline Low Dose  Xanomeline High Dose  Total
                                    (N=33)       (N=41)               (N=37)                (N=111)
-------------------------------------------------------------------------------------------------------

Age (years)
  n                                 33           41                   37                    111
  Mean (SD)                         73.4 (8.15)  75.6 (8.38)          73.9 (8.38)           74.4 (8.29)
  Median                            74.0         77.0                 77.0                  77.0
  Min, Max                          52, 85       51, 88               56, 86                51, 88

Age group (years)
  18-64                               5 (15.2%)    3 ( 7.3%)            6 (16.2%)            14 (12.6%)
  >64                                28 (84.8%)   38 (92.7%)           31 (83.8%)            97 (87.4%)
```

Each page starts with the first block. The subgroup is not a row of the table.

## Related

- Reference: [%columns](../reference/columns.md), [%layout](../reference/layout.md),
  [%print](../reference/print.md), [%describe](../reference/describe.md), [%freq](../reference/freq.md).
- How-to: [Make a demographic table with tests](demographic-table.md).
- Explanation: [How a program reads](../explanation/program.md).
