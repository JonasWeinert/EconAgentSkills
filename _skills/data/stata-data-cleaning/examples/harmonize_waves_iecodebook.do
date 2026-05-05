*-------------------------------------------------------------*
* Purpose : Harmonize variable names and labels across baseline
*           and endline survey rounds, then append into a single
*           panel-format dataset. Uses iecodebook append, which
*           is the right tool when waves use different variable
*           names for the same concepts.
* Inputs  : ${baseline_final}/baseline_hh_clean.dta
*           ${endline_final}/endline_hh_clean.dta
*           ${doc}/harmonize_codebook.xlsx
* Outputs : ${final}/panel_hh.dta
*           ${doc}/harmonize_codebook_export.xlsx
*-------------------------------------------------------------*

ieboilstart, version(17.0)
`r(version)'

* 1. Generate the harmonization codebook if missing ---------
capture confirm file "${doc}/harmonize_codebook.xlsx"
if _rc {
    di as txt "Generating harmonization template."
    iecodebook append ///
        "${baseline_final}/baseline_hh_clean.dta" ///
        "${endline_final}/endline_hh_clean.dta" ///
        using "${doc}/harmonize_codebook.xlsx", ///
        gen(round) match(hhid) ///
        clear
    di as error "Fill the template, then rerun."
    exit
}

* 2. Apply harmonization + append ---------------------------
iecodebook append ///
    "${baseline_final}/baseline_hh_clean.dta" ///
    "${endline_final}/endline_hh_clean.dta" ///
    using "${doc}/harmonize_codebook.xlsx", ///
    gen(round) match(hhid) ///
    clear

* 3. Validate the resulting panel ---------------------------
isid hhid round
xtset hhid round

* 4. Save panel and export self-describing codebook ---------
ieboilsave, idvars(hhid round)
save "${final}/panel_hh.dta", replace

iecodebook export using "${doc}/harmonize_codebook_export.xlsx", replace

di as txt "Harmonized panel saved. N = " _N
