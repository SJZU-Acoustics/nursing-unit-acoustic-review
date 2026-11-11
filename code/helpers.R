# Shared inputs and mappings for the three analyses. Run from the repository root.
d <- read.csv('output/numbers/analysis_records.csv', check.names = FALSE, stringsAsFactors = FALSE,
              colClasses = c(recording_mode = 'character', clock_coverage = 'character', documented_locations = 'character'))
stopifnot(nrow(d) == 87, !anyDuplicated(d$dataset_id))
codes <- data.frame(dataset_id = d$dataset_id, mode = d$recording_mode, coverage = d$clock_coverage,
                    space = d$documented_locations, controlled = as.integer(d$controlled_test), note = d$sampling_note)
status_levels <- c('Full', 'Partial', 'Absent', 'Not applicable')
fields <- c(weighting = 'frequency_weighting', integration = 'integration_window', logging = 'logging_interval',
            instrument = 'instrument_class', calibration = 'calibration')
for (n in names(fields)) { stopifnot(all(d[[fields[n]]] %in% status_levels)); d[[n]] <- d[[fields[n]]] }
pairs <- list(weighting_integration = c('weighting', 'integration'), logging_integration = c('logging', 'integration'),
              instrument_calibration = c('instrument', 'calibration'))
purposes <- c('U-A', 'U-B', 'U-C', 'U-D', 'U-E', 'U-F', 'U-G', 'U-H')
groups <- c(list(All = rep(TRUE, nrow(d))), setNames(lapply(purposes, function(u) d[[u]] == 1), purposes))
ids <- function(mask) paste(d$dataset_id[mask], collapse = ';')
pct <- function(n, den) if (den == 0) NA_real_ else round(100 * n / den, 1)
out <- function(x, path) write.csv(x, path, row.names = FALSE, na = '', fileEncoding = 'UTF-8')
