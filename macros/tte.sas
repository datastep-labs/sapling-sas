/*******************************************************************************
| Macro Name    : tte.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.9.1
| Created By    : Sapling
| Date          : 16NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : One time-to-event parameter in one call: for each subject the
|                 first event, else the latest censoring. With end= an at-risk
|                 period from START to END: only the events and censorings in it
|                 count, else the subject is censored at the end of the period.
| Procedure     : PROC SORT, MERGE
| Proven        : the fixtures of the step kinds tte and tte.period
|                 (src/adam_steps.ts; node tools/adam_steps_sas.ts); ran on SAS
|                 9.4 M9, 2026-11-12
|
| Input Parameters :
|
| Name           Description                                      Default
|-------------------------------------------------------------------------------
| subjects       One record per subject (USUBJID) with START      Required
|                (and END). The result keeps its variables: it
|                must not have ADT, CNSR, AVAL or the values
|                below.
| events         The records the events come from: a data set     Required
| censors        The records of the censorings: the latest date   Optional
|                in the period (on one date the last record).
|                Default: SUBJECTS.
| event          Which records of EVENTS are events: a            Optional
|                condition. Default: all.
| date           The date of an event, a variable of EVENTS       Required
|                (missing: no event)
| time           The time of an event (seconds since midnight),   Optional
|                a variable of EVENTS, for the start day
| priority       Variables of EVENTS that order the events of     Optional
|                one date (a missing value last). Default: the
|                order of the data.
| start          The start of the period and the origin of AVAL,  Required
|                a date of SUBJECTS
| start_time     The time of the start, of SUBJECTS: on the       Optional
|                start day an event counts unless both times are
|                there and the event time is before it
| end            The end of the at-risk period, a date of         Optional
|                SUBJECTS. Without END: no period, every date
|                counts, a date before START is START (as
|                admiral).
| censor_date    The date of a censoring, of CENSORS (or of       Optional
|                SUBJECTS)
| seq            SRCSEQ of an event: a variable of EVENTS.        Optional
|                Default: missing.
| adtf           ADTF of an event: the flag of its date, a        Optional
|                variable of EVENTS
| atmf           ATMF of an event: the flag of its time, a        Optional
|                variable of EVENTS
| keep           Other variables of the record taken, in EVENTS   Optional
|                and CENSORS both (the values of the rows that
|                the program stacked before the call)
| censor_cnsr    CNSR of a censoring: a number, or a variable of  1
|                CENSORS
| end_cnsr       CNSR at the end of the period                    1
| censor_desc    EVNTDESC of a censoring: a text in quotes, or a  Optional
|                variable
| censor_source  SRCDOM of a censoring of SUBJECTS and of the     Optional
|                end of the period, in quotes; SRCVAR is then
|                the name of CENSOR_DATE (of END)
| end_desc       EVNTDESC at the end of the period                "End of at-risk
|                                                                 period"
| event_desc     EVNTDESC of an event: a text in quotes, or a     Optional
|                variable of EVENTS
| source         SRCDOM of an event, in quotes; SRCVAR is then    Optional
|                the name of DATE
| paramcd        PARAMCD, in quotes                               Required
| out            The result (see Output)                          Required
| debug          yes: keep the work data sets _tte_*              no
|-------------------------------------------------------------------------------
|
| Output        : OUT: one record per subject with an event, a censoring or
|                 (with end=) a period: the variables of SUBJECTS, PARAMCD, ADT,
|                 CNSR, AVAL (ADT - START + 1), ATM (with time=) and the values
|                 above, in the order of SUBJECTS. With end= a subject without
|                 START or without END gets no record and a WARNING that names it
|                 (USUBJID=); a subject whose START is after its END gets no
|                 record. Two records of a subject in SUBJECTS are an ERROR.
|
| Example:
|
 %tte(
     subjects      = work.adsl
   , events        = adam.adlb
   , event         = paramcd IN ('ALT', 'AST') AND r2a1hi >= 3
   , date          = adt
   , priority      = paramcd
   , start         = trtsdt
   , end           = dcutdt
   , censor_date   = dcutdt
   , seq           = aseq
   , censor_desc   = "Cutoff date"
   , censor_source = "ADSL"
   , event_desc    = "ALT/AST >= 3x ULN"
   , source        = "ADLB"
   , paramcd       = "DIL3X"
   , out           = work.dil3x
 )
|
|-------------------------------------------------------------------------------
| Change Log :
| Date        Programmer   Description
|-------------------------------------------------------------------------------
| 12-NOV-2026 Sapling      1.0.0: initial version: one call is one parameter,
|                          after the ideas of %adtte_obs (the at-risk period,
|                          the start day and its times, the priority, the end
|                          of the period, the traceability SRCDOM, SRCVAR,
|                          SRCSEQ, ADTF).
| 12-NOV-2026 Sapling      1.0.0: ran on SAS 9.4 M9 on the fixtures.
| 12-NOV-2026 Sapling      1.1.0: the house standard (docs/sas-style.md): header,
|                          signature, typed checks, numbered steps, log lines.
|                          No number changes.
| 16-NOV-2026 Sapling      1.9.0: the license line; the example in the house
|                          case (names in lower case). No number changes.
|
*******************************************************************************/
%MACRO tte(
     subjects      =        /* One record per subject, with START and END */
   , events        =        /* The records the events come from */
   , censors       =        /* The records of the censorings (default SUBJECTS) */
   , event         =        /* A condition: the records of EVENTS that are events */
   , date          =        /* The date of an event */
   , time          =        /* The time of an event (the start day) */
   , priority      =        /* The order of the events of one date */
   , start         =        /* The start of the period, a date of SUBJECTS */
   , start_time    =        /* The time of the start */
   , end           =        /* The end of the at risk period, a date of SUBJECTS */
   , censor_date   =        /* The date of a censoring */
   , seq           =        /* SRCSEQ of an event */
   , adtf          =        /* ADTF of an event */
   , atmf          =        /* ATMF of an event */
   , keep          =        /* Other variables of the record taken */
   , censor_cnsr   = 1      /* CNSR of a censoring */
   , end_cnsr      = 1      /* CNSR at the end of the period */
   , censor_desc   =        /* EVNTDESC of a censoring */
   , censor_source =        /* SRCDOM of a censoring of SUBJECTS and of the end */
   , end_desc      = "End of at-risk period"
                            /* EVNTDESC at the end of the period */
   , event_desc    =        /* EVNTDESC of an event */
   , source        =        /* SRCDOM of an event */
   , paramcd       =        /* PARAMCD, in quotes */
   , out           =        /* The result */
   , debug         = no     /* yes: keep the work data sets _tte_* */
) / DES = 'One time-to-event parameter: the first event, else the latest censoring (PROC SORT)';
  %LOCAL t0 i dsn token keys made period evdrop;
  %LET t0 = %_spl_begin(tte);

  /* Step 1: the parameters: the data sets exist, the variables are in them */
  %IF not %_spl_need(tte, subjects events date start paramcd out) %THEN %RETURN;
  %IF not %_spl_oneof(tte, debug, yes no) %THEN %RETURN;
  %DO i = 1 %TO 3;
    %LET dsn = %SCAN(subjects events censors, &i.);
    %IF %LENGTH(%SUPERQ(&dsn.)) %THEN %DO;
      %IF not %SYSFUNC(EXIST(%SCAN(%SUPERQ(&dsn.), 1, %STR(%()))) %THEN %DO;
        %PUT %STR(ERR)OR: [tte] &dsn.=%SCAN(%SUPERQ(&dsn.), 1, %STR(%()) does not exist;
        %PUT %STR(ERR)OR: [tte]   fix: give &dsn.= a data set that exists (make it first).;
        %RETURN;
      %END;
    %END;
  %END;
  %IF not %_spl_vars(tte, subjects, start start_time end) %THEN %RETURN;
  %IF not %_spl_vars(tte, events, date time priority seq adtf atmf keep) %THEN %RETURN;
  %IF %LENGTH(%SUPERQ(censors)) %THEN %DO;
    %IF %LENGTH(%SUPERQ(censor_date)) = 0 %THEN %DO;
      %PUT %STR(ERR)OR: [tte] censors=&censors. has no date;
      %PUT %STR(ERR)OR: [tte]   fix: give censor_date= the date of a censoring in it.;
      %RETURN;
    %END;
    %IF not %_spl_vars(tte, censors, censor_date keep) %THEN %RETURN;
  %END;
  %ELSE %IF not %_spl_vars(tte, subjects, censor_date) %THEN %RETURN;
  %IF %LENGTH(&end.) = 0 and (%LENGTH(&time.) or %LENGTH(&start_time.)) %THEN %DO;
    %PUT %STR(ERR)OR: [tte] time= and start_time= are the rule of the start day of a period;
    %PUT %STR(ERR)OR: [tte]   fix: give end= (or neither).;
    %RETURN;
  %END;

  /* the variables of the period that the steps below take from the subjects */
  %LET period = _tte_start _tte_end;  /* the variables of the at risk period */
  %IF %LENGTH(&start_time.) %THEN %LET period = &period. _tte_starttm;  /* plus the start time */

  /* Step 2: the subjects in their order, with the start (and the end) of each */
  DATA _tte_subjects;
    SET &subjects.;
    _tte_row   = _N_;
    _tte_start = &start.;
    %IF %LENGTH(&start_time.) %THEN %DO;
      _tte_starttm = &start_time.;
    %END;
    %IF %LENGTH(&end.) %THEN %DO;
      _tte_end = &end.;
      /* a subject without its period is reported, not left out in silence */
      IF MISSING(_tte_start) THEN DO;
        PUT "WAR" "NING: [tte] " &paramcd. ": no start date (start=&start.): no record, "
            "give the subject a start date " usubjid=;
        DELETE;
      END;
      IF MISSING(_tte_end) THEN DO;
        PUT "WAR" "NING: [tte] " &paramcd. ": no end of the at-risk period (end=&end.): no record, "
            "give the subject an end date " usubjid=;
        DELETE;
      END;
      IF _tte_start > _tte_end THEN DELETE;
    %END;
  RUN;
  PROC SORT DATA=_tte_subjects; BY usubjid; RUN;
  DATA _NULL_;
    SET _tte_subjects;
    BY usubjid;
    IF FIRST.usubjid AND NOT LAST.usubjid THEN
      PUT "ERR" "OR: [tte] more than one record of the subject in subjects=&subjects.: "
          "give one record per subject " usubjid=;
  RUN;

  /* Step 3: the events: the records of EVENTS that meet EVENT, with a date, and their order */
  DATA _tte_events;
    %IF %LENGTH(%SUPERQ(event_desc)) %THEN %DO;
      LENGTH evntdesc $200;
    %END;
    %IF %LENGTH(%SUPERQ(source)) %THEN %DO;
      LENGTH srcdom srcvar $32;
    %END;
    SET &events.;
    %IF %LENGTH(%SUPERQ(event)) %THEN %DO;
      IF &event.;
    %END;
    _tte_date = &date.;
    IF NOT MISSING(_tte_date);
    _tte_n = _N_;
    %LET made   = ;
    %LET evdrop = _tte_n;
    %IF %LENGTH(&time.) %THEN %DO;
      %LET evdrop = &evdrop. _tte_time;
      _tte_time = &time.;
      atm       = &time.;
      %LET made = &made. _tte_time atm;
    %END;
    %IF %LENGTH(%SUPERQ(event_desc)) %THEN %DO;
      evntdesc = &event_desc.;
      %LET made = &made. evntdesc;
    %END;
    %IF %LENGTH(%SUPERQ(source)) %THEN %DO;
      srcdom = &source.;
      srcvar = "%UPCASE(&date.)";
      %IF %LENGTH(&seq.) %THEN %DO;
        srcseq = &seq.;
      %END;
      %ELSE %DO;
        srcseq = .;
      %END;
      %LET made = &made. srcdom srcvar srcseq;
    %END;
    %IF %LENGTH(&adtf.) %THEN %DO;
      adtf = &adtf.;
      %LET made = &made. adtf;
    %END;
    %IF %LENGTH(&atmf.) %THEN %DO;
      atmf = &atmf.;
      %LET made = &made. atmf;
    %END;
    /* two events of one date: in the order of PRIORITY, a missing value last */
    %LET keys = ;
    %DO i = 1 %TO %SYSFUNC(COUNTW(&priority., %STR( )));
      %LET token = %SCAN(&priority., &i., %STR( ));
      _TTE_M&i. = MISSING(&token.);
      %LET keys   = &keys. _tte_m&i. &token.;
      %LET evdrop = &evdrop. _tte_m&i. &token.;
    %END;
    KEEP usubjid _tte_date _tte_n &keys. &made. &keep.;
  RUN;
  PROC SORT DATA=_tte_events; BY usubjid _tte_date &keys. _tte_n; RUN;

  /* Step 4: the events in the period (with end=) */
  /* An event counts after the start and on or before the end, or on the start day (with both
     times there: not before the start time). */
  %IF %LENGTH(&end.) %THEN %DO;
    DATA _tte_events;
      MERGE _tte_events(IN=_tte_inevent) _tte_subjects(KEEP=usubjid &period. IN=_tte_insubject);
      BY usubjid;
      IF _tte_inevent AND _tte_insubject;
      %IF %LENGTH(&time.) and %LENGTH(&start_time.) %THEN %DO;
        IF (_tte_start < _tte_date <= _tte_end) OR (_tte_date = _tte_start AND (MISSING(_tte_time)
          OR MISSING(_tte_starttm) OR _tte_time >= _tte_starttm));
      %END;
      %ELSE %DO;
        IF _tte_start <= _tte_date <= _tte_end;
      %END;
      DROP &period.;
    RUN;
  %END;

  /* Step 5: the first event of each subject */
  DATA _tte_taken;
    SET _tte_events;
    BY usubjid;
    IF FIRST.usubjid;
    _tte_cnsr = 0;
    DROP &evdrop.;
  RUN;

  /* Step 6: the censorings (with censor_date=) */
  /* The records of CENSORS (or SUBJECTS) with a date; with end= those in the period (both ends
     in); the latest of each subject; then the event when there is one, else the censoring. */
  %IF %LENGTH(%SUPERQ(censor_date)) %THEN %DO;
    DATA _tte_censors;
      %IF %LENGTH(%SUPERQ(censor_desc)) %THEN %DO;
        LENGTH evntdesc $200;
      %END;
      %IF %LENGTH(%SUPERQ(censors)) = 0 and %LENGTH(%SUPERQ(censor_source)) %THEN %DO;
        LENGTH srcdom srcvar $32;
      %END;
      %IF %LENGTH(%SUPERQ(censors)) %THEN %DO;
        SET &censors.;
      %END;
      %ELSE %DO;
        SET &subjects.;
      %END;
      _tte_date = &censor_date.;
      IF NOT MISSING(_tte_date);
      _tte_n    = _N_;
      _tte_cnsr = &censor_cnsr.;
      %LET made = ;
      %IF %LENGTH(%SUPERQ(censor_desc)) %THEN %DO;
        evntdesc = &censor_desc.;
        %LET made = &made. evntdesc;
      %END;
      %IF %LENGTH(%SUPERQ(censors)) = 0 and %LENGTH(%SUPERQ(censor_source)) %THEN %DO;
        srcdom = &censor_source.;
        srcvar = "%UPCASE(&censor_date.)";
        %LET made = &made. srcdom srcvar;
      %END;
      %IF %LENGTH(%SUPERQ(censors)) %THEN %LET made = &made. &keep.;
      KEEP usubjid _tte_date _tte_n _tte_cnsr &made.;
    RUN;
    PROC SORT DATA=_tte_censors; BY usubjid _tte_date _tte_n; RUN;
    %IF %LENGTH(&end.) %THEN %DO;
      DATA _tte_censors;
        MERGE _tte_censors(IN=_tte_incensor)
              _tte_subjects(KEEP=usubjid _tte_start _tte_end IN=_tte_insubject);
        BY usubjid;
        IF _tte_incensor AND _tte_insubject;
        IF _tte_start <= _tte_date <= _tte_end;
        DROP _tte_start _tte_end;
      RUN;
    %END;
    DATA _tte_censors;
      SET _tte_censors;
      BY usubjid;
      IF LAST.usubjid;
      DROP _tte_n;
    RUN;
    DATA _tte_taken;
      SET _tte_taken _tte_censors;
      BY usubjid;
      IF FIRST.usubjid;
    RUN;
  %END;

  /* Step 7: one record per subject: the record taken; with end=, else the end of the period */
  DATA &out.;
    %IF %LENGTH(&end.) %THEN %DO;
      LENGTH evntdesc $200;
      %IF %LENGTH(%SUPERQ(censor_source)) %THEN %DO;
        LENGTH srcdom srcvar $32;
      %END;
    %END;
    MERGE _tte_subjects(IN=_tte_insubject) _tte_taken(IN=_tte_intaken);
    BY usubjid;
    IF _tte_insubject;
    IF _tte_intaken THEN DO;
      adt  = _tte_date;
      cnsr = _tte_cnsr;
    END;
    %IF %LENGTH(&end.) %THEN %DO;
      ELSE DO;
        adt      = _tte_end;
        cnsr     = &end_cnsr.;
        evntdesc = &end_desc.;
        %IF %LENGTH(%SUPERQ(censor_source)) %THEN %DO;
          srcdom = &censor_source.;
          srcvar = "%UPCASE(&end.)";
        %END;
      END;
    %END;
    %ELSE %DO;
      ELSE DELETE;
      /* without a period a date before the start is the start (as admiral) */
      IF NMISS(adt, _tte_start) = 0 AND adt < _tte_start THEN adt = _tte_start;
    %END;
    paramcd = &paramcd.;
    IF NMISS(adt, _tte_start) = 0 THEN aval = adt - _tte_start + 1;
    FORMAT adt DATE9.;
    DROP _tte_date _tte_cnsr _tte_start;
    %IF %LENGTH(&end.) %THEN %DO;
      DROP &period.;
    %END;
  RUN;
  PROC SORT DATA=&out. OUT=&out.(DROP=_tte_row); BY _tte_row; RUN;

  /* Step 8: the work data sets are deleted (kept with debug=yes) */
  %IF %UPCASE(&debug.) ne YES %THEN %DO;
    PROC DATASETS LIBRARY=work NOLIST NOWARN;
      DELETE _tte_:;
    QUIT;
  %END;
  %_spl_end(tte, &t0., &debug.)
%MEND tte;
