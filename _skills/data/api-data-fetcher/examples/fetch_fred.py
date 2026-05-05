"""fetch_fred.py

Vintage-aware FRED fetcher with content-addressed caching and
codebook logging. Writes one parquet per series to RAW with a
vintage suffix; never edits an existing file.
"""

from __future__ import annotations

import csv
import hashlib
import json
import os
import time
from datetime import datetime, timezone
from pathlib import Path

import pandas as pd

FRED_SERIES = {
    "GDPC1":    {"description": "Real GDP", "units": "Billions of Chained 2017 Dollars"},
    "UNRATE":   {"description": "Unemployment Rate", "units": "Percent"},
    "CPIAUCSL": {"description": "CPI All Urban Consumers", "units": "Index 1982-84=100"},
    "FEDFUNDS": {"description": "Federal Funds Effective Rate", "units": "Percent"},
    "DGS10":    {"description": "10-Year Treasury Constant Maturity Rate", "units": "Percent"},
}


def _cache_key(series_id: str, **kwargs) -> str:
    payload = {"series_id": series_id, **kwargs}
    return hashlib.sha256(json.dumps(payload, sort_keys = True).encode()).hexdigest()[:16]


def _append_codebook(docs: Path, row: dict) -> None:
    path = docs / "source_codebook.csv"
    write_header = not path.exists()
    with path.open("a", newline = "", encoding = "utf-8") as f:
        writer = csv.DictWriter(f, fieldnames = row.keys())
        if write_header:
            writer.writeheader()
        writer.writerow(row)


def fetch_fred(out_dir: Path, docs: Path, vintage: str) -> None:
    """Fetch all configured FRED series and log provenance."""
    try:
        from fredapi import Fred
    except ImportError as exc:
        raise ImportError("Install fredapi: pip install fredapi") from exc

    api_key = os.environ.get("FRED_API_KEY")
    if not api_key:
        raise RuntimeError("FRED_API_KEY is not set; add it to .env")

    out_dir.mkdir(parents = True, exist_ok = True)
    docs.mkdir(parents = True, exist_ok = True)
    fred = Fred(api_key = api_key)

    for series_id, meta in FRED_SERIES.items():
        target = out_dir / f"{series_id}_{vintage}.parquet"
        if target.exists():
            print(f"[fred] {series_id}: already fetched for vintage {vintage}; skip.")
            continue

        try:
            series = fred.get_series(series_id)
        except Exception as exc:
            print(f"[fred] {series_id}: FAILED ({exc})")
            continue

        df = series.rename("value").to_frame()
        df.index.name = "date"
        df.reset_index().to_parquet(target, index = False)

        _append_codebook(docs, {
            "source":         "FRED",
            "series_id":      series_id,
            "description":    meta["description"],
            "units":          meta["units"],
            "frequency":      "varies",          # use get_series_info if you want exact
            "transformation": "none",
            "vintage":        vintage,
            "access_date":    datetime.now(timezone.utc).isoformat(timespec = "seconds"),
            "coverage_start": str(df.index.min().date()),
            "coverage_end":   str(df.index.max().date()),
            "n_obs":          int(df["value"].notna().sum()),
            "license":        "Public domain (US Government)",
            "citation":       f"U.S. Federal Reserve Economic Data (FRED), series {series_id}, retrieved {vintage}.",
        })
        print(f"[fred] {series_id}: {len(df):>5} obs -> {target.name}")
        time.sleep(0.2)   # polite throttling
