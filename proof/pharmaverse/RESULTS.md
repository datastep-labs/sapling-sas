# The SAS macros against the pharmaverse examples

Written by `node tools/proof_pharmaverse.ts` (do not edit). Verdict: **PASS**.

The reference is the site of the pharmaverse examples ([pharmaverse.github.io/examples](https://pharmaverse.github.io/examples), branch
gh-pages at [bcaacf1](https://github.com/pharmaverse/examples/tree/bcaacf1143fbb1e4f59a46ed14194564a2e72eae)): the tables that {rtables} and {tern} make from the test data
of the R package pharmaverseadam. Each program of `programs/` makes one of them with the SAS macro library from ADSL
and ADAE of pharmaverseadam 1.3.0 (`data/*.xpt`, written by `data/make_xpt.R`), on SAS 9.4, with the same
preparation of the data as the example (written in the program). Its numbers file (`%ard`) is compared with each
number the page prints; a number is the same when the reference is the SAS value rounded to its decimals.

| Output | Program | Numbers | Same | Explained | Not made |
|---|---|---:|---:|---:|---:|
| Demographic table ({rtables} and {tern}): age, age group, sex, race ([reference](https://github.com/pharmaverse/examples/blob/bcaacf1143fbb1e4f59a46ed14194564a2e72eae/tlg/demographic.html)) | [demographic.sas](programs/demographic.sas) | 98 | 86 | 12 | 0 |
| Adverse events table ({rtables} and {tern}): patients and events by system organ class and preferred term ([reference](https://github.com/pharmaverse/examples/blob/bcaacf1143fbb1e4f59a46ed14194564a2e72eae/tlg/adverse_events.html)) | [adverse_events.sas](programs/adverse_events.sas) | 1867 | 1867 | 0 | 0 |
| **All** | 2 programs | **1965** | **1953** | **12** | **0** |

Each number, with the place in the reference it was read from: `results/<program>.csv`. The numbers of the reference
alone: `reference/<program>.csv`.

## The numbers that are not the same

- **EXPLAINED**, demographic T_AGEGR1 n Placebo: reference 86, SAS 86.0000. the n of a block of categories ({rtables} analyze_vars) is the number of subjects with a value; %freq gives the count of each category, and their sum is that number (86.0000)
- **EXPLAINED**, demographic T_AGEGR1 n Xanomeline High Dose: reference 72, SAS 72.0000. the n of a block of categories ({rtables} analyze_vars) is the number of subjects with a value; %freq gives the count of each category, and their sum is that number (72.0000)
- **EXPLAINED**, demographic T_AGEGR1 n Xanomeline Low Dose: reference 96, SAS 96.0000. the n of a block of categories ({rtables} analyze_vars) is the number of subjects with a value; %freq gives the count of each category, and their sum is that number (96.0000)
- **EXPLAINED**, demographic T_AGEGR1 n All Patients: reference 254, SAS 254.0000. the n of a block of categories ({rtables} analyze_vars) is the number of subjects with a value; %freq gives the count of each category, and their sum is that number (254.0000)
- **EXPLAINED**, demographic T_SEX n Placebo: reference 86, SAS 86.0000. the n of a block of categories ({rtables} analyze_vars) is the number of subjects with a value; %freq gives the count of each category, and their sum is that number (86.0000)
- **EXPLAINED**, demographic T_SEX n Xanomeline High Dose: reference 72, SAS 72.0000. the n of a block of categories ({rtables} analyze_vars) is the number of subjects with a value; %freq gives the count of each category, and their sum is that number (72.0000)
- **EXPLAINED**, demographic T_SEX n Xanomeline Low Dose: reference 96, SAS 96.0000. the n of a block of categories ({rtables} analyze_vars) is the number of subjects with a value; %freq gives the count of each category, and their sum is that number (96.0000)
- **EXPLAINED**, demographic T_SEX n All Patients: reference 254, SAS 254.0000. the n of a block of categories ({rtables} analyze_vars) is the number of subjects with a value; %freq gives the count of each category, and their sum is that number (254.0000)
- **EXPLAINED**, demographic T_RACE n Placebo: reference 86, SAS 86.0000. the n of a block of categories ({rtables} analyze_vars) is the number of subjects with a value; %freq gives the count of each category, and their sum is that number (86.0000)
- **EXPLAINED**, demographic T_RACE n Xanomeline High Dose: reference 72, SAS 72.0000. the n of a block of categories ({rtables} analyze_vars) is the number of subjects with a value; %freq gives the count of each category, and their sum is that number (72.0000)
- **EXPLAINED**, demographic T_RACE n Xanomeline Low Dose: reference 96, SAS 96.0000. the n of a block of categories ({rtables} analyze_vars) is the number of subjects with a value; %freq gives the count of each category, and their sum is that number (96.0000)
- **EXPLAINED**, demographic T_RACE n All Patients: reference 254, SAS 254.0000. the n of a block of categories ({rtables} analyze_vars) is the number of subjects with a value; %freq gives the count of each category, and their sum is that number (254.0000)
