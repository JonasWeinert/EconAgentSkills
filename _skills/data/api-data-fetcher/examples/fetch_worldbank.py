"""fetch_worldbank.py

World Bank Indicators fetcher with codebook logging. Produces
one country-year-indicator file per call to RAW.
"""

from __future__ import annotations

import csv
from datetime import datetime, timezone
from pathlib import Path

import pandas as pd

WB_INDICATORS = {
    "NY.GDP.PCAP.CD":    {"name": "gdp_per_capita_usd",   "units": "Current US$"},
    "NY.GDP.MKTP.KD.ZG": {"name": "gdp_growth_pct",       "units": "Percent (annual)"},
    "SP.POP.TOTL":       {"name": "population",           "units": "People"},
    "SI.POV.GINI":       {"name": "gini",                 "units": "Index"},
    "FP.CPI.TOTL.ZG":    {"name": "inflation_pct",        "units": "Percent (annual)"},
}

DEFAULT_COUNTRIES = ["USA", "GBR", "DEU", "FRA", "JPN",
                     "CHN", "IND", "BRA", "MEX", "ZAF"]


def _append_codebook(docs: Path, row: dict) -> None:
    path = docs / "source_codebook.csv"
    write_header = not path.exists()
    with path.open("a", newline = "", encoding = "utf-8") as f:
        writer = csv.DictWriter(f, fieldnames = row.keys())
        if write_header:
            writer.writeheader()
        writer.writerow(row)


def fetch_worldbank(out_dir: Path,
                    docs: Path,
                    vintage: str,
                    countries: list[str] | None = None) -> None:
    try:
        import wbdata
    except ImportError as exc:
        raise ImportError("Install wbdata: pip install wbdata") from exc

    countries = countries or DEFAULT_COUNTRIES
    out_dir.mkdir(parents = True, exist_ok = True)
    docs.mkdir(parents = True, exist_ok = True)

    target = out_dir / f"worldbank_panel_{vintage}.parquet"
    if target.exists():
        print(f"[wb] already fetched for vintage {vintage}; skip.")
        return

    indicators = {code: meta["name"] for code, meta in WB_INDICATORS.items()}

    try:
        df = wbdata.get_dataframe(indicators, country = countries).reset_index()
    except Exception as exc:
        print(f"[wb] FAILED ({exc})")
        return

    df["date"] = pd.to_datetime(df["date"]).dt.year
    df = df.rename(columns = {"date": "year"})

    df.to_parquet(target, index = False)
    print(f"[wb] {len(df):>5} rows x {df.shape[1]} cols -> {target.name}")

    for code, meta in WB_INDICATORS.items():
        _append_codebook(docs, {
            "source":         "World Bank Indicators",
            "series_id":      code,
            "description":    meta["name"],
            "units":          meta["units"],
            "frequency":      "annual",
            "transformation": "none",
            "vintage":        vintage,
            "access_date":    datetime.now(timezone.utc).isoformat(timespec = "seconds"),
            "coverage_start": str(int(df["year"].min())),
            "coverage_end":   str(int(df["year"].max())),
            "n_obs":          int(df[meta["name"]].notna().sum()),
            "license":        "CC BY 4.0",
            "citation":       f"World Bank, World Development Indicators, {code}, retrieved {vintage}.",
        })
