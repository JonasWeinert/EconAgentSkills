# theme_paper.R
# Source this from every figure script in the project so every
# figure shares typography, gridlines, and palette.

library(ggplot2)

theme_paper <- function(base_size = 11) {
  theme_minimal(base_size = base_size) +
    theme(
      panel.grid.minor    = element_blank(),
      panel.grid.major.x  = element_blank(),
      plot.title          = element_text(face = "plain", size = base_size + 1),
      plot.title.position = "plot",
      plot.caption        = element_text(hjust = 0, size = base_size - 2,
                                          color = "grey40"),
      strip.background    = element_blank(),
      strip.text          = element_text(face = "bold"),
      legend.position     = "bottom",
      legend.title        = element_blank(),
      legend.key.height   = unit(0.6, "lines")
    )
}

# Okabe-Ito colorblind-safe palette
okabe_ito <- c("#0072B2", "#D55E00", "#009E73", "#F0E442",
               "#CC79A7", "#56B4E9", "#E69F00", "#000000")

# Convenience scales
scale_color_paper <- function(...) ggplot2::scale_color_manual(values = okabe_ito, ...)
scale_fill_paper  <- function(...) ggplot2::scale_fill_manual(values = okabe_ito, ...)
