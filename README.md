# Acoustic measurement in hospital nursing-unit studies

Code for data analysis for the paper **A scoping review of acoustic measurement, research purposes and comparability in hospital nursing-unit studies since 2022**, by Weihang Wang, Xinhao Yang, Yunting Cui and Yuan Zhang.

## Requirements

The release was checked with R 4.5.3 and Python 3.13.7 on macOS. Required R packages are `ggplot2` (4.0.2), `patchwork` (1.3.2), `dplyr` (1.2.0), `tidyr` (1.3.2), `readr` (2.2.0), `scales` (1.4.0), `ragg` (1.5.2) and `systemfonts` (1.3.2). Python requires `openpyxl` (3.1.5) and `pandas` (2.3.2). Figure typography uses Helvetica; font substitution on another operating system can affect appearance.

```r
install.packages(c("ggplot2", "patchwork", "dplyr", "tidyr", "readr", "scales", "ragg", "systemfonts"))
```

Install the Python packages with `python -m pip install openpyxl pandas`.

## File structure

- `run_all.R` runs the complete reproduction from the deposited workbook.
- `code/load_data.py` reads the workbook and writes one disposable CSV per data sheet.
- `code/descriptive.py` counts datasets by setting, design, methodological pathway, research purpose, result dimension, parameter reporting status and comparability descriptor.
- `code/analysis_01_joint_reporting.R`, `code/analysis_02_sampling_coverage.R` and `code/analysis_03_within_setting.R` produce the paired-parameter, sampling-coverage and within-setting counts; `code/helpers.R` holds their shared inputs.
- `code/validate.R` recounts those tables independently and checks the headline counts stated in the paper.
- `code/tables_si.py` writes the row fragments of Supplementary Tables S1 to S12 for inclusion in a LaTeX document.
- `code/figures.R` draws Figures 2 to 4 and lists every plotted value in `figure_values_check.csv`.
- `data/` holds the downloaded workbook, which is not duplicated in this repository.
- `output/` receives three figures, the supplementary table fragments and the count tables behind them. Figure 1 and main-text Tables 1 and 2 are descriptive displays written in the manuscript; their counts are in `output/numbers/` and in the workbook's `selection_flow` sheet.
- `.cache/` holds the CSV copies of the workbook sheets and run logs; it can be deleted and regenerated.

## Usage

1. Download `Nursing_unit_acoustic_measurement_scoping_review.xlsx` from [Zenodo](https://doi.org/10.5281/zenodo.24135850) and place it in `data/`. The record opens when the paper is accepted; during peer review the manuscript gives reviewers a private link to the same file.
2. Open a terminal in the repository root and run:

```sh
Rscript run_all.R
```

If Python is not available as `python3`, set the `PYTHON` environment variable to your environment's Python executable before running. The run takes under a minute. It stops on a failed step and reports the relevant log. Outputs are overwritten when rerun.

The workbook contains 91 reports, 87 linked acoustic datasets and 92 report–dataset links, the 55 datasets with an explicit equivalent sound-level metric, descriptors of the 41 conditionally comparable datasets, selection-flow counts and dictionaries. The analysis is descriptive: no sound levels are pooled and no inferential tests are run. The deposited workbook is the complete data input; no source-study PDFs or licensed database exports are needed.

## Licence

Code is released under the [MIT Licence](LICENSE). The dataset is separately released on Zenodo under CC BY 4.0.
