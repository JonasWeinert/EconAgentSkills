# Economics Visualization Reference

Detailed code patterns. Use these as canonical templates when generating publication-quality figures.

## 1. Paper-wide ggplot2 Theme

```r
# theme_paper.R - source this from every figure script
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
```

## 2. Event Study Coefficient Plot (R)

```r
library(fixest)
library(broom)
library(ggplot2)

# Estimate
m <- feols(y ~ sunab(cohort, year) | unit + year, data = df, cluster = ~unit)

# Tidy to a plottable data frame
coefs <- tidy(m, conf.int = TRUE) |>
  filter(grepl("year", term)) |>
  mutate(rel_time = as.integer(gsub(".*::(-?\\d+).*", "\\1", term)))

ggplot(coefs, aes(rel_time, estimate)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey40") +
  geom_vline(xintercept = -0.5, linetype = "dashed", color = "grey40") +
  geom_pointrange(aes(ymin = conf.low, ymax = conf.high),
                  size = 0.4, fatten = 2.5, color = "#0072B2") +
  labs(x = "Years relative to treatment",
       y = "ATT(e)",
       caption = "Note: Sun-Abraham (2021) estimator; 95% CIs from cluster-robust SEs.") +
  theme_paper()

ggsave("paper/figs/fig_event_study.pdf",
       width = 6.5, height = 4, units = "in", device = cairo_pdf)
```

## 3. Coefficient Plot Across Specifications (R)

```r
library(fixest)
library(broom)
library(dplyr)
library(ggplot2)

m1 <- feols(y ~ treat                    | unit + year, data = df, cluster = ~unit)
m2 <- feols(y ~ treat + x1 + x2          | unit + year, data = df, cluster = ~unit)
m3 <- feols(y ~ treat + x1 + x2          | unit + year + region^year, data = df, cluster = ~unit)

specs <- list("Baseline" = m1, "+ Controls" = m2, "+ Region#Year FE" = m3)

coef_df <- bind_rows(
  lapply(names(specs), function(nm) {
    tidy(specs[[nm]], conf.int = TRUE) |>
      filter(term == "treat") |>
      mutate(spec = nm)
  })
) |>
  mutate(spec = factor(spec, levels = rev(names(specs))))

ggplot(coef_df, aes(estimate, spec)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey40") +
  geom_pointrange(aes(xmin = conf.low, xmax = conf.high),
                  color = "#0072B2") +
  labs(x = "Coefficient on Treatment x Post", y = NULL,
       caption = "95% CIs from cluster-robust SEs (cluster: unit).") +
  theme_paper()

ggsave("paper/figs/fig_coefplot.pdf", width = 6.5, height = 3,
       units = "in", device = cairo_pdf)
```

## 4. Time Series with Recession Shading (R)

```r
library(ggplot2)
library(dplyr)

# US NBER recession dates (excerpt; extend as needed)
recessions <- tibble(
  start = as.Date(c("2001-03-01","2007-12-01","2020-02-01")),
  end   = as.Date(c("2001-11-01","2009-06-01","2020-04-01")),
)

ggplot(macro, aes(date, gdp_growth)) +
  geom_rect(data = recessions, inherit.aes = FALSE,
            aes(xmin = start, xmax = end, ymin = -Inf, ymax = Inf),
            fill = "grey85", alpha = 0.6) +
  geom_line(color = "#0072B2", linewidth = 0.8) +
  geom_hline(yintercept = 0, linetype = "dotted", color = "grey50") +
  labs(x = NULL, y = "Year-over-year GDP growth (%)",
       caption = "Shaded: NBER recessions. Source: BEA via FRED.") +
  theme_paper()

ggsave("paper/figs/fig_gdp_growth.pdf", width = 6.5, height = 3.2,
       units = "in", device = cairo_pdf)
```

## 5. Binscatter (R, `binsreg`)

```r
library(binsreg)

bs <- binsreg(y = df$y, x = df$x, w = df[c("x1","x2")],
              ci = TRUE, line = c(3,3), polyreg = 1)
plot(bs$bins_plot[[1]]$plot) +
  labs(x = "Income", y = "Outcome",
       caption = "Binscatter with cubic local fit; controls partialled out.") +
  theme_paper()
```

## 6. Event Study (Python, matplotlib)

```python
import matplotlib.pyplot as plt
import pyfixest as pf

m = pf.feols("y ~ sunab(cohort, year) | unit + year",
             data = df, vcov = {"CRV1": "unit"})

coefs = m.tidy().reset_index()
coefs["rel_time"] = coefs["Coefficient"].str.extract(r"::(-?\d+)").astype(int)

fig, ax = plt.subplots(figsize = (6.5, 4))
ax.axhline(0, color = "grey", linestyle = "--", linewidth = 0.8)
ax.axvline(-0.5, color = "grey", linestyle = "--", linewidth = 0.8)
ax.errorbar(coefs["rel_time"], coefs["Estimate"],
            yerr = 1.96 * coefs["Std. Error"],
            fmt = "o", color = "#0072B2", capsize = 3)
ax.set_xlabel("Years relative to treatment")
ax.set_ylabel("ATT(e)")
ax.spines[["top", "right"]].set_visible(False)
fig.text(0.02, 0.02,
         "Note: Sun-Abraham estimator; 95% CIs from cluster-robust SEs.",
         fontsize = 8, color = "grey")
fig.tight_layout()
fig.savefig("paper/figs/fig_event_study.pdf")
```

## 7. Stata `coefplot` for Event Studies

```stata
* eventstudyinteract or csdid produces the matrix; coefplot makes the figure.
matrix b = e(b_iw)
matrix V = e(V_iw)

coefplot matrix(b), se(V) ///
    keep(Lead* Lag*) vertical omitted ///
    yline(0, lpattern(dash)) ///
    xline(5.5, lpattern(dash)) ///
    ciopts(recast(rcap)) ///
    coeflabels(, interaction(" x ")) ///
    xtitle("Years since treatment") ytitle("ATT(e)") ///
    scheme(white_tableau)
graph export "paper/figs/fig_event_study.pdf", replace as(pdf)
```

## 8. Balance Plot (Standardized Differences)

```r
library(ggplot2)
library(dplyr)

bal <- tibble(
  variable    = c("Age", "Female", "Years schooling", "Baseline outcome"),
  std_diff    = c(0.02, -0.01, 0.04, 0.03),
  ci_lo       = c(-0.05, -0.05, -0.02, -0.04),
  ci_hi       = c(0.09, 0.03, 0.10, 0.10),
)

ggplot(bal, aes(std_diff, reorder(variable, std_diff))) +
  geom_vline(xintercept = c(-0.1, 0, 0.1),
             linetype = c("dotted", "solid", "dotted"),
             color    = c("grey50",  "grey20", "grey50")) +
  geom_pointrange(aes(xmin = ci_lo, xmax = ci_hi), color = "#0072B2") +
  labs(x = "Standardized difference (Treatment - Control)",
       y = NULL,
       caption = "Vertical dotted lines at +/-0.10 (Imbens-Rubin guideline).") +
  theme_paper()
```

## 9. Choropleth Map (R, `sf` + ggplot2)

```r
library(sf)
library(ggplot2)
library(viridis)

us  <- read_sf(here::here("data", "geo", "us_states.gpkg"))
df  <- arrow::read_parquet(here::here("data", "processed", "state_outcomes.parquet"))
map <- left_join(us, df, by = c("state_abb"))

ggplot(map) +
  geom_sf(aes(fill = outcome), color = "white", linewidth = 0.1) +
  scale_fill_viridis_c(option = "C", name = "Outcome",
                       guide = guide_colorbar(barwidth = 12, barheight = 0.4)) +
  coord_sf(crs = 5070) +     # NAD83 / Conus Albers
  theme_void(base_size = 11) +
  theme(legend.position = "bottom")

ggsave("paper/figs/fig_map.pdf", width = 6.5, height = 4,
       units = "in", device = cairo_pdf)
```

## 10. Faceting Convention

Use facets when comparisons share an axis:

```r
ggplot(df, aes(year, y, color = group)) +
  geom_line() +
  facet_wrap(~ region, ncol = 2, scales = "fixed") +
  scale_color_manual(values = okabe_ito[1:2]) +
  theme_paper()
```

Pin `scales = "fixed"` unless ranges differ by orders of magnitude — facets with different scales are easy to misread.

## 11. Standalone vs Paper Figures

| Element            | In paper (rely on caption) | Standalone (slide/blog) |
|--------------------|----------------------------|--------------------------|
| Title              | Omit (caption has it)      | Required, descriptive    |
| Axis labels        | Required                   | Required                 |
| Axis units         | In axis labels             | In axis labels           |
| Source             | In paper bibliography      | In figure (small grey text) |
| Takeaway annotation| Optional                   | Strongly recommended     |
| Legend             | Title omitted              | Title required           |

## 12. Reproducibility Discipline (DIME applied)

- One script writes every figure for the paper; rerun before each PDF build.
- Use `here::here(...)` (R) or `Path(__file__).resolve().parents[N]` (Python) — never `setwd` or `cd`.
- Save vector formats (PDF/EPS/SVG) for paper figures; PNG only for maps with raster backgrounds.
- Pin font families that are likely available everywhere (`Helvetica`, `Liberation Sans`, `Arial`); use `device = cairo_pdf` in R for consistent rendering.
- Match figure dimensions to the LaTeX `\textwidth` you'll use; converting in `\includegraphics` after the fact distorts text size.
- Treat the figure script the same as a regression script — it must run end-to-end from a clean session.
