# event_study_ggplot.R
# ---------------------------------------------------------------
# Sun-Abraham (2021) event study coefficient plot via fixest +
# ggplot2. Writes paper/figs/fig_event_study.pdf.
# ---------------------------------------------------------------

suppressPackageStartupMessages({
  library(fixest)
  library(broom)
  library(dplyr)
  library(ggplot2)
  library(here)
})

source(here("code", "r", "theme_paper.R"))

set.seed(20240101)
df <- arrow::read_parquet(here("data", "processed", "panel.parquet"))

# Estimate
m <- feols(y ~ sunab(cohort, year) | unit + year,
           data    = df,
           cluster = ~unit)

# Tidy to a plottable data frame
coefs <- tidy(m, conf.int = TRUE) |>
  filter(grepl("year", term)) |>
  mutate(rel_time = as.integer(gsub(".*::(-?\\d+).*", "\\1", term)))

p <- ggplot(coefs, aes(rel_time, estimate)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey40") +
  geom_vline(xintercept = -0.5, linetype = "dashed", color = "grey40") +
  geom_pointrange(aes(ymin = conf.low, ymax = conf.high),
                  size = 0.4, fatten = 2.5, color = okabe_ito[1]) +
  scale_x_continuous(breaks = unique(coefs$rel_time)) +
  labs(x = "Years relative to treatment",
       y = "ATT(e)",
       caption = "Sun-Abraham (2021); 95% CIs from cluster-robust SEs (cluster: unit).") +
  theme_paper()

dir.create(here("paper", "figs"), recursive = TRUE, showWarnings = FALSE)
ggsave(here("paper", "figs", "fig_event_study.pdf"),
       plot = p, width = 6.5, height = 4, units = "in",
       device = cairo_pdf)
