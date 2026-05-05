# did_callaway_santanna.R
# ---------------------------------------------------------------
# Heterogeneity-robust DiD for staggered treatment adoption.
# Implements Callaway & Sant'Anna (2021).
#
# Use this whenever cohorts adopt treatment at different dates
# and effects may vary by cohort or time since treatment.
# ---------------------------------------------------------------

suppressPackageStartupMessages({
  library(did)
  library(dplyr)
  library(ggplot2)
})

set.seed(20240101)

# ---- 1. Simulate a staggered-adoption panel ----------------------
n_units <- 300
n_years <- 12

cohorts <- sample(c(0, 4, 7, 10), n_units, replace = TRUE,
                  prob = c(0.4, 0.2, 0.2, 0.2))   # 0 = never treated

df <- expand.grid(
  unit_id = seq_len(n_units),
  year    = seq_len(n_years)
) |>
  mutate(
    cohort = cohorts[unit_id],
    treated_now = cohort > 0 & year >= cohort,
    rel_time    = ifelse(cohort > 0, year - cohort, NA),
    unit_fe = rep(rnorm(n_units), times = n_years),
    year_fe = rep(rnorm(n_years), each  = n_units),
    # heterogeneous, dynamic effect: late cohorts have larger effects
    effect = ifelse(treated_now,
                    0.2 + 0.1 * (rel_time + 1) + 0.05 * (cohort - 4),
                    0),
    outcome = effect + unit_fe + year_fe + rnorm(n())
  )

# ---- 2. Estimate ATT(g, t) with the doubly-robust method ---------
att <- att_gt(
  yname         = "outcome",
  tname         = "year",
  idname        = "unit_id",
  gname         = "cohort",            # 0 means never-treated
  data          = df,
  control_group = "notyettreated",
  est_method    = "dr",
  bstrap        = TRUE,
  cband         = TRUE
)
summary(att)

# ---- 3. Aggregate to a single ATT --------------------------------
agg_simple <- aggte(att, type = "simple", na.rm = TRUE)
summary(agg_simple)

# ---- 4. Dynamic event-study aggregation --------------------------
agg_es <- aggte(att, type = "dynamic", min_e = -4, max_e = 5, na.rm = TRUE)
summary(agg_es)

ggdid(agg_es) +
  labs(title = "Callaway-Sant'Anna event study",
       x = "Years since treatment", y = "ATT(e)")

# ---- 5. Aggregation by cohort (group-time effects) ---------------
agg_group <- aggte(att, type = "group", na.rm = TRUE)
summary(agg_group)
ggdid(agg_group)
