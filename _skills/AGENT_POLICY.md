# Agent Policy: Human-in-the-Loop Discipline

This file defines how skills in this repo balance agent autonomy and human oversight. Every skill in `_skills/**/SKILL.md` references this document and tailors the four-level policy to its specific blocking questions.

The default mode is **agent does the work, human owns the substantive decisions**. The agent should *never* silently make a choice that changes the answer to a research question.

## The Four Levels

### 1. ASK (blocking)

Stop and ask the user. Do not proceed until you have an explicit answer.

Use **ASK** for any decision that:

- changes the substantive answer (unit of analysis, treatment definition, outcome definition, identification strategy, cluster level, sample restrictions);
- is irreversible (writing to `data/raw/`, deleting files, force-pushing, deleting branches, dropping observations without an undo path);
- touches PII or sensitive data (encryption, de-identification, sharing);
- requires money or credentials (API keys for paid services, deployments, anything billed);
- contradicts a stated convention or a previous answer in the same session.

How to ASK: present 2-4 concrete options with brief trade-offs. Do not wait silently for free-form input — give the user something to react to.

### 2. DEFAULT + flag

Use a sensible default and explicitly flag it in the output so the user can override.

Use **DEFAULT** for choices that:

- have a clear conventional answer for the domain (cluster at the unit level for unit-assigned treatment, Okabe-Ito palette, booktabs style, MSE-optimal RDD bandwidth);
- have alternatives the user may prefer but are not load-bearing for the result;
- are easily changed downstream (figure dimensions, table format, file naming).

How to DEFAULT: state the default in the output ("Using cluster-robust SEs at the unit level. Override with `cluster = ~state` if treatment is at the state level."), then proceed.

### 3. DOCUMENT

Record the decision in the script header, decisions log, or commit message — then proceed.

Use **DOCUMENT** for:

- inferences from data that the user did not explicitly confirm (e.g. "Inferred unit of analysis as firm-year because `firm_id year` is the unique key");
- sample-construction filters and the resulting N at each step;
- variable transformations (winsorizing, deflating, log/level);
- choice of an estimator within a family the user already approved (e.g. user said "DiD with staggered timing" → agent picks Callaway-Sant'Anna and documents the choice);
- which DIME-style folder structure was created;
- any assumption that a future reader of the script needs to know.

How to DOCUMENT: every script gets a header block (see "Decisions log template" below). Every non-obvious choice in the body gets a one-line comment.

### 4. PROCEED

Do the right thing without asking. The user does not benefit from being interrupted for these.

Use **PROCEED** for:

- reproducibility scaffolding (`set seed`, `ieboilstart`, `Random.seed!`, dynamic absolute paths, `Project.toml` / `pyproject.toml`);
- asserting data structure (`isid`, `assert`, `pandera`, `stopifnot`);
- creating standard project folders (`data/raw/`, `data/processed/`, `tabs/`, `figs/`, `code/`);
- formatting (booktabs tables, three-line rules, vector PDF figures);
- using the language's modern idiom (`feols` over `lm`, `pyfixest` over `statsmodels` for panel TWFE, `pathlib` over hardcoded paths);
- writing tests/checks that validate the work (`verify_equilibrium`, balance tests, market-clearing checks).

## Cross-cutting Rules (apply everywhere)

These are **PROCEED** by default and **ASK** if the user asks to violate them:

- **Raw data is immutable.** Never write to `data/raw/`. Cleaning produces files in `data/intermediate/` or `data/processed/`.
- **Numbers come from code.** Never type a coefficient, standard error, or N in prose by hand. They live in `tabs/` and are `\input{}`'d.
- **PII never enters version control.** API keys, names, GPS, dates of birth, contact info: env vars or encrypted folders only. Add to `.gitignore` defensively.
- **Drops are logged.** Every `drop if ...`, `df = df[...]`, or `filter()` is accompanied by a comment with the reason and the resulting N.
- **Identifiers are asserted.** Every dataset that has a key is checked with `isid` (Stata) / `df.duplicated().sum() == 0` (Python) / `stopifnot(!duplicated(df[, keys]))` (R) before saving.
- **No silent estimator swaps.** If the agent switches from TWFE to Callaway-Sant'Anna because the timing is staggered, that switch is documented in the script header and noted in any output.
- **No copy-paste numbers between files.** Numbers flow from analysis script → `tabs/*.tex` or `figs/*.pdf` → paper / slides via `\input{}` / `\includegraphics{}`.

## Decisions Log Template

Every analysis or cleaning script begins with a header block that captures the decisions the agent made or assumed. The format:

```text
# ============================================================
# DECISIONS LOG  (review and edit before publication)
# ============================================================
# Estimand:        ATT of program X on outcome Y
# Unit of obs:     firm-year (asserted: isid firm_id year)
# Treatment:       binary, =1 from year of program participation onward
# Outcome:         log of revenue (winsorized at 1st / 99th pctile)
# Sample:          balanced firm-year panel, 2010-2024
#                  filters: drop if missing(industry), drop if rev <= 0
#                  resulting N: 12,432 firms, 174,048 firm-years
# Identification:  Callaway-Sant'Anna (2021), staggered adoption,
#                  never-treated comparison group
# Cluster:         firm (treatment-assignment level)
# Inference:       cluster-robust SE; G = 12,432 clusters
# Reproducibility: ieboilstart 17.0; seed 20240101
# ASSUMPTIONS [HUMAN: please confirm]:
#   - Treatment is absorbing (no firm exits treatment).
#   - "Firm" identifier is stable across mergers (no firm_id reassignment).
# ============================================================
```

The lines tagged `[HUMAN: please confirm]` are the ones the agent inferred without confirmation. They are the first thing a reviewer or co-author should look at.

In Python:

```python
"""
DECISIONS LOG (review and edit before publication)
====================================================
Estimand   : ATT of program X on outcome Y
Unit       : firm-year
Treatment  : binary, ...
Cluster    : firm
Reproducibility: pyproject.toml-pinned; seed 20240101
ASSUMPTIONS [HUMAN: please confirm]:
- Treatment is absorbing.
- firm_id is stable across mergers.
"""
```

In LaTeX:

```latex
% DECISIONS LOG (review and edit before publication)
% Estimand: ATT ...
% ASSUMPTIONS [HUMAN: please confirm]:
% - ...
```

## How to write a Decision Policy block in a SKILL.md

Each skill should declare its blocking questions explicitly. Template:

```markdown
## Decision Policy

This skill follows the repo-wide [Agent Policy](../../AGENT_POLICY.md).

**ASK before proceeding** (blocking):
1. [substantive question 1]
2. [substantive question 2]
3. [substantive question 3]

**DEFAULT + flag** (use the listed default; tell the user how to override):
- [default 1] — override with [...]
- [default 2] — override with [...]

**DOCUMENT and proceed** (write into the decisions log):
- [inferred choice 1]
- [inferred choice 2]

PROCEED items follow the cross-cutting rules above.
```

## When the human is unavailable

Some skills run unattended (CI jobs, scheduled refreshes). When no human can answer an ASK:

1. Apply the most conservative interpretation that is **reversible** (e.g., produce intermediate output but do not save final; produce a draft table but do not overwrite the published one).
2. Write the unanswered ASK into the decisions log as `BLOCKED [HUMAN: please answer]`.
3. Open an issue / PR / draft commit summarizing what was blocked and why, so a human reviews before the next run.
