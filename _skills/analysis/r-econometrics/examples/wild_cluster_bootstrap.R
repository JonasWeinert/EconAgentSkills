# wild_cluster_bootstrap.R
# ---------------------------------------------------------------
# Inference with few clusters: wild cluster bootstrap.
# Use whenever the number of clusters is small (rule of thumb < 30)
# or treatment is concentrated in a small number of clusters.
# Cameron-Gelbach-Miller (2008); MacKinnon-Webb (2018).
# ---------------------------------------------------------------

suppressPackageStartupMessages({
  library(fixest)
  library(fwildclusterboot)
  library(clubSandwich)
  library(dplyr)
})

set.seed(20240101)

# ---- 1. Simulate data with only 12 clusters ---------------------
n_clusters <- 12
n_per      <- 150
df <- tibble(
  cluster = rep(seq_len(n_clusters), each = n_per),
  treated = as.integer(cluster <= 3),                   # 3 treated clusters
  x       = rnorm(n_clusters * n_per),
  cluster_shock = rep(rnorm(n_clusters, sd = 0.6), each = n_per),
  y       = 0.3 * treated + 0.5 * x + cluster_shock + rnorm(n())
)

# ---- 2. Standard cluster-robust SE (likely undercovers) ---------
mod <- feols(y ~ treated + x, data = df, cluster = ~cluster)
summary(mod)

# ---- 3. CR2 small-sample correction (better than CR1) -----------
cr2 <- coef_test(mod, vcov = "CR2", cluster = df$cluster)
print(cr2)

# ---- 4. Wild cluster bootstrap (Rademacher weights, 9999 reps) --
boot <- boottest(
  mod,
  param   = "treated",
  clustid = "cluster",
  B       = 9999,
  type    = "rademacher",
  fe      = NULL
)
summary(boot)
# `boot$p_val` is the bootstrap p-value;
# `boot$conf_int` is the inverted CI.

# ---- 5. Compare all three approaches ----------------------------
result <- tibble(
  method = c("Cluster-robust (CR1)", "CR2", "Wild cluster bootstrap"),
  estimate = c(coef(mod)["treated"], coef(mod)["treated"], coef(mod)["treated"]),
  p_value = c(
    summary(mod)$coeftable["treated", "Pr(>|t|)"],
    cr2[cr2$Coef == "treated", "p_Satt"],
    boot$p_val
  )
)
print(result)
