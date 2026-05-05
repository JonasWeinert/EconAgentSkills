"""sample_construction_logging.py

The `log_filter` pattern: every filter records the resulting N and
the number of distinct units. The output of these prints belongs in
the decisions log of the script.
"""

from __future__ import annotations

import pandas as pd


def log_filter(df: pd.DataFrame, label: str, unit_col: str = "firm_id") -> pd.DataFrame:
    n_rows  = len(df)
    n_units = df[unit_col].nunique() if unit_col in df.columns else None
    if n_units is not None:
        print(f"[{label:<40s}] N = {n_rows:>9,d}  units = {n_units:>7,d}")
    else:
        print(f"[{label:<40s}] N = {n_rows:>9,d}")
    return df


# Demo on a tiny synthetic frame
raw = pd.DataFrame({
    "firm_id":   [1, 1, 2, 2, 3, 3, 4, 4, 5, 5],
    "year":      [2018, 2019, 2018, 2019, 2018, 2019, 2018, 2019, 2018, 2019],
    "industry":  ["A", "A", "B", "B", None, "C", "D", "D", "E", "E"],
    "revenue":   [100, 110, 200, -5,  50,   60,   0,    80,  120, 130],
    "outcome":   [1.0, 1.1, 0.9, 1.0, 0.8, 0.85, 1.2, None, 0.95, 1.0],
})

clean = (
    raw
    .pipe(log_filter, "raw")
    .query("year >= 2018")
    .pipe(log_filter, "year >= 2018")
    .dropna(subset=["industry"])
    .pipe(log_filter, "non-missing industry")
    .query("revenue > 0")
    .pipe(log_filter, "revenue > 0")
    .dropna(subset=["outcome"])
    .pipe(log_filter, "non-missing outcome")
)

# Sanity checks downstream code depends on
assert clean.duplicated(["firm_id", "year"]).sum() == 0
assert clean["firm_id"].notna().all()
assert (clean["revenue"] > 0).all()

print("\nFinal sample:")
print(clean)
