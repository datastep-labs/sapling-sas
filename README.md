# Sapling SAS macros

A SAS macro library for the tables, listings and figures of clinical trials, and its proof: the macros give the same
numbers as public pharmaverse references, number by number.

**The manual: [https://datastep-labs.github.io/sapling-sas/](https://datastep-labs.github.io/sapling-sas/)**: a tutorial, how-to guides, a reference page for every macro with
its example and the real output of that example, and the explanation of the design and the proof.

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

How to load the library in your own program: [Use the macros in your own program](https://datastep-labs.github.io/sapling-sas/how-to/own-program/).
The reference of every macro, with its parameters, examples and their output: [the manual](https://datastep-labs.github.io/sapling-sas/reference/)
(the same as data: `macros/index.json`). Run the proof on your own SAS 9.4: [proof/run.sas](proof/run.sas).

## Examples

Every example of the manual runs on the example data in [examples/data](examples/data): data sets of the R packages
pharmaverseadam and pharmaversesdtm (the subjects of the CDISC pilot study, [examples/data/NOTICE](examples/data/NOTICE)).
Set `spl_root` in [examples/setup.sas](examples/setup.sas) to the folder of this repository and run it first: it reads
the transport files and makes the WORK data sets the examples use. Then run [examples/tutorial.sas](examples/tutorial.sas)
(the tutorial) or [examples/reference.sas](examples/reference.sas) (every example of the reference), or the examples of the reference in the order
of [Run the examples of the reference](https://datastep-labs.github.io/sapling-sas/how-to/run-the-examples/) (an example may use the results of the
ones before it). Under each example the manual shows what it gave on SAS 9.4: its result data sets, the listing of a
table, the figure.

## License

The macros are **source available, not open source**: the code and the proof are public to read. The terms of use are
in the [LICENSE](LICENSE) of DataStep Labs. The data and the references of the proof belong to their owners
([NOTICE](NOTICE)).
