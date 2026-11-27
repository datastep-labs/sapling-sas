/*******************************************************************************
| Program       : t14_3_02.sas
| Study         : CDISCPILOT01 (the CDISC pilot study, public example data)
| Output        : ANCOVA of Change from Baseline at Week 20 (glucose,
|                 Xanomeline High Dose against Placebo)
| Reference     : output/tlf-efficacy.rtf of the R Consortium R Submission
|                 Pilot 1 (github.com/RConsortium/submissions-pilot1)
| Data          : adam/adsl.xpt and adam/adlbc.xpt of the same repository
*******************************************************************************/
%study(CDISCPILOT01, program = t14_3_02)

DATA itt;
  SET adam.adsl;
  WHERE ittfl = 'Y';
  KEEP usubjid;
RUN;

/* the glucose records of the subjects of the ITT population, high dose and placebo, at a visit */
DATA gluc;
  MERGE adam.adlbc(IN=inlab WHERE=(trtpn IN (0 81) AND paramcd = 'GLUC' AND NOT MISSING(avisitn)))
        itt(IN=initt);
  BY usubjid;
  IF inlab AND initt;
RUN;

%describe(
     data  = gluc
   , where = (avisitn = 0)
   , var   = base
   , by    = trtp
   , stats = n="XX" mean="XX.X" sd="XX.XX"
   , label = "Baseline"
   , out   = t_base
 )
%describe(
     data  = gluc
   , where = (avisitn = 20 AND NOT MISSING(chg) AND NOT MISSING(base))
   , var   = aval
   , by    = trtp
   , stats = n="XX" mean="XX.X" sd="XX.XX"
   , label = "Week 20"
   , out   = t_week20
 )
%describe(
     data  = gluc
   , where = (avisitn = 20 AND NOT MISSING(chg) AND NOT MISSING(base))
   , var   = chg
   , by    = trtp
   , stats = n="XX" mean="XX.X" sd="XX.XX"
   , label = "Change from Baseline"
   , out   = t_chg
 )
%lsmeans(
     data   = gluc
   , where  = (avisitn = 20)
   , var    = chg
   , by     = trtp
   , covars = base
   , pairs  = "Xanomeline High Dose" "Placebo"
   , stats  = lsmean="XX.XX" lsmean_lcl="XX.XX" lsmean_ucl="XX.XX" diff="XX.XX" diff_se="XX.XXX"
              lcl="XX.XX" ucl="XX.XX" pval="X.XXX"
   , label  = "LS mean (95% CI) and the difference against Placebo (ANCOVA)"
   , out    = t_ancova
 )
%stack(t_base t_week20 t_chg t_ancova, out=t14_3_02)
%columns(data=t14_3_02, var=trtp, out=t14_3_02_cols)
%ard(data=t14_3_02, columns=t14_3_02_cols, file=t14_3_02)
%layout(
     data    = t14_3_02
   , columns = t14_3_02_cols
   , var     = trtp
   , file    = &spl_out./tlf/t14_3_02
   , setup   = t14_3_02_print
   , out     = t14_3_02_display
 )

TITLE1 J=L "Protocol: CDISCPILOT01";
TITLE2 J=L "Population: Intent-to-Treat";
TITLE3 "ANCOVA of Change from Baseline at Week 20 (glucose)";
FOOTNOTE1 J=L "ANCOVA of the change with treatment as a factor and baseline as a covariate.";
FOOTNOTE2 J=L "Program: t14_3_02.sas";
%print(&t14_3_02_print.)
