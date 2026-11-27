# Make an efficacy table with an ANCOVA

This guide shows how to make a table of a continuous endpoint at one visit: the descriptive statistics of the
baseline, the value and the change from baseline, then the LS means and their differences from an analysis of
covariance. You get an RTF file, a text listing and a numbers file.

## Before you start

- Submit `examples/setup.sas`, or start your own program as [Use the macros in your own program](own-program.md)
  shows.
- Have the analysis records: one record per subject at the visit, with the baseline (`base`), the value (`aval`) and
  the change (`chg`). The guide uses the systolic blood pressure of `advs` at Week 12.
- Know the model of the plan: the response, the covariates, the class factors and the pairs of groups to compare.
  The guide models the change with the baseline as covariate and compares each dose with placebo.
- Know the analysis population of the plan. An efficacy table is usually on the efficacy or full analysis
  population, by the planned treatment (`TRT01P`). The example data have no flag of such a population (no `EFFFL`,
  no `ITTFL`): the guide uses the safety population (`SAFFL`) of `examples/setup.sas`, by the planned treatment. With
  your own data, select the population of the plan in step 1 and give its subjects to `n=`.

## Steps

### 1. Select the analysis records

Select the parameter, the visit and the analysis flag in a DATA step:

```sas
DATA sbp;
  SET advs;
  WHERE paramcd = 'SYSBP' AND avisit = 'Week 12' AND anl01fl = 'Y';
RUN;
```

```text
sbp: the first 3 of 150 rows
USUBJID      TRT01P                AVISIT   BASE  AVAL  CHG
01-701-1015  Placebo               Week 12   130   139    9
01-701-1028  Xanomeline High Dose  Week 12   138   128  -10
01-701-1034  Xanomeline High Dose  Week 12   163   145  -18
```

The analysis flag `anl01fl` selects one record per subject at each visit. The model needs exactly one.

### 2. Describe the baseline, the value and the change

Call `%describe` once for each variable, each with its own label:

```sas
%describe(data=sbp, var=base, by=trt01p, label="Baseline (mmHg)", out=t_base)
%describe(data=sbp, var=aval, by=trt01p, label="Week 12 (mmHg)", out=t_aval)
%describe(data=sbp, var=chg, by=trt01p, label="Change from baseline (mmHg)", out=t_chg)
```

### 3. Fit the ANCOVA

Call `%lsmeans` with the change as `var=` and the baseline as covariate. Name each pair of groups, the group first
and then the group it is compared with. Ask for the LS means in `stats=`:

```sas
%lsmeans(
     data   = sbp
   , var    = chg
   , by     = trt01p
   , covars = base
   , pairs  = "Xanomeline Low Dose" "Placebo"
            # "Xanomeline High Dose" "Placebo"
   , order  = trt01pn
   , stats  = lsmean="XX.X" lsmean_se="XX.XX" diff="XX.X" diff_se="XX.XX" lcl="XX.X" ucl="XX.X"
              pval="X.XXX"
   , label  = "ANCOVA of the change from baseline"
   , out    = t_model
 )
```

```text
t_model: the first 8 of 16 rows
TRT01P                VERSUS   STAT       TEXT
Placebo                        lsmean     -3.2
Placebo                        lsmean_se  1.58
Xanomeline High Dose           lsmean     -8.9
Xanomeline High Dose           lsmean_se  2.03
Xanomeline Low Dose            lsmean     -3.1
Xanomeline Low Dose            lsmean_se  2.03
Xanomeline High Dose  Placebo  diff       -5.7
Xanomeline High Dose  Placebo  diff_se    2.57
```

The rows with a blank `VERSUS` hold the LS mean of each group. The other rows compare a group with the group in
`VERSUS`. To add a class factor, such as a site or a stratum, give it in `class=`.

### 4. Test the dose response

If the plan also tests a trend over the doses, call `%ancova` with the numeric dose in `test=`:

```sas
%ancova(
     data   = sbp
   , var    = chg
   , covars = base
   , test   = trt01pn
   , label  = "Test of the dose response"
   , out    = t_dose
 )
```

Skip this step if the plan has no such test.

### 5. Stack the blocks and print the table

```sas
%stack(t_base t_aval t_chg t_model t_dose, out=t_eff)
TITLE1 "Table 14.4.1 Systolic blood pressure (mmHg): ANCOVA of the change from baseline at Week 12";
TITLE2 "Safety population, by planned treatment";
FOOTNOTE1 J=L "ANCOVA: change from baseline = baseline + treatment.";
FOOTNOTE2 J=L "Difference: the dose group minus placebo, with its 95% confidence interval.";
%table(
     data  = t_eff
   , n     = adsl
   , var   = trt01p
   , order = trt01pn
   , file  = &spl_out./tlf/t_eff
 )
```

```text
tlf/t_eff.lst: 37 lines
Table 14.4.1 Systolic blood pressure (mmHg): ANCOVA of the change from baseline at Week 12
Safety population, by planned treatment

                                    Placebo        Xanomeline Low Dose  Xanomeline High Dose  All
                                    (N=86)         (N=84)               (N=84)                groups
----------------------------------------------------------------------------------------------------

Baseline (mmHg)
  n                                 68             41                   41
  Mean (SD)                         137.8 (17.68)  136.6 (16.12)        138.7 (16.98)
  Median                            139.0          137.0                140.0
  Min, Max                          90, 180        100, 178             100, 170

Week 12 (mmHg)
  n                                 68             41                   41
  Mean (SD)                         134.5 (14.35)  134.1 (15.76)        129.2 (15.50)
  Median                            132.0          135.0                130.0
  Min, Max                          100, 164       104, 170             100, 160

Change from baseline (mmHg)
  n                                 68             41                   41
  Mean (SD)                         -3.2 (15.53)   -2.5 (16.23)         -9.5 (16.48)
  Median                            -4.5           -7.0                 -10.0
  Min, Max                          -40, 24        -43, 30              -48, 30

ANCOVA of the change from baseline
  LS mean (SE)                      -3.2 (1.58)    -3.1 (2.03)          -8.9 (2.03)
  vs Placebo
    Difference (SE)                                0.1 (2.57)           -5.7 (2.57)
    Confidence interval                            (-5.0, 5.2)          (-10.8, -0.7)
    p-value                                        0.975                0.027

Test of the dose response
  p-value                                                                                     0.068

ANCOVA: change from baseline = baseline + treatment.
Difference: the dose group minus placebo, with its 95% confidence interval.
```

The LS mean prints in the column of its group, and each difference in the column of the dose group, under
`vs Placebo`. The p-value of the dose response prints in the column `All groups`.

## Make the table in one call

`%table_model` makes the descriptive blocks and the ANCOVA block of this table from the records of all visits. Give
the visit of the table in `at=`, the population in `adsl=` (the N of the columns) and the labels of the blocks in
`names=`. Its table differs from the table above in two things:

- It has no test of the dose response, and so no column `All groups`. Add it with the long program (`show = yes`)
  and the `%ancova` call of step 4.
- The ANCOVA block has the label the macro gives it, `ANCOVA, adjusted for base`.

Like `%print`, it prints the TITLE and FOOTNOTE statements in force: set them before the call.

```sas
TITLE1 "Table 14.4.2 Systolic blood pressure (mmHg): ANCOVA of the change from baseline at Week 12";
%table_model(
     data     = advs
   , adsl     = adsl
   , where    = (paramcd = 'SYSBP' AND anl01fl = 'Y')
   , covars   = base
   , by       = trt01p
   , at       = "Week 12"
   , order    = trt01pn
   , describe = base aval chg
   , pairs    = "Xanomeline Low Dose" "Placebo"
              # "Xanomeline High Dose" "Placebo"
   , names    = base="Baseline (mmHg)" aval="Week 12 (mmHg)" chg="Change from baseline (mmHg)"
   , file     = &spl_out./tlf/t_eff_short
 )
```

```text
tlf/t_eff_short.lst: 33 lines
Table 14.4.2 Systolic blood pressure (mmHg): ANCOVA of the change from baseline at Week 12

                             Placebo        Xanomeline Low Dose  Xanomeline High Dose
                             (N=86)         (N=84)               (N=84)
-------------------------------------------------------------------------------------

Baseline (mmHg)
  n                          68             41                   41
  Mean (SD)                  137.8 (17.68)  136.6 (16.12)        138.7 (16.98)
  Median                     139.0          137.0                140.0
  Min, Max                   90, 180        100, 178             100, 170

Week 12 (mmHg)
  n                          68             41                   41
  Mean (SD)                  134.5 (14.35)  134.1 (15.76)        129.2 (15.50)
  Median                     132.0          135.0                130.0
  Min, Max                   100, 164       104, 170             100, 160

Change from baseline (mmHg)
  n                          68             41                   41
  Mean (SD)                  -3.2 (15.53)   -2.5 (16.23)         -9.5 (16.48)
  Median                     -4.5           -7.0                 -10.0
  Min, Max                   -40, 24        -43, 30              -48, 30

ANCOVA, adjusted for base
  LS mean (SE)               -3.2 (1.58)    -3.1 (2.03)          -8.9 (2.03)
  vs Placebo
    Difference (SE)                         0.1 (2.57)           -5.7 (2.57)
    Confidence interval                     (-5.0, 5.2)          (-10.8, -0.7)
    p-value                                 0.975                0.027

ANCOVA: change from baseline = baseline + treatment.
Difference: the dose group minus placebo, with its 95% confidence interval.
```

For a mixed model for repeated measures over all visits, add `method = mmrm`.

## Related

- Reference: [%describe](../reference/describe.md), [%lsmeans](../reference/lsmeans.md),
  [%ancova](../reference/ancova.md), [%mmrm](../reference/mmrm.md), [%table](../reference/table.md),
  [%table_model](../reference/table_model.md).
- Explanation: [The result shape](../explanation/result-shape.md),
  [How a number is kept and printed](../explanation/numbers.md).
