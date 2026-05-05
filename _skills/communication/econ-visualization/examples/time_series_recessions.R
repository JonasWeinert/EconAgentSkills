# time_series_recessions.R
# ---------------------------------------------------------------
# Time series with shaded NBER recessions. Replace `macro` with
# the actual data path. Recession dates updated through 2023.
# ---------------------------------------------------------------

suppressPackageStartupMessages({
  library(ggplot2)
  library(dplyr)
  library(tibble)
  library(here)
})

source(here("code", "r", "theme_paper.R"))

# NBER US recession peaks and troughs (extend as needed)
recessions <- tribble(
  ~start,        ~end,
  "1990-07-01",  "1991-03-01",
  "2001-03-01",  "2001-11-01",
  "2007-12-01",  "2009-06-01",
  "2020-02-01",  "2020-04-01"
) |>
  mutate(across(c(start, end), as.Date))

macro <- arrow::read_parquet(here("data", "processed", "macro_panel.parquet")) |>
  filter(indicator == "GDPC1", entity == "USA") |>
  arrange(date) |>
  mutate(
    date  = as.Date(date),
    growth = 100 * (value / lag(value, 4) - 1)
  ) |>
  filter(!is.na(growth))

p <- ggplot(macro, aes(date, growth)) +
  geom_rect(data = recessions, inherit.aes = FALSE,
            aes(xmin = start, xmax = end, ymin = -Inf, ymax = Inf),
            fill = "grey85", alpha = 0.6) +
  geom_line(color = okabe_ito[1], linewidth = 0.8) +
  geom_hline(yintercept = 0, linetype = "dotted", color = "grey50") +
  labs(x = NULL,
       y = "Year-over-year real GDP growth (%)",
       caption = "Shaded: NBER recessions. Source: BEA via FRED.") +
  theme_paper()

dir.create(here("paper", "figs"), recursive = TRUE, showWarnings = FALSE)
ggsave(here("paper", "figs", "fig_gdp_growth.pdf"),
       plot = p, width = 6.5, height = 3.2, units = "in",
       device = cairo_pdf)
