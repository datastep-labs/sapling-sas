# Make an adverse event table

This guide shows how to make a table of the subjects with treatment-emergent adverse events, by system organ class
and preferred term, with Fisher's exact test of each term. You get an RTF file, a text listing and a numbers file.

## Before you start

- Submit `examples/setup.sas`, or start your own program with `%study`.
- Have two data sets: the population, one row per subject (`adsl`), and the adverse events, one row per event
  (`adae`). Both need the treatment variable of the columns (`trt01a`).
- Know the condition of the events to count. The guide counts the treatment-emergent events: `trtemfl = 'Y'`.

## Steps

### 1. Count the subjects with any event

Call `%freq` without `var=`. Give the population to `denom=`: each percent is then a percent of all subjects of
the population, with or without an event.

```sas
%freq(
     data  = adae
   , denom = adsl
   , where = (trtemfl = 'Y')
   , by    = trt01a
   , label = "Subjects with at least one treatment-emergent adverse event"
   , out   = t_any
 )
```

```text
t_any: 6 rows
TRT01A                STAT         VALUE  TEXT
Placebo               n               65  65
Placebo               pct   75.581395349  (75.6%)
Xanomeline High Dose  n               68  68
Xanomeline High Dose  pct   94.444444444  (94.4%)
Xanomeline Low Dose   n               84  84
Xanomeline Low Dose   pct           87.5  (87.5%)
```

### 2. Count the subjects in each system organ class

Call `%freq` with the class alone in `var=`. Each row counts the subjects with at least one event in the class:

```sas
%freq(
     data  = adae
   , denom = adsl
   , where = (trtemfl = 'Y')
   , var   = aebodsys
   , by    = trt01a
   , order = frequency
   , label = "System organ class"
   , out   = t_soc
 )
```

```text
t_soc: the first 3 of 138 rows
TRT01A   AEBODSYS                                    STAT  TEXT
Placebo  CARDIAC DISORDERS                           n     12
Placebo  CARDIAC DISORDERS                           pct   (14.0%)
Placebo  CONGENITAL, FAMILIAL AND GENETIC DISORDERS  n     0
```

### 3. Count the subjects in each preferred term

Name the class and the term in `var=`, in their order of nesting. Add `order = frequency` to put the most frequent
term first in each class:

```sas
%freq(
     data  = adae
   , denom = adsl
   , where = (trtemfl = 'Y')
   , var   = aebodsys aedecod
   , by    = trt01a
   , order = frequency
   , label = "Treatment-emergent adverse events"
   , out   = t_term
 )
```

A subject with two events of the same term counts once in its row. In this block the class is a heading over its
terms: the heading has no count. The counts of the classes are the rows of the block of step 2.

### 4. Test each term

Call `%fisher` with the same records, the same `denom=` and the same `label=` as the counts. `within=` gives one test
per term:

```sas
%fisher(
     data   = adae
   , denom  = adsl
   , where  = (trtemfl = 'Y')
   , by     = trt01a
   , within = aebodsys aedecod
   , label  = "Treatment-emergent adverse events"
   , out    = t_term_test
 )
```

```text
t_term_test: the first 3 of 230 rows
AEBODSYS           AEDECOD              STAT   TEXT
CARDIAC DISORDERS  ATRIAL FIBRILLATION  pval  0.858
CARDIAC DISORDERS  ATRIAL FLUTTER       pval  0.743
CARDIAC DISORDERS  ATRIAL HYPERTROPHY   pval  0.622
```

Skip this step if the table has no p-values.

### 5. Stack the blocks and print the table

`%table` makes the columns, the numbers file, the display data set and the printed table in one call:

```sas
%stack(t_any t_soc t_term t_term_test, out=t_ae)
TITLE1 "Table 14.3.1 Treatment-emergent adverse events by system organ class and preferred term";
TITLE2 "Safety population";
FOOTNOTE1 J=L "A subject is counted once in each row. p-value: Fisher's exact test.";
%table(
     data  = t_ae
   , n     = adsl
   , var   = trt01a
   , order = trt01an
   , file  = &spl_out./tlf/t_ae
 )
```

```text
tlf/t_ae.lst: the first 50 of 369 lines
Table 14.3.1 Treatment-emergent adverse events by system organ class and preferred term
Safety population

                                                                       Placebo     Xanomeline Low Dose  Xanomeline High Dose  All
                                                                       (N=86)      (N=96)               (N=72)                groups
------------------------------------------------------------------------------------------------------------------------------------

Subjects with at least one treatment-emergent adverse event            65 (75.6%)  84 (87.5%)           68 (94.4%)

System organ class
  GENERAL DISORDERS AND ADMINISTRATION SITE CONDITIONS                 21 (24.4%)  51 (53.1%)           36 (50.0%)
  SKIN AND SUBCUTANEOUS TISSUE DISORDERS                               20 (23.3%)  39 (40.6%)           39 (54.2%)
  NERVOUS SYSTEM DISORDERS                                              8 ( 9.3%)  22 (22.9%)           23 (31.9%)
  GASTROINTESTINAL DISORDERS                                           17 (19.8%)  15 (15.6%)           19 (26.4%)
  CARDIAC DISORDERS                                                    12 (14.0%)  14 (14.6%)           14 (19.4%)
  INFECTIONS AND INFESTATIONS                                          16 (18.6%)   9 ( 9.4%)           13 (18.1%)
  PSYCHIATRIC DISORDERS                                                10 (11.6%)  11 (11.5%)            7 ( 9.7%)
  RESPIRATORY, THORACIC AND MEDIASTINAL DISORDERS                       8 ( 9.3%)   9 ( 9.4%)           10 (13.9%)
  INVESTIGATIONS                                                       10 (11.6%)   7 ( 7.3%)            5 ( 6.9%)
  MUSCULOSKELETAL AND CONNECTIVE TISSUE DISORDERS                       4 ( 4.7%)   7 ( 7.3%)            7 ( 9.7%)
  INJURY, POISONING AND PROCEDURAL COMPLICATIONS                        4 ( 4.7%)   5 ( 5.2%)            5 ( 6.9%)
  RENAL AND URINARY DISORDERS                                           4 ( 4.7%)   3 ( 3.1%)            3 ( 4.2%)
  METABOLISM AND NUTRITION DISORDERS                                    6 ( 7.0%)   1 ( 1.0%)            2 ( 2.8%)
  VASCULAR DISORDERS                                                    3 ( 3.5%)   3 ( 3.1%)            1 ( 1.4%)
  EYE DISORDERS                                                         2 ( 2.3%)   2 ( 2.1%)            1 ( 1.4%)
  SURGICAL AND MEDICAL PROCEDURES                                       2 ( 2.3%)   1 ( 1.0%)            2 ( 2.8%)
  EAR AND LABYRINTH DISORDERS                                           1 ( 1.2%)   2 ( 2.1%)            1 ( 1.4%)
  CONGENITAL, FAMILIAL AND GENETIC DISORDERS                            0 ( 0.0%)   1 ( 1.0%)            2 ( 2.8%)
  NEOPLASMS BENIGN, MALIGNANT AND UNSPECIFIED (INCL CYSTS AND POLYPS)   0 ( 0.0%)   2 ( 2.1%)            1 ( 1.4%)
  REPRODUCTIVE SYSTEM AND BREAST DISORDERS                              2 ( 2.3%)   0 ( 0.0%)            1 ( 1.4%)
  HEPATOBILIARY DISORDERS                                               1 ( 1.2%)   0 ( 0.0%)            0 ( 0.0%)
  IMMUNE SYSTEM DISORDERS                                               0 ( 0.0%)   1 ( 1.0%)            0 ( 0.0%)
  SOCIAL CIRCUMSTANCES                                                  0 ( 0.0%)   0 ( 0.0%)            1 ( 1.4%)

A subject is counted once in each row. p-value: Fisher's exact test.

Table 14.3.1 Treatment-emergent adverse events by system organ class and preferred term
Safety population

                                                                       Placebo     Xanomeline Low Dose  Xanomeline High Dose  All
                                                                       (N=86)      (N=96)               (N=72)                groups
------------------------------------------------------------------------------------------------------------------------------------

Treatment-emergent adverse events
  CARDIAC DISORDERS
    SINUS BRADYCARDIA                                                   2 ( 2.3%)   7 ( 7.3%)            8 (11.1%)            0.078
    MYOCARDIAL INFARCTION                                               4 ( 4.7%)   2 ( 2.1%)            4 ( 5.6%)            0.511
    ATRIAL FIBRILLATION                                                 1 ( 1.2%)   2 ( 2.1%)            2 ( 2.8%)            0.858
    SUPRAVENTRICULAR EXTRASYSTOLES                                      1 ( 1.2%)   1 ( 1.0%)            1 ( 1.4%)            >0.999
    VENTRICULAR EXTRASYSTOLES                                           0 ( 0.0%)   2 ( 2.1%)            1 ( 1.4%)            0.504
```

The block of the classes comes first, with the subjects of each class; then the block of the terms, each term
under the heading of its class. Each p-value prints in the row of its term, in the column `All groups`.

## Make the table without tests in one call

If the table needs no p-values, `%table_ae` makes it in one call. It selects the population, counts and prints:

```sas
TITLE1 "Table 14.3.2 Treatment-emergent adverse events by system organ class and preferred term";
FOOTNOTE1 J=L "A subject is counted once in each row.";
%table_ae(
     data  = adae
   , adsl  = adsl
   , where = (trtemfl = 'Y')
   , var   = aebodsys aedecod
   , by    = trt01a
   , order = trt01an
   , sort  = frequency
   , label = "Treatment-emergent adverse events"
   , file  = &spl_out./tlf/t_ae_short
 )
```

```text
tlf/t_ae_short.lst: the first 16 of 325 lines
Table 14.3.2 Treatment-emergent adverse events by system organ class and preferred term

                                                                       Placebo     Xanomeline Low Dose  Xanomeline High Dose
                                                                       (N=86)      (N=96)               (N=72)
----------------------------------------------------------------------------------------------------------------------------

Treatment-emergent adverse events
  CARDIAC DISORDERS
    SINUS BRADYCARDIA                                                   2 ( 2.3%)   7 ( 7.3%)            8 (11.1%)
    MYOCARDIAL INFARCTION                                               4 ( 4.7%)   2 ( 2.1%)            4 ( 5.6%)
    ATRIAL FIBRILLATION                                                 1 ( 1.2%)   2 ( 2.1%)            2 ( 2.8%)
    SUPRAVENTRICULAR EXTRASYSTOLES                                      1 ( 1.2%)   1 ( 1.0%)            1 ( 1.4%)
    VENTRICULAR EXTRASYSTOLES                                           0 ( 0.0%)   2 ( 2.1%)            1 ( 1.4%)
    ATRIAL FLUTTER                                                      0 ( 0.0%)   1 ( 1.0%)            1 ( 1.4%)
    ATRIOVENTRICULAR BLOCK FIRST DEGREE                                 1 ( 1.2%)   1 ( 1.0%)            0 ( 0.0%)
    BUNDLE BRANCH BLOCK RIGHT                                           1 ( 1.2%)   1 ( 1.0%)            0 ( 0.0%)
```

To show only the common terms, add `threshold = 5`: a term then needs 5% of the subjects of at least one group.

The table of `%table_ae` has one block: a class is a heading over its terms, without a count. To add the counts
of the classes, write the long program with `show = yes`, and add the `%freq` call of step 2 before the block of
the terms in `%stack`.

## Related

- Reference: [%freq](../reference/freq.md), [%fisher](../reference/fisher.md), [%stack](../reference/stack.md),
  [%table](../reference/table.md), [%table_ae](../reference/table_ae.md).
- Explanation: [The result shape](../explanation/result-shape.md).
