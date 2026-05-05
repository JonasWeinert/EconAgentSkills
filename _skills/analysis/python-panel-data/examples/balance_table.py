"""balance_table.py

DIME-style balance table in Python. There is no `iebaltab` in
Python, so build it with pandas + scipy and export to LaTeX.
"""

from __future__ import annotations

from pathlib import Path

import numpy as np
import pandas as pd
from scipy import stats

rng = np.random.default_rng(20240101)


def balance_table(df: pd.DataFrame,
                   treatment: str,
                   variables: list[str]) -> pd.DataFrame:
    """Two-arm balance table with mean, t-stat, and p-value."""
    rows = []
    for v in variables:
        treated = df.loc[df[treatment] == 1, v].dropna()
        control = df.loc[df[treatment] == 0, v].dropna()
        diff = treated.mean() - control.mean()
        t, p = stats.ttest_ind(treated, control, equal_var = False)
        rows.append({
            "variable":     v,
            "treated_mean": treated.mean(),
            "control_mean": control.mean(),
            "difference":   diff,
            "t":            t,
            "p_value":      p,
            "n_treated":    len(treated),
            "n_control":    len(control),
        })
    return pd.DataFrame(rows)


# ---- Demo with synthetic baseline data -----------------------
n = 1000
df = pd.DataFrame({
    "treated":      rng.binomial(1, 0.5, n),
    "age":          rng.normal(40, 12, n),
    "female":       rng.binomial(1, 0.52, n),
    "years_school": rng.normal(11, 3, n),
    "baseline_y":   rng.normal(0, 1, n),
})

bal = balance_table(df, "treated",
                     ["age", "female", "years_school", "baseline_y"])
print(bal.round(3))

# ---- Export to LaTeX -----------------------------------------
out = Path("results/tables/balance.tex")
out.parent.mkdir(parents = True, exist_ok = True)
bal.to_latex(out, index = False, float_format = "%.3f",
             caption = "Baseline balance",
             label = "tab:balance")
