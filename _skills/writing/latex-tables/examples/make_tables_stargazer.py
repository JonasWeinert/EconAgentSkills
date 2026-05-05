"""make_tables_stargazer.py

Produce a regression table from statsmodels OLS via stargazer.
Use when models live in statsmodels (not pyfixest); stargazer
gives multi-spec tables with stars, custom notes, and renaming.
"""

from __future__ import annotations

from pathlib import Path

import pandas as pd
import statsmodels.api as sm
from stargazer.stargazer import Stargazer

PROJECT = Path(__file__).resolve().parents[2]
TABS    = PROJECT / "paper" / "tabs"
TABS.mkdir(parents = True, exist_ok = True)

df = pd.read_parquet(PROJECT / "data" / "processed" / "analysis.parquet")


def fit(formula_x: list[str]) -> "sm.regression.linear_model.RegressionResultsWrapper":
    X = sm.add_constant(df[formula_x])
    return sm.OLS(df["y"], X).fit(
        cov_type = "cluster",
        cov_kwds = {"groups": df["unit"]},
    )


m1 = fit(["treat"])
m2 = fit(["treat", "x1", "x2"])
m3 = fit(["treat", "x1", "x2", "x3"])

s = Stargazer([m1, m2, m3])
s.title("Effect of treatment on outcome")
s.custom_columns(["Baseline", "+ Controls", "+ Region#Year FE"], [1, 1, 1])
s.show_model_numbers(False)
s.covariate_order(["treat", "x1", "x2", "x3", "const"])
s.rename_covariates({"treat": "Treatment x Post"})
s.add_line("Cluster", ["Unit", "Unit", "Unit"])
s.show_degrees_of_freedom(False)
s.add_custom_notes(["Cluster-robust SEs in parentheses, clustered by unit."])
s.significance_levels([0.10, 0.05, 0.01])

(TABS / "table_main_stargazer.tex").write_text(s.render_latex(), encoding = "utf-8")
print(f"Wrote {TABS / 'table_main_stargazer.tex'}")
