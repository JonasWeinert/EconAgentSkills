# did_twfe_baseline.R
# ---------------------------------------------------------------
# Single-shock DiD with two-way fixed effects.
# Use ONLY when treatment timing is the same across all treated units.
# For staggered timing see did_callaway_santanna.R.
# ---------------------------------------------------------------

suppressPackageStartupMessages({
  library(fixest)
  library(dplyr)
})

set.seed(20240101)

# ---- 1. Simulate a panel with one treatment date -----------------
n_units <- 200
n_years <- 10
treat_year <- 6

df <- expand.grid(
  unit_id = seq_len(n_units),
  year    = seq_len(n_years)
) |>
  mutate(
    treated   = unit_id <= n_units / 2,
    post      = year >= treat_year,
    treat_post = as.integer(treated & post),
    unit_fe   = rep(rnorm(n_units), times = n_years),
    year_fe   = rep(rnorm(n_years), each  = n_units),
    epsilon   = rnorm(n()),
    outcome   = 0.8 * treat_post + unit_fe + year_fe + epsilon
  )

# ---- 2. Pre-flight checks ----------------------------------------
stopifnot(nrow(df) == n_distinct(df$unit_id) * n_distinct(df$year))

# ---- 3. Main TWFE specification ----------------------------------
mod <- feols(
  outcome ~ treat_post | unit_id + year,
  data    = df,
  cluster = ~unit_id
)
summary(mod)

# ---- 4. Event study (validates parallel trends + dynamics) -------
event <- feols(
  outcome ~ i(year - treat_year, treated, ref = -1) | unit_id + year,
  data    = df,
  cluster = ~unit_id
)
iplot(event, ref.line = -1, main = "Event study: pre-trends and dynamics")

# ---- 5. Robustness ladder ---------------------------------------
mod_twoway <- feols(
  outcome ~ treat_post | unit_id + year,
  data    = df,
  cluster = ~unit_id + year       # two-way clustering
)

# ---- 6. Reporting -----------------------------------------------
etable(
  list("Main" = mod, "Two-way cluster" = mod_twoway),
  fitstat = ~ n + r2 + war2,
  digits  = "r3",
  signif.code = c("***" = 0.01, "**" = 0.05, "*" = 0.1)
)
