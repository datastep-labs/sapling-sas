/*******************************************************************************
| Program       : setup.sas
| SAS Version   : SAS 9.4
| Created By    : Sapling
| Date          : 27NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Purpose       : The example data of the macro library, ready for the examples of
|                 the manual: run this program first, then the examples in the
|                 order of the page "Run the examples of the reference"
|                 (https://datastep-labs.github.io/sapling-sas/how-to/run-the-examples/).
|                 The data are data sets of the R packages pharmaverseadam 1.3.0
|                 and pharmaversesdtm 1.4.0 (Apache License 2.0; data/NOTICE), the
|                 subjects of the CDISC pilot study, written as transport files by
|                 data/make_data.R.
| Output        : the ADaM data sets in <spl_root>/examples/adam (library ADAM),
|                 DS and EX in <spl_root>/examples/sdtm (library SDTM), the WORK
|                 data sets adsl (the safety population), adae, advs, adlb, adtte
|                 and adrs, the formats VISIT. and $SEXF., and the output folder
|                 <spl_root>/examples/out (SPL_OUT, set by %study).
*******************************************************************************/
%LET spl_root = /path/to/sapling-sas;  /* the folder that holds macros/ and examples/ */
%INCLUDE "&spl_root./macros/sapling.sas";

/* the folders of the data sets are made when they are missing */
OPTIONS DLCREATEDIR;
%import_xpt(
    dir     = &spl_root./examples/data
  , members = adsl adae advs adlb adtte adrs
  , out     = &spl_root./examples/adam
)
%import_xpt(dir=&spl_root./examples/data, members=ds ex, out=&spl_root./examples/sdtm)

%study(
    CDISCPILOT01
  , program = examples
  , adam    = &spl_root./examples/adam
  , out     = &spl_root./examples/out
)
LIBNAME sdtm "&spl_root./examples/sdtm" ACCESS=READONLY;

/* ADSL holds every subject: the examples use the safety population */
DATA adsl;
  SET adam.adsl;
  WHERE saffl = 'Y';
RUN;

/* the other data sets hold the subjects of the safety population only */
DATA adae;
  SET adam.adae;
RUN;
DATA advs;
  SET adam.advs;
RUN;
/* PARAMCD of ADLB is $3 (ALT, AST): $8 holds the codes that %relchange adds (_ALT) */
DATA adlb;
  LENGTH paramcd $8;
  SET adam.adlb;
RUN;
DATA adtte;
  SET adam.adtte;
RUN;
DATA adrs;
  SET adam.adrs;
RUN;

/* the visits of ADVS (AVISITN, in weeks) and the decode of SEX */
PROC FORMAT;
  VALUE visit
    0 = 'Baseline'
    2 = 'Week 2'
    4 = 'Week 4'
    6 = 'Week 6'
    8 = 'Week 8'
    12 = 'Week 12'
    16 = 'Week 16'
    20 = 'Week 20'
    24 = 'Week 24'
    26 = 'Week 26'
    99 = 'End of Treatment';
  VALUE $sexf
    'F' = 'Female'
    'M' = 'Male';
RUN;
