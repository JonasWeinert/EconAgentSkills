"""make_tables_pyfixest.py

Produce all paper tables from one Python script via pyfixest.
Writes .tex files directly to paper/tabs/. DIME "full
replicability" tier: no manual editing between code and PDF.
"""

from __future__ import annotations

from pathlib import Path

import pandas as pd
import pyfixest as pf

PROJECT = Path(__file__).resolve().parents[2]
TABS    = PROJECT / "paper" / "tabs"
TABS.mkdir(parents = True, exist_ok = True)

df = pd.read_parquet(PROJECT / "data" / "processed" / "analysis.parquet")

# ---- Main results ---------------------------------------------
m1 = pf.feols("y ~ treat | unit + year",
              data = df, vcov = {"CRV1": "unit"})
m2 = pf.feols("y ~ treat + x1 + x2 | unit + year",
              data = df, vcov = {"CRV1": "unit"})
m3 = pf.feols("y ~ treat + x1 + x2 | unit + year + region^year",
              data = df, vcov = {"CRV1": "unit"})

pf.etable(
    [m1, m2, m3],
    type        = "tex",
    file_name   = str(TABS / "table_main.tex"),
    keep        = ["treat"],
    coef_fmt    = "b (se)",
    notes       = "Cluster-robust standard errors in parentheses, clustered by unit.",
)

# ---- Robustness -----------------------------------------------
r1 = pf.feols("y ~ treat + x1 + x2 | unit + year",
              data = df, vcov = {"CRV1": "unit"})
r2 = pf.feols("y ~ treat + x1 + x2 | unit + year",
              data = df, vcov = {"CRV1": ["unit", "year"]})
r3 = pf.feols("y ~ treat + x1 + x2 | unit + year",
              data = df.query("rural == 1"), vcov = {"CRV1": "unit"})

pf.etable(
    [r1, r2, r3],
    type        = "tex",
    file_name   = str(TABS / "table_robustness.tex"),
    keep        = ["treat"],
    coef_fmt    = "b (se)",
    notes       = "Standard errors in parentheses.",
)

print(f"All tables written to {TABS}")
