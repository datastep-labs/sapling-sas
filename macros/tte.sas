/*******************************************************************************
| Macro Name    : tte.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.10.0
| Created By    : Sapling
| Date          : 27NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : Returns one time-to-event parameter: for each subject the date
|                 of the first event, or else of the latest censoring. It writes
|                 the records of an ADTTE parameter; %km, %logrank and %cox then
|                 analyse them. The rule:
|                 - An event is a record of events= that meets event= and has a
|                   date. The first event of a subject is taken; priority=
|                   orders the events of one date.
|                 - When a subject has no event, the latest censoring is taken:
|                   the latest date of censors= (or of subjects=); on one date,
|                   the last record.
|                 - AVAL is ADT - START + 1, in days.
|                 Without end=, every date counts, and a date before START
|                 becomes START (as admiral does). A subject with no event and
|                 no censoring date gets no record, and the log has a NOTE with
|                 the number of such subjects. With end=, the at-risk period
|                 runs from START to END: only the events and censorings in it
|                 count, and a subject with neither is censored at END. An event
|                 on the start day counts unless time= and start_time= are both
|                 there and the event time is before the start time.
| Procedure     : PROC SORT, MERGE
| Proven        : Checked on its test cases of the time to an event, also within
|                 a period (small made-up records): every value the same as that
|                 of the expected records; ran on SAS 9.4 M9, 2026-11-12
|
| Input Parameters :
|
| Name           Description                                      Default
|-------------------------------------------------------------------------------
| subjects       The data set of the subjects, one record per     Required
|                subject (USUBJID), with the start (and the end)
|                of the period. The result keeps its variables,
|                so it must not have ADT, CNSR, AVAL or the
|                other variables the macro makes.
| events         The data set of the records the events come      Required
|                from, such as adae
| censors        The data set of the records of the censorings,   Optional
|                with censor_date=. When not given, the
|                censorings come from subjects=.
| event          The records of events= that are events: a        Optional
|                condition, such as event = trtemfl = 'Y'. When
|                not given, every record with a date is an
|                event.
| date           The date of an event: a numeric date variable    Required
|                of events=. A record with a missing date is no
|                event.
| time           The time of an event: a numeric variable of      Optional
|                events=, in seconds since midnight. It decides
|                an event on the start day, and needs end=.
| priority       The variables of events= that order the events   Optional
|                of one date, separated by blanks; a missing
|                value sorts last. When not given, the events of
|                one date keep the order of the data.
| start          The start of the period and the origin of AVAL:  Required
|                a date variable of subjects=
| start_time     The time of the start: a numeric variable of     Optional
|                subjects=, in seconds since midnight. On the
|                start day an event counts unless its time is
|                before this time. It needs end=.
| end            The end of the at-risk period: a date variable   Optional
|                of subjects=. When not given, there is no
|                period and every date counts.
| censor_date    The date of a censoring: a date variable of      Optional
|                censors= (or of subjects=)
| seq            The variable of events= that gives SRCSEQ of an  Optional
|                event, such as aeseq. When not given, SRCSEQ is
|                missing.
| adtf           The variable of events= that gives ADTF, the     Optional
|                imputation flag of the date of an event
| atmf           The variable of events= that gives ATMF, the     Optional
|                imputation flag of the time of an event
| keep           Other variables of the record taken, separated   Optional
|                by blanks: they must be in events= and in
|                censors= both
| censor_cnsr    CNSR of a censoring: a number, or a numeric      1
|                variable of censors=
| end_cnsr       CNSR of a subject censored at the end of the     1
|                period: a number
| censor_desc    EVNTDESC of a censoring: a text in quotes, or a  Optional
|                variable of censors= (or of subjects=)
| censor_source  SRCDOM of a censoring from subjects= and of a    Optional
|                censoring at the end of the period: a text in
|                quotes, such as "ADSL". SRCVAR is then the name
|                of censor_date= (or of end=).
| end_desc       EVNTDESC of a subject censored at the end of     "End of at-risk
|                the period: a text in quotes                     period"
| event_desc     EVNTDESC of an event: a text in quotes, or a     Optional
|                variable of events=, such as aedecod
| source         SRCDOM of an event: a text in quotes, such as    Optional
|                "ADAE". SRCVAR is then the name of date=.
| paramcd        PARAMCD of the parameter: a text in quotes,      Required
|                such as "TTDE"
| out            The name of the data set it writes               Required
| debug          yes: keep the work data sets _tte_*              no
|-------------------------------------------------------------------------------
|
| Output        : OUT: one record per subject with an event, a censoring or
|                 (with end=) a period, in the order of subjects=: the variables
|                 of subjects=, PARAMCD, ADT, CNSR, AVAL, ATM (with time=),
|                 EVNTDESC, SRCDOM, SRCVAR, SRCSEQ, ADTF and ATMF (when their
|                 parameters are given) and the variables of keep=. With end=, a
|                 subject with no START or no END gets no record and a WARNING
|                 that names it; a subject whose START is after its END gets no
|                 record. Two records of a subject in subjects= give an ERROR
|                 line. Without end=, a subject with no event and no censoring
|                 date gets no record, and a NOTE gives their number.
|
| Example:
|
 * Derives the time to the first skin event from the first dose: CNSR 0 is an event, 1 a censoring.;
 %tte(
     subjects      = adsl
   , events        = adae
   , event         = trtemfl = 'Y' AND aebodsys = 'SKIN AND SUBCUTANEOUS TISSUE DISORDERS'
   , date          = astdt
   , start         = trtsdt
   , censor_date   = trtedt
   , seq           = aeseq
   , censor_desc   = "End of treatment"
   , censor_source = "ADSL"
   , event_desc    = aedecod
   , source        = "ADAE"
   , paramcd       = "TTDE"
   , out           = adttde
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
| 27-NOV-2026 Sapling      1.10.0: the example runs on the example data
|                          (sas/examples). The text of the header for the
|                          manual: the summary, the form of each parameter. No
|                          number changes.
| 27-NOV-2026 Sapling      1.10.0: the message prints a macro variable, not a
|                          macro expression: it reads the same in the log and in
|                          the code. No number changes.
| 27-NOV-2026 Sapling      1.10.0: a caption for each call of the example (a
|                          comment line before it). No number changes.
| 27-NOV-2026 Sapling      1.10.0: Proven in plain words, for the published
|                          manual. Without end=, a subject with no event and no
|                          censoring date is no longer left out in silence: a
|                          NOTE gives their number. No number changes.
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
  %LOCAL t0 i dsn dsname token keys made period evdrop nodate;
  %LET t0 = %_spl_begin(tte);

  /* Step 1: the parameters: the data sets exist, the variables are in them */
  %IF not %_spl_need(tte, subjects events date start paramcd out) %THEN %RETURN;
  %IF not %_spl_oneof(tte, debug, yes no) %THEN %RETURN;
  %DO i = 1 %TO 3;
    %LET dsn = %SCAN(subjects events censors, &i.);
    %IF %LENGTH(%SUPERQ(&dsn.)) %THEN %DO;
      %LET dsname = %SCAN(%SUPERQ(&dsn.), 1, %STR(%());  /* the data set without its options */
      %IF not %SYSFUNC(EXIST(&dsname.)) %THEN %DO;
        %PUT %STR(ERR)OR: [tte] &dsn.=&dsname. does not exist;
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
    %PUT %STR(ERR)OR: [tte] time= and start_time= need end=, the end of the period;
    %PUT %STR(ERR)OR: [tte]   fix: give end=, or give neither time= nor start_time=.;
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

  /* Step 8: without end=, the subjects with no record are counted in the log */
  %IF %LENGTH(&end.) = 0 %THEN %DO;
    %LET nodate = %EVAL(%_spl_nobs(_tte_subjects) - %_spl_nobs(&out.));  /* the subjects left out */
    %IF &nodate. > 0 %THEN
      %PUT NOTE: [tte] &nodate. subject(s) with no event and no censoring date: no record.;
  %END;

  /* Step 9: the work data sets are deleted (kept with debug=yes) */
  %IF %UPCASE(&debug.) ne YES %THEN %DO;
    PROC DATASETS LIBRARY=work NOLIST NOWARN;
      DELETE _tte_:;
    QUIT;
  %END;
  %_spl_end(tte, &t0., &debug.)
%MEND tte;
