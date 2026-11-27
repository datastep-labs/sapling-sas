# Check a table against an independent program

This guide shows how to check every number of a table against the numbers of a second program, as in double
programming. You compare the numbers file of the table with the numbers of the check program in PROC COMPARE, and
get a report that lists each difference.

## Before you start

- Submit `examples/setup.sas`, or start your own program as [Use the macros in your own program](own-program.md)
  shows.
- Have the program of the table. It must write the numbers file with `%ard` (or `%table` with `file=`). The guide
  checks a table of age and sex as in the [tutorial](../tutorial/index.md).

## Steps

### 1. Run the program of the table

This is the program the guide checks. `%ard` writes its numbers file, `ard/t_dm.csv` in the output folder:

```sas
%describe(
     data  = adsl
   , var   = age
   , by    = trt01a
   , total = yes
   , label = "Age (years)"
   , out   = t_age
 )
%freq(
     data  = adsl
   , var   = sex
   , by    = trt01a
   , total = yes
   , label = "Sex"
   , out   = t_sex
 )
%stack(t_age t_sex, out=t_dm)
%columns(
     data  = t_dm
   , n     = adsl
   , var   = trt01a
   , order = trt01an
   , total = yes
   , out   = t_dm_cols
 )
%ard(data=t_dm, columns=t_dm_cols, file=t_dm)
```

```text
ard/t_dm.csv: the first 6 of 45 lines
result,stat,g1_value,g2_value,g3_value,g4_value,g5_value,raw,formatted
N,n,Placebo,,,,,86,(N=86)
N,n,Xanomeline Low Dose,,,,,96,(N=96)
N,n,Xanomeline High Dose,,,,,72,(N=72)
N,n,Total,,,,,254,(N=254)
T_AGE,n,Placebo,,,,,86,86
```

### 2. Read the numbers file

Each line of the numbers file holds one number: its result, its statistic, the values of its groups, the number
written with the format `BEST32.` (`raw`: at most 15 significant digits, the last one cut, not rounded; see
[How a number is kept and printed](../explanation/numbers.md#the-numbers-file)), and its printed text (`formatted`). Read it with a DATA step:

```sas
DATA prod;
  INFILE "&spl_out./ard/t_dm.csv" DSD FIRSTOBS=2 TRUNCOVER;
  LENGTH result stat $32 g1_value g2_value g3_value g4_value g5_value formatted $200;
  INPUT result stat g1_value g2_value g3_value g4_value g5_value raw formatted;
RUN;
```

```text
prod: the first 8 of 44 rows
RESULT  STAT    G1_VALUE              G2_VALUE           RAW  FORMATTED
N       n       Placebo                                   86  (N=86)
N       n       Xanomeline Low Dose                       96  (N=96)
N       n       Xanomeline High Dose                      72  (N=72)
N       n       Total                                    254  (N=254)
T_AGE   n       Placebo                                   86  86
T_AGE   mean    Placebo                         75.209302326  75.2
T_AGE   sd      Placebo                         8.5901671271  8.59
T_AGE   median  Placebo                                   76  76.0
```

The first lines (result `N`) hold the N of each column. The other lines hold the numbers of the results, named as
the results of the table program (`T_AGE`, `T_SEX`).

### 3. Compute the same numbers in the check program

Compute each number again with SAS procedures, without the macros. Write it in the same form: one row per number,
with the same `result`, `stat` and group values. Add the group `Total` as a copy of every subject. `%study` sets
`VALIDVARNAME=UPCASE`, so `VNAME` gives the name of a statistic in upper case: `LOWCASE` makes it the `stat` of the
numbers file.

```sas
DATA qc_adsl;
  SET adsl;
  OUTPUT;
  trt01a = 'Total';
  OUTPUT;
RUN;

PROC FREQ DATA=qc_adsl NOPRINT;
  TABLES trt01a / OUT=qc_n;
  TABLES trt01a * sex / OUTPCT OUT=qc_sex;
RUN;

PROC MEANS DATA=qc_adsl NOPRINT NWAY;
  CLASS trt01a;
  VAR age;
  OUTPUT OUT=qc_age N=n MEAN=mean STD=sd MEDIAN=median MIN=min MAX=max;
RUN;

DATA qc;
  LENGTH result stat $32 g1_value g2_value $200;
  SET qc_n(IN=in_n) qc_age(IN=in_age) qc_sex(IN=in_sex);
  ARRAY s {*} n mean sd median min max;
  g1_value = trt01a;
  IF in_n THEN DO;
    result = 'N';
    stat   = 'n';
    raw    = count;
    OUTPUT;
  END;
  ELSE IF in_age THEN DO;
    result = 'T_AGE';
    DO i = 1 TO DIM(s);
      stat = LOWCASE(VNAME(s{i}));
      raw  = s{i};
      OUTPUT;
    END;
  END;
  ELSE IF in_sex THEN DO;
    result   = 'T_SEX';
    g2_value = sex;
    stat     = 'n';
    raw      = count;
    OUTPUT;
    stat = 'pct';
    raw  = pct_row;
    OUTPUT;
  END;
  KEEP result stat g1_value g2_value raw;
RUN;
```

### 4. Compare the two

Sort both by the keys of a number. Then compare `raw` in PROC COMPARE, and write the report to a file:

```sas
PROC SORT DATA=prod;
  BY result stat g1_value g2_value;
RUN;
PROC SORT DATA=qc;
  BY result stat g1_value g2_value;
RUN;

OPTIONS DLCREATEDIR;
LIBNAME checks "&spl_out./qc";
ODS LISTING FILE="&spl_out./qc/t_dm_compare.lst";
PROC COMPARE BASE=prod COMPARE=qc OUT=checks.t_dm_diff OUTNOEQUAL METHOD=RELATIVE CRITERION=1E-10;
  ID result stat g1_value g2_value;
  VAR raw;
RUN;
%LET compare_code = &sysinfo.;
ODS LISTING CLOSE;
ODS LISTING;
```

```text
qc/t_dm_compare.lst: 39 lines
The COMPARE Procedure
Comparison of WORK.PROD with WORK.QC
(Method=RELATIVE, Criterion=1.0E-10)

Data Set Summary

Dataset             Created          Modified  NVar    NObs

WORK.PROD  27NOV26:13:44:21  27NOV26:13:44:21     9      44
WORK.QC    27NOV26:13:44:21  27NOV26:13:44:21     5      44

Variables Summary

Number of Variables in Common: 5.
Number of Variables in WORK.PROD but not in WORK.QC: 4.
Number of ID Variables: 4.
Number of VAR Statement Variables: 1.

Observation Summary

Observation      Base  Compare  ID

First Obs           1        1  RESULT=N STAT=n G1_VALUE=Placebo G2_VALUE=
Last  Obs          44       44  RESULT=T_SEX STAT=pct G1_VALUE=Xanomeline Low Dose G2_VALUE=M

Number of Observations in Common: 44.
Total Number of Observations Read from WORK.PROD: 44.
Total Number of Observations Read from WORK.QC: 44.

Number of Observations with Some Compared Variables Unequal: 0.
Number of Observations with All Compared Variables Equal: 44.

Values Comparison Summary

Number of Variables Compared with All Observations Equal: 1.
Number of Variables Compared with Some Observations Unequal: 0.
Total Number of Values which Compare Unequal: 0.
Total Number of Values not EXACTLY Equal: 14.
Maximum Difference Criterion Value: 1.6592E-15.
```

The report says that the two data sets have all 44 numbers in common and that no value differs by more than the
criterion. 14 values are not exactly equal: the numbers file holds at most 15 significant digits, with the last one cut, and
`METHOD=RELATIVE CRITERION=1E-10` accepts a difference in the last digits.

### 5. Decide from the return code

An empty `OUT=` data set is not enough: it holds only the numbers that are in both data sets, so a number that one
program has and the other does not never reaches it. Decide from the return code of PROC COMPARE, which step 4 kept
in `&compare_code.`. Four of its bits matter: 64 (a number only in the numbers file), 128 (a number only in the
check program), 4096 (a value outside the criterion) and 32768 (the comparison could not be done):

```sas
DATA verdict;
  LENGTH verdict $80;
  compare_code = &compare_code.;
  IF BAND(compare_code, 64 + 128 + 4096 + 32768) = 0 THEN
    verdict = 'checked: the same numbers on both sides, every value within the criterion';
  ELSE verdict = 'not checked: read the report of PROC COMPARE';
RUN;
```

```text
verdict: 1 row
VERDICT                                                                    COMPARE_CODE
checked: the same numbers on both sides, every value within the criterion             0
```

If the verdict is "not checked", the report lists the numbers in one data set only and the values that differ. Find
each number by its `result`, `stat` and group values, and look at the program that computed it.

This compares the values (`raw`). It does not check the printed text: a wrong pattern, such as one decimal where the
shell asks for two, prints the right value wrongly. To check the text too, write your own text of each value with
`PUTN` and the pattern of the shell, and compare it with `formatted`.

## Related

- Reference: [%ard](../reference/ard.md), [%table](../reference/table.md).
- Explanation: [How a number is kept and printed](../explanation/numbers.md),
  [What the proof shows](../explanation/proof.md).
