*-------------------------------------------------------------*
* Purpose : Heterogeneity-robust event study via Sun & Abraham
*           (2021), implemented in `eventstudyinteract`.
* Inputs  : ${data_final}/analysis.dta
* Outputs : ${results}/Figures/event_study_sa.pdf
*-------------------------------------------------------------*

use "${data_final}/analysis.dta", clear
isid unit_id year

* Build relative-time indicators around treatment date
gen rel_time   = year - first_treat_year if first_treat_year > 0
gen never_treat = first_treat_year == .

* Lead and lag dummies (omit -1 as baseline)
forvalues k = 1/5 {
    gen Lead`k' = rel_time == -`k'
}
forvalues k = 0/5 {
    gen Lag`k'  = rel_time == `k'
}

* Sun-Abraham estimator: interaction-weighted estimator with
* never-treated as the control cohort.
eventstudyinteract outcome Lead2-Lead5 Lag0-Lag5, ///
    cohort(first_treat_year) ///
    control_cohort(never_treat) ///
    absorb(unit_id year) ///
    vce(cluster unit_id)

* Coefficient plot
matrix b = e(b_iw)
matrix V = e(V_iw)

coefplot matrix(b), se(V) ///
    keep(Lead* Lag*) ///
    vertical omitted ///
    yline(0) xline(5.5, lpattern(dash)) ///
    ciopts(recast(rcap)) ///
    xtitle("Years since treatment") ytitle("ATT(e)") ///
    title("Sun-Abraham event study")
graph export "${results}/Figures/event_study_sa.pdf", replace
