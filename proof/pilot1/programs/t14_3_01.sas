/*******************************************************************************
| Program       : t14_3_01.sas
| Study         : CDISCPILOT01 (the CDISC pilot study, public example data)
| Output        : Table 14-3.01 Primary Endpoint Analysis: ADAS Cog (11) -
|                 Change from Baseline to Week 24 - LOCF
| Reference     : output/tlf-primary.rtf of the R Consortium R Submission
|                 Pilot 1 (github.com/RConsortium/submissions-pilot1)
| Data          : adam/adsl.xpt and adam/adadas.xpt of the same repository
*******************************************************************************/
%study(CDISCPILOT01, program = t14_3_01)

DATA eff;
  SET adam.adsl;
  WHERE efffl = 'Y' AND ittfl = 'Y';
  trtp  = trt01p;
  trtpn = trt01pn;
RUN;

DATA adas;
  SET adam.adadas;
  WHERE efffl = 'Y' AND ittfl = 'Y' AND paramcd = 'ACTOT' AND anl01fl = 'Y';
RUN;

%describe(
     data  = adas
   , where = (avisitn = 0)
   , var   = aval
   , by    = trtp
   , stats = n="XX" mean="XX.X" sd="XX.XX" median="XX.X" min="XX" max="XX"
   , label = "Baseline"
   , out   = t_base
 )
%describe(
     data  = adas
   , where = (avisitn = 24)
   , var   = aval
   , by    = trtp
   , stats = n="XX" mean="XX.X" sd="XX.XX" median="XX.X" min="XX" max="XX"
   , label = "Week 24"
   , out   = t_week24
 )
%describe(
     data  = adas
   , where = (avisitn = 24)
   , var   = chg
   , by    = trtp
   , stats = n="XX" mean="XX.X" sd="XX.XX" median="XX.X" min="XX" max="XX"
   , label = "Change from Baseline"
   , out   = t_chg
 )
%ancova(
     data   = adas
   , where  = (avisitn = 24)
   , var    = chg
   , covars = base
   , class  = sitegr1
   , test   = trtpn
   , label  = "p-value (Dose Response)"
   , out    = t_dose
 )
%lsmeans(
     data   = adas
   , where  = (avisitn = 24)
   , var    = chg
   , by     = trtp
   , covars = base
   , class  = sitegr1
   , pairs  = all
   , order  = trtpn
   , label  = "Pairwise comparison (ANCOVA)"
   , out    = t_pairs
 )
%stack(t_base t_week24 t_chg t_dose t_pairs, out=t14_3_01)
%columns(data=t14_3_01, n=eff, var=trtp, order=trtpn, out=t14_3_01_cols)
%ard(data=t14_3_01, columns=t14_3_01_cols, file=t14_3_01)
%layout(
     data    = t14_3_01
   , columns = t14_3_01_cols
   , var     = trtp
   , file    = &spl_out./tlf/t14_3_01
   , setup   = t14_3_01_print
   , out     = t14_3_01_display
 )

TITLE1 J=L "Protocol: CDISCPILOT01";
TITLE2 J=L "Population: Efficacy";
TITLE3 "Table 14-3.01 Primary Endpoint Analysis: ADAS Cog (11) - Change from Baseline to Week 24 - LOCF";
FOOTNOTE1 J=L "ANCOVA of the change with treatment and site group as factors and baseline as a covariate;";
FOOTNOTE2 J=L "the dose response: the treatment as a continuous variable. Program: t14_3_01.sas";
%print(&t14_3_01_print.)
