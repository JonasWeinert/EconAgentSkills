"""fetch_bls.py

BLS Public Data API client. Register for a free key at
https://www.bls.gov/developers/ for higher rate limits.
"""

from __future__ import annotations

import csv
import os
from datetime import datetime, timezone
from pathlib import Path

import pandas as pd
import requests

BLS_SERIES = {
    "LNS14000000": {"description": "Civilian Unemployment Rate (16+)", "units": "Percent"},
    "CES0000000001": {"description": "Total Nonfarm Employment (Establishment Survey)",
                      "units": "Thousands of persons"},
    "LNS11300000": {"description": "Labor Force Participation Rate (16+)", "units": "Percent"},
}


def _post_bls(payload: dict) -> dict:
    r = requests.post(
        "https://api.bls.gov/publicAPI/v2/timeseries/data/",
        json = payload, timeout = 30,
    )
    r.raise_for_status()
    return r.json()


def fetch_bls(out_dir: Path,
              docs: Path,
              vintage: str,
              start_year: int = 2000,
              end_year: int | None = None) -> Path:
    out_dir.mkdir(parents = True, exist_ok = True)
    docs.mkdir(parents = True, exist_ok = True)
    end_year = end_year or datetime.utcnow().year

    target = out_dir / f"bls_{vintage}.parquet"
    if target.exists():
        return target

    payload = {
        "seriesid":         list(BLS_SERIES.keys()),
        "startyear":        str(start_year),
        "endyear":          str(end_year),
        "registrationkey":  os.environ.get("BLS_API_KEY", ""),
    }
    data = _post_bls(payload)

    if data.get("status") != "REQUEST_SUCCEEDED":
        raise RuntimeError(f"BLS API error: {data.get('message')}")

    rows = []
    for series in data["Results"]["series"]:
        sid = series["seriesID"]
        for obs in series["data"]:
            rows.append({
                "series_id": sid,
                "year":      int(obs["year"]),
                "period":    obs["period"],
                "value":     float(obs["value"]),
            })
    df = pd.DataFrame(rows)
    df.to_parquet(target, index = False)
    print(f"[bls] {len(df):>5} obs -> {target.name}")

    # Append to source codebook
    cb = docs / "source_codebook.csv"
    write_header = not cb.exists()
    with cb.open("a", newline = "", encoding = "utf-8") as f:
        writer = csv.DictWriter(f, fieldnames = [
            "source", "series_id", "description", "units", "frequency",
            "transformation", "vintage", "access_date",
            "coverage_start", "coverage_end", "n_obs", "license", "citation",
        ])
        if write_header:
            writer.writeheader()
        for sid, meta in BLS_SERIES.items():
            sub = df.query("series_id == @sid")
            if sub.empty:
                continue
            writer.writerow({
                "source":         "BLS",
                "series_id":      sid,
                "description":    meta["description"],
                "units":          meta["units"],
                "frequency":      "monthly",
                "transformation": "none",
                "vintage":        vintage,
                "access_date":    datetime.now(timezone.utc).isoformat(timespec = "seconds"),
                "coverage_start": str(sub["year"].min()),
                "coverage_end":   str(sub["year"].max()),
                "n_obs":          int(len(sub)),
                "license":        "Public domain (US Government)",
                "citation":       f"U.S. Bureau of Labor Statistics, series {sid}, retrieved {vintage}.",
            })

    return target
