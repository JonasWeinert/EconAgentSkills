"""twfe_pyfixest.py

Single-shock TWFE DiD with `pyfixest`.
Use only when treatment timing is uniform across treated units.
For staggered timing see event_study_sun_abraham.py.
"""

from __future__ import annotations

import numpy as np
import pandas as pd
import pyfixest as pf

rng = np.random.default_rng(20240101)

# ---- 1. Simulate a balanced panel with one treatment date ----
n_units, n_years, treat_year = 200, 10, 6

unit_id = np.repeat(np.arange(n_units), n_years)
year    = np.tile(np.arange(1, n_years + 1), n_units)
treated = (unit_id < n_units // 2).astype(int)
post    = (year >= treat_year).astype(int)
treat_post = treated * post

unit_fe = rng.normal(size = n_units)[unit_id]
year_fe = rng.normal(size = n_years)[year - 1]
eps     = rng.normal(size = n_units * n_years)
outcome = 0.8 * treat_post + unit_fe + year_fe + eps

df = pd.DataFrame({
    "unit_id":    unit_id,
    "year":       year,
    "treated":    treated,
    "post":       post,
    "treat_post": treat_post,
    "outcome":    outcome,
})

# ---- 2. Pre-flight assertions --------------------------------
assert df.duplicated(["unit_id", "year"]).sum() == 0
assert len(df) == n_units * n_years

# ---- 3. Main TWFE specification ------------------------------
m_main = pf.feols(
    "outcome ~ treat_post | unit_id + year",
    data = df,
    vcov = {"CRV1": "unit_id"},
)
print(m_main.summary())

# ---- 4. Two-way clustering (robustness) ----------------------
m_two = pf.feols(
    "outcome ~ treat_post | unit_id + year",
    data = df,
    vcov = {"CRV1": ["unit_id", "year"]},
)

# ---- 5. Event-study version (validates parallel trends) ------
df["rel_time"] = df["year"] - treat_year
m_event = pf.feols(
    "outcome ~ i(rel_time, treated, ref = -1) | unit_id + year",
    data = df,
    vcov = {"CRV1": "unit_id"},
)
pf.iplot(m_event, ref_line = -1, title = "Event study: pre-trends and dynamics")

# ---- 6. Reporting --------------------------------------------
pf.etable(
    [m_main, m_two],
    type      = "md",
    coef_fmt  = "b (se)",
    keep      = ["treat_post"],
    notes     = "Cluster-robust SEs in parentheses.",
)
