# What the proof shows

The library is checked against tables that other people made, in R, with the pharmaverse, and published. The check
compares numbers, one by one. This page explains what the check shows and what it does not.

## The references

| Reference | What it is | Outputs |
|---|---|---|
| R Consortium R Submission Pilot 1 | The CDISC pilot study made in R and reviewed by the FDA in 2022 | demographics, the ADAS-Cog ANCOVA, the glucose ANCOVA, the Kaplan-Meier figure |
| pharmaverse examples | The tables that `{rtables}` and `{tern}` make from the test data of `pharmaverseadam` | the demographic table, the adverse event table |

Each reference is read at a fixed commit of its repository. The data are the data the reference used: the ADaM
transport files of the pilot, and ADSL and ADAE of `pharmaverseadam` 1.3.0.

## How a number is compared

For each output, a SAS program calls the macros and writes the numbers file with `%ard`. A tool reads every number
that the reference prints, from its text, its RTF or its PDF, and records where it read it. Then it compares:

- A number is **the same** when the reference is the SAS value rounded to the decimals the reference prints. Either
  rounding of a tie counts, because SAS and R round a tie in different ways.
- A number is **explained** when the reference computes it in another way, and the tool proves the explanation: it
  computes the number the way of the reference, from the SAS numbers, and gets the number of the reference. Example:
  the reference gives a confidence interval as estimate ± 1.96 × SE; SAS uses the t quantile; the SAS estimate and
  SE with 1.96 give the limits of the reference.
- A number is **not made** when no macro computes it. It is declared with its reason and listed. It never counts as
  the same.

The tool also counts the numbers it reads from each reference and compares the count with the known count. A parser
that loses a row makes the proof fail.

## The result

| Reference | Numbers | Same | Explained | Not made |
|---|---:|---:|---:|---:|
| R Submission Pilot 1 | 231 | 228 | 2 | 1 |
| pharmaverse examples | 1,965 | 1,953 | 12 | 0 |

Every number, with the place in the reference it was read from and its verdict, is in the `results` folder of each
suite of the repository.

## What the proof does not show

- **Only the outputs that were compared.** The proof covers the statistics that these six outputs use: descriptive
  statistics, frequencies, ANCOVA with LS means, Kaplan-Meier, the adverse event counts. Each macro has its own check
  against known answers, but a macro that no reference uses is not part of this comparison.
- **Only the numbers, not the look.** The layout of a SAS table differs from the layout of the reference. The proof
  compares numbers, not rows, fonts or page breaks.
- **Agreement, not truth.** Two programs that agree can both be wrong in the same way. The references are independent
  of the library (other people, another language, other procedures), and one of them was reviewed by the FDA. That
  makes a shared error unlikely, not impossible.
