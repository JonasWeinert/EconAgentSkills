---
name: stata-data-cleaning
description: >
  Generates rigorous, reproducible Stata data-cleaning workflows that follow World Bank DIME Analytics conventions (`iefieldkit`, `ietoolkit`, `iefolder` DataWork structure, `ieboilstart`, `iecodebook`, `ieduplicates`, `iecompdup`, extended missing values, master datasets, encryption for PII, dynamic absolute paths). Defaults to codebook-driven cleaning, `assert`/`isid` validation, labeled categorical variables, and reproducible from-clean-session execution.
  Use when the user asks to clean survey or administrative data in Stata, build an analysis-ready panel, handle duplicates, harmonize datasets across rounds, write a master dataset, de-identify data, label variables, or produce a codebook.
workflow_stage: data
compatibility:
  - claude-code
  - cursor
  - codex
  - gemini-cli
author: JonasWeinert
version: 2.0.0
tags:
  - stata
  - data-cleaning
  - dime
  - ietoolkit
  - iefieldkit
  - iecodebook
  - reproducibility
---

# Stata Data Cleaning

Generate rigorous, reproducible Stata data-cleaning code that follows DIME Analytics impact-evaluation conventions. The default style is `iefolder` + `iecodebook` + `ieduplicates` + extended missing values + labeled categorical variables — never hand-rolled `clear all` + `cd`.

## Operating Principles

1. **Reproducibility first.** Every cleaning script starts with `ieboilstart`, declares dynamic absolute paths via globals, and runs end-to-end from a clean Stata session. Never `cd`. Never overwrite raw data. Never commit PII to a public repo.
2. **Identify and document, then fix.** DIME's [Data Cleaning](https://dimewiki.worldbank.org/Data_Cleaning) guidance is explicit: prioritize identifying and documenting irregularities (outliers, illogical values, typos, duplicates, missing-value codes) before correcting them. Many fixes depend on the analysis design that the PI controls.
3. **Codebooks, not ad-hoc do-files.** Use `iecodebook template` and `iecodebook apply` for repetitive renames/labels/recodes. Codebooks are human-readable, machine-applicable, and easier to review than long do-file blocks.
4. **Master dataset is the single source of truth.** Time-invariant identifying information, sampling, and treatment assignment live in one master dataset per unit of observation. All other datasets link to it.
5. **Numeric, labeled, and asserted.** Categorical variables stored numerically with value labels; survey codes stored as extended missing values (`.a`, `.b`, ..., `.z`) with labels; every cleaned dataset has `isid` and `assert` checks.

## Decision Policy

This skill follows the repo-wide [Agent Policy](../../AGENT_POLICY.md). For cross-cutting data discipline (unit of analysis, ID variables, merging, master dataset, PII), this skill defers to [`working-with-data`](../working-with-data/).

**ASK before proceeding** (blocking):

1. Unit of observation and the unique identifier (single or composite).
2. Whether the file contains PII; if yes, is encryption already configured.
3. How to resolve duplicates that `ieduplicates` finds (correction, update, keep_one, drop).
4. Sample restrictions to apply; each `iedropone` is logged but the choice is the user's.
5. For multi-wave projects: harmonization strategy across rounds (variable name remapping in `iecodebook append`).

**DEFAULT + flag** (use this default; tell the user how to override):

- DataWork folder layout via `iefolder` (DIME default).
- `iecodebook` Excel-driven cleaning over hand-written rename/recode/label blocks.
- Extended missing values `.a` "Don't know", `.b` "Refuse", `.c` "Not applicable", `.n` "Skipped (logic)" with a single harmonized label set.
- `encode ..., label() noextend` for string categoricals (errors when an unexpected value appears).
- `ieboilsave` before every save; `ieboilstart 17.0` at the top of every script.

**DOCUMENT and proceed** (write into the decisions log + `documentation/cleaning_log.md`):

- Inferred unit of observation if not stated, with the assertion that confirms it.
- Each filter applied and the resulting N.
- Each value recode and which raw codes mapped where.
- Choice of which extended missing letter maps to which survey code.

`PROCEED` items: never `cd`; always reference paths as globals; raw is immutable; encrypted folder gitignored; `ieboilsave` checks before saving.

## Pre-flight Checklist

Before writing code, confirm with the user — and write the answers in the do-file header:

- **Data source.** Primary survey (CAPI export?), administrative, secondary, or API?
- **Unit of observation.** Household, individual, firm, plot, school, country-year?
- **Unique identifier.** Single ID variable (e.g. `hhid`)? Composite key (e.g. `hhid year`)?
- **Survey rounds.** Single cross-section, panel waves, or repeated cross-sections?
- **Sensitive content.** Does the raw data contain PII (names, GPS, dates of birth, contact info, photos)?
- **Cleaning goals.** Recoding, harmonization across waves, de-duplication, missing-value handling, derived variables, or all of the above?
- **Output.** Analysis-ready `.dta`, public-release de-identified `.dta`, or both?

## DIME DataWork Layout

Every cleaning script assumes a `DataWork/` folder created by `iefolder` (see [DataWork Folder](https://dimewiki.worldbank.org/DataWork_Folder)):

```
ProjectABC/
├── DataWork/
│   ├── MasterDoFile.do
│   ├── MasterData/                          # Time-invariant info, sampling, treatment
│   │   ├── master_household.dta             # de-identified
│   │   └── master_household_PII.dta         # encrypted-only
│   ├── EncryptedData/                       # Anything PII (encrypted with VeraCrypt)
│   │   ├── Baseline/
│   │   └── Endline/
│   └── Baseline/
│       ├── DataSets/
│       │   ├── Raw/                         # IMMUTABLE; never edit
│       │   ├── Intermediate/
│       │   └── Final/                       # analysis-ready, de-identified
│       ├── Dofiles/
│       │   ├── Cleaning/
│       │   ├── Construction/                # derived variables
│       │   └── Analysis/
│       ├── Output/
│       ├── Documentation/
│       └── Questionnaire/
└── README.md
```

PII rules ([DIME PII page](https://dimewiki.worldbank.org/Personally_Identifiable_Information_(PII))):

- All PII lives in `EncryptedData/`, encrypted with VeraCrypt or equivalent.
- The working dataset in `Final/` is de-identified.
- Never commit `EncryptedData/` to git (`.gitignore` it).

## Cleaning Workflow

```
1. Import raw data (CAPI exporter or read_csv) into Raw/  - IMMUTABLE
2. Validate IDs with ieduplicates / isid
3. Harmonize variables across waves with iecodebook append
4. Apply codebook (iecodebook apply): rename, label, recode, drop
5. Convert survey codes to extended missing values (.a, .b, ...)
6. Convert string categorical to numeric labeled (encode ..., label() noextend)
7. Construct derived variables in a separate construction do-file
8. Validate with assert + isid + duplicates report
9. Save Intermediate -> save Final -> save de-identified version
10. Export iecodebook to Documentation/
```

## Estimator-Free Decision Tree

### Duplicates

```
duplicates report id_var
  └── if any:
       ieduplicates id_var, ...                # creates an Excel report
       iecompdup id_var, ...                   # compare and resolve
       Document resolution in Documentation/duplicates_log.xlsx
```

### Missing Values

```
Survey codes (-99, -88, -77, -98 etc.):
  └── Replace with extended missing values:
       label define mvlbl .a "Don't know" .b "Refuse" .c "Not applicable"
       mvdecode varlist, mv(-99=.a \ -88=.b \ -77=.c)
       label values varlist mvlbl

True missingness from survey skip patterns:
  └── Use a distinct extended missing value (e.g. .n "Not asked due to skip")
       so it is distinguishable from "Don't know".

After cleaning, the Final dataset should contain no plain "." values
in cleaned variables — every missing value should explain itself.
```

### Categorical Variables

```
Numeric categorical:
  label define edu_lbl 1 "None" 2 "Primary" 3 "Secondary" 4 "Tertiary"
  label values education edu_lbl

String categorical:
  encode region_string, gen(region) label(region_lbl) noextend
  // noextend ERRORS if a new value appears that is not in the predefined label
```

### IDs

```
isid hhid                                      # cross-section
isid hhid year                                 # panel
duplicates report hhid year                    # any duplicates?
assert !missing(hhid, year)                    # IDs must be non-missing
```

### Outliers and Illogical Values

```
1. IDENTIFY before fixing (DIME guidance):
     summarize varlist, detail
     graph box varlist
     scatter varlist xvar
2. Document each anomaly in Documentation/cleaning_log.md
3. Discuss with PI which to flag vs cap vs drop
4. Apply correction in code, never by hand
5. Tag with a flag variable: gen flag_outlier_y = (y > p99 & !mi(y))
```

## Output Skeleton

```stata
*-------------------------------------------------------------*
* Project   : ProjectABC
* Purpose   : Clean baseline household survey
* Author    : First Last
* Created   : 2026-05-05
* Inputs    : ${baseline_raw}/baseline_hh.dta  (CAPI export, IMMUTABLE)
* Outputs   : ${baseline_int}/baseline_hh_clean.dta
*             ${baseline_doc}/baseline_hh_codebook.xlsx
*             ${master_data}/master_household.dta
* Estimand  : N/A (cleaning, not estimation)
* PII       : raw contains names, GPS — handled in EncryptedData/
*-------------------------------------------------------------*

* 0. Settings
ieboilstart, version(17.0)
`r(version)'

* 1. Load raw (NEVER overwrite)
use "${baseline_raw}/baseline_hh.dta", clear

* 2. ID validation
ieduplicates hhid using "${baseline_doc}/duplicates_baseline.xlsx", ///
    uniquevars(hhid) keepvars(enum_id submission_date) ///
    folder("${baseline_doc}") ///
    listofdiffs(diff_log_baseline) replace

isid hhid

* 3. Apply codebook (rename, label, recode in one shot)
iecodebook apply using "${baseline_doc}/baseline_codebook.xlsx", ///
    missingvalues(.a "Don't know" .b "Refuse" .c "Not applicable")

* 4. Survey codes to extended missing values
mvdecode age income, mv(-99=.a \ -88=.b \ -77=.c)
mvdecode age income, mv(-98=.n)             // .n = "skipped due to logic"

* 5. String to labeled numeric
encode region, gen(region_id) label(region_lbl) noextend

* 6. Validation
assert age >= 0 & age <= 120 if !missing(age)
assert inlist(female, 0, 1)               if !missing(female)
isid hhid

* 7. Save (with checks)
ieboilsave, ///
    idvars(hhid) ///
    versionvar(version_var)             // adds version comment
save "${baseline_int}/baseline_hh_clean.dta", replace

* 8. Export codebook for documentation
iecodebook export using "${baseline_doc}/baseline_hh_codebook.xlsx", replace
```

## Common Pitfalls

- Hardcoded paths and `cd` — break collaboration; use globals defined in `MasterDoFile.do`.
- Editing raw data — `Raw/` is immutable; create `Intermediate/` outputs.
- Plain `.` for everything missing — kills downstream interpretation; use extended missing values with labels.
- `encode` without `label() noextend` — silently rebases codes when new values appear; always pre-define the label.
- Dropping rows without `iedropone` — silent drops break replication; `iedropone` errors if the count is unexpected.
- Committing `EncryptedData/` or files containing names, GPS, contact info to git.
- Long ad-hoc rename/label/recode blocks — replace with `iecodebook apply` driven by an Excel codebook.
- Saving over the master dataset from a cleaning script — master is updated through a controlled process.

## Additional Resources

- `reference.md` — extended code patterns, codebook recipes, harmonization, and master-dataset workflow.
- `examples/` — runnable do-files:
  - `examples/master_cleaning.do` — entry point that routes to all cleaning steps
  - `examples/clean_with_iecodebook.do` — codebook-driven cleaning
  - `examples/duplicates_workflow.do` — `ieduplicates` + `iecompdup`
  - `examples/missing_values_extended.do` — extended missing values for survey codes
  - `examples/harmonize_waves_iecodebook.do` — `iecodebook append` across rounds
  - `examples/master_dataset.do` — building and updating a master dataset
  - `examples/deidentify_for_release.do` — strip PII for public release

## Requirements

- Stata >= 16.
- DIME packages: `iefieldkit` (provides `iecodebook`, `ieduplicates`, `iecompdup`, `ietestform`), `ietoolkit` (provides `iefolder`, `ieboilstart`, `ieboilsave`, `iedropone`).
- Optional helpers: `mdesc`, `unique`, `labutil`, `fre`, `winsor2`, `quantiles` (for cross-checks).

```stata
ssc install iefieldkit, replace
ssc install ietoolkit,  replace
ssc install mdesc,      replace
ssc install unique,     replace
ssc install labutil,    replace
ssc install fre,        replace
ssc install winsor2,    replace
```

## References

### DIME Conventions

- DIME Analytics, [Data Cleaning](https://dimewiki.worldbank.org/Data_Cleaning)
- DIME Analytics, [DataWork Folder](https://dimewiki.worldbank.org/DataWork_Folder)
- DIME Analytics, [Master Do-files](https://dimewiki.worldbank.org/Master_Do-files)
- DIME Analytics, [iecodebook](https://dimewiki.worldbank.org/Iecodebook)
- DIME Analytics, [ietoolkit](https://dimewiki.worldbank.org/ietoolkit)
- DIME Analytics, [iefieldkit](https://dimewiki.worldbank.org/Iefieldkit)
- DIME Analytics, [Personally Identifiable Information (PII)](https://dimewiki.worldbank.org/Personally_Identifiable_Information_(PII))
- DIME Analytics, [ID Variable Properties](https://dimewiki.worldbank.org/ID_Variable_Properties)
- DIME Analytics, [Reproducible Research](https://dimewiki.worldbank.org/Reproducible_Research)
- *Development Research in Practice* (DIME Analytics handbook).

### Style References

- Gentzkow & Shapiro (2014). *Code and Data for the Social Sciences*.
- IPA, *Reproducible Research: Best Practices for Data and Code Management*.
