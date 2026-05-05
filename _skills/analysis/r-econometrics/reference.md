# R Econometrics Reference

Detailed code patterns for each estimator family. Use these as the canonical templates when generating analysis scripts.

## 1. Difference-in-Differences

### 1.1 Single-shock DiD (two periods, two groups)

```r
library(fixest)

mod <- feols(
  outcome ~ treated_post + controls | unit_id + period,
  data    = df,
  cluster = ~unit_id
)
etable(mod, tex = TRUE, fitstat = ~n + r2 + war2)
```

Report: coefficient on `treated_post`, cluster-robust SE, N, within-R^2.

### 1.2 Static DiD with staggered timing (Sun-Abraham)

`sunab` is the simplest heterogeneity-robust upgrade. It returns cohort-specific ATTs and an aggregated ATT.

```r
mod <- feols(
  outcome ~ sunab(cohort, period) | unit_id + period,
  data    = df,
  cluster = ~unit_id
)
summary(mod, agg = "att")            # overall ATT
summary(mod, agg = "cohort")         # by cohort
iplot(mod, ref.line = -1)            # event-study plot
```

`cohort` is the period of first treatment; never-treated units should have `cohort = Inf` or `NA`.

### 1.3 Dynamic effects (Callaway & Sant'Anna)

Most flexible: returns ATT(g, t) for every cohort-period cell, then aggregates.

```r
library(did)

att <- att_gt(
  yname        = "outcome",
  tname        = "period",
  idname       = "unit_id",
  gname        = "cohort",          # 0 or NA for never-treated
  data         = df,
  control_group = "notyettreated",  # or "nevertreated"
  est_method   = "dr",              # doubly robust
  bstrap       = TRUE,
  cband        = TRUE
)

# Aggregate to a single ATT
agg_simple <- aggte(att, type = "simple")
summary(agg_simple)

# Event-study aggregation
agg_es <- aggte(att, type = "dynamic", min_e = -5, max_e = 5)
ggdid(agg_es)
```

Report: simple ATT, dynamic ATT(e) for relative event time `e`, and the underlying ATT(g, t) when reviewers ask.

### 1.4 Imputation estimator (Borusyak, Jaravel, Spiess)

```r
library(didimputation)

est <- did_imputation(
  data      = df,
  yname     = "outcome",
  gname     = "cohort",
  tname     = "period",
  idname    = "unit_id",
  horizon   = TRUE
)
```

### 1.5 Continuous or non-binary treatment

```r
library(DIDmultiplegt)

did_multiplegt(
  df, Y = "outcome", G = "unit_id", T = "period", D = "treatment",
  placebo = 3, dynamic = 5, brep = 200
)
```

### 1.6 Pre-trend tests

For a static DiD, run an event study with leads:

```r
event <- feols(
  outcome ~ i(rel_time, ref = -1) | unit_id + period,
  data    = df,
  cluster = ~unit_id
)
iplot(event, ref.line = -1, main = "Pre-trends and dynamic effects")

# Roth (2022) honest pre-test (sensitivity analysis)
# library(HonestDiD)  # for full sensitivity bounds
```

Do not condition on a "clean" pre-trend test — that biases inference (Roth 2022).

## 2. Instrumental Variables

### 2.1 Cross-section 2SLS with first-stage diagnostics

```r
library(fixest)

iv <- feols(y ~ x_exog | endog ~ z, data = df, vcov = "hetero")

summary(iv)                 # 2SLS estimate
summary(iv, stage = 1)      # first stage
fitstat(iv, ~ ivf + ivwald) # F (KP), Wald
```

### 2.2 Panel IV with fixed effects

```r
iv <- feols(
  y ~ x_exog | unit + year | endog ~ z,
  data    = df,
  cluster = ~unit
)
summary(iv, stage = 1)
```

### 2.3 Weak-IV-robust inference

When the effective F is below 100, conventional 2SLS standard errors and t-tests are unreliable. Report at least one of:

```r
# Anderson-Rubin confidence set
library(ivmodel)
mod <- ivmodel(Y = df$y, D = df$endog, Z = as.matrix(df[, z_vars]),
               X = as.matrix(df[, x_exog]))
AR.test(mod, alpha = 0.05)

# tF-adjusted CIs (Lee et al. 2022)
library(ivDiag)
ivDiag(data = df, Y = "y", D = "endog", Z = z_vars, controls = x_exog)
```

### 2.4 First-stage reporting checklist

Always report:

- First-stage coefficient on each instrument with cluster-robust SE.
- Effective first-stage F (Olea-Pflueger), not the standard F.
- Sargan/Hansen J for over-identified models.
- Reduced-form regression of `y` on instruments (the AR test in disguise).

## 3. Regression Discontinuity

### 3.1 Sharp RDD with `rdrobust`

```r
library(rdrobust)
library(rddensity)

# Main estimate (MSE-optimal bandwidth, bias-corrected, robust SE)
rd <- rdrobust(y = df$outcome, x = df$running, c = 0)
summary(rd)

# Plot
rdplot(y = df$outcome, x = df$running, c = 0,
       binselect = "esmv", x.label = "Running variable", y.label = "Outcome")

# Density manipulation test (McCrary / Cattaneo-Jansson-Ma)
dens <- rddensity(X = df$running, c = 0)
summary(dens)
```

### 3.2 Bandwidth sensitivity

```r
h_opt  <- rd$bws[1, 1]
results <- lapply(c(h_opt / 2, h_opt, 2 * h_opt), function(h) {
  rdrobust(y = df$outcome, x = df$running, c = 0, h = h)
})
```

Report a small table: bandwidth, point estimate, robust SE, robust CI, effective N.

### 3.3 Fuzzy RDD

```r
rd <- rdrobust(y = df$outcome, x = df$running, c = 0, fuzzy = df$treatment)
summary(rd)
```

### 3.4 Covariate balance and donut RDD

- Run the same RDD with each pre-determined covariate as the outcome — they should be flat.
- Drop observations within a small window around the cutoff (donut) to test for sorting.

## 4. Inference with Few or Awkward Clusters

### 4.1 CR2 small-sample correction

```r
library(clubSandwich)

mod <- feols(y ~ treat | unit + year, data = df)
coef_test(mod, vcov = "CR2", cluster = df$state)
```

### 4.2 Wild cluster bootstrap

```r
library(fwildclusterboot)

mod <- feols(y ~ treat + controls | unit + year, data = df)
boot <- boottest(
  mod,
  param   = "treat",
  clustid = "state",
  B       = 9999,
  type    = "rademacher"
)
summary(boot)
```

### 4.3 Multi-way clustering

Only when there is real correlation along both dimensions:

```r
mod <- feols(y ~ treat | unit + year, data = df, cluster = ~state + year)
```

## 5. Tables and Figures

### 5.1 `etable` (best for `fixest` models)

```r
etable(
  list("Pooled" = m1, "Unit FE" = m2, "Two-way FE" = m3),
  tex      = TRUE,
  fitstat  = ~ n + r2 + war2,
  digits   = "r3",
  digits.stats = "r3",
  signif.code  = c("***" = 0.01, "**" = 0.05, "*" = 0.1),
  notes    = c("Cluster-robust SEs in parentheses."),
  file     = "results/main_table.tex",
  replace  = TRUE
)
```

### 5.2 `modelsummary` (works across model types)

```r
library(modelsummary)
modelsummary(
  list("(1)" = m1, "(2)" = m2, "(3)" = m3),
  stars   = c("*" = 0.1, "**" = 0.05, "***" = 0.01),
  coef_map = c("treat_post" = "Treatment x Post"),
  gof_map  = c("nobs", "r.squared", "adj.r.squared"),
  output  = "results/main_table.tex"
)
```

### 5.3 Coefficient and event-study plots

```r
iplot(event_model, ref.line = -1, ci.lty = 1)

# or with modelsummary
modelplot(list("Main" = m1, "Robust" = m2), coef_omit = "Intercept|fe_")
```

## 6. Reproducibility Conventions

- `set.seed(20240101)` at the top of any script that uses bootstrap or simulation.
- Pin packages with `renv::init()` for serious projects.
- Save fitted models as `.rds` next to the table they produce.
- Log filter Ns:

```r
log_filter <- function(df, label) {
  message(sprintf("[%s] N = %d, units = %d",
                  label, nrow(df), dplyr::n_distinct(df$unit_id)))
  df
}

df_clean <- df |>
  log_filter("raw") |>
  filter(year >= 2000) |>
  log_filter("post-2000") |>
  filter(!is.na(outcome)) |>
  log_filter("non-missing outcome")
```
