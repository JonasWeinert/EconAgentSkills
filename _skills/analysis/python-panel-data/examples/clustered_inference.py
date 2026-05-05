"""clustered_inference.py

Inference patterns: one-way cluster, two-way cluster, and wild
cluster bootstrap. Use the bootstrap when there are few clusters
(rule of thumb: < 30) or treatment is concentrated in a few clusters.
"""

from __future__ import annotations

import numpy as np
import pandas as pd
import pyfixest as pf

rng = np.random.default_rng(20240101)

# ---- 1. Simulate data with only 12 clusters (states) ---------
n_states, n_per = 12, 200
state = np.repeat(np.arange(n_states), n_per)
treat = (state < 3).astype(int)                      # 3 treated states
state_shock = rng.normal(size = n_states, scale = 0.6)[state]
x  = rng.normal(size = len(state))
y  = 0.3 * treat + 0.5 * x + state_shock + rng.normal(size = len(state))

df = pd.DataFrame({"state": state, "treat": treat, "x": x, "y": y})

# ---- 2. One-way cluster-robust SE (likely undercovers) -------
m_cr = pf.feols("y ~ treat + x", data = df, vcov = {"CRV1": "state"})
print("Cluster-robust:")
print(m_cr.summary())

# ---- 3. Wild cluster bootstrap via the wildboottest package --
try:
    from wildboottest.wildboottest import wildboottest
except ImportError as exc:
    raise ImportError(
        "Install wildboottest: pip install wildboottest"
    ) from exc

# Build the model matrix manually for wildboottest
import statsmodels.api as sm
X = sm.add_constant(df[["treat", "x"]])
ols = sm.OLS(df["y"], X).fit()

wbt = wildboottest(
    model        = ols,
    cluster      = df["state"],
    param        = "treat",
    B            = 9999,
    bootstrap_type = "11",
    impose_null  = True,
)
print("\nWild cluster bootstrap (Rademacher, 9999 reps):")
print(wbt)

# ---- 4. Multi-way clustering ---------------------------------
# (Not meaningful with simulated data above, but illustrates syntax.)
m_two = pf.feols("y ~ treat + x", data = df,
                 vcov = {"CRV1": ["state"]})  # add second dim if needed
