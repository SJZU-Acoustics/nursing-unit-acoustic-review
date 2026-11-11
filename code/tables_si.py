#!/usr/bin/env python3
"""Build the Supplementary Information table fragments for the nursing-unit scoping review.

Run from the repository root (run_all.R does this after the analyses):
    python3 code/tables_si.py

Outputs (row-only LaTeX fragments, no float, no caption; the SI file owns captions):
    output/tables/si/si_prisma_scr.tex          Table S1
    output/tables/si/si_eligibility.tex         Table S2
    output/tables/si/si_linkage.tex             Table S3
    output/tables/si/si_coding_definitions.tex  Table S4
    output/tables/si/si_sampling_rows.tex       Table S5
    output/tables/si/si_characteristics.tex     Table S6
    output/tables/si/si_reporting.tex           Table S7
    output/tables/si/si_method_purpose.tex      Table S8
    output/tables/si/si_within_setting.tex      Table S9
    output/tables/si/si_dimensions.tex          Table S10
    output/tables/si/si_candidates.tex          Table S11
    output/tables/si/si_g2_descriptors.tex      Table S12
    output/tables/si/si_g2_pairs.tex            paragraph below Table S12
    output/tables/si/si_build_check.json        counts written

Sources: the workbook sheets in .cache/data/ and the count tables in output/numbers/.
Tables S1, S2 and S4 are descriptive text tables with no computed content.
"""
import csv
import json
import pathlib


DATA = pathlib.Path(".cache/data")
NUM = pathlib.Path("output/numbers")
OUT = pathlib.Path("output/tables/si")
OUT.mkdir(parents=True, exist_ok=True)
CHECK = {}


def esc(s):
    s = "" if s is None else str(s)
    out = (s.replace("\\", r"\textbackslash{}").replace("&", r"\&").replace("%", r"\%")
            .replace("_", r"\_").replace("#", r"\#").replace("$", r"\$")
            .replace("–", "--").replace("—", "---").replace("−", "$-$")
            .replace("‐", "-").replace("’", "'")
            .replace("×", r"$\times$").replace("±", r"$\pm$").replace("μ", r"$\mu$")
            .replace("≥", r"$\geq$").replace("≤", r"$\leq$").replace("′", r"$'$"))
    for ch, repl in (
        ("á", r"{\'a}"), ("é", r"{\'e}"), ("í", r"{\'\i}"), ("ó", r"{\'o}"),
        ("ñ", r"{\~n}"), ("ö", r"{\"o}"), ("ä", r"{\"a}"), ("ü", r"{\"u}"),
        ("ć", r"{\'c}"), ("Ö", r"{\"O}"), ("ğ", r"{\u{g}}"), ("ç", r"{\c{c}}"),
    ):
        out = out.replace(ch, repl)
    return out


def row(cells):
    return " & ".join(cells) + r" \\"


def group(label, ncol):
    return r"\multicolumn{%d}{@{}l}{\textbf{%s}} \\" % (ncol, label)


def write(name, lines):
    (OUT / name).write_text("\n".join(lines) + "\n", encoding="utf-8")
    CHECK[name] = len([l for l in lines if l.endswith(r"\\") and not l.startswith(r"\multicolumn") and not l.startswith(r"\addlinespace")])


def read_csv(path):
    with open(path, newline="", encoding="utf-8") as f:
        return list(csv.DictReader(f))


def pct(n, d):
    return f"{100.0 * n / d:.1f}"


# --------------------------------------------------------------------------- Table S1 PRISMA-ScR
PRISMA = [
    ("Title", "1", "Identify the report as a scoping review", "Title"),
    ("Abstract", "2", "Structured summary of background, objectives, eligibility, sources, charting, results and conclusions", "Abstract"),
    ("Introduction", "3", "Rationale for the review in the context of what is already known", "Section 1"),
    ("", "4", "Objectives and questions", "Section 1 (research questions RQ1--RQ3)"),
    ("Methods", "5", "Protocol and registration", "Section 4.3 (not prospectively registered)"),
    ("", "6", "Eligibility criteria", "Section 2.1; Table S2"),
    ("", "7", "Information sources", "Section 2.2; Supplementary Methods S1.1"),
    ("", "8", "Full search strategy for at least one database", "Supplementary Methods S1.1 (all four databases, verbatim)"),
    ("", "9", "Selection of sources of evidence", "Section 2.3; Figure 1"),
    ("", "10", "Data charting process", "Section 2.4"),
    ("", "11", "Data items", "Section 2.4; Table S4"),
    ("", "12", "Critical appraisal of individual sources of evidence (optional)", "Not performed (Section 2.5)"),
    ("", "13", "Synthesis of results", "Section 2.5"),
    ("Results", "14", "Selection of sources of evidence", "Section 3.1; Figure 1"),
    ("", "15", "Characteristics of sources of evidence", "Section 3.1; Tables S3 and S6"),
    ("", "16", "Critical appraisal within sources of evidence (optional)", "Not performed"),
    ("", "17", "Results of individual sources of evidence", "Sections 3.2--3.5; Tables S5, S10 and S11"),
    ("", "18", "Synthesis of results", "Sections 3.2--3.5; Figures 2--4; Table 1"),
    ("Discussion", "19", "Summary of evidence", "Section 4.1"),
    ("", "20", "Limitations", "Section 4.3"),
    ("", "21", "Conclusions", "Section 5"),
    ("Funding", "22", "Sources of funding and role of funders", "Funding statement"),
]
write("si_prisma_scr.tex", [row([esc(a), b, esc(c), esc(d)]) for a, b, c, d in PRISMA])

# --------------------------------------------------------------------------- Table S2 eligibility (PCC)
PCC = [
    ("Population", "No restriction on patients, accompanying family or caregivers, or staff; linkage with population outcomes permitted",
     "None on population grounds"),
    ("Concept", "Real-world nursing-unit environmental sound field with an extractable measurement process and acoustic results",
     "Wearable-only personal-exposure studies without a reconstructible nursing-unit sound field; stand-alone device tests; laboratory simulations"),
    ("Context", "Inpatient nursing units: patient rooms, nurses' stations, corridors and treatment or support spaces",
     "Studies outside inpatient nursing units, and mixed hospital settings in which nursing-unit results cannot be separated"),
    ("Source", "Original empirical research in peer-reviewed journals published from 1 January 2022 to 13 September 2026",
     "Reviews, editorials, conference abstracts, theses, or peer review that cannot be verified"),
    ("Source list (added 22 September 2026)", "Chinese-language reports in journals on the 2023 Guide to the Core Journals of China, the 2025 Academic Edition of the Chinese Science and Technology Core Journals, or the CSSCI 2025--2026 source list (expanded list excluded)",
     "Four reports from journals outside these lists; this journal-level criterion did not assess individual study quality"),
]
write("si_eligibility.tex", [row([esc(a), esc(b), esc(c)]) for a, b, c in PCC])

# --------------------------------------------------------------------------- Table S4 coding definitions
SD = [
    ("SD1", "Cross-sectional or single-stage observational field study", "No investigator-assigned intervention. Describes or compares the acoustic environment, or concurrent associations, within one study stage. Repeated or multi-day sampling alone does not make a study longitudinal."),
    ("SD2", "Longitudinal, prospective cohort or follow-up study", "The same participants or unit are followed over time and subsequent change or outcomes are analysed. Longitudinality arises from follow-up logic, not sampling frequency."),
    ("SD3", "Retrospective or secondary-data observational study", "The report primarily analyses existing records, historical monitoring or parent-study data. Retrospectively constructed exposure groups remain SD3."),
    ("SD4", "Non-randomised intervention, quasi-experiment, natural experiment or quality improvement", "A prospective or concurrent non-random intervention, system change, renovation, relocation or improvement structure is central to the design."),
    ("SD5", "Randomised experimental study", "Explicit random allocation, randomised sequence, randomised crossover or cluster randomisation."),
    ("SD6", "Methodological or engineering diagnostic and validation study", "Primary objective is the development or validation of a measurement or identification tool, algorithm, model or engineering diagnosis."),
]
DD = [
    ("D1", "Temporal characteristics", "Results preserve a meaningful temporal structure, including day and night, shifts, handover, activity stages, multi-day repetition or continuous series."),
    ("D2", "Spatial characteristics", "Results preserve a spatial structure or comparison within or between nursing-unit spaces. Near-body sensors used only for personal exposure do not qualify."),
    ("D3", "Sound-level statistics and distribution", "Equivalent levels with defined windows, maxima or peaks, percentile levels, threshold-exceedance proportions or durations, or distributions."),
    ("D4", "Spectral characteristics", "Octave or one-third-octave band levels or other reported frequency-domain features."),
    ("D5", "Room-acoustic characteristics", "Reverberation time, speech transmission index, clarity, spatial decay, sound insulation or comparable building-acoustic parameters."),
    ("D6", "Sound sources and sound events", "Sources or discrete events treated as explicit analysis units with structured results. Questionnaire-only source perceptions or time above a threshold without event identification do not qualify."),
]
UU = [
    ("U-A", "Describe current acoustic conditions", "Description of the existing level, distribution or composition is itself an explicit purpose."),
    ("U-B", "Compare times or spaces", "Explicit comparison across periods or locations. Intervention-stage comparison is coded as U-E."),
    ("U-C", "Compare with standards or recommended values", "Explicit comparison with an external guideline, standard, recommendation or reference threshold."),
    ("U-D", "Identify sound sources or events", "Acoustic or event data used to identify, classify or quantify sources or events and their occurrence or contribution."),
    ("U-E", "Evaluate an intervention or design", "Acoustic data used to evaluate a management, alarm, material, spatial, architectural or other intervention or design change."),
    ("U-F", "Patient-related outcomes", "Acoustic data linked to patient-centred outcomes such as sleep, physiology, delirium, recovery or comfort."),
    ("U-G", "Staff-related outcomes", "Acoustic data linked to nurse or staff perception, annoyance, performance, stress or other staff outcomes."),
    ("U-H", "Method or tool development", "Substantial development or validation of a measurement system, algorithm, evaluation method or monitoring approach."),
    ("U-X", "Other explicit purpose", "Reserved for a distinct purpose outside U-A to U-H, and never used for missing purpose information (no assignments)."),
]
MP = [
    ("MP1", "Sound-level time-series monitoring", "Continuous or near-continuous sound-level recording at an identified point, space and window for about one hour or longer."),
    ("MP2", "Short-duration or scheduled spot measurement", "Single short measurements, scheduled or shift-timed readings, or context- or device-specific measurements. May coexist with MP1."),
    ("MP3", "Sound-source or activity logging", "A structured record of sources or activities collected alongside the acoustic data (field classification, alarm or clinical logs)."),
    ("MP4", "Audio, video or signal identification", "Recordings or signal processing used to identify or classify acoustic events beyond aggregate level reporting."),
    ("MP5", "Linkage with subjective or clinical outcomes", "Acoustic measurements analysed alongside or linked to subjective, behavioural or clinical outcome data."),
    ("MP6", "Intervention or design comparison", "Acoustic results compared across an intervention, crossover, facility or design change, or before-and-after condition."),
    ("MP7", "Targeted acoustic testing", "Specialised measurement beyond broadband level monitoring, covering spectra, room acoustics, sound insulation or speech transmission."),
]
GG = [
    ("G1", "Directly groupable", "Nursing-unit type, core metric, weighting, time scale, spatial target, operating state and statistical meaning are specified sufficiently to permit direct matching; a counterpart in the corpus is not required. Matching study-level values are shown together and described by their range, and an unmatched result is reported individually."),
    ("G2", "Conditionally comparable", "The metric, measurement location, analysis period and reported summary are identifiable, but a difference in measurement conditions or missing comparison-critical detail on weighting, integration window, period boundaries or aggregation prevents direct matching. Numerical results are presented with these conditions, and no common centre is estimated."),
    ("G3", "Stand-alone description", "No identifiable, separable equivalent-level result is available for numerical comparison, or its physical, temporal or spatial meaning cannot be established. Retain in the evidence map."),
]
REP = [
    ("Full", "Reporting status", "The field is reported completely for all relevant metrics in the dataset."),
    ("Partial", "Reporting status", "The field is reported for some metrics or incompletely."),
    ("Absent", "Reporting status", "The field is not reported. This status does not imply that the procedure was omitted."),
    ("Not applicable", "Reporting status", "A known different metric makes this field inapplicable. An undefined equivalent metric is recorded separately as unassessable. Both are outside the integration-window denominator."),
]
SAMP = [
    ("C", "Recording mode: continuous within sessions", "Continuous or automatic recording within sessions, without requiring full-day coverage. A continuous series plus supplementary scheduled short or spot measurements, triggered audio, source measurements or controlled tests remains C."),
    ("S", "Recording mode: scheduled short or spot samples", "Scheduled sessions of up to 30 minutes or intermittent point readings. The 30-minute boundary is an operational description."),
    ("E", "Recording mode: event or scenario selected", "Scenario-selected or threshold-gated recording without a continuous ambient series."),
    ("T", "Recording mode: controlled tests only", "Controlled or unoccupied tests without ambient monitoring."),
    ("U", "Recording mode: unclear", "Acquisition continuity insufficiently described."),
    ("F", "Clock coverage: full day--night cycle described", "A 24-hour session, an extended deployment or a sampling schedule distributed across the whole day--night cycle is described. This code records deployment coverage, whereas effective valid-data coverage and excluded periods are separate."),
    ("W", "Clock coverage: day and night windows, full cycle not established", "Day and night windows documented without an established full cycle."),
    ("D", "Clock coverage: daytime or evening only", "Recording restricted to daytime or evening."),
    ("N", "Clock coverage: overnight only", "Recording restricted to the night."),
    ("U", "Clock coverage: unclear", "Clock coverage not specified."),
    ("A", "Clock coverage: not applicable", "Ambient clock coverage inapplicable to pre-occupancy controlled tests."),
    ("P / S / X", "Documented locations", "Patient-care area or unit environment (P), staff work area (S) and incubator-related microenvironment (X). Flags overlap and describe meter locations, not populations."),
    ("Controlled", "Controlled-test component", "An explicitly described controlled or unoccupied-room acoustic test, whether stand-alone or conducted alongside other evidence."),
]
UU = [(a, b, c + " This code includes measured comparisons and design evaluations based on measurements or calculations, whereas MP6 requires a measured comparison." if a == "U-E" else c) for a, b, c in UU]
REP.append(("Unassessable metric", "Metric applicability", "An equivalent-level metric cannot be confirmed from the reported definition. Its integration window is not counted as absent. Other applicable parameter fields retain their own denominators."))
lines = [group("Primary study design (one code per dataset)", 3)]
lines += [row([esc(a), esc(b), esc(c)]) for a, b, c in SD]
lines += [r"\addlinespace", group("Acoustic-environment result dimensions (multiple codes)", 3)]
lines += [row([esc(a), esc(b), esc(c)]) for a, b, c in DD]
lines += [r"\addlinespace", group("Research purposes (multiple codes)", 3)]
lines += [row([esc(a), esc(b), esc(c)]) for a, b, c in UU]
lines += [r"\addlinespace", group("Methodological pathways (multiple codes)", 3)]
lines += [row([esc(a), esc(b), esc(c)]) for a, b, c in MP]
lines += [r"\addlinespace", group("Reporting status of measurement parameters", 3)]
lines += [row([esc(a), esc(b), esc(c)]) for a, b, c in REP]
lines += [r"\addlinespace", group("Comparability of equivalent sound-level results (55 candidates, one code each)", 3)]
lines += [row([esc(a), esc(b), esc(c)]) for a, b, c in GG]
lines += [r"\addlinespace", group("Sampling descriptions coded from the extracted fields", 3)]
lines += [row([esc(a), esc(b), esc(c)]) for a, b, c in SAMP]
write("si_coding_definitions.tex", lines)

# --------------------------------------------------------------------------- Table S5 sampling rows
cw = read_csv(NUM / "sampling_coding.csv")
assert len(cw) == 87, len(cw)
lines = []
for r in cw:
    flags = "".join(["P" if r["patient_area"] == "TRUE" else "--",
                     " S" if r["staff_area"] == "TRUE" else "",
                     " X" if r["microenvironment"] == "TRUE" else ""])
    lines.append(row([esc(r["dataset_id"]), r["mode"], r["coverage"], flags.strip(),
                      "yes" if r["controlled"] == "1" else "", esc(r["note"])]))
write("si_sampling_rows.tex", lines)
CHECK["sampling_mode_counts"] = {m: sum(1 for r in cw if r["mode"] == m) for m in "CSETU"}
CHECK["sampling_coverage_counts"] = {m: sum(1 for r in cw if r["coverage"] == m) for m in "FWDNUA"}

# --------------------------------------------------------------------------- Table S6 characteristics
freq = read_csv(NUM / "reproduced_frequencies.csv")
countries = sorted([(r["category"], int(r["n"])) for r in freq if r["family"] == "country"])
assert sum(n for _, n in countries) == 87 and len(countries) == 29
def fam(name):
    return [(r["category"], int(r["n"])) for r in freq if r["family"] == name]
UNIT_ORDER = ["Adult ICU", "NICU", "Adult general ward", "Mixed or multiple", "PICU"]
UNIT_LABEL = {"Mixed or multiple": "Mixed or multiple unit types"}
SD_LABEL = {"SD1": "SD1 Cross-sectional or single-stage field study", "SD2": "SD2 Longitudinal, cohort or follow-up study",
            "SD3": "SD3 Retrospective or secondary-data study", "SD4": "SD4 Non-randomised intervention, quasi-experiment, natural experiment or quality improvement",
            "SD5": "SD5 Randomised experimental study", "SD6": "SD6 Methodological or engineering diagnostic and validation study"}
lines = [group("Publication year", 3)]
for cat, n in fam("year"):
    lines.append(row([cat, str(n), pct(n, 87)]))
lines += [r"\addlinespace", group("Nursing-unit type", 3)]
units = dict(fam("unit"))
for u in UNIT_ORDER:
    lines.append(row([UNIT_LABEL.get(u, u), str(units[u]), pct(units[u], 87)]))
lines += [r"\addlinespace", group("Primary study design", 3)]
for cat, n in fam("design"):
    lines.append(row([esc(SD_LABEL[cat]), str(n), pct(n, 87)]))
lines += [r"\addlinespace", group("Country or region (29)", 3)]
for name, n in countries:
    lines.append(row([esc(name), str(n), pct(n, 87)]))
write("si_characteristics.tex", lines)
CHECK["year"] = dict(fam("year")); CHECK["unit"] = units; CHECK["design"] = dict(fam("design")); CHECK["countries"] = dict(countries)

# --------------------------------------------------------------------------- Table S7 reporting
rc = read_csv(NUM / "reporting_completeness.csv")
FIELD = {"instrument_class": "Instrument class", "calibration": "Calibration", "frequency_weighting": "Frequency weighting",
         "measurement_height": "Measurement height and reference", "logging_interval": "Sound-level logging interval",
         "integration_window": "Integration time window"}
lines = [group("Individual fields", 6)]
for r in rc:
    lines.append(row([FIELD[r["field"]], "All datasets", r["applicable"], r["full"], r["partial"], r["absent"]]))
time_response_reported = sum(1 for r in read_csv(NUM / "analysis_records.csv") if r["time_response"] == "Reported")
lines.append(row(["Time-response setting (explicit reports only)", "All datasets", "--", str(time_response_reported), "--", "--"]))
js = read_csv(NUM / "joint_summary.csv")
PAIR = {"weighting_integration": "Frequency weighting + integration window", "logging_integration": "Logging interval + integration window",
        "instrument_calibration": "Instrument class + calibration"}
GROUP = {"All": "All datasets", "U-A": "U-A Describe conditions", "U-B": "U-B Compare times or spaces", "U-C": "U-C Compare with standards",
         "U-D": "U-D Identify sources or events", "U-E": "U-E Intervention or design", "U-F": "U-F Patient outcomes",
         "U-G": "U-G Staff outcomes", "U-H": "U-H Method development"}
lines += [r"\addlinespace", group("Pairs of related fields by purpose group", 6)]
for g in ["All", "U-A", "U-B", "U-C", "U-D", "U-E", "U-F", "U-G", "U-H"]:
    for p in ["weighting_integration", "logging_integration", "instrument_calibration"]:
        r = next(x for x in js if x["group"] == g and x["pair"] == p)
        lines.append(row([PAIR[p], GROUP[g], r["applicable"], r["both_full"], str(int(r["both_at_least_partial"])-int(r["both_full"])), r["at_least_one_absent"]]))
write("si_reporting.tex", lines)
CHECK["joint_all"] = {r["pair"]: r["both_full"] + "/" + r["applicable"] for r in js if r["group"] == "All"}

# --------------------------------------------------------------------------- Table S9 within setting
ws = read_csv(NUM / "within_setting.csv")
assert len(ws) == 48, len(ws)
MEAS = {"integration": "Integration window", "weighting_integration": "Weighting + window", "logging_integration": "Logging + window",
        "instrument_calibration": "Instrument + calibration"}
PURP = {"All": "All", "U-E": "U-E", "U-F": "U-F", "U-G": "U-G"}
lines = []
for r in ws:
    lines.append(row([esc(r["setting"]), PURP[r["purpose"]], MEAS[r["measure"]], r["group_n"], r["applicable"], r["full"], r["partial"], r["absent"], r["not_applicable"]]))
write("si_within_setting.tex", lines)

# --------------------------------------------------------------------------- Table S8 method x purpose
mpm = read_csv(NUM / "method_purpose_matrix.csv")
mtot = dict(fam("method")); ptot = dict(fam("purpose"))
U = ["U-A", "U-B", "U-C", "U-D", "U-E", "U-F", "U-G", "U-H"]
MPL = {"MP1": "Sound-level time-series monitoring", "MP2": "Short or scheduled spot measurement", "MP3": "Sound-source or activity logging",
       "MP4": "Audio, video or signal identification", "MP5": "Linkage with subjective or clinical outcomes", "MP6": "Intervention or design comparison",
       "MP7": "Targeted acoustic testing"}
lines = []
for r in mpm:
    cells = [r["method"], esc(MPL[r["method"]]), str(mtot[r["method"]])]
    for u in U:
        v = r[u]
        if (r["method"], u) in {("MP5", "U-F"), ("MP5", "U-G")}:
            v = v + r"$^{\dagger}$"
        cells.append(v)
    lines.append(row(cells))
lines.append(r"\midrule")
lines.append(row(["", r"\textit{Datasets with the purpose}", "87"] + [str(ptot[u]) for u in U]))
# purposes by nursing-unit type (from the per-dataset analysis records)
ar = read_csv(NUM / "analysis_records.csv")
assert len(ar) == 87, len(ar)
lines.append(r"\addlinespace")
lines.append(group("Research purposes by nursing-unit type (datasets with the purpose)", 11))
for unit in UNIT_ORDER:
    sub = [r for r in ar if r["unit_type"] == unit]
    lines.append(row(["", esc(UNIT_LABEL.get(unit, unit)), str(len(sub))] + [str(sum(1 for r in sub if float(r[u]) == 1)) for u in U]))
CHECK["purpose_by_unit"] = {unit: [sum(1 for r in ar if r["unit_type"] == unit and float(r[u]) == 1) for u in U] for unit in UNIT_ORDER}
write("si_method_purpose.tex", lines)
CHECK["matrix_total_check"] = sum(int(r[u]) for r in mpm for u in U)

# --------------------------------------------------------------------------- Table S10 dimensions
DL = {"D1": "D1 Temporal characteristics", "D2": "D2 Spatial characteristics", "D3": "D3 Sound-level statistics and distribution",
      "D4": "D4 Spectral characteristics", "D5": "D5 Room-acoustic characteristics", "D6": "D6 Sound sources and events"}
lines = [group("Dimension frequencies (87 datasets, multiple codes)", 4)]
for cat, n in fam("dimension"):
    lines.append(row([DL[cat], str(n), pct(n, 87), ""]))
# unit x dimension block, in the unit order and labels of Tables S6 and S8
lines += [r"\addlinespace", group("Dimension coverage by nursing-unit type", 4)]
by_setting = {r["setting"]: r for r in read_csv(NUM / "coverage_by_setting.csv")}
assert set(by_setting) == set(UNIT_ORDER)
for unit in UNIT_ORDER:
    r = by_setting[unit]
    parts = [f"{d}: {r[d]}" for d in ["D1", "D2", "D3", "D4", "D5", "D6"]]
    lines.append(row([esc(UNIT_LABEL.get(unit, unit)), r["n"], "", esc("; ".join(parts))]))
lines += [r"\addlinespace", group("Co-occurrence of dimensions", 4)]
for item in read_csv(NUM / "dimension_cooccurrence.csv"):
    lab, n = item["label"], int(item["n"])
    lines.append(row([lab, str(n), pct(n, 87), ""]))
bd = read_csv(NUM / "method_purpose_dimension_boundaries.csv")
BDL = {"U-D with MP3 or MP4": "Purpose U-D with MP3 or MP4 (union)", "U-D without MP3/MP4": "Purpose U-D without MP3 or MP4",
       "MP3/MP4 without U-D": "MP3 or MP4 without purpose U-D", "U-D without D6": "Purpose U-D without structured source or event results (D6)",
       "D6 without U-D": "D6 results without purpose U-D", "MP7 and D5": "MP7 with room-acoustic results (D5)", "MP6 and D5": "MP6 with room-acoustic results (D5)"}
lines += [r"\addlinespace", group("Boundary cases between purpose, method and result dimension", 4)]
for r in bd:
    lines.append(row([esc(BDL[r["comparison"]]), r["n"], "", esc(r["dataset_ids"].replace(";", ", "))]))
write("si_dimensions.tex", lines)
CHECK["dimension"] = dict(fam("dimension"))

# --------------------------------------------------------------------------- Table S12 G2 descriptors
g2 = read_csv(NUM / "g2_flags_by_dataset.csv")
assert len(g2) == 41
COLS = ["frequency_absent", "frequency_partial", "integration_absent", "integration_partial", "clock_boundary", "heterogeneous_space",
        "incubator_room", "special_operation", "intervention_change", "aggregation_limit", "acoustic_sample_unit"]
lines = []
for r in g2:
    marks = [r"$\bullet$" if r[c] == "1" else "" for c in COLS]
    k = sum(1 for c in COLS if r[c] == "1")
    lines.append(row([esc(r["dataset_id"])] + marks + [str(k)]))
lines.append(r"\midrule")
tots = [str(sum(1 for r in g2 if r[c] == "1")) for c in COLS]
lines.append(row([r"\textit{Datasets with the descriptor}"] + tots + [""]))
pairs = read_csv(NUM / "g2_flag_pairs.csv")
PL = {"frequency_incomplete": "weighting incomplete", "integration_incomplete": "integration window incomplete", "clock_boundary": "clock boundary",
      "heterogeneous_space": "heterogeneous spaces", "incubator_room": "incubator and room", "special_operation": "special operation",
      "intervention_change": "intervention or change", "aggregation_limit": "aggregation or selected summary", "acoustic_sample_unit": "sample unit"}
nz = [p for p in pairs if int(p["n"]) > 0]
ge3 = [f"{PL[p['feature_a']]} with {PL[p['feature_b']]} ({p['n']})" for p in nz if int(p["n"]) >= 3]
eq2 = [f"{PL[p['feature_a']]} with {PL[p['feature_b']]}" for p in nz if int(p["n"]) == 2]
eq1 = [f"{PL[p['feature_a']]} with {PL[p['feature_b']]}" for p in nz if int(p["n"]) == 1]
def join_and(items):
    return items[0] if len(items) == 1 else ", ".join(items[:-1]) + " and " + items[-1]
pair_text = (
    r"\textbf{Co-occurring descriptor pairs.} "
    r"Counts combine absent and partial status for weighting and integration window. "
    f"The most frequent pairs were {esc(join_and(ge3[:2]))}. "
    f"Other pairs in three or more datasets were {esc(join_and(ge3[2:]))}. "
    f"Pairs in two datasets each were {esc(join_and(eq2))}. "
    f"Pairs occurring in one dataset included {esc(join_and(eq1[:4]))}. "
    f"Further single-dataset pairs were {esc(join_and(eq1[4:8]))}. "
    f"The remaining single-dataset pairs were {esc(join_and(eq1[8:]))}."
)
write("si_g2_pairs.tex", [pair_text])
write("si_g2_descriptors.tex", lines)
CHECK["g2_totals"] = dict(zip(COLS, tots))
CHECK["g2_no_descriptor"] = sum(1 for r in g2 if all(r[c] == "0" for c in COLS))

# --------------------------------------------------------------------------- Table S3 linkage
links = read_csv(DATA / "report_links.csv")
assert len(links) == 92, len(links)
bib = {r["report_id"]: r for r in read_csv(DATA / "reports.csv")}
assert len(bib) == 91, len(bib)
lines = []
for r in links:
    b = bib[r["report_id"]]
    first = b["authors"].split(";")[0].strip()
    if "," in first:
        first = first.split(",")[0].strip()
    lines.append(row([esc(r["link_id"]), esc(r["dataset_id"]), esc(r["report_id"]), r["role"], esc(first), b["year"],
                      esc(b["title"]), esc(b["journal"]), esc(b["doi"]).replace("/", "/\\allowbreak{}").replace(".", ".\\allowbreak{}")]))
write("si_linkage.tex", lines)

# --------------------------------------------------------------------------- Table S11 candidates
cr = read_csv(DATA / "equivalent_level_candidates.csv")
assert len(cr) == 55, len(cr)
brk = lambda x: esc(x).replace("/", "/\\allowbreak{}").replace(";", ";\\allowbreak{}")
lines = []
for r in cr:
    lines.append(row([esc(r["dataset_id"]).replace("\\_", "\\_\\allowbreak{}"), esc(r["unit_type"]),
                      brk(r["metrics"] + "; " + r["time_windows"]), brk(r["space"] + "; " + r["operating_state"]),
                      brk(r["aggregation"]), r["comparability_group"], brk(r["selected_result"]), brk(r["rationale"])]))
write("si_candidates.tex", lines)
CHECK["candidates_G"] = {g: sum(1 for r in cr if r["comparability_group"] == g) for g in ("G1", "G2", "G3")}

(OUT / "si_build_check.json").write_text(json.dumps(CHECK, ensure_ascii=False, indent=1), encoding="utf-8")
print(json.dumps(CHECK, ensure_ascii=False, indent=1))
