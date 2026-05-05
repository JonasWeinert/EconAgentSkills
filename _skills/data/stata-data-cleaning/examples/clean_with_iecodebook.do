*-------------------------------------------------------------*
* Purpose : Apply the codebook-driven cleaning to the
*           deduplicated baseline dataset. Renames, labels,
*           recodes, and drops live in an Excel codebook so
*           the team can edit cleaning logic without writing
*           Stata code.
* Inputs  : ${baseline_int}/baseline_hh_dedup.dta
*           ${baseline_doc}/baseline_codebook.xlsx
* Outputs : ${baseline_int}/baseline_hh_codebook_applied.dta
*           ${baseline_doc}/baseline_hh_codebook_export.xlsx
*-------------------------------------------------------------*

ieboilstart, version(17.0)
`r(version)'

use "${baseline_int}/baseline_hh_dedup.dta", clear

* 1. Generate template if it does not yet exist -------------
capture confirm file "${baseline_doc}/baseline_codebook.xlsx"
if _rc {
    di as txt "No codebook found; generating a template for the team to fill."
    iecodebook template using "${baseline_doc}/baseline_codebook.xlsx"
    di as error "Fill the template in Excel, then rerun this do-file."
    exit
}

* 2. Apply the codebook --------------------------------------
*    The `missingvalues()` option harmonizes extended missing
*    values across the entire codebook.
iecodebook apply using "${baseline_doc}/baseline_codebook.xlsx", ///
    missingvalues( ///
        .a "Don't know" \  ///
        .b "Refuse"      \ ///
        .c "Not applicable" \ ///
        .n "Skipped (logic)" ///
    )

* 3. Save intermediate ---------------------------------------
isid hhid
ieboilsave, idvars(hhid)
save "${baseline_int}/baseline_hh_codebook_applied.dta", replace

* 4. Export a self-describing codebook for documentation -----
iecodebook export using "${baseline_doc}/baseline_hh_codebook_export.xlsx", ///
    replace

di as txt "Codebook applied. N = " _N ", vars = " c(k)
