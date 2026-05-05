*-------------------------------------------------------------*
* Purpose : 2SLS with full first-stage diagnostics and
*           weak-IV-robust inference (Olea-Pflueger F + AR set).
* Inputs  : ${data_final}/analysis.dta
* Outputs : ${results}/Tables/iv_main.tex
*-------------------------------------------------------------*

use "${data_final}/analysis.dta", clear

* ---- 1. First stage (always shown) --------------------------
reg endog z x_exog, cluster(cluster_var)
test z

* ---- 2. 2SLS with diagnostics -------------------------------
* `first` shows the first stage; `robust` for hetero-robust SE
ivreg2 outcome x_exog (endog = z), cluster(cluster_var) first robust
estimates store iv_main

* ---- 3. Olea-Pflueger effective F ---------------------------
weakivtest

* If F < 100, conventional 2SLS t-tests and CIs are unreliable.
* Report at least one weak-IV-robust set:

* ---- 4. Anderson-Rubin / CLR confidence sets ----------------
* `condivreg` gives AR + CLR + LM:
condivreg outcome x_exog (endog = z), cluster(cluster_var) ar clr lm

* Alternative: rivtest after ivreg2
* rivtest, ci grid(-1(0.05)2)

* ---- 5. Reduced form (= AR test by construction) ------------
reg outcome z x_exog, cluster(cluster_var)
test z
estimates store rf

* ---- 6. Panel IV with high-dim FE ---------------------------
ivreghdfe outcome x_exog (endog = z), ///
    absorb(unit_id year) cluster(cluster_var) first
weakivtest
estimates store iv_panel

* ---- 7. Export ---------------------------------------------
esttab iv_main rf iv_panel using "${results}/Tables/iv_main.tex", ///
    replace booktabs label se ///
    mtitles("2SLS" "Reduced form" "Panel IV") ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    stats(N widstat, fmt(%9.0fc %9.2f) ///
          labels("Observations" "Kleibergen-Paap rk Wald F")) ///
    notes("Cluster-robust SEs in parentheses.")
