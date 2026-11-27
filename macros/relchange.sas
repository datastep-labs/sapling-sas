/*******************************************************************************
| Macro Name    : relchange.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.9.1
| Created By    : Sapling
| Date          : 27NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : Returns new records with the change from the record before,
|                 relative to the normal range, flagged in ANRIND. Each new
|                 record compares a value with the value of the record before it
|                 in its group (by=, sorted by order=): the change is divided by
|                 half the width of the normal range, so 1 is a change as large
|                 as half the range, and limit=1 flags a change larger than half
|                 the normal range as abnormal. For each record read, the new
|                 record has:
|                 - PARAMCD: prefix= before the code of the record
|                 - AVAL: (value - the value of the record before) / ((upper
|                   limit - lower limit) / 2), rounded to digits= decimals
|                 - ANRIND: H when AVAL is above limit=, L when it is below
|                   -limit=, N between, blank when AVAL is missing
|                 AVAL is missing on the first record of a group, on a record
|                 with no AVISITN, and when a value or a limit is missing or the
|                 upper limit is not above the lower one. For the change from
|                 baseline (CHG = AVAL - BASE), use %baseline and a DATA step.
| Procedure     : PROC SORT, a DATA step (LAG)
| Proven        : the fixtures of the step kind relchange (src/adam_steps.ts;
|                 node tools/adam_steps_sas.ts); ran on SAS 9.4 M9, 2026-11-12
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| data        The input data set, such as adlb; it is not         Required
|             changed
| where       The records to read: a condition in parentheses,    Optional
|             such as where = (paramcd = 'ALT'). The record
|             before is one of these records.
| value       The numeric variable of the measured value, such    Required
|             as lbstresn
| by          The groups: variables separated by blanks. The      USUBJID PARAMCD
|             first record of a group has no record before.
| lo          The numeric variable of the lower limit of the      A1LO
|             normal range
| hi          The numeric variable of the upper limit of the      A1HI
|             normal range
| order       The variables that sort the records of a group and  VISITNUM ADT LBSEQ
|             so give the record before, separated by blanks. A
|             missing value sorts first.
| prefix      The text put before PARAMCD in the new records,     _
|             without quotes
| digits      The number of decimals of AVAL                      1
| limit       The limit of ANRIND, in half ranges: H above        1
|             limit=, L below -limit=. The value 1 is half the
|             normal range.
| reset       The variables that are set missing on the new       BASE CHG BNRIND R2A1LO
|             records, separated by blanks; a variable that       R2A1HI BR2A1LO BR2A1HI
|             data= does not have is skipped
| out         The name of the data set of the new records         Required
| debug       yes: keep the work data sets _relchange_*           no
|-------------------------------------------------------------------------------
|
| Output        : OUT: one new record for each record read, sorted by by= and
|                 order=, with the variables of data=. The limits and the
|                 variables of reset= are missing. PARAMCD keeps its length in
|                 data=, so it must be long enough for the new codes (the
|                 generated programs give it the length of the specification,
|                 which lists them).
|
| Example:
|
 %relchange(
     data  = adlb
   , where = (paramcd = 'ALT' AND MISSING(dtype))
   , value = lbstresn
   , lo    = anrlo
   , hi    = anrhi
   , out   = alt_rel
 )
|
|-------------------------------------------------------------------------------
| Change Log :
| Date        Programmer   Description
|-------------------------------------------------------------------------------
| 12-NOV-2026 Sapling      1.0.0: initial version.
| 12-NOV-2026 Sapling      1.0.0: ran on SAS 9.4 M9.
| 12-NOV-2026 Sapling      1.1.0: the house standard (docs/sas-style.md). No
|                          number changes.
| 16-NOV-2026 Sapling      1.9.0: value= may name AVAL, in any case (the value
|                          is read before AVAL is set; AVAL was empty); ANRIND
|                          keeps its length in data= (length 1 only when data=
|                          has none: a WARNING of two lengths before). The
|                          license line; the example in the house case.
| 27-NOV-2026 Sapling      1.9.1: the example runs on the example data
|                          (sas/examples). The text of the header for the
|                          manual: the summary, the form of each parameter. No
|                          number changes.
| 27-NOV-2026 Sapling      1.9.1: The text says that CHG is a DATA step after
|                          %baseline. No number changes.
| 27-NOV-2026 Sapling      1.9.1: the text says what the macro computes. No
|                          number changes.
|
*******************************************************************************/
%MACRO relchange(
     data   =                    /* The records (not changed) */
   , where  =                    /* The records to read, in parentheses */
   , value  =                    /* The measured value (LBSTRESN) */
   , by     = USUBJID PARAMCD    /* The groups */
   , lo     = A1LO               /* The lower limit */
   , hi     = A1HI               /* The upper limit */
   , order  = VISITNUM ADT LBSEQ /* The order that gives the record before */
   , prefix = _                  /* The prefix of the new PARAMCD */
   , digits = 1                  /* The decimals of AVAL */
   , limit  = 1                  /* ANRIND is H above plus LIMIT, L below minus LIMIT */
   , reset  = BASE CHG BNRIND R2A1LO R2A1HI BR2A1LO BR2A1HI
                                 /* Variables set missing on the new records */
   , out    =                    /* The new records */
   , debug  = no                 /* yes: keep the work data sets _relchange_* */
) / DES = 'New records of the change from the record before, relative to the normal range (LAG)';
  %LOCAL t0 lastby i v dsid rc clear hasind;
  %LET t0 = %_spl_begin(relchange);

  /* Step 1: the parameters */
  %IF not %_spl_need(relchange, data value out) %THEN %RETURN;
  %IF not %_spl_vars(relchange, data, value by) %THEN %RETURN;
  %IF not %_spl_oneof(relchange, debug, yes no) %THEN %RETURN;

  %LET lastby = %SCAN(&by., -1, %STR( ));  /* the last variable of by= */

  /* Step 2: the records in the order that gives the record before */
  DATA _relchange_records;
    SET &data.;
    %IF %LENGTH(%SUPERQ(where)) %THEN %DO;
      IF &where.;
    %END;
  RUN;
  PROC SORT DATA=_relchange_records; BY &by. &order.; RUN;

  /* Step 3: the variables of RESET that the records have; ANRIND keeps its length in DATA */
  %LET dsid = %SYSFUNC(OPEN(_relchange_records));
  %DO i = 1 %TO %SYSFUNC(COUNTW(&reset., %STR( )));
    %LET v = %SCAN(&reset., &i., %STR( ));
    %IF %SYSFUNC(VARNUM(&dsid., &v.)) > 0 %THEN %LET clear = &clear. &v.;
  %END;
  %LET hasind = %SYSFUNC(VARNUM(&dsid., ANRIND));
  %LET rc     = %SYSFUNC(CLOSE(&dsid.));

  /* Step 4: each record: the change from the record before, relative to half the range */
  /* the value is read before AVAL is set: value= may name AVAL itself, in any case */
  DATA &out.;
    %IF &hasind. = 0 %THEN %DO;
      LENGTH anrind $1;
    %END;
    SET _relchange_records;
    BY &by.;
    _relchange_value  = &value.;
    _relchange_before = LAG(_relchange_value);
    IF first.&lastby. THEN _relchange_before = .;
    aval = .;
    IF NOT MISSING(avisitn) AND NMISS(_relchange_value, _relchange_before, &lo., &hi.) = 0 THEN DO;
      IF &hi. > &lo. THEN
        aval = ROUND((_relchange_value - _relchange_before) / ((&hi. - &lo.) / 2), 10 ** -&digits.);
    END;
         IF MISSING(aval)   THEN anrind = ' ';
    ELSE IF aval > &limit.  THEN anrind = 'H';
    ELSE IF aval < -&limit. THEN anrind = 'L';
    ELSE                         anrind = 'N';
    paramcd = CATS("&prefix.", paramcd);
    CALL MISSING(OF &lo. &hi. &clear.);
    DROP _relchange_value _relchange_before;
  RUN;

  /* Step 5: the work data sets are deleted (kept with debug=yes) */
  %IF %UPCASE(&debug.) ne YES %THEN %DO;
    PROC DATASETS LIBRARY=work NOLIST NOWARN;
      DELETE _relchange_:;
    QUIT;
  %END;
  %_spl_end(relchange, &t0., &debug.)
%MEND relchange;
