# Python Panel Data Reference

Detailed code patterns for panel and causal-inference work in Python. Use these as canonical templates when generating analysis scripts.

## 1. `pyfixest` — the modern default

`pyfixest` is a Python port of R's `fixest`. It is the fastest and cleanest option for panel TWFE, event studies, and IV with high-dimensional fixed effects.

### 1.1 TWFE with `pyfixest`

```python
import pyfixest as pf

mod = pf.feols(
    "outcome ~ treat_post + controls | unit_id + year",
    data = df,
    vcov = {"CRV1": "unit_id"}     # cluster-robust at unit level
)
print(mod.summary())
```

### 1.2 Two-way clustering

```python
mod = pf.feols(
    "outcome ~ treat_post | unit_id + year",
    data = df,
    vcov = {"CRV1": ["unit_id", "year"]}
)
```

### 1.3 Event study (naive — only valid under uniform timing)

```python
mod = pf.feols(
    "outcome ~ i(rel_time, ref = -1) | unit_id + year",
    data = df,
    vcov = {"CRV1": "unit_id"}
)
pf.iplot(mod, ref_line = -1)
```

### 1.4 Sun-Abraham event study (heterogeneity-robust)

```python
# `cohort` is the period of first treatment; np.inf for never-treated
mod = pf.feols(
    "outcome ~ sunab(cohort, year) | unit_id + year",
    data = df,
    vcov = {"CRV1": "unit_id"}
)
pf.iplot(mod, ref_line = -1, title = "Sun-Abraham event study")
```

### 1.5 Panel IV with `pyfixest`

```python
iv = pf.feols(
    "outcome ~ x_exog | unit_id + year | endog ~ z",
    data = df,
    vcov = {"CRV1": "unit_id"}
)
print(iv.summary())
```

### 1.6 Tables across multiple specifications

```python
pf.etable(
    [m1, m2, m3],
    type      = "tex",
    file_name = "results/tables/main.tex",
    keep      = ["treat_post"],
    coef_fmt  = "b (se)",
    notes     = "Cluster-robust SEs at the unit level."
)
```

## 2. `linearmodels.PanelOLS`

Use when you want explicit `EntityEffects`, `TimeEffects`, RandomEffects, FirstDifferenceOLS, BetweenOLS, or formal panel diagnostics.

### 2.1 PanelOLS with two-way effects

```python
from linearmodels.panel import PanelOLS

df_idx = df.set_index(["unit_id", "year"])
mod = PanelOLS.from_formula(
    "outcome ~ 1 + treat_post + controls + EntityEffects + TimeEffects",
    data = df_idx
)
res = mod.fit(cov_type = "clustered", cluster_entity = True)
print(res.summary)
```

### 2.2 Random effects

```python
from linearmodels.panel import RandomEffects

re = RandomEffects.from_formula(
    "outcome ~ 1 + x1 + x2", data = df_idx
).fit(cov_type = "clustered", cluster_entity = True)
```

### 2.3 First-difference estimator

```python
from linearmodels.panel import FirstDifferenceOLS

fd = FirstDifferenceOLS.from_formula(
    "outcome ~ 1 + treat_post + x1", data = df_idx
).fit(cov_type = "clustered", cluster_entity = True)
```

### 2.4 Multi-way clustering

```python
res = mod.fit(
    cov_type        = "clustered",
    clusters        = df_idx.reset_index()[["unit_id", "year"]],
)
```

### 2.5 Comparing models

```python
from linearmodels.panel import compare
print(compare({"M1": res1, "M2": res2, "M3": res3}, precision = "std_errors"))
```

## 3. Cross-section IV with `linearmodels.IV2SLS`

```python
from linearmodels import IV2SLS

iv = IV2SLS.from_formula(
    "outcome ~ 1 + x_exog + [endog ~ z]",
    data = df
).fit(cov_type = "clustered", clusters = df.cluster)
print(iv.summary)

# First-stage and reduced-form diagnostics
print(iv.first_stage)
```

`linearmodels` reports the Kleibergen-Paap rk Wald F. For Olea-Pflueger effective F or Anderson-Rubin / CLR confidence sets, use R `ivDiag` or Stata `weakivtest`/`condivreg`, or implement AR by hand:

```python
# AR test via reduced-form regression
import statsmodels.api as sm

X = sm.add_constant(df[["z", "x_exog"]])
rf = sm.OLS(df.outcome, X).fit(cov_type = "cluster",
                                cov_kwds = {"groups": df.cluster})
print(rf.summary())
```

## 4. Wild Cluster Bootstrap

`pyfixest` integrates with the `wildboottest` package for inference with few clusters:

```python
import wildboottest as wb

wbt = wb.wildboottest(
    model     = mod,                # pyfixest result
    param     = "treat_post",
    cluster   = df.state,
    B         = 9999,
    weights_type = "rademacher",
    seed      = 20240101
)
print(wbt)
```

## 5. Balance Tables in Python

There is no `iebaltab` equivalent; build it explicitly:

```python
import numpy as np
import pandas as pd
from scipy import stats

def balance_table(df, treatment, variables):
    rows = []
    for v in variables:
        treated = df.loc[df[treatment] == 1, v]
        control = df.loc[df[treatment] == 0, v]
        diff = treated.mean() - control.mean()
        t, p = stats.ttest_ind(treated.dropna(), control.dropna(), equal_var = False)
        rows.append({
            "variable":   v,
            "treated_mean": treated.mean(),
            "control_mean": control.mean(),
            "difference":   diff,
            "t":            t,
            "p_value":      p,
            "n_treated":    treated.notna().sum(),
            "n_control":    control.notna().sum()
        })
    return pd.DataFrame(rows)

bal = balance_table(df, "treated", ["age", "female", "years_school", "baseline_y"])
bal.to_latex("results/tables/balance.tex", index = False, float_format = "%.3f")
```

## 6. Data Hygiene Conventions

- Always read with explicit dtypes when possible:
  ```python
  df = pd.read_parquet("data.parquet")  # parquet preserves types
  ```
- Set the panel index early and verify uniqueness:
  ```python
  df = df.set_index(["unit_id", "year"])
  assert df.index.is_unique
  ```
- Use `pathlib.Path(__file__).resolve().parents[N]` instead of hardcoded paths.
- Use a `Makefile` or `invoke` task to run scripts in order; this is Python's analogue to a Stata master do-file.
- Pin packages with `pyproject.toml` + `uv` or `requirements.txt` + `pip-tools`.

## 7. When to Switch Languages

Python is excellent for panel TWFE, event studies, IV with FE, and general data engineering. Switch to R or Stata when you need:

- Callaway-Sant'Anna with rich aggregation (`R: did`, `Stata: csdid`).
- BJS imputation with formal pretest (`R: didimputation`, `Stata: did_imputation`).
- de Chaisemartin-D'Haultfoeuille for continuous or reversible treatment.
- Olea-Pflueger effective F or AR/CLR confidence sets out of the box.
- DIME `iebaltab` / `ieddtab` style outputs.

In a multi-language project, run those steps via subprocess from a Python orchestrator and load the results back with `pandas`.
