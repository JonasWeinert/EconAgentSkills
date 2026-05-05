# Stata Data Cleaning Reference

Detailed code patterns aligned with DIME Analytics data-cleaning conventions. Use these as the canonical templates when generating Stata cleaning scripts.

## 1. Boilerplate (`ieboilstart`)

Every cleaning do-file begins with:

```stata
ieboilstart, version(17.0)
`r(version)'
```

`ieboilstart` standardizes Stata version, memory settings, `more off`, `varabbrev off`, and other settings across collaborators. Use the **oldest** Stata version anyone on the team has installed.

## 2. Codebook-Driven Cleaning (`iecodebook`)

`iecodebook` lets you do most renames, recodes, and label assignments through an Excel codebook instead of long do-file blocks ([DIME wiki](https://dimewiki.worldbank.org/Iecodebook)).

### 2.1 Generate a template from the raw dataset

```stata
use "${baseline_raw}/raw_household.dta", clear
iecodebook template using "${baseline_doc}/baseline_codebook.xlsx"
```

Open the codebook in Excel:

- Fill the `name` column with the new variable name. Leave blank or use `.` to drop the variable.
- Fill the `label` column with a descriptive variable label.
- Fill `choices` with a value-label name; define the labels in the `choices` sheet.
- Fill `recode:current` with rules like `(0=1)(1=0)` to reorder values.

### 2.2 Apply the codebook

```stata
iecodebook apply using "${baseline_doc}/baseline_codebook.xlsx", ///
    missingvalues(.a "Don't know" .b "Refuse" .c "Not applicable")
```

The `missingvalues(...)` option harmonizes extended missing-value labels across the entire codebook — every cleaned variable gets the same `.a/.b/.c` definitions.

### 2.3 Export a codebook from a clean dataset

After cleaning, export a self-describing codebook:

```stata
iecodebook export using "${baseline_doc}/baseline_hh_codebook.xlsx", replace
```

## 3. Duplicates (`ieduplicates`, `iecompdup`)

```stata
ieduplicates hhid using "${baseline_doc}/duplicates_baseline.xlsx", ///
    uniquevars(hhid) ///
    keepvars(enum_id submission_date device_id) ///
    folder("${baseline_doc}") ///
    listofdiffs(diff_log_baseline) replace
```

This produces an Excel report with one row per duplicate set. The team flags each set as a `correction`, `update`, `keep_one`, or `drop`. Re-running `ieduplicates` applies the resolutions in a reproducible way.

For comparing the contents of duplicates side by side: `iecompdup`.

## 4. Extended Missing Values for Survey Codes

Stata supports `.a`-`.z` extended missing values, which behave like `.` in numeric contexts but carry value labels. Use them to preserve the meaning of survey non-responses.

```stata
* Define one global label set for all survey codes
label define mvlbl ///
    .a "Don't know"           ///
    .b "Refuse"               ///
    .c "Not applicable"       ///
    .n "Not asked (skip)"     ///
    .r "Refused at consent"

* Convert numeric survey codes to extended missing values
mvdecode income age, mv(-99=.a \ -88=.b \ -77=.c \ -98=.n)

* Apply the missing-value labels
foreach v of varlist income age {
    label values `v' mvlbl
}
```

After cleaning, the analysis-ready dataset should have **no plain `.`** in cleaned variables; every missing value should self-describe.

## 5. Categorical Variables

### 5.1 Numeric categorical with predefined value labels

```stata
label define edu_lbl 1 "None" 2 "Primary" 3 "Secondary" 4 "Tertiary"
label values education edu_lbl
label variable education "Highest level of education completed"
```

### 5.2 String categorical (use `encode ..., label() noextend`)

```stata
* 1. Pre-define the label so you control the codes
label define region_lbl 1 "North" 2 "South" 3 "East" 4 "West"

* 2. encode with noextend ERRORS if a new value appears
encode region, gen(region_id) label(region_lbl) noextend

* If encode errors, you have unexpected values — investigate before
* dropping or adding to the label.
```

`noextend` matters: without it, `encode` silently rebases codes to alphabetical order, which breaks every downstream interpretation.

## 6. Validation (`assert`, `isid`, `iedropone`)

```stata
* Unique identifier
isid hhid                            // cross-section
isid hhid year                       // panel

* Hard assertions (do not run silently)
assert age >= 0 & age <= 120 if !missing(age)
assert inlist(female, 0, 1)         if !missing(female)
assert !missing(hhid)
assert !missing(treatment_status)   if sample == 1

* Safe drops with explicit count
iedropone if missing(outcome), error
```

`iedropone` errors if the count is unexpected. Bare `drop if ...` should be the exception, not the rule.

## 7. Master Dataset

A master dataset stores time-invariant identifying information, sampling status, and treatment assignment. There is **one master dataset per unit of observation**. All other datasets link to it via the ID variable.

Two versions are maintained:

- `MasterData/master_household.dta` — de-identified, used in scripts and shared across the team.
- `EncryptedData/master_household_PII.dta` — with names, GPS, contact info; encrypted with VeraCrypt.

Updates to the master dataset go through a single, reviewed do-file:

```stata
use "${master_data}/master_household.dta", clear
merge 1:1 hhid using "${baseline_int}/baseline_treatment_assignment.dta", ///
    keepusing(treated stratum) assert(match) nogen
ieboilsave, idvars(hhid)
save "${master_data}/master_household.dta", replace
```

## 8. Harmonization Across Rounds (`iecodebook append`)

`iecodebook append` is the right tool when baseline and endline use different variable names but represent the same concepts.

```stata
iecodebook append ///
    "${baseline_int}/baseline_clean.dta" ///
    "${endline_int}/endline_clean.dta" ///
    using "${doc}/harmonize_codebook.xlsx", ///
    clear gen(round) match(hhid)
```

Open the codebook to map each variable across rounds; the result is a single panel-format dataset with consistent names and labels.

## 9. De-identification for Public Release

Before sharing data publicly:

```stata
use "${final}/baseline_hh_clean.dta", clear

* Drop direct identifiers
drop name surname phone gps_lat gps_lon dob

* Coarsen quasi-identifiers
gen age_group = floor(age / 5) * 5
drop age
recode region (1/2 = 1 "North/East") (3/4 = 2 "South/West"), gen(region_coarse)

* Optionally aggregate or k-anonymize small cells
* (use sdcMicro in R for serious disclosure-risk analysis)

ieboilsave, idvars(hhid)
save "${final}/public_release/baseline_hh_public.dta", replace
```

Consider J-PAL's [`pii_scan`](https://github.com/J-PAL/stata_PII_scan) to flag remaining likely-PII variables.

## 10. Reproducibility Discipline

- Every cleaning script must run end-to-end from a clean Stata session.
- `set seed` whenever there is randomness (sampling, jitter, stochastic imputation).
- Never `cd`. Always reference paths via globals defined in `MasterDoFile.do`.
- `Raw/` is immutable. Every transformation produces a new file in `Intermediate/` or `Final/`.
- Add `EncryptedData/` and any local secrets to `.gitignore`.
- After non-trivial changes, run `iedorep` ([DIME's reproducibility checker](https://dimewiki.worldbank.org/Iedorep)) before publishing.
- Document every drop, every imputed value, and every renamed variable in `Documentation/cleaning_log.md`.
