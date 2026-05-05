*-------------------------------------------------------------*
* Purpose : Stata `merge 1:1` and `m:1` with explicit cardinality
*           validation, _merge inspection, and assertions.
* Inputs  : ${data_int}/master.dta, ${data_int}/using.dta
* Outputs : ${data_processed}/merged.dta
*-------------------------------------------------------------*

ieboilstart, version(17.0)
`r(version)'

* ============================================================
* 1:1 merge on a single key
* ============================================================
use "${data_int}/master.dta", clear
isid hhid
assert !missing(hhid)

merge 1:1 hhid using "${data_int}/using.dta", ///
    keepusing(outcome_y) ///
    update                                  // optional: update master from using

* Inspect _merge:
*   _merge == 1: master only
*   _merge == 2: using only
*   _merge == 3: matched
*   _merge == 4: master observation updated (when `update` used)
*   _merge == 5: master observation conflicting (when `update` used)

tabulate _merge

* Hard policy: require all matched. If you do not want this,
* document the alternative in the decisions log.
assert _merge == 3
drop _merge

isid hhid

* ============================================================
* m:1 merge: many individuals to one household
* ============================================================
use "${data_int}/individual.dta", clear
isid hhid person_id

merge m:1 hhid using "${data_int}/household.dta", ///
    keepusing(region treated) ///
    assert(match master)                    // every individual must match;
                                             // master-only allowed if some
                                             // households have no individuals

drop _merge
isid hhid person_id

save "${data_processed}/individuals_with_hh.dta", replace

di as txt "Merge complete. N = " _N
