# Sapling SAS macros

A SAS macro library for the tables, listings and figures of clinical trials, and its proof: the macros give the same
numbers as public pharmaverse references, number by number.

**2,181 of 2,196 numbers of the references are the same in SAS**; 14 more differ for a reason that is explained and
checked, and 1 is a statistic no macro makes. Nothing is left unexplained.

| Reference | Outputs | Numbers | Same | Explained | Not made | Results |
|---|---:|---:|---:|---:|---:|---|
| [R Consortium R Submission Pilot 1](https://github.com/RConsortium/submissions-pilot1/tree/ba1d3e7af60e281def02df11c76c64f8352526f4): the CDISC pilot study, made in R and reviewed by the FDA (demographics, the ADAS-Cog ANCOVA, the glucose ANCOVA, the Kaplan-Meier figure) | 4 | 231 | 228 | 2 | 1 | [proof/pilot1/RESULTS.md](proof/pilot1/RESULTS.md) |
| [pharmaverse examples](https://pharmaverse.github.io/examples) ([bcaacf1](https://github.com/pharmaverse/examples/tree/bcaacf1143fbb1e4f59a46ed14194564a2e72eae)): the demographic and the adverse events table of {rtables} and {tern} on pharmaverseadam | 2 | 1,965 | 1,953 | 12 | 0 | [proof/pharmaverse/RESULTS.md](proof/pharmaverse/RESULTS.md) |

How the numbers are compared, and what "explained" and "not made" mean: [proof/README.md](proof/README.md).

## A program reads like the table it makes

```sas
%study(CDISCPILOT01, program = t14_2_01)

DATA itt;
  SET adam.adsl;
  WHERE ittfl = 'Y';
RUN;

%describe(data=itt, var=age, by=trt01p, label="Age", out=t_age)
%freq(data=itt, var=race, by=trt01p, label="Race", out=t_race)
%stack(t_age t_race, out=t14_2_01)
%columns(data=t14_2_01, n=itt, var=trt01p, order=trt01pn, out=t14_2_01_cols)
%ard(data=t14_2_01, columns=t14_2_01_cols, file=t14_2_01)
%layout(data=t14_2_01, columns=t14_2_01_cols, var=trt01p, file=&spl_out./tlf/t14_2_01, setup=t14_2_01_print, out=t14_2_01_display)

TITLE1 "Table 14-2.01 Summary of Demographic and Baseline Characteristics";
%print(&t14_2_01_print.)
```

Each statistics macro holds the procedure it runs (`%describe` its PROC MEANS, `%freq` its PROC FREQ, `%lsmeans` its
PROC MIXED) and writes a data set in one result shape; `%ard` writes every number with its full value; `%layout` makes
the rows of the table as a data set you can change; `%print` is the only printer (one PROC REPORT into RTF and a
listing). The programs of the proof (`proof/*/programs`) are complete examples.

## Use it

```sas
%LET spl_root = /path/to/sapling-sas;
%INCLUDE "&spl_root./macros/sapling.sas";
```

The manual of every macro, with its parameters and examples: [docs/macros.md](docs/macros.md) (the same as data:
`macros/index.json`). Run the proof on your own SAS 9.4: [proof/run.sas](proof/run.sas).

## License

The macros are **source available, not open source**: you may read them and check the proof, but using them needs a
license of DataStep Labs ([LICENSE](LICENSE)). The data and the references of the proof belong to their owners
([NOTICE](NOTICE)).
