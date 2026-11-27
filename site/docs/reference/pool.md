# %pool

Pools small groups, such as sites, into one group: a new variable that is the group, or the pooled value.

**Procedure:** PROC FREQ, PROC SUMMARY, MERGE · **Family:** [ADaM steps](index.md#adam)

## Syntax

```sas
%pool(
     data   =
   , var    =
   , by     =
   , min    =
   , length =
   , new    =
   , into   =
   , debug  = no
 )
```

## Parameters

`data=`
:   The data set to change in place, one record per subject, such as adsl. *(required)*

`var=`
:   The variable of the groups to pool, such as siteid. *(required)*

`by=`
:   The variable whose every group must have `min=` records in a group of `var=`, such as the treatment. *(required)*

`min=`
:   The smallest number of records: a whole number. *(required)*

`length=`
:   The length of the new variable, such as $3. *(optional)*

`new=`
:   The name of the new variable: the value of `var=`, or `into=` for a small group. *(required)*

`into=`
:   The value of the pooled group, without quotes. *(required)*

`debug=`
:   yes: keep the work data sets _pool_*. *(optional, default `no`)*
    Accepts: `yes`, `no`.

## Result

The data sets: `data=`, changed in place: the variable `new=`, with the value of `var=`, or the value of `into=` for a small group.

## Details

A group of `var=` goes into the pooled group when it has fewer than `min=` records in one of the groups of `by=`, such as a treatment. The macro counts records: in a data set with one record per subject, such as adsl, these are the subjects. A group that has no record in a group of `by=` counts 0 there and is pooled. The rows of `data=` keep their order.

## Examples

The examples run on the [example data](../tutorial/index.md#the-example-data) after `examples/setup.sas`. The output under each call is the output of that run. All examples of the reference run as one program: [examples/reference.sas](https://github.com/datastep-labs/sapling-sas/blob/main/examples/reference.sas).

Copies the subjects with their site and their planned treatment.

```sas
DATA sl;
  SET adsl;
  KEEP usubjid siteid trt01p;
RUN;
```

Pools each site with fewer than 3 subjects in a group into the site group 900.

```sas
%pool(
     data   = sl
   , var    = siteid
   , by     = trt01p
   , min    = 3
   , length = $3
   , new    = sitegr1
   , into   = 900
 )
```

```text
sl: each site and its pooled group: the first 15 of 17 rows
SITEID  SITEGR1
   701      701
   702      900
   703      703
   704      704
   705      705
   706      900
   707      900
   708      708
   709      709
   710      710
   711      900
   713      713
   714      900
   715      900
   716      716
```

## Messages

The macro gives only the [messages every macro shares](index.md#messages-every-macro-shares).

## See also

ADaM steps: [%merge_subject](merge_subject.md), [%pick](pick.md), [%summarize](summarize.md), [%summarize_groups](summarize_groups.md), [%baseline](baseline.md), [%flag_first](flag_first.md), [%flag_if_any](flag_if_any.md), [%windows](windows.md), [%visits](visits.md), [%locf](locf.md), [%relchange](relchange.md), [%param_wide](param_wide.md), [%tte](tte.md).

## Proof

Checked on its test cases of the pooled groups (small made-up records): every value the same as that of the expected records; ran on SAS 9.4 M9, 2026-11-12.

The known answers and test cases are kept with the development of the library, not in this repository.

The examples of this page ran on SAS 9.4 M9 on 2026-11-27, with a log free of ERROR and WARNING.

[Source of %pool](https://github.com/datastep-labs/sapling-sas/blob/main/macros/pool.sas)
