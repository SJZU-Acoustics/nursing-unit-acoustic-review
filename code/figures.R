#!/usr/bin/env Rscript
# ---------------------------------------------------------------------------
# figures.R -- Figures 2-4 of the hospital nursing-unit acoustic-environment
# scoping review.
#
# Run from the repository root:
#     Rscript code/figures.R   (run_all.R does this last)
#
# Outputs (output/figures/):
#   fig2_sampling_coverage.png       a: recording mode x clock coverage counts with
#                                    marginal totals; b: integration-window reporting
#                                    status by clock coverage (stacked bars)
#   fig3_reporting_completeness.png  a: field completeness (100 % stacked bars);
#                                    b: joint pair completeness by purpose group
#   fig4_method_purpose.png          method x purpose matrix (counts; fill = share of
#                                    the purpose group)
#   figure_values_check.csv          every number drawn: figure, panel, row, column,
#                                    value, note -- for checking against the manuscript
#
# Style: double column 178 mm, square plot areas
# aligned within a row, Helvetica 9 pt (axis titles 10 pt), no grid, no figure title,
# black left/bottom axes with outward ticks on bar panels only (none on tile
# matrices), lowercase panel tags at the top-left of the full panel footprint,
# PNG 600 dpi, opaque white, Okabe-Ito colours.
# No data value is typed in this file: every number comes from the source CSVs.
# ---------------------------------------------------------------------------

suppressPackageStartupMessages({
  library(ggplot2); library(patchwork); library(dplyr); library(tidyr)
  library(readr); library(scales); library(ragg); library(systemfonts)
})

if (!file.exists("code/figures.R"))
  stop("Run from the repository root: Rscript code/figures.R")
OUT_DIR <- "output/figures"
dir.create(OUT_DIR, showWarnings = FALSE, recursive = TRUE)

# ===========================================================================
# 1. Style specification -- the one place where appearance is decided
# ===========================================================================
STYLE <- list(
  figure_width_mode    = "double_column",
  fig_width_mm         = 178,
  fig4_max_height_mm   = 172,    # single-panel matrix: square if it fits, else as tall as this
  panel_aspect         = "square plot areas, equal within a row",
  font_family_primary  = "Helvetica",
  font_family_fallback = "Arial",
  font_size_base       = 9,      # tick labels, legend text, in-plot data labels
  font_size_axis_title = 10,
  font_size_tag        = 10,
  tick_direction       = "out",
  tick_length_mm       = 1.0,
  major_tick_target    = "5-8 per axis (double column)",
  minor_ticks          = FALSE,
  show_spines          = "left + bottom on bar panels; none on tile matrices",
  grid_mode            = "off",
  legend_strategy      = "multi-panel: top strip, right of the panel tag; Fig 4: below the matrix",
  panel_label_mode     = "lowercase a, b; top-left of the full panel footprint",
  output_format        = "png",
  dpi                  = 600,
  transparent          = FALSE,
  # shared encodings (identical in every figure) ----------------------------
  status_fill  = c(full = "#0072B2", partial = "#E69F00", absent = "#BBBBBB", not_applicable = "#FFFFFF"),
  status_line  = c(full = "#0072B2", partial = "#E69F00", absent = "#BBBBBB", not_applicable = "grey55"),
  status_label = c(full = "Full", partial = "Partial", absent = "Absent", not_applicable = "Outside equivalent-
metric denominator"),
  seq_low      = "#FFFFFF",
  seq_high     = "#0072B2",
  text_switch  = 0.55,           # fraction of the scale maximum above which cell text is white
  tile_border  = "grey80",
  tile_border_lwd = 0.3,
  rule_lwd     = 0.4,            # thin black rule separating marginal totals (Fig 2a)
  total_gap    = 0.35,           # extra gap (cell units) before the Total row/column (Fig 2a)
  bar_half_width  = 0.35,        # bars occupy 70 % of the row height
  seg_outline_lwd = 0.3,
  min_label_share = 5,           # Fig 3a: print a count only when the segment is >= 5 %
  label_pad_mm    = 0.3,         # Fig 2b: print a count only when the segment holds it with this padding
  x_title_offset_mm = 6.5        # bar panels: axis title top sits this far below the panel edge
)

FONT <- STYLE$font_family_primary
font_path <- systemfonts::match_fonts(FONT)$path
if (!grepl("Helvetica", font_path, ignore.case = TRUE)) {
  message("Helvetica not found (matched ", font_path, "); using ", STYLE$font_family_fallback)
  FONT <- STYLE$font_family_fallback
}

# ---- helpers ---------------------------------------------------------------
pt2mm <- function(pt) pt * 25.4 / 72
gsize <- function(pt = STYLE$font_size_base) pt / .pt            # geom_text size for a print point size
label_width_mm <- function(x, size = STYLE$font_size_base) {     # widest line of each label, in print mm
  vapply(x, function(s) {
    lines <- strsplit(s, "\n", fixed = TRUE)[[1]]
    max(pt2mm(systemfonts::string_width(lines, family = FONT, size = size, res = 72)))
  }, numeric(1), USE.NAMES = FALSE)
}
cell_text_colour <- function(v, vmax) ifelse(v > STYLE$text_switch * vmax, "white", "black")
read_src <- function(path) {
  if (!file.exists(path)) stop("Missing source file: ", path)
  readr::read_csv(path, show_col_types = FALSE, progress = FALSE)
}
fmt1 <- function(x) formatC(x, format = "f", digits = 1)
# Sum of the absolute (non-null) row heights / column widths of a composed gtable, in
# print mm: the figure height is then fixed rows + the square panel height, exactly.
# Measured on a device at the output resolution: a measuring device at another resolution
# leaves text metrics cached at that resolution, and the render that follows then lands in
# one of two layouts about 2 mm apart from run to run.
fixed_mm <- function(grob) {
  ragg::agg_png(tempfile(fileext = ".png"), width = STYLE$fig_width_mm, height = 100, units = "mm", res = STYLE$dpi)
  on.exit(dev.off())
  c(height = sum(vapply(seq_along(grob$heights), function(i)
                        grid::convertHeight(grob$heights[i], "mm", valueOnly = TRUE), numeric(1))),
    width  = sum(vapply(seq_along(grob$widths),  function(i)
                        grid::convertWidth(grob$widths[i],  "mm", valueOnly = TRUE), numeric(1))))
}
save_png <- function(file, plot, height_mm) {
  ggsave(file, plot, device = ragg::agg_png, width = STYLE$fig_width_mm, height = height_mm,
         units = "mm", dpi = STYLE$dpi, bg = "white")
}
check_rows <- list()   # accumulates the figure_values_check rows
add_check <- function(figure, panel, row, column, value, note = "") {
  check_rows[[length(check_rows) + 1]] <<- tibble(
    figure = figure, panel = panel, row = as.character(row), column = as.character(column),
    value = as.character(value), note = note)
}

# ---- themes ----------------------------------------------------------------
theme_pub <- function(base_size = STYLE$font_size_base,
                      axis_title_size = STYLE$font_size_axis_title) {
  theme_classic(base_size = base_size, base_family = FONT) +
    theme(
      text              = element_text(colour = "black"),
      axis.line         = element_line(colour = "black", linewidth = 0.4),
      axis.ticks        = element_line(colour = "black", linewidth = 0.4),
      axis.ticks.length = unit(STYLE$tick_length_mm, "mm"),       # positive = outward
      axis.title        = element_text(size = axis_title_size),
      axis.text         = element_text(size = base_size, colour = "black"),
      axis.text.y       = element_text(hjust = 1, lineheight = 0.9,
                                       margin = margin(r = 1.5, unit = "mm")),
      legend.text       = element_text(size = base_size),
      legend.title      = element_text(size = base_size),
      legend.background = element_blank(),
      legend.key        = element_blank(),
      panel.grid        = element_blank(),
      plot.title        = element_blank(),
      plot.background   = element_rect(fill = "white", colour = NA),
      panel.background  = element_rect(fill = "white", colour = NA),
      plot.margin       = margin(2, 2, 2, 2, "mm")
    )
}
# Tile matrices: no axis lines, ticks or titles; column labels rotated 90 degrees
# (the columns are 8-16 mm wide, far narrower than any wrapped horizontal label).
# Multi-panel matrices carry them below the matrix so that the panel tags stay next to
# the content and the two plot areas top-align; Fig 4 (single panel) carries them on top.
theme_tile <- function() {
  theme_pub() +
    theme(
      axis.line           = element_blank(),
      axis.ticks          = element_blank(),
      axis.ticks.length   = unit(0, "mm"),
      axis.title          = element_blank(),
      axis.title.x.top    = element_blank(),     # theme_classic sets these two explicitly
      axis.title.x.bottom = element_blank(),
      axis.text.x.top     = element_text(angle = 90, hjust = 0, vjust = 0.5, lineheight = 0.9,
                                         margin = margin(b = 1.5, unit = "mm")),
      axis.text.x.bottom  = element_text(angle = 90, hjust = 1, vjust = 0.5, lineheight = 0.9,
                                         margin = margin(t = 1.5, unit = "mm"))
    )
}
# Legend on the top strip, immediately to the right of the panel tag
theme_legend_strip <- function(tag_room_mm = 6) {
  theme(
    legend.position          = "top",
    legend.location          = "plot",
    legend.justification.top = "left",
    legend.direction         = "horizontal",
    legend.margin            = margin(0, 0, 0, 0),
    legend.box.margin        = margin(0, 0, 0, tag_room_mm, "mm"),
    legend.box.spacing       = unit(2, "mm"),
    legend.key.size          = unit(3.5, "mm"),
    legend.key.spacing.x     = unit(3, "mm"),
    legend.text              = element_text(margin = margin(l = 1.5, unit = "mm"))
  )
}
tag_theme <- theme(
  plot.tag          = element_text(size = STYLE$font_size_tag, face = "bold",
                                   hjust = 0, vjust = 1, family = FONT),
  plot.tag.location = "plot",
  plot.tag.position = c(0, 1)
)
no_outer_margin <- theme(plot.margin = margin(0, 0, 0, 0))   # patchwork's own outer margin
# Bar panels beside a tile matrix: the matrix's rotated column labels make the shared
# axis row ~35 mm tall, which would strand a normal x-axis title far below its axis
# (patchwork's free(type = "label") keeps an empty title row). The title is therefore
# drawn at a fixed offset below the panel edge, centred on the panel like a real title.
x_title_below <- function(label) {
  annotation_custom(grid::textGrob(
    label, x = unit(0.5, "npc"), y = unit(0, "npc") - unit(STYLE$x_title_offset_mm, "mm"), vjust = 1,
    gp = grid::gpar(fontfamily = FONT, fontsize = STYLE$font_size_axis_title, col = "black")))
}
# Horizontal colourbar, title to the left of the bar
guide_seq_bar <- function(len_mm) {
  guide_colourbar(
    theme = theme(
      legend.key.width      = unit(len_mm, "mm"),
      legend.key.height     = unit(3, "mm"),
      legend.ticks          = element_line(colour = "black", linewidth = 0.3),
      legend.ticks.length   = unit(0.8, "mm"),
      legend.frame          = element_rect(colour = "grey60", fill = NA, linewidth = 0.3),
      legend.title.position = "left",
      legend.title          = element_text(vjust = 1, margin = margin(r = 2, unit = "mm")),
      legend.text           = element_text(margin = margin(t = 1, unit = "mm"))
    ),
    draw.ulim = TRUE, draw.llim = TRUE
  )
}
scale_fill_seq <- function(vmax, name = NULL, breaks = waiver(), guide = "none") {
  scale_fill_gradient(low = STYLE$seq_low, high = STYLE$seq_high, limits = c(0, vmax),
                      breaks = breaks, name = name, guide = guide)
}

# ===========================================================================
# 2. Sources
# ===========================================================================
mbc <- read_src("output/numbers/mode_by_coverage.csv")
cai <- read_src("output/numbers/coverage_and_integration.csv")
rc  <- read_src("output/numbers/reporting_completeness.csv")
js  <- read_src("output/numbers/joint_summary.csv")
mpm <- read_src("output/numbers/method_purpose_matrix.csv")
rf  <- read_src("output/numbers/reproduced_frequencies.csv")

# ---- display labels (keyed by the exact source strings) --------------------
MODE_LABELS <- c(
  "Continuous recording within sessions"        = "Continuous within\nsessions",
  "Scheduled short or spot samples"             = "Scheduled short or\nspot samples",
  "Event or scenario selected recording"        = "Event or scenario\nselected",
  "Controlled tests without ambient monitoring" = "Controlled tests\nonly",
  "Acquisition mode unclear"                    = "Acquisition mode\nunclear")
COV_LABELS <- c(
  "Full day-night cycle described"                = "Full day–night cycle\ndescribed",
  "Day/night windows; full cycle not established" = "Day/night windows, full\ncycle not established",
  "Daytime or evening only"                       = "Daytime or evening only",
  "Overnight only"                                = "Overnight only",
  "Clock coverage unclear"                        = "Clock coverage unclear",
  "Ambient clock coverage not applicable"         = "Not applicable")
FIELD_LABELS <- c(
  instrument_class    = "Instrument class",
  calibration         = "Calibration",
  frequency_weighting = "Frequency weighting",
  measurement_height  = "Measurement height",
  logging_interval    = "Logging interval",
  integration_window  = "Integration window")
GROUP_LABELS <- c(
  "All" = "All datasets",
  "U-E" = "Intervention or\ndesign",
  "U-F" = "Patient outcomes",
  "U-G" = "Staff outcomes")
PAIR_LABELS <- c(
  weighting_integration  = "Weighting and\nintegration window",
  logging_integration    = "Logging interval and\nintegration window",
  instrument_calibration = "Instrument class\nand calibration")
METHOD_BASE <- c(
  MP1 = "MP1 Sound-level time-series\nmonitoring",
  MP2 = "MP2 Short or scheduled\nspot measurement",
  MP3 = "MP3 Sound-source or\nactivity logging",
  MP4 = "MP4 Audio, video or signal\nidentification",
  MP5 = "MP5 Linkage with subjective\nor clinical outcomes",
  MP6 = "MP6 Intervention or design\ncomparison",
  MP7 = "MP7 Targeted acoustic\ntesting")
PURPOSE_BASE <- c(
  "U-A" = "U-A Describe current\nconditions",
  "U-B" = "U-B Compare times\nor spaces",
  "U-C" = "U-C Compare with\nstandards",
  "U-D" = "U-D Identify sources\nor events",
  "U-E" = "U-E Evaluate intervention\nor design",
  "U-F" = "U-F Patient\noutcomes",
  "U-G" = "U-G Staff\noutcomes",
  "U-H" = "U-H Method or tool\ndevelopment")
DAGGER_CELLS <- c("MP5 U-F", "MP5 U-G")   # definition-linked method-purpose pairs
STATUS4 <- names(STYLE$status_label)                  # full, partial, absent, not_applicable
STATUS3 <- STATUS4[1:3]

# ===========================================================================
# 3. Figure 2 -- sampling coverage
# ===========================================================================
mode_order <- names(MODE_LABELS); cov_order <- names(COV_LABELS)
n_mode <- length(mode_order);     n_cov <- length(cov_order)
stopifnot(nrow(mbc) == n_mode * n_cov, sum(mbc$Freq) == 87,
          setequal(mbc$mode, mode_order), setequal(mbc$coverage, cov_order),
          nrow(cai) == n_cov, setequal(cai$coverage, cov_order), sum(cai$n) == 87,
          all(cai$full + cai$partial + cai$absent + cai$not_applicable == cai$n),
          all(cai$applicable + cai$not_applicable == cai$n))

# ---- panel a: count matrix with marginal totals ----------------------------
GAP <- STYLE$total_gap
cells_a <- mbc %>%
  transmute(mode, coverage, value = Freq,
            row = match(mode, mode_order), col = match(coverage, cov_order)) %>%
  mutate(x = col, y = n_mode + 1 - row)                      # row 1 at the top
x_tot <- n_cov + 1 + GAP;  y_tot <- -GAP                     # Total column (right), Total row (bottom)
row_tot <- cells_a %>% group_by(mode, y) %>% summarise(value = sum(value), .groups = "drop") %>% mutate(x = x_tot)
col_tot <- cells_a %>% group_by(coverage, x) %>% summarise(value = sum(value), .groups = "drop") %>% mutate(y = y_tot)
grand   <- tibble(value = sum(cells_a$value), x = x_tot, y = y_tot)
totals_a <- bind_rows(row_tot %>% select(x, y, value), col_tot %>% select(x, y, value), grand)
# column totals must equal panel b's denominators
chk <- col_tot %>% inner_join(cai %>% select(coverage, n), by = "coverage")
stopifnot(nrow(chk) == n_cov, all(chk$value == chk$n))
vmax_a <- max(cells_a$value)
cells_a <- cells_a %>% mutate(txt = cell_text_colour(value, vmax_a))
xlim_a <- c(0.5, x_tot + 0.5);  ylim_a <- c(y_tot - 0.5, n_mode + 0.5)
x_rule <- n_cov + 0.5 + GAP / 2; y_rule <- 0.5 - GAP / 2

p2a <- ggplot() +
  geom_tile(data = cells_a, aes(x, y, fill = value), width = 1, height = 1,
            colour = STYLE$tile_border, linewidth = STYLE$tile_border_lwd) +
  geom_tile(data = totals_a, aes(x, y), width = 1, height = 1, fill = "white",
            colour = STYLE$tile_border, linewidth = STYLE$tile_border_lwd) +
  annotate("segment", x = x_rule, xend = x_rule, y = ylim_a[1], yend = ylim_a[2],
           colour = "black", linewidth = STYLE$rule_lwd) +
  annotate("segment", x = xlim_a[1], xend = xlim_a[2], y = y_rule, yend = y_rule,
           colour = "black", linewidth = STYLE$rule_lwd) +
  geom_text(data = cells_a, aes(x, y, label = value, colour = txt), size = gsize(), family = FONT) +
  geom_text(data = totals_a, aes(x, y, label = value), colour = "black", size = gsize(), family = FONT) +
  scale_colour_identity() +
  scale_fill_seq(vmax_a) +
  scale_x_continuous(breaks = c(seq_len(n_cov), x_tot), labels = c(unname(COV_LABELS), "Total"),
                     limits = xlim_a, expand = c(0, 0)) +
  scale_y_continuous(breaks = c(n_mode:1, y_tot), labels = c(unname(MODE_LABELS), "Total"),
                     limits = ylim_a, expand = c(0, 0)) +
  labs(x = NULL, y = NULL) +
  coord_cartesian(clip = "off") +
  theme_tile()

for (i in seq_len(nrow(cells_a)))
  add_check("fig2", "a", cells_a$mode[i], cells_a$coverage[i], cells_a$value[i], "cell count")
for (i in seq_len(nrow(row_tot))) add_check("fig2", "a", row_tot$mode[i], "Total", row_tot$value[i], "row total")
for (i in seq_len(nrow(col_tot))) add_check("fig2", "a", "Total", col_tot$coverage[i], col_tot$value[i], "column total")
add_check("fig2", "a", "Total", "Total", grand$value, "grand total")

# ---- panel b: integration-window status by clock coverage -------------------
XMAX_B <- 60
seg_b <- cai %>%
  mutate(row = match(coverage, cov_order), y = n_cov + 1 - row) %>%
  select(coverage, row, y, n, all_of(STATUS4)) %>%
  pivot_longer(all_of(STATUS4), names_to = "status", values_to = "count") %>%
  mutate(status = factor(status, levels = STATUS4)) %>%
  arrange(row, status) %>%
  group_by(row) %>% mutate(xmax = cumsum(count), xmin = xmax - count, xmid = (xmin + xmax) / 2) %>%
  ungroup()
stopifnot(all((seg_b %>% group_by(row) %>% summarise(ok = max(xmax) == first(n)))$ok),
          max(seg_b$xmax) <= XMAX_B)
# The two plot areas are equal (patchwork default); their width follows from the figure
# width minus the absolute columns (y labels, margins). A count is printed inside a
# segment only when the segment is wide enough to hold it.
fixed_w2 <- 2 * 2 + max(label_width_mm(c(MODE_LABELS, "Total"))) + 1.5 +
            2 * 2 + max(label_width_mm(COV_LABELS)) + 1.5 + STYLE$tick_length_mm
plot_w2  <- (STYLE$fig_width_mm - fixed_w2) / 2
seg_b <- seg_b %>%
  mutate(seg_mm = count * plot_w2 / XMAX_B,
         labelled = count > 0 & seg_mm >= label_width_mm(as.character(count)) + 2 * STYLE$label_pad_mm)
drawn_b <- seg_b %>% filter(count > 0)

p2b <- ggplot(drawn_b) +
  geom_rect(aes(xmin = xmin, xmax = xmax, ymin = y - STYLE$bar_half_width, ymax = y + STYLE$bar_half_width,
                fill = status, colour = status), linewidth = STYLE$seg_outline_lwd) +
  geom_text(data = filter(drawn_b, labelled, status == "full"), aes(xmid, y, label = count),
            colour = "white", size = gsize(), family = FONT) +
  geom_text(data = filter(drawn_b, labelled, status != "full"), aes(xmid, y, label = count),
            colour = "black", size = gsize(), family = FONT) +
  x_title_below("Datasets (n)") +
  scale_fill_manual(values = STYLE$status_fill, labels = STYLE$status_label, limits = STATUS4, name = NULL) +
  scale_colour_manual(values = STYLE$status_line, labels = STYLE$status_label, limits = STATUS4, name = NULL) +
  scale_x_continuous(limits = c(0, XMAX_B), breaks = seq(0, XMAX_B, 10), expand = c(0, 0)) +
  scale_y_continuous(breaks = n_cov:1, labels = unname(COV_LABELS),
                     limits = c(0.4, n_cov + 0.6), expand = c(0, 0)) +
  labs(x = NULL, y = NULL) +
  coord_cartesian(clip = "off") +
  theme_pub() + theme_legend_strip()

for (i in seq_len(nrow(seg_b)))
  add_check("fig2", "b", seg_b$coverage[i], as.character(seg_b$status[i]), seg_b$count[i],
            if (seg_b$count[i] == 0) "zero segment, nothing drawn"
            else if (seg_b$labelled[i]) "segment length and printed count"
            else sprintf("segment length only; count not printed (segment %.1f mm wide)", seg_b$seg_mm[i]))

# ---- assemble --------------------------------------------------------------
fig2 <- wrap_plots(p2a, p2b, ncol = 2) + plot_annotation(tag_levels = "a", theme = no_outer_margin) & tag_theme
fx2 <- fixed_mm(patchwork::patchworkGrob(fig2))
panel_w2 <- (STYLE$fig_width_mm - fx2[["width"]]) / 2
H2 <- ceiling(fx2[["height"]] + panel_w2)
save_png(file.path(OUT_DIR, "fig2_sampling_coverage.png"), fig2, H2)
cat(sprintf("Fig 2: %d x %d mm; plot areas %.1f x %.1f mm; fixed rows %.1f mm\n",
            STYLE$fig_width_mm, H2, panel_w2, H2 - fx2[["height"]], fx2[["height"]]))
cat("Fig 2b counts not printed (segment too narrow): ",
    paste(sprintf("%s / %s = %d", seg_b$coverage, seg_b$status, seg_b$count)[seg_b$count > 0 & !seg_b$labelled],
          collapse = "; "), "\n")

# ===========================================================================
# 4. Figure 3 -- reporting completeness
# ===========================================================================
stopifnot(nrow(rc) == length(FIELD_LABELS), setequal(rc$field, names(FIELD_LABELS)),
          all(rc$full + rc$partial + rc$absent == rc$applicable),
          all(rc$full + rc$partial == rc$at_least_partial))
n_field <- length(FIELD_LABELS)
seg3 <- rc %>%
  mutate(row = match(field, names(FIELD_LABELS)), y = n_field + 1 - row) %>%
  select(field, row, y, applicable, all_of(STATUS3)) %>%
  pivot_longer(all_of(STATUS3), names_to = "status", values_to = "count") %>%
  mutate(status = factor(status, levels = STATUS3), share = 100 * count / applicable) %>%
  arrange(row, status) %>%
  group_by(row) %>% mutate(xmax = cumsum(share), xmin = xmax - share, xmid = (xmin + xmax) / 2) %>%
  ungroup() %>%
  mutate(labelled = count > 0 & share >= STYLE$min_label_share)
drawn_3 <- seg3 %>% filter(count > 0)

p3a <- ggplot(drawn_3) +
  geom_rect(aes(xmin = xmin, xmax = xmax, ymin = y - STYLE$bar_half_width, ymax = y + STYLE$bar_half_width,
                fill = status, colour = status), linewidth = STYLE$seg_outline_lwd) +
  geom_text(data = filter(drawn_3, labelled, status == "full"), aes(xmid, y, label = count),
            colour = "white", size = gsize(), family = FONT) +
  geom_text(data = filter(drawn_3, labelled, status != "full"), aes(xmid, y, label = count),
            colour = "black", size = gsize(), family = FONT) +
  x_title_below("Applicable datasets (%)") +
  scale_fill_manual(values = STYLE$status_fill[STATUS3], labels = STYLE$status_label[STATUS3],
                    limits = STATUS3, name = NULL) +
  scale_colour_manual(values = STYLE$status_line[STATUS3], labels = STYLE$status_label[STATUS3],
                      limits = STATUS3, name = NULL) +
  scale_x_continuous(limits = c(0, 100), breaks = seq(0, 100, 25), expand = c(0, 0)) +
  scale_y_continuous(breaks = n_field:1, labels = unname(FIELD_LABELS),
                     limits = c(0.4, n_field + 0.6), expand = c(0, 0)) +
  labs(x = NULL, y = NULL) +
  coord_cartesian(clip = "off") +
  theme_pub() + theme_legend_strip()

for (i in seq_len(nrow(seg3)))
  add_check("fig3", "a", seg3$field[i], as.character(seg3$status[i]), seg3$count[i],
            sprintf("%s %% of %d applicable; count %s", fmt1(seg3$share[i]), seg3$applicable[i],
                    if (seg3$labelled[i]) "printed" else "not printed (segment under 5 %)"))

# ---- panel b: joint reporting by purpose group -----------------------------
jm <- js %>%
  filter(group %in% names(GROUP_LABELS), pair %in% names(PAIR_LABELS)) %>%
  transmute(group, pair, both_full, applicable, pct = 100 * both_full / applicable,
            pct_src = both_full_percent, label = sprintf("%d/%d", both_full, applicable))
stopifnot(nrow(jm) == length(GROUP_LABELS) * length(PAIR_LABELS), all(abs(jm$pct - jm$pct_src) < 0.1))
VMAX3 <- 100
stopifnot(max(jm$pct) <= VMAX3)
jm <- jm %>% mutate(group = factor(group, levels = rev(names(GROUP_LABELS))),
                    pair  = factor(pair,  levels = names(PAIR_LABELS)),
                    txt   = cell_text_colour(pct, VMAX3))

p3b <- ggplot(jm, aes(pair, group)) +
  geom_tile(aes(fill = pct), colour = STYLE$tile_border, linewidth = STYLE$tile_border_lwd) +
  geom_text(aes(label = label, colour = txt), size = gsize(), family = FONT) +
  scale_colour_identity() +
  scale_fill_seq(VMAX3, "Both fully reported (%)", seq(0, VMAX3, 25), guide_seq_bar(30)) +
  scale_x_discrete(labels = PAIR_LABELS) +
  scale_y_discrete(labels = GROUP_LABELS) +
  labs(x = NULL, y = NULL) +
  coord_cartesian(expand = FALSE, clip = "off") +
  theme_tile() + theme_legend_strip()

for (i in seq_len(nrow(jm)))
  add_check("fig3", "b", as.character(jm$group[i]), as.character(jm$pair[i]), jm$label[i],
            sprintf("fill = %s %% (both_full / applicable)", fmt1(jm$pct[i])))

# ---- assemble --------------------------------------------------------------
fig3 <- wrap_plots(p3a, p3b, ncol = 2) + plot_annotation(tag_levels = "a", theme = no_outer_margin) & tag_theme
fx3 <- fixed_mm(patchwork::patchworkGrob(fig3))
panel_w3 <- (STYLE$fig_width_mm - fx3[["width"]]) / 2
H3 <- ceiling(fx3[["height"]] + panel_w3)
save_png(file.path(OUT_DIR, "fig3_reporting_completeness.png"), fig3, H3)
cat(sprintf("Fig 3: %d x %d mm; plot areas %.1f x %.1f mm; fixed rows %.1f mm\n",
            STYLE$fig_width_mm, H3, panel_w3, H3 - fx3[["height"]], fx3[["height"]]))

# ===========================================================================
# 5. Figure 4 -- method x purpose matrix
# ===========================================================================
m_tot <- with(filter(rf, family == "method"),  setNames(n, category))
u_tot <- with(filter(rf, family == "purpose"), setNames(n, category))
stopifnot(all(names(METHOD_BASE) %in% names(m_tot)), all(names(PURPOSE_BASE) %in% names(u_tot)))
long4 <- mpm %>%
  pivot_longer(-method, names_to = "purpose", values_to = "count") %>%
  mutate(purpose_total = unname(u_tot[purpose]),
         pct    = 100 * count / purpose_total,
         dagger = paste(method, purpose) %in% DAGGER_CELLS,
         label  = ifelse(dagger, paste0(count, "†"), as.character(count)),
         txt    = cell_text_colour(pct, 100))
stopifnot(nrow(long4) == length(METHOD_BASE) * length(PURPOSE_BASE),
          setequal(long4$method, names(METHOD_BASE)), setequal(long4$purpose, names(PURPOSE_BASE)),
          all(long4$count <= long4$purpose_total), sum(long4$dagger) == length(DAGGER_CELLS))
METHOD_LABELS  <- setNames(sprintf("%s (%d)", METHOD_BASE,  m_tot[names(METHOD_BASE)]),  names(METHOD_BASE))
PURPOSE_LABELS <- setNames(sprintf("%s (%d)", PURPOSE_BASE, u_tot[names(PURPOSE_BASE)]), names(PURPOSE_BASE))
long4 <- long4 %>% mutate(method  = factor(method,  levels = rev(names(METHOD_BASE))),
                          purpose = factor(purpose, levels = names(PURPOSE_BASE)))

p4 <- ggplot(long4, aes(purpose, method)) +
  geom_tile(aes(fill = pct), colour = STYLE$tile_border, linewidth = STYLE$tile_border_lwd) +
  geom_text(aes(label = label, colour = txt), size = gsize(), family = FONT) +
  scale_colour_identity() +
  scale_fill_seq(100, "Share of datasets with that purpose (%)", seq(0, 100, 25), guide_seq_bar(45)) +
  scale_x_discrete(position = "top", labels = PURPOSE_LABELS) +
  scale_y_discrete(labels = METHOD_LABELS) +
  labs(x = NULL, y = NULL) +
  coord_cartesian(expand = FALSE, clip = "off") +
  theme_tile() +
  theme(legend.position = "bottom", legend.box.spacing = unit(3, "mm"),
        legend.margin = margin(0, 0, 0, 0))

for (i in seq_len(nrow(long4)))
  add_check("fig4", "", as.character(long4$method[i]), as.character(long4$purpose[i]), long4$label[i],
            sprintf("fill = %s %% of purpose total %d%s", fmt1(long4$pct[i]), long4$purpose_total[i],
                    if (long4$dagger[i]) "; dagger marks a definition-linked pair" else ""))
for (m in names(METHOD_BASE))  add_check("fig4", "", m, "row label", m_tot[[m]], "method total in the row label")
for (u in names(PURPOSE_BASE)) add_check("fig4", "", "column label", u, u_tot[[u]], "purpose total in the column label")

fx4 <- fixed_mm(ggplotGrob(p4))
panel_w4 <- STYLE$fig_width_mm - fx4[["width"]]
panel_h4 <- min(panel_w4, STYLE$fig4_max_height_mm - fx4[["height"]])   # square when it fits the height cap
H4 <- ceiling(fx4[["height"]] + panel_h4)
save_png(file.path(OUT_DIR, "fig4_method_purpose.png"), p4, H4)
cat(sprintf("Fig 4: %d x %d mm; plot area %.1f x %.1f mm (aspect %.2f); row-label zone %.0f %% of the width\n",
            STYLE$fig_width_mm, H4, panel_w4, H4 - fx4[["height"]], (H4 - fx4[["height"]]) / panel_w4,
            100 * (fx4[["width"]] - 4) / STYLE$fig_width_mm))

# ===========================================================================
# 6. Values check file and export verification
# ===========================================================================
check <- bind_rows(check_rows)
write_csv(check, file.path(OUT_DIR, "figure_values_check.csv"))
cat(sprintf("figure_values_check.csv: %d rows\n", nrow(check)))

png_header <- function(f) {                                 # IHDR size and pHYs density without decoding the image
  con <- file(f, "rb"); on.exit(close(con))
  readBin(con, "raw", 8)
  out <- list(width = NA_integer_, height = NA_integer_, dpi = NA_real_)
  repeat {
    len <- readBin(con, "integer", 1, size = 4, endian = "big")
    if (length(len) == 0) break
    type <- rawToChar(readBin(con, "raw", 4)); data <- readBin(con, "raw", len); readBin(con, "raw", 4)
    if (type == "IHDR") {
      out$width  <- readBin(data[1:4], "integer", size = 4, endian = "big")
      out$height <- readBin(data[5:8], "integer", size = 4, endian = "big")
    }
    if (type == "pHYs" && as.integer(data[9]) == 1)
      out$dpi <- readBin(data[1:4], "integer", size = 4, endian = "big") * 0.0254
    if (type %in% c("IDAT", "IEND")) break
  }
  out
}
for (f in c("fig2_sampling_coverage.png", "fig3_reporting_completeness.png", "fig4_method_purpose.png")) {
  p <- file.path(OUT_DIR, f); h <- png_header(p)
  cat(sprintf("%-32s %5d x %5d px  %.0f dpi  %.2f MB\n", f, h$width, h$height, h$dpi, file.size(p) / 1e6))
}

# Remove the implicit device used only to measure plot layout.
if (file.exists("Rplots.pdf")) { if (dev.cur() > 1) invisible(dev.off()); unlink("Rplots.pdf") }
