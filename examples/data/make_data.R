# The example data of the SAS macro library: data sets of the R packages pharmaverseadam 1.3.0 and
# pharmaversesdtm 1.4.0 (Apache License 2.0, github.com/pharmaverse), written as SAS transport files
# (version 5). The subjects are those of the CDISC pilot study (public example data). Each subset and
# each added variable is written below; no value of the packages is changed.
# Run in this folder: Rscript make_data.R
library(pharmaverseadam)  # 1.3.0; install it into a library of its own and give that library in R_LIBS
library(pharmaversesdtm)  # 1.4.0
stopifnot(packageVersion("pharmaverseadam") == "1.3.0", packageVersion("pharmaversesdtm") == "1.4.0")

# The treatments as numbers, the order of the columns of a table (order= of the macros): the planned
# doses of the CDISC pilot, Placebo 0, Xanomeline Low Dose 54, Xanomeline High Dose 81 (mg). The
# packages have only the treatment as text (TRT01P, TRT01A); a screen failure has no number.
dose <- c("Placebo" = 0, "Xanomeline Low Dose" = 54, "Xanomeline High Dose" = 81)
labelled <- function(x, label) structure(x, label = label)
twins <- function(d) {
  d$TRT01PN <- labelled(unname(dose[d$TRT01P]), "Planned Treatment for Period 01 (N)")
  d$TRT01AN <- labelled(unname(dose[d$TRT01A]), "Actual Treatment for Period 01 (N)")
  d
}
# The variables of each subject from ADSL, by USUBJID, in the order of the rows of d
from_adsl <- function(d, vars) {
  k <- match(d$USUBJID, pharmaverseadam::adsl$USUBJID)
  for (v in vars) d[[v]] <- pharmaverseadam::adsl[[v]][k]
  d
}
safety <- function(d) d[!is.na(d$SAFFL) & d$SAFFL == "Y", ]
keep <- function(d, vars) d[, intersect(vars, names(d))]

# ADSL: every subject (also the screen failures: the population is chosen in a program), with the
# treatment numbers and TEAECNT, the number of treatment-emergent adverse events of a subject of the
# safety population (0 without one; missing for a screen failure): the count of %rateratio.
adsl <- twins(pharmaverseadam::adsl)
teae <- table(pharmaverseadam::adae$USUBJID[pharmaverseadam::adae$TRTEMFL %in% "Y"])
adsl$TEAECNT <- labelled(ifelse(adsl$SAFFL %in% "Y", as.numeric(teae[adsl$USUBJID]), NA_real_),
                         "Number of Treatment-emergent AEs")
adsl$TEAECNT[adsl$SAFFL %in% "Y" & is.na(adsl$TEAECNT)] <- 0

# ADAE: every record, with the treatment numbers of ADSL
adae <- twins(pharmaverseadam::adae)

# ADVS: systolic and diastolic blood pressure after lying down for 5 minutes (ATPTN 815) and weight,
# of the safety population; fewer variables (the size of the file: not TRTP, TRTA, PCHG, the visit of
# SDTM and the text of ATPTN)
advs <- pharmaverseadam::advs
advs <- safety(advs[(advs$PARAMCD %in% c("SYSBP", "DIABP") & advs$ATPTN %in% 815) |
                    advs$PARAMCD %in% "WEIGHT", ])
advs <- keep(twins(advs), c(
  "STUDYID", "USUBJID", "SITEID", "AGE", "AGEGR1", "SEX", "RACE", "SAFFL", "TRT01P", "TRT01PN",
  "TRT01A", "TRT01AN", "TRTSDT", "TRTEDT", "ADT", "ADY", "AVISIT", "AVISITN", "ATPTN", "PARAM",
  "PARAMCD", "PARAMN", "AVAL", "BASE", "CHG", "ANRIND", "BNRIND", "DTYPE", "ABLFL", "ANL01FL",
  "ONTRTFL", "VSSEQ"))

# ADLB: alanine aminotransferase and aspartate aminotransferase of the safety population; fewer
# variables (not TRTP, TRTA, PCHG, PARCAT1 and the test and its normal range of SDTM)
adlb <- pharmaverseadam::adlb
adlb <- safety(adlb[adlb$PARAMCD %in% c("ALT", "AST"), ])
adlb <- keep(twins(adlb), c(
  "STUDYID", "USUBJID", "SITEID", "AGE", "AGEGR1", "SEX", "RACE", "SAFFL", "TRT01P", "TRT01PN",
  "TRT01A", "TRT01AN", "TRTSDT", "TRTEDT", "ADT", "ADY", "VISIT", "VISITNUM", "AVISIT", "AVISITN",
  "PARAM", "PARAMCD", "PARAMN", "AVAL", "BASE", "CHG", "ANRIND", "BNRIND", "ANRLO", "ANRHI",
  "DTYPE", "ABLFL", "ANL01FL", "ONTRTFL", "LBSEQ", "LBSTRESN"))

# ADTTE: the data set adtte_onco (overall survival, progression-free survival, response duration),
# with the treatments of ADSL (TRT01P, TRT01PN, TRT01A, TRT01AN)
adtte <- twins(from_adsl(pharmaverseadam::adtte_onco, c("TRT01P", "TRT01A")))

# ADRS: the data set adrs_onco, the parameters BOR (best overall response) and RSP (responder), the
# subjects of the safety population, with the treatment numbers; fewer variables
adrs <- pharmaverseadam::adrs_onco
adrs <- safety(adrs[adrs$PARAMCD %in% c("BOR", "RSP"), ])
adrs <- keep(twins(adrs), c(
  "STUDYID", "USUBJID", "SUBJID", "SITEID", "AGE", "AGEGR1", "SEX", "RACE", "SAFFL", "TRT01P",
  "TRT01PN", "TRT01A", "TRT01AN", "TRTSDT", "ADT", "AVISIT", "PARAM", "PARAMCD", "AVAL", "AVALC",
  "ANL01FL"))

# SDTM: the domains DS (disposition) and EX (exposure), every record
ds <- pharmaversesdtm::ds
ex <- pharmaversesdtm::ex

for (d in c("adsl", "adae", "advs", "adlb", "adtte", "adrs", "ds", "ex")) {
  haven::write_xpt(get(d), paste0(d, ".xpt"), version = 5, name = d)
}
