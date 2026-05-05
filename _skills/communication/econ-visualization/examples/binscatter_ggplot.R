# binscatter_ggplot.R
# ---------------------------------------------------------------
# Binscatter via the binsreg package (Cattaneo, Crump, Farrell &
# Feng). Useful when N is large and the conditional-mean shape
# is what you want to convey.
# ---------------------------------------------------------------

suppressPackageStartupMessages({
  library(binsreg)
  library(ggplot2)
  library(here)
})

source(here("code", "r", "theme_paper.R"))

df <- arrow::read_parquet(here("data", "processed", "analysis.parquet"))

bs <- binsreg(
  y      = df$y,
  x      = df$x,
  w      = df[, c("x1", "x2")],     # partial out covariates
  ci     = c(3, 3),                  # piecewise cubic CI
  line   = c(3, 3),
  polyreg = 1,
  noplot = TRUE
)

p <- bs$bins_plot[[1]]$plot +
  labs(x = "Predictor X (with controls partialled out)",
       y = "Outcome Y",
       caption = "Binscatter (binsreg) with cubic local fit; controls partialled out.") +
  theme_paper()

dir.create(here("paper", "figs"), recursive = TRUE, showWarnings = FALSE)
ggsave(here("paper", "figs", "fig_binscatter.pdf"),
       plot = p, width = 6.5, height = 4, units = "in",
       device = cairo_pdf)
