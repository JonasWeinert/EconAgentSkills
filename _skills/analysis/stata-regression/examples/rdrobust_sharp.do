*-------------------------------------------------------------*
* Purpose : Sharp RDD with optimal-bandwidth, bias-corrected,
*           robust SEs (Calonico, Cattaneo & Titiunik 2014),
*           plus density manipulation test (Cattaneo-Jansson-Ma).
* Inputs  : ${data_final}/analysis.dta
* Outputs : ${results}/Tables/rdd_main.tex
*           ${results}/Tables/rdd_sensitivity.tex
*           ${results}/Figures/rdplot.pdf
*-------------------------------------------------------------*

use "${data_final}/analysis.dta", clear

* `running` is the assignment variable; cutoff at 0
* `outcome` is the outcome of interest

* ---- 1. RD plot ---------------------------------------------
rdplot outcome running, c(0) binselect(esmv) ///
    graph_options(title("Sharp RDD") ///
                  xtitle("Running variable (centered)") ///
                  ytitle("Outcome"))
graph export "${results}/Figures/rdplot.pdf", replace

* ---- 2. Main estimate (MSE-optimal h, robust SE) ------------
rdrobust outcome running, c(0)
estimates store rdd_main

local h_opt = e(h_l)

* ---- 3. Density manipulation test ---------------------------
rddensity running, c(0)

* ---- 4. Bandwidth sensitivity table -------------------------
eststo clear
foreach factor in 0.5 1 2 {
    local h = `h_opt' * `factor'
    quietly rdrobust outcome running, c(0) h(`h')
    estadd scalar bandwidth = `h'
    estadd scalar n_left    = e(N_h_l)
    estadd scalar n_right   = e(N_h_r)
    eststo h_`=round(`factor'*100)'
}

esttab using "${results}/Tables/rdd_sensitivity.tex", ///
    replace booktabs ///
    cells(b(fmt(3) star) se(fmt(3) par)) ///
    keep(RD_Estimate) ///
    stats(bandwidth n_left n_right, fmt(%9.3f %9.0fc %9.0fc) ///
          labels("Bandwidth" "N (left)" "N (right)")) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    mtitles("h_opt/2" "h_opt" "2*h_opt") ///
    notes("Bias-corrected estimates with robust standard errors.")

* ---- 5. Fuzzy RDD (if applicable) ---------------------------
* rdrobust outcome running, c(0) fuzzy(treatment_received)
