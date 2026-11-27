# The proof: the SAS macros against public pharmaverse references

The SAS macro library (`sas/macros`) is checked against outputs that other people made and published, in R, with the
pharmaverse. Each suite has readable SAS programs that call the macros, the numbers of its reference as a CSV file, the
result of every comparison, and a results page that a tool writes (never by hand).

| Suite | Reference | Data | Results |
|---|---|---|---|
| `pilot1/` | the R Consortium R Submission Pilot 1 (the CDISC pilot study, reviewed by the FDA in 2022): Tables 14-2.01, 14-3.01, the glucose ANCOVA, Figure 14-1 | the ADaM transport files of that repository | [pilot1/RESULTS.md](pilot1/RESULTS.md) |
| `pharmaverse/` | the pharmaverse examples site: the demographic table and the adverse events table of {rtables} and {tern} | ADSL and ADAE of pharmaverseadam 1.3.0 (`pharmaverse/data`) | [pharmaverse/RESULTS.md](pharmaverse/RESULTS.md) |

## What "the same" means

Each program writes its numbers file with `%ard`: every number of the table with its full value, not the text it
prints. A tool reads every number the reference prints (from its text, its RTF or its PDF, with the place it was read
from) and compares it with the SAS value. A number is the **same** when the reference is the SAS value rounded to the
decimals the reference prints (either way of rounding a tie, as R and SAS round ties differently).

A number that is not the same is never hidden. It is either

- **explained**: the reference computes it another way, and the tool checks the explanation: the way of the reference,
  computed from the SAS numbers, must give the number of the reference (for example a confidence interval with 1.96
  where SAS uses the t quantile); or
- **not made**: no macro makes it; the number is declared with its reason and listed (for example a root mean squared
  error divided by n).

A suite passes when every number is the same, explained or declared, every log is free of ERROR and WARNING, and the
count of numbers read from each reference is the count the reference has (a parser cannot lose a row unseen).

## Run it

[run.sas](run.sas) runs the programs of a suite on your SAS 9.4 and writes their numbers files; each number of
`<suite>/results/*.csv` (its column `sas`) is in them. The comparison with the references was made by the tool of the
development repository, which reads the references at the pinned commits above; its verdicts are the columns
`verdict` and `why` of `results/*.csv` and the pages `RESULTS.md`.
