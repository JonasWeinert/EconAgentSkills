"""iv_panel_pyfixest.py

Panel IV with `pyfixest`, including first-stage diagnostics.

For Olea-Pflueger effective F or Anderson-Rubin / CLR confidence
sets, switch to R `ivDiag` or Stata `weakivtest`/`condivreg`.
"""

from __future__ import annotations

import numpy as np
import pandas as pd
import pyfixest as pf

rng = np.random.default_rng(20240101)

# ---- 1. Simulate panel data with one endogenous regressor ----
n_units, n_years = 300, 6
unit_id = np.repeat(np.arange(n_units), n_years)
year    = np.tile(np.arange(2018, 2018 + n_years), n_units)

z       = rng.normal(size = len(unit_id))           # instrument
unobs   = rng.normal(size = len(unit_id))
endog   = 0.4 * z + 0.7 * unobs + rng.normal(size = len(unit_id))
x_exog  = rng.normal(size = len(unit_id))
y       = 1.2 * endog + 0.5 * x_exog + 0.8 * unobs + rng.normal(size = len(unit_id))

df = pd.DataFrame({
    "unit_id": unit_id, "year": year,
    "y": y, "endog": endog, "x_exog": x_exog, "z": z,
})

# ---- 2. First stage (always shown) ---------------------------
fs = pf.feols(
    "endog ~ z + x_exog | unit_id + year",
    data = df,
    vcov = {"CRV1": "unit_id"},
)
print("First stage:")
print(fs.summary())

# ---- 3. Panel 2SLS via pyfixest ------------------------------
iv = pf.feols(
    "y ~ x_exog | unit_id + year | endog ~ z",
    data = df,
    vcov = {"CRV1": "unit_id"},
)
print("\nPanel 2SLS:")
print(iv.summary())

# ---- 4. Reduced form (= AR test by construction) -------------
rf = pf.feols(
    "y ~ z + x_exog | unit_id + year",
    data = df,
    vcov = {"CRV1": "unit_id"},
)
print("\nReduced form:")
print(rf.summary())

# ---- 5. Reporting checklist for IV tables --------------------
# - First stage coefficient on z and cluster-robust SE.
# - First-stage F (use pyfixest fitstat or compute manually).
# - Reduced form regression of y on z.
# - When effective F < 100: switch to R/Stata for AR / tF CIs.
