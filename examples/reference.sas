/* The examples of the reference pages of the Sapling SAS macros, in the order they run.
   Run examples/setup.sas first, in the same SAS session; then submit this program, or one part after another.
   A later part may read the out= of an earlier one. Each part is the example of one page:
   https://datastep-labs.github.io/sapling-sas/reference/<macro>/ */

/* %import_xpt: https://datastep-labs.github.io/sapling-sas/reference/import_xpt/ */
* Copies the six ADaM transport files of the example data into SAS data sets of one folder.;
%import_xpt(
     dir     = &spl_root./examples/data
   , members = adsl adae advs adlb adtte adrs
   , out     = &spl_root./examples/adam
 )
TITLE;
FOOTNOTE;

/* %study: https://datastep-labs.github.io/sapling-sas/reference/study/ */
* Starts the program of the examples: it sets SPL_STUDY, SPL_PROGRAM and SPL_OUT and opens ADAM.;
%study(
     CDISCPILOT01
   , program = examples
   , adam    = &spl_root./examples/adam
   , out     = &spl_root./examples/out
 )
TITLE;
FOOTNOTE;

/* %tte: https://datastep-labs.github.io/sapling-sas/reference/tte/ */
* Makes TTDE. Log NOTE: 2 subject(s) with no event and no censoring date: no record (no TRTEDT).;
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
* Makes the subjects with the end of week 12 (day 84) and the time of the first dose.;
DATA sl;
  SET adsl;
  wk12dt = trtsdt + 83;
  trtstm = TIMEPART(trtsdtm);
  FORMAT wk12dt DATE9. trtstm TIME5.;
RUN;
* Ends the period at week 12: no event or censoring in it gives CNSR 1 on day 84. All 254 count.;
%tte(
     subjects      = sl
   , events        = adae
   , event         = trtemfl = 'Y' AND aebodsys = 'SKIN AND SUBCUTANEOUS TISSUE DISORDERS'
   , date          = astdt
   , start         = trtsdt
   , end           = wk12dt
   , censor_date   = trtedt
   , seq           = aeseq
   , censor_desc   = "End of treatment"
   , censor_source = "ADSL"
   , end_desc      = "End of week 12"
   , event_desc    = aedecod
   , source        = "ADAE"
   , paramcd       = "TTDE12"
   , out           = adttde12
 )
* Makes the start time of each event, in seconds since midnight.;
DATA ae_times;
  SET adae;
  asttm = TIMEPART(astdtm);
  FORMAT asttm TIME5.;
RUN;
* Adds the times of the start day: all are 00:00, imputed (ATMF H), so the events of day 1 count.;
%tte(
     subjects      = sl
   , events        = ae_times
   , event         = trtemfl = 'Y' AND aebodsys = 'SKIN AND SUBCUTANEOUS TISSUE DISORDERS'
   , date          = astdt
   , time          = asttm
   , start         = trtsdt
   , start_time    = trtstm
   , end           = wk12dt
   , censor_date   = trtedt
   , seq           = aeseq
   , atmf          = asttmf
   , censor_desc   = "End of treatment"
   , censor_source = "ADSL"
   , end_desc      = "End of week 12"
   , event_desc    = aedecod
   , source        = "ADAE"
   , paramcd       = "TTDE12"
   , out           = adttde12t
 )
TITLE;
FOOTNOTE;

/* %describe: https://datastep-labs.github.io/sapling-sas/reference/describe/ */
* Summarizes age in each group and in the Total: n, mean, SD, median, minimum and maximum.;
%describe(
     data  = adsl
   , var   = age
   , by    = trt01a
   , total = yes
   , label = "Age (years)"
   , out   = age_describe
 )
* Uses three BY variables: one row per group, parameter, visit and statistic, with PARAM kept.;
%describe(
     data  = advs
   , where = (anl01fl = 'Y')
   , var   = aval
   , by    = trt01a paramcd avisit
   , keep  = param avisitn
   , out   = vs
 )
* Adds the SE, Q1 and Q3 and calls the Total All subjects: the rows keep the order of stats=.;
%describe(
     data  = advs
   , where = (paramcd = 'WEIGHT' AND ablfl = 'Y')
   , var   = aval
   , by    = trt01a
   , total = "All subjects"
   , stats = n mean sd se median q1 q3 min="XX.X" max="XX.X"
   , label = "Weight at baseline (kg)"
   , out   = wt_describe
 )
* Adds sex as a second BY variable: the rows of each group and sex, for a page per sex.;
%describe(
     data  = adsl
   , var   = age
   , by    = trt01a sex
   , total = yes
   , label = "Age (years)"
   , out   = age_sex
 )
TITLE;
FOOTNOTE;

/* %anova: https://datastep-labs.github.io/sapling-sas/reference/anova/ */
* Tests age across the three groups: one row, the p value of the F test.;
%anova(
     data  = adsl
   , var   = age
   , by    = trt01a
   , label = "Age (years)"
   , out   = age_anova
 )
TITLE;
FOOTNOTE;

/* %freq: https://datastep-labs.github.io/sapling-sas/reference/freq/ */
* Counts each sex in each group and in the Total: n and the percent of the subjects of the group.;
%freq(
     data  = adsl
   , var   = sex
   , by    = trt01a
   , total = yes
   , label = "Sex"
   , out   = sex_freq
 )
* Counts subjects and events of each term under its class: the percent uses the N of denom=.;
%freq(
     data  = adae
   , denom = adsl
   , where = (trtemfl = 'Y')
   , var   = aebodsys aedecod
   , by    = trt01a
   , stats = n pct events
   , out   = teae
 )
* Counts the shift at Week 24 with planned levels: a level without a subject has a row of 0.;
%freq(
     data   = adlb
   , denom  = adsl
   , where  = (avisit = 'Week 24')
   , var    = paramcd bnrind anrind
   , by     = trt01a
   , levels = bnrind 'LOW' 'NORMAL' 'HIGH' anrind 'LOW' 'NORMAL' 'HIGH'
   , out    = shift
 )
* Keeps the terms that reach 5 percent in a group: AEDECODN ranks them, the most subjects first.;
%freq(
     data      = adae
   , denom     = adsl
   , where     = (trtemfl = 'Y')
   , var       = aedecod
   , by        = trt01a
   , threshold = 5
   , order     = frequency
   , out       = common
 )
* Adds sex as a second BY variable: the age groups of each group and sex, for a page per sex.;
%freq(
     data  = adsl
   , var   = agegr1
   , by    = trt01a sex
   , total = yes
   , label = "Age group"
   , out   = agegr_sex
 )
TITLE;
FOOTNOTE;

/* %chisq: https://datastep-labs.github.io/sapling-sas/reference/chisq/ */
* Tests sex across the groups: one row, the p value of the chi square test.;
%chisq(
     data  = adsl
   , var   = sex
   , by    = trt01a
   , label = "Sex"
   , out   = sex_chisq
 )
* Runs the exact test of the normal range within each parameter: one p value per parameter.;
%chisq(
     data   = adlb
   , where  = (avisit = 'Week 24')
   , var    = anrind
   , by     = trt01a
   , within = paramcd
   , exact  = yes
   , out    = nr_test
 )
TITLE;
FOOTNOTE;

/* %worst: https://datastep-labs.github.io/sapling-sas/reference/worst/ */
* Keeps the records of each subject and term at the worst severity, the last value of levels=.;
%worst(
     data   = adae
   , where  = (trtemfl = 'Y')
   , var    = aesev
   , by     = aebodsys aedecod
   , levels = 'MILD' 'MODERATE' 'SEVERE'
   , out    = ae_worst
 )
TITLE;
FOOTNOTE;

/* %termflags: https://datastep-labs.github.io/sapling-sas/reference/termflags/ */
* Flags each subject for each term that reaches 5 percent: FLAG is Y with the term, N without.;
%termflags(
     data      = adae
   , denom     = adsl
   , where     = (trtemfl = 'Y')
   , terms     = aebodsys aedecod
   , by        = trt01a
   , threshold = 5
   , out       = ae_flags
 )
TITLE;
FOOTNOTE;

/* %fisher: https://datastep-labs.github.io/sapling-sas/reference/fisher/ */
* Tests the subjects with an event against those without in each class: one p value per class.;
%fisher(
     data   = adae
   , denom  = adsl
   , where  = (trtemfl = 'Y')
   , by     = trt01a
   , within = aebodsys
   , out    = soc_test
 )
TITLE;
FOOTNOTE;

/* %cmh: https://datastep-labs.github.io/sapling-sas/reference/cmh/ */
* Tests the status at the end of the study across the groups, stratified by sex: one p value.;
%cmh(
     data   = adsl
   , var    = eosstt
   , by     = trt01a
   , strata = sex
   , label  = "Discontinued the study"
   , out    = eos_cmh
 )
* Uses the row mean score statistic for the ordered age groups: one p value.;
%cmh(
     data      = adsl
   , var       = agegr1
   , by        = trt01a
   , statistic = rowmean
   , label     = "Age group"
   , out       = agegr_cmh
 )
TITLE;
FOOTNOTE;

/* %proportion: https://datastep-labs.github.io/sapling-sas/reference/proportion/ */
* Gives the percent that completed and that discontinued, each with its Clopper Pearson limits.;
%proportion(
     data   = adsl
   , var    = eosstt
   , by     = trt01a
   , levels = eosstt 'COMPLETED' 'DISCONTINUED'
   , ci     = clopper-pearson
   , out    = eos_ci
 )
* Gives the percent of the best responses CR and PR of the N of denom=, with Wilson limits.;
%proportion(
     data   = adrs
   , denom  = adsl
   , where  = (paramcd = 'BOR')
   , var    = avalc
   , by     = trt01a
   , levels = avalc 'CR' 'PR'
   , ci     = wilson
   , out    = bor_ci
 )
TITLE;
FOOTNOTE;

/* %risk: https://datastep-labs.github.io/sapling-sas/reference/risk/ */
* Gives the risk difference of discontinuation of each pair, its Newcombe limits and p value.;
%risk(
     data  = adsl
   , var   = eosstt
   , event = "DISCONTINUED"
   , by    = trt01a
   , order = trt01an
   , ci    = newcombe
   , out   = eos_rd
 )
* Gives the risk difference of each flagged term against Placebo, within its class and term.;
%risk(
     data   = work.ae_flags
   , var    = flag
   , event  = "Y"
   , by     = trt01a
   , within = aebodsys aedecod
   , pairs  = "Xanomeline High Dose" "Placebo"
            # "Xanomeline Low Dose"  "Placebo"
   , ci     = newcombe
   , out    = ae_rd
 )
* Asks for the relative risk with measure=rr: the rows of STAT rr hold the ratio of the two risks.;
%risk(
     data    = adsl
   , var     = eosstt
   , event   = "DISCONTINUED"
   , by      = trt01a
   , order   = trt01an
   , measure = rr
   , out     = eos_rr
 )
* Stratifies by sex: the risk difference is the Mantel Haenszel estimate over the strata.;
%risk(
     data   = adsl
   , var    = eosstt
   , event  = "DISCONTINUED"
   , by     = trt01a
   , strata = sex
   , order  = trt01an
   , out    = eos_rd_mh
 )
TITLE;
FOOTNOTE;

/* %logistic: https://datastep-labs.github.io/sapling-sas/reference/logistic/ */
* Gives the odds ratio of discontinuation for each pair, adjusted for age and sex.;
%logistic(
     data   = adsl
   , var    = eosstt
   , event  = "DISCONTINUED"
   , by     = trt01a
   , covars = age
   , class  = sex
   , order  = trt01an
   , out    = eos_or
 )
* Gives the odds ratio against Placebo for each sex: the rows carry SEX.;
%logistic(
     data   = adsl
   , var    = eosstt
   , event  = "DISCONTINUED"
   , by     = trt01a
   , within = sex
   , pairs  = "Xanomeline High Dose" "Placebo"
            # "Xanomeline Low Dose"  "Placebo"
   , out    = eos_or_sex
 )
TITLE;
FOOTNOTE;

/* %rate: https://datastep-labs.github.io/sapling-sas/reference/rate/ */
* Gives the subjects with an event per 100 patient years, with the exposure and the limits.;
%rate(
     data     = adae
   , denom    = adsl(WHERE=(trtdurd > 0))
   , where    = (trtemfl = 'Y')
   , by       = trt01a
   , exposure = trtdurd / 365.25
   , out      = ae_rate
 )
* Counts the events, not the subjects, with count=events: a subject adds each of its events.;
%rate(
     data     = adae
   , denom    = adsl(WHERE=(trtdurd > 0))
   , where    = (trtemfl = 'Y')
   , by       = trt01a
   , exposure = trtdurd / 365.25
   , count    = events
   , out      = ae_events
 )
* Gives the rate of severe events per 1000 patient years with per=1000.;
%rate(
     data     = adae
   , denom    = adsl(WHERE=(trtdurd > 0))
   , where    = (trtemfl = 'Y' AND aesev = 'SEVERE')
   , by       = trt01a
   , exposure = trtdurd / 365.25
   , per      = 1000
   , out      = ae_rate1000
 )
TITLE;
FOOTNOTE;

/* %rateratio: https://datastep-labs.github.io/sapling-sas/reference/rateratio/ */
* Compares the event counts in a negative binomial model: STAT irr is the rate ratio.;
%rateratio(
     data     = adsl
   , where    = (trtdurd > 0)
   , var      = teaecnt
   , by       = trt01a
   , exposure = trtdurd / 365.25
   , dist     = negbin
   , order    = trt01an
   , out      = ae_rr
 )
TITLE;
FOOTNOTE;

/* %ancova: https://datastep-labs.github.io/sapling-sas/reference/ancova/ */
* Tests a linear dose response of the change at Week 12, adjusted for baseline: one p value.;
%ancova(
     data   = advs
   , where  = (paramcd = 'SYSBP' AND avisit = 'Week 12' AND anl01fl = 'Y')
   , var    = chg
   , covars = base
   , test   = trt01pn
   , label  = "Dose response"
   , out    = sbp_dose
 )
TITLE;
FOOTNOTE;

/* %lsmeans: https://datastep-labs.github.io/sapling-sas/reference/lsmeans/ */
* Gives the difference of the LS means of every pair at Week 12, adjusted for baseline and sex.;
%lsmeans(
     data   = advs
   , where  = (paramcd = 'SYSBP' AND avisit = 'Week 12' AND anl01fl = 'Y')
   , var    = chg
   , by     = trt01p
   , covars = base
   , class  = sex
   , pairs  = all
   , order  = trt01pn
   , out    = sbp_ls
 )
* Without class=sex, two pairs at a 90 percent level: High Dose -5.73 here, not -5.24 as above.;
%lsmeans(
     data   = advs
   , where  = (paramcd = 'SYSBP' AND avisit = 'Week 12' AND anl01fl = 'Y')
   , var    = chg
   , by     = trt01p
   , covars = base
   , pairs  = "Xanomeline High Dose" "Placebo"
            # "Xanomeline Low Dose"  "Placebo"
   , order  = trt01pn
   , level  = 0.90
   , stats  = lsmean lsmean_se diff lcl ucl pval
   , out    = sbp_ls90
 )
* Fits one model at each visit with within=avisit: High Dose against Placebo at Week 12 and 24.;
%lsmeans(
     data   = advs
   , where  = (paramcd = 'SYSBP' AND avisit IN ('Week 12' 'Week 24') AND anl01fl = 'Y')
   , var    = chg
   , by     = trt01p
   , within = avisit
   , covars = base
   , class  = sex
   , pairs  = "Xanomeline High Dose" "Placebo"
   , order  = trt01pn
   , out    = sbp_ls_vis
 )
TITLE;
FOOTNOTE;

/* %adjust: https://datastep-labs.github.io/sapling-sas/reference/adjust/ */
* Adjusts the p values of the two comparisons against Placebo by Hochberg: PADJ after PVAL.;
%adjust(
     data   = sbp_ls
   , by     = trt01p
   , family = "Xanomeline High Dose" "Placebo"
            # "Xanomeline Low Dose"  "Placebo"
   , method = hochberg
   , out    = sbp_adj
 )
TITLE;
FOOTNOTE;

/* %mmrm: https://datastep-labs.github.io/sapling-sas/reference/mmrm/ */
* Fits the MMRM of the change at five visits and compares the groups at Week 24.;
%mmrm(
     data     = advs
   , where    = (paramcd = 'SYSBP' AND anl01fl = 'Y' AND avisitn IN (4 8 12 16 24))
   , var      = chg
   , by       = trt01p
   , visit    = avisit
   , at       = "Week 24"
   , model    = base trt01p avisit trt01p*avisit base*avisit
   , type     = un
   , fallback = toep
   , pairs    = all
   , order    = trt01pn
   , out      = sbp_mmrm
 )
TITLE;
FOOTNOTE;

/* %ttest: https://datastep-labs.github.io/sapling-sas/reference/ttest/ */
* Compares each pair of groups with the pooled t test: the difference, its SE, limits and p value.;
%ttest(
     data  = advs
   , where = (paramcd = 'SYSBP' AND avisit = 'Week 12' AND anl01fl = 'Y')
   , var   = chg
   , by    = trt01p
   , order = trt01pn
   , out   = sbp_t
 )
* Uses the Welch test of unequal variances on two pairs: the SE, limits and p value change.;
%ttest(
     data      = advs
   , where     = (paramcd = 'SYSBP' AND avisit = 'Week 12' AND anl01fl = 'Y')
   , var       = chg
   , by        = trt01p
   , pairs     = "Xanomeline High Dose" "Placebo"
               # "Xanomeline Low Dose"  "Placebo"
   , variances = unequal
   , out       = sbp_welch
 )
TITLE;
FOOTNOTE;

/* %wilcoxon: https://datastep-labs.github.io/sapling-sas/reference/wilcoxon/ */
* Compares each pair with the Wilcoxon rank sum test and the Hodges Lehmann estimate.;
%wilcoxon(
     data  = advs
   , where = (paramcd = 'DIABP' AND avisit = 'Week 12' AND anl01fl = 'Y')
   , var   = chg
   , by    = trt01p
   , order = trt01pn
   , out   = dbp_w
 )
* Leaves out the continuity correction for one pair: only the p value changes.;
%wilcoxon(
     data       = advs
   , where      = (paramcd = 'DIABP' AND avisit = 'Week 12' AND anl01fl = 'Y')
   , var        = chg
   , by         = trt01p
   , pairs      = "Xanomeline High Dose" "Placebo"
   , correction = no
   , out        = dbp_w_nocc
 )
TITLE;
FOOTNOTE;

/* %interaction_glm: https://datastep-labs.github.io/sapling-sas/reference/interaction_glm/ */
* Tests the treatment by sex interaction of the change at Week 12, adjusted for baseline.;
%interaction_glm(
     data   = advs
   , where  = (paramcd = 'SYSBP' AND avisit = 'Week 12' AND anl01fl = 'Y')
   , var    = chg
   , by     = trt01p
   , factor = sex
   , covars = base
   , label  = "Sex"
   , out    = sbp_int
 )
TITLE;
FOOTNOTE;

/* %interaction_logistic: https://datastep-labs.github.io/sapling-sas/reference/interaction_logistic/ */
* Tests the treatment by sex interaction of discontinuation in a logistic model with age.;
%interaction_logistic(
     data   = adsl
   , var    = eosstt
   , event  = "DISCONTINUED"
   , by     = trt01a
   , factor = sex
   , covars = age
   , label  = "Sex"
   , out    = eos_int
 )
TITLE;
FOOTNOTE;

/* %interaction_genmod: https://datastep-labs.github.io/sapling-sas/reference/interaction_genmod/ */
* Tests the treatment by sex interaction of the event counts in a negative binomial model.;
%interaction_genmod(
     data     = adsl
   , where    = (trtdurd > 0)
   , var      = teaecnt
   , by       = trt01a
   , factor   = sex
   , exposure = trtdurd / 365.25
   , dist     = negbin
   , label    = "Sex"
   , out      = ae_int
 )
TITLE;
FOOTNOTE;

/* %km: https://datastep-labs.github.io/sapling-sas/reference/km/ */
* Gives n, events, the median and its limits of each group: NE is a median not reached.;
%km(
     data  = adttde
   , var   = aval
   , by    = trt01a
   , label = "Time to the first skin event (days)"
   , out   = ttde_km
 )
* Gives the percent of subjects alive at day 182 and its limits, with the patterns of stats=.;
%km(
     data  = adtte
   , where = (paramcd = 'OS')
   , var   = aval
   , by    = trt01p
   , time  = 182
   , stats = n="XX" events="XX" surv="XX.X" lcl="XX.X" ucl="XX.X"
   , out   = os_km
 )
* Uses conftype=loglog: only the lower limit of Low Dose changes, 51 to 48.;
%km(
     data     = adttde
   , var      = aval
   , by       = trt01a
   , conftype = loglog
   , out      = ttde_kmll
 )
* Gives the survival at day 182 with 90 percent limits, narrower than the 95 percent limits.;
%km(
     data  = adttde
   , var   = aval
   , by    = trt01a
   , time  = 182
   , level = 0.90
   , stats = n events surv lcl ucl
   , out   = ttde_km90
 )
TITLE;
FOOTNOTE;

/* %logrank: https://datastep-labs.github.io/sapling-sas/reference/logrank/ */
* Tests the curves of the groups with the log rank test, stratified by sex: one p value.;
%logrank(
     data   = adttde
   , var    = aval
   , by     = trt01a
   , strata = sex
   , out    = ttde_test
 )
TITLE;
FOOTNOTE;

/* %cox: https://datastep-labs.github.io/sapling-sas/reference/cox/ */
* Gives the hazard ratio of each pair, stratified by sex, with its limits and p value.;
%cox(
     data   = adttde
   , var    = aval
   , by     = trt01a
   , strata = sex
   , order  = trt01an
   , out    = ttde_hr
 )
* Gives the hazard ratio against Placebo for each sex: the rows carry SEX, for a forest plot.;
%cox(
     data   = adttde
   , var    = aval
   , by     = trt01a
   , within = sex
   , pairs  = "Xanomeline High Dose" "Placebo"
            # "Xanomeline Low Dose"  "Placebo"
   , out    = hr_sex
 )
* Gives the hazard ratio against Placebo for each age group.;
%cox(
     data   = adttde
   , var    = aval
   , by     = trt01a
   , within = agegr1
   , pairs  = "Xanomeline High Dose" "Placebo"
            # "Xanomeline Low Dose"  "Placebo"
   , out    = hr_age
 )
* Uses the Breslow ties, and as p value the log rank test of the two groups of each pair.;
%cox(
     data   = adttde
   , var    = aval
   , by     = trt01a
   , pairs  = "Xanomeline High Dose" "Placebo"
            # "Xanomeline Low Dose"  "Placebo"
   , ties   = breslow
   , pvalue = logrank
   , out    = ttde_hr_lr
 )
TITLE;
FOOTNOTE;

/* %interaction_phreg: https://datastep-labs.github.io/sapling-sas/reference/interaction_phreg/ */
* Tests the treatment by sex interaction of the time to the event in a Cox model.;
%interaction_phreg(
     data   = adttde
   , var    = aval
   , by     = trt01a
   , factor = sex
   , label  = "Sex"
   , out    = ttde_int
 )
TITLE;
FOOTNOTE;

/* %stack: https://datastep-labs.github.io/sapling-sas/reference/stack/ */
* Stacks four results in the order of the table: RESULT and ORD tell where each row came from.;
%stack(age_describe age_anova sex_freq sex_chisq, out=t14_2_1)
* Stacks the hazard ratios by sex and by age group, for one forest plot.;
%stack(hr_sex hr_age, out=hr_sub)
* Stacks age and the age groups by sex: the results of a table with a page per sex.;
%stack(age_sex agegr_sex, out=t14_1_1)
TITLE;
FOOTNOTE;

/* %columns: https://datastep-labs.github.io/sapling-sas/reference/columns/ */
* Makes the four columns with their N from adsl, the Total last, in the order of TRT01AN.;
%columns(
     data  = t14_2_1
   , n     = adsl
   , var   = trt01a
   , order = trt01an
   , total = yes
   , out   = t14_2_1_cols
 )
* Gives page=sex: one row per column and sex, the N of each column on the page of its sex.;
%columns(
     data  = t14_1_1
   , n     = adsl
   , var   = trt01a
   , order = trt01an
   , page  = sex
   , total = yes
   , out   = t14_1_1_cols
 )
* Leaves out n=: the columns have no N and come in the order of their values, the Total last.;
%columns(
     data  = t14_2_1
   , var   = trt01a
   , total = yes
   , out   = t14_2_1_cols_no_n
 )
TITLE;
FOOTNOTE;

/* %ard: https://datastep-labs.github.io/sapling-sas/reference/ard/ */
* Writes every number of the table and each column N to one CSV file: the raw value and the text.;
%ard(data=t14_2_1, columns=t14_2_1_cols, file=t14_2_1)
TITLE;
FOOTNOTE;

/* %layout: https://datastep-labs.github.io/sapling-sas/reference/layout/ */
* Makes the display data set: one row per printed line, one column per group, sex by its labels.;
%layout(
     data    = t14_2_1
   , columns = t14_2_1_cols
   , var     = trt01a
   , format  = sex $sexf.
   , file    = &spl_out./tlf/t14_2_1
   , setup   = t14_2_1_print
   , out     = t14_2_1_display
 )
* Makes one page per sex: SEX and HEAD_C1 to HEAD_C4 hold the page and the N of each column on it.;
%layout(
     data    = t14_1_1
   , columns = t14_1_1_cols
   , var     = trt01a
   , page    = sex
   , format  = sex $sexf.
   , file    = &spl_out./tlf/t14_1_1
   , setup   = t14_1_1_print
   , out     = t14_1_1_display
 )
* Puts label= and rows= into the setup: the last column is labelled p value, 30 rows a page.;
%layout(
     data    = t14_2_1
   , columns = t14_2_1_cols
   , var     = trt01a
   , format  = sex $sexf.
   , label   = c99="p-value"
   , rows    = 30
   , file    = &spl_out./tlf/t14_2_1_label
   , setup   = t14_2_1_label_print
   , out     = t14_2_1_label_display
 )
* Prints the display data set again with the call that the setup keeps.;
%print(&t14_2_1_label_print.)
* Counts the severe events of the subjects under 50: there is none, so the result has no row.;
%freq(
     data  = adae
   , denom = adsl
   , where = (aesev = 'SEVERE' AND age < 50)
   , var   = aedecod
   , by    = trt01a
   , out   = t_sev50
 )
* Gives nodata= for a result with no row: the display data set has no row.;
%layout(
     data    = t_sev50
   , columns = t14_2_1_cols
   , var     = trt01a
   , file    = &spl_out./tlf/t_sev50
   , nodata  = No subject under 50 had a severe event
   , setup   = t_sev50_print
   , out     = t_sev50_display
 )
* Prints the setup of the empty table: the page has the text of nodata= in place of the rows.;
%print(&t_sev50_print.)
TITLE;
FOOTNOTE;

/* %print: https://datastep-labs.github.io/sapling-sas/reference/print/ */
* Prints the display data set as RTF and as a listing: the rows of one block stay on one page.;
%print(
     data     = t14_2_1_display
   , by       = row
   , var      = c:
   , together = grp
   , label    = %STR(row=" ")
   , file     = &spl_out./tlf/t14_2_1
 )
* Prints one page per sex: the N of each column is that of the page, and the title names the sex.;
OPTIONS NOBYLINE;
TITLE1 "Table 14.1.1 Demographic characteristics by sex";
TITLE2 "Sex: #BYVAL1";
%print(
     data     = t14_1_1_display
   , by       = row
   , var      = c:
   , page     = sex
   , together = grp
   , label    = %STR(row=" ")
   , file     = &spl_out./tlf/t14_1_1_page
 )
* Resets the BY line and titles, sorts the events, prints the listing: USUBJID shown once each.;
OPTIONS BYLINE;
TITLE;
PROC SORT DATA=adae OUT=ae_listing; BY usubjid astdt aedecod; RUN;
%print(
     data = ae_listing
   , by   = usubjid
   , var  = trt01a aedecod astdt aesev
   , file = &spl_out./listings/l14_5_1
 )
TITLE;
FOOTNOTE;

/* %table: https://datastep-labs.github.io/sapling-sas/reference/table/ */
* Runs columns, ard, layout and print in one call: the same table as the long program.;
%table(
     data   = t14_2_1
   , n      = adsl
   , var    = trt01a
   , order  = trt01an
   , total  = yes
   , format = sex $sexf.
   , file   = &spl_out./tlf/t14_2_1_table
   , setup  = t14_2_1_table_print
 )
TITLE;
FOOTNOTE;

/* %csv: https://datastep-labs.github.io/sapling-sas/reference/csv/ */
* Writes the listing as a CSV file: the names of var= in the first line, then one line per record.;
%csv(data=adae, var=trt01a usubjid aedecod astdt, file=l14_5_1)
TITLE;
FOOTNOTE;

/* %kmplot: https://datastep-labs.github.io/sapling-sas/reference/kmplot/ */
* Draws the curves with the number at risk and the median of each group, and keeps the numbers.;
%kmplot(
     data    = adttde
   , columns = t14_2_1_cols
   , time    = aval
   , by      = trt01a
   , median  = yes
   , xlabel  = "Days to the first skin event"
   , file    = &spl_out./figures/f_ttde
   , out     = f_ttde
   , outpar  = f_ttde_par
 )
* Draws the figure again from out= and outpar= of the call before: no median, another label.;
%kmplot(
     plot   = f_ttde
   , par    = f_ttde_par
   , by     = trt01a
   , median = no
   , ylabel = "Subjects without a skin event (%)"
   , file   = &spl_out./figures/f_ttde_again
 )
TITLE;
FOOTNOTE;

/* %forestplot: https://datastep-labs.github.io/sapling-sas/reference/forestplot/ */
* Draws the hazard ratios of each subgroup on a log scale, with the reference line at 1.;
%forestplot(
     data     = hr_sub
   , columns  = t14_2_1_cols
   , estimate = hr
   , within   = sex agegr1
   , by       = trt01a
   , scale    = log
   , ref      = 1
   , file     = &spl_out./figures/f_hr_sub
   , out      = f_hr_sub
 )
TITLE;
FOOTNOTE;

/* %meanplot: https://datastep-labs.github.io/sapling-sas/reference/meanplot/ */
* Draws the mean change and its SE at each visit, a panel per parameter, with the n of each point.;
%meanplot(
     data    = advs
   , columns = t14_2_1_cols
   , where   = (paramcd IN ('SYSBP' 'DIABP') AND anl01fl = 'Y' AND avisitn < 99)
   , y       = chg
   , x       = avisitn
   , by      = trt01a
   , panel   = param
   , ntable  = yes
   , xformat = VISIT.
   , ref     = 0
   , file    = &spl_out./figures/f_bp_mean
   , out     = f_bp_mean
 )
TITLE;
FOOTNOTE;

/* %lineplot: https://datastep-labs.github.io/sapling-sas/reference/lineplot/ */
* Draws the means that meanplot kept as lines, with a band between the limits.;
%lineplot(
     data    = f_bp_mean
   , columns = t14_2_1_cols
   , x       = x
   , y       = y
   , by      = trt01a
   , panel   = param
   , lower   = lower
   , upper   = upper
   , band    = yes
   , xformat = VISIT.
   , ylabel  = "Mean change from baseline (SE)"
   , ref     = 0
   , file    = &spl_out./figures/f_bp_line
   , out     = f_bp_line
 )
TITLE;
FOOTNOTE;

/* %boxplot: https://datastep-labs.github.io/sapling-sas/reference/boxplot/ */
* Draws a box of the change of the systolic blood pressure at each visit for each group.;
%boxplot(
     data    = advs
   , columns = t14_2_1_cols
   , where   = (paramcd = 'SYSBP' AND anl01fl = 'Y' AND avisitn IN (4 12 24))
   , y       = chg
   , x       = avisitn
   , by      = trt01a
   , xformat = VISIT.
   , ref     = 0
   , file    = &spl_out./figures/f_sbp_box
   , out     = f_sbp_box
 )
TITLE;
FOOTNOTE;

/* %barplot: https://datastep-labs.github.io/sapling-sas/reference/barplot/ */
* Draws the percent of the subjects with each severity in each group, of the N of denom=.;
%barplot(
     data    = adae
   , columns = t14_2_1_cols
   , denom   = adsl
   , where   = (trtemfl = 'Y')
   , var     = aesev
   , by      = trt01a
   , file    = &spl_out./figures/f_ae_sev
   , out     = f_ae_sev
 )
TITLE;
FOOTNOTE;

/* %aeplot: https://datastep-labs.github.io/sapling-sas/reference/aeplot/ */
* Draws the percent of each term of 5 percent or more and its risk difference against Placebo.;
%aeplot(
     data      = adae
   , columns   = t14_2_1_cols
   , denom     = adsl
   , where     = (trtemfl = 'Y')
   , term      = aedecod
   , by        = trt01a
   , reference = "Placebo"
   , threshold = 5
   , file      = &spl_out./figures/f_ae_risk
   , out       = f_ae_risk
 )
TITLE;
FOOTNOTE;

/* %profileplot: https://datastep-labs.github.io/sapling-sas/reference/profileplot/ */
* Draws the ALT of each subject over the study days: one line per subject, no mean.;
%profileplot(
     data    = adlb
   , columns = t14_2_1_cols
   , where   = (paramcd = 'ALT' AND anl01fl = 'Y' AND MISSING(dtype))
   , x       = ady
   , y       = aval
   , by      = trt01a
   , mean    = no
   , file    = &spl_out./figures/f_alt_prof
   , out     = f_alt_prof
 )
TITLE;
FOOTNOTE;

/* %scatterplot: https://datastep-labs.github.io/sapling-sas/reference/scatterplot/ */
* Draws the ALT at Week 24 against its baseline, with the line where the two are equal.;
%scatterplot(
     data     = adlb
   , columns  = t14_2_1_cols
   , where    = (paramcd = 'ALT' AND avisit = 'Week 24')
   , x        = base
   , y        = aval
   , by       = trt01a
   , identity = yes
   , file     = &spl_out./figures/f_alt_scat
   , out      = f_alt_scat
 )
TITLE;
FOOTNOTE;

/* %table_summary: https://datastep-labs.github.io/sapling-sas/reference/table_summary/ */
* Makes the demographic table from one row per subject: age as numbers, the categories as rows.;
%table_summary(
     data   = adam.adsl
   , where  = (saffl = 'Y')
   , vars   = age agegr1# sex# race# ethnic#
   , by     = trt01a
   , order  = trt01an
   , total  = yes
   , format = sex $sexf.
   , title  = "Table 14.2.1 Demographic characteristics" "Safety population"
   , file   = &spl_out./tlf/t14_2_1_summary
 )
* Names the blocks, plans a race with no subject and asks for Q1 and Q3: ASIAN has a row of 0.;
%table_summary(
     data     = adsl
   , vars     = age trtdurd race#
   , by       = trt01a
   , order    = trt01an
   , levels   = race 'WHITE' 'BLACK OR AFRICAN AMERICAN' 'ASIAN' 'AMERICAN INDIAN OR ALASKA NATIVE'
   , catstats = n pct
   , names    = age="Age (years)" trtdurd="Duration of treatment (days)" race="Race"
   , stats    = n mean sd median q1 q3 min max
   , title    = "Table 14.2.2 Age, duration of treatment and race"
   , file     = &spl_out./tlf/t14_2_2
 )
TITLE;
FOOTNOTE;

/* %table_ae: https://datastep-labs.github.io/sapling-sas/reference/table_ae/ */
* Makes the table of the subjects with an event by class and term, each term by its subjects.;
%table_ae(
     data  = adam.adae
   , adsl  = adam.adsl
   , pop   = (saffl = 'Y')
   , where = (trtemfl = 'Y')
   , var   = aebodsys aedecod
   , by    = trt01a
   , order = trt01an
   , sort  = frequency
   , label = "Treatment-emergent adverse events"
   , title = "Table 14.5.2 Treatment-emergent adverse events by SOC and PT"
   , file  = &spl_out./tlf/t14_5_2
 )
* Keeps the terms that reach 5 percent in a group, with the events and a Total column.;
%table_ae(
     data      = adae
   , adsl      = adsl
   , where     = (trtemfl = 'Y')
   , var       = aedecod
   , by        = trt01a
   , order     = trt01an
   , sort      = frequency
   , threshold = 5
   , total     = yes
   , label     = "Subjects with an event, n (%) and events"
   , stats     = n pct events
   , title     = "Table 14.5.3 Common treatment-emergent adverse events"
   , file      = &spl_out./tlf/t14_5_3
 )
TITLE;
FOOTNOTE;

/* %table_visit: https://datastep-labs.github.io/sapling-sas/reference/table_visit/ */
* Makes the table of the value at each visit and of its change after baseline.;
%table_visit(
     data  = adam.advs
   , adsl  = adam.adsl
   , pop   = (saffl = 'Y')
   , where = (paramcd = 'SYSBP' AND (ablfl = 'Y' OR anl01fl = 'Y'))
   , vars  = aval chg
   , by    = trt01a
   , keep  = param paramn avisitn
   , order = trt01an
   , post  = chg
   , title = "Table 14.7.1 Systolic blood pressure by visit"
   , file  = &spl_out./tlf/t14_7_1
 )
* Names the blocks, asks for Q1 and Q3 and adds a Total column.;
%table_visit(
     data  = advs
   , adsl  = adsl
   , where = (paramcd = 'DIABP' AND (ablfl = 'Y' OR anl01fl = 'Y') AND avisitn IN (0 12 24))
   , vars  = aval chg
   , by    = trt01a
   , keep  = param paramn avisitn
   , order = trt01an
   , post  = chg
   , names = aval="Value" chg="Change from baseline"
   , total = yes
   , stats = n mean sd median q1 q3 min max
   , title = "Table 14.7.2 Diastolic blood pressure at Week 12 and Week 24"
   , file  = &spl_out./tlf/t14_7_2
 )
TITLE;
FOOTNOTE;

/* %table_model: https://datastep-labs.github.io/sapling-sas/reference/table_model/ */
* Makes the ANCOVA table at Week 12: three descriptive blocks, then the LS means and difference.;
%table_model(
     data     = advs
   , adsl     = adsl
   , where    = (paramcd = 'SYSBP' AND anl01fl = 'Y' AND avisitn < 99)
   , covars   = base
   , by       = trt01p
   , at       = "Week 12"
   , order    = trt01pn
   , describe = base aval chg
   , pairs    = "Xanomeline High Dose" "Placebo"
   , title    = "Table 14.3.1 ANCOVA of the change of systolic blood pressure at Week 12"
   , file     = &spl_out./tlf/t14_3_1
 )
* Uses method=mmrm with the model of the mmrm example: the same differences at Week 24.;
%table_model(
     data     = advs
   , adsl     = adsl
   , where    = (paramcd = 'SYSBP' AND anl01fl = 'Y' AND avisitn IN (4 8 12 16 24))
   , covars   = base
   , visit    = avisit
   , by       = trt01p
   , at       = "Week 24"
   , order    = trt01pn
   , method   = mmrm
   , model    = base trt01p avisit trt01p*avisit base*avisit
   , type     = un
   , fallback = toep
   , title    = "Table 14.3.3 MMRM of the change of systolic blood pressure at Week 24"
   , file     = &spl_out./tlf/t14_3_3
 )
TITLE;
FOOTNOTE;

/* %table_response: https://datastep-labs.github.io/sapling-sas/reference/table_response/ */
* Makes the table of the responders with their limits and the risk difference of each pair.;
%table_response(
     data   = adrs
   , where  = (paramcd = 'RSP')
   , var    = avalc
   , by     = trt01a
   , order  = trt01an
   , diffci = newcombe
   , title  = "Table 14.3.2 Responders"
   , file   = &spl_out./tlf/t14_3_2
 )
* Asks for Wilson limits of each percent, the relative risk, and the odds ratio adjusted for age.;
%table_response(
     data    = adrs
   , where   = (paramcd = 'RSP')
   , var     = avalc
   , event   = "Y"
   , by      = trt01a
   , covars  = age
   , order   = trt01an
   , pairs   = "Xanomeline High Dose" "Placebo"
             # "Xanomeline Low Dose"  "Placebo"
   , ci      = wilson
   , measure = rr
   , title   = "Table 14.3.4 Responders: relative risk and odds ratio adjusted for age"
   , file    = &spl_out./tlf/t14_3_4
 )
TITLE;
FOOTNOTE;

/* %table_tte: https://datastep-labs.github.io/sapling-sas/reference/table_tte/ */
* Makes the table of the time to the event: Kaplan Meier, the log rank test and the hazard ratio.;
%table_tte(
     data  = adttde
   , by    = trt01a
   , order = trt01an
   , pairs = "Xanomeline High Dose" "Placebo"
   , title = "Table 14.6.1 Time to the first skin event"
   , file  = &spl_out./tlf/t14_6_1
 )
* Takes the N of each column from adsl= and stratifies the test and the Cox model by sex.;
%table_tte(
     data   = adttde
   , adsl   = adsl
   , by     = trt01a
   , strata = sex
   , order  = trt01an
   , title  = "Table 14.6.2 Time to the first skin event, stratified by sex"
   , file   = &spl_out./tlf/t14_6_2
 )
TITLE;
FOOTNOTE;

/* %table_shift: https://datastep-labs.github.io/sapling-sas/reference/table_shift/ */
* Makes the shift table of the normal range at Week 12 and Week 24, with every planned level.;
%table_shift(
     data   = adlb
   , where  = (avisit IN ('Week 12' 'Week 24'))
   , within = paramcd avisit
   , by     = trt01a
   , order  = trt01an
   , levels = 'LOW' 'NORMAL' 'HIGH'
   , title  = "Table 14.8.1 Shift from baseline of the normal range"
   , file   = &spl_out./tlf/t14_8_1
 )
* Shifts to the highest value after baseline, with a label of the block and a Total column.;
%table_shift(
     data   = adlb
   , adsl   = adsl
   , where  = (avisit = 'POST-BASELINE MAXIMUM')
   , within = paramcd
   , by     = trt01a
   , keep   = param
   , order  = trt01an
   , levels = 'LOW' 'NORMAL' 'HIGH'
   , total  = yes
   , label  = "Baseline by the highest value after baseline"
   , title  = "Table 14.8.2 Shift to the highest value after baseline"
   , file   = &spl_out./tlf/t14_8_2
 )
TITLE;
FOOTNOTE;

/* %merge_subject: https://datastep-labs.github.io/sapling-sas/reference/merge_subject/ */
* Copies the time to event records with four variables of their own.;
DATA tt;
  SET adtte;
  KEEP usubjid paramcd aval cnsr;
RUN;
* Adds the age group, the race and the planned treatment of adsl by USUBJID, two of them renamed.;
%merge_subject(
     data = tt
   , from = adsl
   , vars = agegr1 race trtp=trt01p trtpn=trt01pn
 )
TITLE;
FOOTNOTE;

/* %pick: https://datastep-labs.github.io/sapling-sas/reference/pick/ */
* Copies the subjects with USUBJID and TRTSDT only.;
DATA sl;
  SET adsl;
  KEEP usubjid trtsdt;
RUN;
* Takes the date of the first exposure record of each subject, as a text of 10.;
%pick(
     data   = sl
   , from   = sdtm.ex
   , value  = exstdtc
   , order  = exstdtc exseq
   , which  = first
   , length = $10
   , new    = exfstdtc
 )
* Takes the dose of the last exposure record of each subject.;
%pick(
     data  = sl
   , from  = sdtm.ex
   , value = exdose
   , order = exstdtc exseq
   , which = last
   , new   = exldose
 )
* Keeps the disposition event of each subject: one record per subject.;
DATA ds_eos;
  SET sdtm.ds;
  WHERE dscat = 'DISPOSITION EVENT';
RUN;
* Takes the disposition term: unique=yes checks one record per subject, so no order is needed.;
%pick(
     data   = sl
   , from   = work.ds_eos
   , value  = dsdecod
   , unique = yes
   , new    = dcdecod
 )
TITLE;
FOOTNOTE;

/* %summarize: https://datastep-labs.github.io/sapling-sas/reference/summarize/ */
* Copies the subjects with USUBJID and TRTDURD only.;
DATA sl;
  SET adsl;
  KEEP usubjid trtdurd;
RUN;
* Takes the largest end day of the exposure records of each subject.;
%summarize(
     data  = sl
   , from  = sdtm.ex
   , value = exendy
   , stat  = max
   , new   = exlstdy
 )
* Takes the mean dose of the exposure records of each subject.;
%summarize(
     data  = sl
   , from  = sdtm.ex
   , value = exdose
   , stat  = mean
   , new   = exmdose
 )
TITLE;
FOOTNOTE;

/* %flag_if_any: https://datastep-labs.github.io/sapling-sas/reference/flag_if_any/ */
* Copies the subjects with USUBJID and EOSSTT only.;
DATA sl;
  SET adsl;
  KEEP usubjid eosstt;
RUN;
* Sets COMPLFL to Y for a subject with a disposition record COMPLETED, else to N.;
%flag_if_any(
     data  = sl
   , from  = sdtm.ds
   , where = (dsdecod = 'COMPLETED')
   , new   = complfl
 )
TITLE;
FOOTNOTE;

/* %pool: https://datastep-labs.github.io/sapling-sas/reference/pool/ */
* Copies the subjects with their site and their planned treatment.;
DATA sl;
  SET adsl;
  KEEP usubjid siteid trt01p;
RUN;
* Pools each site with fewer than 3 subjects in a group into the site group 900.;
%pool(
     data   = sl
   , var    = siteid
   , by     = trt01p
   , min    = 3
   , length = $3
   , new    = sitegr1
   , into   = 900
 )
TITLE;
FOOTNOTE;

/* %param_wide: https://datastep-labs.github.io/sapling-sas/reference/param_wide/ */
* Puts the value and the change of SYSBP and DIABP side by side: one row per subject and visit.;
%param_wide(
     data   = advs
   , where  = (anl01fl = 'Y')
   , params = sysbp diabp
   , vars   = aval chg
   , by     = usubjid avisitn
   , out    = bp_wide
 )
TITLE;
FOOTNOTE;

/* %summarize_groups: https://datastep-labs.github.io/sapling-sas/reference/summarize_groups/ */
* Takes the largest AVAL and the smallest CHG of each subject and parameter: one record each.;
%summarize_groups(
     data  = advs
   , by    = usubjid paramcd
   , vars  = aval chg
   , stats = max min
   , out   = vs_extremes
 )
TITLE;
FOOTNOTE;

/* %visits: https://datastep-labs.github.io/sapling-sas/reference/visits/ */
* Copies the ALT records that are not derived, without an analysis visit.;
DATA lb;
  SET adlb;
  WHERE paramcd = 'ALT' AND MISSING(dtype);
  KEEP usubjid paramcd visit aval;
RUN;
* Maps each collected visit to its analysis visit and its number: SCREENING 1 is the Baseline.;
%visits(
     data   = lb
   , visits = "SCREENING 1" 0  "Baseline"
            # "WEEK 2"      2  "Week 2"
            # "WEEK 4"      4  "Week 4"
            # "WEEK 6"      6  "Week 6"
            # "WEEK 8"      8  "Week 8"
            # "WEEK 12"     12 "Week 12"
            # "WEEK 16"     16 "Week 16"
            # "WEEK 20"     20 "Week 20"
            # "WEEK 24"     24 "Week 24"
            # "WEEK 26"     26 "Week 26"
 )
TITLE;
FOOTNOTE;

/* %windows: https://datastep-labs.github.io/sapling-sas/reference/windows/ */
* Copies the systolic records with only the variables the windows need: no old AVISIT or AVISITN.;
DATA vs;
  SET advs;
  WHERE paramcd = 'SYSBP';
  KEEP usubjid paramcd param adt ady aval vsseq;
RUN;
* Puts each record in the window of its study day, with the limits, the target and the distance.;
%windows(
     data    = vs
   , windows = 0  "Baseline" .   1   1   "<=1"
             # 4  "Week 4"   2   42  28  "2-42"
             # 12 "Week 12"  43  126 84  "43-126"
             # 24 "Week 24"  127 210 168 "127-210"
   , day     = ady
 )
TITLE;
FOOTNOTE;

/* %locf: https://datastep-labs.github.io/sapling-sas/reference/locf/ */
* Copies the systolic records of the analysis visits.;
DATA vs;
  SET advs;
  WHERE paramcd = 'SYSBP' AND avisitn IN (0 4 12 24);
RUN;
* Carries the last value forward into a visit without a value: DTYPE is LOCF on the new records.;
%locf(
     data    = vs
   , windows = 0  "Baseline" .   1   1   "<=1"
             # 4  "Week 4"   2   42  28  "2-42"
             # 12 "Week 12"  43  126 84  "43-126"
             # 24 "Week 24"  127 210 168 "127-210"
   , where   = (paramcd = 'SYSBP')
   , length  = $7
 )
TITLE;
FOOTNOTE;

/* %baseline: https://datastep-labs.github.io/sapling-sas/reference/baseline/ */
* Copies the systolic records.;
DATA vs;
  SET advs;
  WHERE paramcd = 'SYSBP';
RUN;
* Copies the value of the baseline record to BASE on each record of its subject and parameter.;
%baseline(
     data    = vs
   , value   = aval
   , by      = usubjid paramcd
   , replace = yes
   , new     = base
 )
TITLE;
FOOTNOTE;

/* %flag_first: https://datastep-labs.github.io/sapling-sas/reference/flag_first/ */
* Copies the systolic records.;
DATA vs;
  SET advs;
  WHERE paramcd = 'SYSBP';
RUN;
* Flags in ANL02FL the first record of each subject, parameter and visit by day and time point.;
%flag_first(
     data  = vs
   , where = (NOT MISSING(avisitn) AND NOT MISSING(aval))
   , by    = usubjid paramcd avisitn
   , order = ady atptn vsseq
   , new   = anl02fl
 )
TITLE;
FOOTNOTE;

/* %relchange: https://datastep-labs.github.io/sapling-sas/reference/relchange/ */
* Adds a record per value: its change from the record before, relative to half the normal range.;
%relchange(
     data  = adlb
   , where = (paramcd = 'ALT' AND MISSING(dtype))
   , value = lbstresn
   , lo    = anrlo
   , hi    = anrhi
   , out   = alt_rel
 )
TITLE;
FOOTNOTE;
