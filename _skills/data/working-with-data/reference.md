# Working With Data Reference

Detailed cross-language patterns for the discipline that every data-touching skill assumes.

## 1. Composite Keys

A composite key is a tuple of columns whose combination is unique. It does not become unique just because each column has many values.

```stata
isid hhid year                                  // unique on (hhid, year)
isid country product month                      // unique on triple
```

```python
assert df.duplicated(["hhid", "year"]).sum() == 0
```

```r
stopifnot(!anyDuplicated(df[, c("hhid", "year")]))
```

To find the offenders before you fix them:

```stata
duplicates tag hhid year, gen(dup_tag)
list hhid year if dup_tag > 0, sepby(hhid)
```

```python
mask = df.duplicated(["hhid", "year"], keep=False)
df.loc[mask].sort_values(["hhid", "year"])
```

## 2. Hierarchical Data (households and individuals)

A household survey usually has at least two units of observation: the household and the individual. Treat them as separate datasets, each with its own master file.

```
data/processed/
├── master/
│   ├── master_household.dta          # one row per hhid
│   └── master_individual.dta         # one row per (hhid, person_id)
├── baseline/
│   ├── household.dta                 # one row per hhid
│   └── individual.dta                # one row per (hhid, person_id)
└── endline/
    ├── household.dta
    └── individual.dta
```

When you need household covariates on individual rows (the common case for analysis):

```stata
use "data/processed/baseline/individual.dta", clear
isid hhid person_id
merge m:1 hhid using "data/processed/baseline/household.dta", ///
    assert(match) keep(match) nogen
isid hhid person_id
```

This is `m:1` (many individuals : one household). The reverse (collapsing individuals up to household level) is a `collapse` / `groupby`, not a merge.

## 3. Changing the Unit of Analysis

Going to a coarser unit (collapse / groupby):

```stata
collapse (sum) sales (mean) emp_size, by(firm_id year)
isid firm_id year
```

```python
out = (df.groupby(["firm_id", "year"], as_index=False)
         .agg(sales = ("sales", "sum"),
              emp_size = ("emp_size", "mean")))
assert out.duplicated(["firm_id", "year"]).sum() == 0
```

```r
library(dplyr)
out <- df |>
  group_by(firm_id, year) |>
  summarise(sales = sum(sales), emp_size = mean(emp_size),
            .groups = "drop")
stopifnot(!anyDuplicated(out[, c("firm_id", "year")]))
```

Going to a finer unit (expand): require a "weights" or share table that documents how to split. Never invent shares.

## 4. Wide vs Long

Long format is the default for analysis-ready panels (one row per observation):

```
hhid year   outcome  treat   controls...
001  2018   1.34     0       ...
001  2019   1.42     1       ...
```

Wide is right for outputs that humans read across columns (a balance table, a summary by year). Convert at the boundary, not in the middle of analysis.

```stata
reshape long y_, i(hhid) j(year)
reshape wide y_, i(hhid) j(year)
```

```python
long_df = df.melt(id_vars=["hhid"], var_name="year", value_name="y")
wide_df = long_df.pivot(index="hhid", columns="year", values="y")
```

```r
long_df <- tidyr::pivot_longer(df, cols = starts_with("y_"),
                               names_to = "year", values_to = "y")
wide_df <- tidyr::pivot_wider(long_df, names_from = "year", values_from = "y")
```

After every reshape, re-assert the unit of analysis.

## 5. Survey Weights

Survey weights need to travel with the unit they are defined for. Most common:

- Sampling weights at the household level for a household survey.
- Replicate weights for variance estimation.

If you collapse to a coarser unit, the weight aggregation rule depends on the design:

- For totals: sum the weights.
- For means / proportions: weight the variable, then aggregate.

Never silently drop the weight column. Tag it in the codebook and propagate it explicitly.

```stata
svyset hhid [pweight = sampw]
svy: mean income
```

```r
library(survey)
des <- svydesign(id = ~hhid, weights = ~sampw, data = df)
svymean(~income, des)
```

## 6. Crosswalks (deterministic) and Fuzzy Matching

A crosswalk is a small reference dataset that maps IDs from one schema to another. Build it once, version it, and merge against it.

```
data/raw/crosswalks/
├── industry_naics_to_isic.csv
├── state_fips_to_iso.csv
└── firm_id_2018_to_2024.csv          # tracks mergers / reassignments
```

For fuzzy matching (names, addresses) when no crosswalk exists:

- R: `fuzzyjoin::stringdist_join(..., method = "jw", max_dist = 0.15)`.
- Python: `rapidfuzz.process.extract(...)`.
- Stata: `matchit name1 using "B.dta", ...` or `reclink2`.

Always:
1. Block by something exact (state, year, industry) before fuzzy.
2. Validate on a hand-labeled subsample.
3. Report a match rate and a precision estimate.
4. Save the crosswalk and reuse it; never re-run probabilistic matching ad hoc.

## 7. Time-Zone, Date, and Encoding Discipline

- Store dates as native date types, not strings (`%td` in Stata, `datetime64[ns]` in pandas, `Date` in R).
- Be explicit about time zones for timestamps. Default to UTC at storage; convert to local for display only.
- Choose an encoding (UTF-8) and stick to it. CSV imports from Excel are the usual culprit for double-encoded characters.

```stata
gen survey_date = date(survey_date_str, "YMD")
format survey_date %td
```

```python
df["survey_date"] = pd.to_datetime(df["survey_date_str"], format="%Y-%m-%d")
df["timestamp_utc"] = pd.to_datetime(df["timestamp"], utc=True)
```

```r
df$survey_date <- as.Date(df$survey_date_str, format = "%Y-%m-%d")
df$timestamp_utc <- lubridate::ymd_hms(df$timestamp, tz = "UTC")
```

## 8. Codebook (data dictionary)

Every cleaned dataset ships with a codebook. Minimum columns:

| name | type | label | source | unit | notes |
|------|------|-------|--------|------|-------|

Production via:

- Stata: `iecodebook export using "..."` (DIME).
- Python: a one-script generator over `df.dtypes` + a curated YAML of labels.
- R: `labelled::var_label(df) |> tibble::enframe()`.

The codebook is the artifact that lets a future you (or a referee) understand what every column means.

## 9. Decisions Log Header (cross-language)

```text
# DECISIONS LOG (review and edit before publication)
# ============================================================
# Script         : code/r/build_panel.R
# Inputs         : data/raw/baseline.csv, data/raw/endline.csv
# Outputs        : data/processed/panel.parquet
# Unit of obs    : firm-year (asserted)
# ID             : firm_id (numeric, immutable across waves)
# Panel structure: unbalanced; 12,432 firms, 174,048 firm-years
# Merges:
#   - baseline x endline on firm_id  (1:1, both-only kept; N=12,432)
#   - + master on firm_id            (m:1, all matched)
# Filters (cumulative N):
#   - raw                          : 14,012 firms
#   - drop missing(industry)       : 13,801
#   - drop revenue <= 0            : 12,711
#   - keep firm in both waves      : 12,432
# Derived variables:
#   - log_rev = log(revenue + 1)
#   - winsorized log_rev at p1/p99
# PII handling:
#   - dropped: name, address, phone, owner_dob
# Reproducibility:
#   - seed: 20240101
#   - lockfile: renv.lock
# ASSUMPTIONS [HUMAN: please confirm]:
#   - firm_id is stable across the 2018 reform.
#   - "Industry" is fixed at baseline for each firm.
# ============================================================
```

The agent fills this in. The human reviews and edits.

## 10. Reproducibility Conventions (DIME applied)

- `data/raw/` is `.gitignore`d unless the source license allows redistribution.
- `data/encrypted/` is `.gitignore`d always.
- `data/intermediate/` is `.gitignore`d (it's a cache).
- `data/processed/` may be committed if size allows; otherwise gitignored and rebuilt from `code/`.
- A single `Makefile` / `master.do` / `run_all.py` rebuilds everything from raw.
- Pin the language: `Project.toml`+`Manifest.toml` (Julia), `pyproject.toml`+`uv.lock` (Python), `renv.lock` (R), Stata `version 17.0` via `ieboilstart`.
- `set seed` in every script that bootstraps, samples, or jitters.
