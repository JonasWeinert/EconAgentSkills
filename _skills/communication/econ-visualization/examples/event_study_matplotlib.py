"""event_study_matplotlib.py

Sun-Abraham event study plot via pyfixest + matplotlib.
Writes paper/figs/fig_event_study.pdf.
"""

from __future__ import annotations

from pathlib import Path

import matplotlib.pyplot as plt
import pandas as pd
import pyfixest as pf

PROJECT = Path(__file__).resolve().parents[2]
FIGS    = PROJECT / "paper" / "figs"
FIGS.mkdir(parents = True, exist_ok = True)

df = pd.read_parquet(PROJECT / "data" / "processed" / "panel.parquet")

# Estimate
m = pf.feols(
    "y ~ sunab(cohort, year) | unit + year",
    data = df,
    vcov = {"CRV1": "unit"},
)

# Tidy: pyfixest's tidy returns a DataFrame indexed by coefficient name
coefs = m.tidy().reset_index()
coefs["rel_time"] = (coefs["Coefficient"]
                     .str.extract(r"::(-?\d+)").astype(int))

# Plot
fig, ax = plt.subplots(figsize = (6.5, 4.0))
ax.axhline(0, color = "grey", linestyle = "--", linewidth = 0.8)
ax.axvline(-0.5, color = "grey", linestyle = "--", linewidth = 0.8)
ax.errorbar(
    coefs["rel_time"], coefs["Estimate"],
    yerr   = 1.96 * coefs["Std. Error"],
    fmt    = "o",
    color  = "#0072B2",                 # Okabe-Ito blue
    capsize = 3,
    markersize = 5,
    linewidth  = 1.2,
)
ax.set_xlabel("Years relative to treatment")
ax.set_ylabel("ATT(e)")
ax.spines[["top", "right"]].set_visible(False)
fig.text(0.02, 0.02,
         "Sun-Abraham (2021); 95% CIs from cluster-robust SEs (cluster: unit).",
         fontsize = 8, color = "grey")
fig.tight_layout(rect = [0, 0.04, 1, 1])
fig.savefig(FIGS / "fig_event_study.pdf")
print(f"Wrote {FIGS / 'fig_event_study.pdf'}")
