# EconAgentSkills

Opinionated agent skills for econometrics research, built to make Claude Code, Cursor, Codex, and Gemini CLI behave like a competent research assistant who actually reads modern econometrics papers.

## What is an "agent skill"?

A skill is a folder with a `SKILL.md` file (YAML frontmatter + markdown body) that an AI agent loads when it detects a relevant request. Skills follow the open [SKILL.md standard](https://agentskills.io/home) used by Anthropic Claude Code, Cursor, Codex, and Gemini CLI. The frontmatter includes a `description` that the agent uses to decide whether the skill is relevant to the current task; the body contains the operating procedure, decision trees, and links to deeper reference material and runnable examples.

Each skill in this repo ships with:

- `SKILL.md` — the routing layer the agent reads every time.
- `reference.md` — extended patterns, code recipes, and quality checks the agent loads when it needs depth.
- `examples/` — runnable scripts (R, Python, Stata, Julia, LaTeX) that the agent adapts rather than copy-pastes verbatim.

## Why I built this

I built these to streamline my own econometrics research. The defaults that ship with general-purpose AI tools are uneven: they happily generate plain TWFE on staggered treatment, report `F > 10` as a sufficient first-stage test, paste regression numbers into LaTeX by hand, and mix red-green palettes for treatment vs. control. The skills here force the agent into the patterns I want (and the patterns I think most applied economists should want).

They are deliberately **highly opinionated**. The opinions come from:

- **DIME Analytics' [DIME Wiki](https://dimewiki.worldbank.org/)** — `iefolder`, `iecodebook`, `ieduplicates`, master do-files, the four-tier replicability standard, the [Reviewing Graphs](https://dimewiki.worldbank.org/Checklist:_Reviewing_Graphs) and [Submit Table](https://dimewiki.worldbank.org/Checklist:_Submit_Table) checklists, and the general "single source of truth + master orchestrator" mindset (translated to Python, Julia, and LaTeX where DIME's guidance is Stata-only).
- **Modern econometrics literature** — Goodman-Bacon (2021), Callaway-Sant'Anna (2021), Sun-Abraham (2021), Borusyak-Jaravel-Spiess (2024), de Chaisemartin-D'Haultfoeuille; Olea-Pflueger (2013) and Lee et al. (2022) for weak IV; Calonico-Cattaneo-Titiunik (2014) for RDD; Cameron-Gelbach-Miller (2008) and MacKinnon-Webb (2018) for wild cluster bootstrap; Roth, Sant'Anna, Bilinski & Poe (2023) for the modern DiD landscape.
- **Modern packages** — `fixest` / `pyfixest`, `did`, `didimputation`, `eventstudyinteract`, `csdid`, `did_imputation`, `boottest`/`fwildclusterboot`, `rdrobust`, `linearmodels`, `modelsummary`/`stargazer`/`esttab`.

The repo was inspired by [meleantonio/awesome-econ-ai-stuff](https://github.com/meleantonio/awesome-econ-ai-stuff) — the original curated catalog. This is a narrower, more opinionated rewrite focused on four workflow stages.

## What's included

Ten skills across four stages, plus a repo-wide agent policy:

```
data/             working-with-data, api-data-fetcher, stata-data-cleaning
analysis/         r-econometrics, stata-regression, python-panel-data
writing/          academic-paper-writer, latex-tables
communication/    econ-visualization, beamer-presentation
```

`_skills/data/working-with-data/` is the foundational data-discipline skill that the others assume — unit of analysis, ID variables, merge cardinality, master dataset, PII, sample-construction logging.

Browse `_skills/<stage>/<skill>/SKILL.md` for the routing layer or `reference.md` for the deep version.

## Human-in-the-loop discipline (read this if you use these in agent mode)

Modern AI coding tools will happily run end-to-end with no questions asked. For econometrics that is dangerous. A confident agent will pick a unit of analysis, fill in a treatment definition, settle on a clustering level, drop "anomalous" observations, and write the resulting numbers into your paper — none of which it should do without you.

This repo's `_skills/AGENT_POLICY.md` is the most important file in the project. It defines a four-level discipline that every skill follows, so the agent has a clear policy on when to stop, when to default, when to document, and when to just do the work.

| Level | Behavior | Examples |
|-------|----------|----------|
| **ASK** | Block and present 2-4 concrete options with trade-offs. Do not proceed. | Unit of analysis; treatment definition; cluster level; identification strategy; anything touching PII or `data/raw/`. |
| **DEFAULT + flag** | Use the stated default and tell the user how to override. | Use Callaway-Sant'Anna for staggered DiD by default; cluster at the unit level; Okabe-Ito palette; booktabs tables; vector PDF figures. |
| **DOCUMENT** | Record the assumption in the script's decisions log, then proceed. | "Inferred unit of analysis as firm-year"; "Used `log1p` instead of `log + 1` to handle zero-revenue observations"; merge-cardinality and N-only-master / N-only-using counts. |
| **PROCEED** | Just do the right thing — these are universally good and not interesting to ask about. | `set seed`; `ieboilstart`; `pathlib`; `isid`; vector format figures; raw data is immutable. |

Cross-cutting rules apply to every skill:

- Raw data is immutable; cleaning produces files in `intermediate/` or `processed/`.
- Numbers come from code; never typed in prose.
- PII never enters version control; API keys live in env vars only.
- Every dropped observation has a reason and an N before/after in the log.
- Every dataset that has a key is asserted unique before save.
- No silent estimator swaps — switching from TWFE to Callaway-Sant'Anna because timing is staggered is documented.

Every script the agent generates begins with a **decisions log** header that captures what the agent assumed. Items tagged `[HUMAN: please confirm]` are the ones the agent inferred without asking. Example (from `_skills/data/working-with-data/examples/decisions_log.txt`):

```text
# DECISIONS LOG (review and edit before publication)
# Unit of obs   : firm-year (asserted)
# ID            : firm_id (numeric, immutable across waves)
# Cluster       : firm (treatment-assignment level)
# Filters (cumulative): raw 14,012 -> drop missing(industry) 13,801 ->
#                       drop revenue<=0 12,711 -> in-both-waves 12,432
# ASSUMPTIONS [HUMAN: please confirm]:
#   - firm_id is stable across the 2018 reform.
#   - Industry is fixed at baseline for each firm.
# BLOCKED [HUMAN: please answer]:
#   - Treat acquired firms as right-censored or as continuing units?
```

Each individual `SKILL.md` has a `## Decision Policy` section listing its specific blocking questions, defaults, and documented inferences. Browse those when designing an autonomous workflow on top of these skills.

**Why this matters for agentic use.** The skills are designed so that an unattended agent (e.g. running in CI, or in a Cursor background agent) can do real work without making research-substantive decisions on its own. When an answer is needed and no human is available, the policy is to be conservative (produce intermediate output, not final), write the unanswered question into the log, and surface it via PR or commit message for human review.

### Recommended companion: `git-ai` for AI contribution tracking

The decisions log gives you the agent's stated assumptions; **what it does not give you is line-level attribution of who actually wrote each line of code.** When you run these skills in agent mode (background agents, CI jobs, long autonomous sessions), I strongly recommend pairing them with [`git-ai`](https://github.com/git-ai-project/git-ai) — an open-source git extension that tracks AI-generated code automatically.

It complements this repo well:

- **The policy doc is upstream control** — what the agent should ask, default, document, or just do.
- **`git-ai` is downstream observability** — what the agent actually wrote, with which agent, which model, and which prompt produced each line.

What you get:

- **Per-commit AI vs. human breakdown** — printed automatically on every `git commit` (e.g. "you 6% / mixed 2% / ai 92%").
- **`git-ai blame`** — drop-in replacement for `git blame` that shows the model, agent, and session behind every line; especially useful for an empirical paper where reviewers may ask "did you write this regression spec or did the agent?".
- **`git-ai stats`** — JSON output with AI-accept rates, human-override counts, and tool/model breakdowns. Easy to drop into a referee response.
- **`/ask` skill** — talk to the agent that wrote a line about its instructions and the transcript that produced it. Helps a co-author or future-you reconstruct *why* a particular bit of analysis code looks the way it does.
- **Local-first, no login required** — works offline. AI-attribution is stored in git notes; transcripts are stored in local SQLite (or optionally in a self-hosted store for teams).
- Works with Claude Code, Cursor, Codex, Copilot, Windsurf, Gemini, OpenCode, and others — the same tools these skills target.

Install (Mac / Linux / WSL):

```bash
curl -sSL https://usegitai.com/install.sh | bash
```

No per-repo setup; commit and prompt as normal. I use it whenever I run any of these skills in autonomous agent mode — research code that nobody can attribute later is research code nobody trusts later.

## Install on a new machine

The skills work with any agent that supports the SKILL.md standard. The installer copies a skill into the agent's skills directory.

```bash
git clone https://github.com/JonasWeinert/EconAgentSkills.git
cd EconAgentSkills

# All skills, all four stages
python scripts/install_skills.py --target cursor --all
python scripts/install_skills.py --target claude --all

# A single stage
python scripts/install_skills.py --target cursor --stage analysis

# A single skill
python scripts/install_skills.py --target cursor --skill r-econometrics
```

Default install paths:

| Tool | Path |
|------|------|
| Cursor | `~/.cursor/skills/` |
| Claude Code | `~/.claude/skills/` |
| Codex | `~/.codex/skills/` |

Use `--dest /path/to/your/project/.cursor/skills` to install per-project instead of globally.

## Use a skill

Once installed, just describe the task in your normal voice; the agent picks the right skill from the description. Or invoke explicitly:

```
/r-econometrics Run a Callaway-Sant'Anna DiD with state and year fixed effects, clustered by state.
```

```
/stata-data-cleaning Clean baseline household survey, harmonize with endline, and produce an iecodebook export.
```

## References and inspirations

- [meleantonio/awesome-econ-ai-stuff](https://github.com/meleantonio/awesome-econ-ai-stuff) — the original catalog.
- DIME Analytics, [DIME Wiki](https://dimewiki.worldbank.org/) — Stata coding practices, reproducible research, data cleaning, exporting analysis, data visualization, PII discipline.
- Roth, Sant'Anna, Bilinski & Poe (2023), [What's Trending in Difference-in-Differences?](https://jonathandroth.github.io/assets/files/DiD_Review_Paper.pdf).
- Berge (2018), [`fixest`](https://lrberge.github.io/fixest/) — the package that defines a lot of what these skills do well.
- Cunningham (2021), [Causal Inference: The Mixtape](https://mixtape.scunning.com/).
- Anthropic, [Agent Skills documentation](https://docs.anthropic.com/claude/docs/skills).
- [Cursor Skills documentation](https://cursor.com/docs/skills).

## License

[CC0 1.0](LICENSE) — public domain.
