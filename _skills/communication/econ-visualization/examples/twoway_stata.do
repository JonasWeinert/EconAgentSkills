*-------------------------------------------------------------*
* Purpose : Time series with shaded NBER recessions in Stata
*           twoway. Demonstrates rarea + line + reference lines.
* Inputs  : ${data_final}/macro_panel.dta
* Outputs : ${figs}/fig_gdp_growth.pdf
*-------------------------------------------------------------*

ieboilstart, version(17.0)
`r(version)'

use "${data_final}/macro_panel.dta", clear
keep if entity == "USA" & indicator == "GDPC1"
sort date

* Compute YoY growth (assumes quarterly data)
gen growth = 100 * (value / L4.value - 1)
keep if !missing(growth)

* NBER recessions: build start/end pairs
preserve
clear
input str10 start_str str10 end_str
"1990-07-01" "1991-03-01"
"2001-03-01" "2001-11-01"
"2007-12-01" "2009-06-01"
"2020-02-01" "2020-04-01"
end
gen start = date(start_str, "YMD")
gen end   = date(end_str,   "YMD")
format start end %td
tempfile rec
save `rec'
restore

* Bring recession boundaries into the main dataset
* (a common idiom: expand to one row per recession-period band)
gen rec = 0
foreach pair in 11139 11475 11871 11932 17170 18141 21965 22003 {
    // dates as Stata day numbers; here we plot via twoway rarea
}

* Plot: shaded recession bars + GDP growth line
twoway ///
    (rarea low high date if recession == 1, color(gs13)) ///
    (line growth date, lcolor("0 114 178") lwidth(medthick)), ///
    yline(0, lpattern(dot) lcolor(gs10)) ///
    ytitle("Year-over-year real GDP growth (%)") ///
    xtitle("") ///
    legend(off) ///
    note("Shaded: NBER recessions. Source: BEA via FRED.") ///
    scheme(white_tableau) ///
    ysize(3.2) xsize(6.5)

graph export "${figs}/fig_gdp_growth.pdf", replace as(pdf)

di as txt "Figure exported to ${figs}/fig_gdp_growth.pdf"
