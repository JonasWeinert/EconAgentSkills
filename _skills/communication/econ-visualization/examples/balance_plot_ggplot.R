# balance_plot_ggplot.R
# ---------------------------------------------------------------
# Standardized differences plot for treatment-control balance.
# Imbens-Rubin guidance: |std diff| < 0.10 is well-balanced.
# ---------------------------------------------------------------

suppressPackageStartupMessages({
  library(ggplot2)
  library(dplyr)
  library(here)
})

source(here("code", "r", "theme_paper.R"))

# Replace with real values from the balance script
bal <- tibble::tibble(
  variable = c("Age", "Female", "Years schooling",
               "Married", "Baseline outcome", "Income (log)"),
  std_diff = c(0.02, -0.01, 0.04, 0.06, 0.03, -0.05),
  ci_lo    = c(-0.05, -0.05, -0.02, -0.01, -0.04, -0.12),
  ci_hi    = c( 0.09,  0.03,  0.10,  0.13,  0.10,  0.02)
) |>
  mutate(variable = forcats::fct_reorder(variable, std_diff))

p <- ggplot(bal, aes(std_diff, variable)) +
  geom_vline(xintercept = c(-0.10, 0.10), linetype = "dotted", color = "grey50") +
  geom_vline(xintercept = 0,              linetype = "solid",  color = "grey20") +
  geom_pointrange(aes(xmin = ci_lo, xmax = ci_hi), color = okabe_ito[1]) +
  labs(x = "Standardized difference (Treatment - Control)",
       y = NULL,
       caption = "Vertical dotted lines at +/-0.10 (Imbens-Rubin balance guideline).") +
  theme_paper()

dir.create(here("paper", "figs"), recursive = TRUE, showWarnings = FALSE)
ggsave(here("paper", "figs", "fig_balance.pdf"),
       plot = p, width = 6.5, height = 3.5, units = "in",
       device = cairo_pdf)
