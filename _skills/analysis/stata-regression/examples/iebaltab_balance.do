*-------------------------------------------------------------*
* Purpose : DIME-style balance table with iebaltab.
* Inputs  : ${data_final}/analysis.dta
* Outputs : ${results}/Tables/balance.xlsx
*-------------------------------------------------------------*

use "${data_final}/analysis.dta", clear

* Restrict to baseline sample
keep if year == 2018

* Treatment variable: 0 = control, 1 = treatment
isid unit_id

* Balance table over a panel of pre-treatment characteristics
iebaltab age female years_school baseline_y, ///
    grpvar(treated) ///
    save("${results}/Tables/balance.xlsx") replace ///
    rowlabels("age Age (years) @ female Female @ years_school Years of schooling @ baseline_y Baseline outcome") ///
    starlevels(0.10 0.05 0.01) ///
    notecombine ///
    feqtest

* For multi-arm trials, add `pttest` for pairwise t-tests:
* iebaltab age female years_school, grpvar(treatment_arm) pttest ...

* For stratified randomization, add `fixedeffect(stratum)`:
* iebaltab age female, grpvar(treated) fixedeffect(stratum) ...

* For covariate-adjusted differences, add `covariates(x1 x2)`:
* iebaltab age female, grpvar(treated) covariates(district) ...
