"""fetch_oecd_sdmx.py

OECD via the SDMX endpoint. Useful for cross-country panels at
quarterly frequency.

Browse the OECD data structure at https://stats.oecd.org or
https://data-viewer.oecd.org. The dataflow code (e.g. QNA) and
the dimension keys are part of the API contract.
"""

from __future__ import annotations

from datetime import datetime, timezone
from pathlib import Path

import pandas as pd


def fetch_oecd_qna(out_dir: Path, vintage: str,
                   countries: list[str] | None = None) -> Path | None:
    """Quarterly National Accounts: GDP volume index, QoQ annualized."""
    try:
        import pandasdmx as sdmx
    except ImportError as exc:
        raise ImportError("Install pandasdmx: pip install pandasdmx") from exc

    out_dir.mkdir(parents = True, exist_ok = True)
    target = out_dir / f"oecd_qna_{vintage}.parquet"
    if target.exists():
        return target

    countries = countries or ["USA", "GBR", "DEU", "FRA", "JPN"]
    oecd = sdmx.Request("OECD")

    key = {
        "LOCATION":  countries,
        "SUBJECT":   "B1_GE",          # GDP at market prices
        "MEASURE":   "VPVOBARSA",      # Volume, percentage change, annual rate
        "FREQUENCY": "Q",
    }
    msg = oecd.data("QNA", key = key, params = {"startTime": "2000"})
    df  = sdmx.to_pandas(msg).reset_index()

    if df.empty:
        print("[oecd] empty response; skip")
        return None

    df.to_parquet(target, index = False)
    print(f"[oecd] {len(df):>5} rows -> {target.name}"
          f"  (retrieved {datetime.now(timezone.utc).isoformat(timespec='seconds')})")
    return target


if __name__ == "__main__":
    fetch_oecd_qna(out_dir = Path("data/raw/oecd"), vintage = datetime.utcnow().date().isoformat())
