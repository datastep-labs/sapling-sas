/*******************************************************************************
| Macro Name    : relchange.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.9.1
| Created By    : Sapling
| Date          : 16NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : New records of the change from the record before, relative to
|                 the normal range (the pilot SAP 8.3: a change larger than half
|                 the normal range is abnormal). For each record: a record of
|                 the parameter PREFIX + PARAMCD whose AVAL is (value - the
|                 value of the record before) / ((upper - lower limit) / 2),
|                 rounded as ROUND; ANRIND H above +LIMIT, L below -LIMIT, else
|                 N.
| Procedure     : PROC SORT, a DATA step (LAG)
| Proven        : the fixtures of the step kind relchange (src/adam_steps.ts;
|                 node tools/adam_steps_sas.ts); ran on SAS 9.4 M9, 2026-11-12
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| data        The records (not changed)                           Required
| where       The records to read, a condition in parentheses     Optional
|             (the record before is one of them)
| value       The measured value (LBSTRESN)                       Required
| by          The groups (default USUBJID PARAMCD)                USUBJID PARAMCD
| lo          The limits (default A1LO, A1HI)                     A1LO
| hi          The limits (default A1LO, A1HI)                     A1HI
| order       The order that gives the record before (default     VISITNUM ADT LBSEQ
|             VISITNUM ADT LBSEQ; a missing value sorts first)
| prefix      The prefix of the new PARAMCD (default _)           _
| digits      The decimals of AVAL (default 1)                    1
| limit       ANRIND is H above +LIMIT and L below -LIMIT         1
|             (default 1: half the range)
| reset       The variables set missing on the new records,       BASE CHG BNRIND R2A1LO
|             those that DATA has (default BASE CHG BNRIND        R2A1HI BR2A1LO BR2A1HI
|             R2A1LO R2A1HI BR2A1LO BR2A1HI); the limits are set
|             missing too
| out         The new records: one for each record of DATA,       Required
|             sorted by BY and ORDER
| debug       yes: keep the work data sets _relchange_*           no
|-------------------------------------------------------------------------------
|
| Output        : OUT: has the variables of DATA. AVAL has a value on a scheduled
|                 visit (AVISITN not missing) when the value, the value before
|                 and both limits are there and the upper limit is above the
|                 lower one; it is missing on the first record of a group.
|                 PARAMCD keeps its length in DATA: it must hold the new codes
|                 (the generated programs give it the length of the
|                 specification, which lists them).
|
| Example:
|
 %relchange(
     data  = work.adlbc
   , value = lbstresn
   , out   = work._relchange
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
