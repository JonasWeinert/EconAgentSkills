# event_study_sun_abraham.R
# ---------------------------------------------------------------
# Heterogeneity-robust event study via Sun & Abraham (2021).
# Implemented as `fixest::sunab` — minimal code change vs TWFE.
# ---------------------------------------------------------------

suppressPackageStartupMessages({
  library(fixest)
  library(dplyr)
})

set.seed(20240101)

# ---- 1. Simulate staggered adoption with heterogeneous effects --
n_units <- 250
n_years <- 12
df <- expand.grid(unit_id = seq_len(n_units), year = seq_len(n_years)) |>
  mutate(
    cohort = sample(c(Inf, 4, 7, 10), n_units, replace = TRUE,
                    prob = c(0.4, 0.2, 0.2, 0.2))[unit_id],
    rel_time   = ifelse(is.finite(cohort), year - cohort, NA),
    treated_now = is.finite(cohort) & year >= cohort,
    unit_fe = rep(rnorm(n_units), times = n_years),
    year_fe = rep(rnorm(n_years), each  = n_units),
    effect  = ifelse(treated_now,
                     0.3 + 0.05 * (rel_time + 1) + 0.04 * (cohort - 4),
                     0),
    outcome = effect + unit_fe + year_fe + rnorm(n())
  )

# `sunab` requires `cohort` (treatment date; Inf for never-treated)
mod_sa <- feols(
  outcome ~ sunab(cohort, year) | unit_id + year,
  data    = df,
  cluster = ~unit_id
)

# Aggregate ATT
summary(mod_sa, agg = "att")

# Cohort-specific ATTs
summary(mod_sa, agg = "cohort")

# Event-study coefficients
iplot(mod_sa, ref.line = -1,
      main = "Sun-Abraham event study",
      xlab = "Years since treatment")

# ---- Compare with naive TWFE event study (often biased) ----------
mod_naive <- feols(
  outcome ~ i(rel_time, ref = -1) | unit_id + year,
  data    = df |> mutate(rel_time = ifelse(is.finite(cohort), year - cohort, -1)),
  cluster = ~unit_id
)

iplot(list("Naive TWFE" = mod_naive, "Sun-Abraham" = mod_sa),
      ref.line = -1,
      main = "Naive TWFE vs Sun-Abraham")
