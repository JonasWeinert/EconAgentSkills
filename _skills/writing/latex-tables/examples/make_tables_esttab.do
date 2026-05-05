*-------------------------------------------------------------*
* Purpose : Produce all paper tables from one Stata script.
*           Writes .tex files directly to paper/tabs/.
*           DIME "full replicability" tier: no manual editing.
* Inputs  : ${data_final}/analysis.dta
* Outputs : ${tabs}/table_summary.tex
*           ${tabs}/table_balance.tex
*           ${tabs}/table_main.tex
*           ${tabs}/table_robustness.tex
*-------------------------------------------------------------*

ieboilstart, version(17.0)
`r(version)'

use "${data_final}/analysis.dta", clear

* ============================================================
* Table 1: Summary statistics
* ============================================================
eststo clear
estpost summarize y treat $controls

esttab using "${tabs}/table_summary.tex", ///
    replace booktabs label nomtitle nonumber ///
    cells("mean(fmt(%9.2f)) sd(fmt(%9.2f)) min(fmt(%9.2f)) max(fmt(%9.2f)) count(fmt(%9.0fc))") ///
    title("Summary statistics\label{tab:summary}") ///
    addnotes("Sample: full estimation sample.")

* ============================================================
* Table 2: Balance across treatment arms (DIME-style)
* ============================================================
iebaltab age female years_school baseline_y, ///
    grpvar(treated) ///
    savetex("${tabs}/table_balance.tex") replace ///
    rowlabels("age Age (years) @ female Female @ years_school Years of schooling @ baseline_y Baseline outcome") ///
    starlevels(0.10 0.05 0.01) feqtest

* ============================================================
* Table 3: Main results
* ============================================================
eststo clear

reghdfe y treat,                  absorb(unit year) vce(cluster unit)
estadd local controls "No"
estadd local fes "Unit, Year"
eststo m1

reghdfe y treat $controls,        absorb(unit year) vce(cluster unit)
estadd local controls "Yes"
estadd local fes "Unit, Year"
eststo m2

reghdfe y treat $controls,        absorb(unit year region#year) vce(cluster unit)
estadd local controls "Yes"
estadd local fes "Unit, Year, Region#Year"
eststo m3

esttab m1 m2 m3 using "${tabs}/table_main.tex", ///
    replace booktabs label se ///
    keep(treat) ///
    coeflabels(treat "Treatment x Post") ///
    stats(controls fes N r2_within, ///
          fmt(%s %s %9.0fc %9.3f) ///
          labels("Controls" "Fixed effects" "Observations" "Within R-squared")) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    mtitles("Baseline" "+ Controls" "+ Region#Year FE") ///
    title("Effect of treatment on outcome\label{tab:main}") ///
    notes("Cluster-robust standard errors in parentheses, clustered by unit." ///
          "* p<0.10, ** p<0.05, *** p<0.01.")

* ============================================================
* Table 4: Robustness (alt clustering, alt sample)
* ============================================================
eststo clear

reghdfe y treat $controls, absorb(unit year) vce(cluster unit)
estadd local sample "Full"
estadd local cluster "Unit"
eststo r1

reghdfe y treat $controls, absorb(unit year) vce(cluster unit year)
estadd local sample "Full"
estadd local cluster "Unit, Year"
eststo r2

reghdfe y treat $controls if rural == 1, absorb(unit year) vce(cluster unit)
estadd local sample "Rural"
estadd local cluster "Unit"
eststo r3

esttab r1 r2 r3 using "${tabs}/table_robustness.tex", ///
    replace booktabs label se ///
    keep(treat) ///
    coeflabels(treat "Treatment x Post") ///
    stats(sample cluster N r2_within, ///
          fmt(%s %s %9.0fc %9.3f) ///
          labels("Sample" "Cluster" "Observations" "Within R-squared")) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    mtitles("Baseline" "Two-way cluster" "Rural only") ///
    title("Robustness\label{tab:robustness}") ///
    notes("Standard errors in parentheses." ///
          "* p<0.10, ** p<0.05, *** p<0.01.")

di as txt "All tables written to ${tabs}/"
