# make_tables_modelsummary.R
# ---------------------------------------------------------------
# Produce all paper tables from one R script. Writes .tex files
# directly to paper/tabs/. DIME "full replicability" tier.
# ---------------------------------------------------------------

suppressPackageStartupMessages({
  library(fixest)
  library(modelsummary)
  library(dplyr)
  library(here)
})

set.seed(20240101)

TABS <- here("paper", "tabs")
dir.create(TABS, recursive = TRUE, showWarnings = FALSE)

df <- arrow::read_parquet(here("data", "processed", "analysis.parquet"))

# ---- Table 1: Summary statistics --------------------------------
datasummary(
  All(df %>% select(y, treat, x1, x2)) ~ Mean + SD + Min + Max + N,
  data    = df,
  output  = file.path(TABS, "table_summary.tex"),
  fmt     = 2,
  title   = "Summary statistics",
  notes   = "Sample: full estimation sample."
)

# ---- Table 2: Main results --------------------------------------
m1 <- feols(y ~ treat                  | unit + year,                 data = df, cluster = ~unit)
m2 <- feols(y ~ treat + x1 + x2        | unit + year,                 data = df, cluster = ~unit)
m3 <- feols(y ~ treat + x1 + x2        | unit + year + region^year,   data = df, cluster = ~unit)

modelsummary(
  list("Baseline" = m1, "+ Controls" = m2, "+ Region#Year FE" = m3),
  output    = file.path(TABS, "table_main.tex"),
  fmt       = 3,
  coef_map  = c("treat" = "Treatment x Post"),
  gof_map   = c("nobs", "r.squared", "adj.r.squared"),
  stars     = c("*" = 0.10, "**" = 0.05, "***" = 0.01),
  title     = "Effect of treatment on outcome",
  notes     = "Cluster-robust standard errors in parentheses, clustered by unit.",
  escape    = FALSE
)

# ---- Table 3: Robustness ----------------------------------------
r1 <- feols(y ~ treat + x1 + x2 | unit + year, data = df, cluster = ~unit)
r2 <- feols(y ~ treat + x1 + x2 | unit + year, data = df, cluster = ~unit + year)
r3 <- feols(y ~ treat + x1 + x2 | unit + year, data = filter(df, rural == 1), cluster = ~unit)

modelsummary(
  list("Baseline" = r1, "Two-way cluster" = r2, "Rural only" = r3),
  output    = file.path(TABS, "table_robustness.tex"),
  fmt       = 3,
  coef_map  = c("treat" = "Treatment x Post"),
  gof_map   = c("nobs", "r.squared"),
  stars     = c("*" = 0.10, "**" = 0.05, "***" = 0.01),
  title     = "Robustness",
  notes     = "Standard errors in parentheses.",
  escape    = FALSE
)

cat("All tables written to", TABS, "\n")
