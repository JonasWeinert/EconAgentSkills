# API Data Fetcher Reference

Detailed patterns for the API-data-fetcher skill. Apply DIME Analytics conceptual conventions ([Reproducible Research](https://dimewiki.worldbank.org/Reproducible_Research), [Data Cleaning](https://dimewiki.worldbank.org/Data_Cleaning), [DataWork Folder](https://dimewiki.worldbank.org/DataWork_Folder)) to Python data acquisition.

## 1. Source Codebook Schema

Every fetched series should have one row in `docs/source_codebook.csv`:

| column            | example                                       | notes                                       |
|-------------------|-----------------------------------------------|---------------------------------------------|
| `source`          | `FRED`                                        | canonical source name                       |
| `series_id`       | `GDPC1`                                       | source's stable ID (not the human title)    |
| `description`     | Real Gross Domestic Product                   | as published                                |
| `units`           | Billions of Chained 2017 Dollars              | exactly as published                        |
| `frequency`       | quarterly                                     | annual/quarterly/monthly/weekly/daily       |
| `transformation`  | `none` / `log` / `pct_change_yoy`             | what we did locally                         |
| `vintage`         | `2026-05-05`                                  | ISO date the data was fetched               |
| `access_date`     | `2026-05-05T14:32:11Z`                        | timestamp of the API call                   |
| `coverage_start`  | `1947-01-01`                                  | first observation in the response           |
| `coverage_end`    | `2026-03-31`                                  | last observation in the response            |
| `n_obs`           | 318                                           | number of non-missing observations          |
| `license`         | Public domain                                 | record the source's terms                   |
| `citation`        | U.S. Bureau of Economic Analysis, retrieved...| ready-to-paste                              |

The codebook is the audit trail. If a paper cites a number, the codebook should let any reader reconstruct it.

## 2. FRED Patterns

```python
import os
from fredapi import Fred

fred = Fred(api_key = os.environ["FRED_API_KEY"])

# Current revisions
gdp = fred.get_series("GDPC1",
                      observation_start = "1947-01-01",
                      observation_end   = "2026-03-31")

# Real-time vintage (first release)
gdp_first = fred.get_series_first_release("GDPC1")

# All vintages
gdp_history = fred.get_series_all_releases("GDPC1")

# Series metadata for the codebook
info = fred.get_series_info("GDPC1")
```

Common FRED series economists fetch repeatedly:

| Topic       | Series IDs                                                    |
|-------------|---------------------------------------------------------------|
| Output      | `GDP` `GDPC1` `GDPPOT`                                        |
| Labor       | `UNRATE` `PAYEMS` `CIVPART` `JTSJOL` `LNS14000003`            |
| Prices      | `CPIAUCSL` `CPILFESL` `PCEPI` `DFEDTARU`                      |
| Rates       | `FEDFUNDS` `DGS10` `DGS2` `T10Y2Y` `MORTGAGE30US`             |
| Money       | `M2SL` `WALCL` `TOTRESNS`                                     |
| Sentiment   | `UMCSENT` `USSLIND`                                           |
| Trade       | `BOPGSTB` `IEABC`                                             |

## 3. World Bank Patterns

```python
import wbdata
import pandas as pd

# Find indicators by topic
search = wbdata.search_indicators("GDP per capita")

# Fetch a panel
indicators = {
    "NY.GDP.PCAP.CD":      "gdp_per_capita_usd",
    "NY.GDP.MKTP.KD.ZG":   "gdp_growth_pct",
    "SP.POP.TOTL":         "population",
    "SI.POV.GINI":         "gini",
}
df = wbdata.get_dataframe(
    indicators,
    country = ["USA", "GBR", "DEU", "FRA", "JPN", "CHN", "IND", "BRA"],
).reset_index()
```

Watch-outs:

- World Bank country codes use the 3-letter ISO 3166-1 alpha-3 standard, with extras like `WLD`, `EUU`, `OED`.
- Coverage is uneven; never silently treat NaN as zero.
- Indicators are sometimes redefined. Pin the indicator code; record the units in the codebook.

## 4. OECD via SDMX

```python
import pandasdmx as sdmx

oecd = sdmx.Request("OECD")

# Discover the dataset structure
dataflows = oecd.dataflow().dataflow

# Fetch Quarterly National Accounts
key = dict(LOCATION = ["USA", "GBR", "DEU"],
           SUBJECT  = "B1_GE",     # GDP at market prices
           MEASURE  = "VPVOBARSA",  # Volume, percentage change, annual rate
           FREQUENCY = "Q")
data_msg = oecd.data("QNA", key = key, params = {"startTime": "2000"})
df = sdmx.to_pandas(data_msg).reset_index()
```

For OECD codes, browse https://stats.oecd.org or https://data-viewer.oecd.org.

## 5. BLS Patterns

```python
import os, requests

api_key = os.environ["BLS_API_KEY"]
payload = {
    "seriesid":  ["LNS14000000", "CES0000000001"],
    "startyear": "2000",
    "endyear":   "2026",
    "registrationkey": api_key,
}
r = requests.post("https://api.bls.gov/publicAPI/v2/timeseries/data/",
                   json = payload, timeout = 30)
r.raise_for_status()
data = r.json()
```

BLS ID structure (e.g. CPS, CES) is opaque; document each ID with its descriptive label in the codebook.

## 6. Caching

Two patterns work well:

### 6.1 `requests-cache` for HTTP-level caching

```python
import requests_cache
session = requests_cache.CachedSession(
    cache_name = "data/cache/http",
    backend    = "sqlite",
    expire_after = 3600 * 24,    # 1 day
)
```

### 6.2 Hand-rolled JSON cache for SDK calls

```python
import hashlib, json
from pathlib import Path

CACHE = Path("data/cache/fred")
CACHE.mkdir(parents = True, exist_ok = True)

def cached_fred_series(fred, series_id: str, **kwargs) -> "pd.Series":
    key  = hashlib.sha256(
        json.dumps({"id": series_id, **kwargs}, sort_keys = True).encode()
    ).hexdigest()[:16]
    path = CACHE / f"{series_id}_{key}.parquet"
    if path.exists():
        return pd.read_parquet(path)["value"]
    s = fred.get_series(series_id, **kwargs)
    s.rename("value").to_frame().to_parquet(path)
    return s
```

Cache invalidation rules: bump the cache version when the upstream schema changes; never silently use stale data for production runs.

## 7. Schema Validation with `pandera`

```python
import pandas as pd
import pandera as pa

PanelSchema = pa.DataFrameSchema({
    "country":     pa.Column(str),
    "year":        pa.Column(int, checks = pa.Check.in_range(1960, 2026)),
    "indicator":   pa.Column(str),
    "value":       pa.Column(float, nullable = True),
    "source":      pa.Column(str),
    "vintage":     pa.Column(str),
})

def validate(df: pd.DataFrame) -> pd.DataFrame:
    return PanelSchema.validate(df, lazy = True)
```

`pandera` raises a single error containing all violations, which makes data debugging much faster than ad-hoc `assert`s.

## 8. Long vs Wide Format

Recommend **long format** for the canonical processed file:

```
country | year | indicator | value | source | vintage
USA     | 2020 | gdp_pc    | 63... | FRED   | 2026-05-05
```

- Easier to add new indicators without schema migrations.
- Trivially filterable by source / vintage for sensitivity analysis.
- Pivot to wide on the way into Stata / R only when needed.

## 9. Real-Time vs Current-Vintage Data

For policy-relevant or forecasting analysis, current revisions are misleading. Use real-time vintages:

- FRED: `get_series_first_release(...)` or ALFRED.
- BEA: `BEA Vintage History` API.
- Many central banks publish vintage archives.

Record the vintage policy explicitly in the codebook.

## 10. Rate Limiting and Politeness

- Throttle bulk downloads (`time.sleep(0.2)` between calls is usually enough for FRED/World Bank).
- Use exponential backoff on 429 / 5xx responses.
- Identify your client with a User-Agent header containing project name and contact email.
- Honor each API's documented limits and licensing terms.

## 11. Reproducibility Discipline (DIME applied to Python)

- `pyproject.toml` + `uv` or `requirements.txt` + `pip-tools` for pinned dependencies.
- `.env` for API keys; `.env.example` checked in with placeholders only.
- `data/raw/` is `.gitignore`d unless the source license allows redistribution.
- Every analysis-ready file in `data/processed/` is reproducible from `pipelines/run_all.py` and the recorded vintages.
- Add a `Makefile` or `invoke` task so collaborators reproduce with one command:

```makefile
.PHONY: data
data:
	uv run python pipelines/run_all.py
```
