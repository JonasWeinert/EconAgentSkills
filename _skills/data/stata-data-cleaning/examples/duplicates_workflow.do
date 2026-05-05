*-------------------------------------------------------------*
* Purpose : Identify, document, and resolve duplicates in the
*           raw baseline household dataset using ieduplicates +
*           iecompdup. Resolution decisions are recorded in an
*           Excel report so cleaning is fully replicable.
* Inputs  : ${baseline_raw}/baseline_hh_raw.dta
* Outputs : ${baseline_doc}/duplicates_baseline.xlsx
*           ${baseline_int}/baseline_hh_dedup.dta
*-------------------------------------------------------------*

ieboilstart, version(17.0)
`r(version)'

use "${baseline_raw}/baseline_hh_raw.dta", clear

* 1. Initial overview ---------------------------------------
duplicates report hhid

* 2. ieduplicates: produce / update the resolution report ---
*    First run creates the Excel with one row per duplicate set.
*    Team annotates each row with `correction`, `update`,
*    `keep_one`, or `drop` and rerun.
ieduplicates hhid using "${baseline_doc}/duplicates_baseline.xlsx", ///
    uniquevars(hhid) ///
    keepvars(enum_id submission_date device_id gps_lat gps_lon) ///
    folder("${baseline_doc}") ///
    listofdiffs(diff_log_baseline) ///
    replace

* 3. After resolutions are applied, hhid is unique ----------
isid hhid
assert !missing(hhid)

* 4. Save deduplicated intermediate file --------------------
ieboilsave, idvars(hhid)
save "${baseline_int}/baseline_hh_dedup.dta", replace

di as txt "Duplicates resolved. N = " _N
