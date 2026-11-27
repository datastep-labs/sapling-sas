# The data of the proof: ADSL and ADAE of the R package pharmaverseadam 1.3.0 (Apache License 2.0,
# github.com/pharmaverse/pharmaverseadam), written as SAS transport files (version 5) without a change.
# Run in this folder: Rscript make_xpt.R
stopifnot(packageVersion("pharmaverseadam") == "1.3.0")
for (d in c("adsl", "adae")) {
  haven::write_xpt(getExportedValue("pharmaverseadam", d), paste0(d, ".xpt"), version = 5, name = d)
}
