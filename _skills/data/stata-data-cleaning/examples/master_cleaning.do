*=============================================================*
* Master cleaning do-file for ProjectABC, Baseline round.
* Run from the project master do-file (which sets all globals).
*=============================================================*

ieboilstart, version(17.0)
`r(version)'

* Switches: set to 1 to run, 0 to skip
local doDuplicates  1
local doCodebook    1
local doMissing     1
local doConstruct   1
local doMaster      1
local doRelease     0    // turn on once team agrees on release version

if `doDuplicates' do "${do_clean}/duplicates_workflow.do"
if `doCodebook'   do "${do_clean}/clean_with_iecodebook.do"
if `doMissing'    do "${do_clean}/missing_values_extended.do"
if `doConstruct'  do "${do_constr}/construct_derived.do"
if `doMaster'     do "${do_clean}/master_dataset.do"
if `doRelease'    do "${do_clean}/deidentify_for_release.do"

di as txt "Baseline cleaning pipeline complete."
