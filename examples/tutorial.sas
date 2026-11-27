/* The tutorial "Your first table" of the Sapling SAS macros: https://datastep-labs.github.io/sapling-sas/tutorial/
   Run examples/setup.sas first, in the same SAS session; then submit this program. */
TITLE;

%describe(
     data  = adsl
   , var   = age
   , by    = trt01a
   , total = yes
   , label = "Age (years)"
   , out   = t_age
 )

%freq(
     data  = adsl
   , var   = sex
   , by    = trt01a
   , total = yes
   , label = "Sex"
   , out   = t_sex
 )

%stack(t_age t_sex, out=t_first)

%columns(
     data  = t_first
   , n     = adsl
   , var   = trt01a
   , order = trt01an
   , total = yes
   , out   = t_first_cols
 )

%ard(data=t_first, columns=t_first_cols, file=t_first)

%layout(
     data    = t_first
   , columns = t_first_cols
   , var     = trt01a
   , file    = &spl_out./tlf/t_first
   , setup   = t_first_print
   , out     = t_first_display
 )

TITLE1 "Table 1 Age and sex by treatment";
TITLE2 "Safety population";
FOOTNOTE1 J=L "Program: tutorial.sas";
%print(&t_first_print.)
