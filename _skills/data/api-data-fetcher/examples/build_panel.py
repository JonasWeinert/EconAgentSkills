"""build_panel.py

Combine raw FRED + World Bank parquet files into one
analysis-ready long-format panel, validated against a schema.
"""

from __future__ import annotations

from pathlib import Path

import pandas as pd

LONG_COLUMNS = ["entity", "date", "indicator", "value", "source", "vintage"]


def _load_fred_long(raw_dir: Path, vintage: str) -> pd.DataFrame:
    fred_files = list(raw_dir.glob(f"fred/*_{vintage}.parquet"))
    rows = []
    for path in fred_files:
        series_id = path.stem.replace(f"_{vintage}", "")
        df = pd.read_parquet(path)
        df["entity"]    = "USA"
        df["indicator"] = series_id
        df["source"]    = "FRED"
        df["vintage"]   = vintage
        rows.append(df.rename(columns = {"date": "date", "value": "value"}))
    if not rows:
        return pd.DataFrame(columns = LONG_COLUMNS)
    return pd.concat(rows, ignore_index = True)[LONG_COLUMNS]


def _load_wb_long(raw_dir: Path, vintage: str) -> pd.DataFrame:
    wb_files = list(raw_dir.glob(f"worldbank/worldbank_panel_{vintage}.parquet"))
    if not wb_files:
        return pd.DataFrame(columns = LONG_COLUMNS)
    df = pd.read_parquet(wb_files[0])
    long = df.melt(
        id_vars     = ["country", "year"],
        var_name    = "indicator",
        value_name  = "value",
    )
    long = long.rename(columns = {"country": "entity", "year": "date"})
    long["source"]  = "WB"
    long["vintage"] = vintage
    return long[LONG_COLUMNS]


def build_macro_panel(raw_dir: Path,
                       int_dir: Path,
                       final_dir: Path,
                       docs_dir: Path,
                       vintage: str) -> Path:
    int_dir.mkdir(parents = True, exist_ok = True)
    final_dir.mkdir(parents = True, exist_ok = True)

    fred_long = _load_fred_long(raw_dir, vintage)
    wb_long   = _load_wb_long(raw_dir, vintage)
    panel     = pd.concat([fred_long, wb_long], ignore_index = True)

    # Schema validation (hand-rolled to avoid mandatory pandera dep)
    expected_cols = set(LONG_COLUMNS)
    assert set(panel.columns) == expected_cols, (
        f"Schema mismatch: {set(panel.columns) ^ expected_cols}"
    )
    assert panel["vintage"].nunique() == 1, "Mixed vintages in one panel"
    assert panel["entity"].notna().all()
    assert panel["indicator"].notna().all()

    intermediate = int_dir / f"macro_panel_{vintage}.parquet"
    final = final_dir / "macro_panel.parquet"

    panel.to_parquet(intermediate, index = False)
    panel.to_parquet(final, index = False)

    print(f"[panel] {len(panel):>6} rows, "
          f"{panel['indicator'].nunique()} indicators, "
          f"{panel['entity'].nunique()} entities")
    print(f"[panel] -> {intermediate.relative_to(int_dir.parent)}")
    print(f"[panel] -> {final.relative_to(final_dir.parent)}")

    return final
