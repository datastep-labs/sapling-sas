/*******************************************************************************
| Program       : adverse_events.sas
| Study         : the test data of pharmaverseadam 1.3.0 (CDISC pilot subjects)
| Output        : the adverse events table of the pharmaverse examples
|                 ({rtables} and {tern}): patients with an adverse event and
|                 the events, overall, by system organ class and by preferred
|                 term, by actual arm, with the column All Patients
| Reference     : tlg/adverse_events.html of github.com/pharmaverse/examples
|                 (pharmaverse.github.io/examples/tlg/adverse_events.html)
| Data          : adsl and adae of pharmaverseadam 1.3.0 as transport files
*******************************************************************************/
%study(PHARMAVERSEADAM, program = adverse_events)

/* the adverse events of the safety population; the N of each column are all subjects of ADSL,
   as in the example (alt_counts_df = adsl): All Patients counts the screen failures too */
DATA adae;
  SET adam.adae;
  WHERE saffl = 'Y';
RUN;

%freq(
     data  = adae
   , denom = adam.adsl
   , by    = actarm
   , total = "All Patients"
   , stats = n="XX" pct="(XX.X%)" events="XX"
   , label = "Total number of patients with at least one adverse event"
   , out   = t_any
 )
%freq(
     data  = adae
   , denom = adam.adsl
   , var   = aebodsys
   , by    = actarm
   , total = "All Patients"
   , stats = n="XX" pct="(XX.X%)" events="XX"
   , label = "MedDRA System Organ Class"
   , out   = t_soc
 )
%freq(
     data  = adae
   , denom = adam.adsl
   , var   = aebodsys aedecod
   , by    = actarm
   , total = "All Patients"
   , stats = n="XX" pct="(XX.X%)"
   , label = "MedDRA Preferred Term"
   , out   = t_pt
 )
%stack(t_any t_soc t_pt, out=adverse_events)

/* the screen failures are no column of the table: All Patients counts them (N=306) */
DATA adverse_events;
  SET adverse_events;
  WHERE actarm NE 'Screen Failure';
RUN;
%columns(data=adverse_events, n=adam.adsl, var=actarm, total="All Patients", out=ae_cols)
DATA ae_cols;
  SET ae_cols;
  WHERE colvalue NE 'Screen Failure';
  col = _N_;
RUN;
%ard(data=adverse_events, columns=ae_cols, file=adverse_events)
%layout(
     data    = adverse_events
   , columns = ae_cols
   , var     = actarm
   , file    = &spl_out./tlf/adverse_events
   , setup   = adverse_events_print
   , out     = adverse_events_display
 )

TITLE1 "Adverse events table (the pharmaverse examples, {rtables} and {tern})";
FOOTNOTE1 J=L "Program: adverse_events.sas";
%print(&adverse_events_print.)
