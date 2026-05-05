*-------------------------------------------------------------*
* Purpose : Baseline panel DiD with reghdfe + esttab.
*           Single-shock design (uniform treatment timing).
* Inputs  : ${data_final}/analysis.dta
* Outputs : ${results}/Tables/table_did_main.tex
* Estimand: ATT of program on outcome Y
* Cluster : at the unit level (treatment assignment)
*-------------------------------------------------------------*

* Assumes globals are set by MasterDoFile.do

use "${data_final}/analysis.dta", clear

* Pre-flight assertions
isid unit_id year
assert !missing(treated, post)

* Construct treatment x post indicator
gen treat_post = treated * post
label var treat_post "Treatment x Post"

* Main and robustness specifications -----------------------
eststo clear

reghdfe outcome treat_post, ///
    absorb(unit_id year) vce(cluster unit_id)
eststo m_main

reghdfe outcome treat_post, ///
    absorb(unit_id year) vce(cluster unit_id year)
eststo m_twoway

reghdfe outcome treat_post controls_*, ///
    absorb(unit_id year) vce(cluster unit_id)
eststo m_controls

reghdfe outcome treat_post, ///
    absorb(unit_id year region#year) vce(cluster unit_id)
eststo m_regionyear

* Export ----------------------------------------------------
esttab m_main m_twoway m_controls m_regionyear ///
    using "${results}/Tables/table_did_main.tex", ///
    replace booktabs label se ///
    keep(treat_post) ///
    stats(N r2_within, fmt(%9.0fc %9.3f) ///
          labels("Observations" "Within R-squared")) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    mtitles("Baseline" "Two-way cluster" "+ Controls" "+ Region#Year FE") ///
    indicate("Controls = controls_*") ///
    notes("Cluster-robust SEs in parentheses, clustered by unit.")
