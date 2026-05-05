*-------------------------------------------------------------*
* Purpose : Heterogeneity-robust DiD with staggered adoption,
*           via Callaway & Sant'Anna (2021) implemented in csdid.
* Inputs  : ${data_final}/analysis.dta with `first_treat_year`
*           equal to the first period of treatment, and 0 (or
*           missing) for never-treated units.
* Outputs : ${results}/Tables/csdid_simple.tex
*           ${results}/Figures/event_study_cs.pdf
*-------------------------------------------------------------*

use "${data_final}/analysis.dta", clear
isid unit_id year

* csdid expects gvar = 0 for never-treated
replace first_treat_year = 0 if missing(first_treat_year)

* ---- 1. Doubly-robust ATT(g, t) -----------------------------
csdid outcome controls_*, ///
    ivar(unit_id) time(year) gvar(first_treat_year) ///
    method(dripw) cluster(unit_id)

* ---- 2. Aggregate to a single overall ATT -------------------
estat simple
estimates store cs_simple

* ---- 3. Event-study aggregation -----------------------------
estat event, window(-5 5)
event_plot, default_look ///
    graph_opt(xtitle("Years since treatment") ///
              ytitle("ATT(e)") ///
              title("Callaway-Sant'Anna event study"))
graph export "${results}/Figures/event_study_cs.pdf", replace

* ---- 4. Group-time aggregation ------------------------------
estat group

* ---- 5. Calendar-time aggregation ---------------------------
estat calendar

* ---- 6. Export overall ATT to LaTeX -------------------------
esttab cs_simple using "${results}/Tables/csdid_simple.tex", ///
    replace booktabs label se ///
    cells(b(fmt(3) star) se(fmt(3) par)) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    notes("Callaway-Sant'Anna ATT, doubly robust, never-treated control group.")
