# LaTeX Tables Reference

Detailed code patterns for producing publication-ready LaTeX tables from Stata, R, and Python in the DIME "full replicability" tier. Use these as canonical templates.

## 1. Stata: `esttab` (estout family)

### 1.1 Multi-spec regression table

```stata
eststo clear

reghdfe y treat,                 absorb(unit year) vce(cluster unit)
eststo m1, addscalars(controls "No"  fe "Unit, Year")

reghdfe y treat $controls,       absorb(unit year) vce(cluster unit)
eststo m2, addscalars(controls "Yes" fe "Unit, Year")

reghdfe y treat $controls,       absorb(unit year region#year) vce(cluster unit)
eststo m3, addscalars(controls "Yes" fe "Unit, Year, Region#Year")

esttab m1 m2 m3 using "tabs/table_main.tex", ///
    replace booktabs label se ///
    keep(treat) ///
    order(treat) ///
    coeflabels(treat "Treatment x Post") ///
    stats(controls fe N r2_within, ///
          fmt(%s %s %9.0fc %9.3f) ///
          labels("Controls" "Fixed effects" "Observations" "Within R-squared")) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    mtitles("Baseline" "+ Controls" "+ Region#Year FE") ///
    notes("Cluster-robust SEs in parentheses, clustered by unit." ///
          "* p<0.10, ** p<0.05, *** p<0.01.") ///
    nonotes addnotes("Sample: balanced panel of N units over T years.")
```

`esttab` writes a complete `\begin{table} ... \end{table}` environment to `tabs/table_main.tex` so the paper just does `\input{tabs/table_main.tex}`.

### 1.2 Summary statistics

```stata
eststo clear
estpost summarize y treat $controls, detail

esttab using "tabs/table_summary.tex", ///
    replace booktabs label ///
    cells("mean(fmt(2)) sd(fmt(2)) min(fmt(2)) max(fmt(2)) count(fmt(0))") ///
    nomtitle nonumber ///
    title("Summary statistics") ///
    addnotes("Sample: full estimation sample.")
```

### 1.3 Balance / difference-in-means via `iebaltab`

For DIME-canonical balance tables across treatment arms, use [`iebaltab`](https://dimewiki.worldbank.org/Iebaltab):

```stata
iebaltab age female years_school baseline_y, ///
    grpvar(treated) ///
    save("tabs/table_balance.xlsx") ///
    savetex("tabs/table_balance.tex") replace ///
    rowlabels("age Age @ female Female @ years_school Years of schooling") ///
    starlevels(0.10 0.05 0.01) feqtest
```

## 2. R: `modelsummary` and `fixest::etable`

### 2.1 Multi-spec via `modelsummary`

```r
library(fixest)
library(modelsummary)

m1 <- feols(y ~ treat                 | unit + year,                data = df, cluster = ~unit)
m2 <- feols(y ~ treat + x1 + x2       | unit + year,                data = df, cluster = ~unit)
m3 <- feols(y ~ treat + x1 + x2       | unit + year + region^year,  data = df, cluster = ~unit)

modelsummary(
  list("Baseline" = m1, "+ Controls" = m2, "+ Region#Year FE" = m3),
  output    = "tabs/table_main.tex",
  fmt       = 3,
  coef_map  = c("treat" = "Treatment x Post"),
  gof_map   = c("nobs", "r.squared", "adj.r.squared"),
  stars     = c("*" = 0.10, "**" = 0.05, "***" = 0.01),
  notes     = "Cluster-robust SEs in parentheses, clustered by unit.",
  escape    = FALSE
)
```

`modelsummary` also supports `output = "tabs/table_main.docx"` for Word workflows via `flextable`.

### 2.2 `fixest::etable` (best for fixest-only tables)

```r
etable(
  m1, m2, m3,
  tex      = TRUE,
  file     = "tabs/table_main.tex",
  replace  = TRUE,
  fitstat  = ~ n + r2 + war2,
  digits   = "r3",
  digits.stats = "r3",
  signif.code  = c("***" = 0.01, "**" = 0.05, "*" = 0.10),
  notes    = c("Cluster-robust SEs in parentheses.")
)
```

## 3. Python: `pyfixest.etable` and `stargazer`

### 3.1 `pyfixest.etable` (pyfixest models)

```python
import pyfixest as pf

m1 = pf.feols("y ~ treat | unit + year", data = df, vcov = {"CRV1": "unit"})
m2 = pf.feols("y ~ treat + x1 + x2 | unit + year", data = df, vcov = {"CRV1": "unit"})
m3 = pf.feols("y ~ treat + x1 + x2 | unit + year + region^year", data = df, vcov = {"CRV1": "unit"})

pf.etable(
    [m1, m2, m3],
    type        = "tex",
    file_name   = "tabs/table_main.tex",
    keep        = ["treat"],
    coef_fmt    = "b (se)",
    notes       = "Cluster-robust SEs in parentheses, clustered by unit.",
)
```

### 3.2 `stargazer` (statsmodels OLS, GLM)

```python
import statsmodels.api as sm
from stargazer.stargazer import Stargazer

X = sm.add_constant(df[["treat", "x1", "x2"]])
ols = sm.OLS(df["y"], X).fit(cov_type = "cluster", cov_kwds = {"groups": df["unit"]})

s = Stargazer([ols])
s.title("Main results")
s.covariate_order(["treat", "x1", "x2", "const"])
s.rename_covariates({"treat": "Treatment x Post"})
s.add_line("Cluster", ["Unit"])
s.show_degrees_of_freedom(False)
s.add_custom_notes(["Cluster-robust SEs in parentheses."])

with open("tabs/table_main.tex", "w") as f:
    f.write(s.render_latex())
```

## 4. Manual Templates ("Good Replicability" Tier)

When you cannot run a code-driven exporter (e.g. you're hand-formatting one decisive headline number for a fact sheet), use a copy-paste tabular skeleton that still uses booktabs:

```latex
\begin{table}[htbp]\centering
\caption{Effect of treatment on outcome}
\label{tab:main}
\begin{threeparttable}
\begin{tabular}{lccc}
\toprule
                       & (1)        & (2)        & (3) \\
                       & Baseline   & + Controls & + FE \\
\midrule
Treatment $\times$ Post & 0.123*** & 0.118***  & 0.104** \\
                       & (0.045)   & (0.043)   & (0.041) \\
\midrule
Controls               & No        & Yes       & Yes \\
Fixed effects          & Unit, Year& Unit, Year& Unit, Year, Region$\times$Year \\
Observations           & 10{,}000  & 10{,}000  & 10{,}000 \\
Within R$^2$           & 0.04      & 0.07      & 0.11 \\
\bottomrule
\end{tabular}
\begin{tablenotes}\footnotesize
\item Cluster-robust standard errors in parentheses, clustered by unit.
\item * $p<0.10$, ** $p<0.05$, *** $p<0.01$.
\end{tablenotes}
\end{threeparttable}
\end{table}
```

This is "good replicability" in DIME's framework: still produced by hand but consistent and reproducible by re-running the same script that generated the numbers. Use it only when the code path doesn't yet exist; otherwise upgrade to `esttab`/`modelsummary`/`stargazer`.

## 5. Decimal Alignment with `siunitx`

```latex
\usepackage{siunitx}
\sisetup{detect-all = true,
         table-format = -2.3,
         input-symbols = {()*}, % keep parens and stars in S columns
         table-align-text-pre = false}

\begin{tabular}{l S S S}
\toprule
                     & {(1)}   & {(2)}   & {(3)}   \\
\midrule
Treatment x Post     & 0.123   & 0.118   & 0.104   \\
                     & (0.045) & (0.043) & (0.041) \\
\bottomrule
\end{tabular}
```

Use `S` columns when you need precise decimal alignment — common for multi-panel tables with mixed scales.

## 6. Multi-Panel Tables

A clean way to combine results from multiple subsamples:

```latex
\begin{table}[htbp]\centering
\caption{Effect by subgroup}
\label{tab:hetero}
\begin{threeparttable}
\begin{tabular}{lccc}
\toprule
                          & (1) & (2) & (3) \\
\midrule
\multicolumn{4}{l}{\textit{Panel A: Full sample}}\\
Treatment x Post          & 0.12*** & 0.11*** & 0.10** \\
                          & (0.03)  & (0.03)  & (0.03) \\
\addlinespace
\multicolumn{4}{l}{\textit{Panel B: Subsample (rural)}}\\
Treatment x Post          & 0.18*** & 0.17*** & 0.15*** \\
                          & (0.04)  & (0.04)  & (0.04) \\
\midrule
Controls                  & No  & Yes & Yes \\
Fixed effects             & Yes & Yes & Yes \\
Observations              & 10{,}000 & 10{,}000 & 10{,}000 \\
\bottomrule
\end{tabular}
\begin{tablenotes}\footnotesize
\item Cluster-robust SEs in parentheses, clustered by unit.
\end{tablenotes}
\end{threeparttable}
\end{table}
```

Generate panels separately with `esttab`/`modelsummary` and `\input` them inside one `tabular`.

## 7. Cross-References

```latex
\usepackage[capitalize, noabbrev]{cleveref}

% In body text:
\Cref{tab:main} reports our preferred specification.
% Renders as: "Table 2 reports our preferred specification."
```

Use `\Cref{}` (capital C) at sentence start so capitalization is correct.

## 8. Common Reviewer-Style Fixes

| Symptom                                       | Fix                                                                |
|-----------------------------------------------|--------------------------------------------------------------------|
| "Standard errors are missing N column"        | Always include N in `stats()` / `gof_map`.                          |
| "Why are stars different in tables 2 and 3?"  | Pin one star convention in a paper-wide preamble macro.            |
| "Tables don't fit the page"                   | Use `\small` inside the `table` env; or rotate via `sidewaystable`.|
| "Missing standard-error type in notes"        | Add to the notes block, never to the caption.                       |
| "Inconsistent variable labels"                | Define labels once in a Stata `label var` block or R `coef_map`.    |
| "Mixed precision: 0.05 vs 0.0512"             | Set a global format (`fmt(%9.3f)` in `esttab` / `fmt = 3` in MS).   |
| "R^2 reported but model has FE"               | Use within-R^2 (`r2_within`) instead of overall R^2.                |
| "Number of clusters not reported"             | Add `addscalars(clust "N clusters: ...")` and include in `stats()`. |

## 9. Paper-Wide Style Macros

Put consistent style choices once in `tex/preamble.tex`:

```latex
% Significance stars footnote (paper-wide)
\newcommand{\starnote}{%
  \footnotesize Standard errors in parentheses.\\
  $^{*}\,p<0.10$, $^{**}\,p<0.05$, $^{***}\,p<0.01$.}

% Clustering footnote
\newcommand{\clustnote}[1]{%
  \footnotesize Cluster-robust standard errors in parentheses, clustered by #1.}
```

Reference inside `tablenotes`:

```latex
\begin{tablenotes}\starnote\clustnote{unit}\end{tablenotes}
```

## 10. Reproducibility Discipline (DIME applied)

- Every `tabs/*.tex` is the output of exactly one script. Add a header comment in each `.tex` (most exporters do this automatically) saying which script produced it.
- The paper's `Makefile` should rebuild tables before LaTeX:
  ```makefile
  tabs/%.tex: code/r/make_tables.R
      Rscript $<
  paper.pdf: $(wildcard tabs/*.tex) paper.tex
      latexmk -pdf paper
  ```
- Never commit edited `.tex` tables alongside the script; the next run will diverge.
- For "version control via results" (DIME term), date or commit-hash the table file when iterating: `tabs/table_main_2026-05-05.tex` → final `tabs/table_main.tex`.
