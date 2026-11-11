"""Descriptive counts for the 87 linked acoustic datasets.

Reads the CSV copies of the workbook sheets in .cache/data/ and writes the count
tables to output/numbers/. No sound levels are pooled and no inferential tests are run.
Run from the repository root (run_all.R does this after load_data.py).
"""
from pathlib import Path
from itertools import combinations
import pandas as pd

C = Path(".cache/data")
O = Path("output/numbers")
O.mkdir(parents=True, exist_ok=True)

d = pd.read_csv(C / "datasets.csv").set_index("dataset_id")
n = len(d)
d["U-X"] = 0    # reserved purpose code with no assignments
assert n == 87 and d.index.is_unique
assert d.comparability_group.value_counts().to_dict() == {"G2": 41, "Not a candidate": 32, "G3": 11, "G1": 3}
links = pd.read_csv(C / "report_links.csv")
assert len(links) == 92 and links.report_id.nunique() == 91 and set(links.dataset_id) == set(d.index)
assert sorted(links.groupby("dataset_id").size().value_counts().items()) == [(1, 82), (2, 5)]
M = [f"MP{i}" for i in range(1, 8)]
U = ["U-" + c for c in "ABCDEFGH"]
D = [f"D{i}" for i in range(1, 7)]
for c in M + U + D:                       # "Indeterminate" pathway cells become missing
    d[c] = pd.to_numeric(d[c], errors="coerce")
assert d.MP1.isna().sum() == 3 and d.MP2.isna().sum() == 3
fields = ["instrument_class", "calibration", "frequency_weighting", "measurement_height", "logging_interval", "integration_window"]


def write(name, rows):
    z = rows if isinstance(rows, pd.DataFrame) else pd.DataFrame(rows)
    z.to_csv(O / (name + ".csv"), index=False)
    return z


def app(col):
    return d[col] != "Not applicable"


write("analysis_records", d.reset_index())
freq = []
for family, col in [("year", "publication_year"), ("unit", "unit_type"), ("design", "study_design"), ("country", "country")]:
    for c, k in d[col].value_counts().sort_index().items():
        freq.append(dict(family=family, category=str(int(c)) if family == "year" else c, n=int(k), denominator=n, percent=round(k / n * 100, 1)))
for family, codes in [("method", M), ("purpose", U + ["U-X"]), ("dimension", D)]:
    for c in codes:
        k = int((d[c] == 1).sum())
        freq.append(dict(family=family, category=c, n=k, denominator=n, percent=round(k / n * 100, 1)))
write("reproduced_frequencies", freq)
mat = pd.DataFrame([[int(((d[m] == 1) & (d[u] == 1)).sum()) for u in U] for m in M], index=M, columns=U)
write("method_purpose_matrix", mat.reset_index(names="method"))

report = []
sub = []
for field in fields:
    mask = app(field)
    den = int(mask.sum())
    full = int((d[field] == "Full").sum())
    partial = int((d[field] == "Partial").sum())
    absent = int((d[field] == "Absent").sum())
    assert full + partial + absent == den
    report.append(dict(field=field, applicable=den, full=full, partial=partial, absent=absent, at_least_partial=full + partial, percent=round((full + partial) / den * 100, 1)))
    for typ, groups in [("setting", [(u, d.unit_type == u) for u in d.unit_type.unique()]), ("purpose", [(u, d[u] == 1) for u in U])]:
        for name, g in groups:
            a = g & mask
            den2 = int(a.sum())
            ab = int((a & (d[field] == "Absent")).sum())
            sub.append(dict(group_type=typ, group=name, group_n=int(g.sum()), field=field, applicable=den2,
                            full=int((a & (d[field] == "Full")).sum()), partial=int((a & (d[field] == "Partial")).sum()),
                            absent=ab, percent_absent=round(ab / den2 * 100, 1) if den2 else None))
write("reporting_completeness", report)
write("reporting_by_setting_and_purpose", sub)

setting = []
for unit, ss in d.groupby("unit_type"):
    row = dict(setting=unit, n=len(ss), candidates=int((ss.comparability_group != "Not a candidate").sum()))
    row.update({c: int((ss[c] == 1).sum()) for c in M + U + D})
    row.update({g: int((ss.comparability_group == g).sum()) for g in ["G1", "G2", "G3"]})
    setting.append(row)
write("coverage_by_setting", setting)

f = pd.read_csv(C / "g2_descriptors.csv").set_index("dataset_id")
assert set(f.index) == set(d.index[d.comparability_group == "G2"])
f["frequency_incomplete"] = (f.frequency_absent | f.frequency_partial).astype(int)
f["integration_incomplete"] = (f.integration_absent | f.integration_partial).astype(int)
features = ["frequency_incomplete", "integration_incomplete", "clock_boundary", "heterogeneous_space", "incubator_room",
            "special_operation", "intervention_change", "aggregation_limit", "acoustic_sample_unit"]
assert ((f == 0) | (f == 1)).all().all()
assert (f[features].sum(axis=1) > 0).all()
write("g2_flags_by_dataset", f.reset_index())
write("g2_flag_frequencies", [dict(feature=c, n=int(f[c].sum()), denominator=len(f), percent=round(f[c].mean() * 100, 1), dataset_ids=";".join(f.index[f[c] == 1])) for c in features])
write("g2_flag_pairs", pd.DataFrame([dict(feature_a=a, feature_b=b, n=int(((f[a] == 1) & (f[b] == 1)).sum()), denominator=len(f), dataset_ids=";".join(f.index[(f[a] == 1) & (f[b] == 1)])) for a, b in combinations(features, 2)]).sort_values(["n", "feature_a", "feature_b"], ascending=[False, True, True]))
write("g2_characteristic_counts", f[features].sum(axis=1).value_counts().sort_index().rename_axis("distinct_characteristics").reset_index(name="datasets"))

audit = []
for label, mask in [("U-D with MP3 or MP4", (d["U-D"] == 1) & ((d.MP3 == 1) | (d.MP4 == 1))),
                    ("U-D without MP3/MP4", (d["U-D"] == 1) & ~((d.MP3 == 1) | (d.MP4 == 1))),
                    ("MP3/MP4 without U-D", ((d.MP3 == 1) | (d.MP4 == 1)) & (d["U-D"] != 1)),
                    ("U-D without D6", (d["U-D"] == 1) & (d.D6 != 1)),
                    ("D6 without U-D", (d.D6 == 1) & (d["U-D"] != 1)),
                    ("MP7 and D5", (d.MP7 == 1) & (d.D5 == 1)),
                    ("MP6 and D5", (d.MP6 == 1) & (d.D5 == 1))]:
    audit.append(dict(comparison=label, n=int(mask.sum()), dataset_ids=";".join(d.index[mask])))
write("method_purpose_dimension_boundaries", audit)
write("dimension_cooccurrence", [dict(label=label, n=int(mask.sum())) for label, mask in [
    ("D1 and D3", (d.D1 == 1) & (d.D3 == 1)), ("D2 and D3", (d.D2 == 1) & (d.D3 == 1)),
    ("D4 and D5", (d.D4 == 1) & (d.D5 == 1)), ("All six dimensions", d[D].sum(axis=1) == 6)]])
write("method_coverage_within_purpose", [dict(method=m, purpose=u, n=int(mat.loc[m, u]), denominator=int((d[u] == 1).sum()),
                                              percent=round(mat.loc[m, u] / (d[u] == 1).sum() * 100, 1),
                                              interpretation="Definition-linked" if m == "MP5" and u in ["U-F", "U-G"] else "Descriptive coverage")
                                         for m in M for u in U])

cand = pd.read_csv(C / "equivalent_level_candidates.csv")
g3 = cand.loc[cand.comparability_group == "G3", ["dataset_id", "g3_primary_reason"]]
assert set(g3.dataset_id) == set(d.index[d.comparability_group == "G3"]) and g3.g3_primary_reason.notna().all()
write("g3_primary_reasons", g3.groupby("g3_primary_reason").size().sort_values(ascending=False).rename_axis("reason").reset_index(name="datasets"))
print(pd.DataFrame(report).to_string(index=False))
