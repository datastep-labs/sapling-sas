/*******************************************************************************
| Program       : t14_2_01.sas
| Study         : CDISCPILOT01 (the CDISC pilot study, public example data)
| Output        : Table 14-2.01 Summary of Demographic and Baseline Characteristics
| Reference     : output/tlf-demographic.out of the R Consortium R Submission
|                 Pilot 1 (github.com/RConsortium/submissions-pilot1)
| Data          : adam/adsl.xpt of the same repository
*******************************************************************************/
%study(CDISCPILOT01, program = t14_2_01)

DATA itt;
  SET adam.adsl;
  WHERE ittfl = 'Y';
RUN;

%describe(
     data  = itt
   , var   = age
   , by    = trt01p
   , stats = mean="XX.XX" sd="XX.XX" median="XX.X" min="XX" max="XX"
   , label = "Age"
   , out   = t_age
 )
%freq(data=itt, var=agegr1, by=trt01p, stats=n="XX", label="Pooled Age Group 1", out=t_agegr1)
%freq(data=itt, var=race, by=trt01p, stats=n="XX", label="Race", out=t_race)
%describe(
     data  = itt
   , var   = heightbl
   , by    = trt01p
   , stats = mean="XX.XX" sd="XX.XX" median="XX.X" min="XX.X" max="XX.X"
   , label = "Baseline Height (cm)"
   , out   = t_height
 )
%describe(
     data  = itt
   , var   = weightbl
   , by    = trt01p
   , stats = mean="XX.XX" sd="XX.XX" median="XX.XX" min="XX.X" max="XX.X"
   , label = "Baseline Weight (kg)"
   , out   = t_weight
 )
%describe(
     data  = itt
   , var   = bmibl
   , by    = trt01p
   , stats = mean="XX.XX" sd="XX.XX" median="XX.X" min="XX.X" max="XX.X"
   , label = "Baseline BMI (kg/m^2)"
   , out   = t_bmi
 )
%describe(
     data  = itt
   , var   = mmsetot
   , by    = trt01p
   , stats = mean="XX.XX" sd="XX.XX" median="XX.X" min="XX" max="XX"
   , label = "MMSE Total"
   , out   = t_mmse
 )
%stack(t_age t_agegr1 t_race t_height t_weight t_bmi t_mmse, out=t14_2_01)
%columns(data=t14_2_01, n=itt, var=trt01p, order=trt01pn, out=t14_2_01_cols)
%ard(data=t14_2_01, columns=t14_2_01_cols, file=t14_2_01)
%layout(
     data    = t14_2_01
   , columns = t14_2_01_cols
   , var     = trt01p
   , file    = &spl_out./tlf/t14_2_01
   , setup   = t14_2_01_print
   , out     = t14_2_01_display
 )

TITLE1 J=L "Protocol: CDISCPILOT01";
TITLE2 J=L "Population: Intent-to-Treat";
TITLE3 "Table 14-2.01 Summary of Demographic and Baseline Characteristics";
FOOTNOTE1 J=L "Program: t14_2_01.sas";
%print(&t14_2_01_print.)
