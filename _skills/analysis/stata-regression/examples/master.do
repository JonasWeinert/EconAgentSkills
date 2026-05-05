*=============================================================*
* Project   : ProjectABC
* Master    : MasterDoFile.do
* Purpose   : Run the full DataWork pipeline end-to-end
* Authors   : Research Team
* Created   : 2026-05-05
*-------------------------------------------------------------*
* Folder layout (created by `iefolder new project, ...`):
*   ProjectABC/
*     DataWork/
*       Baseline/
*         DataSets/{Raw, Intermediate, Final}/
*         Dofiles/{Cleaning, Construction, Analysis}/
*         Output/{Tables, Figures}/
*         Documentation/
*=============================================================*

* 1. Boilerplate -----------------------------------------------
ieboilstart, version(17.0)
`r(version)'

* 2. Install / update packages (always include with `, replace`)
ssc install ietoolkit,          replace
ssc install reghdfe,            replace
ssc install ftools,             replace
ssc install ivreg2,             replace
ssc install ivreghdfe,          replace
ssc install ranktest,           replace
ssc install weakivtest,         replace
ssc install csdid,              replace
ssc install drdid,              replace
ssc install eventstudyinteract, replace
ssc install did_imputation,     replace
ssc install did_multiplegt_dyn, replace
ssc install jwdid,              replace
ssc install rdrobust,           replace
ssc install rddensity,          replace
ssc install boottest,           replace
ssc install estout,             replace
ssc install coefplot,           replace

* 3. User-specific root globals --------------------------------
if c(username) == "jonas"      global root "/Users/jonas/Dropbox/ProjectABC"
if c(username) == "coauthor1"  global root "C:/Users/coauthor1/Dropbox/ProjectABC"
if c(username) == "coauthor2"  global root "/home/coauthor2/projects/ProjectABC"

if "$root" == "" {
    di as error "Unknown user `c(username)'. Add a root path in MasterDoFile.do."
    error 198
}

* 4. Project subfolder globals ---------------------------------
global dataWork    "${root}/DataWork"
global baseline    "${dataWork}/Baseline"
global do_clean    "${baseline}/Dofiles/Cleaning"
global do_constr   "${baseline}/Dofiles/Construction"
global do_anal     "${baseline}/Dofiles/Analysis"
global data_raw    "${baseline}/DataSets/Raw"
global data_int    "${baseline}/DataSets/Intermediate"
global data_final  "${baseline}/DataSets/Final"
global results     "${baseline}/Output"

* 5. Routing switches ------------------------------------------
local doClean      0
local doConstr     0
local doAnalysis   1

if `doClean'    do "${do_clean}/master_cleaning.do"
if `doConstr'   do "${do_constr}/master_construction.do"
if `doAnalysis' do "${do_anal}/master_analysis.do"

di as txt "MasterDoFile.do completed."
