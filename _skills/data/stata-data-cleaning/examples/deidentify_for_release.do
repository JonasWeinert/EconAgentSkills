*-------------------------------------------------------------*
* Purpose : Strip PII and coarsen quasi-identifiers to produce
*           a public-release version of the analysis-ready
*           dataset. Run only after the team has agreed on the
*           release version and reviewed disclosure risk.
* Inputs  : ${baseline_final}/baseline_hh_clean.dta
* Outputs : ${baseline_final}/public_release/baseline_hh_public.dta
*           ${baseline_final}/public_release/codebook_public.xlsx
*-------------------------------------------------------------*

ieboilstart, version(17.0)
`r(version)'

use "${baseline_final}/baseline_hh_clean.dta", clear

* 1. Drop direct identifiers --------------------------------
*    Check the DIME PII page for the canonical list:
*    https://dimewiki.worldbank.org/Personally_Identifiable_Information_(PII)
local direct_pii name surname phone email contact_address ///
                 gps_lat gps_lon dob national_id passport_no
foreach v of local direct_pii {
    capture confirm variable `v'
    if !_rc drop `v'
}

* 2. Coarsen quasi-identifiers ------------------------------
*    Age in 5-year bands; collapse small regions; round dates.
gen age_group = floor(age / 5) * 5
label var age_group "Age in 5-year bands (lower bound)"
drop age

recode region (1/2 = 1 "North/East") (3/4 = 2 "South/West"), ///
    gen(region_coarse)
drop region

* 3. Suppress small cells (k-anonymity threshold) -----------
*    Drop categorical levels with fewer than `k` observations.
local k = 10
foreach v of varlist region_coarse age_group {
    bysort `v': gen _ct = _N
    replace `v' = . if _ct < `k'
    drop _ct
}

* 4. Validate ------------------------------------------------
isid hhid
foreach v of local direct_pii {
    capture confirm variable `v'
    assert _rc != 0    // PII variable should no longer exist
}

* 5. Optional: scan for any leftover likely PII --------------
*    capture noisily pii_scan, save("${doc}/pii_scan_report.csv")

* 6. Save and document ---------------------------------------
capture mkdir "${baseline_final}/public_release"
ieboilsave, idvars(hhid)
save "${baseline_final}/public_release/baseline_hh_public.dta", replace

iecodebook export ///
    using "${baseline_final}/public_release/codebook_public.xlsx", ///
    replace

di as txt "Public-release dataset saved."
di as txt "Review disclosure risk before sharing."
