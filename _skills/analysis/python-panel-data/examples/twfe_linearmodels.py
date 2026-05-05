"""twfe_linearmodels.py

Two-way fixed effects panel model with `linearmodels.PanelOLS`.
Use this when you want explicit Entity/Time effects, formal panel
diagnostics, or compatibility with random effects / first differences.
"""

from __future__ import annotations

import numpy as np
import pandas as pd
from linearmodels.panel import PanelOLS

rng = np.random.default_rng(20240101)

# ---- 1. Simulate a balanced firm-year panel ------------------
n_firms, n_years = 250, 8
firm_id = np.repeat(np.arange(n_firms), n_years)
year    = np.tile(np.arange(2010, 2010 + n_years), n_firms)

treated = (firm_id < n_firms // 2).astype(int)
post    = (year >= 2014).astype(int)
treat_post = treated * post

firm_fe = rng.normal(scale = 1.0, size = n_firms)[firm_id]
year_fe = rng.normal(scale = 0.4, size = n_years)[year - 2010]
x1      = rng.normal(size = len(firm_id))
eps     = rng.normal(size = len(firm_id))

outcome = 0.6 * treat_post + 0.3 * x1 + firm_fe + year_fe + eps

df = pd.DataFrame({
    "firm_id":    firm_id,
    "year":       year,
    "treat_post": treat_post,
    "x1":         x1,
    "outcome":    outcome,
}).set_index(["firm_id", "year"])

# ---- 2. Assert panel structure -------------------------------
assert df.index.is_unique

# ---- 3. PanelOLS with two-way FE -----------------------------
mod = PanelOLS.from_formula(
    "outcome ~ 1 + treat_post + x1 + EntityEffects + TimeEffects",
    data = df,
)
res = mod.fit(cov_type = "clustered", cluster_entity = True)
print(res.summary)

# ---- 4. Two-way clustering -----------------------------------
clusters = df.reset_index()[["firm_id", "year"]]
res_two = mod.fit(cov_type = "clustered", clusters = clusters)
print(res_two.summary)

# ---- 5. Compare specifications --------------------------------
from linearmodels.panel import compare
print(compare({"Entity-cluster": res, "Two-way": res_two},
              precision = "std_errors"))
