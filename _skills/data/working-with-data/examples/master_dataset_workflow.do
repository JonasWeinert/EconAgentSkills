*-------------------------------------------------------------*
* Purpose : Build the household master dataset from the sampling
*           frame and the treatment assignment table. Produces:
*             - encrypted version (with PII)  -> EncryptedData/
*             - de-identified version         -> MasterData/
*           DIME convention: one master per unit of observation.
* Inputs  : ${data_encrypted}/sampling_frame_PII.dta
*           ${data_int}/treatment_assignment.dta
* Outputs : ${data_encrypted}/master_household_PII.dta
*           ${master_data}/master_household.dta
*-------------------------------------------------------------*

ieboilstart, version(17.0)
`r(version)'

* ============================================================
* DECISIONS LOG
* Unit of observation: hhid (asserted)
* PII : sampling frame contains names, GPS, phone, dob.
*       Encrypted master holds these; de-identified master does not.
* Treatment: stratified by region; assignment in
*       data/intermediate/treatment_assignment.dta
* ASSUMPTIONS [HUMAN: please confirm]:
*   - hhid is stable across baseline and endline.
*   - Sampling frame is the universe of eligible households.
* ============================================================

* 1. Load encrypted sampling frame -------------------------------
use "${data_encrypted}/sampling_frame_PII.dta", clear
isid hhid
assert !missing(hhid, region)

* 2. Bring in treatment assignment ------------------------------
merge 1:1 hhid using "${data_int}/treatment_assignment.dta", ///
    keepusing(treated stratum) ///
    assert(match) nogen
isid hhid

* 3. Save encrypted master (full PII) ---------------------------
ieboilsave, idvars(hhid)
save "${data_encrypted}/master_household_PII.dta", replace

* 4. Build de-identified master ---------------------------------
*    Drop direct identifiers; keep only what analysis scripts
*    will need. Coarsening of quasi-identifiers happens later
*    in the deidentify_for_release pipeline (in stata-data-cleaning).
local pii name surname phone email contact_address ///
          gps_lat gps_lon dob national_id passport_no
foreach v of local pii {
    capture confirm variable `v'
    if !_rc drop `v'
}

isid hhid
ieboilsave, idvars(hhid)
save "${master_data}/master_household.dta", replace

di as txt "Master dataset updated."
di as txt "  encrypted: ${data_encrypted}/master_household_PII.dta"
di as txt "  de-identified: ${master_data}/master_household.dta"
