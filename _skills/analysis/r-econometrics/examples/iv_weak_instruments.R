# iv_weak_instruments.R
# ---------------------------------------------------------------
# 2SLS with first-stage diagnostics and weak-IV-robust inference.
#
# Default reporting:
#   - First stage with cluster-robust SE
#   - Effective F (Olea-Pflueger)
#   - Anderson-Rubin confidence set when F < 100
#   - tF-adjusted CI (Lee 2022) when available
# ---------------------------------------------------------------

suppressPackageStartupMessages({
  library(fixest)
  library(dplyr)
})

set.seed(20240101)

# ---- 1. Simulate a panel with one endogenous regressor + one IV --
n <- 5000
df <- tibble(
  z       = rnorm(n),                          # instrument
  unobs   = rnorm(n),                          # confounder
  endog   = 0.3 * z + 0.7 * unobs + rnorm(n),  # endogenous regressor
  x_exog  = rnorm(n),
  cluster = sample(1:50, n, replace = TRUE),
  y       = 1.0 * endog + 0.5 * x_exog + 0.8 * unobs + rnorm(n)
)

# ---- 2. First stage (always estimated and reported) --------------
first_stage <- feols(endog ~ z + x_exog,
                     data = df, cluster = ~cluster)
summary(first_stage)
fitstat(first_stage, ~ f + ivf)   # F and effective F

# ---- 3. 2SLS via fixest -----------------------------------------
iv <- feols(y ~ x_exog | endog ~ z, data = df, cluster = ~cluster)
summary(iv)
summary(iv, stage = 1)              # first stage in same format
fitstat(iv, ~ ivf + ivwald)         # IV F, Wald

# ---- 4. Weak-IV-robust inference --------------------------------
# Anderson-Rubin confidence set via ivmodel
if (requireNamespace("ivmodel", quietly = TRUE)) {
  library(ivmodel)
  m <- ivmodel(Y = df$y, D = df$endog,
               Z = matrix(df$z, ncol = 1),
               X = matrix(df$x_exog, ncol = 1))
  AR.test(m, alpha = 0.05)
  CLR(m, alpha = 0.05)              # Conditional Likelihood Ratio
}

# tF-adjusted CIs (Lee, McCrary, Moreira & Porter 2022) via ivDiag
if (requireNamespace("ivDiag", quietly = TRUE)) {
  library(ivDiag)
  diag <- ivDiag(data = as.data.frame(df),
                 Y = "y", D = "endog", Z = "z", controls = "x_exog",
                 cl = "cluster", parallel = FALSE)
  print(diag$est_2sls)
  print(diag$tF)
}

# ---- 5. Reduced form (= AR test in another form) ----------------
reduced <- feols(y ~ z + x_exog, data = df, cluster = ~cluster)
summary(reduced)
