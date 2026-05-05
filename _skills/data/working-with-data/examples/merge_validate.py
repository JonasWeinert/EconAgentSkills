"""merge_validate.py

Pandas merges with explicit cardinality validation and full
inspection of non-matches. Works as a runnable demo on synthetic
data; adapt to real datasets by replacing the two `make_*` calls.
"""

from __future__ import annotations

import pandas as pd


def make_master(seed: int = 0) -> pd.DataFrame:
    return pd.DataFrame({
        "hhid": [1, 2, 3, 4, 5],
        "region": ["N", "N", "S", "S", "E"],
        "treated": [0, 1, 0, 1, 0],
    })


def make_using() -> pd.DataFrame:
    return pd.DataFrame({
        "hhid":      [1, 2, 3, 4, 6],     # note: 6 only in using; 5 only in master
        "outcome_y": [1.2, 1.4, 0.9, 1.1, 0.7],
    })


def merge_with_validation(master: pd.DataFrame,
                           using: pd.DataFrame,
                           on: str | list[str],
                           how: str = "left",
                           validate: str = "1:1") -> pd.DataFrame:
    """Merge with hard-coded checks: keys are unique, _merge inspected."""
    keys = [on] if isinstance(on, str) else list(on)

    assert master.duplicated(keys).sum() == 0, f"master duplicated on {keys}"
    assert using.duplicated(keys).sum() == 0,  f"using duplicated on {keys}"
    assert master[keys].notna().all().all(),    f"master has NA in {keys}"
    assert using[keys].notna().all().all(),     f"using has NA in {keys}"

    out = master.merge(using, on=on, how=how, validate=validate, indicator=True)

    counts = out["_merge"].value_counts()
    n_only_master = int(counts.get("left_only", 0))
    n_only_using  = int(counts.get("right_only", 0))
    n_both        = int(counts.get("both", 0))
    print(f"[merge:{how}/{validate} on {keys}] "
          f"both={n_both}, only_master={n_only_master}, only_using={n_only_using}")

    if n_only_master > 0 or n_only_using > 0:
        print("  -- Non-matches; review or document the reason. --")

    return out.drop(columns="_merge")


if __name__ == "__main__":
    master = make_master()
    using  = make_using()

    out = merge_with_validation(master, using, on="hhid", how="left", validate="1:1")
    print(out)
