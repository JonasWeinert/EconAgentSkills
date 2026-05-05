*-------------------------------------------------------------*
* Purpose : Convert numeric survey codes (-99/-88/-77/-98) to
*           extended missing values (.a/.b/.c/.n) with a single
*           harmonized label set. After this step, no plain "."
*           should remain in cleaned variables.
* Inputs  : ${baseline_int}/baseline_hh_codebook_applied.dta
* Outputs : ${baseline_int}/baseline_hh_missing_clean.dta
*-------------------------------------------------------------*

ieboilstart, version(17.0)
`r(version)'

use "${baseline_int}/baseline_hh_codebook_applied.dta", clear

* 1. One harmonized label set for survey-code missingness ---
label define mvlbl ///
    .a "Don't know"          ///
    .b "Refuse"              ///
    .c "Not applicable"      ///
    .n "Skipped (skip logic)" ///
    .r "Refused at consent", ///
    replace

* 2. Convert numeric survey codes ---------------------------
*    Add or remove variables to match the survey instrument.
local numeric_with_codes age income hours_worked savings_amount

foreach v of local numeric_with_codes {
    capture confirm numeric variable `v'
    if _rc continue
    quietly mvdecode `v', mv(-99=.a \ -88=.b \ -77=.c \ -98=.n)
    label values `v' mvlbl
}

* 3. Validate: no plain "." in cleaned variables ------------
foreach v of local numeric_with_codes {
    quietly count if `v' == .
    if r(N) > 0 {
        di as error "`v' still has plain . missing values: investigate."
    }
}

* 4. Validate ranges and types ------------------------------
assert age >= 0 & age <= 120 if !missing(age)
assert hours_worked >= 0 & hours_worked <= 168 if !missing(hours_worked)

* 5. Save intermediate ---------------------------------------
ieboilsave, idvars(hhid)
save "${baseline_int}/baseline_hh_missing_clean.dta", replace

di as txt "Extended missing values applied."
