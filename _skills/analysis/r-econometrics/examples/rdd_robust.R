# rdd_robust.R
# ---------------------------------------------------------------
# Sharp and fuzzy RDD with optimal-bandwidth, bias-corrected,
# robust SEs (Calonico, Cattaneo & Titiunik via `rdrobust`).
# ---------------------------------------------------------------

suppressPackageStartupMessages({
  library(rdrobust)
  library(rddensity)
  library(dplyr)
})

set.seed(20240101)

# ---- 1. Simulate a sharp RDD ------------------------------------
n <- 3000
df <- tibble(
  x = runif(n, -1, 1),                               # running variable
  treat = as.integer(x >= 0),
  noise = rnorm(n, sd = 0.3),
  y = 0.4 * treat +
      0.5 * x + 0.3 * x^2 +                          # smooth trend
      0.6 * (x >= 0) * x +                           # kink at cutoff
      noise
)

# ---- 2. Visualize before estimating -----------------------------
rdplot(y = df$y, x = df$x, c = 0,
       binselect = "esmv",
       title = "Sharp RDD",
       x.label = "Running variable", y.label = "Outcome")

# ---- 3. Main estimate (MSE-optimal bandwidth, robust SE) --------
rd <- rdrobust(y = df$y, x = df$x, c = 0)
summary(rd)

cat("\nMSE-optimal bandwidth:", rd$bws[1, 1], "\n")
cat("Effective N (treated):  ", rd$N_h[2], "\n")
cat("Effective N (control):  ", rd$N_h[1], "\n")

# ---- 4. Bandwidth sensitivity table -----------------------------
h_opt <- rd$bws[1, 1]
sens <- lapply(c(h_opt / 2, h_opt, 2 * h_opt), function(h) {
  est <- rdrobust(y = df$y, x = df$x, c = 0, h = h)
  tibble(h = h,
         tau = est$Estimate[1, 1],
         se  = est$se[3, 1],          # robust SE
         ci_lo = est$ci[3, 1],
         ci_hi = est$ci[3, 2],
         n_eff = est$N_h[1] + est$N_h[2])
}) |> bind_rows()
print(sens)

# ---- 5. Density manipulation test (Cattaneo-Jansson-Ma) ---------
dens <- rddensity(X = df$x, c = 0)
summary(dens)
# Plot it: rdplotdensity(dens, X = df$x)

# ---- 6. Covariate balance (RDD on each pre-determined X) --------
# In real data: rerun rdrobust with each baseline covariate as outcome.
# All should be statistically zero.

# ---- 7. Fuzzy RDD example ----------------------------------------
df_fuzzy <- df |>
  mutate(actual_treat = as.integer(treat == 1 & runif(n()) < 0.7))
rd_fuzzy <- rdrobust(y = df_fuzzy$y, x = df_fuzzy$x, c = 0,
                     fuzzy = df_fuzzy$actual_treat)
summary(rd_fuzzy)
