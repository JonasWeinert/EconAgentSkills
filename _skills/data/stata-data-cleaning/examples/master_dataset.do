*-------------------------------------------------------------*
* Purpose : Build / update the master dataset for the household
*           unit of observation. The master dataset stores
*           time-invariant identifying information, sampling
*           status, and treatment assignment. There is one
*           master per unit of observation.
* Inputs  : ${master_data_PII}/sampling_frame_PII.dta  (encrypted)
*           ${baseline_int}/treatment_assignment.dta
* Outputs : ${master_data}/master_household.dta          (de-identified)
*           ${master_data_PII}/master_household_PII.dta  (encrypted)
*-------------------------------------------------------------*

ieboilstart, version(17.0)
`r(version)'

* 1. Start from the sampling frame (encrypted version) -------
*    This is the only step that touches PII. It runs from
*    EncryptedData/ which is mounted via VeraCrypt only when
*    needed. The output is split into two files: with and
*    without identifying information.

use "${master_data_PII}/sampling_frame_PII.dta", clear
isid hhid

* 2. Merge in randomization assignment -----------------------
merge 1:1 hhid using "${baseline_int}/treatment_assignment.dta", ///
    keepusing(treated stratum) assert(match) nogen

* 3. Save the encrypted master (full PII) --------------------
ieboilsave, idvars(hhid)
save "${master_data_PII}/master_household_PII.dta", replace

* 4. Strip PII and save the de-identified master -------------
*    Drop direct identifiers; coarsen quasi-identifiers if
*    needed. See deidentify_for_release.do for public release.
drop name surname phone gps_lat gps_lon dob

ieboilsave, idvars(hhid)
save "${master_data}/master_household.dta", replace

di as txt "Master dataset updated."
di as txt "Encrypted version: ${master_data_PII}/master_household_PII.dta"
di as txt "De-identified:     ${master_data}/master_household.dta"
