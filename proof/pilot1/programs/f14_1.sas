/*******************************************************************************
| Program       : f14_1.sas
| Study         : CDISCPILOT01 (the CDISC pilot study, public example data)
| Output        : Figure 14-1 Kaplan-Meier plot of the time to the first
|                 dermatologic event, safety population, with the number at risk
| Reference     : output/tlf-kmplot.pdf of the R Consortium R Submission
|                 Pilot 1 (github.com/RConsortium/submissions-pilot1)
| Data          : adam/adsl.xpt and adam/adtte.xpt of the same repository
*******************************************************************************/
%study(CDISCPILOT01, program = f14_1)

DATA saf;
  SET adam.adsl;
  WHERE saffl = 'Y';
  KEEP usubjid trt01a trt01an;
RUN;

/* the time to the first dermatologic event of each subject of the safety population */
DATA ttde;
  MERGE adam.adtte(IN=intte WHERE=(paramcd = 'TTDE') KEEP=usubjid paramcd aval cnsr) saf(IN=insaf);
  BY usubjid;
  IF intte AND insaf;
RUN;

TITLE1 "KM plot for Time to First Dermatologic Event: Safety population";
FOOTNOTE1 J=L "Program: f14_1.sas";
%kmplot(
     data   = ttde
   , time   = aval
   , cnsr   = cnsr
   , by     = trt01a
   , times  = 0 20 40 60 80 100 120 140 160 180 200
   , xlabel = "Time to First Dermatologic Event (Days)"
   , file   = &spl_out./figures/f14_1
   , out    = f14_1
 )

/* the numbers the figure draws under it: the number at risk of each group at each tick */
DATA f14_1_atrisk;
  SET f14_1;
  WHERE kind = 'atrisk';
RUN;
%csv(data=f14_1_atrisk, var=trt01a x n, folder=figures, file=f14_1_atrisk)
