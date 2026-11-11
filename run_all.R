# Reproduce the supplementary tables, Figures 2-4 and the supporting counts from the deposited workbook.
# Run from the repository root:  Rscript run_all.R
required <- c("ggplot2", "patchwork", "dplyr", "tidyr", "readr", "scales", "ragg", "systemfonts")
missing <- required[!vapply(required, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) stop("Install required R packages: ", paste(missing, collapse = ", "))
python <- Sys.getenv("PYTHON", unset = Sys.which("python3"))
if (!nzchar(python)) stop("Python 3 with openpyxl and pandas is required; set PYTHON to its executable.")
if (!file.exists("code/load_data.py")) stop("Run Rscript run_all.R from the repository root.")
for (d in c(".cache/data", ".cache/logs", "output/figures", "output/tables/si", "output/numbers")) dir.create(d, recursive = TRUE, showWarnings = FALSE)

run <- function(command, script) {
  message(format(Sys.time(), "%H:%M:%S"), "  ", script)
  log <- file.path(".cache/logs", paste0(basename(script), ".txt"))
  status <- system2(command, shQuote(script), stdout = log, stderr = log)
  if (status != 0L) { cat(tail(readLines(log), 25), sep = "\n"); stop("Failed: ", script) }
}
rscript <- file.path(R.home("bin"), "Rscript")
run(python, "code/load_data.py")
run(python, "code/descriptive.py")
for (script in c("analysis_01_joint_reporting.R", "analysis_02_sampling_coverage.R", "analysis_03_within_setting.R", "validate.R"))
  run(rscript, file.path("code", script))
run(python, "code/tables_si.py")
run(rscript, "code/figures.R")
writeLines(capture.output(sessionInfo()), "output/sessionInfo.txt")
message("Complete: figures, table fragments and counts are in output/.")
