*-------------------------------------------------------------*
* Purpose : Coefficient plot (Stata) from eststo-stored models.
*           Shows treat coefficient with 95% CI across specs.
* Inputs  : ${data_final}/analysis.dta
* Outputs : ${figs}/fig_coefplot.pdf
*-------------------------------------------------------------*

ieboilstart, version(17.0)
`r(version)'

use "${data_final}/analysis.dta", clear

eststo clear
reghdfe y treat,                 absorb(unit year)        vce(cluster unit)
eststo m1
reghdfe y treat $controls,       absorb(unit year)        vce(cluster unit)
eststo m2
reghdfe y treat $controls,       absorb(unit year region#year) vce(cluster unit)
eststo m3

coefplot (m1, label("Baseline")) ///
        (m2, label("+ Controls")) ///
        (m3, label("+ Region#Year FE")), ///
    keep(treat) ///
    coeflabels(treat = "Treatment x Post") ///
    xline(0, lpattern(dash) lcolor(gs8)) ///
    ciopts(recast(rcap)) ///
    levels(95) ///
    xtitle("Coefficient on Treatment x Post (95% CI)") ///
    note("Cluster-robust SEs, clustered by unit." ///
         "Bands: 95% confidence intervals.") ///
    scheme(white_tableau) ///
    ysize(3) xsize(6.5)

graph export "${figs}/fig_coefplot.pdf", replace as(pdf)

di as txt "Figure exported to ${figs}/fig_coefplot.pdf"
