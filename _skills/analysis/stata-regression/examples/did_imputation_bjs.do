*-------------------------------------------------------------*
* Purpose : Borusyak-Jaravel-Spiess (2024) imputation estimator.
*           Generally the most efficient heterogeneity-robust
*           DiD estimator under parallel trends.
* Inputs  : ${data_final}/analysis.dta
* Outputs : ${results}/Tables/did_bjs.tex
*-------------------------------------------------------------*

use "${data_final}/analysis.dta", clear
isid unit_id year

* did_imputation expects:
*   - outcome (numeric)
*   - unit identifier
*   - time identifier
*   - treatment-onset year (missing for never-treated)

did_imputation outcome unit_id year first_treat_year, ///
    horizons(0/5) pretrends(5) autosample ///
    cluster(unit_id) minn(0)

* Coefficient plot from saved estimates
event_plot, default_look ///
    graph_opt(xtitle("Years since treatment") ///
              ytitle("ATT(e)") ///
              title("BJS imputation event study"))

* Pretest for parallel trends (joint test of pre-period coefficients)
did_imputation outcome unit_id year first_treat_year, ///
    horizons(0/5) pretrends(5) autosample ///
    cluster(unit_id) minn(0)
