"""Read the deposited workbook and write one CSV per data sheet to .cache/data/.

Run from the repository root (run_all.R does this first).
"""
from pathlib import Path
import csv
import sys

from openpyxl import load_workbook

WORKBOOK = Path("data/Nursing_unit_acoustic_measurement_scoping_review.xlsx")
SHEETS = {"reports": 91, "report_links": 92, "datasets": 87, "equivalent_level_candidates": 55, "g2_descriptors": 41}
OUT = Path(".cache/data")

if not WORKBOOK.exists():
    sys.exit(f"Missing {WORKBOOK}: download the workbook from the Zenodo record and place it in data/.")
OUT.mkdir(parents=True, exist_ok=True)
wb = load_workbook(WORKBOOK, read_only=True, data_only=True)
for sheet, expected in SHEETS.items():
    rows = [list(r) for r in wb[sheet].iter_rows(values_only=True)]
    width = len([h for h in rows[0] if h is not None])
    body = [r[:width] for r in rows[1:] if any(v is not None for v in r[:width])]
    if len(body) != expected:
        sys.exit(f"Sheet {sheet}: expected {expected} rows, found {len(body)}.")
    with (OUT / f"{sheet}.csv").open("w", newline="", encoding="utf-8") as f:
        w = csv.writer(f, lineterminator="\n")
        w.writerow(rows[0][:width])
        w.writerows([["" if v is None else v for v in r] for r in body])
print("Workbook read:", ", ".join(f"{k} {v}" for k, v in SHEETS.items()))
