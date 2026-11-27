# The SAS macros against the R Submission Pilot 1

Written by `node tools/proof_pilot1.ts` (do not edit). Verdict: **PASS**.

The reference is the R Consortium R Submission Pilot 1 ([ba1d3e7](https://github.com/RConsortium/submissions-pilot1/tree/ba1d3e7af60e281def02df11c76c64f8352526f4)): the CDISC pilot study
CDISCPILOT01, its tables made in R and reviewed by the FDA in 2022. Each program of `programs/` makes one of its outputs
with the SAS macro library, from the ADaM transport files of the same repository (`adam/*.xpt`), on SAS 9.4. Its
numbers file (`%ard`: every number with its full value) is compared with each number the reference prints. A number
is the same when the reference is the SAS value rounded to the decimals the reference prints.

| Output | Program | Numbers | Same | Explained | Not made |
|---|---|---:|---:|---:|---:|
| Table 14-2.01 Summary of Demographic and Baseline Characteristics ([reference](https://github.com/RConsortium/submissions-pilot1/tree/ba1d3e7af60e281def02df11c76c64f8352526f4/output/tlf-demographic.out)) | [t14_2_01.sas](programs/t14_2_01.sas) | 96 | 96 | 0 | 0 |
| Table 14-3.01 Primary Endpoint Analysis: ADAS Cog (11), Change from Baseline to Week 24, LOCF ([reference](https://github.com/RConsortium/submissions-pilot1/tree/ba1d3e7af60e281def02df11c76c64f8352526f4/output/tlf-primary.rtf)) | [t14_3_01.sas](programs/t14_3_01.sas) | 73 | 73 | 0 | 0 |
| ANCOVA of Change from Baseline at Week 20 (glucose) ([reference](https://github.com/RConsortium/submissions-pilot1/tree/ba1d3e7af60e281def02df11c76c64f8352526f4/output/tlf-efficacy.rtf)) | [t14_3_02.sas](programs/t14_3_02.sas) | 29 | 26 | 2 | 1 |
| Figure 14-1 Kaplan-Meier plot of the time to the first dermatologic event: the number at risk ([reference](https://github.com/RConsortium/submissions-pilot1/tree/ba1d3e7af60e281def02df11c76c64f8352526f4/output/tlf-kmplot.pdf)) | [f14_1.sas](programs/f14_1.sas) | 33 | 33 | 0 | 0 |
| **All** | 4 programs | **231** | **228** | **2** | **1** |

Each number, with the place in the reference it was read from: `results/<program>.csv`. The numbers of the reference
alone: `reference/<program>.csv`.

## The numbers that are not the same

- **EXPLAINED**, t14_3_02 T_ANCOVA lcl Xanomeline High Dose vs Placebo: reference -0.50, SAS -0.5087. the reference computes the limits of the difference as estimate +/- 1.96 x SE (the normal quantile, vignettes/tlf-efficacy.Rmd); SAS (PROC MIXED) uses the t quantile of the residual degrees of freedom. The estimate and SE of SAS with 1.96 give the limits of the reference (-0.5012)
- **EXPLAINED**, t14_3_02 T_ANCOVA ucl Xanomeline High Dose vs Placebo: reference 0.63, SAS 0.6394. the reference computes the limits of the difference as estimate +/- 1.96 x SE (the normal quantile, vignettes/tlf-efficacy.Rmd); SAS (PROC MIXED) uses the t quantile of the residual degrees of freedom. The estimate and SE of SAS with 1.96 give the limits of the reference (0.6320)
- **NOT MADE**, t14_3_02 T_ANCOVA rmse : reference 1.30, SAS none. the reference prints sqrt(mean(residual^2)) (vignettes/tlf-efficacy.Rmd), divided by n, not by the residual degrees of freedom as the root mean squared error of PROC GLM and PROC MIXED: no macro of the library makes it
