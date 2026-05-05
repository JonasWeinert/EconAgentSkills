# Stata Regression Reference

Detailed code patterns aligned with DIME Analytics conventions and modern econometrics. Use these as the canonical templates when generating Stata code.

## 1. Boilerplate and Settings (`ieboilstart`)

Every shared do-file starts with:

```stata
ieboilstart, version(17.0)
`r(version)'                  // actually applies the version
```

`ieboilstart` standardizes Stata version, memory settings, `more off`, `varabbrev off`, `set seed`, etc. Use the **oldest** Stata version anyone on the team has — once randomization or sampling is locked in, do not change the version.

## 2. Master Do-file Skeleton

```stata
*-------------------------------------------------------------*
* Project   : ProjectABC
* Master    : MasterDoFile.do
* Purpose   : Run the full DataWork pipeline end-to-end
* Inputs    : DataWork/Baseline/DataSets/Raw/*
* Outputs   : DataWork/Baseline/Output/*
*-------------------------------------------------------------*

* 1. Boilerplate
ieboilstart, version(17.0)
`r(version)'

* 2. Install packages (always include with `, replace` for replicability)
ssc install ietoolkit,          replace
ssc install reghdfe,            replace
ssc install ftools,             replace
ssc install ivreg2,             replace
ssc install ranktest,           replace
ssc install csdid,              replace
ssc install drdid,              replace
ssc install eventstudyinteract, replace
ssc install did_imputation,     replace
ssc install rdrobust,           replace
ssc install rddensity,          replace
ssc install boottest,           replace
ssc install estout,             replace
ssc install coefplot,           replace

* 3. User-specific root globals
if c(username) == "jonas"      global root "/Users/jonas/Dropbox/ProjectABC"
if c(username) == "coauthor1"  global root "C:/Users/coauthor1/Dropbox/ProjectABC"

* 4. Project subfolder globals
global dataWork    "${root}/DataWork"
global baseline    "${dataWork}/Baseline"
global do_clean    "${baseline}/Dofiles/Cleaning"
global do_constr   "${baseline}/Dofiles/Construction"
global do_anal     "${baseline}/Dofiles/Analysis"
global data_raw    "${baseline}/DataSets/Raw"
global data_int    "${baseline}/DataSets/Intermediate"
global data_final  "${baseline}/DataSets/Final"
global results     "${baseline}/Output"

* 5. Switches: set to 1 to run, 0 to skip
local doClean    1
local doConstr   1
local doAnalysis 1

if `doClean'    do "${do_clean}/master_cleaning.do"
if `doConstr'   do "${do_constr}/master_construction.do"
if `doAnalysis' do "${do_anal}/master_analysis.do"
```

## 3. Asserting Data Structure

```stata
use "${data_final}/analysis.dta", clear

* Unique identifier
isid hhid year

* Balanced panel check
xtset hhid year
xtdes

* No missing key vars
assert !missing(treated, post)
```

## 4. Balance Tables (`iebaltab`)

```stata
iebaltab age female years_school baseline_y, ///
    grpvar(treated) ///
    save("${results}/Tables/balance.xlsx") replace ///
    rowlabels("age Age @ female Female @ years_school Years of schooling") ///
    starlevels(0.10 0.05 0.01) ///
    notecombine
```

For multi-arm trials, `iebaltab` will produce all pairwise contrasts. Add `pttest` for pairwise t-tests, `feqtest` for F-tests of joint orthogonality, `fixedeffect(stratum)` for stratification, and `covariates(x1 x2)` for covariate-adjusted differences.

## 5. Difference-in-Differences

### 5.1 Two-period DD (`ieddtab` for the DIME-canonical table)

```stata
ieddtab outcome, t(year) treatment(treated) ///
    save("${results}/Tables/ieddtab.xlsx") replace
```

### 5.2 Static TWFE (only if timing is uniform)

```stata
reghdfe outcome treat_post, absorb(hhid year) vce(cluster hhid)
```

### 5.3 Staggered DiD: Callaway & Sant'Anna (`csdid`)

`csdid` requires a `gvar` that is the period of first treatment (0 for never-treated):

```stata
* gvar = first year of treatment, 0 if never treated
csdid outcome controls, ivar(unit_id) time(year) gvar(first_treat_year) ///
    method(dripw) cluster(unit_id)

* Aggregate to overall ATT
estat simple

* Dynamic event study
estat event
event_plot, default_look ///
    graph_opt(xtitle("Years since treatment") ytitle("ATT(e)"))
```

### 5.4 Staggered DiD: Sun & Abraham (`eventstudyinteract`)

```stata
* Build relative-time dummies
gen rel_time = year - first_treat_year if first_treat_year > 0
gen never_treat = first_treat_year == .
forvalues k = 0/5 {
    gen Lead`k' = rel_time == -`k'
    gen Lag`k'  = rel_time ==  `k'
}

eventstudyinteract outcome Lead* Lag*, ///
    cohort(first_treat_year) ///
    control_cohort(never_treat) ///
    absorb(unit_id year) ///
    vce(cluster unit_id)
```

### 5.5 Staggered DiD: BJS imputation (`did_imputation`)

```stata
did_imputation outcome unit_id year first_treat_year, ///
    horizons(0/5) pretrends(5) autosample
```

### 5.6 de Chaisemartin & D'Haultfoeuille (`did_multiplegt_dyn`)

Handles continuous and reversible treatment:

```stata
did_multiplegt_dyn outcome unit_id year treatment, ///
    effects(5) placebo(3) controls(controls) cluster(unit_id)
```

### 5.7 Event-study figure (`coefplot`)

```stata
coefplot, keep(Lead* Lag*) ///
    vertical omitted ///
    yline(0) xline(0, lpattern(dash)) ///
    ciopts(recast(rcap)) ///
    coeflabels(, interaction(" x ")) ///
    xtitle("Years since treatment") ytitle("ATT(e)")
graph export "${results}/Figures/event_study.pdf", replace
```

## 6. Instrumental Variables

### 6.1 Cross-section with full diagnostics

```stata
ivreg2 y x_exog (endog = z), cluster(cluster_var) first robust

* Olea-Pflueger effective F (post-2SLS)
weakivtest
```

### 6.2 Panel IV with high-dim FE

```stata
ivreghdfe y x_exog (endog = z), absorb(unit year) cluster(cluster_var) first
weakivtest
```

### 6.3 Weak-IV-robust inference

```stata
* Anderson-Rubin and CLR confidence sets
condivreg y x_exog (endog = z), cluster(cluster_var)

* Or rivtest (post-ivreg2):
rivtest, ci grid(0.5(0.05)1.5)
```

### 6.4 Reporting checklist for IV tables

- First-stage coefficient and cluster-robust SE on each instrument
- Kleibergen-Paap rk Wald F (from `ivreg2`)
- Olea-Pflueger effective F (from `weakivtest`)
- Hansen J for over-identified models
- Reduced-form regression of `y` on instruments

## 7. Regression Discontinuity

### 7.1 Sharp RDD with `rdrobust`

```stata
* Plot first
rdplot y x, c(0) binselect(esmv) ///
    graph_options(title("Sharp RDD") xtitle("Running variable"))
graph export "${results}/Figures/rdplot.pdf", replace

* MSE-optimal bandwidth, bias-corrected, robust SE
rdrobust y x, c(0)

* Density manipulation test
rddensity x, c(0)
```

### 7.2 Bandwidth sensitivity table

```stata
qui rdrobust y x, c(0)
local h_opt = e(h_l)

eststo clear
foreach h in `=`h_opt'/2' `h_opt' `=2*`h_opt'' {
    quietly rdrobust y x, c(0) h(`h')
    estadd scalar bandwidth = `h'
    eststo h_`=round(`h'*100)'
}

esttab using "${results}/Tables/rdd_sensitivity.tex", ///
    replace booktabs ///
    keep(RD_Estimate) ///
    stats(bandwidth N_l N_r, fmt(%9.3f %9.0fc %9.0fc) ///
        labels("Bandwidth" "N (left)" "N (right)"))
```

### 7.3 Fuzzy RDD

```stata
rdrobust y x, c(0) fuzzy(treatment)
```

## 8. Inference with Few Clusters

### 8.1 Wild cluster bootstrap (`boottest`)

```stata
reghdfe y treat controls, absorb(unit year) cluster(state)

boottest treat, reps(9999) cluster(state) ///
    weight(rademacher) seed(20240101)
```

### 8.2 Inverted CI from `boottest`

```stata
boottest treat, reps(9999) cluster(state) ci nograph
```

### 8.3 Multi-way clustering

```stata
* reghdfe with two-way clustering
reghdfe y treat, absorb(unit year) vce(cluster unit year)
```

## 9. Tables with `esttab`

### 9.1 Multi-spec table (LaTeX)

```stata
eststo clear
reghdfe y treat,                      absorb(unit year)        vce(cluster unit)
eststo m1
reghdfe y treat controls,             absorb(unit year)        vce(cluster unit)
eststo m2
reghdfe y treat controls,             absorb(unit year region) vce(cluster unit)
eststo m3

esttab m1 m2 m3 using "${results}/Tables/table_main.tex", ///
    replace booktabs label se ///
    keep(treat) ///
    stats(N r2_within, fmt(%9.0fc %9.3f) ///
          labels("Observations" "Within R-squared")) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    mtitles("Baseline" "+ Controls" "+ Region FE") ///
    indicate("Controls = controls" "Region FE = region") ///
    notes("Cluster-robust SEs in parentheses, clustered by unit.")
```

### 9.2 CSV / Excel export

Same `esttab` call with `.csv` or `.rtf`. For Word, use `.rtf`.

## 10. Reproducibility Discipline

- `set seed` at the top of every script that bootstraps or randomizes.
- Never `cd`. Always reference paths as `"${global}/sub/file.dta"`.
- Save intermediate `.dta` files into `DataSets/Intermediate/` with versioned names if appropriate.
- Use `iedropone` instead of bare `drop` when dropping by condition — it errors if the count is unexpected.
- Use `ieboilsave` before saving final analysis files — checks for valid IDs, encodings, etc.
- Use `iedorep` (DIME's reproducibility checker) before publishing.
- Never commit raw PII data to GitHub. Use `iecodebook` to harmonize and de-identify.
