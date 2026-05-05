"""event_study_sun_abraham.py

Heterogeneity-robust event study via Sun & Abraham (2021),
implemented in `pyfixest` with the `sunab()` term.

Use this whenever cohorts adopt treatment at different dates and
effects may vary by cohort or time since treatment. Plain TWFE
event studies are biased in this setting.
"""

from __future__ import annotations

import numpy as np
import pandas as pd
import pyfixest as pf

rng = np.random.default_rng(20240101)

# ---- 1. Simulate staggered adoption with heterogeneous effects ----
n_units, n_years = 300, 12
unit_id = np.repeat(np.arange(n_units), n_years)
year    = np.tile(np.arange(1, n_years + 1), n_units)

# Random adoption cohorts: never-treated, early, mid, late
cohort_pool = np.array([np.inf, 4, 7, 10])
cohort_assignment = rng.choice(cohort_pool, size = n_units,
                               p = [0.4, 0.2, 0.2, 0.2])
cohort = cohort_assignment[unit_id]

rel_time     = np.where(np.isfinite(cohort), year - cohort, np.nan)
treated_now  = (np.isfinite(cohort)) & (year >= cohort)

unit_fe = rng.normal(size = n_units)[unit_id]
year_fe = rng.normal(size = n_years)[year - 1]

# Heterogeneous, dynamic effect: late cohorts get larger effects
effect = np.where(
    treated_now,
    0.3 + 0.05 * (rel_time + 1) + 0.04 * (cohort - 4),
    0,
)
outcome = effect + unit_fe + year_fe + rng.normal(size = len(unit_id))

df = pd.DataFrame({
    "unit_id":  unit_id,
    "year":     year,
    "cohort":   cohort,        # np.inf for never-treated
    "outcome":  outcome,
})

# ---- 2. Sun-Abraham via pyfixest -----------------------------
m_sa = pf.feols(
    "outcome ~ sunab(cohort, year) | unit_id + year",
    data = df,
    vcov = {"CRV1": "unit_id"},
)
print(m_sa.summary())

pf.iplot(m_sa, ref_line = -1, title = "Sun-Abraham event study",
         xlab = "Years since treatment", ylab = "ATT(e)")

# ---- 3. Aggregated overall ATT --------------------------------
print(m_sa.tidy())              # full coefficient table
# Aggregated ATT (overall): pf has helpers; you can also average
# the post-treatment leads weighted by cell counts.
