*-------------------------------------------------------------*
* Purpose : Wild cluster bootstrap for inference with few
*           clusters (Cameron-Gelbach-Miller; MacKinnon-Webb).
* Inputs  : ${data_final}/analysis.dta
* Outputs : ${results}/Tables/boottest_main.tex
*-------------------------------------------------------------*

use "${data_final}/analysis.dta", clear

* Suppose treatment is at the state level and there are only
* ~12 states. Cluster-robust SEs will undercover.

reghdfe outcome treat controls_*, ///
    absorb(unit_id year) cluster(state)
estimates store reghdfe_main

* ---- 1. Wild cluster bootstrap (Rademacher) ------------------
boottest treat, ///
    reps(9999) cluster(state) weight(rademacher) ///
    seed(20240101)

* ---- 2. Inverted bootstrap CI (preferred for reporting) ------
boottest treat, ///
    reps(9999) cluster(state) weight(rademacher) ///
    ci nograph seed(20240101)

* ---- 3. With small-sample correction --------------------------
boottest treat, ///
    reps(9999) cluster(state) weight(rademacher) ///
    small seed(20240101)

* ---- 4. Subcluster bootstrap when needed ----------------------
* boottest treat, reps(9999) cluster(state) bootcluster(state) ...
