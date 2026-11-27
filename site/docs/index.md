# Sapling SAS macros

SAS macros for the tables, listings and figures of clinical trials. A program that uses them reads like the table
it makes. Every number the table prints is also written, with its full value, to a
[numbers file](glossary.md) that a second program can check.

!!! success "Proven against pharmaverse"
    On six published outputs of the R Consortium R Submission Pilot 1 and the pharmaverse examples, **2,181 of 2,196
    numbers are the same in SAS**. 14 more differ for a known reason that the check reproduces from the SAS numbers;
    1 is a statistic no macro computes. [What the proof shows](explanation/proof.md)

A table of age and sex by treatment, from the [example data](tutorial/index.md#the-example-data):

```sas
%describe(data=adsl, var=age, by=trt01a, total=yes, label="Age (years)", out=t_age)
%freq(data=adsl, var=sex, by=trt01a, total=yes, label="Sex", out=t_sex)
%stack(t_age t_sex, out=t14_2_01)

TITLE1 "Table 14-2.01 Age and sex";
%table(
     data  = t14_2_01
   , n     = adsl
   , var   = trt01a
   , order = trt01an
   , total = yes
   , file  = &spl_out./tlf/t14_2_01
 )
```

```text
tlf/t14_2_01.lst: 15 lines
Table 14-2.01 Age and sex

             Placebo      Xanomeline Low Dose  Xanomeline High Dose  Total
             (N=86)       (N=96)               (N=72)                (N=254)
--------------------------------------------------------------------------------

Age (years)
  n          86           96                   72                    254
  Mean (SD)  75.2 (8.59)  76.0 (8.11)          73.8 (7.94)           75.1 (8.25)
  Median     76.0         78.0                 75.5                  77.0
  Min, Max   52, 89       51, 88               56, 88                51, 89

Sex
  F           53 (61.6%)   55 (57.3%)           35 (48.6%)           143 (56.3%)
  M           33 (38.4%)   41 (42.7%)           37 (51.4%)           111 (43.7%)
```

## Where to go

<div class="grid cards" markdown>

- **[Tutorial](tutorial/index.md)**: make your first table from the example data, step by step.
- **[How-to guides](how-to/index.md)**: make a demographic table, an adverse event table, a model table, a figure.
- **[Reference](reference/index.md)**: every macro, its parameters, its result, an example and its output.
- **[Explanation](explanation/index.md)**: how a program reads, the result shape, the numbers, the proof.

</div>

## License

The macros are source available: you may read them, run the tutorial and the examples, and check the proof. Using
them in your own work needs a license of DataStep Labs.
