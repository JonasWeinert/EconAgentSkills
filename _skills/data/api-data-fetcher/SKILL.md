---
name: api-data-fetcher
description: >
  Generates rigorous, reproducible Python data-acquisition pipelines for economic APIs (FRED, World Bank, BLS, OECD SDMX, IMF, Eurostat, Yahoo Finance). Applies DIME Analytics conceptual conventions to Python: DataWork-style folders with immutable Raw/, master orchestration script with dynamic absolute paths via `pathlib`, secrets-as-env-vars (PII discipline applied to API keys), source codebooks recording series IDs / units / vintage / access date, deterministic caching, and asserted output schemas.
  Use when the user asks to download economic indicators, build cross-country panels, automate data refreshes, combine multiple API sources, set up a reproducible data pipeline, or document data provenance.
workflow_stage: data
compatibility:
  - claude-code
  - cursor
  - codex
  - gemini-cli
author: JonasWeinert
version: 2.0.0
tags:
  - python
  - api
  - fred
  - world-bank
  - oecd
  - imf
  - bls
  - eurostat
  - data-pipeline
  - reproducibility
  - dime
---

# API Data Fetcher

Generate rigorous, reproducible Python pipelines for fetching economic data from public APIs. Apply DIME Analytics' [reproducibility principles](https://dimewiki.worldbank.org/Reproducible_Research) and [data-cleaning discipline](https://dimewiki.worldbank.org/Data_Cleaning) to Python: an immutable raw layer, a master orchestration script, dynamic absolute paths, secrets in env vars only, codebook-style source documentation, and asserted output schemas.

## Operating Principles

1. **Raw is immutable, like in DIME.** Every API response is written to `data/raw/` with a vintage suffix (`_v2026-05-05`) and never edited. Cleaning happens in `data/intermediate/`; analysis-ready outputs in `data/processed/`. This mirrors DIME's [DataWork folder](https://dimewiki.worldbank.org/DataWork_Folder).
2. **Secrets are PII.** API keys are treated like personally identifiable information ([DIME PII page](https://dimewiki.worldbank.org/Personally_Identifiable_Information_(PII))): never hardcode, never commit, never log. Read from environment variables or `.env` files that are `.gitignore`d.
3. **Master script orchestrates.** A `pipelines/run_all.py` file is the Python equivalent of DIME's [master do-file](https://dimewiki.worldbank.org/Master_Do-files): installs packages, defines paths via `pathlib`, sets seeds, runs each fetcher in order, and is the single command that reproduces the dataset.
4. **Document provenance.** Every fetched series carries a source codebook entry: source name, series ID, units, frequency, transformation, vintage, access date, license. This is the DIME [data documentation](https://dimewiki.worldbank.org/Data_Documentation) principle applied to API data.
5. **Cache deterministically.** Cache files are content-addressed by request parameters; identical calls return identical bytes; cache invalidation is explicit, not silent. `requests-cache` or a hand-rolled JSON cache work fine.
6. **Validate the schema.** After every fetch, assert: expected columns, dtypes, frequency, date range, no extra series IDs returned, no silent NaN explosions. Use `pandera` or hand-rolled assertions.

## Decision Policy

This skill follows the repo-wide [Agent Policy](../../AGENT_POLICY.md). For cross-cutting data discipline (unit of analysis, ID variables, merging, master dataset, PII), this skill defers to [`working-with-data`](../working-with-data/).

**ASK before proceeding** (blocking):

1. Indicators (which exact series IDs / indicator codes), geography, frequency, and date range.
2. Data vintage policy: real-time first releases vs current revisions (matters for forecasting / policy work).
3. Update cadence: one-shot vs scheduled refresh (changes how vintage tagging and caching are set up).
4. License attribution requirements (especially for redistribution).

**DEFAULT + flag** (use this default; tell the user how to override):

- One immutable parquet per series in `data/raw/<source>/<series>_<vintage>.parquet`.
- Long-format country/entity-date-indicator file in `data/processed/` as the canonical analysis input.
- `requests-cache` SQLite cache or content-addressed JSON cache in `data/cache/`; explicit invalidation only.
- Hand-rolled `assert` schema validation; upgrade to `pandera` when the schema gets non-trivial.
- Source codebook CSV at `docs/source_codebook.csv`, one row per series.

**DOCUMENT and proceed** (write into the decisions log + `docs/source_codebook.csv`):

- Vintage and access timestamp for every fetched series.
- Source-side units, transformations applied locally, and the resulting unit.
- Any silent re-mapping (e.g. World Bank country code aliases).

`PROCEED` items: API keys via env vars only (`.env` + `.gitignore`), polite throttling (≥ 0.2s between calls), exponential backoff on 429/5xx, dynamic absolute paths via `pathlib`, `mkdir(parents=True, exist_ok=True)` for output folders.

## Pre-flight Checklist

Before writing code, confirm — and write the answers in the script docstring:

- **Indicators.** Which series IDs (FRED) / indicators (World Bank) / topic codes (OECD)?
- **Geography.** Single country, custom country list, or all-available?
- **Frequency.** Annual, quarterly, monthly, daily? Are mixed frequencies acceptable?
- **Date range.** Fixed or rolling window?
- **Vintage.** Real-time data (`fred.get_series_first_release`) or current revisions?
- **Update cadence.** One-shot, daily, monthly?
- **Output format.** Long-format country-year-indicator parquet, or wide-format CSVs per indicator?
- **License and citation.** Is there an attribution requirement?

## Project Layout (DIME-style, in Python)

```
ProjectABC/
├── pyproject.toml                       # pinned deps via uv / pip-tools
├── .env                                 # API keys; .gitignore'd
├── .gitignore
├── data/
│   ├── raw/                             # IMMUTABLE; vintage-suffixed files
│   │   ├── fred/
│   │   │   └── GDP_2026-05-05.csv
│   │   └── worldbank/
│   ├── intermediate/                    # cleaned per-source files
│   ├── processed/                       # analysis-ready, multi-source
│   └── cache/                           # request cache (content-addressed)
├── docs/
│   └── source_codebook.csv              # one row per fetched series
├── pipelines/
│   ├── run_all.py                       # master orchestration script
│   ├── fetch_fred.py
│   ├── fetch_worldbank.py
│   ├── fetch_bls.py
│   ├── fetch_oecd.py
│   ├── fetch_imf.py
│   └── build_panel.py                   # combine sources
└── README.md
```

## Source Selection Decision Tree

```
US macro time series (GDP, CPI, unemployment, FFR, yields, M2):
└── FRED via `fredapi`. Set FRED_API_KEY.
    For real-time vintages: fred.get_series_first_release(...)
    or use ALFRED via the same package.

Cross-country development (GDP per capita, poverty, education, health):
└── World Bank Indicators via `wbdata` (no key needed) or `pandas-datareader`.

US labor (CES, CPS, JOLTS, OES):
└── BLS Public Data API via `bls` package. Register for a key for >25 series/day.

OECD panels (Main Economic Indicators, OECD.Stat):
└── `pandasdmx` against the OECD SDMX endpoint. No key.

IMF:
└── IFS, WEO, BOP via `imf-reader` (formerly `imfpy`) or direct SDMX with pandasdmx.

Eurostat:
└── `eurostat` package or `pandasdmx`.

Markets / financial:
└── `yfinance` for equities; for fixed-income use FRED.
    For commercial-grade data, route to Bloomberg / Refinitiv (paid, not in scope).

Geospatial / nightlights / weather:
└── See climate / GIS skills; this skill is for tabular API data.
```

## Output Skeleton (`run_all.py`)

```python
"""
Project   : ProjectABC
Pipeline  : Fetch, validate, and combine FRED + World Bank data.
Author    : First Last
Created   : 2026-05-05
Inputs    : public APIs (FRED, World Bank)
Outputs   : data/processed/macro_panel.parquet
            docs/source_codebook.csv
"""
from __future__ import annotations

import os
from datetime import date
from pathlib import Path

from pipelines.fetch_fred       import fetch_fred
from pipelines.fetch_worldbank  import fetch_worldbank
from pipelines.build_panel      import build_macro_panel

# 1. Paths (DIME-style: dynamic absolute paths)
PROJECT     = Path(__file__).resolve().parents[1]
DATA_RAW    = PROJECT / "data" / "raw"
DATA_INT    = PROJECT / "data" / "intermediate"
DATA_FINAL  = PROJECT / "data" / "processed"
DOCS        = PROJECT / "docs"
for p in (DATA_RAW, DATA_INT, DATA_FINAL, DOCS):
    p.mkdir(parents = True, exist_ok = True)

VINTAGE = date.today().isoformat()

# 2. Secrets (never hardcoded; read from env)
assert os.getenv("FRED_API_KEY"), "Set FRED_API_KEY in .env"

# 3. Run each fetcher (each writes to RAW with vintage suffix)
fetch_fred(out_dir = DATA_RAW / "fred",        vintage = VINTAGE)
fetch_worldbank(out_dir = DATA_RAW / "worldbank", vintage = VINTAGE)

# 4. Build the analysis-ready panel
build_macro_panel(
    raw_dir   = DATA_RAW,
    int_dir   = DATA_INT,
    final_dir = DATA_FINAL,
    docs_dir  = DOCS,
    vintage   = VINTAGE,
)

print(f"Pipeline complete. Vintage = {VINTAGE}")
```

## Common Pitfalls

- Hardcoding API keys in scripts or notebooks. Use `os.environ` + `.env`.
- Overwriting raw files when re-running. Always include a vintage suffix.
- Silent frequency mixing (annual GDP joined to monthly CPI without resampling).
- Trusting series titles instead of series IDs. FRED renames titles; IDs are stable.
- Ignoring data revisions. For policy-relevant analysis use real-time vintages, not the latest revisions.
- Caching by URL only and missing changes in headers/parameters. Hash the full request.
- Pulling enormous datasets into memory. Stream to parquet and load lazily with `pyarrow`.
- Not recording units. World Bank / OECD often switch units between releases.
- Treating missing values as zero. World Bank coverage is uneven; drop or impute deliberately.

## Additional Resources

- `reference.md` — extended patterns: source codebook schema, caching, validation, real-time vintages, rate limiting.
- `examples/` — runnable scripts:
  - `examples/economic_data_fetcher.py` — minimal FRED + World Bank fetch (legacy reference)
  - `examples/run_all.py` — master orchestration script
  - `examples/fetch_fred.py` — vintage-aware FRED fetcher
  - `examples/fetch_worldbank.py` — World Bank country-year panel
  - `examples/fetch_oecd_sdmx.py` — OECD via SDMX/pandasdmx
  - `examples/fetch_bls.py` — BLS Public Data API
  - `examples/build_panel.py` — combine sources, validate schema, write parquet
  - `examples/source_codebook.csv` — example provenance log

## Requirements

- Python >= 3.10.
- Core: `pandas`, `pyarrow`, `requests`, `python-dotenv`.
- Source clients: `fredapi`, `wbdata`, `pandasdmx`, `bls`, `eurostat`, `yfinance`.
- Validation: `pandera` (optional but recommended).

```bash
pip install pandas pyarrow requests python-dotenv pandera \
            fredapi wbdata pandasdmx bls eurostat yfinance
```

`.env` template:

```bash
FRED_API_KEY=your_fred_key_here
BLS_API_KEY=your_bls_key_here
```

`.gitignore`:

```gitignore
.env
data/raw/
data/intermediate/
data/cache/
```

## References

### DIME Conceptual Inputs

- DIME Analytics, [Reproducible Research](https://dimewiki.worldbank.org/Reproducible_Research)
- DIME Analytics, [DataWork Folder](https://dimewiki.worldbank.org/DataWork_Folder)
- DIME Analytics, [Master Do-files](https://dimewiki.worldbank.org/Master_Do-files)
- DIME Analytics, [Data Cleaning](https://dimewiki.worldbank.org/Data_Cleaning)
- DIME Analytics, [Personally Identifiable Information (PII)](https://dimewiki.worldbank.org/Personally_Identifiable_Information_(PII))
- DIME Analytics, [Data Documentation](https://dimewiki.worldbank.org/Data_Documentation)

### API Documentation

- [FRED API](https://fred.stlouisfed.org/docs/api/fred/)
- [World Bank Indicators API](https://datahelpdesk.worldbank.org/knowledgebase/topics/125589)
- [BLS Public Data API](https://www.bls.gov/developers/)
- [OECD SDMX](https://data.oecd.org/api/)
- [IMF Data Services](https://data.imf.org/api/help)
- [Eurostat REST API](https://ec.europa.eu/eurostat/web/main/data/web-services)

### Style

- QuantEcon, [Python Programming for Economics and Finance](https://python-programming.quantecon.org/).
- Wickham (2014), *Tidy Data*.
