---
name: working-with-data
description: >
  Foundational data-discipline skill for econometrics work in any language. Enforces the discipline that every other data, analysis, and writing skill depends on: define the unit of analysis before anything else; treat IDs as a contract; merge with explicit cardinality and validation; never silently change the unit of observation; protect PII; document every drop; keep raw immutable; build a master dataset per unit of observation. Cross-language patterns for Stata, R, and Python; aligned with DIME Analytics' [Data Cleaning](https://dimewiki.worldbank.org/Data_Cleaning), [ID Variable Properties](https://dimewiki.worldbank.org/ID_Variable_Properties), and [DataWork Folder](https://dimewiki.worldbank.org/DataWork_Folder) guidance.
  Use when the user asks to combine datasets, build a panel, validate data structure, set up a project's data folder, handle PII / de-identification, define or change the unit of analysis, debug a merge, or whenever multiple data skills are about to interact (e.g. before running an analysis on a freshly-cleaned dataset).
workflow_stage: data
compatibility:
  - claude-code
  - cursor
  - codex
  - gemini-cli
author: JonasWeinert
version: 1.0.0
tags:
  - data
  - data-discipline
  - unit-of-analysis
  - merging
  - master-dataset
  - pii
  - dime
  - reproducibility
  - foundational
---

# Working With Data

The foundational data-discipline skill. Every other skill in this repo (`api-data-fetcher`, `stata-data-cleaning`, the analysis skills, the writing skills) assumes the data was prepared with this discipline. Use this skill before, between, or alongside the others — not after.

## Operating Principles

1. **Unit of analysis first, code second.** Before any merge, regression, or figure, state the unit of analysis explicitly (firm-year, household-month, country-quarter, individual). Assert it with `isid` / `df.duplicated().sum() == 0` / `stopifnot(!duplicated(...))`. Half of empirical mistakes come from a silent change of unit between two operations.
2. **IDs are a contract.** A unique identifier is unique, non-missing, immutable, type-stable, and documented. If your ID can be missing, it isn't an ID. If it can change between waves, it isn't an ID.
3. **Merging is cardinality first.** Always declare 1:1, m:1, 1:m, or m:m before the merge. Always require `match` (or its language equivalent) and inspect anything that doesn't match. There is no such thing as a "safe" `m:m` merge; if you wrote one, redesign.
4. **Raw is immutable.** `data/raw/` is write-once. Every transformation produces a new file in `data/intermediate/` or `data/processed/`. Re-running a pipeline from scratch reproduces the analysis-ready file byte-for-byte.
5. **PII never leaves the encrypted folder.** Names, GPS, dates of birth, contact info, national IDs, photos: encrypted at rest, env-var keys, `.gitignore`d, never echoed to logs. The de-identified version is what the analysis sees.
6. **Drops are logged.** Every filter has a reason in a comment and an N before/after.

## Decision Policy

This skill follows the repo-wide [Agent Policy](../../AGENT_POLICY.md).

**ASK before proceeding** (blocking):

1. What is the unit of analysis (single ID or composite key)?
2. Is the dataset a panel (balanced, unbalanced, rotating) or a cross-section?
3. Does the raw data contain PII? If yes, is encryption already set up?
4. Before any merge: what is the cardinality (1:1, m:1, 1:m), what is the match key, and what should happen to non-matches (drop, keep with `_merge` flag, error)?
5. When changing the unit of analysis (collapse, expand, reshape): which observations should aggregate, and how?

**DEFAULT + flag** (use this default; tell the user how to override):

- DataWork folder layout: `data/{raw, intermediate, processed}` + `data/encrypted/` for PII (see [DIME DataWork Folder](https://dimewiki.worldbank.org/DataWork_Folder)). Override with explicit paths.
- Merge non-matches: drop master-only and using-only with a count printed, unless the user specifies `keep` or `keepall`.
- Master dataset per unit of observation, in `data/processed/master/`.
- Numeric IDs over string IDs when both are available.
- Long format for analysis-ready panels; wide only when needed for a specific output.

**DOCUMENT and proceed** (write into the decisions log):

- Inferred unit of analysis when not stated, with the assertion that confirms it.
- Each merge: cardinality, key, N matched / master-only / using-only.
- Each filter: reason and N before/after.
- Each derived variable: source columns and transformation.
- Choice of de-identification thresholds (k-anonymity level, age coarsening width).

`PROCEED` items follow the cross-cutting rules in `AGENT_POLICY.md` (raw immutable, no PII in git, dynamic absolute paths, `set seed`, `ieboilstart` / `pyproject.toml` / `Project.toml`).

## Pre-flight Checklist

Before generating code, confirm with the user — and write the answers into the script header:

- **Unit of analysis.** Single ID (`hhid`) or composite (`hhid year`)? What is "one observation"?
- **Panel structure.** Cross-section / balanced panel / unbalanced / rotating panel?
- **ID provenance.** Where do IDs come from? Are they stable across waves? Across data sources?
- **PII status.** Does the file contain personally identifying information? If yes, is the workspace already configured for encryption?
- **Goal of this script.** Build master dataset / merge for analysis / reshape / sample construction / harmonize across waves / de-identify for release?

## Decision Tree: Combining Datasets

```
Same unit of observation, complementary variables
├── Cross-section: 1:1 merge on the unit ID
│   Stata:  merge 1:1 hhid using "B.dta", assert(match)
│   Python: pd.merge(A, B, on="hhid", how="inner", validate="1:1")
│   R:      dplyr::inner_join(A, B, by = "hhid")
│           stopifnot(nrow(A) == nrow(result))
└── Panel: 1:1 on the composite key
    Stata:  merge 1:1 hhid year using "B.dta", assert(match)
    Python: pd.merge(A, B, on=["hhid","year"], validate="1:1")

Multiple obs in one, one in the other (e.g. household + member info)
└── m:1 from the many side, attach the household covariates
    Stata:  merge m:1 hhid using "household.dta", assert(match master)
    Python: pd.merge(members, household, on="hhid", validate="m:1")

Both sides multi (e.g. transactions x people, with same key)
└── DO NOT m:m merge. Either:
    1. Aggregate one side first to make it 1:m, OR
    2. Use a join that explicitly handles the cross product
       (rarely the right answer; reconsider the question).

Different units of observation but you need a panel
└── First decide the unit of the result, then aggregate one side.
    "Firm-year × employee-quarter" -> aggregate employees to
    firm-year (means, sums, counts) before merging.

Cross-walks / fuzzy keys (names, addresses)
└── Use a deterministic crosswalk file when possible. If not, use
    a probabilistic match (R: fuzzyjoin; Python: rapidfuzz; Stata:
    matchit / reclink2). Always validate on a labeled subset and
    report match rates.
```

## ID Variable Contract

(Following DIME's [ID Variable Properties](https://dimewiki.worldbank.org/ID_Variable_Properties).)

A field is an ID variable iff it satisfies *all* of:

1. **Unique** within the dataset (or with the rest of the composite key).
2. **Non-missing** for every observation.
3. **Immutable** within and across data sources. Same firm = same `firm_id` everywhere.
4. **Type-stable.** Either always numeric or always string. Strings preserve leading zeros and very long codes; numerics are smaller and faster. Choose once.
5. **Documented** in the codebook with: source, format (digits, with/without leading zeros), domain, and any known issues (mergers, reassignments).

Standard assertion (run after import, after merge, before save):

```stata
isid hhid year                       // Stata
duplicates report hhid year          // explicit count
assert !missing(hhid)
```

```python
assert df.duplicated(["hhid", "year"]).sum() == 0       # Python
assert df[["hhid", "year"]].notna().all().all()
```

```r
stopifnot(!anyDuplicated(df[, c("hhid", "year")]))      # R
stopifnot(!any(is.na(df$hhid)))
```

## Merging Without Surprises

Before any merge, declare:

1. **Cardinality.** 1:1, m:1, 1:m. (Reject m:m.)
2. **Key.** Single column or composite, same name on both sides.
3. **Expected match status.** All match? Master-only allowed? Using-only allowed?
4. **What happens to non-matches.** Drop, flag, error.

Validation pattern:

```stata
* Stata
use "master.dta", clear
isid hhid
merge 1:1 hhid using "using.dta"
assert _merge == 3                     // require all match; or:
* tabulate _merge
* drop if _merge == 2                  // drop using-only
drop _merge
isid hhid
```

```python
# Python (pandas)
master = pd.read_parquet("master.parquet")
using  = pd.read_parquet("using.parquet")
assert master["hhid"].is_unique
assert using["hhid"].is_unique
out = master.merge(using, on="hhid", how="left",
                   validate="1:1", indicator=True)
n_only_master = (out["_merge"] == "left_only").sum()
n_only_using  = (out["_merge"] == "right_only").sum()
print(f"only_master={n_only_master}, only_using={n_only_using}")
out = out.drop(columns="_merge")
```

```r
# R (dplyr / inner_join, with explicit anti-joins to inspect)
library(dplyr)
master <- arrow::read_parquet("master.parquet")
using  <- arrow::read_parquet("using.parquet")
stopifnot(!anyDuplicated(master$hhid), !anyDuplicated(using$hhid))

only_master <- anti_join(master, using, by = "hhid")
only_using  <- anti_join(using, master, by = "hhid")
message(sprintf("only_master=%d, only_using=%d",
                nrow(only_master), nrow(only_using)))

out <- inner_join(master, using, by = "hhid")
stopifnot(!anyDuplicated(out$hhid))
```

If `n_only_master` or `n_only_using` is non-zero, **stop and ask** (or document if the agent has been told what to do).

## Master Dataset

A master dataset is the single source of truth for time-invariant information about each unit:

- one master per unit of observation (household, individual, firm, school);
- de-identified version in `data/processed/master/` for analysis;
- encrypted version in `data/encrypted/master/` if PII is involved;
- updated through one reviewed script, never ad-hoc.

A master dataset typically holds:

- The ID and any aliases / crosswalks.
- Sample frame (was this unit in the sampling universe?).
- Sampling status and stratum.
- Treatment assignment (and date, for staggered designs).
- Time-invariant characteristics (region, founding year, baseline values used in matching).

When in doubt: store time-invariant fields in master, time-varying fields in survey-round files, and `merge m:1` from the round file to master at analysis time.

## Sample Construction Discipline

Every cleaning script logs N at every filter. Pattern:

```python
def log_filter(df, label):
    print(f"[{label}] N = {len(df):,}, units = {df['unit'].nunique():,}")
    return df

clean = (raw
         .pipe(log_filter, "raw")
         .query("year >= 2010").pipe(log_filter, "year >= 2010")
         .dropna(subset=["outcome"]).pipe(log_filter, "outcome non-missing")
         .query("revenue > 0").pipe(log_filter, "revenue > 0"))
```

```r
log_filter <- function(df, label) {
  message(sprintf("[%s] N = %d, units = %d",
                  label, nrow(df), dplyr::n_distinct(df$unit)))
  df
}

clean <- raw |>
  log_filter("raw") |>
  filter(year >= 2010) |> log_filter("year >= 2010") |>
  filter(!is.na(outcome)) |> log_filter("outcome non-missing")
```

In Stata, prefer `iedropone` over bare `drop`:

```stata
ieduplicates ...                              // resolve dups first
iedropone if year < 2010, error               // errors if count is unexpected
iedropone if missing(outcome), error
```

The output of these logs goes into the decisions log block at the top of the script.

## PII Discipline

Treat PII like radioactive material:

- Common PII (always): names, GPS coordinates, dates of birth, contact info, national IDs, photos.
- Context-dependent PII: small geographic units, rare conditions, employer x role for high-profile people.
- Never commit PII to git. Add `data/encrypted/`, `*.dta` containing PII, and `.env` to `.gitignore`.
- Encrypt at rest (VeraCrypt for Stata-native; age / gpg for plain files).
- Coarsen quasi-identifiers before sharing (age in 5-year bands; collapse small geographies; suppress small cells).
- Use [J-PAL `pii_scan`](https://github.com/J-PAL/stata_PII_scan) to flag candidates the agent might miss.
- `stata-data-cleaning` skill has a full `deidentify_for_release.do` example.

## Common Pitfalls

- Merging without checking `_merge` codes (Stata) or `validate=` (pandas) — silently produces a Cartesian-style result when the cardinality is wrong.
- Reshape that silently drops rows because variable names don't match the stub.
- `m:m` merge that turns 1,000 + 1,000 rows into 50,000.
- Using a string ID like `"01234"` and a numeric ID like `1234` interchangeably across files — they look the same, never match.
- Filtering on a derived variable, then later regenerating the variable with a different definition.
- Storing dates as strings in some files and as Stata dates / pandas datetime in others.
- Saving a "cleaned" file that still contains observations the team agreed to drop, because the drop was applied in interactive mode but not in the script.
- Hand-typing N in the paper because the cleaning log is in a notebook.

## Additional Resources

- `reference.md` — extended patterns: composite keys, hierarchical data (households / individuals), reshape, survey weights, crosswalks, time-zone discipline, encoding gotchas, codebooks.
- `examples/` — runnable cross-language patterns:
  - `examples/merge_validate.py` — pandas merges with explicit `validate=` and `_merge`-equivalent inspection
  - `examples/merge_validate.do` — Stata `merge 1:1` / `m:1` with `assert(match)` and `_merge` discipline
  - `examples/merge_validate.R` — dplyr joins with anti-join inspection
  - `examples/master_dataset_workflow.do` — building a master HH dataset DIME-style
  - `examples/sample_construction_logging.py` — the `log_filter` pattern in pandas
  - `examples/decisions_log.txt` — annotated example of a filled-in decisions log

## Cross-Skill Routing

- For API data acquisition (FRED, World Bank, BLS, etc.) → `api-data-fetcher`.
- For Stata-specific cleaning (`iecodebook`, `ieduplicates`, extended missing values, harmonization across waves) → `stata-data-cleaning`.
- For panel analysis after data is ready → `r-econometrics` / `stata-regression` / `python-panel-data`.

## References

### DIME (the conceptual backbone)

- DIME Analytics, [Data Cleaning](https://dimewiki.worldbank.org/Data_Cleaning).
- DIME Analytics, [ID Variable Properties](https://dimewiki.worldbank.org/ID_Variable_Properties).
- DIME Analytics, [DataWork Folder](https://dimewiki.worldbank.org/DataWork_Folder).
- DIME Analytics, [Master Do-files](https://dimewiki.worldbank.org/Master_Do-files).
- DIME Analytics, [Personally Identifiable Information (PII)](https://dimewiki.worldbank.org/Personally_Identifiable_Information_(PII)).
- DIME Analytics, [Reproducible Research](https://dimewiki.worldbank.org/Reproducible_Research).

### Style

- Wickham (2014), *Tidy Data*.
- Gentzkow & Shapiro (2014), *Code and Data for the Social Sciences*.
- IPA, *Reproducible Research: Best Practices for Data and Code Management*.
- Quartz, [Bad Data Guide](https://github.com/Quartz/bad-data-guide).
