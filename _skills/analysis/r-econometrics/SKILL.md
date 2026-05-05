---
name: r-econometrics
description: >
  Generates rigorous, modern, reproducible R code for causal inference and panel econometrics with `fixest`, heterogeneity-robust DiD estimators (Callaway-Sant'Anna, Sun-Abraham, BJS, de Chaisemartin-D'Haultfoeuille), weak-IV-robust inference, optimal-bandwidth RDD via `rdrobust`, and wild cluster bootstrap.
  Use when the user asks for IV, DiD, event studies, RDD, TWFE, staggered treatment, clustered or wild-bootstrap inference, instrumental variables, parallel trends, first-stage F, AR confidence sets, or publication-ready R regression output.
workflow_stage: analysis
compatibility:
  - claude-code
  - cursor
  - codex
  - gemini-cli
author: JonasWeinert
version: 2.0.0
tags:
  - R
  - econometrics
  - causal-inference
  - fixest
  - did
  - iv
  - rdd
  - event-study
---

# R Econometrics

Generate rigorous, modern, reproducible R code for causal inference and panel econometrics. Default to estimators that are robust to the failure modes of 2010-era TWFE, weak instruments, and naive cluster-robust inference.

## Operating Principles

1. **Identification before code.** State the estimand, the source of identifying variation, and the threats to identification before writing any model. Write these as comments at the top of the script.
2. **Modern estimators by default.** Plain TWFE under staggered treatment is biased; weak IV with F just above 10 is unreliable; RDD without `rdrobust` understates uncertainty. Use heterogeneity-robust DiD, weak-IV-robust inference, and bias-corrected RDD unless the user explicitly opts out.
3. **Match inference to design.** Cluster at the level of treatment assignment or sampling. With few clusters (rule of thumb < 30), use wild cluster bootstrap, not cluster-robust SEs.
4. **Make every script runnable.** Set seeds, declare paths, write to `results/`, separate one-time data prep from estimation, and never silently drop observations.
5. **Show the alternatives.** When two reasonable estimators exist (TWFE vs Callaway-Sant'Anna; CR1 vs wild bootstrap), report both and explain divergence.

## Decision Policy

This skill follows the repo-wide [Agent Policy](../../AGENT_POLICY.md).

**ASK before proceeding** (blocking):

1. Estimand and identification strategy (RCT / IV / DiD / RDD / descriptive).
2. Treatment timing — uniform shock vs staggered adoption (drives the choice between TWFE and CS / SA / BJS).
3. Cluster level for inference (treatment-assignment level by default).
4. Sample restrictions to apply (each is irreversible without re-running).

**DEFAULT + flag** (use this default; tell the user how to override):

- `feols` from `fixest` over `lm` for panel models.
- Heterogeneity-robust DiD (Callaway-Sant'Anna by default) when timing is staggered; TWFE only when the user opts in.
- `rdrobust` with MSE-optimal bandwidth for sharp RDD; report sensitivity at h/2, h, 2h.
- Wild cluster bootstrap (`fwildclusterboot`) when there are fewer than 30 clusters.
- Output to `results/` (tables) and `results/figures/` (vector PDF).

**DOCUMENT and proceed** (write into the decisions log):

- The chosen estimator within an approved family (e.g. CS vs SA vs BJS).
- The omitted period in event studies (default: `-1`).
- Inference type (CR1, CR2, wild bootstrap) and cluster level.
- Any composition shifts that emerged (e.g. dropped never-treated cohorts because too small).

`PROCEED` items: `set.seed(20240101)`, `here::here()` paths, `theme_paper()` for figures, asserting panel structure with `n_distinct` before estimation.

## Pre-flight Checklist

Before writing code, confirm with the user — and write the answers as a header block:

- **Estimand.** ATT, LATE, ITT, sharp/fuzzy RD effect, or descriptive?
- **Unit of observation and panel keys.** Assert uniqueness (`fixest::demean` will silently aggregate; `dplyr::n_distinct(unit, time)` should equal `nrow(df)` for a balanced panel).
- **Treatment timing.** Single shock, simultaneous adoption, staggered adoption, or reversible?
- **Identifying variation.** Which comparisons drive the coefficient? What is the implicit control group?
- **Clustering level.** Where is treatment assigned, or where does within-group correlation live?
- **Sample restrictions.** Document every filter and report the resulting N at each step.
- **Output target.** Working paper, slides, journal submission, or exploratory.

## Estimator Decision Tree

### Difference-in-Differences

```
Is treatment timing the same across all treated units?
├── YES (one shock, two groups)
│   └── feols(y ~ treat_post | unit + time, cluster = ~unit)   # OK
│
└── NO (staggered adoption)
    ├── Are treatment effects plausibly homogeneous?
    │   └── If you really believe this: TWFE with caveats.
    │
    └── Otherwise (the realistic case):
        ├── Callaway & Sant'Anna  (did::att_gt + aggte)
        ├── Sun & Abraham         (fixest::sunab)
        ├── Borusyak/Jaravel/Spiess (didimputation::did_imputation)
        └── de Chaisemartin & D'Haultfoeuille (DIDmultiplegt)

   Report at least two estimators when possible.
```

### Instrumental Variables

```
Always estimate and report the first stage explicitly.

Effective first-stage F (Olea-Pflueger):
├── F >= 100  → conventional 2SLS inference is reliable
├── 10 <= F < 100 → conventional t is unreliable; report:
│   ├── Anderson-Rubin confidence set (ivmodel, ivDiag)
│   └── tF-adjusted CI (Lee 2022)
└── F < 10  → instrument is weak; do not interpret 2SLS as causal
              without weak-IV-robust inference.

Panel IV: feols(y ~ x1 | fe | endog ~ z, data = df)
First stage: summary(model, stage = 1)
```

### Regression Discontinuity

```
Sharp RDD:
├── Default: rdrobust::rdrobust(y, x, c = cutoff)
├── Visualization: rdrobust::rdplot(y, x, c = cutoff)
├── Density manipulation test: rddensity::rddensity(x, c = cutoff)
└── Bandwidth sensitivity: report estimates over [h/2, h, 2h]

Fuzzy RDD: rdrobust(y, x, c, fuzzy = treatment)

Never pick a bandwidth by eye. Use rdbwselect or rdrobust's MSE-optimal default.
```

### Inference

```
Number of clusters G:
├── G >= 50    → vcov = cluster-robust (CR1) is fine
├── 30 <= G < 50 → use clubSandwich::vcovCR(..., type = "CR2")
└── G < 30     → use wild cluster bootstrap (fwildclusterboot::boottest)

Multi-way clustering only when there is real correlation along
both dimensions (e.g. industry x year shocks). Adding a second
dimension always inflates SEs and is not "more conservative" — it
is a different estimator.
```

## Output Skeleton

Every analysis script should follow this structure:

```r
# 0. Header: estimand, identification, sample, clustering, data version
# 1. Setup: packages, seed, paths
# 2. Load + assert panel structure (isid-equivalent)
# 3. Sample construction with documented filters and Ns
# 4. Descriptives (Table 1, balance table)
# 5. Main specification(s)
# 6. Robustness ladder (alt FE, alt cluster, alt sample, alt estimator)
# 7. Diagnostics (pre-trends, first-stage, density, placebo)
# 8. Tables: etable() or modelsummary() to results/
# 9. Figures: iplot(), coefplot() to results/
# 10. Save fitted models with versioned filenames
```

## Common Pitfalls

- Plain TWFE with staggered timing — biased when effects are heterogeneous (Goodman-Bacon 2021, de Chaisemartin & D'Haultfoeuille 2020).
- Reporting first-stage F > 10 as a sufficient pre-test — biased; use AR or tF (Andrews, Stock & Sun 2019; Lee 2022).
- Cluster-robust SEs with a handful of clusters — undercoverage; use wild bootstrap (Cameron, Gelbach & Miller 2008; MacKinnon & Webb 2018).
- Picking an RDD bandwidth by eye — use `rdrobust` / `rdbwselect`.
- Using `lm()` for panel data — slow, no within transform, fragile clustering. Use `feols`.
- Quietly dropping observations — log every filter and report sample sizes.
- Treating a coefficient on `treated * post` as the "DiD" without thinking about composition when treatment is staggered.

## Additional Resources

- `reference.md` — extended code patterns for each estimator family.
- `examples/` — runnable R scripts:
  - `examples/did_twfe_baseline.R` — single-shock DiD with `fixest`
  - `examples/did_callaway_santanna.R` — staggered DiD with `did`
  - `examples/event_study_sun_abraham.R` — heterogeneity-robust event study
  - `examples/iv_weak_instruments.R` — first-stage diagnostics, AR set, tF
  - `examples/rdd_robust.R` — sharp and fuzzy RDD with `rdrobust`
  - `examples/wild_cluster_bootstrap.R` — inference with few clusters

## Requirements

- R >= 4.1
- Core: `fixest`, `modelsummary`, `dplyr`, `ggplot2`
- Modern DiD: `did`, `didimputation`, `DIDmultiplegt`
- IV: `ivmodel`, `ivDiag`
- RDD: `rdrobust`, `rddensity`
- Inference: `clubSandwich`, `fwildclusterboot`, `sandwich`, `lmtest`

```r
install.packages(c(
  "fixest", "modelsummary", "dplyr", "ggplot2",
  "did", "didimputation", "DIDmultiplegt",
  "ivmodel", "ivDiag",
  "rdrobust", "rddensity",
  "clubSandwich", "fwildclusterboot", "sandwich", "lmtest"
))
```

## References

- Goodman-Bacon (2021). *Difference-in-Differences with Variation in Treatment Timing*. JoE.
- Callaway & Sant'Anna (2021). *Difference-in-Differences with Multiple Time Periods*. JoE.
- Sun & Abraham (2021). *Estimating Dynamic Treatment Effects in Event Studies with Heterogeneous Effects*. JoE.
- Borusyak, Jaravel & Spiess (2024). *Revisiting Event Study Designs: Robust and Efficient Estimation*. ReStud.
- de Chaisemartin & D'Haultfoeuille (2020). *Two-way Fixed Effects Estimators with Heterogeneous Treatment Effects*. AER.
- Olea & Pflueger (2013). *A Robust Test for Weak Instruments*. JBES.
- Lee, McCrary, Moreira & Porter (2022). *Valid t-ratio Inference for IV*. AER.
- Calonico, Cattaneo & Titiunik (2014). *Robust Nonparametric Confidence Intervals for RDD*. Econometrica.
- MacKinnon & Webb (2018). *The Wild Bootstrap for Few (Treated) Clusters*. EJ.
- Roth, Sant'Anna, Bilinski & Poe (2023). *What's Trending in Difference-in-Differences?* JoE.
