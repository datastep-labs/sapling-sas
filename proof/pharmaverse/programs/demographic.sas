/*******************************************************************************
| Program       : demographic.sas
| Study         : the test data of pharmaverseadam 1.3.0 (CDISC pilot subjects)
| Output        : the demographic table of the pharmaverse examples ({rtables}
|                 and {tern}): age, age group, sex and race by planned arm, with
|                 the column All Patients
| Reference     : tlg/demographic.html of github.com/pharmaverse/examples
|                 (pharmaverse.github.io/examples/tlg/demographic.html)
| Data          : adsl of pharmaverseadam 1.3.0 as a transport file
*******************************************************************************/
%study(PHARMAVERSEADAM, program = demographic)

/* the subjects without the screen failures; sex in words and the age groups of the example */
DATA adsl;
  LENGTH sex $6 agegr1 $5;
  SET adam.adsl(RENAME=(sex = sexcd agegr1 = agegr1cd));
  WHERE actarm NE 'Screen Failure';
       IF sexcd = 'M' THEN sex = 'MALE';
  ELSE IF sexcd = 'F' THEN sex = 'FEMALE';
       IF 18 <= age <= 40 THEN agegr1 = '18-40';
  ELSE IF 41 <= age <= 64 THEN agegr1 = '41-64';
  ELSE IF age > 64        THEN agegr1 = '>=65';
RUN;

%describe(
     data  = adsl
   , var   = age
   , by    = actarm
   , total = "All Patients"
   , stats = n="XX" mean="XX.X" sd="XX.X" median="XX.X" min="XX.X" max="XX.X"
   , label = "Age (yr)"
   , out   = t_age
 )
%freq(
     data   = adsl
   , var    = agegr1
   , by     = actarm
   , levels = agegr1 '18-40' '41-64' '>=65'
   , total  = "All Patients"
   , label  = "Age group"
   , out    = t_agegr1
 )
%freq(data=adsl, var=sex, by=actarm, total="All Patients", label="Sex", out=t_sex)
%freq(data=adsl, var=race, by=actarm, total="All Patients", label="Race", out=t_race)
%stack(t_age t_agegr1 t_sex t_race, out=demographic)
%columns(data=demographic, n=adsl, var=actarm, total="All Patients", out=demographic_cols)
%ard(data=demographic, columns=demographic_cols, file=demographic)
%layout(
     data    = demographic
   , columns = demographic_cols
   , var     = actarm
   , file    = &spl_out./tlf/demographic
   , setup   = demographic_print
   , out     = demographic_display
 )

TITLE1 "Demographic table (the pharmaverse examples, {rtables} and {tern})";
FOOTNOTE1 J=L "Program: demographic.sas";
%print(&demographic_print.)
